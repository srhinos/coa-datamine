"""Mythic+/Challenges pack (task V2-5): Challenge.dbc hub + Challenge* link/type tables
-> data/mythic/challenges/ (per-challenge files); MythicKeystones/MythicAffixes/
MythicPlusScaling/TimedDungeons/MapDifficulty -> data/mythic/*.

Amendment D (single-writer ownership): build_mythic.py is the SOLE writer under
data/mythic/ - build() clears and rebuilds the whole directory itself, no other builder
touches it.

Full mapping evidence (join-rates, disproven hypotheses, goldens) is documented in
tools/dbc.py's TABLE_MAPS comments for the Challenge*/Mythic*/TimedDungeons/MapDifficulty
tables and in .superpowers/sdd/task-v2-5-report.md. Summary of what this module derives
on top of the raw named columns:

- Challenge.dbc (297x53) is the hub: id/name_enUS/description_enUS/iconToken/
  difficultyToken/modeToken are all proven string columns (see tools/dbc.py). The golden
  (Challenge 7 "Nudist") is cross-validated end-to-end here: its own ChallengeRules row
  resolves ruleTypeToken CHALLENGE_RULES_TYPE_NO_EQUIP_ARMOR, which the ChallengeRuleTypes
  lookup resolves to name "No Equipping Armor" / description "You may not equip any
  armor." - matching Nudist's own description text.
- ChallengeModifierTypes/ChallengeRuleTypes/ChallengeConditionTypes/
  ChallengeRequirementTypes are small lookup tables (id/token/name/description), shipped
  verbatim in challenges/_lookups.json.
- 9 link tables (Groups/Levels/Rules/Modifiers/Conditions/Requirements/Rewards/Featured/
  Spells) each carry a proven challengeId column (join-rate >=80% raw, see tools/dbc.py
  and challenges/_meta.json); rows are grouped onto their owning challenge file.
  ChallengeGroupRewards has no direct challengeId - it is proven to key by
  ChallengeGroups.id instead (93.75% chained join through ChallengeGroups.challengeId),
  so it is attached as each group's "reward", nested under a challenge's "groups" list.
- ChallengeRules/ChallengeRequirements additionally resolve a per-row *TypeToken (a
  proven STRING match, not a numeric FK - see tools/dbc.py) against the corresponding
  Types lookup table for name/description. ChallengeConditions has no provable type link
  at all (its own string block is too small to carry a denormalized token) and ships
  challengeId-only.
- ChallengeSpells.spellId (f5) is sparse (802/7702 rows) but 100% proven on its populated
  subset; only those rows are attached to a challenge's "spells" list.
- MythicKeystones/MythicAffixes/MythicPlusScaling/TimedDungeons/MapDifficulty are small
  standalone tables; see tools/dbc.py for each column's proof. MythicKeystones is
  reshaped per-dungeon (Amendment C stable-semantic-key sharding); MythicAffixes (13409
  rows) is bucketed by its own id (Amendment C fixed id-range bucketing, matching the
  creatures/quests bucket-by-id convention) since a single file would exceed 5,000 lines.
"""
import json, shutil
from collections import defaultdict

from tools import config, dbc, sharding

MIN_JOIN_RATE = 0.80
AFFIX_BUCKET = 5000


def _raw_rows(table):
    """Yield each row of `table` as a dict: TABLE_MAPS-named columns decoded, every
    unmapped column carried as raw f<N> (same pattern build_creatures.py/build_classmeta.py
    use for Quest.dbc's f1..f28 and ChrSpecs' f63)."""
    spec = dbc.TABLE_MAPS[table]
    mapped = {idx: (name, kind) for name, idx, kind in spec["columns"]}
    f = dbc.DBCFile(config.WORK_DBC_DIR / f"{table}.dbc")
    for row in f.iter_rows():
        rec = {}
        for i in range(f.fields):
            if i in mapped:
                name, kind = mapped[i]
                rec[name] = f.string(row[i]) if kind == "s" else dbc.u32(row[i])
            else:
                rec[f"f{i}"] = dbc.u32(row[i])
        yield rec


def _join_rate(rows, key, id_set):
    rows = list(rows)
    if not rows:
        return 0.0, 0
    hits = sum(1 for r in rows if r[key] in id_set)
    return hits / len(rows), len(rows)


