# Raw client tables (generated)

Regenerate: `python -m tools.decode_all`. Every byte under this directory is written by `tools/decode_all.py` from `tools/extract_all.py`'s extraction of the MPQ chain. Nothing is hand-authored, no table is treated specially, and no table is left out.

## Totals

- **368 tables** decoded of 368 in the client census
- **0 failures** (`_failures.json`)
- **7,467,568 rows** in 7,857 shards
- **131.8 MB** on disk (1955.4 MB uncompressed)
- **56,045,598 string-block bytes**: 56,041,336 reached by a decoded record, 4,262 referenced by no column and written out verbatim to `<Table>.strings.json`

- **987 versions** of those tables: 234 paths are shipped in more than one version by the chain, and all 619 extra versions are decoded too (2,377,659 further rows, 116.0 MB)

## Layout

```
raw/tables/index.json          every table: rows, columns, shards, bytes
raw/tables/_failures.json      anything not decoded, and why
raw/tables/_variants.json      every table shipped in more than one version
raw/tables/<Table>/index.json  shard map: key ranges, format, sha256,
                               and `variants`: every version of this table
raw/tables/<Table>/<Table>.colinfo.json
                               per column: measurement + inferred type
raw/tables/<Table>/<Table>.strings.json
                               string-block entries no column points at
raw/tables/<Table>/<lo>-<hi>.jsonl[.gz]
                               one record per line: {"f0":..,"f1":..}
raw/tables/<Table>/variants/<archive-slug>/
                               a NON-winning version of the same table,
                               same files, same rules, same decoder
```

## Versions

A path can be carried by several archives, and the chain picks one. The other copies are not history: this client's realm directory sits above the whole base chain, so for a path the overlay carries, the chain winner is the OVERLAY's table and the table a character outside that realm reads is a different file. Every distinct version is therefore decoded, and each one records which chain context selects it.

A chain context is a set of archives a running client actually loads. It is enumerated from the client's own directory layout, not from a list: the context called `baseChain` is every archive in the base and locale directories - what a character reads when no realm overlay applies - and there is one further context per realm directory found, holding that same base set plus the archives that realm's own `listarchive` declares. A version APPLIES TO a context when its archive is the highest-ranked carrier of that path inside it; chain rank is position in tools/inventory.discover_archives(), the same loader order the census and the extractor use. A version that is the highest-ranked carrier in no context at all is still decoded - it is real client data - and is marked shadowed.

One version per DISTINCT sha256 among the copies of a path, not one per carrying archive: byte-identical copies in several archives are ONE version, listed once under the highest-ranked archive that carries those bytes with the rest recorded in `alsoIn`. The chain winner - the copy tools/decode_all.py already decoded - keeps its place at raw/tables/<T>/ and is listed here with `chainWinner` true; every other version is decoded into raw/tables/<T>/variants/<slug>/ by the same decoder, so the two are comparable byte for byte. `rowDelta` is this version's record count minus the chain winner's.

`raw/tables/_variants.json` lists all 234 of them. 10 are contested between the base chain and a realm overlay - the ones where reading the chain winner means reading another realm's table:

| table | base rows | base archive | overlay rows | overlay archive |
| --- | ---: | --- | ---: | --- |
| CharacterAdvancement | 10,234 | Data/patch-M.MPQ | 7,820 | Data/area-52/patch-D.MPQ |
| CharacterAdvancementEssence | 5,600 | Data/patch-M.MPQ | 5,440 | Data/area-52/patch-D.MPQ |
| Manastorm | 1,017 | Data/patch-M.MPQ | 1,025 | Data/area-52/patch-D.MPQ |
| ManastormModifiers | 32,768 | Data/patch-M.MPQ | 32,768 | Data/area-52/patch-D.MPQ |
| SkillLineAbility | 40,981 | Data/patch-M.MPQ | 38,542 | Data/area-52/patch-D.MPQ |
| Spell | 209,140 | Data/patch-T.MPQ | 238,939 | Data/area-52/patch-D.MPQ |
| SpellCharges | 400 | Data/patch-S.MPQ | 473 | Data/area-52/patch-D.MPQ |
| SpellChargesCategory | 105 | Data/patch-S.MPQ | 108 | Data/area-52/patch-D.MPQ |
| SpellRank | 23,182 | Data/patch-S.MPQ | 19,601 | Data/area-52/patch-D.MPQ |
| Talent | 2,383 | Data/patch-M.MPQ | 2,368 | Data/area-52/patch-D.MPQ |

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

