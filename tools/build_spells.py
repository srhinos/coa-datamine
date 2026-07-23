"""Build data/spells/spells.jsonl: every referenced spell, fully enriched.

Referenced = CharacterAdvancementData spells + SpellRankData chains + Talent.dbc
ranks, then closed transitively over EffectTriggerSpell (tag "trigger").

Amendment C: output is sharded data/spells/by-id/spells-<id//BUCKET_SIZE*BUCKET_SIZE>.jsonl
+ data/spells/index.json (bucket manifest); _meta.json keeps counts only, full
missing-ref id lists live in _missing_refs.json (one line per source array)."""
import json, shutil
from collections import defaultdict

from tools import config, dbc, enums335, sharding

BUCKET_SIZE = 10000


def iter_all():
    """Yield every spell record across all id-bucket shards, via index.json - the
    reader path for build_classes._spell_min / build_talents._spell_names."""
    out_dir = config.DATA_DIR / "spells"
    index = json.loads((out_dir / "index.json").read_text(encoding="utf-8"))
    for b in index["buckets"]:
        with open(out_dir / b["file"], encoding="utf-8") as fh:
            for line in fh:
                yield json.loads(line)


def _write_missing_refs(path, missing_by_source):
    """Amendment C: each source's array on ONE line, not json.dumps(indent=...)'d
    (which would put one id per line and blow past the 5,000-line gate)."""
    keys = sorted(missing_by_source)
    lines = ["{"]
    for i, k in enumerate(keys):
        arr = json.dumps(missing_by_source[k], separators=(",", ":"))
        comma = "," if i < len(keys) - 1 else ""
        lines.append(f' "{k}": {arr}{comma}')
    lines.append("}")
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def _content(name):
    return json.loads((config.RAW_CONTENT_DIR / name).read_text(encoding="utf-8-sig"))


def _initial_refs(cad):
    refs = {}
    def add(i, tag):
        if i:
            refs.setdefault(int(i), set()).add(tag)
    for e in cad:
        for s in e.get("Spells", []):
            add(s, "cad")
    for e in _content("SpellRankData.json"):
        add(e["spellId"], "rank")
        add(e["firstSpellId"], "rank")
    for t in dbc.iter_named("Talent"):
        for i in range(1, 10):
            add(t[f"rankSpell{i}"], "talent")
    return refs


def _cad_realm_split(cad):
    """Amendment A: CharacterAdvancementData.json is account-wide across four realms;
    Reborn*-class entries belong to "Bronzebeard - Warcraft Reborn", whose spell data
    isn't materialized in this client's Spell.dbc snapshot. Split CAD-referenced ids
    into "referenced by >=1 non-Reborn entry" vs "referenced only by Reborn entries"."""
    other, reborn = set(), set()
    for e in cad:
        bucket = reborn if str(e.get("Class", "")).startswith("Reborn") else other
        for s in e.get("Spells", []):
            if s:
                bucket.add(int(s))
    reborn -= other
    return other, reborn


def _bucket(tags, cad_other_ids, cad_reborn_ids, sid):
    if sid in cad_other_ids:
        return "cad_other"
    if sid in cad_reborn_ids:
        return "cad_reborn"
    if "talent" in tags:
        return "talent"
    return "rank"


def _aux():
    return {
        "cast": {r["id"]: r for r in dbc.iter_named("SpellCastTimes")},
        "dur": {r["id"]: r for r in dbc.iter_named("SpellDuration")},
        "rng": {r["id"]: r for r in dbc.iter_named("SpellRange")},
        "rad": {r["id"]: r for r in dbc.iter_named("SpellRadius")},
        "icon": {r["id"]: r["texturePath"] for r in dbc.iter_named("SpellIcon")},
        "dispel": {r["id"]: r["name_enUS"] for r in dbc.iter_named("SpellDispelType")},
        "mech": {r["id"]: r["name_enUS"] for r in dbc.iter_named("SpellMechanic")},
        "rune": {r["id"]: r for r in dbc.iter_named("SpellRuneCost")},
        "roles": {e["Spell"]: e for e in _content("SpellToRoleSuggestionData.json")},
        "rank": {e["spellId"]: e for e in _content("SpellRankData.json")},
    }


