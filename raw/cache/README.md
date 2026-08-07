# Client query caches (generated)

Regenerate: `python -m tools.extract_cache`. Written by `tools/extract_cache.py`
from `E:\ascension-live\Cache\WDB`. Nothing here is hand-authored and no file in that
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
| `enus` | 10 | 22,476 | 9.20 |
| `enus/rexxar-conquest-of-azeroth` | 11 | 22,998 | 9.34 |
| `root` | 1 | 0 | 0.00 |

A realm subdirectory is not a copy of the base cache - it is what that realm
served. Merging them would be the same class of error as reading only the base
MPQ chain for `Spell.dbc`.

## Totals

- **22 files**, 18.5 MB on disk
- **45,474 records** decoded
- tiers: {"schema": 18, "blocks": 0, "flat": 2, "raw": 2}

## Layout

```
raw/cache/index.json                     every file: header, tier, records, sha256
raw/cache/_interpretation.json           position -> TrinityCore field name (UNVERIFIED)
raw/cache/<group>/<name>/<lo>-<hi>.jsonl[.gz]
```

Records are positional: `{"_entry":100248,"f0":4,"f3":"Beaststalker's Belt",...}`.
`_entry` is the block header's own entry id. `fN` is field N of the measured
layout. No field name appears anywhere in the data.

## How a field layout earns the right to be used

A field LAYOUT is applied to a WDB file only if it consumes every block of that file exactly: each block declares its own byte length in its header, and the decode must land on that length for all blocks, with no block skipped. One mismatch anywhere disqualifies the layout for the whole file (never per-block), and the file falls back to a lossless base64 block dump with the mismatch recorded. WHAT THIS DOES NOT CATCH, stated so it is not over-trusted: (1) reading a uint32 as a float32 consumes the same bytes and passes; (2) PERMUTING any two same-kind same-width fields consumes the same bytes and passes. Both were measured - removing a field, or moving a string by one position, fail on the first block; a width-preserving swap does not. Because (2) is unfalsifiable from the bytes alone, THIS LAYER SHIPS NO FIELD NAMES: every decoded record is positional (f0..fN), exactly like raw/tables. The TrinityCore-derived names are published separately in raw/cache/_interpretation.json, labelled as the unverified interpretation they are. A reader can therefore never mistake a name for a measurement.

## The field names, and why they are not in the data

The field names below are an INTERPRETATION, not a measurement. They were read off TrinityCore 3.3.5's query-response handlers by a human and mapped onto the positions this layer measured. The measurement is the layout - field count, widths, kinds, and the variable-length runs - which is proven by exact block consumption. The names are not proven by anything: any two same-kind same-width fields can be swapped without changing a single byte of consumption, so `f21` being called `flags` is a claim about what the server meant, verifiable only against an external source. Use the positions for data and treat every name here as a hypothesis to check.

`_interpretation.json` maps every position to the name TrinityCore gives it, per
magic, with the handler it came from. Read a value out of `fN`; use the name to
form a hypothesis about what `fN` is, then check it.

## Files with no WDB header

A file with no WDB header is tried as Ascension's own flat cache shape: uint32 count, uint32 hash, then `count` fixed-width records. The width is derived - (fileSize - 8) must be divisible by count and by 4 - not assumed. Columns stay positional (f0..fN); a column is called float only if every non-zero value in it is a finite binary32 of magnitude in [1e-20, 1e+20], otherwise it is an int.

## Per file

| file | magic | tier | records | KB |
| --- | --- | --- | ---: | ---: |
| `enUS/baddons.wcf` | `-` | raw | 0 | 0 |
| `enUS/creaturecache.wdb` | `WMOB` | schema | 2,515 | 278 |
| `enUS/gameobjectcache.wdb` | `WGOB` | schema | 1,951 | 319 |
| `enUS/itemcache.wdb` | `WIDB` | schema | 17,531 | 8,394 |
| `enUS/itemnamecache.wdb` | `WNDB` | schema | 215 | 7 |
| `enUS/itemtextcache.wdb` | `WITX` | schema | 0 | 0 |
| `enUS/npccache.wdb` | `WNPC` | schema | 54 | 39 |
| `enUS/pagetextcache.wdb` | `WPTX` | schema | 0 | 0 |
| `enUS/questcache.wdb` | `WQST` | schema | 210 | 162 |
| `enUS/Rexxar - Conquest of Azeroth/creaturecache.wdb` | `WMOB` | schema | 2,634 | 291 |
| `enUS/Rexxar - Conquest of Azeroth/gameobjectcache.wdb` | `WGOB` | schema | 2,034 | 332 |
| `enUS/Rexxar - Conquest of Azeroth/itemcache.wdb` | `WIDB` | schema | 17,569 | 8,419 |
| `enUS/Rexxar - Conquest of Azeroth/itemnamecache.wdb` | `WNDB` | schema | 242 | 8 |
| `enUS/Rexxar - Conquest of Azeroth/itemstatcache.wdb` | `-` | flat | 176 | 30 |
| `enUS/Rexxar - Conquest of Azeroth/itemtextcache.wdb` | `WITX` | schema | 0 | 0 |
| `enUS/Rexxar - Conquest of Azeroth/npccache.wdb` | `WNPC` | schema | 70 | 48 |
| `enUS/Rexxar - Conquest of Azeroth/pagetextcache.wdb` | `WPTX` | schema | 7 | 2 |
| `enUS/Rexxar - Conquest of Azeroth/questcache.wdb` | `WQST` | schema | 257 | 207 |
| `enUS/Rexxar - Conquest of Azeroth/questcacheaddon.wdb` | `-` | flat | 9 | 0 |
| `enUS/Rexxar - Conquest of Azeroth/wowcache.wdb` | `WRDN` | schema | 0 | 0 |
| `enUS/wowcache.wdb` | `WRDN` | schema | 0 | 0 |
| `version.bin` | `-` | raw | 0 | 0 |

## Sharding and compression

Rows are grouped by the unsigned value of one column - f0 unless f0 cannot keep every group within the cap, in which case the lowest-indexed column that can is used, and if no column can, fixed row-index blocks are used (recorded per table as shardKey.mode). A group is a fixed decimal-prefix range of that value, split only where a range exceeds 5000 rows, so a row's shard is a function of the row's own value and never shifts because a neighbouring range grew. Shard files are named <lo>-<hi> over that value, zero-padded to a fixed width.

The decision is per table, so a table is never half-readable: when a table's whole decoded text is <= 1048576 bytes its shards stay plain .jsonl and grep reads them directly, and when it is larger every shard is written as .jsonl.gz (deflate level 9, gzip mtime and name fields zeroed so reruns are byte-identical). The choice and both byte counts are recorded per table and per shard in the table index. Small tables are the long tail an agent greps; the handful of large ones compress by roughly 20x and would otherwise be the whole layer's weight.