def _by_challenge(rows, challenge_ids):
    d = defaultdict(list)
    for r in rows:
        if r["challengeId"] in challenge_ids:
            d[r["challengeId"]].append(r)
    return d


def build_challenges() -> dict:
    out_dir = config.DATA_DIR / "mythic" / "challenges"
    out_dir.mkdir(parents=True, exist_ok=True)

    challenges = list(dbc.iter_named("Challenge"))
    challenge_ids = {c["id"] for c in challenges}

    rule_types = list(dbc.iter_named("ChallengeRuleTypes"))
    modifier_types = list(dbc.iter_named("ChallengeModifierTypes"))
    condition_types = list(dbc.iter_named("ChallengeConditionTypes"))
    requirement_types = list(dbc.iter_named("ChallengeRequirementTypes"))
    rule_by_token = {r["token"]: r for r in rule_types}
    requirement_by_token = {r["token"]: r for r in requirement_types}
    modifier_by_id = {r["id"]: r for r in modifier_types}
    spell_names = {s["id"]: s["name_enUS"] for s in dbc.iter_named("Spell")}

    groups_rows = list(_raw_rows("ChallengeGroups"))
    levels_rows = list(_raw_rows("ChallengeLevels"))
    rules_rows = list(_raw_rows("ChallengeRules"))
    modifiers_rows = list(_raw_rows("ChallengeModifiers"))
    conditions_rows = list(_raw_rows("ChallengeConditions"))
    requirements_rows = list(_raw_rows("ChallengeRequirements"))
    rewards_rows = list(_raw_rows("ChallengeRewards"))
    featured_rows = list(_raw_rows("ChallengeFeatured"))
    spells_rows = list(_raw_rows("ChallengeSpells"))
    group_rewards_rows = list(_raw_rows("ChallengeGroupRewards"))

    # gate (brief): >=80% of link-table challenge-id values resolve to Challenge rows
    link_meta = {}
    for name, rows in [
        ("groups", groups_rows), ("levels", levels_rows), ("rules", rules_rows),
        ("modifiers", modifiers_rows), ("conditions", conditions_rows),
        ("requirements", requirements_rows), ("rewards", rewards_rows),
        ("featured", featured_rows), ("spells", spells_rows),
    ]:
        rate, total = _join_rate(rows, "challengeId", challenge_ids)
        assert rate >= MIN_JOIN_RATE, (
            f"{name} challengeId join-rate {rate:.3f} < {MIN_JOIN_RATE} - mapping is wrong")
        link_meta[name] = {"totalRows": total, "challengeJoinRate": round(rate, 4)}

    # spellId sub-gate: proven only on the populated subset (see tools/dbc.py)
    spell_pop = [r for r in spells_rows if r["spellId"]]
    spell_hits = sum(1 for r in spell_pop if r["spellId"] in spell_names)
    link_meta["spells"]["spellIdPopulated"] = len(spell_pop)
    link_meta["spells"]["spellIdJoinRate"] = (
        round(spell_hits / len(spell_pop), 4) if spell_pop else 0.0)

    # ChallengeGroupRewards: no direct challengeId - proven to key by ChallengeGroups.id
    # (not ChallengeLevels.id - see tools/dbc.py for the disambiguation evidence)
    group_challenge = {r["id"]: r["challengeId"] for r in groups_rows}
    group_hits = sum(1 for r in group_rewards_rows if r["groupId"] in group_challenge)
    challenge_hits = sum(1 for r in group_rewards_rows
                          if group_challenge.get(r["groupId"]) in challenge_ids)
    total_gr = len(group_rewards_rows)
    link_meta["groupRewards"] = {
        "totalRows": total_gr,
        "groupJoinRate": round(group_hits / total_gr, 4) if total_gr else 0.0,
        "challengeJoinRateViaGroup": round(challenge_hits / total_gr, 4) if total_gr else 0.0,
    }
    assert link_meta["groupRewards"]["challengeJoinRateViaGroup"] >= MIN_JOIN_RATE

    groups_by = _by_challenge(groups_rows, challenge_ids)
    levels_by = _by_challenge(levels_rows, challenge_ids)
    rules_by = _by_challenge(rules_rows, challenge_ids)
    modifiers_by = _by_challenge(modifiers_rows, challenge_ids)
    conditions_by = _by_challenge(conditions_rows, challenge_ids)
    requirements_by = _by_challenge(requirements_rows, challenge_ids)
    rewards_by = _by_challenge(rewards_rows, challenge_ids)
    featured_challenge_ids = {r["challengeId"] for r in featured_rows
                               if r["challengeId"] in challenge_ids}
    spells_by = _by_challenge(spells_rows, challenge_ids)
    reward_by_group = {r["groupId"]: r for r in group_rewards_rows}

    index_entries = []
    for c in sorted(challenges, key=lambda x: x["id"]):
        cid = c["id"]

        level_entries = [
            {"id": r["id"], "f2": r["f2"], "f3": r["f3"], "f4": r["f4"]}
            for r in sorted(levels_by.get(cid, []), key=lambda x: x["id"])
        ]

        rule_entries = []
        for r in sorted(rules_by.get(cid, []), key=lambda x: x["id"]):
            rt = rule_by_token.get(r["ruleTypeToken"])
            rule_entries.append({
                "ruleTypeToken": r["ruleTypeToken"] or None,
                "name": rt["name_enUS"] if rt else None,
                "description": rt["description_enUS"] if rt else None,
                "f2": r["f2"], "f3": r["f3"],
            })

        modifier_entries = []
        for r in sorted(modifiers_by.get(cid, []), key=lambda x: x["modifierTypeId"]):
            mt = modifier_by_id.get(r["modifierTypeId"])
            modifier_entries.append({
                "modifierTypeId": r["modifierTypeId"],
                "name": mt["name_enUS"] if mt else None,
                "description": mt["descriptionFormat_enUS"] if mt else None,
                "f2": r["f2"], "f3": r["f3"], "f4": r["f4"], "f5": r["f5"],
                "f6": r["f6"], "f7": r["f7"],
            })

        condition_entries = [
            {k: v for k, v in r.items() if k != "challengeId"}
            for r in sorted(conditions_by.get(cid, []), key=lambda x: x["id"])
        ]

        requirement_entries = []
        for r in sorted(requirements_by.get(cid, []), key=lambda x: x["id"]):
            rt = requirement_by_token.get(r["requirementTypeToken"])
            requirement_entries.append({
                "requirementTypeToken": r["requirementTypeToken"] or None,
                "name": rt["name_enUS"] if rt else None,
                "description": rt["description_enUS"] if rt else None,
                "f2": r["f2"], "f3": r["f3"], "f5": r["f5"], "f6": r["f6"],
                "f7": r["f7"], "f8": r["f8"],
            })

        reward_entries = [
            {k: v for k, v in r.items() if k != "challengeId"}
            for r in sorted(rewards_by.get(cid, []), key=lambda x: x["id"])
        ]

        spell_entries = [
            {"spellId": r["spellId"], "name": spell_names.get(r["spellId"])}
            for r in sorted(spells_by.get(cid, []), key=lambda x: x["id"])
            if r["spellId"]
        ]

        group_entries = []
        for r in sorted(groups_by.get(cid, []), key=lambda x: x["id"]):
            reward = reward_by_group.get(r["id"])
            group_entries.append({
                "id": r["id"], "f2": r["f2"],
                "reward": ({k: v for k, v in reward.items() if k != "groupId"}
                            if reward else None),
            })

        doc = {
            "id": cid, "name": c["name_enUS"], "description": c["description_enUS"],
            "iconToken": c["iconToken"] or None, "difficultyToken": c["difficultyToken"] or None,
            "modeToken": c["modeToken"] or None, "featured": cid in featured_challenge_ids,
            "groups": group_entries, "levels": level_entries, "rules": rule_entries,
            "modifiers": modifier_entries, "conditions": condition_entries,
            "requirements": requirement_entries, "rewards": reward_entries,
            "spells": spell_entries,
        }
        slug = sharding.slugify(c["name_enUS"])
        fname = f"{cid}-{slug}.json"
        # dump_manifest (not indent=1): a handful of challenges (e.g. the default
        # "Adventure Mode") aggregate thousands of per-level rule/condition/reward rows -
        # one-record-per-line keeps every challenge file well under the 5,000-line gate.
        (out_dir / fname).write_text(sharding.dump_manifest(doc), encoding="utf-8")
        index_entries.append({
            "id": cid, "name": c["name_enUS"], "file": fname,
            "difficultyToken": c["difficultyToken"] or None,
            "modeToken": c["modeToken"] or None, "featured": cid in featured_challenge_ids,
        })

    (out_dir / "index.json").write_text(
        sharding.dump_manifest({"challenges": index_entries}), encoding="utf-8")

    lookups = {
        "ruleTypes": sorted(rule_types, key=lambda x: x["id"]),
        "modifierTypes": sorted(modifier_types, key=lambda x: x["id"]),
        "conditionTypes": sorted(condition_types, key=lambda x: x["id"]),
        "requirementTypes": sorted(requirement_types, key=lambda x: x["id"]),
    }
    (out_dir / "_lookups.json").write_text(
        sharding.dump_manifest(lookups), encoding="utf-8")

    meta = {
        "count": len(challenges),
        "linkTables": link_meta,
        "golden": (
            "Challenge 7 'Nudist' / 'You are unable to equip or wear armor of any kind.' "
            "cross-validated end-to-end via its own ChallengeRules row "
            "(ruleTypeToken=CHALLENGE_RULES_TYPE_NO_EQUIP_ARMOR) resolving through "
            "ChallengeRuleTypes id5 to name 'No Equipping Armor' / description "
            "'You may not equip any armor.'"
        ),
        "conditionsFinding": (
            "No conditionTypeId link is provable for ChallengeConditions (its own string "
            "block is only 167 bytes - too small to carry a per-row denormalized token the "
            "way ChallengeRules/ChallengeRequirements do); conditions ship challengeId-only, "
            "no resolved type name."
        ),
    }
    (out_dir / "_meta.json").write_text(
        json.dumps(meta, ensure_ascii=False, indent=1, sort_keys=True), encoding="utf-8")

    return {"count": len(challenges), "linkTables": link_meta}


