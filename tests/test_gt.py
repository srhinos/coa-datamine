"""Task W4-2 gate: gt* combat-rating/regen tables (coa-sim-handoff/DATAMINE-REQUEST.md
Sec 1.1 + Sec 13 item 1) -> data/gt/.

RE-DERIVES (not trusts) the five layout goldens DATAMINE-REQUEST.md cites, fresh against
this machine's live work/dbc/gt*.dbc snapshot at test time - a future client patch that
silently reshuffles a gt table's layout fails this file loudly. Reproduces >=3 of the 5
(actually reproduces 4 of 5 plus the CoA archetype-clone bonus check and the level-100-slot
trap at 3 boundaries): level-80 combat-rating constants (13/14 exact), spell-crit
166.67@80/80.00@70 + Warrior/Rogue/DeathKnight=0, melee-crit 83.33/62.50/52.08@80, and the
*Base tables' exact 32-row count. Also pins the ARMOR_PENETRATION anomaly (11.55 vs
published 15.39) and asserts every curated curve is exactly 99 values long (levels 1-99
only - the level-100-slot trap)."""
import json, sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from tools import config, dbc, build_gt

MAX_LINES = 5000

stats = build_gt.build()
gdir = config.DATA_DIR / "gt"


def _line_count(p):
    return sum(1 for _ in open(p, encoding="utf-8"))


# ================= raw DBC-level layout re-derivation (independent of build_gt.py) =================

def _load(name):
    f = dbc.DBCFile(config.WORK_DBC_DIR / f"{name}.dbc")
    return [dbc.f32(row[0]) for row in f.iter_rows()], f.records


def _class_block(vals, class_id):
    return vals[(class_id - 1) * 100:class_id * 100]


def _cr_block(vals, cr):
    return vals[cr * 100:(cr + 1) * 100]


# ---- golden 1: gtCombatRatings level-80 constants, 13/14 exact under class-major-as-
# rating-major, 0/14 under the transposed reading (RE-DERIVED, not asserted from the doc) ----
cr_vals, cr_n = _load("gtCombatRatings")
assert cr_n == 3200, cr_n
L80_GOLDENS = {
    1: 4.9185, 2: 45.2502, 3: 45.2502, 5: 32.79, 6: 32.79, 7: 26.232,
    8: 45.906, 9: 45.906, 10: 45.906, 17: 32.79, 18: 32.79, 19: 32.79, 23: 8.1975,
}
matched = sum(1 for cr, exp in L80_GOLDENS.items()
              if abs(_cr_block(cr_vals, cr)[79] - exp) < 1e-3)
assert matched == 13, matched
# the transposed (level-major) reading must fail all of them - proves the ordering, not
# just that SOME slot happens to carry the right number
transposed_matched = sum(
    1 for cr, exp in L80_GOLDENS.items()
    if abs(cr_vals[79 * 32 + cr] - exp) < 1e-3 if 79 * 32 + cr < len(cr_vals))
assert transposed_matched == 0, transposed_matched
# ARMOR_PENETRATION (cr24): the documented anomaly, not a layout failure
assert abs(_cr_block(cr_vals, 24)[79] - 11.55) < 1e-3
assert abs(_cr_block(cr_vals, 24)[79] - 15.39) > 1.0   # must NOT match the published figure
assert abs(_cr_block(cr_vals, 24)[59] - 4.20) < 1e-3

# ---- golden 2: gtChanceToSpellCrit 166.67@80 / 80.00@70, Warrior/Rogue/DeathKnight=0 ----
sc_vals, sc_n = _load("gtChanceToSpellCrit")
assert sc_n == 3200, sc_n
for cid in (1, 4, 6):  # Warrior, Rogue, DeathKnight
    assert all(v == 0.0 for v in _class_block(sc_vals, cid)), cid
for cid in (2, 3, 5, 7, 8, 9, 10):  # Paladin/Hunter/Priest/Shaman/Mage/Warlock/Hero
    block = _class_block(sc_vals, cid)
    assert abs(round(1.0 / block[79] / 100.0, 2) - 166.67) < 0.01, (cid, block[79])
    assert abs(round(1.0 / block[69] / 100.0, 2) - 80.00) < 0.01, (cid, block[69])

# ---- golden 3: gtChanceToMeleeCrit 83.33/62.50/52.08 agi/1% @80 (Hunter/Warrior/Paladin) ----
mc_vals, mc_n = _load("gtChanceToMeleeCrit")
assert mc_n == 3200, mc_n
assert abs(round(1.0 / _class_block(mc_vals, 3)[79] / 100.0, 2) - 83.33) < 0.01   # Hunter
assert abs(round(1.0 / _class_block(mc_vals, 1)[79] / 100.0, 2) - 62.50) < 0.01   # Warrior
assert abs(round(1.0 / _class_block(mc_vals, 2)[79] / 100.0, 2) - 52.08) < 0.01   # Paladin

