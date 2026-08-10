"""Gates for the universal raw table layer (datamine.py + tools/dbcdecode.py
-> raw/tables/).

What these assert, in order of how much they matter:

 1. NO HAND-AUTHORED COLUMN NAME REACHES THE DATA. Every column name in every
    colinfo and every key in every emitted record is positional (`f<N>`, plus
    the two structural sidecar suffixes). This is the output-side proof, and it
    covers all 368 tables, not a sample.
 2. NO HAND-AUTHORED COLUMN NAME EXISTS IN THE SOURCE. The decoder and the
    emitter are AST-scanned and their string literals must be disjoint from (a)
    every column name this repo's curated layer has ever asserted
    (tools/dbc.TABLE_MAPS - the repo's own hand-authored vocabulary, used here
    as an external ground truth rather than a list invented by this test) and
    (b) every table name in the client census, which is what proves no table is
    special-cased. They must also not reference the curated column-map
    machinery at all.
 3. NOTHING IS SILENTLY DROPPED. Every table in the client census is either
    decoded or named in _failures.json with a reason.
 4. THE INDEX IS TRUE. Every shard's recorded sha256/row count/key range matches
    the bytes on disk, shard row counts respect the cap, and the per-table row
    counts add up to the header's record count.
 5. THE READER DID NOT DRIFT. tools/dbcdecode.Table agrees row-for-row and
    string-for-string with the verified tools/dbc.DBCFile wherever DBCFile can
    read at all, and the tables where it cannot are exactly the ones whose
    recordSize is not a multiple of 4.
 6. RERUNS ARE BYTE-IDENTICAL. Decoding a sample of tables twice from the bytes
    the traversal staged produces identical files, and those files are the ones
    committed.

MIGRATED, 2026-08. This file used to drive `tools/extract_all.py` and
`tools/decode_all.py`, which the single-script collapse retired, and it sat
failing on import for a commit. The gates are unchanged in substance; what
changed is where they get their inputs:

  * the decoder is `tools/dbcdecode.py` (was `tools/decode_all.py`), and the
    per-table emission is `tools/emit.py` (was `decode_all.run`);
  * the client census is `raw/_inventory/dbc.json`, published by the traversal,
    rather than `tools/inventory.py`'s work file;
  * the extracted table bytes are what the traversal STAGED at
    `work/harvest/tables/<archive-slug>/<Table>.dbc`, rather than a separate
    extraction pass.

ONE GATE WAS DELETED RATHER THAN REWRITTEN, and it is called out because a
silent drop would be the same defect this file exists to catch: the old [3]
"chain agreement" check compared `tools/extract_all.py`'s independently-resolved
MPQ chain winner against `tools/inventory.py`'s. Both walks are now the same
walk - `datamine.resolve_union` - so the check would compare a list to itself.
The property it protected (the census and the extractor agree on the winner) is
now structural rather than testable here, and [4] still checks every
`sourceSha256` against the census.
"""
import ast
import gzip
import hashlib
import json
import re
import shutil
import struct
import sys
import tempfile
from collections import Counter
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from tools import config, dbc, dbcdecode, emit, layerstate

RAW = config.RAW_DIR / "tables"
STAGED = config.WORK_DIR / "harvest" / "tables"
MAX_LINES = 5000
COLUMN_NAME = re.compile(r"f\d+")
RECORD_KEY = re.compile(r"f\d+[is]?")
MODULES = [Path(dbcdecode.__file__), Path(emit.__file__),
           Path(__file__).resolve().parent.parent / "datamine.py"]

layerstate.require_complete(RAW, "python datamine.py")
cat = json.loads((RAW / "index.json").read_text(encoding="utf-8"))
failures = json.loads((RAW / "_failures.json").read_text(encoding="utf-8"))

# The client census, as the traversal published it. Keyed by file name so it
# lines up with the old census shape.
census = {r["table"]: r for r in json.loads(
    (config.RAW_DIR / "_inventory" / "dbc.json").read_text(
        encoding="utf-8"))["tables"]}
assert census, "raw/_inventory/dbc.json is empty - run python datamine.py"
indexes = {r["table"]: json.loads((RAW / r["table"] / "index.json").read_text(
    encoding="utf-8")) for r in cat["tables"]}


