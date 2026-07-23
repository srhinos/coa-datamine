"""TDD gate for task V2-3: class/spec metadata pack (ChrSpecs -> specs.json,
CharacterCreationArchetypes(+Details) -> archetypes.json, data/classes/index.json
specIds/roles enrichment).

Per the empirical-mapping rule, this also pins the NEGATIVE findings documented in
.superpowers/sdd/task-v2-3-report.md and tools/dbc.py's TABLE_MAPS comments: ChrSpecs'
low-cardinality "role" candidate (f63) was probed against Tank/Healer/DPS semantics and
against "ordinal spec position" and DISPROVEN both ways - it ships raw as f63, not a
named "role" field."""
import json, sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from tools import config
from tools import build_classes, build_classmeta

build_classes.build()
stats = build_classmeta.build()

cdir = config.DATA_DIR / "classes"

# ---- specs.json ----
specs_doc = json.loads((cdir / "specs.json").read_text(encoding="utf-8"))
specs = specs_doc["specs"]
per_class = specs_doc["perClass"]
by_id = {s["id"]: s for s in specs}

assert len(specs) == 101, len(specs)
assert [s["id"] for s in specs] == sorted(s["id"] for s in specs), "not sorted by id"

# gate: every spec classId in 1..32 or null
for s in specs:
    assert s["classId"] is None or 1 <= s["classId"] <= 32, s

# gate: >=60% of the 32 ChrClasses have >=1 spec
matched_class_ids = {s["classId"] for s in specs if s["classId"] is not None}
coverage = len(matched_class_ids) / 32
assert coverage >= 0.60, f"only {coverage:.1%} of ChrClasses have a spec - mapping is wrong"

# goldens: spec DISPLAY name column (f29), verified against known CoA/vanilla spec names
assert by_id[87]["name"] == "Frost" and by_id[87]["classId"] == 8 and by_id[87]["className"] == "Mage"
assert by_id[85]["name"] == "Arcane" and by_id[85]["classId"] == 8
assert by_id[86]["name"] == "Fire" and by_id[86]["classId"] == 8
assert by_id[76]["name"] == "Discipline" and by_id[76]["classId"] == 5  # Priest
assert by_id[88]["name"] == "Affliction" and by_id[88]["classId"] == 9  # Warlock
assert by_id[100]["classId"] == 26 and by_id[100]["classToken"] == "STARCALLER"  # custom

# armorType golden: matches real WoW class armor proficiency for matched classes
assert by_id[64]["armorType"] == "Plate"     # Warrior Arms
assert by_id[85]["armorType"] == "Cloth"     # Mage Arcane
assert by_id[73]["armorType"] == "Leather"   # Rogue Assassination
assert by_id[70]["armorType"] == "Mail"      # Hunter Beast Mastery

# unmatched class token (DemonHunter is not one of the 32 ChrClasses ground-truth rows)
assert by_id[7]["classId"] is None and by_id[7]["className"] is None
assert by_id[7]["classToken"] == "DEMONHUNTER"

# f63 shipped raw (role hypothesis disproven - see report/tools/dbc.py comments)
assert set(by_id[k]["f63"] for k in by_id) <= {1, 2, 3}

# perClass groups agree with specs' own classId, and are sorted
for cls_name, ids in per_class.items():
    assert ids == sorted(ids)
    for sid in ids:
        assert by_id[sid]["className"] == cls_name
assert per_class["Mage"] == sorted(s["id"] for s in specs if s["className"] == "Mage")

# ---- archetypes.json ----
arch_doc = json.loads((cdir / "archetypes.json").read_text(encoding="utf-8"))
archetypes = arch_doc["archetypes"]
assert len(archetypes) == 56, len(archetypes)
names = {a["name"] for a in archetypes}
assert "Naturalist" in names, "archetype name golden failed"
by_name = {a["name"]: a for a in archetypes}
naturalist = by_name["Naturalist"]
assert naturalist["cinematicPath"] == "Interface\\Cinematics\\Naturalist.avi"
assert isinstance(naturalist["weaponTypes"], list) and isinstance(naturalist["armorTypes"], list)
for a in archetypes:
    assert not any(t.startswith("MAX_") for t in a["weaponTypes"] + a["armorTypes"]), \
        "enum-max sentinel leaked into curated output"
    assert isinstance(a["races"], list)
assert any(a["races"] for a in archetypes), "no archetype resolved any race via the FK join"

# ---- data/classes/index.json enrichment: specIds + chrClasses roles ----
index = json.loads((cdir / "index.json").read_text(encoding="utf-8"))
by_class_entry = {c["name"]: c for c in index["classes"]}
assert "specIds" in by_class_entry["Mage"]
assert by_class_entry["Mage"]["specIds"] == per_class["Mage"]
assert by_class_entry["Mage"]["specIds"] == [85, 86, 87]
# a class dir with no ChrClasses match still gets the key, empty
assert by_class_entry["DemonHunter"]["classId"] is None
assert by_class_entry["DemonHunter"]["specIds"] == []

chr_by_id = {c["id"]: c for c in index["chrClasses"]}
assert set(chr_by_id[1]["roles"]) == {"DPS", "Tank"}          # Warrior
assert set(chr_by_id[5]["roles"]) == {"DPS", "Healer"}         # Priest
assert set(chr_by_id[2]["roles"]) == {"DPS", "Tank", "Healer"} # Paladin
assert chr_by_id[8]["roles"] == ["DPS"]                        # Mage
assert chr_by_id[1]["specialAbility"] is None
sham = chr_by_id[7]  # Shaman - has a proven specialAbilitySpellId
assert sham["specialAbility"] == {"id": 1182001, "name": "Earthen Guardian"}

# ---- stats sanity ----
assert stats["specs"]["count"] == 101
assert stats["specs"]["classesCovered"] == len(matched_class_ids)
assert stats["archetypes"]["count"] == 56

print("ALL PASS")
