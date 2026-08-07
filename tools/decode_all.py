"""Mechanically decode every extracted client table into the raw layer.

    python -m tools.decode_all          # THE entry point: extracts (if needed), decodes

Step 2 of the raw table layer; step 1 is tools/extract_all.py, which this module
runs for you when work/dbc_all is missing or does not match the client. Output
lands in raw/tables/ - one directory per table, plus a generated catalog.

WHAT "MECHANICAL" MEANS HERE
----------------------------
Columns are f0..fN. There is no column-name table in this module, no enum table,
no per-table branch, and no table is mentioned by name anywhere in it. Every
statement the layer makes about a column is a MEASUREMENT over the whole column,
and the measurement is emitted next to the conclusion so a reader can disagree
with the conclusion without losing the data.

TYPES ARE INFERRED, NEVER ASSERTED
----------------------------------
Per column the decoder counts, over every row:

  int      the raw 4-byte little-endian signed value, as the verified reader
           reads it (tools/dbc.DBCFile). Always available; this is the floor.
  float    the same 4 bytes read as IEEE-754 binary32. Counted as plausible
           when the result is finite and its magnitude is within
           [FLOAT_ABS_MIN, FLOAT_ABS_MAX]. Small integers decode to denormals
           far below that band, so a column of small ints scores ~0 here while
           a real float column scores 1.0.
  string   the value as an offset into the table's string block. Counted as
           valid when it is 0, or points just past a NUL (i.e. at the first
           byte of a NUL-terminated string). Offset 0 holds REAL CONTENT in
           this build - it is not an empty sentinel - which is why the reader's
           offset-0 semantics are reused verbatim.

The rule that turns those counts into `inferred` is fixed and documented in
INFERENCE_RULE below. It runs on the numbers, in the same order, for all 368
tables.

NOTHING IS LOST TO A WRONG INFERENCE
------------------------------------
A record key is `f<N>`, optionally suffixed:

  f5      the value under the inferred type
  f5i     the raw int, present when f5 was decoded as a string
  f5s     the decoded string, present when f5 was decoded as an int and the
          column is nonetheless a valid string-offset column

So a column the rule calls wrong in either direction still carries both
readings. Floats need no sidecar: the emitted value is the exact binary32, so
the 4 bytes are recoverable from it.

HEADER ANOMALIES ARE HANDLED BY MEASUREMENT
-------------------------------------------
recordSize, not the declared field count, determines the row stride (10 tables
in this client declare a count that disagrees; both numbers are recorded). When
recordSize is not a multiple of 4 the 4-byte field model provably does not
describe the record, so the row is read as recordSize//4 four-byte columns
followed by recordSize%4 one-byte columns - no bytes are dropped, and the widths
are recorded per column. Zero-row tables decode to zero shards and still emit
their header facts.

SHARDING AND COMPRESSION
------------------------
See SHARD_RULE and COMPRESSION_RULE. Both are stated in the generated
raw/tables/README.md too, so the layer explains itself without this file.
"""
import argparse
import array
import bisect
import gzip
import hashlib
import json
import re
import struct
import sys
import time
from collections import Counter
from pathlib import Path

from tools import config, sharding
from tools.extract_all import OUT_DIR as SRC_DIR
from tools.extract_all import PROVENANCE, extract, load_provenance

OUT_DIR = config.RAW_DIR / "tables"

SHARD_MAX_ROWS = 5000
PLAIN_MAX_TABLE_BYTES = 1 << 20    # 1 MiB of decoded text, per table
SAMPLES_PER_COLUMN = 5

# Magnitude band a binary32 must land in to count as a plausible float. The low
# bound sits far above the denormal range small integers decode into (int 5 ->
# 7.0e-45), the high bound far above any real game constant.
FLOAT_ABS_MIN = 1e-20
FLOAT_ABS_MAX = 1e20

SHARD_RULE = (
    "Rows are grouped by the unsigned value of one column - f0 unless f0 cannot "
    "keep every group within the cap, in which case the lowest-indexed column "
    "that can is used, and if no column can, fixed row-index blocks are used "
    "(recorded per table as shardKey.mode). A group is a fixed decimal-prefix "
    "range of that value, split only where a range exceeds "
    f"{SHARD_MAX_ROWS} rows, so a row's shard is a function of the row's own "
    "value and never shifts because a neighbouring range grew. Shard files are "
    "named <lo>-<hi> over that value, zero-padded to a fixed width."
)

COMPRESSION_RULE = (
    "The decision is per table, so a table is never half-readable: when a "
    f"table's whole decoded text is <= {PLAIN_MAX_TABLE_BYTES} bytes its "
    "shards stay plain .jsonl and grep reads them directly, and when it is "
    "larger every shard is written as .jsonl.gz (deflate level 9, gzip mtime "
    "and name fields zeroed so reruns are byte-identical). The choice and both "
    "byte counts are recorded per table and per shard in the table index. "
    "Small tables are the long tail an agent greps; the handful of large ones "
    "compress by roughly 20x and would otherwise be the whole layer's weight."
)

