# Loose client content (generated)

Regenerate: `python datamine.py`. Extracted from the snapshot of
`Data\Content`. Nothing here is hand-authored and nothing in that tree is
filtered out of it.

## Totals

- **82 files** in the client tree (94.0 MB)
- **18 JSON payloads**, copied verbatim, byte for byte
- **64 `.loc` localization files**, 1,605,624 records decoded
- **0 failures** (`index.json` -> `failures`)

## The `.loc` format

Undocumented in the client and nowhere else. Decoded, not guessed:

```
uint32 recordCount, then recordCount x (uint32 id, uint32 byteLength, byteLength bytes of UTF-8). No trailing bytes.
```

A decode is accepted only if it consumes the file EXACTLY: the declared record count is read in full, no length runs past EOF, every string decodes as strict UTF-8, and the final offset equals the file size. Any shortfall or overrun is a LocError carrying the offset reached and the record index that failed - never a partial result.

## Sharding and compression

Rows are grouped by the unsigned value of one column - f0 unless f0 cannot keep every group within the cap, in which case the lowest-indexed column that can is used, and if no column can, fixed row-index blocks are used (recorded per table as shardKey.mode). A group is a fixed decimal-prefix range of that value, split only where a range exceeds 5000 rows, so a row's shard is a function of the row's own value and never shifts because a neighbouring range grew. Shard files are named <lo>-<hi> over that value, zero-padded to a fixed width.

The decision is per table, so a table is never half-readable: when a table's whole decoded text is <= 1048576 bytes its shards stay plain .jsonl and grep reads them directly, and when it is larger every shard is written as .jsonl.gz (deflate level 9, gzip mtime and name fields zeroed so reruns are byte-identical). The choice and both byte counts are recorded per table and per shard in the table index. Small tables are the long tail an agent greps; the handful of large ones compress by roughly 20x and would otherwise be the whole layer's weight.
