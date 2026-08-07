# Complete Interface census (generated)

Regenerate: `python -m tools.extract_interface_all`. Written by
`tools/extract_interface_all.py` from `raw/_inventory/files/` (so run
`python -m tools.inventory` first). Nothing here is hand-authored.

## Totals

- **93,437 Interface paths** (4.449 GB uncompressed in the client)
- **1,456 measured text**, 91,896 measured binary, 85 unreadable
- bytes committed: 1,444 already in `raw/interface/`, 12 added here (60 KB)
- **0 sha256 mismatches** against the inventory across 3.53 GB re-read and re-hashed
- on-disk `Interface\` tree: **4,592 files** (460 MB) in 141 addon directories - counted, not extracted (see below)

## Layout

```
raw/interface_all/index.json        totals, extension census, both rules, shard map
raw/interface_all/paths/*.jsonl     every path, one compact record per line
raw/interface_all/text/**           bytes of text files raw/interface/ does not carry
```

Each path record: `path`, `winner` (archive), `size`, `sha256`, `storedBytes`,
`flags`, `readable`, `isText`, `encoding`, and `bytesAt` - the repo path holding
the bytes, or `null` when only the hash is kept.

## What decides text vs binary

A file is text if its decompressed bytes contain no NUL and fewer than one C0 control byte per 512 bytes outside tab/newline/CR/FF/VT; an empty file is text. Its encoding is recorded as utf-8 when it decodes strictly as UTF-8 and latin-1 otherwise. The rule reads the bytes - no extension list, no filename pattern, and no judgment about which files matter decides it, so a .blp that really were text would be committed and a .lua that really were binary would not.

## Why binary bytes are not committed

Bytes are committed for every file measured as text. For binary files the record carries path, uncompressed size and sha256 and the bytes stay in the client. This is a repository-size decision, not a curation decision: the Interface tree is 4.45 GB and is 99% art. Every binary file's sha256 is here, so the exact bytes this census saw can be pulled from the client and verified at any time.

## Extension census

| ext | files | MB | text | unreadable |
| --- | ---: | ---: | ---: | ---: |
| `blp` | 91,514 | 3,475.4 | 0 | 1 |
| `lua` | 930 | 13.8 | 918 | 12 |
| `xml` | 432 | 5.9 | 420 | 12 |
| `skin` | 154 | 12.1 | 0 | 0 |
| `toc` | 105 | 0.0 | 104 | 1 |
| `m2` | 95 | 21.0 | 0 | 0 |
| `tga` | 81 | 2.1 | 0 | 0 |
| `avi` | 57 | 917.5 | 0 | 57 |
| `sig` | 26 | 0.0 | 0 | 1 |
| `pub` | 14 | 0.0 | 0 | 0 |
| `sbt` | 10 | 0.0 | 10 | 0 |
| `wav` | 10 | 0.5 | 0 | 1 |
| `zmp` | 5 | 0.3 | 0 | 0 |
| `txt` | 2 | 0.0 | 2 | 0 |

## Scope: the on-disk `Interface\` tree

Third-party addons the user installed. Not client data, so not extracted; counted here so the boundary is auditable. AddOns/APIDocumentation is the sole exception and is extracted by tools/extract_interface.py.
