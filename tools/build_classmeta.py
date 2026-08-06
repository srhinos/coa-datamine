"""Class/spec metadata pack (task V2-3): ChrSpecs -> data/classes/specs.json,
CharacterCreationArchetypes(+ArchetypeDetails) -> data/classes/archetypes.json.

Amendment D (single-writer ownership): this module owns specs.json/archetypes.json
ONLY - it must run after build_classes.build() (which owns the per-class
subdirectories + index.json) but never reads or writes data/classes/index.json.
specIds/roles/specialAbilities all live inside specs.json instead (see below);
consumers that want spec/role data read specs.json, not index.json.

Full mapping evidence (golden probes, join-rates, disproven hypotheses) is documented
in tools/dbc.py's TABLE_MAPS comments for ChrSpecs/ChrClassesRoles/CharacterCreation*
and in .superpowers/sdd/task-v2-3-report.md. Summary of what this module derives on
top of the raw named columns:

- ChrSpecs.classToken (a string, not a raw int) is joined against ChrClasses.name_enUS
  (normalized), falling back to ChrClasses.filename (normalized) when the name join
  misses [task W4-5] - the 24/101 specs that used to have no match at all
  (DEMONHUNTER/MONK/SONOFARUGAL/FLESHWARDEN/PROPHET/WILDWALKER/SPIRITMAGE tokens,
  which are filename-column values, not display names - see tools/dbc.py's
  ChrClasses TABLE_MAPS comment) now all resolve via the fallback; coverage went
  from 25/32 to 32/32 ChrClasses. A spec's classId/className still ships null only
  if BOTH joins miss (none currently do, but the fallback chain is kept rather than
  asserting 32/32, in case a future client patch reintroduces a genuinely
  unmatched token).
- ChrSpecs' 4 armor-flag columns (armorCloth/armorLeather/armorMail/armorPlate) are
  combined into one "armorType" string (None when zero or more than one flag is set).
- ChrSpecs.f63 (the brief's disproven "role" candidate) is read directly off the raw
  row - iter_named() only exposes named TABLE_MAPS columns, so it is not available via
  dbc.iter_named("ChrSpecs") and is looked up from a parallel raw DBCFile pass keyed by
  id, the same pattern build_creatures.py uses for NPCTrainer's unmapped f3.
- ChrClassesRoles.roleMask is decoded into a role-name list (Tank/Healer/DPS) and
  specialAbilitySpellId is resolved to {spellId, name} via Spell.dbc; both are written
  into specs.json's top-level "roles"/"specialAbilities" dicts, keyed by className
  (all 32 ChrClasses names for roles; only the classes with a non-zero
  specialAbilitySpellId for specialAbilities).
- CharacterCreationArchetypes' weapon/armor-type slot columns drop
  "MAX_ITEM_SUBCLASS_*" enum-terminator sentinels (not real values). Each archetype's
  supported races are derived from CharacterCreationArchetypeDetails' proven
  archetypeId/raceId join, resolved to names via ChrRaces.dbc.

Task W4-11e (DATAMINE-REQUEST.md Sec 11 / Sec 13 item 20) added `tabStatus` to each
spec row. **Task W4-14 re-derived it against the LIVE talent builder and renamed
every state, because the old ones were misleading in exactly the way this dataset's
central bug is misleading**: the old `"live"` meant only "a CAD tab with this token
exists" - a statement about the CATALOG - and 93/101 specs carried it, including
Starcaller/TIDES, whose tree does not exist in game. The states are now named for
what they actually assert:

  inLiveBuilder  - this spec's tree IS in the live builder payload. `liveTab` names
                   it and `renamed` says whether the live name differs from the CAD
                   one, because CAD tab names and live tab names are DIFFERENT
                   GENERATIONS (Starcaller CAD "Tides" is live "Moon Priest").
  cadOnly        - the spec's tree exists ONLY in the CAD catalog; no live builder
                   tab maps to it. This is the state the old "live" was hiding.
  unreleased     - named by neither layer.
  noLiveGeometry - the class has a CAD tab layer but no builder capture at all (the
                   10 vanilla + Reborn classes) - liveness is NOT claimed.
  noCadClass     - the class has no data/classes/ directory at all (Hero, classId
                   10) - structural, not a content gap. (Was "noTabLayer".)

The CAD-tab -> live-tab mapping is NOT re-derived here: it is read from
`data/classes/_live_summary.json`'s `tabMapping` (written by build_classes.py, which
owns data/classes/ - Amendment D), where each pair carries its method and its
node-overlap evidence. The match ladder below deliberately tries ChrSpecs' `name`
BEFORE its `tabToken`, because `name` is the live-generation label and `tabToken` is
the catalog-generation one: Chronomancer spec 33 is named "Artificer" with tabToken
"TIME", and the live tab literally named "Time" is a DIFFERENT tree (spec 31,
tabToken "DISPLACEMENT") - token-first would have swapped them.

Consequence for Sec 11's "7 of 70 specs have no CAD tab": all 7 resolve now, and by
a MECHANISM rather than the pinned 5-token table W4-11e used - a spec's own `name`
matching a live builder tab covers VALKYR->Valkyrie and WITCHKNIGHT->Black Knight
(which no normalized token match reaches) and also closes the 2 W4-9 could not place
(Starcaller/HYDROMANCY is live tab "Warden", spec 45's own name; Cultist/BULWARK is
"Dreadnought", spec 96's) - the two "unmatchedExtraTabs" W4-9 recorded but could not
attribute. `unreleased` is consequently empty today; it stays a defined state so a
genuinely unshipped spec still lands somewhere honest.

Depends on `data/classes/_live_summary.json` + `data/talents/coa/_meta.json` already
existing - `build_dataset.py` runs `build_classes.build()` and
`build_coatalents.build()` BEFORE `build_classmeta.build()` (task W4-11e ordering,
still valid; see build_dataset.py's stage-order comments).
"""
import json
from collections import Counter, defaultdict

