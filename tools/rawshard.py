"""Shared shard writer for the raw JSONL layers (localization, WDB caches).

Deliberately thin: it reuses `tools/decode_all.py`'s already-proven pieces
rather than re-implementing them, so every raw layer in this repo shards,
compresses and hashes by exactly the same rules and an agent only has to learn
them once.

  * range planning        decode_all.plan_shards - fixed decimal-prefix ranges
                          over an unsigned key, split only where a range exceeds
                          the row cap. A record's shard is a function of the
                          record's own key, so it never moves because a
                          neighbouring range grew (which is what count-chunking
                          does, and why it is banned here).
  * plain shard writing   decode_all.write_plain  - bytes, LF, sha256 recorded.
  * compression           decode_all.compress_shard - deflate level 9 with the
                          gzip mtime and name fields zeroed, so a rerun over an
                          unchanged client is byte-identical.

The one policy this module adds is the same per-group compression decision the
table layer makes: a group is never half-readable - either all of its shards are
plain .jsonl and greppable, or all of them are .jsonl.gz.
"""
import json
from pathlib import Path

from tools.decode_all import (PLAIN_MAX_TABLE_BYTES, SHARD_MAX_ROWS,
                              COMPRESSION_RULE, SHARD_RULE,
                              compress_shard, plan_shards, write_plain)

__all__ = ["PLAIN_MAX_TABLE_BYTES", "SHARD_MAX_ROWS", "COMPRESSION_RULE",
           "SHARD_RULE", "line", "write_group"]


# Characters that a line-based reader treats as a line break and that
# `json.dumps(ensure_ascii=False)` nevertheless emits RAW. Everything below
# U+0020 is already escaped for us; these three are not, and a record carrying
# one of them would be split across two lines by str.splitlines() - the JSONL
# contract broken silently, in exactly one record out of millions. Escaping them
# changes no data (json.loads returns the identical string) and no existing
# layer's bytes: a scan of every committed shard in raw/content, raw/cache,
# raw/tables and raw/recovered found zero occurrences. The client's binaries do
# contain them, which is how this was found.
_LINE_BREAKERS = {"\u0085": "\\u0085",
                  "\u2028": "\\u2028",
                  "\u2029": "\\u2029"}


def line(rec: dict) -> str:
    """One compact, key-sorted JSON record - the line format every raw layer
    uses, so `grep '"id":12345'` behaves the same everywhere. Guaranteed to be
    ONE line: see _LINE_BREAKERS."""
    text = json.dumps(rec, ensure_ascii=False, sort_keys=True,
                      separators=(",", ":"))
    for raw, escaped in _LINE_BREAKERS.items():
        if raw in text:
            text = text.replace(raw, escaped)
    return text


def write_group(out_dir: Path, rows: list, key_of, stem: str = "",
                limit: int = SHARD_MAX_ROWS) -> dict:
    """Shard `rows` into out_dir by the unsigned integer `key_of(row)`.

    Returns {"shards": [...], "rows": n, "plainBytes": n, "storedBytes": n,
    "format": "plain"|"gzip"} - the per-group index fragment the caller embeds
    in its own index.json. Rows are emitted in (key, original order) so the
    output is a pure function of the input."""
    out_dir.mkdir(parents=True, exist_ok=True)
    keyed = [(key_of(r) & 0xFFFFFFFF, i, r) for i, r in enumerate(rows)]
    counts = {}
    for k, _, _ in keyed:
        counts[k] = counts.get(k, 0) + 1
    if not counts:
        counts = {0: 0}
    plan = plan_shards(counts, limit)
    by_key = {}
    for k, i, r in keyed:
        by_key.setdefault(k, []).append((i, r))

    shards, plain_total = [], 0
    for lo, hi, keys, _total, width in plan:
        members = []
        for k in sorted(keys or []):
            members.extend(sorted(by_key.get(k, [])))
        name = f"{stem}{str(lo).zfill(width)}-{str(hi).zfill(width)}.jsonl"
        rec = write_plain(out_dir / name, [line(r) for _, r in members])
        rec.update({"lo": lo, "hi": hi})
        plain_total += rec["plainBytes"]
        shards.append(rec)

    fmt = "plain"
    if plain_total > PLAIN_MAX_TABLE_BYTES:
        fmt = "gzip"
        shards = [compress_shard(out_dir, s) for s in shards]
    return {"shards": shards, "rows": len(rows), "format": fmt,
            "plainBytes": plain_total,
            "storedBytes": sum(s["storedBytes"] for s in shards),
            "shardCount": len(shards),
            "oversizeShards": [s["file"] for s in shards if s["rows"] > limit]}