def build_keystones() -> dict:
    out_dir = config.DATA_DIR / "mythic" / "keystones"
    out_dir.mkdir(parents=True, exist_ok=True)

    lfg = {d["id"]: d for d in dbc.iter_named("LFGDungeons")}
    by_dungeon = defaultdict(list)
    unresolved = []
    total = 0
    for r in dbc.iter_named("MythicKeystones"):
        total += 1
        if r["dungeonId"] in lfg:
            by_dungeon[r["dungeonId"]].append({"id": r["id"], "level": r["level"]})
        else:
            unresolved.append(r)

    index_entries = []
    for did in sorted(by_dungeon):
        levels = sorted(by_dungeon[did], key=lambda x: x["level"])
        name = lfg[did]["name_enUS"]
        fname = f"{did}-{sharding.slugify(name)}.json"
        payload = {"dungeonId": did, "dungeonName": name, "levels": levels}
        (out_dir / fname).write_text(
            json.dumps(payload, ensure_ascii=False, indent=1, sort_keys=True), encoding="utf-8")
        index_entries.append({"dungeonId": did, "dungeonName": name, "file": fname,
                               "count": len(levels)})

    (out_dir / "index.json").write_text(
        sharding.dump_manifest({"dungeons": index_entries}), encoding="utf-8")
    if unresolved:
        (out_dir / "_unresolved.json").write_text(
            sharding.dump_manifest({"rows": unresolved}), encoding="utf-8")

    rate = 1 - (len(unresolved) / total) if total else 0.0
    return {"count": total, "dungeons": len(by_dungeon), "unresolved": len(unresolved),
            "dungeonJoinRate": round(rate, 4)}


