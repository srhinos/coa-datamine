"""TDD gate for task W4-11: items layer (coa-sim-handoff/DATAMINE-REQUEST.md Sec 8 +
Sec 13 items 14/15/16/20/21). Split into sections per sub-task letter, each
independently re-derived against a fresh 2026-08-06 extraction (not copied from the
source doc) - see .superpowers/sdd/task-w4-11-report.md for the full log.
"""
import gzip, json, sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from tools import config, dbc, extract_mpq, build_items, wdb_item

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

# =========================================================================
# (b) ItemStat - Sec 8.2, Sec 4 trap 8, Sec 13 item 15
# =========================================================================
assert config.WANTED_DBCS_V7 == ["ItemStat.dbc"]
assert set(config.WANTED_DBCS_V7) <= set(config.WANTED_DBCS)
assert "itemstat.dbc" in prov["files"], "missing from chain: ItemStat.dbc"

f = dbc.DBCFile(config.WORK_DBC_DIR / "ItemStat.dbc")
assert f.records == 1513931 and f.fields == 39 and f.declared_fields == 39
assert len(f._strings) == 0                                   # no string block

# ItemStat is a CUSTOM_RAW_DUMP_TABLES entry - dump_all()'s generic per-table dump
# must skip it entirely (no single raw/dbc/ItemStat.csv.gz - that's the 236MB
# hostile-file case this whole letter exists to avoid).
assert "ItemStat" in dbc.CUSTOM_RAW_DUMP_TABLES
assert not (config.RAW_DBC_DIR / "ItemStat.csv.gz").exists()
assert not (config.RAW_DBC_DIR / "ItemStat.colinfo.json").exists()

# ---- independent golden re-derivation: item 100248 vs itemcache.wdb ----
WDB_PATH = config.CLIENT_DIR / "Cache" / "WDB" / "enUS" / "itemcache.wdb"
assert WDB_PATH.is_file(), f"itemcache.wdb not found: {WDB_PATH}"
_build, wdb_items, wdb_bad, wdb_term, wdb_size = wdb_item.parse_file(str(WDB_PATH))
assert len(wdb_bad) == 0, wdb_bad[:5]
wdb_by_entry = {it["entry"]: it for it in wdb_items}
golden = wdb_by_entry[100248]
assert golden["name"] == "Beaststalker's Belt"
assert golden["itemLevel"] == 61
assert golden["armor"] == 277
assert golden["stats"] == [(3, 13), (5, 8), (7, 9), (31, 10), (38, 17)]

# raw ItemStat rows for f1==100248 (this must reproduce independent of build_items'
# own internal assertions - re-derived directly against work/dbc here)
rows_100248 = [f.row_ints(i) for i in range(f.records) if f.row_ints(i)[1] == 100248]
assert len(rows_100248) == 75, len(rows_100248)                # the 75-row block
by_ilvl = {r[2]: r for r in rows_100248}
row61 = by_ilvl[61]
assert row61[27] == 277                                        # armor: EXACT
pairs61 = [(row61[3 + 2 * k], row61[4 + 2 * k]) for k in range(10) if row61[3 + 2 * k]]
assert pairs61 == [(3, 13), (5, 8), (7, 9), (31, 9), (38, 17)]  # 4/5 exact, statType
                                                                 # 31 ("hit") off by 1
row60 = by_ilvl[60]
assert row60[27] == 271 and row60[27] != golden["armor"]        # f2=60 does NOT match

# the 75-distinct-value / dense-then-sparse claim, table-wide
f2_values = {f.row_ints(i)[2] for i in range(f.records)}
assert len(f2_values) == 75
assert sorted(f2_values)[:65] == list(range(1, 66))
assert sorted(f2_values)[65:] == [86, 88, 91, 94, 96, 98, 99, 101, 103, 105]

# ---- naming decision: f1/f2 now in TABLE_MAPS given the golden above holds ----
assert dbc.TABLE_MAPS["ItemStat"] == {"expected_fields": 39, "columns": [
    ("itemId", 1, "u"), ("ownItemLevel", 2, "u"),
]}

# ---- build_items.build() - sharded raw dump + curated statsByItem index ----
items_stats = build_items.build()
assert items_stats["itemstatRows"] == 1513931
assert items_stats["statsByItem"]["written"] == 20267

# raw/dbc/itemstat/ shards: index completeness, no single shard is anywhere near
# the 236MB single-file problem this letter exists to avoid, named f1/f2 header
istat_dir = config.RAW_DBC_DIR / "itemstat"
istat_idx = json.loads((istat_dir / "index.json").read_text(encoding="utf-8"))
assert istat_idx["bucketSize"] == 50000
assert istat_idx["totalRows"] == 1513931
on_disk = {p.name for p in istat_dir.glob("*.csv.gz")}
listed = {s["file"].split("/")[-1] for s in istat_idx["shards"]}
assert on_disk == listed, on_disk ^ listed
total_rows = 0
for s in istat_idx["shards"]:
    p = config.REPO_ROOT / s["file"]
    assert p.stat().st_size < 15_000_000, (s["file"], p.stat().st_size)  # sane, not 236MB
    with gzip.open(p, "rt", encoding="utf-8", newline="") as fh:
        header = fh.readline().strip().split(",")
        n = sum(1 for _ in fh)
    assert header[0] == "f0" and header[1] == "itemId" and header[2] == "ownItemLevel"
    assert header[3] == "f3"
    assert n == s["rows"], (s["file"], n, s["rows"])
    total_rows += n
assert total_rows == 1513931

# data/items/statsByItem/: index completeness + line-gate + the 100248 golden record
sbi_dir = config.DATA_DIR / "items" / "statsByItem"
sbi_idx = json.loads((sbi_dir / "index.json").read_text(encoding="utf-8"))
assert sbi_idx["bucketSize"] == 5000
assert sbi_idx["count"] == 20267
on_disk = {p.name for p in sbi_dir.glob("*.jsonl")}
listed = {b["file"] for b in sbi_idx["buckets"]}
assert on_disk == listed, on_disk ^ listed
grand_total = 0
for b in sbi_idx["buckets"]:
    n = sum(1 for _ in open(sbi_dir / b["file"], encoding="utf-8"))
    assert n <= 5000, (b["file"], n)                            # data/ line gate
    assert n == b["count"], (b["file"], n, b["count"])
    grand_total += n
assert grand_total == 20267 == sbi_idx["count"]

found_100248 = None
for line in open(sbi_dir / "statsByItem-100000.jsonl", encoding="utf-8"):
    rec = json.loads(line)
    if rec["itemId"] == 100248:
        found_100248 = rec
        break
assert found_100248 is not None
assert found_100248["rowCount"] == 75
assert found_100248["ilvls"][:5] == [1, 2, 3, 4, 5]
assert found_100248["ilvls"][-1] == 105
assert found_100248["rawShard"] == "raw/dbc/itemstat/itemstat-100000.csv.gz"

sbi_meta = json.loads((sbi_dir / "_meta.json").read_text(encoding="utf-8"))
assert sbi_meta["count"] == 20267
assert abs(sbi_meta["itemIdJoinRate"] - 0.9696) < 0.0005

print("(b) ItemStat golden + sharded dump + statsByItem index: PASS")

print("ALL PASS")