INFERENCE_RULE = (
    "Per column, in this order: no rows -> unknown; every value zero -> zero; "
    "one-byte column -> int (a single byte can be neither a binary32 nor a "
    "string offset); every value a valid string offset AND every referenced "
    "string strict-UTF-8 AND free of control characters AND at least one of "
    "them non-empty -> string; every non-zero value a plausible binary32 "
    f"(finite, magnitude in [{FLOAT_ABS_MIN}, {FLOAT_ABS_MAX}]) -> float; "
    "otherwise int. Every count the rule reads is emitted under the column's "
    "`evidence`, so the conclusion is auditable and reversible."
)

HEADER = struct.Struct("<4s4I")
_F32 = struct.Struct("<f")
_I32 = struct.Struct("<i")
_CONTROL = re.compile(r"[\x00-\x08\x0b\x0c\x0e-\x1f]")
_FAST_INTS = sys.byteorder == "little" and array.array("i").itemsize == 4
_RESERVED = {"con", "prn", "aux", "nul", "com1", "com2", "com3", "com4", "com5",
             "com6", "com7", "com8", "com9", "lpt1", "lpt2", "lpt3", "lpt4",
             "lpt5", "lpt6", "lpt7", "lpt8", "lpt9"}


class DecodeError(RuntimeError):
    pass


def write_text(path: Path, text: str) -> None:
    """UTF-8, LF, no BOM - always. Path.write_text() would translate newlines to
    the platform's, which would make this layer's bytes (and every sha256 the
    index records for them) depend on the OS it was generated on. The shards are
    written as bytes for the same reason."""
    path.write_bytes(text.encode("utf-8"))


# --------------------------------------------------------------------------
# reader
# --------------------------------------------------------------------------

class Table:
    """WDBC reader with the same verified semantics as tools/dbc.DBCFile - the
    record stride comes from recordSize, and string-block offset 0 is real
    content, not an empty sentinel - extended in the two places a universal
    decoder needs and that reader refuses: a recordSize that is not a multiple
    of 4 (read as a 4-byte prefix plus 1-byte tail columns instead of raising)
    and a string block whose last entry is unterminated (clipped and counted
    instead of raising). tests/test_raw_tables.py pins this reader against
    DBCFile row-for-row and string-for-string on the tables where DBCFile can
    read at all, so the two cannot drift."""

    def __init__(self, path: Path):
        self.path = Path(path)
        data = self.path.read_bytes()
        if len(data) < HEADER.size:
            raise DecodeError(f"file is {len(data)} bytes, shorter than a header")
        magic, self.records, self.declared_fields, self.record_size, str_size = \
            HEADER.unpack_from(data, 0)
        self.magic = magic.decode("latin-1")
        if magic != b"WDBC":
            raise DecodeError(f"magic {self.magic!r}")
        if self.record_size == 0 and self.records:
            raise DecodeError(f"recordSize 0 with {self.records} records")
        body_end = HEADER.size + self.records * self.record_size
        if body_end > len(data):
            raise DecodeError(
                f"body needs {body_end} bytes, file has {len(data)}")
        self.size_reconciles = body_end + str_size == len(data)
        self.body = data[HEADER.size:body_end]
        self.strings = data[body_end:]
        self.string_block_size = str_size
        self.wide = self.record_size // 4
        self.narrow = self.record_size % 4
        self.fields = self.wide + self.narrow
        self.row = struct.Struct(f"<{self.wide}i{self.narrow}B")
        self.unterminated = 0
        self._buf = None

    def widths(self) -> list:
        return [4] * self.wide + [1] * self.narrow

    def row_at(self, i: int) -> tuple:
        return self.row.unpack_from(self.body, i * self.record_size)

    def iter_rows(self):
        if self.record_size:
            return self.row.iter_unpack(self.body)
        return iter(())

    def column(self, c: int):
        """Every value of one column, as a sequence. Uses a C-level strided
        slice when the platform's int is a little-endian 4-byte int (the only
        arrangement this format is written in), and falls back to unpacking
        rows otherwise, so the result is identical either way."""
        if c < self.wide and self.narrow == 0 and _FAST_INTS:
            if self._buf is None:
                self._buf = array.array("i")
                self._buf.frombytes(self.body)
            return self._buf[c::self.wide]
        return [r[c] for r in self.iter_rows()]

    def string(self, offset: int) -> str:
        if offset < 0 or offset >= len(self.strings):
            return ""
        end = self.strings.find(b"\x00", offset)
        if end < 0:
            self.unterminated += 1
            end = len(self.strings)
        return self.strings[offset:end].decode("utf-8", "replace")

    def raw_string(self, offset: int) -> bytes:
        if offset < 0 or offset >= len(self.strings):
            return b""
        end = self.strings.find(b"\x00", offset)
        if end < 0:
            end = len(self.strings)
        return self.strings[offset:end]

    def offset_is_valid(self, v: int) -> bool:
        if self.string_block_size <= 0 or v < 0 or v >= len(self.strings):
            return False
        return v == 0 or self.strings[v - 1] == 0