from tools import config, dbc


def _norm(s):
    import re
    return re.sub(r"[^a-z0-9]", "", (s or "").lower())


ARMOR_FLAGS = [("armorCloth", "Cloth"), ("armorLeather", "Leather"),
               ("armorMail", "Mail"), ("armorPlate", "Plate")]
ROLE_BITS = [(2, "Tank"), (4, "Healer"), (8, "DPS")]
MIN_CLASS_COVERAGE = 0.60


def _armor_type(r: dict):
    hits = [name for key, name in ARMOR_FLAGS if r[key] == 1]
    return hits[0] if len(hits) == 1 else None


def _class_roles_and_abilities() -> tuple[dict, dict]:
    """roles: {className: [role,...]} for all 32 ChrClasses (roleMask decoded).
    specialAbilities: {className: {spellId, name|null}} for only the classes with a
    proven non-zero specialAbilitySpellId (see tools/dbc.py's ChrClassesRoles proof)."""
    chr_names = {c["id"]: c["name_enUS"] for c in dbc.iter_named("ChrClasses")}
    spell_names = {s["id"]: s["name_enUS"] for s in dbc.iter_named("Spell")}
    roles, special = {}, {}
    for r in dbc.iter_named("ChrClassesRoles"):
        cls_name = chr_names.get(r["id"])
        if cls_name is None:
            continue
        mask = r["roleMask"]
        roles[cls_name] = [name for bit, name in ROLE_BITS if mask & bit]
        sid = r["specialAbilitySpellId"]
        if sid:
            special[cls_name] = {"spellId": sid, "name": spell_names.get(sid)}
    return roles, special


def _class_tab_layer(cdir) -> dict:
    """classId -> sorted CAD tab-name list (data/classes/<dir>/index.json's own
    `files[].tab` set), for every class that has a directory at all. A class with
    no data/classes/ entry (e.g. Hero, classId 10) is simply absent from this map.
    Vanilla and Reborn dirs share a classId (Druid/RebornDruid both resolve to 11),
    so the tab names are UNIONED rather than last-writer-wins - today the two agree
    exactly on every such pair, but a union cannot silently drop a tab if they ever
    diverge."""
    idx = json.loads((cdir / "index.json").read_text(encoding="utf-8"))
    out = defaultdict(set)
    for c in idx["classes"]:
        cid = c.get("classId")
        if cid is None:
            continue
        cidx_path = cdir / c["dir"] / "index.json"
        if not cidx_path.is_file():
            continue
        cidx = json.loads(cidx_path.read_text(encoding="utf-8"))
        out[cid].update(f["tab"] for f in cidx["files"] if f["tab"])
    return {cid: sorted(tabs) for cid, tabs in out.items()}


