"""Task W4-3 gate: spell column completion for damage modeling
(coa-sim-handoff/DATAMINE-REQUEST.md Sec 1.2-1.4 + Sec 13 items 2-4).

Adds/re-derives: effectRealPointsPerLevel (f77-79), the 8 already-mapped-but-
dropped columns (Sec 1.3), effectSpellClassMask (f122-130), effectDamageMultiplier
(f216-218), spellFamilyFlags3 (f211), equippedItemSubClassMask/InventoryTypeMask
(f69-70), effectPointsPerComboPoint (f119-121), effectBonusMultiplier (f229-231,
emitted as bonusMultiplierStock), spellMissileID (f227), and data/spells/_coverage.json.

Every fill-rate figure below is independently RE-DERIVED against work/dbc/Spell.dbc
(never just copied from the source doc) over the "CoA class set" - every spell id
(incl. rank chains) referenced by the 21 coa-custom-tagged classes in data/classes/,
intersected with live Spell.dbc ids (build_spells._coa_class_spell_ids()). This
re-derivation reproduces the doc's own headline counts EXACTLY: 6,436 total ids /
6,038 resolved in base Spell.dbc (matches DATAMINE-REQUEST.md Sec 3's "base resolves
6,038/6,436" verbatim) - see .superpowers/sdd/task-w4-3-report.md for the full log.
"""
import json, sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from tools import config, dbc, build_spells

stats = build_spells.build()
sdir = config.DATA_DIR / "spells"
meta = json.loads((sdir / "_meta.json").read_text(encoding="utf-8"))
index = json.loads((sdir / "index.json").read_text(encoding="utf-8"))
coverage = json.loads((sdir / "_coverage.json").read_text(encoding="utf-8"))

# ---- v1 gate unchanged ----
assert stats["written"] == meta["count"] > 15000

# ---- load every record once, keep the goldens we need ----
golden_ids = {116, 133, 11069, 2061, 53385, 501229, 500038, 800856, 804535,
              17, 592, 600, 3747, 6065, 6066, 10898, 10899, 10900, 10901}
by_id = {}
for b in index["buckets"]:
    with open(sdir / b["file"], encoding="utf-8") as fh:
        for line in fh:
            r = json.loads(line)
            if r["id"] in golden_ids:
                by_id[r["id"]] = r
assert len(by_id) == len(golden_ids), sorted(golden_ids - set(by_id))

# =====================================================================
# Golden 1: stock Frostbolt (116) slot 2 - f78 float bit pattern (Sec 1.5 trap 3)
# =====================================================================
fb = by_id[116]
assert fb["name"] == "Frostbolt"
slot2 = next(e for e in fb["effects"] if e["slot"] == 2)
assert slot2["realPointsPerLevel"] == 0.5, slot2

# =====================================================================
# Golden 2: a ranked spell's per-level ramp - Power Word: Shield's own rank
# chain (17 -> 592 -> 600 -> 3747 -> 6065 -> 6066 -> 10898 -> 10899 -> 10900
# -> 10901), slot 1 realPointsPerLevel strictly increasing across ranks.
# =====================================================================
pws_ranks = [17, 592, 600, 3747, 6065, 6066, 10898, 10899, 10900, 10901]
ramp = []
for sid in pws_ranks:
    e1 = next(e for e in by_id[sid]["effects"] if e["slot"] == 1)
    ramp.append(e1["realPointsPerLevel"])
assert ramp == sorted(ramp) and ramp[0] < ramp[-1], ramp
assert ramp == [0.8, 1.2, 1.6, 2.0, 2.3, 2.6, 3.0, 3.4, 3.9, 4.3], ramp

# =====================================================================
# Golden 3: EffectSpellClassMask - Improved Fireball (11069, stock talent)
# slot 1 ADD_FLAT_MODIFIER classMask selects Fireball (133) by its own
# spellFamilyFlags1 bit - both spellFamilyName 3 (Mage), both bit 0 set.
# =====================================================================
impfb = by_id[11069]
e1 = next(e for e in impfb["effects"] if e["slot"] == 1)
assert e1["aura"]["name"] == "ADD_FLAT_MODIFIER"
assert e1["spellClassMask"] == [1, 0, 0], e1["spellClassMask"]
fireball = by_id[133]
assert fireball["name"] == "Fireball"
assert impfb["family"]["id"] == fireball["family"]["id"] == 3          # Mage
assert fireball["family"]["flags1"] & e1["spellClassMask"][0] == 1     # bit 0 overlap