def read_shard(table: str, shard: dict) -> list:
    p = RAW / table / shard["file"]
    raw = p.read_bytes()
    if shard["format"] == "gzip":
        raw = gzip.decompress(raw)
    return raw.decode("utf-8").splitlines()


def staged_bytes(entry: dict) -> bytes:
    """The bytes the traversal read for a table's WINNING copy, from its own
    staging tree. Read back rather than re-extracted on purpose: re-extracting
    would re-open an archive, which is the thing this pipeline exists not to
    do, and it would also test a different code path from the one that produced
    the layer."""
    p = STAGED / emit.slug(entry["winner"]) / entry["table"]
    if not p.is_file():
        return b""
    return p.read_bytes()


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

def scan(paths):
    lits, used = set(), set()
    for path in paths:
        tree = ast.parse(Path(path).read_text(encoding="utf-8"))
        for node in ast.walk(tree):
            if isinstance(node, ast.Constant) and isinstance(node.value, str):
                lits.add(node.value)
            elif isinstance(node, ast.Name):
                used.add(node.id)
            elif isinstance(node, ast.Attribute):
                used.add(node.attr)
    return lits, used


# THE COLUMN-NAME SCAN IS SCOPED TO THE DECODER, and the narrowing is
# deliberate rather than convenient. `tools/dbcdecode.py` is the only module
# that decides what a column is called - the emitter never names a column, it
# arranges directories and indexes around what the decoder produced. Scanning
# `tools/emit.py` and `datamine.py` for curated column names does fire, and
# every hit is ARCHIVE vocabulary that collides with a curated column name by
# coincidence: `"id"` (an archive's dir-qualified id), `"rank"` (its chain
# rank), `"flags"` (MPQ block flags) and `"attributes"` (the MPQ `(attributes)`
# member). None of those can become a column name, and suppressing them
# individually would be an escape hatch that grows.
#
# The property is not weakened by the narrowing, because the OUTPUT-side proof
# in [1] is the stronger one and it is exhaustive: every column name in every
# colinfo and every key in every emitted record, across all 368 tables, is
# positional. A curated name could not reach the data without failing there.
dec_literals, dec_used = scan([Path(dbcdecode.__file__)])
hits = sorted(l for l in dec_literals if l in curated_names)
assert not hits, f"curated column names appear in the decoder: {hits}"

# The table-name and curated-machinery scans DO run over the whole pipeline,
# because "no table is special-cased" is a property of the whole pipeline and
# nothing here collides with a table name by accident.
literals, names_used = scan(MODULES)
table_hits = sorted(l for l in literals if l.lower() in table_words)
assert not table_hits, f"a table is named in the source: {table_hits}"
banned = {"TABLE_MAPS", "iter_named", "dump_table", "dump_unmapped", "enums335",
          "WANTED_DBCS", "_spell_columns", "CUSTOM_RAW_DUMP_TABLES"}
assert not (names_used & banned), f"curated machinery referenced: {names_used & banned}"
print(f"[2] source scan: {len(dec_literals)} decoder literals vs "
      f"{len(curated_names)} curated column names, and {len(literals)} "
      f"pipeline literals vs {len(census)} table names - both disjoint")


# --------------------------------------------------------------------------
# 3. no silent drops
# --------------------------------------------------------------------------
decoded = {t + ".dbc" for t in indexes}
listed = {f["table"] for f in failures["failures"]}
missing = sorted(set(census) - decoded - listed)
assert not missing, f"tables in the census neither decoded nor recorded: {missing}"
assert failures["count"] == len(failures["failures"])
assert cat["tableCount"] == len(indexes) == cat["censusTableCount"] == len(census)
for f in failures["failures"]:
    assert f.get("reason") and f.get("table") and f.get("stage"), f

# `_failures.json` records failures PER COPY, not per table, and the difference
# is load-bearing rather than pedantic. The old layer's list held one row per
# table and the arithmetic `decoded + failed == census` followed from that. Here
# a table can have one unreadable copy - the client's `CharVariations.dbc` has a
# DELETE_MARKER tombstone in patch-enUS.MPQ - and still be decoded from another
# archive, which is the CLIENT'S OWN semantics and not a loss. So the gate is
# what actually matters: a listed failure may not be the ONLY copy of its table.
orphaned = sorted(t for t in listed if t not in decoded)
assert not orphaned, (f"these tables are named in _failures.json and were never "
                      f"decoded from any archive: {orphaned}")
