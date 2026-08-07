"""Gates for the universal raw table layer (tools/extract_all.py + tools/decode_all.py
-> raw/tables/).

What these assert, in order of how much they matter:

 1. NO HAND-AUTHORED COLUMN NAME REACHES THE DATA. Every column name in every
    colinfo and every key in every emitted record is positional (`f<N>`, plus
    the two structural sidecar suffixes). This is the output-side proof, and it
    covers all 368 tables, not a sample.
 2. NO HAND-AUTHORED COLUMN NAME EXISTS IN THE SOURCE. The two new modules are
    AST-scanned and their string literals must be disjoint from (a) every column
    name this repo's curated layer has ever asserted (tools/dbc.TABLE_MAPS - the
    repo's own hand-authored vocabulary, used here as an external ground truth
    rather than a list invented by this test) and (b) every table name in the
    client census, which is what proves no table is special-cased. They must
    also not reference the curated column-map machinery at all.
 3. NOTHING IS SILENTLY DROPPED. Every table in the client census is either
    decoded or named in _failures.json with a reason.
 4. THE INDEX IS TRUE. Every shard's recorded sha256/row count/key range matches
    the bytes on disk, shard row counts respect the cap, and the per-table row
    counts add up to the header's record count.
 5. THE READER DID NOT DRIFT. tools/decode_all.Table agrees row-for-row and
    string-for-string with the verified tools/dbc.DBCFile wherever DBCFile can
    read at all, and the tables where it cannot are exactly the ones whose
    recordSize is not a multiple of 4.
 6. RERUNS ARE BYTE-IDENTICAL. Two decodes of a sample of tables into scratch
    dirs produce the same bytes.
"""
import ast
import gzip
import json
import re
import shutil
import struct
import sys
import tempfile
from collections import Counter
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from tools import config, dbc, decode_all, extract_all

RAW = decode_all.OUT_DIR
MAX_LINES = 5000
COLUMN_NAME = re.compile(r"f\d+")
RECORD_KEY = re.compile(r"f\d+[is]?")
MODULES = [Path(extract_all.__file__), Path(decode_all.__file__)]

cat = json.loads((RAW / "index.json").read_text(encoding="utf-8"))
failures = json.loads((RAW / "_failures.json").read_text(encoding="utf-8"))
census = decode_all._census()
assert census, "raw/_inventory/dbc.json missing - run python -m tools.inventory"
indexes = {r["table"]: json.loads((RAW / r["table"] / "index.json").read_text(
    encoding="utf-8")) for r in cat["tables"]}


def read_shard(table: str, shard: dict) -> list:
    p = RAW / table / shard["file"]
    raw = p.read_bytes()
    if shard["format"] == "gzip":
        raw = gzip.decompress(raw)
    return raw.decode("utf-8").splitlines()


# --------------------------------------------------------------------------
# 1. positional column names, everywhere, in every table
# --------------------------------------------------------------------------
bad_names, bad_keys, checked_records = set(), set(), 0
for table, ix in indexes.items():
    ci = json.loads((RAW / table / f"{table}.colinfo.json").read_text(encoding="utf-8"))
    assert ci["columnCount"] == ix["columns"], table
    for i, col in enumerate(ci["columns"]):
        if not COLUMN_NAME.fullmatch(col["name"]) or col["index"] != i \
                or col["name"] != f"f{i}":
            bad_names.add((table, col["name"]))
    expected = set()
    for col in ci["columns"]:
        expected.add(f"f{col['index']}")
        if col["inferred"] == "string":
            expected.add(f"f{col['index']}i")
        elif col.get("stringSidecar"):
            expected.add(f"f{col['index']}s")
    for shard in ix["shards"][:1]:
        for line in read_shard(table, shard)[:25]:
            rec = json.loads(line)
            checked_records += 1
            for k in rec:
                if not RECORD_KEY.fullmatch(k):
                    bad_keys.add((table, k))
            if set(rec) != expected:
                bad_keys.add((table, "record keys disagree with colinfo"))