def _record(r, aux, tags):
    a = aux
    effects = []
    for slot in (1, 2, 3):
        eff = r[f"effect{slot}"]
        if not eff:
            continue
        radius = a["rad"].get(r[f"effectRadiusIndex{slot}"])
        effects.append({
            "slot": slot,
            "effect": {"id": eff, "name": enums335.effect_name(eff)},
            "aura": {"id": r[f"effectAura{slot}"],
                     "name": enums335.aura_name(r[f"effectAura{slot}"])},
            "basePoints": r[f"effectBasePoints{slot}"],
            "dieSides": r[f"effectDieSides{slot}"],
            "miscValue": r[f"effectMiscValue{slot}"],
            "miscValueB": r[f"effectMiscValueB{slot}"],
            "amplitudeMs": r[f"effectAmplitude{slot}"],
            "multipleValue": r[f"effectMultipleValue{slot}"],
            "chainTargets": r[f"effectChainTarget{slot}"],
            "radiusYd": radius["radius"] if radius else 0.0,
            "triggerSpell": r[f"effectTriggerSpell{slot}"],
            "targetA": {"id": r[f"effectImplicitTargetA{slot}"],
                        "name": enums335.target_name(r[f"effectImplicitTargetA{slot}"])},
            "targetB": {"id": r[f"effectImplicitTargetB{slot}"],
                        "name": enums335.target_name(r[f"effectImplicitTargetB{slot}"])},
            "mechanic": {"id": r[f"effectMechanic{slot}"],
                         "name": a["mech"].get(r[f"effectMechanic{slot}"], "None")},
        })
    cast = a["cast"].get(r["castingTimeIndex"])
    dur = a["dur"].get(r["durationIndex"])
    rng = a["rng"].get(r["rangeIndex"])
    rank = a["rank"].get(r["id"])
    role = a["roles"].get(r["id"])
    rune = a["rune"].get(r["runeCostID"]) if r["runeCostID"] else None
    return {
        "id": r["id"], "name": r["name_enUS"], "rank": r["rank_enUS"],
        "description": r["description_enUS"], "tooltip": r["tooltip_enUS"],
        "dispel": {"id": r["dispel"],
                   "name": a["dispel"].get(r["dispel"],
                                           enums335.DISPEL_NAMES.get(r["dispel"], str(r["dispel"])))},
        "mechanic": {"id": r["mechanic"], "name": a["mech"].get(r["mechanic"], "None")},
        "schoolMask": r["schoolMask"], "schools": enums335.school_names(r["schoolMask"]),
        "attributes": [r["attributes"], r["attributesEx"], r["attributesEx2"],
                       r["attributesEx3"], r["attributesEx4"], r["attributesEx5"],
                       r["attributesEx6"], r["attributesEx7"]],
        "powerType": {"id": r["powerType"],
                      "name": enums335.POWER_TYPES.get(r["powerType"], str(r["powerType"]))},
        "manaCost": r["manaCost"], "manaCostPct": r["manaCostPercentage"],
        "levels": {"base": r["baseLevel"], "spell": r["spellLevel"], "max": r["maxLevel"]},
        "castTimeMs": cast["base"] if cast else 0,
        "durationMs": {"base": dur["base"], "max": dur["max"]} if dur else {"base": 0, "max": 0},
        "rangeYd": {"minEnemy": rng["minRange"], "minFriendly": rng["minRangeFriendly"],
                    "maxEnemy": rng["maxRange"], "maxFriendly": rng["maxRangeFriendly"]}
                   if rng else {"minEnemy": 0.0, "minFriendly": 0.0,
                                "maxEnemy": 0.0, "maxFriendly": 0.0},
        "cooldownMs": r["recoveryTime"], "categoryCooldownMs": r["categoryRecoveryTime"],
        "gcdMs": r["startRecoveryTime"], "gcdCategory": r["startRecoveryCategory"],
        "stackAmount": r["stackAmount"], "procFlags": r["procFlags"],
        "procChance": r["procChance"], "procCharges": r["procCharges"],
        "dmgClass": enums335.DMG_CLASS_NAMES.get(r["dmgClass"], str(r["dmgClass"])),
        "preventionType": enums335.PREVENTION_NAMES.get(r["preventionType"],
                                                        str(r["preventionType"])),
        "iconPath": a["icon"].get(r["spellIconID"], ""),
        "stances": r["stances"], "targets": r["targets"],
        "interruptFlags": r["interruptFlags"],
        "auraInterruptFlags": r["auraInterruptFlags"],
        "channelInterruptFlags": r["channelInterruptFlags"],
        "family": {"id": r["spellFamilyName"], "flags1": r["spellFamilyFlags1"],
                   "flags2": r["spellFamilyFlags2"]},
        "runeCost": ({"blood": rune["blood"], "unholy": rune["unholy"],
                      "frost": rune["frost"], "runicPower": rune["runicPower"]}
                     if rune else None),
        "effects": effects,
        "rankChain": ({"first": rank["firstSpellId"], "rank": rank["rank"],
                       "level": rank["level"]} if rank else None),
        "roles": ({"tank": role["TankScore"], "healer": role["HealerScore"],
                   "damage": role["DamageScore"]} if role else None),
        "referencedBy": sorted(tags),
    }