# --------------------------------------------------------------------------
# per-column measurement
# --------------------------------------------------------------------------

def measure(t: Table, c: int, counts: Counter, width: int) -> dict:
    """Every count the inference rule reads, plus the ones a reader needs to
    disagree with it. Runs over the column's distinct values weighted by their
    row counts, which is exactly equivalent to running over every row."""
    rows = t.records
    keys = list(counts)
    zero = counts.get(0, 0)
    non_zero = rows - zero
    ev = {
        "rows": rows,
        "distinct": len(keys),
        "zeroCount": zero,
        "nonZeroCount": non_zero,
        "negativeCount": sum(n for k, n in counts.items() if k < 0),
        "minSigned": min(keys) if keys else None,
        "maxSigned": max(keys) if keys else None,
        "minUnsigned": min((k & 0xFFFFFFFF) for k in keys) if keys else None,
        "maxUnsigned": max((k & 0xFFFFFFFF) for k in keys) if keys else None,
    }
    if width != 4:
        # a single byte is neither a binary32 nor a string offset; the two
        # hypotheses are not applicable rather than merely unsupported
        ev["float"] = {"applicable": False}
        ev["string"] = {"applicable": False}
        return {"evidence": ev, "samples": [], "offsets": [],
                "stringDecodable": False}

    finite = plausible = 0
    lo = hi = None
    for k, n in counts.items():
        if k == 0:
            continue
        v = _F32.unpack(_I32.pack(k))[0]
        if v == v and v not in (float("inf"), float("-inf")):
            finite += n
            a = abs(v)
            if FLOAT_ABS_MIN <= a <= FLOAT_ABS_MAX:
                plausible += n
                lo = a if lo is None or a < lo else lo
                hi = a if hi is None or a > hi else hi
    ev["float"] = {
        "applicable": True,
        "finiteRate": _rate(finite, non_zero),
        "plausibleRate": _rate(plausible, non_zero),
        "plausibleAbsMin": lo,
        "plausibleAbsMax": hi,
    }

    valid = valid_rows = 0
    offsets, decodable, control, non_empty, total_len, covered = [], 0, 0, 0, 0, 0
    for k, n in counts.items():
        if not t.offset_is_valid(k):
            continue
        valid += 1
        valid_rows += n
        offsets.append(k)
        b = t.raw_string(k)
        covered += len(b) + 1
        try:
            s = b.decode("utf-8")
        except UnicodeDecodeError:
            continue
        decodable += 1
        if _CONTROL.search(s):
            control += 1
        if s:
            non_empty += 1
        total_len += len(s)
    ev["string"] = {
        "applicable": t.string_block_size > 0,
        "blockSize": t.string_block_size,
        "validOffsetRate": _rate(valid_rows, rows),
        "distinctOffsets": valid,
        "utf8DecodableOffsets": decodable,
        "controlCharOffsets": control,
        "nonEmptyOffsets": non_empty,
        "meanDecodedLength": round(total_len / valid, 3) if valid else 0.0,
        "blockCoverageRate": _rate(covered, t.string_block_size),
    }
    all_valid = valid == len(keys) and valid_rows == rows and rows > 0
    decodable_all = decodable == valid and control == 0
    samples = []
    for off in sorted(offsets)[:SAMPLES_PER_COLUMN * 8]:
        s = t.string(off)
        if s and s not in samples:
            samples.append(s)
        if len(samples) >= SAMPLES_PER_COLUMN:
            break
    return {"evidence": ev, "samples": samples, "offsets": offsets,
            "stringDecodable": bool(all_valid and decodable_all)}


def unreferenced_entries(t: Table, referenced: set) -> list:
    """Every NUL-terminated entry in the string block that no column points at.
    Without this the layer would drop those bytes silently: they exist in the
    table and no record carries them. On this client the residual is a few
    kilobytes in total, but it is emitted rather than assumed away, so the
    string block is provably accounted for byte by byte."""
    out, pos, blob = [], 0, t.strings
    while pos < len(blob):
        end = blob.find(b"\x00", pos)
        if end < 0:
            end = len(blob)
        if pos not in referenced:
            out.append({"offset": pos, "bytes": end - pos + 1,
                        "text": blob[pos:end].decode("utf-8", "replace")})
        pos = end + 1
    return out


