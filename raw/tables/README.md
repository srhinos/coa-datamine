# Raw client tables (generated)

Regenerate: `python -m tools.decode_all`. Every byte under this directory is written by `tools/decode_all.py` from `tools/extract_all.py`'s extraction of the MPQ chain. Nothing is hand-authored, no table is treated specially, and no table is left out.

## Totals

- **368 tables** decoded of 368 in the client census
- **0 failures** (`_failures.json`)
- **7,467,563 rows** in 7,857 shards
- **131.8 MB** on disk (1955.4 MB uncompressed)
- **56,045,520 string-block bytes**: 56,041,258 reached by a decoded record, 4,262 referenced by no column and written out verbatim to `<Table>.strings.json`

## Layout

```
raw/tables/index.json          every table: rows, columns, shards, bytes
raw/tables/_failures.json      anything not decoded, and why
raw/tables/<Table>/index.json  shard map: key ranges, format, sha256
raw/tables/<Table>/<Table>.colinfo.json
                               per column: measurement + inferred type
raw/tables/<Table>/<Table>.strings.json
                               string-block entries no column points at
raw/tables/<Table>/<lo>-<hi>.jsonl[.gz]
                               one record per line: {"f0":..,"f1":..}
```

## Reading a record

Keys are positional. `f5` is the value of column 5 under the type the measurement implies; `f5i` is the raw int when `f5` was decoded as a string; `f5s` is the decoded string when `f5` was decoded as an int and the column is nonetheless a valid string-offset column. Nothing is lost either way, and a float is emitted exactly, so its four bytes are recoverable from it.

## How a type is decided

Per column, in this order: no rows -> unknown; every value zero -> zero; one-byte column -> int (a single byte can be neither a binary32 nor a string offset); every value a valid string offset AND every referenced string strict-UTF-8 AND free of control characters AND at least one of them non-empty -> string; every non-zero value a plausible binary32 (finite, magnitude in [1e-20, 1e+20]) -> float; otherwise int. Every count the rule reads is emitted under the column's `evidence`, so the conclusion is auditable and reversible.

| inferred | columns |
| --- | ---: |
| int | 4,889 |
| zero | 766 |
| float | 507 |
| string | 444 |
| unknown | 56 |

## Sharding

Rows are grouped by the unsigned value of one column - f0 unless f0 cannot keep every group within the cap, in which case the lowest-indexed column that can is used, and if no column can, fixed row-index blocks are used (recorded per table as shardKey.mode). A group is a fixed decimal-prefix range of that value, split only where a range exceeds 5000 rows, so a row's shard is a function of the row's own value and never shifts because a neighbouring range grew. Shard files are named <lo>-<hi> over that value, zero-padded to a fixed width.

## Compression

The decision is per table, so a table is never half-readable: when a table's whole decoded text is <= 1048576 bytes its shards stay plain .jsonl and grep reads them directly, and when it is larger every shard is written as .jsonl.gz (deflate level 9, gzip mtime and name fields zeroed so reruns are byte-identical). The choice and both byte counts are recorded per table and per shard in the table index. Small tables are the long tail an agent greps; the handful of large ones compress by roughly 20x and would otherwise be the whole layer's weight.

| tables written | count |
| --- | ---: |
| gzip | 58 |
| plain | 310 |

## Largest tables

| table | rows | columns | shards | MB stored |
| --- | ---: | ---: | ---: | ---: |
| ItemStat | 1,513,931 | 39 | 1518 | 23.9 |
| SpellEnchantSuggestions | 1,144,863 | 4 | 1147 | 6.5 |
| Item | 563,335 | 8 | 548 | 2.8 |
| ItemAddon | 563,335 | 48 | 561 | 11.6 |
| SpellTags | 488,662 | 3 | 489 | 2.6 |
| EnchantEnchantSuggestions | 380,008 | 4 | 381 | 2.6 |
| SpellSpellSuggestions | 353,193 | 4 | 351 | 2.3 |
| Spell | 238,939 | 234 | 241 | 21.4 |
| ItemAppearances | 202,903 | 3 | 202 | 1.2 |
| DeclinedWordCases | 141,956 | 4 | 147 | 2.8 |
| ItemSpells | 131,722 | 37 | 131 | 1.0 |
| ItemDisplayInfo | 129,603 | 25 | 135 | 3.6 |
| Creature | 127,178 | 23 | 128 | 2.8 |
| GameObjectDisplayInfo | 120,869 | 19 | 134 | 1.7 |
| GameObjectDisplayInfoAddon | 106,834 | 2 | 112 | 0.5 |

