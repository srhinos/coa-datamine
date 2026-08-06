"""TDD gate for task W4-11: items layer (coa-sim-handoff/DATAMINE-REQUEST.md Sec 8 +
Sec 13 items 14/15/16/20/21). Split into sections per sub-task letter, each
independently re-derived against a fresh 2026-08-06 extraction (not copied from the
source doc) - see .superpowers/sdd/task-w4-11-report.md for the full log.
"""
import gzip, json, sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from tools import config, dbc, extract_mpq

# =========================================================================
# (a) Item DBCs config-add - Sec 8.1, Sec 13 item 14
# =========================================================================
assert len(config.WANTED_DBCS_V6) == 9, len(config.WANTED_DBCS_V6)
assert len(set(n.lower() for n in config.WANTED_DBCS_V6)) == 9, "no duplicate names"
assert all(n.endswith(".dbc") for n in config.WANTED_DBCS_V6)
assert set(config.WANTED_DBCS_V6) <= set(config.WANTED_DBCS)
assert set(config.WANTED_DBCS_V6) == {
    "Item.dbc", "ItemSet.dbc", "SpellItemEnchantment.dbc", "GemProperties.dbc",
    "ScalingStatDistribution.dbc", "ScalingStatValues.dbc", "RandPropPoints.dbc",
    "ItemRandomSuffix.dbc", "ItemRandomProperties.dbc",
}

prov = extract_mpq.extract_all()
for name in config.WANTED_DBCS_V6:
    assert name.lower() in prov["files"], f"missing from chain: {name}"

# Fresh header pins (records, ACTUAL fields = record_size//4) - re-derived 2026-08-06,
# not copied from DATAMINE-REQUEST.md Sec 8.1 (which only gives byte sizes, not row/
# field counts for 7 of the 9 tables). Item's own count (563,335) differs slightly
# from the doc's cited 563,308 - ordinary content drift between snapshots, same class
# as every other re-pinned count in this repo (see AGENT-GUIDE's "Regenerating after
# a client patch" contract).
EXPECTED_V6 = {
    "Item": (563335, 8),
    "ItemSet": (2347, 53),
    "SpellItemEnchantment": (18035, 38),
    "GemProperties": (668, 5),
    "ScalingStatDistribution": (163, 22),
    "ScalingStatValues": (80, 24),
    "RandPropPoints": (300, 16),
    "ItemRandomSuffix": (275, 29),
    "ItemRandomProperties": (10087, 24),
}
assert set(EXPECTED_V6) == {Path(n).stem for n in config.WANTED_DBCS_V6}
for name, (records, fields) in EXPECTED_V6.items():
    f = dbc.DBCFile(config.WORK_DBC_DIR / f"{name}.dbc")
    assert f.records == records, f"{name}: records {f.records} != {records}"
    assert f.fields == fields, f"{name}: fields {f.fields} != {fields}"
    assert f.declared_fields == fields, f"{name}: header lies, unexpected for this set"

# colinfo + raw dump for all 9 - NO curation this letter (none of the 9 has a
# TABLE_MAPS entry), so every one dumps via dbc.dump_unmapped: raw f0..fN header +
# a colinfo.json evidence sidecar. "colinfo all" per the brief.
for name, (records, fields) in EXPECTED_V6.items():
    cp = config.RAW_DBC_DIR / f"{name}.colinfo.json"
    assert cp.is_file(), f"missing colinfo: {cp}"
    colinfo = json.loads(cp.read_text(encoding="utf-8"))
    assert colinfo["table"] == name
    assert colinfo["records"] == records
    assert len(colinfo["columns"]) == fields == colinfo["fields"]

    dp = config.RAW_DBC_DIR / f"{name}.csv.gz"
    assert dp.is_file(), f"missing raw dump: {dp}"
    with gzip.open(dp, "rt", encoding="utf-8", newline="") as fh:
        header = fh.readline().strip().split(",")
    assert header == [f"f{i}" for i in range(fields)], (name, header)
    assert name not in dbc.TABLE_MAPS, f"{name} must stay uncurated this letter"

# Item.dbc = an INDEX, not a stat source (Sec 8.1's framing) - re-derived directly
# from this table's own colinfo, not asserted from the doc's prose:
item_colinfo = json.loads((config.RAW_DBC_DIR / "Item.colinfo.json").read_text(encoding="utf-8"))
assert item_colinfo["string_block_size"] == 0          # zero-length string block
cols = item_colinfo["columns"]
assert all(c["samples"] == [] for c in cols)             # nothing string-like at all
# f0 (id): unique per row, and the max reproduces the doc's own cited ceiling EXACTLY
# (9,200,842) - a strong signature this is the same id space/table shape as Sec 8.2's
# own "max f1 is 9,200,579 vs Item.dbc max 9,200,842" cross-reference.
assert cols[0]["distinct"] == 563335 == item_colinfo["records"]
assert cols[0]["min"] == 1
assert cols[0]["max"] == 9200842
# f5 (displayid, per the doc's named ordering) is the only other high-cardinality
# column - consistent with "the authoritative equippable-id and displayid index"
assert cols[5]["distinct"] == 90622

# "verify size sane" - a raw single-file dump of 563,335 x 8 raw ints compresses to a
# few MB, nowhere near ItemStat's 236MB hostile-single-file problem (see section (b)).
item_gz_size = (config.RAW_DBC_DIR / "Item.csv.gz").stat().st_size
assert 1_000_000 < item_gz_size < 10_000_000, item_gz_size

print("(a) Item DBCs config-add: PASS")

print("ALL PASS")
