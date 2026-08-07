"""TDD gate for task W4-10: simulation-adjacent spell support tables
(coa-sim-handoff/DATAMINE-REQUEST.md Sec 9 + Sec 13 items 13/17).

WANTED_DBCS_V5 adds 12 tables: SpellAffect, SpellDifficulty, SummonProperties,
SpellMissile, SpellShapeshiftForm, SpellFocusObject, SpellRank, CreatureSpellData,
GlyphProperties, GlyphSlot, SpellStatSuggestions, SpellItemEnchantmentCondition -
all confirmed present in the live MPQ chain by extract_mpq.extract_all() itself
(it raises SystemExit on any wanted name missing from every archive).

Only SpellAffect and SpellStatSuggestions get curated columns in TABLE_MAPS, plus
SpellRank named for raw-dump clarity only (NOT wired into build_spells.py's
rank-chain pipeline, which stays on raw/content/SpellRankData.json). The other 9
tables ship raw f0..fN + colinfo.json evidence only - this file pins their fresh
extraction headers and colinfo presence, nothing more.

Every number below is independently re-derived against a fresh 2026-08-06
extraction (not copied from DATAMINE-REQUEST.md Sec 9) - see
.superpowers/sdd/task-w4-10-report.md for the full log and tools/dbc.py's
TABLE_MAPS comments for the per-table evidence."""
import gzip, json, sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from tools import config, dbc, extract_mpq, build_spells

# ---- config sanity ----
assert len(config.WANTED_DBCS_V5) == 12, len(config.WANTED_DBCS_V5)
assert len(set(n.lower() for n in config.WANTED_DBCS_V5)) == 12, "no duplicate names"
assert all(n.endswith(".dbc") for n in config.WANTED_DBCS_V5)
assert set(config.WANTED_DBCS_V5) <= set(config.WANTED_DBCS)

# ---- extraction: all 12 must exist in the live chain (extract_all() raises
# SystemExit otherwise - this IS the "verify each actually exists" gate) ----
prov = extract_mpq.extract_all()
for name in config.WANTED_DBCS_V5:
    assert name.lower() in prov["files"], f"missing from chain: {name}"

# ---- fresh header pins (records, ACTUAL fields = record_size//4, the
# authoritative layout per DBCFile - not the possibly-lying declared header
# count) ----
EXPECTED = {
    "SpellAffect": (36779, 3),
    "SpellDifficulty": (3810, 5),
    "SummonProperties": (217, 6),
    "SpellMissile": (170, 15),
    "SpellShapeshiftForm": (61, 35),
    "SpellFocusObject": (435, 18),
    "SpellRank": (23182, 4),
    "CreatureSpellData": (803, 9),
    "GlyphProperties": (362, 4),
    "GlyphSlot": (10, 3),
    "SpellStatSuggestions": (1121, 4),
    "SpellItemEnchantmentCondition": (49, 16),
}
assert set(EXPECTED) == {Path(n).stem for n in config.WANTED_DBCS_V5}

for name, (records, fields) in EXPECTED.items():
    f = dbc.DBCFile(config.WORK_DBC_DIR / f"{name}.dbc")
    assert f.records == records, f"{name}: records {f.records} != {records}"
    assert f.fields == fields, f"{name}: fields {f.fields} != {fields}"

# SpellItemEnchantmentCondition's header LIES about its own field count - the
# WDBC header declares the real stock-WotLK 31-column operand-condition shape,
# but record_size only backs 16. extract_mpq.py's headerMismatches must have
# caught this on this base-table extraction (previously only ever a realm-
# overlay-table phenomenon, see DBCFile's docstring).
sief = dbc.DBCFile(config.WORK_DBC_DIR / "SpellItemEnchantmentCondition.dbc")
assert sief.declared_fields == 31 and sief.fields == 16
mismatch_names = {m["table"] for m in prov["headerMismatches"]}
assert "spellitemenchantmentcondition.dbc" in mismatch_names, prov["headerMismatches"]

# ---- colinfo presence for ALL 12 (the brief's blanket ask) - committed
# evidence sidecars in raw/dbc/, one per table regardless of curation status ----
for name in EXPECTED:
    p = config.RAW_DBC_DIR / f"{name}.colinfo.json"
    assert p.is_file(), f"missing colinfo: {p}"
    colinfo = json.loads(p.read_text(encoding="utf-8"))
    assert colinfo["table"] == name
    assert colinfo["records"] == EXPECTED[name][0]
    assert len(colinfo["columns"]) == colinfo["fields"]

# ---- raw dumps exist for all 12, and the 3 curated ones carry named headers ----
NAMED_HEADERS = {
    "SpellAffect": ["id", "spellId", "affectedSpellId"],
    "SpellStatSuggestions": ["id", "spellId", "f2", "f3"],
    "SpellRank": ["id", "firstSpellId", "spellId", "rank"],
}
for name in EXPECTED:
    p = config.RAW_DBC_DIR / f"{name}.csv.gz"
    assert p.is_file(), f"missing raw dump: {p}"
    with gzip.open(p, "rt", encoding="utf-8", newline="") as fh:
        header = fh.readline().strip().split(",")
    if name in NAMED_HEADERS:
        assert header == NAMED_HEADERS[name], (name, header)
    else:
        assert header == [f"f{i}" for i in range(EXPECTED[name][1])], (name, header)