# ---- golden 4: *Base tables have exactly 32 rows ----
_, mcb_n = _load("gtChanceToMeleeCritBase")
_, scb_n = _load("gtChanceToSpellCritBase")
assert mcb_n == 32, mcb_n
assert scb_n == 32, scb_n

# ---- bonus: level-100-slot trap, 3 fresh block boundaries, exact float equality ----
for a, b in ((0, 1), (1, 2), (15, 16)):
    assert _cr_block(cr_vals, a)[99] == _cr_block(cr_vals, b)[0]

# ---- bonus: CoA archetype-clone spot check - Necromancer/Warlock bit-identical raw floats ----
assert _class_block(mc_vals, 9) == _class_block(mc_vals, 23)   # Warlock == Necromancer


# ================= curated data/gt/ output =================

# ---- combatRatings.json ----
cr_doc = json.loads((gdir / "combatRatings.json").read_text(encoding="utf-8"))
assert len(cr_doc["ratings"]) == 32
assert _line_count(gdir / "combatRatings.json") <= MAX_LINES
by_index = {r["index"]: r for r in cr_doc["ratings"]}
assert set(by_index) == set(range(32))
for r in cr_doc["ratings"]:
    assert len(r["curve"]) == 99, (r["index"], len(r["curve"]))   # level-100-slot exclusion

NAMED_CR = {
    0: "WEAPON_SKILL", 1: "DEFENSE", 2: "DODGE", 3: "PARRY", 4: "BLOCK",
    5: "HIT_MELEE", 6: "HIT_RANGED", 7: "HIT_SPELL",
    8: "CRIT_MELEE", 9: "CRIT_RANGED", 10: "CRIT_SPELL",
    17: "HASTE_MELEE", 18: "HASTE_RANGED", 19: "HASTE_SPELL",
    23: "EXPERTISE", 24: "ARMOR_PENETRATION",
}
for idx, name in NAMED_CR.items():
    assert by_index[idx]["name"] == name, (idx, by_index[idx]["name"])
UNNAMED_CR = set(range(32)) - set(NAMED_CR)
for idx in UNNAMED_CR:
    assert by_index[idx]["name"] == f"cr{idx}", (idx, by_index[idx]["name"])
# RESILIENCE explicitly must NOT be pinned anywhere (see module docstring / dbc.py comment)
assert "RESILIENCE" not in {r["name"] for r in cr_doc["ratings"]}
# curve values match the level-60/70/80 goldens exactly (index 59/69/79 = level 60/70/80)
assert abs(by_index[1]["curve"][59] - 1.50) < 1e-3      # DEFENSE
assert abs(by_index[2]["curve"][79] - 45.2502) < 1e-3   # DODGE
assert abs(by_index[8]["curve"][79] - 45.906) < 1e-3    # CRIT_MELEE
assert abs(by_index[24]["curve"][79] - 11.55) < 1e-3    # ARMOR_PENETRATION (the anomaly)

# ---- classChanceCurves.json ----
cc_doc = json.loads((gdir / "classChanceCurves.json").read_text(encoding="utf-8"))
assert _line_count(gdir / "classChanceCurves.json") <= MAX_LINES
CURVE_TABLES = {"meleeCrit", "spellCrit", "regenMPPerSpt", "octRegenMP",
                "regenHPPerSpt", "octRegenHP"}
BASE_TABLES = {"meleeCritBase", "spellCritBase"}
assert set(cc_doc) == CURVE_TABLES | BASE_TABLES
for key in CURVE_TABLES:
    recs = cc_doc[key]
    assert len(recs) == 32, (key, len(recs))
    assert {r["classId"] for r in recs} == set(range(1, 33))
    for r in recs:
        assert len(r["curve"]) == 99, (key, r["classId"], len(r["curve"]))
for key in BASE_TABLES:
    recs = cc_doc[key]
    assert len(recs) == 32, (key, len(recs))
    assert {r["classId"] for r in recs} == set(range(1, 33))
    for r in recs:
        assert "value" in r and "curve" not in r

# the brief's required archetype-clone spot check, at the curated-output layer
melee_by_class = {r["classId"]: r["curve"] for r in cc_doc["meleeCrit"]}
assert melee_by_class[9] == melee_by_class[23], "Necromancer/Warlock curated curves differ"
melee_base_by_class = {r["classId"]: r["value"] for r in cc_doc["meleeCritBase"]}
assert melee_base_by_class[9] == melee_base_by_class[23]
assert abs(melee_base_by_class[1] * 100 - 1.189) < 0.01   # Warrior base crit %, from the clone table

# pure-physical classes read exactly 0 spell crit at every curated level
spell_by_class = {r["classId"]: r["curve"] for r in cc_doc["spellCrit"]}
for cid in (1, 4, 6, 12, 18):   # Warrior/Rogue/DeathKnight/Barbarian/Guardian
    assert all(v == 0.0 for v in spell_by_class[cid]), cid