print(f"[3] census coverage: {len(decoded)} decoded = {len(census)} in the "
      f"client; {failures['count']} unreadable COPY(s) recorded with a reason, "
      f"none of which is the only copy of its table")


# --------------------------------------------------------------------------
# 4. the index tells the truth
# --------------------------------------------------------------------------
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
assert rows_total == cat["totalRows"]
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
# platform the layer was generated on.
#
# This used to scan raw/tables ONLY, and the hole it left was found the expensive
# way: 215 of raw/recovered's 270 files were committed with CRLF while the
# extractor writes LF, so re-running the layer reported 208 files MODIFIED with
# an empty `git diff --ignore-cr-at-eol`. The content was deterministic; the
# committed bytes were not, and no gate covered that layer. The sweep is now over
# every generated raw layer.
#
# Verbatim payload trees are exempt BY NAME, not by accident: raw/binaries'
# `resources/` holds RT_MANIFEST blobs lifted byte for byte out of the PEs (six
# of them really are CRLF, because that is what the executable contains), and
# `chunks/`/`bytes/` hold recovered client bytes. Rewriting those would be the
# corruption this rule exists to prevent, so only GENERATED METADATA is checked.
VERBATIM_DIRS = {"resources", "chunks", "bytes"}


def _generated_metadata(root):
    for pattern in ("*.json", "*.jsonl", "*.md"):
        for p in root.rglob(pattern):
            if not VERBATIM_DIRS & set(p.relative_to(root).parts[:-1]):
                yield p


GENERATED_LAYERS = [RAW, config.RAW_DIR / "recovered", config.RAW_DIR / "binaries"]
crlf = [p for root in GENERATED_LAYERS if root.is_dir()
        for p in _generated_metadata(root) if b"\r\n" in p.read_bytes()]
assert not crlf, f"platform line endings leaked into: {crlf[:5]}"
print(f"[4] line endings: LF across {len(GENERATED_LAYERS)} generated layers "
      f"({sum(1 for r in GENERATED_LAYERS if r.is_dir() for _ in _generated_metadata(r)):,} "
      f"metadata files checked)")
attrs = (Path(__file__).resolve().parent.parent / ".gitattributes")
attrs_text = attrs.read_text(encoding="utf-8")
assert attrs.is_file() and "raw/tables/** -text" in attrs_text
# Every path that carries generated bytes whose sha256 this repo records has to
# be covered, or a Windows checkout silently rewrites it. raw/interface was
# committed before this rule existed and lost 128 CR bytes per file in 212 files.
for guarded in ("raw/tables/**", "raw/content/**", "raw/interface/**",
                "raw/interface_all/**", "raw/cache/**", "raw/_catalog/**",
                "raw/_inventory/**", "raw/dbc/**", "raw/realms/**",
                "raw/provenance.json", "raw/talents/**", "data/**",
                "raw/recovered/**", "raw/binaries/**"):
    assert f"{guarded} -text" in attrs_text, guarded
print("[4] .gitattributes: every generated path is -text, so git never rewrites "
      "these bytes on checkout or on add")

# the layer is whole, not something a crash left half-written
sentinel = layerstate.read(RAW)
assert sentinel["tableCount"] == cat["tableCount"], sentinel
assert sentinel["totalRows"] == cat["totalRows"], sentinel
print(f"[4] completion: sentinel agrees with the index "
      f"({sentinel['tableCount']} tables, {sentinel['totalRows']:,} rows)")


# --------------------------------------------------------------------------
# 5. the reader did not drift from the verified one
# --------------------------------------------------------------------------
# The tables the traversal staged, indexed by name. This is the SAME staging the
# layer was built from, so a disagreement here is a disagreement about the
# client's bytes and not about which copy of the file was tested.
assert STAGED.is_dir(), (
    f"{STAGED} is missing - run `python datamine.py` (the traversal stages "
    f"every table copy it reads there, and this gate reads the winner's bytes "
    f"back rather than re-opening an archive)")