def _rate(part: int, whole: int) -> float:
    return round(part / whole, 6) if whole else 0.0


def infer(m: dict, rows: int, width: int) -> str:
    """INFERENCE_RULE, as code. Reads only `m`'s counts."""
    ev = m["evidence"]
    if rows == 0:
        return "unknown"
    if ev["nonZeroCount"] == 0:
        return "zero"
    if width != 4:
        return "int"
    if m["stringDecodable"] and ev["string"]["nonEmptyOffsets"] > 0:
        return "string"
    if ev["float"]["plausibleRate"] == 1.0:
        return "float"
    return "int"


# --------------------------------------------------------------------------
# sharding
# --------------------------------------------------------------------------

def plan_shards(counts: dict, limit: int) -> list:
    """Fixed decimal-prefix ranges over an unsigned key. A range splits only
    when it holds more than `limit` rows, so membership is a function of the
    key alone. Returns [(lo, hi, keys, rows)] sorted by lo."""
    width = max(1, len(str(max(counts))))
    out = []
    stack = [("", sorted(counts))]
    while stack:
        prefix, keys = stack.pop()
        total = sum(counts[k] for k in keys)
        if total <= limit or len(keys) == 1 or len(prefix) >= width:
            rest = width - len(prefix)
            out.append((int(prefix + "0" * rest) if prefix else 0,
                        int(prefix + "9" * rest) if prefix else 10 ** width - 1,
                        keys, total))
            continue
        d = len(prefix)
        groups = {}
        for k in keys:
            groups.setdefault(str(k).zfill(width)[d], []).append(k)
        for ch in sorted(groups):
            stack.append((prefix + ch, groups[ch]))
    out.sort()
    return [(lo, hi, keys, total, width) for lo, hi, keys, total in out]


def choose_shards(t: Table, key_counts: Counter, limit: int):
    """f0 first; the lowest-indexed column that keeps every range within the cap
    otherwise; fixed row blocks if no column can. Returns (mode, column, plan)."""
    if t.records <= limit or t.fields == 0:
        counts = key_counts if key_counts else Counter({0: t.records or 1})
        return "column", 0 if t.fields else None, plan_shards(
            {k & 0xFFFFFFFF: n for k, n in counts.items()}, limit)
    for c in range(t.fields):
        counts = key_counts if c == 0 else Counter(t.column(c))
        plan = plan_shards({k & 0xFFFFFFFF: n for k, n in counts.items()}, limit)
        if all(p[3] <= limit for p in plan):
            return "column", c, plan
    blocks = []
    width = max(1, len(str(max(0, t.records - 1))))
    for lo in range(0, t.records, limit):
        hi = min(lo + limit, t.records) - 1
        blocks.append((lo, hi, None, hi - lo + 1, width))
    return "rowIndex", None, blocks


# --------------------------------------------------------------------------
# emission
# --------------------------------------------------------------------------

def build_plan(t: Table, columns: list):
    """Template + per-value accessors for one table's records. Values that need
    conversion are looked up in a per-column cache keyed by the raw int, so the
    per-row work is a dict lookup and the formatting itself happens in C."""
    parts, plan = [], []
    for col in columns:
        c = col["index"]
        kind = col["inferred"]
        if kind == "string":
            col["_cache"] = cache = {}
            parts.append(f'"f{c}":%s,"f{c}i":%d')
            plan.append((c, cache))
            plan.append((c, None))
        elif kind == "float":
            col["_cache"] = cache = {}
            parts.append(f'"f{c}":%s')
            plan.append((c, cache))
        else:
            parts.append(f'"f{c}":%d')
            plan.append((c, None))
            if col.get("stringSidecar"):
                col["_cache"] = cache = {}
                parts.append(f'"f{c}s":%s')
                plan.append((c, cache))
    return "{" + ",".join(parts) + "}", plan


def fill_caches(t: Table, columns: list) -> None:
    for col in columns:
        cache = col.get("_cache")
        if cache is None:
            continue
        if col["inferred"] == "float":
            for k in col["_values"]:
                cache[k] = repr(_F32.unpack(_I32.pack(k))[0])
        else:
            for k in col["_values"]:
                cache[k] = json.dumps(t.string(k), ensure_ascii=False)


def render(t: Table, tmpl: str, plan: list, indices) -> list:
    simple = all(cache is None for _, cache in plan) and len(plan) == t.fields
    out = []
    if simple:
        if indices is None:
            for row in t.iter_rows():
                out.append(tmpl % row)
        else:
            for i in indices:
                out.append(tmpl % t.row_at(i))
        return out
    rows = t.iter_rows() if indices is None else (t.row_at(i) for i in indices)
    for row in rows:
        out.append(tmpl % tuple(row[c] if cache is None else cache[row[c]]
                                for c, cache in plan))
    return out