# =====================================================================
# Golden 4: maxAffectedTargets - Divine Storm (53385), real WotLK 4-target cap
# =====================================================================
assert by_id[53385]["name"] == "Divine Storm"
assert by_id[53385]["maxAffectedTargets"] == 4

# =====================================================================
# Golden 5: EffectPointsPerComboPoint - Rage of Bethekk (501229) slot 1
# (a real SCHOOL_DAMAGE effect carrying the combo-scaling term, not a dead
# template slot - c.f. Serrated Shot 500073's slot 2, which carries a nonzero
# raw pointsPerComboPoint word but effect=0 there, so per this repo's existing
# "if not eff: continue" convention - already applied to every other effect-
# slot field, unchanged by this task - that dead slot is correctly dropped)
# =====================================================================
rob = by_id[501229]
assert rob["name"] == "Rage of Bethekk"
e1 = next(e for e in rob["effects"] if e["slot"] == 1)
assert e1["effect"]["name"] == "SCHOOL_DAMAGE"
assert e1["pointsPerComboPoint"] == 8.0, e1

# =====================================================================
# Golden 6: spellMissileID - Invigorating Surge, all 8 CoA-set occurrences
# share missile 9429 (matches the doc's "0.13% (8 spells)" exactly)
# =====================================================================
assert by_id[500038]["name"] == "Invigorating Surge"
assert by_id[500038]["missileId"] == 9429

# =====================================================================
# Golden 7: EffectBonusMultiplier (f229-231) emitted as bonusMultiplierStock,
# with the Sec 2 stock/Reborn-only contradiction warning - Flash Heal (2061)
# =====================================================================
fh = by_id[2061]
assert fh["name"] == "Flash Heal"
efh = next(e for e in fh["effects"] if e["slot"] == 1)
assert abs(efh["bonusMultiplierStock"] - 0.807) < 1e-6, efh

# =====================================================================
# Golden 8: the Sec 1.2 maxLevel-clamp warning's own cited examples -
# Decomposition (800856) and Ray of Rot (804535), rppl FROZEN below level 60
# =====================================================================
decomp = by_id[800856]
e1 = next(e for e in decomp["effects"] if e["slot"] == 1)
assert e1["basePoints"] == 12 and round(e1["realPointsPerLevel"], 2) == 0.11
assert decomp["levels"]["max"] == 12

ror = by_id[804535]
e1 = next(e for e in ror["effects"] if e["slot"] == 1)
assert e1["basePoints"] == 11 and round(e1["realPointsPerLevel"], 2) == 0.47
assert ror["levels"]["max"] == 26

# =====================================================================
# Sec 1.3: the 8 already-mapped-but-dropped columns are now emitted (spell-level,
# always present - never omitted, matching this record's existing top-level
# convention for scalar fields)
# =====================================================================
for sid in golden_ids:
    r = by_id[sid]
    for key in ("speed", "equippedItem", "maxAffectedTargets", "casterAuraSpell",
                "targetAuraSpell", "manaPerSecond", "targetCreatureType",
                "casterAuraState", "targetAuraState", "stancesNot", "missileId"):
        assert key in r, (sid, key)
    assert set(r["equippedItem"]) == {"itemClass", "subClassMask", "inventoryTypeMask"}
    assert "flags3" in r["family"]

# Frostbolt is a ranged missile spell - speed and equippedItemClass sentinel golden
# (doc's histogram: -1 x5547, 2 x461, 4 x30 on the CoA class set)
assert fb["speed"] == 28.0
assert fb["equippedItem"]["itemClass"] == -1          # "any weapon" sentinel, not 0

# =====================================================================
# _coverage.json: structural manifest - every TABLE_MAPS["Spell"] column gets
# {mapped, emitted, where}; unmapped-column count against the full 234 width
# =====================================================================
assert coverage["totalFields"] == 234
assert coverage["mappedColumns"] == 128
assert coverage["unmappedColumns"] == 234 - 128 == 106
assert coverage["mappedColumns"] + coverage["unmappedColumns"] == coverage["totalFields"]
assert coverage["emittedColumns"] + coverage["mappedNotEmittedColumns"] == coverage["mappedColumns"]