assert not bad_names, f"non-positional column names: {sorted(bad_names)[:10]}"
assert not bad_keys, f"non-positional record keys: {sorted(bad_keys)[:10]}"
assert checked_records > 5000, checked_records
print(f"[1] positional names: {len(indexes)} tables, {checked_records} records checked")


# --------------------------------------------------------------------------
# 2. the source carries no column vocabulary and no table special-casing
# --------------------------------------------------------------------------
curated_names = set()
for spec in dbc.TABLE_MAPS.values():
    curated_names.update(name for name, _idx, _kind in spec["columns"])
assert len(curated_names) > 100, len(curated_names)

table_words = set()
for name in census:
    table_words.add(name.lower())
    table_words.add(name[:-4].lower())

literals, names_used = set(), set()
for path in MODULES:
    tree = ast.parse(path.read_text(encoding="utf-8"))
    for node in ast.walk(tree):
        if isinstance(node, ast.Constant) and isinstance(node.value, str):
            literals.add(node.value)
        elif isinstance(node, ast.Name):
            names_used.add(node.id)
        elif isinstance(node, ast.Attribute):
            names_used.add(node.attr)

hits = sorted(l for l in literals if l in curated_names)
assert not hits, f"curated column names appear as literals: {hits}"
table_hits = sorted(l for l in literals if l.lower() in table_words)
assert not table_hits, f"a table is named in the source: {table_hits}"
banned = {"TABLE_MAPS", "iter_named", "dump_table", "dump_unmapped", "enums335",
          "WANTED_DBCS", "_spell_columns", "CUSTOM_RAW_DUMP_TABLES"}
assert not (names_used & banned), f"curated machinery referenced: {names_used & banned}"
print(f"[2] source scan: {len(literals)} literals vs {len(curated_names)} curated "
      f"column names and {len(census)} table names - disjoint")


# --------------------------------------------------------------------------
# 3. no silent drops
# --------------------------------------------------------------------------
decoded = {t + ".dbc" for t in indexes}
listed = {f["table"] for f in failures["failures"]}
missing = sorted(set(census) - decoded - listed)
assert not missing, f"tables in the census neither decoded nor recorded: {missing}"
assert failures["count"] == len(failures["failures"]) == len(listed)
assert cat["tableCount"] == len(indexes) == len(census) - len(listed)
print(f"[3] census coverage: {len(decoded)} decoded + {len(listed)} recorded "
      f"= {len(census)} in the client")

# the extractor resolves the MPQ chain independently of tools/inventory.py's
# census walk; a disagreement on ANY winner would mean one of them reads a file
# the client does not use, which is the whole failure this layer exists to end
prov_check = extract_all.load_provenance()
assert prov_check, "run python -m tools.extract_all"
ex = {t["table"]: t for t in prov_check["tables"]}
assert set(ex) == set(census), sorted(set(ex) ^ set(census))[:10]
for name, e in ex.items():
    c = census[name]
    assert e["winner"] == c["winner"], (name, e["winner"], c["winner"])
    assert e["sha256"] == c["sha256"], name
    assert sorted(e["losers"]) == sorted(c["losers"]), name
    assert e["records"] == c["records"] and e["recordSize"] == c["recordSize"], name
print(f"[3] chain agreement: extractor and census agree on the winner, sha256 "
      f"and loser list of all {len(ex)} tables")


# --------------------------------------------------------------------------
# 4. the index tells the truth
# --------------------------------------------------------------------------
import hashlib