def write_plain(path: Path, lines: list) -> dict:
    data = "".join(l + "\n" for l in lines).encode("utf-8")
    path.write_bytes(data)
    return {"file": path.name, "format": "plain", "rows": len(lines),
            "plainBytes": len(data), "storedBytes": len(data),
            "sha256": hashlib.sha256(data).hexdigest()}


def compress_shard(d: Path, rec: dict) -> dict:
    """Rewrite one already-written plain shard as gzip. The table's format is
    decided from the sum of its shards, which is only known once they are all
    rendered, and rendering the biggest tables twice costs far more than
    reading a file back."""
    src = d / rec["file"]
    data = src.read_bytes()
    buf = bytearray()
    with gzip.GzipFile(filename="", mode="wb", compresslevel=9, mtime=0,
                       fileobj=_Sink(buf)) as gz:
        gz.write(data)
    stored = bytes(buf)
    out = src.with_name(src.name + ".gz")
    out.write_bytes(stored)
    src.unlink()
    rec.update({"file": out.name, "format": "gzip", "storedBytes": len(stored),
                "sha256": hashlib.sha256(stored).hexdigest()})
    return rec


class _Sink:
    """Minimal write-only file object so gzip output is assembled in memory and
    the archive's name/mtime fields cannot leak the output path or the clock."""

    def __init__(self, buf: bytearray):
        self.buf = buf

    def write(self, b) -> int:
        self.buf += b
        return len(b)

    def flush(self):
        pass


# --------------------------------------------------------------------------
# one table
# --------------------------------------------------------------------------

def decode_table(name: str, source: dict, out_dir: Path,
                 limit: int = SHARD_MAX_ROWS) -> dict:
    stem = name[:-4] if name.lower().endswith(".dbc") else name
    t = Table(SRC_DIR / name)
    d = out_dir / stem
    d.mkdir(parents=True, exist_ok=True)
    for old in sorted(d.iterdir()):        # sole writer of this directory
        if old.is_file():
            old.unlink()

    widths = t.widths()
    columns, key_counts, referenced = [], None, set()
    for c in range(t.fields):
        counts = Counter(t.column(c))
        if c == 0:
            key_counts = counts
        m = measure(t, c, counts, widths[c])
        referenced.update(m["offsets"])
        kind = infer(m, t.records, widths[c])
        col = {"index": c, "name": f"f{c}", "width": widths[c],
               "inferred": kind, "evidence": m["evidence"],
               "samples": m["samples"]}
        if kind != "string" and kind != "zero" and m["stringDecodable"] \
                and m["evidence"]["string"]["nonEmptyOffsets"] > 0:
            col["stringSidecar"] = True
        if kind in ("string", "float") or col.get("stringSidecar"):
            col["_values"] = list(counts)
        columns.append(col)

    mode, key_col, plan = choose_shards(t, key_counts or Counter(), limit)
    tmpl, emit = build_plan(t, columns)
    fill_caches(t, columns)

    shards = []
    if t.records and t.fields:
        if mode == "column":
            los = [p[0] for p in plan]
            buckets = [[] for _ in plan]
            for i, v in enumerate(t.column(key_col)):
                buckets[bisect.bisect_right(los, v & 0xFFFFFFFF) - 1].append(i)
            placed = sum(len(b) for b in buckets)
            if placed != t.records:
                raise DecodeError(
                    f"sharding placed {placed} of {t.records} rows")
        else:
            buckets = [list(range(p[0], p[1] + 1)) for p in plan]
        single = len(plan) == 1 and len(buckets[0]) == t.records
        for (lo, hi, _keys, _rows, width), idx in zip(plan, buckets):
            if not idx:
                continue
            lines = render(t, tmpl, emit, None if single else idx)
            rec = write_plain(d / f"{lo:0{width}d}-{hi:0{width}d}.jsonl", lines)
            rec.update({"lo": lo, "hi": hi})
            shards.append(rec)
        if sum(s["plainBytes"] for s in shards) > PLAIN_MAX_TABLE_BYTES:
            for rec in shards:
                compress_shard(d, rec)

    for col in columns:
        col.pop("_values", None)
        col.pop("_cache", None)

    orphans = unreferenced_entries(t, referenced)
    orphan_bytes = sum(o["bytes"] for o in orphans)
    if orphans:
        write_text(d / f"{stem}.strings.json", sharding.dump_manifest({
            "note": "String-block entries no column of this table points at. "
                    "They are emitted here so every byte of the string block is "
                    "accounted for by the layer, not silently dropped.",
            "table": stem, "count": len(orphans), "bytes": orphan_bytes,
            "entries": orphans,
        }))

    kinds = Counter(col["inferred"] for col in columns)
    colinfo = {
        "note": "Per-column measurement and the type it implies. `inferred` is "
                "produced by the fixed rule in raw/tables/README.md from the "
                "counts in `evidence`; nothing here is asserted from outside "
                "the bytes. Column names are positional by construction.",
        "table": stem, "file": name,
        "source": {k: source.get(k) for k in ("winner", "losers", "sha256", "bytes")},
        "header": {
            "magic": t.magic, "records": t.records,
            "declaredFields": t.declared_fields, "recordSize": t.record_size,
            "actualFields": t.wide, "trailingBytesPerRecord": t.narrow,
            "declaredFieldsAgrees": t.declared_fields == t.wide,
            "stringBlockSize": t.string_block_size,
            "stringBlockReferencedBytes": t.string_block_size - orphan_bytes,
            "stringBlockUnreferencedBytes": orphan_bytes,
            "stringBlockUnreferencedEntries": len(orphans),
            "sizeReconciles": t.size_reconciles,
            "unterminatedStringReads": t.unterminated,
        },
        "columnCount": t.fields,
        "inferredCounts": dict(sorted(kinds.items())),
        "columns": columns,
    }
    write_text(d / f"{stem}.colinfo.json", sharding.dump_manifest(colinfo))

    oversize = [s["file"] for s in shards if s["rows"] > limit]
    index = {
        "note": "Shard map for this table. Every record is one line of one "
                "shard; `lo`/`hi` bound the shard key, `sha256` is of the "
                "stored bytes, so a rerun that changes nothing changes no file.",
        "table": stem, "file": name,
        "rows": t.records, "columns": t.fields,
        "columnWidths": {"int32": t.wide, "byte": t.narrow},
        "sourceSha256": source.get("sha256"),
        "stringBlockSize": t.string_block_size,
        "unreferencedStringBytes": orphan_bytes,
        "shardKey": {"mode": mode,
                     "column": None if key_col is None else f"f{key_col}",
                     "unsigned": mode == "column", "maxRows": limit},
        "shardRule": SHARD_RULE,
        "compressionRule": COMPRESSION_RULE,
        "format": shards[0]["format"] if shards else "plain",
        "shardCount": len(shards),
        "oversizeShards": oversize,
        "plainBytes": sum(s["plainBytes"] for s in shards),
        "storedBytes": sum(s["storedBytes"] for s in shards),
        "inferredCounts": dict(sorted(kinds.items())),
        "shards": shards,
    }
    write_text(d / "index.json", sharding.dump_manifest(index))
    return index


