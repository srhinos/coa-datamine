"""TDD gate for task W4-11: items layer (coa-sim-handoff/DATAMINE-REQUEST.md Sec 8 +
Sec 13 items 14/15/16/20/21). Split into sections per sub-task letter, each
independently re-derived against a fresh 2026-08-06 extraction (not copied from the
source doc) - see .superpowers/sdd/task-w4-11-report.md for the full log.
"""
import csv, gzip, json, sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from tools import (config, dbc, extract_mpq, build_items, wdb_item, build_classes,
                   build_classmeta, build_coatalents, build_spells)

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

# =========================================================================
# (c) ItemSpells - Sec 4 trap 9, Sec 8.2 closing note, Sec 13 item 15
# =========================================================================
assert config.WANTED_DBCS_V8 == ["ItemSpells.dbc"]
assert set(config.WANTED_DBCS_V8) <= set(config.WANTED_DBCS)
assert "itemspells.dbc" in prov["files"], "missing from chain: ItemSpells.dbc"

isp = dbc.DBCFile(config.WORK_DBC_DIR / "ItemSpells.dbc")
assert isp.records == 131722 and isp.fields == 37 and isp.declared_fields == 37
assert len(isp._strings) == 0
assert "ItemSpells" not in dbc.TABLE_MAPS, "trap-9 table stays raw+colinfo only"

item_dbc_ids = {row[0] for row in
                dbc.DBCFile(config.WORK_DBC_DIR / "Item.dbc").iter_rows()}
spell_dbc_ids = {row[0] & 0xFFFFFFFF for row in
                 dbc.DBCFile(config.WORK_DBC_DIR / "Spell.dbc").iter_rows()}
isp_rows = list(isp.iter_rows())
f1_vals = [r[1] for r in isp_rows]
f2_vals = [r[2] for r in isp_rows]

# trap-9 claim 1: f1 is unique PER ROW (not an item link) - 131,722/131,722
assert len(set(f1_vals)) == len(isp_rows) == 131722

# trap-9 claim 2: f1 vs Item.dbc join is weak (~55%, doc's own headline number)
f1_item_hits = sum(1 for v in f1_vals if v in item_dbc_ids)
f1_item_rate = f1_item_hits / len(isp_rows)
assert abs(f1_item_rate - 0.5545) < 0.001, f1_item_rate

# trap-9 claim 3: f2 -> spellId IS well-supported, 99.81% against a 1.50%-dense
# spell id space (209,130 live ids / a max id well past 10x that)
f2_spell_hits = sum(1 for v in f2_vals if v in spell_dbc_ids)
f2_spell_rate = f2_spell_hits / len(isp_rows)
assert abs(f2_spell_rate - 0.9981) < 0.0005, f2_spell_rate
spell_id_density = len(spell_dbc_ids) / max(spell_dbc_ids)
assert spell_id_density < 0.02, spell_id_density   # "1.50%-dense" - re-derived, not copied

# raw+colinfo evidence exists (no curation this letter, per the brief's own wording)
isp_colinfo_p = config.RAW_DBC_DIR / "ItemSpells.colinfo.json"
assert isp_colinfo_p.is_file()
isp_colinfo = json.loads(isp_colinfo_p.read_text(encoding="utf-8"))
assert isp_colinfo["table"] == "ItemSpells"
assert isp_colinfo["records"] == 131722 and isp_colinfo["fields"] == 37
isp_dump_p = config.RAW_DBC_DIR / "ItemSpells.csv.gz"
assert isp_dump_p.is_file()
with gzip.open(isp_dump_p, "rt", encoding="utf-8", newline="") as fh:
    isp_header = fh.readline().strip().split(",")
assert isp_header == [f"f{i}" for i in range(37)]   # fully raw - trap-9 documented, not named

print("(c) ItemSpells keying evidence: PASS")

# =========================================================================
# (d) ItemVariationData join design doc - Sec 8.3, Sec 13 item 16
# =========================================================================
doc_path = config.REPO_ROOT / "analysis" / "itemvariation-join-design.md"
assert doc_path.is_file()
doc_text = doc_path.read_text(encoding="utf-8")
for marker in ("6,000,000", "95.5%", "23.3%", "1,600,000", "100.0%", "13.3%"):
    assert marker in doc_text, f"design doc missing cited evidence: {marker}"

ivd = json.loads((config.RAW_CONTENT_DIR / "ItemVariationData.json")
                  .read_text(encoding="utf-8-sig"))