def _live_tab_layer() -> dict:
    """[Task W4-14] classId -> {"liveTabs": [names], "mapped": {cadTab: record}}
    read from data/classes/_live_summary.json's tabMapping (build_classes owns it;
    this module does not re-derive the mapping - see the module docstring). Absent
    for every class with no builder capture."""
    p = config.DATA_DIR / "classes" / "_live_summary.json"
    if not p.is_file():
        raise AssertionError(
            "data/classes/_live_summary.json missing - run build_classes.build() "
            "before build_classmeta.build() (task W4-14: specs.json's tabStatus is "
            "derived against the live builder mapping written there)")
    tm = json.loads(p.read_text(encoding="utf-8"))["tabMapping"]["byClass"]
    return {m["classId"]: {"liveTabs": m["liveTabs"],
                           "mapped": {r["cadTab"]: r for r in m["mapped"]}}
            for m in tm.values()}


def _tab_status(class_id, token, spec_name, tab_layer: dict, live_layer: dict) -> dict:
    """See the module docstring for the state names and why the ladder tries the
    spec's own `name` before its `tabToken`."""
    tabs = tab_layer.get(class_id)
    if tabs is None:
        return {"status": "noCadClass", "cadTab": None, "liveTab": None,
                "match": None, "renamed": None}
    cad_tab = next((t for t in tabs if _norm(t) == _norm(token)), None)

    live = live_layer.get(class_id)
    if live is None:
        if cad_tab is None:
            raise AssertionError(
                f"classId={class_id} token={token!r} matches no CAD tab and the class "
                "has no live builder capture either - new drift, needs investigation "
                "before this can be classified")
        return {"status": "noLiveGeometry", "cadTab": cad_tab, "liveTab": None,
                "match": "tabToken", "renamed": None}

    by_norm = {_norm(t): t for t in live["liveTabs"]}
    mapped = live["mapped"].get(cad_tab) if cad_tab else None

    live_tab = match = None
    if _norm(spec_name) in by_norm:              # live-generation label
        live_tab, match = by_norm[_norm(spec_name)], "specName"
    elif mapped is not None and mapped["liveTab"]:
        live_tab, match = mapped["liveTab"], "cadTabMapping:" + mapped["method"]
    elif _norm(token) in by_norm:                # catalog token that survived
        live_tab, match = by_norm[_norm(token)], "tabToken"

    if live_tab is not None:
        return {"status": "inLiveBuilder", "cadTab": cad_tab, "liveTab": live_tab,
                "match": match, "renamed": cad_tab is not None and cad_tab != live_tab}
    if cad_tab is not None:
        return {"status": "cadOnly", "cadTab": cad_tab, "liveTab": None,
                "match": "tabToken", "renamed": None}
    return {"status": "unreleased", "cadTab": None, "liveTab": None,
            "match": None, "renamed": None}