# --------------------------------------------------------------------------
# driver
# --------------------------------------------------------------------------

def _census() -> dict:
    """The table list this layer must cover, from the client census if it has
    been generated, else from the extraction provenance."""
    inv = config.RAW_DIR / "_inventory" / "dbc.json"
    if inv.is_file():
        d = json.loads(inv.read_text(encoding="utf-8"))
        return {t["table"]: t for t in d["tables"]}
    return {}


def run(only=None, resume=False, out_dir: Path = None, verbose: bool = True,
        limit: int = SHARD_MAX_ROWS) -> dict:
    out_dir = out_dir or OUT_DIR
    t0 = time.time()
    prov = load_provenance()
    if not prov:
        if verbose:
            print("no extraction found - extracting", flush=True)
        prov = extract(verbose=verbose)
    sources = {t["table"]: t for t in prov["tables"]}
    census = _census()

    out_dir.mkdir(parents=True, exist_ok=True)
    names = sorted(sources, key=str.lower)
    if only:
        want = {o.lower() for o in only}
        names = [n for n in names
                 if n.lower() in want or n[:-4].lower() in want]
        if not names:
            raise SystemExit(f"no table matched {sorted(want)}")

    failures = list(prov.get("failures", []))
    indexes, skipped = {}, 0
    for i, name in enumerate(names):
        stem = name[:-4] if name.lower().endswith(".dbc") else name
        if stem.lower() in _RESERVED:
            failures.append({"table": name, "stage": "decode",
                             "reason": "name is reserved by the filesystem"})
            continue
        idx_path = out_dir / stem / "index.json"
        if resume and idx_path.is_file():
            old = json.loads(idx_path.read_text(encoding="utf-8"))
            if old.get("sourceSha256") == sources[name].get("sha256") and all(
                    (out_dir / stem / s["file"]).is_file() for s in old["shards"]):
                indexes[stem] = old
                skipped += 1
                continue
        try:
            indexes[stem] = decode_table(name, sources[name], out_dir, limit)
        except Exception as e:                       # noqa: BLE001 - recorded
            failures.append({"table": name, "stage": "decode",
                             "reason": f"{type(e).__name__}: {e}"})
            if verbose:
                print(f"  FAILED {name}: {type(e).__name__}: {e}", flush=True)
            continue
        if verbose and (i % 20 == 0 or i == len(names) - 1):
            ix = indexes[stem]
            print(f"  [{i+1:3d}/{len(names)}] {stem:44s} rows={ix['rows']:8d} "
                  f"cols={ix['columns']:4d} shards={ix['shardCount']:4d} "
                  f"[{time.time()-t0:6.1f}s]", flush=True)

    if not only:
        # sole writer: a table that vanished from the client must not linger
        for old in sorted(out_dir.iterdir()):
            if old.is_dir() and old.name not in indexes:
                for f in sorted(old.iterdir()):
                    f.unlink()
                old.rmdir()

    if only and (out_dir / "index.json").is_file():
        prior = json.loads((out_dir / "index.json").read_text(encoding="utf-8"))
        for rec in prior["tables"]:
            indexes.setdefault(rec["table"], None)

    catalog = write_catalog(out_dir, indexes, sources, census, failures, prov)
    catalog["elapsed"] = round(time.time() - t0, 1)
    catalog["skipped"] = skipped
    return catalog