# ============================= SpellAffect =============================
# Re-derivation of DATAMINE-REQUEST.md Sec 9 - the adversarial verifier's
# explicitly-unconfirmed subsection. Every claim below reproduces against THIS
# task's own fresh extraction; see tools/dbc.py's SpellAffect TABLE_MAPS comment.
spell_rows = list(dbc.DBCFile(config.WORK_DBC_DIR / "Spell.dbc").iter_rows())
spell_dbc = dbc.DBCFile(config.WORK_DBC_DIR / "Spell.dbc")
spell_ids = {dbc.u32(r[0]) for r in spell_rows}
name_by_id = {dbc.u32(r[0]): spell_dbc.string(r[136]) for r in spell_rows}

aff_rows = list(dbc.DBCFile(config.WORK_DBC_DIR / "SpellAffect.dbc").iter_rows())
f1_vals = [dbc.u32(r[1]) for r in aff_rows]
f1_hits = sum(1 for v in f1_vals if v in spell_ids)
assert f1_hits == len(aff_rows), f"f1 join {f1_hits}/{len(aff_rows)}"           # 100.0000%

f2_unsigned_hits = sum(1 for r in aff_rows if dbc.u32(r[2]) in spell_ids)
assert abs(f2_unsigned_hits / len(aff_rows) - 0.934528) < 0.0005                # doc: 93.5%

negatives = sum(1 for r in aff_rows if r[2] < 0)
assert negatives == 2407, negatives                                            # doc: exact

f2_abs_hits = sum(1 for r in aff_rows if abs(r[2]) in spell_ids)
assert f2_abs_hits == len(aff_rows) - 1, f2_abs_hits          # 99.9973%, one dead id (83998)

# 3 goldens - the third's REAL range is wider than the doc's own quoted text
def _affects(sid):
    return [r[2] for r in aff_rows if dbc.u32(r[1]) == sid]

assert _affects(324) == [978816]
assert name_by_id[978816] == "Assault and Battery"
assert sorted(_affects(2565)) == [47294, 47295, 47296]
assert all(name_by_id[v] == "Critical Block" for v in _affects(2565))
hailstorm_block = sorted(_affects(12043))
assert hailstorm_block[:9] == list(range(81328, 81337))          # doc quoted only 81328-81332
assert hailstorm_block[9:] == list(range(281800, 281809))        # doc never mentions this block
assert all(name_by_id[v] in ("Blizzard (Hailstorm)", "Hailstorm") for v in hailstorm_block)

# CoA-coverage-is-low finding, re-derived against data/classes/ (must already
# exist on disk - this test does not rebuild it, matching test_spells_columns.py's
# own convention)
classes_idx = json.loads((config.DATA_DIR / "classes" / "index.json").read_text(encoding="utf-8"))


def _class_spell_ids(tag):
    ids = set()
    for c in classes_idx["classes"]:
        if c.get("tag") != tag:
            continue
        cidx = json.loads((config.DATA_DIR / "classes" / c["index"]).read_text(encoding="utf-8"))
        for fentry in cidx["files"]:
            tab = json.loads((config.DATA_DIR / "classes" / c["dir"] / fentry["file"])
                              .read_text(encoding="utf-8"))
            for e in tab.get("entries", []):
                for s in e.get("spells", []) or []:
                    if s.get("id"):
                        ids.add(s["id"])
                    for rk in s.get("ranks") or []:
                        if rk.get("spellId"):
                            ids.add(rk["spellId"])
    return ids


coa_ids = _class_spell_ids("coa-custom")
# 6,790, not the doc's headline 6,436: this helper reads data/classes/ off disk (the
# WIDE scope), while build_spells._coa_class_spell_ids() takes rank chains only from
# spells that have a base Spell.dbc row (the NARROW scope, still pinned at 6,436 in
# test_spells_columns.py). The 354-id gap is exactly the chains build_classes stopped
# dropping for unresolved spells; the wide set is a strict superset (narrow-only = 0).
assert len(coa_ids) == 6790, len(coa_ids)

MODIFIER_AURA_IDS = {107, 108}                            # ADD_FLAT_MODIFIER, ADD_PCT_MODIFIER
coa_with_modifier = set()
for r in spell_rows:
    sid = dbc.u32(r[0])
    if sid in coa_ids and any(dbc.u32(r[95 + slot]) in MODIFIER_AURA_IDS for slot in range(3)):
        coa_with_modifier.add(sid)

f1_set = set(f1_vals)
f2_abs_set = {abs(r[2]) for r in aff_rows}
assert coa_with_modifier & f1_set == {92123, 92131, 300357, 800274, 805378}
assert coa_with_modifier & f2_abs_set == {
    502582, 502583, 502584, 502585, 502586, 502587, 502588, 502589, 502590, 801708}

