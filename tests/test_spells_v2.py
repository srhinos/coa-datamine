"""Task V2-4 gate: spells.jsonl v2 enrichment (tags/customAttr/descriptionVariables/
category/addon/overrideData) built from SpellTags+SpellTagTypes, SpellCustomAttr,
SpellDescriptionVariables, SpellCategory, SpellAddon and OverrideSpellData - all
proven via golden records (see .superpowers/sdd/task-v2-4-report.md). SpellTags
dedup is intentional (a display-name list, not a tagTypeId list) and pinned here.
SpellAlternativePowerType is proven internally but no per-spell link is provable,
so it's documented in _meta only. SpellCharges/SpellChargesCategory are proven
internally too, but SpellCharges' link to Spell.dbc rows misses the brief's >=90%
attach bar, so per the brief's fallback they ship curated STANDALONE at
data/spells/charges.json instead of attaching to any spell record (both asserted
here). v1 gates (line counts, sort/unique, missing-ref reporting) are re-verified so
this task cannot silently regress test_spells.py's contract."""
import json, sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from tools import config
from tools import build_spells

stats = build_spells.build()
sdir = config.DATA_DIR / "spells"
meta = json.loads((sdir / "_meta.json").read_text(encoding="utf-8"))
index = json.loads((sdir / "index.json").read_text(encoding="utf-8"))

# ---- v1 gates unchanged ----
assert stats["written"] == meta["count"] > 15000
assert index["count"] == meta["count"]
assert meta["schemaVersion"] == 2

# ---- read every record once: golden lookup + omit-when-absent + line/order checks ----
golden_ids = {10, 17, 331, 86543}
by_id = {}
no_tags_seen = no_addon_seen = no_override_seen = False
total = 0
for b in index["buckets"]:
    with open(sdir / b["file"], encoding="utf-8") as fh:
        lines = fh.readlines()
    assert len(lines) == b["count"]
    prev = -1
    for line in lines:
        r = json.loads(line)
        assert r["id"] > prev, "not sorted within bucket"
        prev = r["id"]
        total += 1
        if r["id"] in golden_ids:
            by_id[r["id"]] = r
        if "tags" not in r:
            no_tags_seen = True
        if "addon" not in r:
            no_addon_seen = True
        if "overrideData" not in r:
            no_override_seen = True
assert total == meta["count"]

# enrichment fields are added ONLY where data exists - never null-noise on every record
assert no_tags_seen and no_addon_seen and no_override_seen

# ---- golden: spell 17 Power Word: Shield - tags (SpellTags/SpellTagTypes) + category ----
pws = by_id[17]
assert pws["name"] == "Power Word: Shield"
for expect in ("Priest", "Discipline", "Holy", "Healer", "Absorb", "Magic", "Instant Cast"):
    assert expect in pws["tags"], (expect, pws["tags"])
assert pws["tags"] == sorted(pws["tags"]), "tags must be sorted for determinism"
# spell 17 carries TWO SpellTags rows that both decode to "Priest" (a "Class: Priest"
# tagTypeId and a "Specialization: Priest" tagTypeId) - _spell_tags dedups by display
# name on purpose (tags is a name list, not a tagTypeId list); pin that behavior here.
assert pws["tags"].count("Priest") == 1, pws["tags"]
assert pws["category"] == 1269

# ---- golden: spell 10 Blizzard - descriptionVariables + customAttr ----
bliz = by_id[10]
assert bliz["name"] == "Blizzard"
assert bliz["descriptionVariables"].startswith("$arctic1=")
assert bliz["customAttr"] == [3, 0, 0, 524288, 0, 0, 0, 0, 0, 0]
assert len(bliz["customAttr"]) == 10

# ---- golden: spell 331 Healing Wave - overrideData (OverrideSpellData) ----
hw = by_id[331]
assert hw["name"] == "Healing Wave"
assert hw["overrideData"]["spells"] == [992822, 992824]
assert hw["overrideData"]["raw"] == 4

# ---- golden: spell 86543 Cauterizing Fire - addon (SpellAddon, spellId proven at f1) ----
cf = by_id[86543]
assert cf["name"] == "Cauterizing Fire"
assert len(cf["addon"]["raw"]) == 22
assert cf["addon"]["raw"][0] == 5   # SpellAddon's own row id (f0), unproven but carried raw

# ---- enrichment coverage counts reported in _meta.json (per-field, per the brief) ----
cov = meta["enrichment"]
assert cov["tags"] > 20000
assert cov["customAttr"] > 5000
assert cov["descriptionVariables"] > 1000
assert cov["category"] > 5000
assert cov["addon"] > 100
assert cov["overrideData"] > 0

# ---- SpellCharges/SpellChargesCategory: linkage proven, Spell.dbc join < brief's 90%
# bar -> per the brief's fallback, shipped curated STANDALONE (charges.json), NOT
# attached to any spell record ----
assert cov["charges"]["attached"] is False
assert cov["charges"]["spellIdJoinRate"] < 0.90
assert cov["charges"]["categoryLinkJoinRate"] == 1.0
assert cov["charges"]["file"] == "charges.json"

charges_doc = json.loads((sdir / "charges.json").read_text(encoding="utf-8"))
assert set(charges_doc) == {"_note", "categories", "charges"}
assert "below the 90% attach bar" in charges_doc["_note"]
assert len(charges_doc["charges"]) == cov["charges"]["recordCount"] == 401
assert len(charges_doc["categories"]) == cov["charges"]["categoryRecordCount"] == 105
# deterministic ascending order by "ref"
refs = [c["ref"] for c in charges_doc["charges"]]
assert refs == sorted(refs) and len(set(refs)) == len(refs)
# every charges row has a categoryId key into "categories" (proven 100% link)
for c in charges_doc["charges"]:
    assert str(c["categoryId"]) in charges_doc["categories"]
# spot-check: spell 52 "Overcharged: Manaforge Coruu" is a resolved golden from the
# report's semantic-corroboration sample (mentions "charge" in its own tooltip text)
spot = next(c for c in charges_doc["charges"] if c["ref"] == 52)
assert spot["resolvedSpellName"] == "Overcharged: Manaforge Coruu"
# and at least one row legitimately fails to resolve (the 87.78% finding, not 100%)
assert any(c["resolvedSpellName"] is None for c in charges_doc["charges"])

# ---- SpellAlternativePowerType: hypothesis (negative Spell.powerType indexes this
# table) disproven - powerType==-2 is the pre-existing "Health" sentinel, unrelated ----
assert cov["alternativePowerType"]["attached"] is False

# ---- spells.jsonl still parseable/sorted/unique, line count == _meta count (v1 gate) ----
by_id_all = {}
for b in index["buckets"]:
    with open(sdir / b["file"], encoding="utf-8") as fh:
        for line in fh:
            r = json.loads(line)
            assert r["id"] not in by_id_all, "duplicate id"
            by_id_all[r["id"]] = r
assert len(by_id_all) == meta["count"]

print("ALL PASS")
