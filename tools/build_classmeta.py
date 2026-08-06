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
"""
import json
from collections import defaultdict

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


def build_specs() -> dict:
    cdir = config.DATA_DIR / "classes"
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

    roles, special_abilities = _class_roles_and_abilities()
    payload = {
        "specs": specs, "perClass": dict(sorted(per_class.items())),
        "roles": dict(sorted(roles.items())),
        "specialAbilities": dict(sorted(special_abilities.items())),
    }
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


def build() -> dict:
    cdir = config.DATA_DIR / "classes"
    assert cdir.is_dir(), (
        "data/classes missing - run build_classes.build() before build_classmeta.build()")
    spec_stats = build_specs()
    arch_stats = build_archetypes()
    return {"specs": spec_stats, "archetypes": arch_stats}


if __name__ == "__main__":
    from tools import build_classes
    build_classes.build()
    print(build())