def build_specs() -> dict:
    cdir = config.DATA_DIR / "classes"
    tab_layer = _class_tab_layer(cdir)
    live_layer = _live_tab_layer()
    chr_classes = list(dbc.iter_named("ChrClasses"))
    by_norm = {_norm(c["name_enUS"]): c for c in chr_classes}
    # [Task W4-5] filename fallback join (see tools/dbc.py's ChrClasses TABLE_MAPS
    # comment for the golden evidence). All 24 of this table's previously-unmatched
    # classToken values (DEMONHUNTER x3, MONK x3, SONOFARUGAL x4, FLESHWARDEN x3,
    # PROPHET x4, WILDWALKER x4, SPIRITMAGE x3) are ChrClasses.filename tokens, not
    # display names - a fallback join on filename resolves every one of them
    # (re-derived: coverage 25/32 -> 32/32), closing DATAMINE-REQUEST.md Sec 11's
    # "specs.json is inconsistent... no classId-linked rows for Knight of Xoroth
    # (17), Venomancer (29), Primalist (31), Runemaster (32), DemonHunter, Monk or
    # SonOfArugal" finding at the join level (the deeper spec-NAMING disagreement
    # against the CAD tab layer that section also describes is Sec 13 item 20, out
    # of this task's scope - deliberately not touched here).
    by_filename = {_norm(c["filename"]): c for c in chr_classes}

    # f63 (disproven "role" candidate, see module docstring) isn't a named column -
    # read raw rows in parallel, keyed by id.
    raw = dbc.DBCFile(config.WORK_DBC_DIR / "ChrSpecs.dbc")
    f63_by_id = {row[0]: dbc.u32(row[63]) for row in raw.iter_rows()}

    specs = []
    per_class = defaultdict(list)
    matched_class_ids = set()
    for r in dbc.iter_named("ChrSpecs"):
        token = r["classToken"] or None
        cc = (by_norm.get(_norm(token)) or by_filename.get(_norm(token))) if token else None
        class_id = cc["id"] if cc else None
        class_name = cc["name_enUS"] if cc else None
        if class_id is not None:
            matched_class_ids.add(class_id)
            per_class[class_name].append(r["id"])

        tab_token = r["tabToken"] or None
        tab_status = (_tab_status(class_id, tab_token, r["name_enUS"],
                                  tab_layer, live_layer)
                      if class_id is not None and tab_token else None)

        specs.append({
            "id": r["id"],
            "name": r["name_enUS"],
            "classId": class_id,
            "className": class_name,
            "classToken": token,
            "tabToken": tab_token,
            "tabStatus": tab_status,
            "description": r["description_enUS"] or None,
            "armorType": _armor_type(r),
            "primaryStat": r["primaryStat"] or None,
            "secondaryStat": None if r["secondaryStat"] in ("None", "") else r["secondaryStat"],
            "difficulty": r["difficulty"] or None,
            "powerType": r["powerType"] or None,
            "secondaryPowerType": None if r["secondaryPowerType"] in ("NONE", "") else r["secondaryPowerType"],
            "f63": f63_by_id[r["id"]],
        })

    specs.sort(key=lambda s: s["id"])
    for ids in per_class.values():
        ids.sort()

    assert all(s["classId"] is None or 1 <= s["classId"] <= 32 for s in specs), \
        "a spec resolved to a classId outside 1..32 - mapping is wrong"
    coverage = len(matched_class_ids) / 32
    assert coverage >= MIN_CLASS_COVERAGE, (
        f"only {coverage:.1%} of the 32 ChrClasses have >=1 spec "
        f"(need >={MIN_CLASS_COVERAGE:.0%}) - mapping is wrong, stopping")

    roles, special_abilities = _class_roles_and_abilities()

    # [Task W4-14] tabStatus summary. `renamed` is broken out on purpose: it is the
    # count of specs whose live tree carries a DIFFERENT name from the CAD tab a
    # consumer would have found by browsing data/classes/ - the exact place the old
    # status="live" misled.
    status_counts = Counter(s["tabStatus"]["status"] for s in specs if s["tabStatus"])
    unreleased = sorted(
        (s["id"], s["className"], s["name"], s["tabToken"])
        for s in specs if s["tabStatus"] and s["tabStatus"]["status"] == "unreleased")
    renamed = sorted(
        (s["id"], s["className"], s["tabStatus"]["cadTab"], s["tabStatus"]["liveTab"])
        for s in specs if s["tabStatus"] and s["tabStatus"]["renamed"])
    cad_only = sorted(
        (s["id"], s["className"], s["tabStatus"]["cadTab"])
        for s in specs if s["tabStatus"] and s["tabStatus"]["status"] == "cadOnly")
    tab_status_summary = {
        "counts": dict(status_counts),
        "unreleased": unreleased,
        "cadOnly": cad_only,
        "renamedInLiveBuilder": renamed,
        "statusMeanings": {
            "inLiveBuilder": "this spec's tree is in the live builder payload "
                             "(liveTab names it; renamed=true means the CAD tab is "
                             "called something else)",
            "cadOnly": "the tree exists only in the CAD catalog - no live tab maps "
                       "to it",
            "unreleased": "named by neither layer",
            "noLiveGeometry": "class has a CAD tab layer but no builder capture - "
                              "liveness NOT claimed",
            "noCadClass": "class has no data/classes/ directory at all (structural)",
        },
        "renameNote": (
            f"{len(renamed)} of the {status_counts['inLiveBuilder']} inLiveBuilder "
            "specs have a live tree name DIFFERENT from their CAD tab name - CAD tab "
            "names and live tab names are different generations of the same tree "
            "slots (Starcaller CAD 'Tides' is live 'Moon Priest'). The mapping and "
            "its per-pair evidence live in data/classes/_live_summary.json's "
            "tabMapping."),
        "sec11Correction": (
            f"DATAMINE-REQUEST.md Sec 11 cited '7 of 70 specs have no CAD tab' "
            f"(presumably unreleased); task W4-9 found 5 of the 7 had shipped in the "
            f"live builder. Task W4-14 resolves all 7 by MECHANISM rather than a "
            f"pinned token table: a spec's own `name` is the live-generation label, "
            f"so VALKYR->Valkyrie, WITCHKNIGHT->Black Knight, HYDROMANCY->Warden and "
            f"BULWARK->Dreadnought all resolve by name against the live tab list "
            f"(the last two being W4-9's 'unmatchedExtraTabs', now attributed). "
            f"{len(unreleased)} specs remain unreleased by this re-derivation."
        ),
        "supersedes": (
            "task W4-11e's states (live/shippedExternal/unreleased/noTabLayer). "
            "'live' there meant only 'a CAD tab with this token exists' - a claim "
            "about the catalog, not the game - and covered 93/101 specs including "
            "Starcaller/TIDES, whose tree does not exist in game."),
    }

    payload = {
        "specs": specs, "perClass": dict(sorted(per_class.items())),
        "roles": dict(sorted(roles.items())),
        "specialAbilities": dict(sorted(special_abilities.items())),
        "tabStatusSummary": tab_status_summary,
    }
    (cdir / "specs.json").write_text(
        json.dumps(payload, ensure_ascii=False, indent=1, sort_keys=True), encoding="utf-8")

    return {
        "count": len(specs), "classesCovered": len(matched_class_ids),
        "coverage": round(coverage, 4),
        "byClassId": {cid: sorted(s["id"] for s in specs if s["classId"] == cid)
                      for cid in matched_class_ids},
        "tabStatusCounts": dict(status_counts),
    }


