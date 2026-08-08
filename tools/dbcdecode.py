"""The DBC decoder, as a pure library.

A LIBRARY, NOT A STAGE
----------------------
Everything here is a function of bytes. Nothing in this module opens an archive,
walks the client, decides what to extract or knows the order layers are built
in - that is `datamine.py`'s job, and it is the whole job, done once. This module
turns one table's bytes into one table's directory, and it is called identically
for a chain winner and for every non-winning variant, which is what makes the two
comparable.

The code was MOVED here verbatim from the former `tools/decode_all.py` rather
than rewritten. That is deliberate and it is the reason the collapsed pipeline
reproduces the committed layer byte for byte: a re-derived decoder would have
been a second opinion about the format, and a second opinion is exactly what
this repo has spent its history removing.

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

  int      the raw 4-byte little-endian signed value. Always available; the floor.
  float    the same 4 bytes read as IEEE-754 binary32. Counted as plausible when
           the result is finite and its magnitude is within [FLOAT_ABS_MIN,
           FLOAT_ABS_MAX]. Small integers decode to denormals far below that
           band, so a column of small ints scores ~0 here while a real float
           column scores 1.0.
  string   the value as an offset into the table's string block. Valid when it is
           0, or points just past a NUL. Offset 0 holds REAL CONTENT in this
           build - it is not an empty sentinel.

INFERENCE_RULE turns those counts into `inferred`. It runs on the numbers, in the
same order, for every table.

NOTHING IS LOST TO A WRONG INFERENCE
------------------------------------
  f5      the value under the inferred type
  f5i     the raw int, present when f5 was decoded as a string
  f5s     the decoded string, present when f5 was decoded as an int and the
          column is nonetheless a valid string-offset column

Floats need no sidecar: the emitted value is the exact binary32, so the 4 bytes
are recoverable from it.

HEADER ANOMALIES ARE HANDLED BY MEASUREMENT
-------------------------------------------
recordSize, not the declared field count, determines the row stride (10 tables in
this client declare a count that disagrees; both numbers are recorded). When
recordSize is not a multiple of 4 the 4-byte field model provably does not
describe the record, so the row is read as recordSize//4 four-byte columns
followed by recordSize%4 one-byte columns - no bytes are dropped, and the widths
are recorded per column. Zero-row tables decode to zero shards and still emit
their header facts.
"""
import array
import bisect
import gzip
import hashlib
import json
import re
import struct
import sys
from collections import Counter
from pathlib import Path

from tools import sharding

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

# Names Windows refuses to create a directory for. A table called `con` would
# otherwise fail mid-layer with an OS error instead of being recorded.
RESERVED_NAMES = {"con", "prn", "aux", "nul", "com1", "com2", "com3", "com4",
                  "com5", "com6", "com7", "com8", "com9", "lpt1", "lpt2",
                  "lpt3", "lpt4", "lpt5", "lpt6", "lpt7", "lpt8", "lpt9"}


class DecodeError(RuntimeError):
    pass


def write_text(path: Path, text: str) -> None:
    """UTF-8, LF, no BOM - always. Path.write_text() would translate newlines to
    the platform's, which would make this layer's bytes (and every sha256 the
    index records for them) depend on the OS it was generated on. The shards are
    written as bytes for the same reason."""
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(text.encode("utf-8"))


def header_facts(data: bytes) -> dict:
    """Measured WDBC header + the byte-accurate cross-checks. Nothing here is
    asserted: a declared field count that disagrees with recordSize//4 is
    recorded as a disagreement, and the body/string-block reconciliation is
    reported rather than assumed."""
    if len(data) < HEADER.size:
        return {"bytes": len(data), "truncated": True}
    magic, records, declared, rec_size, str_size = HEADER.unpack_from(data, 0)
    body_end = HEADER.size + records * rec_size
    return {
        "magic": magic.decode("latin-1"),
        "records": records,
        "declaredFields": declared,
        "recordSize": rec_size,
        "stringBlockSize": str_size,
        # recordSize is what actually determines the row stride, so it is the
        # authority; declaredFields is kept as a diagnostic.
        "actualFields": rec_size // 4,
        "trailingBytesPerRecord": rec_size % 4,
        "declaredFieldsAgrees": declared == rec_size // 4,
        "sizeReconciles": body_end + str_size == len(data),
        "bytes": len(data),
    }


# --------------------------------------------------------------------------
# reader
# --------------------------------------------------------------------------
class Table:
    """WDBC reader with the verified semantics: the record stride comes from
    recordSize, and string-block offset 0 is real content, not an empty
    sentinel. Extended in the two places a universal decoder needs: a recordSize
    that is not a multiple of 4 (read as a 4-byte prefix plus 1-byte tail columns
    instead of raising) and a string block whose last entry is unterminated
    (clipped and counted instead of raising)."""

    def __init__(self, source):
        """`source` is a path or the table's bytes. Bytes are accepted so the
        single traversal can decode a member it already holds without a
        round-trip through the filesystem."""
        if isinstance(source, (bytes, bytearray)):
            self.path = None
            data = bytes(source)
        else:
            self.path = Path(source)
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
            raise DecodeError(f"body needs {body_end} bytes, file has {len(data)}")
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
        arrangement this format is written in), and falls back to unpacking rows
        otherwise, so the result is identical either way."""
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
def _rate(part: int, whole: int) -> float:
    return round(part / whole, 6) if whole else 0.0


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
    table and no record carries them."""
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
    """Fixed decimal-prefix ranges over an unsigned key. A range splits only when
    it holds more than `limit` rows, so membership is a function of the key
    alone. Returns [(lo, hi, keys, rows, width)] sorted by lo."""
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
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(data)
    return {"file": path.name, "format": "plain", "rows": len(lines),
            "plainBytes": len(data), "storedBytes": len(data),
            "sha256": hashlib.sha256(data).hexdigest()}


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


def compress_shard(d: Path, rec: dict) -> dict:
    """Rewrite one already-written plain shard as gzip. The table's format is
    decided from the sum of its shards, which is only known once they are all
    rendered, and rendering the biggest tables twice costs far more than reading
    a file back."""
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


# --------------------------------------------------------------------------
# one table
# --------------------------------------------------------------------------
def decode_table(name: str, source: dict, dest: Path, data: bytes,
                 limit: int = SHARD_MAX_ROWS) -> dict:
    """Decode one table's BYTES into one directory.

    `data` is the member as the traversal already read it. Taking bytes rather
    than a path is what lets the single pass decode a table without writing it
    out and reading it back, and it is the same call for a chain winner and for
    a variant - a variant decoded by a second code path would not be comparable
    to the winner, which is the whole point of decoding it."""
    stem = name[:-4] if name.lower().endswith(".dbc") else name
    t = Table(data)
    d = Path(dest)
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
                raise DecodeError(f"sharding placed {placed} of {t.records} rows")
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
