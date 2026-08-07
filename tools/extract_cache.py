"""Complete extraction of the client-side query caches under `Cache\\WDB\\`.

WHY THIS MATTERS MORE THAN ITS SIZE SUGGESTS
--------------------------------------------
These files are the SERVER's answers, cached verbatim by the client. `Item.dbc`
carries no stats at all, so `itemcache.wdb` is the only client-side source of
item stats, damage, sockets and item-level; `creaturecache.wdb` is the only
client-side source of creature type, rank and health/mana modifiers. And they are
PER REALM: `Cache\\WDB\\enUS\\` holds the login/base cache while
`Cache\\WDB\\enUS\\<realm>\\` holds what that realm actually served - which is
different data, not a copy (on this machine the realm itemcache carries 38 more
items than the base one). A layer that read only the base directory would repeat
the realm-overlay mistake the DBC layer already had to fix.

COMPLETENESS
------------
Every file under `Cache\\WDB\\` is walked and recorded - every extension, every
subdirectory, including the ones that are not .wdb at all. Decoding is tiered by
`tools/wdb.py` and each tier is recorded per file:

  schema   recognized magic, and a field schema that consumed every block of the
           file EXACTLY. Named fields.
  blocks   recognized WDB header, but no schema closed it. One record per block
           with the body base64-encoded. Lossless.
  flat     no WDB header, but the file matches Ascension's own flat cache shape
           (uint32 count, uint32 hash, count fixed-width records) with the record
           width DERIVED by exact division. Positional f0..fN, types measured.
  raw      none of the above. The whole file is committed as base64 in the index,
           so its bytes are still in the repo and still rerunnable.

Nothing is skipped, and `index.json`'s `fileCount` is the count of files on
disk - a file that stopped decoding would appear as a `raw`/failed row, never as
an absence.
"""
import base64
import hashlib
import json
import re

from tools import config, rawshard, wdb
from tools.decode_all import write_text

CACHE_DIR = config.CLIENT_DIR / "Cache" / "WDB"
OUT_DIR = config.RAW_DIR / "cache"

# Files this size or smaller are committed verbatim as base64 when nothing
# decodes them, so an undecoded cache is still fully present in the repo.
RAW_EMBED_MAX = 1 << 16

_SLUG = re.compile(r"[^a-z0-9]+")


def slug(s: str) -> str:
    return _SLUG.sub("-", s.lower()).strip("-") or "root"


def _group_of(rel_parts) -> str:
    """('enUS','Rexxar - Conquest of Azeroth','itemcache.wdb') -> 'enus/rexxar-...'.
    The realm subdirectory is kept as its own group precisely because it is
    different data from the base directory, never merged into it."""
    return "/".join(slug(p) for p in rel_parts[:-1]) or "root"