_WEAPON_KEYS = ("weaponType1", "weaponType2", "weaponType3")
_ARMOR_KEYS = ("armorType1", "armorType2", "armorType3")
_ABILITY_KEYS = ("abilityPreview1_enUS", "abilityPreview2_enUS", "abilityPreview3_enUS",
                 "abilityPreview4_enUS", "abilityPreview5_enUS")


def build_archetypes() -> dict:
    cdir = config.DATA_DIR / "classes"
    chr_races = {r["id"]: r["name_enUS"] for r in dbc.iter_named("ChrRaces")}

    races_by_archetype = defaultdict(set)
    for d in dbc.iter_named("CharacterCreationArchetypeDetails"):
        races_by_archetype[d["archetypeId"]].add(d["raceId"])

    archetypes = []
    for r in dbc.iter_named("CharacterCreationArchetypes"):
        weapon_types = [r[k] for k in _WEAPON_KEYS if r[k] and not r[k].startswith("MAX_")]
        armor_types = [r[k] for k in _ARMOR_KEYS if r[k] and not r[k].startswith("MAX_")]
        ability_previews = [r[k] for k in _ABILITY_KEYS if r[k]]
        race_ids = sorted(races_by_archetype.get(r["id"], ()))
        archetypes.append({
            "id": r["id"],
            "name": r["name_enUS"],
            "tagline": r["tagline_enUS"] or None,
            "description": r["description_enUS"] or None,
            "primaryStat": r["primaryStat"] or None,
            "weaponTypes": weapon_types,
            "armorTypes": armor_types,
            "iconToken": r["iconToken"] or None,
            "cinematicPath": r["cinematicPath"] or None,
            "abilityPreviews": ability_previews,
            "races": [chr_races.get(rid, f"race{rid}") for rid in race_ids],
        })
    archetypes.sort(key=lambda a: a["id"])

    names = {a["name"] for a in archetypes}
    assert "Naturalist" in names, "archetype name golden ('Naturalist') failed"

    payload = {"archetypes": archetypes}
    (cdir / "archetypes.json").write_text(
        json.dumps(payload, ensure_ascii=False, indent=1, sort_keys=True), encoding="utf-8")
    return {"count": len(archetypes)}


def build() -> dict:
    cdir = config.DATA_DIR / "classes"
    assert cdir.is_dir(), (
        "data/classes missing - run build_classes.build() before build_classmeta.build()")
    assert (config.DATA_DIR / "talents" / "coa" / "_meta.json").is_file(), (
        "data/talents/coa/_meta.json missing - run build_coatalents.build() before "
        "build_classmeta.build() (the CoA talent layer specs.json reconciles against)")
    assert (cdir / "_live_summary.json").is_file(), (
        "data/classes/_live_summary.json missing - run build_classes.build() before "
        "build_classmeta.build() (task W4-14: specs.json's tabStatus is derived "
        "against the live builder tab mapping written there)")
    spec_stats = build_specs()
    arch_stats = build_archetypes()
    return {"specs": spec_stats, "archetypes": arch_stats}


if __name__ == "__main__":
    from tools import build_classes, build_coatalents, build_spells
    build_spells.build()
    build_classes.build()
    build_coatalents.build()
    print(build())