def write_catalog(out_dir: Path, indexes: dict, sources: dict, census: dict,
                  failures: list, prov: dict) -> dict:
    rows = stored = plain = shard_count = 0
    str_bytes = str_orphan = 0
    kinds, formats = Counter(), Counter()
    records = []
    for stem in sorted(indexes, key=str.lower):
        ix = indexes[stem]
        if ix is None:
            ix = json.loads((out_dir / stem / "index.json").read_text(encoding="utf-8"))
        rows += ix["rows"]
        stored += ix["storedBytes"]
        plain += ix["plainBytes"]
        shard_count += ix["shardCount"]
        kinds.update(ix["inferredCounts"])
        formats[ix["format"]] += 1
        str_bytes += ix["stringBlockSize"]
        str_orphan += ix["unreferencedStringBytes"]
        records.append({"table": stem, "file": ix["file"], "rows": ix["rows"],
                        "columns": ix["columns"], "shards": ix["shardCount"],
                        "storedBytes": ix["storedBytes"],
                        "plainBytes": ix["plainBytes"], "format": ix["format"],
                        "shardKey": ix["shardKey"]["column"] or ix["shardKey"]["mode"],
                        "oversizeShards": len(ix["oversizeShards"]),
                        "winner": sources.get(ix["file"], {}).get("winner")})

    decoded = {r["table"] + ".dbc" for r in records}
    failed = {f["table"] for f in failures}
    missing = sorted(set(census) - decoded - failed)
    for name in missing:
        failures.append({"table": name, "stage": "decode",
                         "reason": "in the client census but not decoded"})

    write_text(out_dir / "_failures.json", sharding.dump_manifest({
        "note": "Every table the census names is either decoded or listed here "
                "with its reason. An empty list means zero silent drops.",
        "count": len(failures),
        "failures": sorted(failures, key=lambda f: (f["table"], f["stage"])),
    }))

    catalog = {
        "note": "Every table in the client, decoded to positional columns "
                "f0..fN. Start here: each record points at raw/tables/<table>/, "
                "which holds index.json (shard map), <table>.colinfo.json "
                "(per-column measurement + inferred type) and the shards "
                "themselves. See README.md for the rules.",
        "tableCount": len(records),
        "censusTableCount": len(census) or len(sources),
        "failureCount": len(failures),
        "totalRows": rows,
        "totalShards": shard_count,
        "plainBytes": plain,
        "storedBytes": stored,
        "stringBlockBytes": str_bytes,
        "unreferencedStringBytes": str_orphan,
        "inferredColumnCounts": dict(sorted(kinds.items())),
        "tablesByFormat": dict(sorted(formats.items())),
        "shardRule": SHARD_RULE,
        "compressionRule": COMPRESSION_RULE,
        "inferenceRule": INFERENCE_RULE,
        "tables": records,
    }
    write_text(out_dir / "index.json", sharding.dump_manifest(catalog))
    write_readme(out_dir)
    return catalog