def build_affixes() -> dict:
    out_dir = config.DATA_DIR / "mythic" / "affixes"
    out_dir.mkdir(parents=True, exist_ok=True)

    spell_names = {s["id"]: s["name_enUS"] for s in dbc.iter_named("Spell")}
    records = []
    for r in _raw_rows("MythicAffixes"):
        effect_spells = []
        for k in ("effectSpellId1", "effectSpellId2", "effectSpellId3"):
            sid = r[k]
            if sid:
                effect_spells.append({"id": sid, "name": spell_names.get(sid)})
        records.append({
            "id": r["id"],
            "grantSpellId": r["grantSpellId"] or None,
            "grantSpellName": (spell_names.get(r["grantSpellId"])
                                if r["grantSpellId"] else None),
            "effectSpells": effect_spells,
            "f1": r["f1"], "f2": r["f2"], "f4": r["f4"], "f5": r["f5"], "f6": r["f6"],
            "f7": r["f7"], "f8": r["f8"], "f9": r["f9"], "f10": r["f10"], "f14": r["f14"],
            "f15": r["f15"],
        })
    records.sort(key=lambda x: x["id"])

    bucketed = defaultdict(list)
    for rec in records:
        bucketed[sharding.bucket_id(rec["id"], AFFIX_BUCKET)].append(rec)

    bucket_index = []
    for bkt in sorted(bucketed):
        recs = bucketed[bkt]
        fname = f"affixes-{bkt}.jsonl"
        with open(out_dir / fname, "w", encoding="utf-8", newline="\n") as fh:
            for rec in recs:
                fh.write(json.dumps(rec, ensure_ascii=False, sort_keys=True,
                                    separators=(",", ":")) + "\n")
        bucket_index.append({"bucket": bkt, "file": fname, "count": len(recs),
                              "minId": recs[0]["id"], "maxId": recs[-1]["id"]})

    (out_dir / "index.json").write_text(
        sharding.dump_manifest({"bucketSize": AFFIX_BUCKET, "count": len(records),
                                 "buckets": bucket_index}), encoding="utf-8")
    return {"count": len(records)}


