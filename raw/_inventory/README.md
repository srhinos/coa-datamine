# Client inventory (generated)

Regenerate: `python datamine.py`. Every file here is written from the snapshot in `work/snapshot/`; nothing in it is hand-authored, and nothing in the client is filtered out of it.

## Start here

| file | what it answers |
| --- | --- |
| `archives.json` | every MPQ, its chain rank, whether it lists, its sha256 |
| `dbc.json` | every DBFilesClient table + its measured WDBC header |
| `categories.json` | how many bytes a full raw extraction costs, by class / directory / extension |
| `unlistable.json` | the archives with no readable `(listfile)` |
| `files.json` | index of the per-path shards in `files/` |
| `files/*.json` | one compact record per line: path, winning archive, size, sha256, flags |

## Totals

- **637,591 paths**
- **368 DBC tables**
- **77 archives** (7 unlistable), 44.9 GB on disk
- **67.88 GB** uncompressed if everything is extracted
- unreadable files: 4,906
- files in unlistable archives that no harvested name identified: **-7**
- paths a loose file at the client root takes from the archives: **25**

## Loose files at the client root beat the whole MPQ chain

A 3.3.5 client resolves `<clientRoot>\<path>` on disk BEFORE it looks in the MPQ chain, so a loose file at the client root beats every archive that carries the same path - which is how this client ships its own ChatBubble textures and its silenced Fizzle sounds. A loose file whose root-relative path is also an MPQ path WINS that path: `source` becomes `loose`, `winner` becomes `<disk>`, `size`/`sha256` are the file's own, and the archive copy it displaced is preserved under `overrides` so nothing is lost.

## What is not readable, and whether it matters

| unreadable by class | count |
| --- | ---: |
| art | 4,879 |
| interface | 22 |
| sound | 5 |

| reason | count |
| --- | ---: |
| deleted: patch tombstone: this layer DELETES the path; it carries no bytes | 4,906 |

## Extraction cost by class

| class | files | GB |
| --- | ---: | ---: |
| art | 486,663 | 53.464 |
| sound | 56,859 | 8.961 |
| interface | 93,437 | 4.449 |
| dbc | 368 | 0.836 |
| content | 82 | 0.094 |
| other | 182 | 0.074 |
| **total** | **637,591** | **67.878** |

Shards in `files/` are keyed by a character prefix of the path (capped at 5,000 records; 640 shards). A path's shard is a pure function of that path, so shard contents do not churn when the client patches.