assert len(f1_set & _class_spell_ids("vanilla")) == 209
assert len(f1_set & _class_spell_ids("reborn")) == 277
assert len(f1_set & coa_ids) == 5

distinct_abs_f2 = {abs(r[2]) for r in aff_rows}
assert len(distinct_abs_f2) == 10684, len(distinct_abs_f2)
in_coa_band = [v for v in distinct_abs_f2 if 500000 <= v < 600000]
assert len(in_coa_band) == 158, len(in_coa_band)

# ============================= SpellStatSuggestions =============================
ss_named = list(dbc.iter_named("SpellStatSuggestions"))
assert len(ss_named) == 1121
by_own_id = {r["id"]: r for r in ss_named}
assert by_own_id[1] == {"id": 1, "spellId": 10}                    # golden: id 1 -> Blizzard
assert name_by_id[10] == "Blizzard"

ss_join_hits = sum(1 for r in ss_named if r["spellId"] in spell_ids)
assert abs(ss_join_hits / len(ss_named) - 0.9991) < 0.001

# build_spells.build() must have already run (module-level side effect below,
# same as test_spells_columns.py) before statSuggestions.json is checked
stats = build_spells.build()
sdir = config.DATA_DIR / "spells"
ss_doc = json.loads((sdir / "statSuggestions.json").read_text(encoding="utf-8"))
assert len(ss_doc["suggestions"]) == 1121
assert ss_doc["spellIdJoinRate"] == round(ss_join_hits / len(ss_named), 4)
blizzard_row = next(r for r in ss_doc["suggestions"] if r["spellId"] == 10)
assert blizzard_row == {"spellId": 10, "resolvedSpellName": "Blizzard",
                         "statCategoryRaw": 3, "f3": 1}
n = sum(1 for _ in open(sdir / "statSuggestions.json", encoding="utf-8"))
assert n <= 5000, n

meta = json.loads((sdir / "_meta.json").read_text(encoding="utf-8"))
assert meta["enrichment"]["statSuggestions"]["recordCount"] == 1121

# ============================= SpellRank =============================
sr_named = list(dbc.iter_named("SpellRank"))
assert len(sr_named) == 23182
sr_f1_hits = sum(1 for r in sr_named if r["firstSpellId"] in spell_ids)
assert sr_f1_hits == 23182                                                    # 100.0000%
sr_f2_hits = sum(1 for r in sr_named if r["spellId"] in spell_ids)
assert sr_f2_hits == 23177, sr_f2_hits                                        # 99.9784%

rank1_rows = [r for r in sr_named if r["rank"] == 1]
rank1_self = sum(1 for r in rank1_rows if r["firstSpellId"] == r["spellId"])
assert rank1_self == 3504 and len(rank1_rows) == 3507

# comparison vs the already-integrated raw/content/SpellRankData.json - NOT
# identical coverage, and NOT wired into build_spells.py by this task
json_rows = json.loads((config.RAW_CONTENT_DIR / "SpellRankData.json").read_text(encoding="utf-8-sig"))
assert len(json_rows) == 13311
json_by_spell = {r["spellId"]: r for r in json_rows}
dbc_spellids = {r["spellId"] for r in sr_named}
json_spellids = set(json_by_spell)
overlap = dbc_spellids & json_spellids
assert len(overlap) == 9945, len(overlap)
dbc_only = dbc_spellids - json_spellids
assert len(dbc_only) == 13237, len(dbc_only)
dbc_only_real = sum(1 for v in dbc_only if v in spell_ids)
assert dbc_only_real == 13232, dbc_only_real                                  # 99.96% of dbc-only

agree_first = sum(1 for r in sr_named if r["spellId"] in json_by_spell
                   and r["firstSpellId"] == json_by_spell[r["spellId"]]["firstSpellId"])
assert agree_first == 9901, agree_first                                       # 99.56% of overlap

# rank agreement - NOT a clean off-by-one (pinned per-diff, not just the aggregate):
# +1 is the largest single bucket but under half of the 565 mismatches (266/565 =
# 47.08%); +2..+8 plus a handful of negatives make up the rest.
from collections import Counter
rank_diffs = Counter()
agree_rank = 0
for r in sr_named:
    j = json_by_spell.get(r["spellId"])
    if j is None:
        continue
    d = r["rank"] - j["rank"]
    if d == 0:
        agree_rank += 1
    else:
        rank_diffs[d] += 1
assert agree_rank == 9380, agree_rank                                         # 94.32% of overlap
assert sum(rank_diffs.values()) == 565, sum(rank_diffs.values())
assert rank_diffs[1] == 266, rank_diffs[1]                                    # 47.08% of mismatches
assert dict(rank_diffs) == {
    -5: 5, -2: 1, -1: 10, 1: 266, 2: 109, 3: 61, 4: 37, 5: 41, 6: 20, 7: 4,
    8: 5, 9: 1, 10: 1, 11: 1, 12: 1, 13: 1, 14: 1,
}, dict(rank_diffs)

print("ALL PASS")