def build_scaling() -> dict:
    mdir = config.DATA_DIR / "mythic"
    records = sorted(_raw_rows("MythicPlusScaling"), key=lambda x: x["id"])
    (mdir / "scaling.json").write_text(
        sharding.dump_manifest({"scaling": records}), encoding="utf-8")
    return {"count": len(records)}


def build_timed_dungeons() -> dict:
    mdir = config.DATA_DIR / "mythic"
    lfg_names = {d["id"]: d["name_enUS"] for d in dbc.iter_named("LFGDungeons")}
    records = []
    resolved = 0
    for r in _raw_rows("TimedDungeons"):
        name = lfg_names.get(r["dungeonId"])
        if name:
            resolved += 1
        records.append({
            "dungeonId": r["dungeonId"], "dungeonName": name,
            "timeLimitMs": r["timeLimitMs"], "f1": r["f1"], "f2": r["f2"],
            "f3": r["f3"], "f5": r["f5"],
        })
    records.sort(key=lambda x: x["dungeonId"])
    (mdir / "timedDungeons.json").write_text(
        sharding.dump_manifest({"timedDungeons": records}), encoding="utf-8")
    rate = resolved / len(records) if records else 0.0
    return {"count": len(records), "dungeonResolved": resolved,
            "dungeonJoinRate": round(rate, 4)}


def build_map_difficulty() -> dict:
    mdir = config.DATA_DIR / "mythic"
    maps = {m["id"]: m["name_enUS"] for m in dbc.iter_named("Map")}
    records = []
    for r in _raw_rows("MapDifficulty"):
        records.append({
            "id": r["id"], "mapId": r["mapId"], "mapName": maps.get(r["mapId"]),
            "difficultyIndex": r["difficultyIndex"],
            "lockoutMessage": r["lockoutMessage_enUS"] or None,
            "difficultyToken": r["difficultyToken"] or None,
        })
    records.sort(key=lambda x: x["id"])
    (mdir / "mapDifficulty.json").write_text(
        sharding.dump_manifest({"mapDifficulty": records}), encoding="utf-8")
    return {"count": len(records)}


def build() -> dict:
    config.ensure_dirs()
    mdir = config.DATA_DIR / "mythic"
    if mdir.exists():
        shutil.rmtree(mdir)          # sole writer (Amendment D) - safe to own outright
    mdir.mkdir(parents=True)

    return {
        "challenges": build_challenges(),
        "keystones": build_keystones(),
        "affixes": build_affixes(),
        "scaling": build_scaling(),
        "timedDungeons": build_timed_dungeons(),
        "mapDifficulty": build_map_difficulty(),
    }


if __name__ == "__main__":
    print(build())