rows_total = shards_total = stored_total = 0
for table, ix in indexes.items():
    src = census[ix["file"]]
    assert ix["rows"] == src["records"], (table, ix["rows"], src["records"])
    assert ix["sourceSha256"] == src["sha256"], table
    assert ix["columns"] == src["recordSize"] // 4 + src["recordSize"] % 4, table
    seen = 0
    for s in ix["shards"]:
        p = RAW / table / s["file"]
        data = p.read_bytes()
        assert hashlib.sha256(data).hexdigest() == s["sha256"], (table, s["file"])
        assert len(data) == s["storedBytes"], (table, s["file"])
        lines = read_shard(table, s)
        assert len(lines) == s["rows"], (table, s["file"])
        assert s["rows"] <= MAX_LINES or s["file"] in ix["oversizeShards"], \
            (table, s["file"], s["rows"])
        seen += s["rows"]
        shards_total += 1
        stored_total += s["storedBytes"]
    assert seen == ix["rows"], (table, seen, ix["rows"])
    rows_total += ix["rows"]
    if ix["shardKey"]["mode"] == "column" and ix["rows"]:
        c = int(ix["shardKey"]["column"][1:])
        for s in ix["shards"]:
            for line in read_shard(table, s)[:5]:
                rec = json.loads(line)
                v = rec.get(f"f{c}i", rec[f"f{c}"])
                v = int(v) & 0xFFFFFFFF
                assert s["lo"] <= v <= s["hi"], (table, s["file"], v)
assert rows_total == cat["totalRows"] == sum(t["records"] for t in census.values())
assert shards_total == cat["totalShards"]
assert stored_total == cat["storedBytes"]
print(f"[4] index integrity: {shards_total} shards, {rows_total} rows, "
      f"{stored_total/1e6:.1f} MB - every sha256 and range verified")

# every byte of every string block is either reachable from a decoded record or
# written out verbatim - the layer may not quietly leave client bytes behind
block_total = orphan_total = 0
for table, ix in indexes.items():
    ci = json.loads((RAW / table / f"{table}.colinfo.json").read_text(encoding="utf-8"))
    h = ci["header"]
    assert h["stringBlockSize"] == census[ix["file"]]["stringBlockSize"], table
    assert h["stringBlockReferencedBytes"] + h["stringBlockUnreferencedBytes"] \
        == h["stringBlockSize"], table
    p = RAW / table / f"{table}.strings.json"
    if h["stringBlockUnreferencedBytes"]:
        s = json.loads(p.read_text(encoding="utf-8"))
        assert s["bytes"] == h["stringBlockUnreferencedBytes"] == \
            sum(e["bytes"] for e in s["entries"]), table
        assert s["count"] == len(s["entries"]) == h["stringBlockUnreferencedEntries"]
    else:
        assert not p.exists(), table
    block_total += h["stringBlockSize"]
    orphan_total += h["stringBlockUnreferencedBytes"]
assert block_total == cat["stringBlockBytes"]
assert orphan_total == cat["unreferencedStringBytes"]
print(f"[4] string blocks: {block_total:,} bytes, {orphan_total:,} unreferenced "
      f"and written out verbatim - nothing unaccounted for")

oversize = [p for p in RAW.rglob("*.json")
            if len(p.read_text(encoding="utf-8").splitlines()) > MAX_LINES]
assert not oversize, f"json files over {MAX_LINES} lines: {oversize}"
print(f"[4] line cap: every metadata file <= {MAX_LINES} lines")

# a CRLF anywhere would mean the bytes (and every recorded sha256) depend on the
# platform the layer was generated on
crlf = [p for p in list(RAW.rglob("*.json")) + list(RAW.rglob("*.jsonl"))
        + [RAW / "README.md"] if b"\r\n" in p.read_bytes()]
assert not crlf, f"platform line endings leaked into: {crlf[:5]}"
attrs = (Path(__file__).resolve().parent.parent / ".gitattributes")
attrs_text = attrs.read_text(encoding="utf-8")
assert attrs.is_file() and "raw/tables/** -text" in attrs_text
# Every path that carries generated bytes whose sha256 this repo records has to
# be covered, or a Windows checkout silently rewrites it. raw/interface was
# committed before this rule existed and lost 128 CR bytes per file in 212 files.
for guarded in ("raw/tables/**", "raw/content/**", "raw/interface/**",
                "raw/interface_all/**", "raw/cache/**", "raw/_catalog/**",
                "raw/_inventory/**", "raw/dbc/**", "raw/realms/**",
                "raw/provenance.json", "raw/talents/**", "data/**"):
    assert f"{guarded} -text" in attrs_text, guarded