# ---- level60.json ----
l60 = json.loads((gdir / "level60.json").read_text(encoding="utf-8"))
assert _line_count(gdir / "level60.json") <= MAX_LINES
l60_cr = {r["name"]: r["value"] for r in l60["combatRatings"]}
assert l60_cr["WEAPON_SKILL"] == 2.5
assert l60_cr["DEFENSE"] == 1.5
assert abs(l60_cr["DODGE"] - 13.80) < 1e-3
assert abs(l60_cr["PARRY"] - 13.80) < 1e-3
assert l60_cr["BLOCK"] == 5.0
assert l60_cr["HIT_MELEE"] == 10.0
assert l60_cr["HIT_RANGED"] == 10.0
assert l60_cr["HIT_SPELL"] == 8.0
assert l60_cr["CRIT_MELEE"] == l60_cr["CRIT_RANGED"] == l60_cr["CRIT_SPELL"] == 14.0
assert l60_cr["HASTE_MELEE"] == l60_cr["HASTE_RANGED"] == l60_cr["HASTE_SPELL"] == 10.0
assert l60_cr["EXPERTISE"] == 2.5
assert abs(l60_cr["ARMOR_PENETRATION"] - 4.20) < 1e-3
assert set(l60["classChanceCurves"]) == CURVE_TABLES | BASE_TABLES
l60_melee = {r["classId"]: r["value"] for r in l60["classChanceCurves"]["meleeCrit"]}
assert l60_melee[9] == l60_melee[23]   # Warlock == Necromancer at level 60

# ---- _meta.json: counts + the three caveats ----
meta = json.loads((gdir / "_meta.json").read_text(encoding="utf-8"))
assert meta["counts"]["gtCombatRatings"] == 3200
assert meta["counts"]["gtChanceToMeleeCrit"] == 3200
assert meta["counts"]["gtChanceToSpellCrit"] == 3200
assert meta["counts"]["gtRegenMPPerSpt"] == 3200
assert meta["counts"]["gtOCTRegenMP"] == 3200
assert meta["counts"]["gtRegenHPPerSpt"] == 3200
assert meta["counts"]["gtOCTRegenHP"] == 3200
assert meta["counts"]["gtChanceToMeleeCritBase"] == 32
assert meta["counts"]["gtChanceToSpellCritBase"] == 32
assert meta["counts"]["gtOCTClassCombatRatingScalar"] == 1024
assert meta["counts"]["gtNPCManaCostScaler"] == 100
assert set(meta["caveats"]) == {
    "gtOCTClassCombatRatingScalar", "clientCopyMayDifferFromServer", "armorPenetrationAnomaly",
    "level100SlotTrap",
}
assert "15.39" in meta["caveats"]["armorPenetrationAnomaly"]
assert "11.55" in meta["caveats"]["armorPenetrationAnomaly"]
assert "server" in meta["caveats"]["clientCopyMayDifferFromServer"].lower()
assert "1024" in meta["caveats"]["gtOCTClassCombatRatingScalar"] or \
       "1,024" in meta["caveats"]["gtOCTClassCombatRatingScalar"]
assert "level-100" in meta["caveats"]["level100SlotTrap"] or \
       "level 100" in meta["caveats"]["level100SlotTrap"]
assert meta["ratingNames"]["8"] == "CRIT_MELEE"
assert meta["ratingNames"]["14"] == "cr14"   # RESILIENCE checked, not pinned

# ---- config: WANTED_DBCS_V4 (11 names, the 10 Sec 1.1 tables + gtNPCManaCostScaler) ----
assert len(config.WANTED_DBCS_V4) == 11
assert "gtCombatRatings.dbc" in config.WANTED_DBCS_V4
assert "gtOCTClassCombatRatingScalar.dbc" in config.WANTED_DBCS_V4
assert "gtNPCManaCostScaler.dbc" in config.WANTED_DBCS_V4
assert "gtBarbershopCostBase.dbc" not in config.WANTED_DBCS_V4   # explicitly not worth taking
assert set(config.WANTED_DBCS_V4) <= set(config.WANTED_DBCS)

# ---- gtOCTClassCombatRatingScalar stays UNMAPPED (raw + colinfo only, no named curve) ----
assert "gtOCTClassCombatRatingScalar" not in dbc.TABLE_MAPS
assert "gtNPCManaCostScaler" not in dbc.TABLE_MAPS
for table in ("gtCombatRatings", "gtChanceToMeleeCrit", "gtChanceToMeleeCritBase",
              "gtChanceToSpellCrit", "gtChanceToSpellCritBase", "gtRegenMPPerSpt",
              "gtOCTRegenMP", "gtRegenHPPerSpt", "gtOCTRegenHP"):
    assert table in dbc.TABLE_MAPS, table
    assert dbc.TABLE_MAPS[table]["expected_fields"] == 1

print(f"ALL PASS - {stats}")
