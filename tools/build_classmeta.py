"""Class/spec metadata pack (task V2-3): ChrSpecs -> data/classes/specs.json,
CharacterCreationArchetypes(+ArchetypeDetails) -> data/classes/archetypes.json, and
specIds/roles enrichment on the data/classes/index.json produced by build_classes.py.

Must run after build_classes.build() - reads and rewrites data/classes/index.json in
place rather than owning it, since this task only adds tools/build_classmeta.py and
does not modify tools/build_classes.py.

Full mapping evidence (golden probes, join-rates, disproven hypotheses) is documented
in tools/dbc.py's TABLE_MAPS comments for ChrSpecs/ChrClassesRoles/CharacterCreation*
and in .superpowers/sdd/task-v2-3-report.md. Summary of what this module derives on
top of the raw named columns:

- ChrSpecs.classToken (a string, not a raw int) is joined against ChrClasses.name_enUS
  (normalized) to resolve classId/className; 27/101 specs have no match (either an
  empty token or a real token for a class outside the 32-row ChrClasses ground truth,
  e.g. DEMONHUNTER/MONK/PROPHET) and ship classId=None/className=None per the brief's
  gate.
- ChrSpecs' 4 armor-flag columns (armorCloth/armorLeather/armorMail/armorPlate) are
  combined into one "armorType" string (None when zero or more than one flag is set).
- ChrSpecs.f63 (the brief's disproven "role" candidate) is read directly off the raw
  row - iter_named() only exposes named TABLE_MAPS columns, so it is not available via
  dbc.iter_named("ChrSpecs") and is looked up from a parallel raw DBCFile pass keyed by
  id, the same pattern build_creatures.py uses for NPCTrainer's unmapped f3.
- ChrClassesRoles.roleMask is decoded into a role-name list (Tank/Healer/DPS) and
  specialAbilitySpellId is resolved to {id, name} via Spell.dbc; both attach to each
  data/classes/index.json "chrClasses" entry (already keyed 1:1 by classId).
- CharacterCreationArchetypes' weapon/armor-type slot columns drop
  "MAX_ITEM_SUBCLASS_*" enum-terminator sentinels (not real values). Each archetype's
  supported races are derived from CharacterCreationArchetypeDetails' proven
  archetypeId/raceId join, resolved to names via ChrRaces.dbc.
"""
import json
from collections import defaultdict

from tools import config, dbc, sharding


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


def build_specs() -> dict:
    cdir = config.DATA_DIR / "classes"
    chr_classes = list(dbc.iter_named("ChrClasses"))
    by_norm = {_norm(c["name_enUS"]): c for c in chr_classes}

    # f63 (disproven "role" candidate, see module docstring) isn't a named column -
    # read raw rows in parallel, keyed by id.
    raw = dbc.DBCFile(config.WORK_DBC_DIR / "ChrSpecs.dbc")
    f63_by_id = {row[0]: dbc.u32(row[63]) for row in raw.iter_rows()}

    specs = []
    per_class = defaultdict(list)
    matched_class_ids = set()
    for r in dbc.iter_named("ChrSpecs"):
        token = r["classToken"] or None
        cc = by_norm.get(_norm(token)) if token else None
        class_id = cc["id"] if cc else None
        class_name = cc["name_enUS"] if cc else None
        if class_id is not None:
            matched_class_ids.add(class_id)
            per_class[class_name].append(r["id"])

        specs.append({
            "id": r["id"],
            "name": r["name_enUS"],
            "classId": class_id,
            "className": class_name,
            "classToken": token,
            "tabToken": r["tabToken"] or None,
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

    payload = {"specs": specs, "perClass": dict(sorted(per_class.items()))}
    (cdir / "specs.json").write_text(
        json.dumps(payload, ensure_ascii=False, indent=1, sort_keys=True), encoding="utf-8")

    return {
        "count": len(specs), "classesCovered": len(matched_class_ids),
        "coverage": round(coverage, 4),
        "byClassId": {cid: sorted(s["id"] for s in specs if s["classId"] == cid)
                      for cid in matched_class_ids},
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


def _class_roles() -> dict:
    spell_names = {s["id"]: s["name_enUS"] for s in dbc.iter_named("Spell")}
    roles = {}
    for r in dbc.iter_named("ChrClassesRoles"):
        mask = r["roleMask"]
        sid = r["specialAbilitySpellId"]
        roles[r["id"]] = {
            "roles": [name for bit, name in ROLE_BITS if mask & bit],
            "specialAbility": {"id": sid, "name": spell_names.get(sid)} if sid else None,
        }
    return roles


def _enrich_class_index(spec_stats: dict) -> None:
    cdir = config.DATA_DIR / "classes"
    index_path = cdir / "index.json"
    index = json.loads(index_path.read_text(encoding="utf-8"))

    by_class_id = spec_stats["byClassId"]
    for c in index["classes"]:
        cid = c.get("classId")
        c["specIds"] = by_class_id.get(cid, []) if cid is not None else []

    roles = _class_roles()
    for c in index["chrClasses"]:
        info = roles.get(c["id"], {"roles": [], "specialAbility": None})
        c["roles"] = info["roles"]
        c["specialAbility"] = info["specialAbility"]

    index_path.write_text(sharding.dump_manifest(index), encoding="utf-8")


def build() -> dict:
    cdir = config.DATA_DIR / "classes"
    assert (cdir / "index.json").is_file(), (
        "data/classes/index.json missing - run build_classes.build() before "
        "build_classmeta.build()")
    spec_stats = build_specs()
    arch_stats = build_archetypes()
    _enrich_class_index(spec_stats)
    return {"specs": spec_stats, "archetypes": arch_stats}


if __name__ == "__main__":
    from tools import build_classes
    build_classes.build()
    print(build())