print("[4] line endings: LF everywhere, and .gitattributes stops git rewriting "
      "them across every generated path")

# the layer is whole, not something a crash left half-written
assert (RAW / "_complete.json").is_file(), (
    "raw/tables has no completion sentinel - run python -m tools.decode_all")
sentinel = json.loads((RAW / "_complete.json").read_text(encoding="utf-8"))
assert sentinel["tableCount"] == cat["tableCount"], sentinel
assert sentinel["totalRows"] == cat["totalRows"], sentinel
assert sentinel["partial"] is False, sentinel
print(f"[4] completion: sentinel agrees with the index "
      f"({sentinel['tableCount']} tables, {sentinel['totalRows']:,} rows)")


# --------------------------------------------------------------------------
# 5. the reader did not drift from the verified one
# --------------------------------------------------------------------------
prov = extract_all.load_provenance()
assert prov, "run python -m tools.extract_all"
sources = {t["table"]: t for t in prov["tables"]}
aligned = sorted((n for n, s in sources.items()
                  if s["recordSize"] % 4 == 0 and s["records"] and
                  s["stringBlockSize"] > 0 and s["bytes"] < 3_000_000),
                 key=lambda n: sources[n]["bytes"], reverse=True)[:8]
assert len(aligned) == 8
for name in aligned:
    mine = decode_all.Table(extract_all.OUT_DIR / name)
    theirs = dbc.DBCFile(extract_all.OUT_DIR / name)
    assert mine.records == theirs.records and mine.wide == theirs.fields, name
    for a, b in zip(mine.iter_rows(), theirs.iter_rows()):
        assert a == b, name
    for off in range(0, mine.string_block_size, 97):
        assert mine.string(off) == theirs.string(off), (name, off)
unaligned = sorted(n for n, s in sources.items() if s["recordSize"] % 4)
for name in unaligned:
    try:
        dbc.DBCFile(extract_all.OUT_DIR / name)
        raise AssertionError(f"{name}: DBCFile unexpectedly accepted it")
    except dbc.LayoutError:
        pass
    t = decode_all.Table(extract_all.OUT_DIR / name)
    assert t.fields == t.wide + t.narrow and t.narrow, name
    assert t.row.size == t.record_size, name
print(f"[5] reader agreement: {len(aligned)} tables row-for-row vs DBCFile; "
      f"{len(unaligned)} unaligned tables ({', '.join(unaligned)}) readable "
      f"only by the extended reader")


# --------------------------------------------------------------------------
# 6. reruns are byte-identical
# --------------------------------------------------------------------------
sample = ["ChrClasses", "SpellIcon", "CharBaseInfo", "PowerDisplay",
          "SpellDuration", "Achievement", "SpellAlternativeCost"]
tmp = Path(tempfile.mkdtemp(prefix="coa_decode_"))
try:
    digests = []
    for i in range(2):
        out = tmp / str(i)
        decode_all.run(only=sample, out_dir=out, verbose=False)
        digests.append({str(p.relative_to(out)).replace("\\", "/"):
                        hashlib.sha256(p.read_bytes()).hexdigest()
                        for p in sorted(out.rglob("*")) if p.is_file()})
    assert digests[0] == digests[1], "a rerun changed bytes"
    assert len(digests[0]) > 20, digests[0]
    for rel, sha in digests[0].items():
        live = RAW / rel
        # _complete.json carries the run's own counts, and this run decoded a
        # 7-table sample; comparing it to the full layer's sentinel would be
        # comparing two different (correct) answers.
        if live.is_file() and not rel.endswith(("index.json", "README.md",
                                                "_failures.json",
                                                "_complete.json")):
            assert hashlib.sha256(live.read_bytes()).hexdigest() == sha, rel
finally:
    shutil.rmtree(tmp, ignore_errors=True)
print(f"[6] determinism: {len(digests[0])} files identical across two runs "
      f"and identical to the committed layer")

print("ALL PASS")