assert len(ivd) == 10830
assert set(ivd[0]) == {"Normal", "Heroic", "Mythic", "Bloodforged"}
assert all(len(r["Mythic"]) == 40 for r in ivd)

both_h = [(r["Normal"], r["Heroic"]) for r in ivd if r["Normal"] and r["Heroic"]]
both_bf = [(r["Normal"], r["Bloodforged"]) for r in ivd if r["Normal"] and r["Bloodforged"]]
both_m0 = [(r["Normal"], r["Mythic"][0]) for r in ivd if r["Normal"] and r["Mythic"][0]]
assert len(both_h) == len(both_bf) == len(both_m0) == 10495

from collections import Counter
h_deltas = Counter(v - n for n, v in both_h)
bf_deltas = Counter(v - n for n, v in both_bf)
m0_deltas = Counter(v - n for n, v in both_m0)
assert h_deltas.most_common(1) == [(300000, 2443)]
assert bf_deltas.most_common(1) == [(6000000, 10022)]
assert m0_deltas.most_common(1) == [(200000, 2451)]
assert abs(10022 / len(both_bf) - 0.955) < 0.001         # Bloodforged: clean, dominant
assert abs(2443 / len(both_h) - 0.233) < 0.001            # Heroic: minority only

# "+1,600,000 Prestigious" claim: exhaustively absent from this repo's own data
near_1_6m = 0
for r in ivd:
    n = r["Normal"]
    if not n:
        continue
    candidates = [r["Heroic"], r["Bloodforged"]] + r["Mythic"]
    near_1_6m += sum(1 for v in candidates if v and abs((v - n) - 1600000) < 50)
assert near_1_6m == 0

# cross-reference against Item.dbc (this task's own W4-11a addition)
item_ids = {row[0] for row in dbc.DBCFile(config.WORK_DBC_DIR / "Item.dbc").iter_rows()}
normal_ids = [r["Normal"] for r in ivd if r["Normal"]]
normal_hits = sum(1 for i in normal_ids if i in item_ids)
assert abs(normal_hits / len(normal_ids) - 1.0) < 0.001   # 100.0%

sbi_all_normal = set()
for b in sbi_idx["buckets"]:
    for line in open(sbi_dir / b["file"], encoding="utf-8"):
        sbi_all_normal.add(json.loads(line)["itemId"])
normal_with_stats = sum(1 for i in normal_ids if i in sbi_all_normal)
assert abs(normal_with_stats / len(normal_ids) - 0.133) < 0.002

print("(d) ItemVariationData join design doc: PASS")

# =========================================================================
# (e) specs.json vs CAD tabs reconciliation - Sec 11, Sec 13 item 20
# =========================================================================
build_spells.build()
build_classes.build()
build_coatalents.build()
classmeta_stats = build_classmeta.build()

specs_doc = json.loads((config.DATA_DIR / "classes" / "specs.json").read_text(encoding="utf-8"))
specs = specs_doc["specs"]
by_id = {s["id"]: s for s in specs}
assert "tabStatusSummary" in specs_doc

# [Task W4-14] re-derived against the LIVE builder and renamed - the old states
# (live/shippedExternal/unreleased/noTabLayer) are gone because "live" there meant
# only "a CAD tab with this token exists", a claim about the catalog rather than the
# game. tests/test_live_flags.py is the full gate for the new derivation; what stays
# here is Sec 11's own reconciliation question, re-asked in the new vocabulary.
STATES = {"inLiveBuilder", "cadOnly", "unreleased", "noLiveGeometry", "noCadClass"}
for s in specs:
    if s["classId"] is not None and s["tabToken"]:
        assert s["tabStatus"] is not None and s["tabStatus"]["status"] in STATES
    else:
        assert s["tabStatus"] is None

counts = specs_doc["tabStatusSummary"]["counts"]
assert counts == {"inLiveBuilder": 70, "noLiveGeometry": 30, "noCadClass": 1}
assert sum(counts.values()) == 101

# Sec 11's own Chronomancer example, re-derived: spec 31 is NAMED "Time" with
# tabToken "DISPLACEMENT", which does cross-reference that class's real
# "Displacement" CAD tab - and that CAD tab is the live builder's "Time" tree, which
# is why the token alone was never enough to say what a player actually has.
assert by_id[31]["name"] == "Time" and by_id[31]["tabToken"] == "DISPLACEMENT"
assert by_id[31]["tabStatus"] == {"status": "inLiveBuilder", "cadTab": "Displacement",
                                  "liveTab": "Time", "match": "specName",
                                  "renamed": True}