def write_readme(out_dir: Path) -> None:
    """Generated from the emitted JSON, read back off disk, so the catalog can
    never quote a number the layer does not actually contain."""
    cat = json.loads((out_dir / "index.json").read_text(encoding="utf-8"))
    fail = json.loads((out_dir / "_failures.json").read_text(encoding="utf-8"))
    L = ["# Raw client tables (generated)\n"]
    L.append("Regenerate: `python -m tools.decode_all`. Every byte under this "
             "directory is written by `tools/decode_all.py` from "
             "`tools/extract_all.py`'s extraction of the MPQ chain. Nothing is "
             "hand-authored, no table is treated specially, and no table is "
             "left out.\n")
    L.append("## Totals\n")
    L.append(f"- **{cat['tableCount']} tables** decoded of "
             f"{cat['censusTableCount']} in the client census")
    L.append(f"- **{cat['failureCount']} failures** (`_failures.json`)")
    L.append(f"- **{cat['totalRows']:,} rows** in "
             f"{cat['totalShards']:,} shards")
    L.append(f"- **{cat['storedBytes']/1e6:.1f} MB** on disk "
             f"({cat['plainBytes']/1e6:.1f} MB uncompressed)")
    ref = cat["stringBlockBytes"] - cat["unreferencedStringBytes"]
    L.append(f"- **{cat['stringBlockBytes']:,} string-block bytes**: "
             f"{ref:,} reached by a decoded record, "
             f"{cat['unreferencedStringBytes']:,} referenced by no column and "
             f"written out verbatim to `<Table>.strings.json`\n")
    L.append("## Layout\n")
    L.append("```")
    L.append("raw/tables/index.json          every table: rows, columns, shards, bytes")
    L.append("raw/tables/_failures.json      anything not decoded, and why")
    L.append("raw/tables/<Table>/index.json  shard map: key ranges, format, sha256")
    L.append("raw/tables/<Table>/<Table>.colinfo.json")
    L.append("                               per column: measurement + inferred type")
    L.append("raw/tables/<Table>/<Table>.strings.json")
    L.append("                               string-block entries no column points at")
    L.append("raw/tables/<Table>/<lo>-<hi>.jsonl[.gz]")
    L.append("                               one record per line: {\"f0\":..,\"f1\":..}")
    L.append("```\n")
    L.append("## Reading a record\n")
    L.append("Keys are positional. `f5` is the value of column 5 under the type "
             "the measurement implies; `f5i` is the raw int when `f5` was "
             "decoded as a string; `f5s` is the decoded string when `f5` was "
             "decoded as an int and the column is nonetheless a valid "
             "string-offset column. Nothing is lost either way, and a float is "
             "emitted exactly, so its four bytes are recoverable from it.\n")
    L.append("## How a type is decided\n")
    L.append(cat["inferenceRule"] + "\n")
    L.append("| inferred | columns |")
    L.append("| --- | ---: |")
    for k, v in sorted(cat["inferredColumnCounts"].items(), key=lambda kv: -kv[1]):
        L.append(f"| {k} | {v:,} |")
    L.append("")
    L.append("## Sharding\n")
    L.append(cat["shardRule"] + "\n")
    L.append("## Compression\n")
    L.append(cat["compressionRule"] + "\n")
    L.append("| tables written | count |")
    L.append("| --- | ---: |")
    for k, v in sorted(cat["tablesByFormat"].items()):
        L.append(f"| {k} | {v:,} |")
    L.append("")
    big = sorted(cat["tables"], key=lambda r: -r["rows"])[:15]
    L.append("## Largest tables\n")
    L.append("| table | rows | columns | shards | MB stored |")
    L.append("| --- | ---: | ---: | ---: | ---: |")
    for r in big:
        L.append(f"| {r['table']} | {r['rows']:,} | {r['columns']} | "
                 f"{r['shards']} | {r['storedBytes']/1e6:.1f} |")
    L.append("")
    if fail["count"]:
        L.append("## Failures\n")
        L.append("| table | stage | reason |")
        L.append("| --- | --- | --- |")
        for f in fail["failures"]:
            L.append(f"| {f['table']} | {f['stage']} | {f['reason']} |")
        L.append("")
    write_text(out_dir / "README.md", "\n".join(L) + "\n")


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--only", nargs="+", metavar="TABLE",
                    help="decode just these tables (with or without .dbc)")
    ap.add_argument("--resume", action="store_true",
                    help="skip tables already decoded from the same bytes")
    ap.add_argument("--out", type=Path, help="write somewhere else than raw/tables")
    ap.add_argument("-q", "--quiet", action="store_true")
    args = ap.parse_args()
    c = run(only=args.only, resume=args.resume, out_dir=args.out,
            verbose=not args.quiet)
    print("\n=== DECODE ===")
    print(f"tables        {c['tableCount']} of {c['censusTableCount']} "
          f"(skipped {c['skipped']}, failures {c['failureCount']})")
    print(f"rows          {c['totalRows']:,}")
    print(f"shards        {c['totalShards']:,}")
    print(f"size          {c['storedBytes']/1e6:.1f} MB stored / "
          f"{c['plainBytes']/1e6:.1f} MB plain")
    print(f"columns       {c['inferredColumnCounts']}")
    print(f"elapsed       {c['elapsed']}s")


if __name__ == "__main__":
    main()