cols = coverage["columns"]
for name in ("effectRealPointsPerLevel1", "effectRealPointsPerLevel2", "effectRealPointsPerLevel3",
             "effectSpellClassMaskA1", "effectSpellClassMaskB2", "effectSpellClassMaskC3",
             "spellFamilyFlags3", "equippedItemSubClassMask", "equippedItemInventoryTypeMask",
             "effectPointsPerComboPoint1", "effectDamageMultiplier2", "effectBonusMultiplier3",
             "spellMissileID"):
    assert cols[name]["mapped"] is True and cols[name]["emitted"] is True, name

# the doc's confirmed zero-fill skip list stays mapped-but-not-emitted (Sec 1.4)
for name in ("manaCostPerLevel", "maxTargetLevel", "spellDifficultyID"):
    assert cols[name]["mapped"] is True and cols[name]["emitted"] is False, name

# _meta.json carries the same summary
assert meta["columnCoverage"]["file"] == "_coverage.json"
assert meta["columnCoverage"]["mappedColumns"] == 128

# =====================================================================
# Fill-rate re-derivation: every new/re-emitted column's CoA-set fill rate is
# independently recomputed here (not copied from the doc) and checked within
# the task's +/-3pp tolerance of the doc's cited figures. This ALSO
# re-verifies the zero-fill skip list is genuinely zero before it is skipped.
# =====================================================================
coa_ids = build_spells._coa_class_spell_ids()
assert len(coa_ids) == 6436, len(coa_ids)              # exact match to Sec 3's "6,436-id CoA class set"
# This set is deliberately NOT "every id in data/classes": rank chains are taken
# only from spells with a base Spell.dbc row, which is what makes both numbers
# below reproduce the doc exactly. data/classes/ carries 354 more chain ids since
# build_classes stopped dropping the chains of unresolved spells - widening the
# scope moves 6436 -> 6790 and 6038 -> 6055. See _coa_class_spell_ids' docstring.
assert 802012 in coa_ids        # the CAD row references it, so it is in the set
assert 501380 not in coa_ids    # but its chain hangs off a spell with no Spell.dbc row

f = dbc.DBCFile(config.WORK_DBC_DIR / "Spell.dbc")
rows = {dbc.u32(row[0]): row for row in f.iter_rows()}
resolved = [sid for sid in coa_ids if sid in rows]
assert len(resolved) == 6038, len(resolved)             # exact match to Sec 3's "base resolves 6,038/6,436"
n = len(resolved)


def fill_rate(idxs):
    hit = sum(1 for sid in resolved if any(rows[sid][i] != 0 for i in idxs))
    return hit / n


TOLERANCE = 0.03  # +/- 3 percentage points, per this task's binding rule

for idxs, doc_pct, label in [
    ((77, 78, 79), 0.3332, "effectRealPointsPerLevel"),
    (list(range(122, 131)), 0.2862, "effectSpellClassMask"),
    ((211,), 0.1209, "spellFamilyFlags3"),
    ((69,), 0.1216, "equippedItemSubClassMask"),
    ((70,), 0.0144, "equippedItemInventoryTypeMask"),
    ((119, 120, 121), 0.0033, "effectPointsPerComboPoint"),
    ((227,), 0.0013, "spellMissileID"),
    ((229, 230, 231), 0.1025, "effectBonusMultiplier"),
    ((47,), 0.1090, "speed"),
    ((212,), 0.1197, "maxAffectedTargets"),
    ((24, 25), 0.1033, "casterAuraSpell/targetAuraSpell"),
    ((44,), 0.0033, "manaPerSecond"),
]:
    measured = fill_rate(idxs)
    assert abs(measured - doc_pct) <= TOLERANCE, (label, measured, doc_pct)

# f227 golden count: exactly 8 spells, matching the doc's literal "(8 spells)"
assert sum(1 for sid in resolved if rows[sid][227] != 0) == 8

# equippedItemClass (f68) non-default histogram - doc's exact per-value counts
# (f68 is decoded signed - see TABLE_MAPS - so -1 stays -1, not a huge u32)
import collections
hist = collections.Counter(rows[sid][68] for sid in resolved)
assert hist[-1] == 5547 and hist[2] == 461 and hist[4] == 30, hist.most_common(5)

# zero-fill skip list: confirmed genuinely zero on the CoA class set before skipping
for idx in (207, 43, 18, 228, 224, 233):
    assert all(rows[sid][idx] == 0 for sid in resolved), idx

print("ALL PASS")