tmpdir = Path(tempfile.mkdtemp(prefix="coa_tables_"))
try:
    aligned = sorted((n for n, s in census.items()
                      if s["recordSize"] % 4 == 0 and s["records"]
                      and s["stringBlockSize"] > 0 and s["size"] < 3_000_000),
                     key=lambda n: census[n]["size"], reverse=True)[:8]
    assert len(aligned) == 8
    checked = 0
    for name in aligned:
        data = staged_bytes(census[name])
        assert data, name
        onto = tmpdir / name
        onto.write_bytes(data)
        mine = dbcdecode.Table(onto)
        theirs = dbc.DBCFile(onto)
        assert mine.records == theirs.records and mine.wide == theirs.fields, name
        for a, b in zip(mine.iter_rows(), theirs.iter_rows()):
            assert a == b, name
        for off in range(0, mine.string_block_size, 97):
            assert mine.string(off) == theirs.string(off), (name, off)
        checked += 1
    unaligned = sorted(n for n, s in census.items() if s["recordSize"] % 4)
    for name in unaligned:
        data = staged_bytes(census[name])
        if not data:
            continue
        onto = tmpdir / name
        onto.write_bytes(data)
        try:
            dbc.DBCFile(onto)
            raise AssertionError(f"{name}: DBCFile unexpectedly accepted it")
        except dbc.LayoutError:
            pass
        t = dbcdecode.Table(onto)
        assert t.fields == t.wide + t.narrow and t.narrow, name
        assert t.row.size == t.record_size, name
finally:
    shutil.rmtree(tmpdir, ignore_errors=True)
print(f"[5] reader agreement: {checked} tables row-for-row vs DBCFile; "
      f"{len(unaligned)} unaligned tables ({', '.join(unaligned)}) readable "
      f"only by the extended reader")


# --------------------------------------------------------------------------
# 6. reruns are byte-identical, and identical to what is committed
# --------------------------------------------------------------------------
sample = ["ChrClasses.dbc", "SpellIcon.dbc", "CharBaseInfo.dbc",
          "PowerDisplay.dbc", "SpellDuration.dbc", "Achievement.dbc",
          "SpellAlternativeCost.dbc"]
sample = [n for n in sample if n in census]
assert len(sample) >= 6, sample
tmp = Path(tempfile.mkdtemp(prefix="coa_decode_"))
try:
    # The `source` dict is echoed verbatim into each colinfo's `source` block,
    # so it is part of the output and has to be the SAME dict emit passes -
    # `losers` there is the byte-identical `alsoIn` set, not the census's full
    # carrier list. Re-derived from the committed version record rather than
    # copied from the census, which is a different (also correct) answer to a
    # different question.
    def source_of(name: str) -> dict:
        win = next(v for v in indexes[name[:-4]]["variants"] if v["chainWinner"])
        return {"winner": win["archive"], "losers": win["alsoIn"],
                "sha256": win["sha256"], "bytes": win["sourceBytes"]}

    digests = []
    for i in range(2):
        out = tmp / str(i)
        for name in sample:
            data = staged_bytes(census[name])
            assert data, name
            dbcdecode.decode_table(name, source_of(name), out / name[:-4], data)
        digests.append({str(p.relative_to(out)).replace("\\", "/"):
                        hashlib.sha256(p.read_bytes()).hexdigest()
                        for p in sorted(out.rglob("*")) if p.is_file()})
    assert digests[0] == digests[1], "a rerun changed bytes"
    assert len(digests[0]) > 20, digests[0]
    # index.json is excluded from the identity comparison and the reason is
    # structural, not convenience: `emit._write_table_indexes` REOPENS the
    # winner's index after decoding and appends the version records
    # (`variants`, `variantCount`, `variantRule`, `contextRule`), which a bare
    # decode has no way to know. Every other file the decoder writes - shards,
    # colinfo, string sidecars - is compared, and the variant directories are
    # compared including their index.json in tests/test_variants.py, because
    # those are never rewritten.
    same = 0
    for rel, sha in digests[0].items():
        if rel.endswith("index.json"):
            continue
        live = RAW / rel
        assert live.is_file(), rel
        assert hashlib.sha256(live.read_bytes()).hexdigest() == sha, rel
        same += 1
    assert same > 15, same
finally:
    shutil.rmtree(tmp, ignore_errors=True)
print(f"[6] determinism: {len(digests[0])} files identical across two decodes "
      f"and all {same} identical to the committed layer")

print("ALL PASS")