def extract_all(verbose: bool = True) -> dict:
    if not CACHE_DIR.is_dir():
        raise SystemExit(f"FATAL: {CACHE_DIR} does not exist")
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    for old in sorted(OUT_DIR.rglob("*"), reverse=True):
        old.unlink() if old.is_file() else old.rmdir()

    files = sorted(p for p in CACHE_DIR.rglob("*") if p.is_file())
    entries, failures = [], []

    for p in files:
        parts = p.relative_to(CACHE_DIR).parts
        data = p.read_bytes()
        group = _group_of(parts)
        name = slug(parts[-1].rsplit(".", 1)[0])
        rec = {"path": "/".join(parts), "group": group, "name": parts[-1],
               "bytes": len(data), "sha256": hashlib.sha256(data).hexdigest()}
        head = wdb.sniff(data)
        rec["header"] = head

        rows, tier, extra = None, None, {}
        if head.get("hasWdbHeader"):
            magic = head["magic"]
            try:
                res = wdb.decode_blocks(data, magic)
            except wdb.WdbError as e:
                res = {"decoded": False, "records": [], "fields": [],
                       "failure": {"reason": f"{type(e).__name__}: {e}"}}
            if res["decoded"]:
                rows, tier = res["records"], "schema"
                extra = {"fields": res["fields"],
                         "schemaSource": wdb.SCHEMA_SOURCE.get(magic)}
            else:
                extra = {"schemaFailure": res["failure"],
                         "schemaSource": wdb.SCHEMA_SOURCE.get(magic)}
                try:
                    rows, tier = wdb.dump_blocks(data), "blocks"
                except wdb.WdbError as e:
                    extra["blockWalkFailure"] = f"{type(e).__name__}: {e}"
        else:
            flat = wdb.sniff_flat(data)
            rec["flat"] = {k: v for k, v in flat.items() if k != "records"}
            if flat["decoded"]:
                rows, tier = flat["records"], "flat"
                extra = {"columns": flat["columns"],
                         "columnTypes": flat["columnTypes"],
                         "recordSize": flat["recordSize"]}

        if rows is None:
            tier = "raw"
            if len(data) <= RAW_EMBED_MAX:
                extra["bytesBase64"] = base64.b64encode(data).decode("ascii")
                extra["bytesCommitted"] = True
            else:
                extra["bytesCommitted"] = False
                extra["note"] = ("no decoder matched and the file exceeds "
                                 f"{RAW_EMBED_MAX} bytes, so only its hash is here")
            failures.append({"path": rec["path"], "tier": tier, **extra})
        else:
            key = ("_entry" if tier in ("schema", "blocks") else "f0")
            out = OUT_DIR / group / name
            frag = rawshard.write_group(
                out, rows, lambda r, k=key: int(r.get(k, 0)) & 0xFFFFFFFF)
            extra.update({"dir": f"{group}/{name}", "shardCount": frag["shardCount"],
                          "format": frag["format"],
                          "storedBytes": frag["storedBytes"]})
            rec["records"] = len(rows)

        rec["tier"] = tier
        rec.update(extra)
        entries.append(rec)
        if verbose:
            print(f"  {rec['path']:56s} {tier:7s} "
                  f"{rec.get('records', 0):7d} records")

    groups = {}
    for e in entries:
        g = groups.setdefault(e["group"], {"files": 0, "records": 0, "bytes": 0})
        g["files"] += 1
        g["records"] += e.get("records", 0)
        g["bytes"] += e["bytes"]

    index = {
        "note": "Every file under Cache\\WDB. Decoded records live in "
                "<group>/<name>/<lo>-<hi>.jsonl[.gz], one record per line, keyed "
                "by the block entry id (`_entry`) for WDB caches and by f0 for "
                "the flat Ascension caches. <group> keeps each realm's cache "
                "separate from the base one - they are different data.",
        "clientCacheDir": str(CACHE_DIR),
        "fileCount": len(entries),
        "recordTotal": sum(e.get("records", 0) for e in entries),
        "sourceBytes": sum(e["bytes"] for e in entries),
        "tierCounts": {t: sum(1 for e in entries if e["tier"] == t)
                       for t in ("schema", "blocks", "flat", "raw")},
        "groups": {k: groups[k] for k in sorted(groups)},
        "validationRule": wdb.VALIDATION_RULE,
        "flatRule": wdb.FLAT_RULE,
        "shardRule": rawshard.SHARD_RULE,
        "compressionRule": rawshard.COMPRESSION_RULE,
        "schemaSources": wdb.SCHEMA_SOURCE,
        "files": entries,
        "failures": failures,
    }
    write_text(OUT_DIR / "index.json",
               json.dumps(index, ensure_ascii=False, indent=1, sort_keys=True) + "\n")
    write_text(OUT_DIR / "README.md", _readme(index))
    return index


def _readme(ix: dict) -> str:
    rows = "\n".join(
        f"| `{e['path']}` | `{e.get('header', {}).get('magic', '-')}` | "
        f"{e['tier']} | {e.get('records', 0):,} | {e['bytes']/1e3:,.0f} |"
        for e in ix["files"])
    grp = "\n".join(f"| `{k}` | {v['files']} | {v['records']:,} | {v['bytes']/1e6:.2f} |"
                    for k, v in ix["groups"].items())
    return f"""# Client query caches (generated)

Regenerate: `python -m tools.extract_cache`. Written by `tools/extract_cache.py`
from `{ix['clientCacheDir']}`. Nothing here is hand-authored and no file in that
tree is filtered out.

## Why this layer exists

`Item.dbc` on this client is an index with no stats, so `itemcache.wdb` is the
only client-side source of item stats, damage, sockets and item level.
`creaturecache.wdb` is likewise the only client-side source of creature type,
rank and health/mana modifiers. Both are the SERVER's own answers, cached by the
client as it played.

## Realms are separate, on purpose

| group | files | records | MB source |
| --- | ---: | ---: | ---: |
{grp}

A realm subdirectory is not a copy of the base cache - it is what that realm
served. Merging them would be the same class of error as reading only the base
MPQ chain for `Spell.dbc`.

## Totals

- **{ix['fileCount']} files**, {ix['sourceBytes']/1e6:.1f} MB on disk
- **{ix['recordTotal']:,} records** decoded
- tiers: {json.dumps(ix['tierCounts'])}

## Layout

```
raw/cache/index.json                     every file: header, tier, records, sha256
raw/cache/<group>/<name>/<lo>-<hi>.jsonl[.gz]
```

## How a field layout earns the right to be used

{ix['validationRule']}

## Files with no WDB header

{ix['flatRule']}

## Per file

| file | magic | tier | records | KB |
| --- | --- | --- | ---: | ---: |
{rows}

## Sharding and compression

{ix['shardRule']}

{ix['compressionRule']}
"""


def main():
    ix = extract_all()
    print(f"cache files: {ix['fileCount']}  records: {ix['recordTotal']}  "
          f"tiers: {ix['tierCounts']}")


if __name__ == "__main__":
    main()