# W4-9's "5 of Sec 11's 7 tokens shipped" finding: all 5 still resolve, now by
# mechanism (the spec's own name is the live-generation label) rather than the
# pinned token table W4-11e read out of data/talents/coa/_meta.json
SHIPPED = {
    25: ("Fleshweaver", "FLESHWEAVER"), 47: ("Valkyrie", "VALKYR"),
    60: ("Mountain King", "MOUNTAINKING"), 97: ("Black Knight", "WITCHKNIGHT"),
    101: ("Vizier", "VIZIER"),
}
for sid, (name, token) in SHIPPED.items():
    assert by_id[sid]["name"] == name and by_id[sid]["tabToken"] == token
    assert by_id[sid]["tabStatus"]["status"] == "inLiveBuilder"
    assert by_id[sid]["tabStatus"]["liveTab"] == name

# ...and the 2 W4-9 could NOT place (its "unmatchedExtraTabs") are now attributed by
# the same mechanism, so Sec 11's unreleased list is empty rather than 7 or 2
FORMERLY_UNRELEASED = {45: ("Warden", "HYDROMANCY"), 96: ("Dreadnought", "BULWARK")}
for sid, (name, token) in FORMERLY_UNRELEASED.items():
    assert by_id[sid]["name"] == name and by_id[sid]["tabToken"] == token
    assert by_id[sid]["tabStatus"]["status"] == "inLiveBuilder"
    assert by_id[sid]["tabStatus"]["liveTab"] == name
assert specs_doc["tabStatusSummary"]["unreleased"] == []

# Hero (classId 10) has no CAD class directory at all - structural, not content drift
assert by_id[94]["className"] == "Hero" and by_id[94]["tabToken"] == "HERO"
assert by_id[94]["tabStatus"] == {"status": "noCadClass", "cadTab": None,
                                  "liveTab": None, "match": None, "renamed": None}
cidx = json.loads((config.DATA_DIR / "classes" / "index.json").read_text(encoding="utf-8"))
assert not any(c.get("classId") == 10 for c in cidx["classes"])

assert classmeta_stats["specs"]["tabStatusCounts"] == counts

print("(e) specs.json vs CAD tabs reconciliation: PASS")

# =========================================================================
# (f) SpellCharges 0.885 join-gap investigation - Sec 11, Sec 13 item 21
# =========================================================================
spells_stats = build_spells.build()
charges_meta = json.loads((config.DATA_DIR / "spells" / "_meta.json")
                          .read_text(encoding="utf-8"))["enrichment"]["charges"]
charges_doc = json.loads((config.DATA_DIR / "spells" / "charges.json").read_text(encoding="utf-8"))

# re-derive independently: build the area-52 realm's own Spell id set straight from
# the committed raw dump (not via build_spells' internals) and cross-check every
# base-non-joining ref by hand
spell_names = {r["id"]: r["name_enUS"] for r in dbc.iter_named("Spell")}
spell_ids = set(spell_names)
non_joining_refs = {c["ref"] for c in charges_doc["charges"] if c["ref"] not in spell_ids}
assert non_joining_refs == {c["ref"] for c in charges_doc["charges"]
                            if c["resolvedSpellName"] is None}

realm_spell_csv = config.RAW_REALMS_DIR / "area-52" / "dbc" / "Spell.csv.gz"
assert realm_spell_csv.is_file()
realm_ids = set()
with gzip.open(realm_spell_csv, "rt", encoding="utf-8", newline="") as fh:
    for row in csv.DictReader(fh):
        realm_ids.add(int(row["id"]))

resolved = {r for r in non_joining_refs if r in realm_ids}
dead = non_joining_refs - resolved
assert charges_meta["realmGapFinding"]["nonJoiningCount"] == len(non_joining_refs)
assert charges_meta["realmGapFinding"]["resolvedByAnyRealm"] == len(resolved)
assert charges_meta["realmGapFinding"]["provenDeadCount"] == len(dead)

# today's live-client finding: every non-joining ref is realm-overlay content, zero
# proven dead - attach stays False, join rate cannot legitimately clear 0.90
assert len(dead) == 0
assert len(resolved) == len(non_joining_refs)
assert charges_meta["attached"] is False
assert charges_meta["spellIdJoinRate"] < 0.90
assert charges_meta["realmGapFinding"]["adjustedJoinRate"] < 0.90

print("(f) SpellCharges join-gap investigation: PASS")

print("ALL PASS")