def build() -> dict:
    config.ensure_dirs()
    cad = _content("CharacterAdvancementData.json")               # load CAD once
    refs = _initial_refs(cad)
    cad_other_ids, cad_reborn_ids = _cad_realm_split(cad)
    initial_ids = set(refs)                                       # pre-closure snapshot
    aux = _aux()

    # pass 1: full records for initially-referenced ids + trigger map for ALL ids
    records, triggers = {}, {}
    for r in dbc.iter_named("Spell"):
        triggers[r["id"]] = (r["effectTriggerSpell1"], r["effectTriggerSpell2"],
                             r["effectTriggerSpell3"])
        if r["id"] in refs:
            records[r["id"]] = r

    # transitive closure over EffectTriggerSpell
    frontier = set(records)
    while frontier:
        new = set()
        for sid in frontier:
            for t in triggers.get(sid, ()):
                if t and t in triggers and t not in refs:
                    refs.setdefault(t, set()).add("trigger")
                    new.add(t)
        frontier = new

    # pass 2: fetch full records for closure-added ids
    todo = set(refs) - set(records)
    todo &= set(triggers)                       # only ids that exist in Spell.dbc
    if todo:
        for r in dbc.iter_named("Spell"):
            if r["id"] in todo:
                records[r["id"]] = r

    # Amendment A: bucket every pre-closure referenced id (cad_other > cad_reborn >
    # talent > rank) and report per-bucket miss ratios instead of one flat ratio -
    # CAD is account-wide across four realms and Reborn's spells aren't on disk here.
    ref_counts = {"cad_other": 0, "cad_reborn": 0, "talent": 0, "rank": 0}
    missing_by_source = {"cad_other": [], "cad_reborn": [], "talent": [], "rank": []}
    for sid in initial_ids:
        b = _bucket(refs[sid], cad_other_ids, cad_reborn_ids, sid)
        ref_counts[b] += 1
        if sid not in triggers:
            missing_by_source[b].append(sid)
    missing_by_source = {k: sorted(v) for k, v in missing_by_source.items()}

    out_dir = config.DATA_DIR / "spells"
    if out_dir.exists():
        shutil.rmtree(out_dir)                    # drop any prior monolith/shards
    by_id_dir = out_dir / "by-id"
    by_id_dir.mkdir(parents=True)

    by_source = {}
    bucketed = defaultdict(list)
    for sid in sorted(records):
        rec = _record(records[sid], aux, refs[sid])
        for t in rec["referencedBy"]:
            by_source[t] = by_source.get(t, 0) + 1
        bucketed[sharding.bucket_id(sid, BUCKET_SIZE)].append(rec)

    bucket_index = []
    for bkt in sorted(bucketed):
        recs = bucketed[bkt]
        fname = f"by-id/spells-{bkt}.jsonl"
        with open(out_dir / fname, "w", encoding="utf-8", newline="\n") as fh:
            for rec in recs:
                fh.write(json.dumps(rec, ensure_ascii=False, sort_keys=True,
                                    separators=(",", ":")) + "\n")
        bucket_index.append({"bucket": bkt, "file": fname, "count": len(recs),
                              "minId": recs[0]["id"], "maxId": recs[-1]["id"]})

    # golden gate: refuse to publish a dataset that fails known ground truth
    g = records.get(17)
    assert g and g["name_enUS"] == "Power Word: Shield" and g["dispel"] == 1, \
        "golden spell 17 failed - column map is wrong, dataset aborted"

    # hard gates: cad_other and talent must resolve near-completely (this client's own
    # realms); cad_reborn and rank are report-only (Reborn realm + stale rank chains)
    co_ratio = len(missing_by_source["cad_other"]) / max(1, ref_counts["cad_other"])
    assert co_ratio <= 0.05, \
        f"cad_other missing ratio {co_ratio:.3f} > 0.05 - non-Reborn CAD refs must resolve"
    tal_ratio = len(missing_by_source["talent"]) / max(1, ref_counts["talent"])
    assert tal_ratio <= 0.05, \
        f"talent missing ratio {tal_ratio:.3f} > 0.05 - Talent.dbc ranks must resolve"

    index = {"bucketSize": BUCKET_SIZE, "count": len(records), "buckets": bucket_index}
    (out_dir / "index.json").write_text(sharding.dump_manifest(index), encoding="utf-8")
    _write_missing_refs(out_dir / "_missing_refs.json", missing_by_source)

    meta = {
        "count": len(records),
        "missing_ref_counts_by_source": {k: len(v) for k, v in missing_by_source.items()},
        "missingRefsFile": "_missing_refs.json",
        "ref_counts": ref_counts, "by_source": by_source,
        "dataNotes": (
            "CharacterAdvancementData.json is account-wide across four realms served by "
            "this client (Area 52 - Free-Pick, Bronzebeard - Warcraft Reborn, Rexxar - "
            "Conquest of Azeroth, Vol'jin - Conquest of Azeroth). Reborn*-class entries "
            "belong to the Warcraft Reborn realm, whose spell data is not materialized in "
            "this client's Spell.dbc snapshot, so cad_reborn misses are expected and "
            "report-only. SpellRankData.json also carries stale orphan rank chains "
            "(bucket 'rank') with no filterable realm/class field; also report-only. "
            "Measured churn baseline: cad_other 211/7162 = 2.95% on 2026-07-17 (real "
            "named custom-class abilities absent from this snapshot's Spell.dbc)."
        ),
        "schema_note": ("sharded by id//" + str(BUCKET_SIZE) + "*" + str(BUCKET_SIZE) +
                        " into by-id/spells-<bucket>.jsonl (one spell per line, ascending "
                        "id within a bucket); see index.json and docs/AGENT-GUIDE.md"),
    }
    (out_dir / "_meta.json").write_text(
        json.dumps(meta, indent=1, sort_keys=True), encoding="utf-8")
    return {"written": len(records), "missing_by_source": missing_by_source,
            "ref_counts": ref_counts, "by_source": by_source}


if __name__ == "__main__":
    s = build()
    print(f"spells written={s['written']} "
          f"missing_by_source={ {k: len(v) for k, v in s['missing_by_source'].items()} } "
          f"ref_counts={s['ref_counts']} by_source={s['by_source']}")
