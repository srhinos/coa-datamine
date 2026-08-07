# Loose client content (generated)

Regenerate: `python -m tools.extract_content`. Written by `tools/extract_content.py`
from `E:\ascension-live\Data\Content`. Nothing in this directory is hand-authored
and nothing in that tree is filtered out of it.

## Totals

- **82 files** in the client tree (94.0 MB on disk)
- **18 JSON payloads**, copied verbatim (byte-identical, sha256 checked against source)
- **64 `.loc` localization files**, 1,605,624 records decoded
- **0 failures** (`index.json` -> `failures`)

## Layout

```
raw/content/index.json         every file: bytes, sha256, decode status
raw/content/README.md          this file
raw/content/<Name>.json        verbatim copy of Data\Content\<Name>.json
raw/content/localization/<Entity>/<Field>/<locale>/<lo>-<hi>.jsonl[.gz]
                               one record per line: {"id":..,"text":".."}
```

## The `.loc` format

Undocumented in the client and nowhere else. Decoded, not guessed:

```
uint32 recordCount, then recordCount x (uint32 id, uint32 byteLength, byteLength bytes of UTF-8). No trailing bytes.
```

A decode is accepted only if it consumes the file EXACTLY: the declared record count is read in full, no length runs past EOF, every string decodes as strict UTF-8, and the final offset equals the file size. Any shortfall or overrun is a LocError carrying the offset reached and the record index that failed - never a partial result.

All 64 files decode to exact closure, so no `.loc` bytes are shipped undecoded. `id` is the id of the entity the directory names - `Spell/Name/deDE.loc`
record id 17 is spell 17 - which was established by reading the ids out and
matching them against known spell and item ids, not by assuming it.

| entity/field | locales | records | MB stored |
| --- | ---: | ---: | ---: |
| `Item/Description` | 8 | 395,835 | 2.19 |
| `Item/Name` | 8 | 397,259 | 4.44 |
| `Spell/Description` | 8 | 44,369 | 5.52 |
| `Spell/Name` | 8 | 47,008 | 1.84 |
| `Spell/Rank` | 8 | 46,266 | 1.36 |
| `Spell/Tooltip` | 8 | 22,753 | 1.31 |
| `Unit/Name` | 8 | 326,067 | 3.80 |
| `Unit/Subname` | 8 | 326,067 | 5.72 |

## Sharding and compression

Rows are grouped by the unsigned value of one column - f0 unless f0 cannot keep every group within the cap, in which case the lowest-indexed column that can is used, and if no column can, fixed row-index blocks are used (recorded per table as shardKey.mode). A group is a fixed decimal-prefix range of that value, split only where a range exceeds 5000 rows, so a row's shard is a function of the row's own value and never shifts because a neighbouring range grew. Shard files are named <lo>-<hi> over that value, zero-padded to a fixed width.

The decision is per table, so a table is never half-readable: when a table's whole decoded text is <= 1048576 bytes its shards stay plain .jsonl and grep reads them directly, and when it is larger every shard is written as .jsonl.gz (deflate level 9, gzip mtime and name fields zeroed so reruns are byte-identical). The choice and both byte counts are recorded per table and per shard in the table index. Small tables are the long tail an agent greps; the handful of large ones compress by roughly 20x and would otherwise be the whole layer's weight.
