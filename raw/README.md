# raw/ - the client, mechanically extracted (generated)

Everything under `raw/` is written by ONE script, `datamine.py`, from a snapshot
of the client at `E:\ascension-live`. Nothing in it is hand-authored,
hand-labelled or hand-selected: column names are positional, types are inferred
by measurement, and no wanted-list decides what is extracted.

## Regenerating

```
python datamine.py
```

No arguments, no stages, no order to get right, no LLM. It snapshots the client,
walks each archive exactly once, and rebuilds every layer below.

## Start here

| layer | what it holds | open first | size | state |
| --- | --- | --- | --- | --- |
| `_inventory` | complete census of every file in the client | `raw/_inventory/README.md` | 647 files / 172.2 MB | complete |
| `tables` | every DBC table, decoded, positional f0..fN | `raw/tables/index.json` | 13,067 files / 266.1 MB | complete |
| `content` | loose Data\Content: JSON payloads + .loc localization | `raw/content/index.json` | 2,063 files / 76.4 MB | complete |
| `interface` | Interface code layer (.lua/.xml/.toc) as bytes | `raw/interface/_manifest.json` | 1,560 files / 20.7 MB | complete |
| `interface_all` | every Interface path: size, sha256, text/binary | `raw/interface_all/index.json` | 112 files / 29.8 MB | complete |
| `cache` | Cache\WDB server query caches, per realm | `raw/cache/index.json` | 78 files / 5.8 MB | complete |
| `binaries` | the client's own executables: strings, Lua, PE structure | `raw/binaries/index.json` | 1,379 files / 19.1 MB | complete |
| `recovered` | archive forensics: MD5 oracle, tombstones, containers | `raw/recovered/README.md` | 773 files / 36.4 MB | complete |
| `_catalog` | the searchable catalog: joins, strings, columns | `raw/_catalog/tables.json` | 4 files / 10.8 MB | complete |

## What this dataset was built from

`raw/_snapshot.json` records the sha256, size and mtime of every one of the
342 files (45.9 GB) this run copied out of the client
before it read anything. That is this dataset's identity.

The snapshot being minutes or hours behind the live client is expected and harmless - the launcher patches the archives roughly hourly. What matters is that ONE client version goes in and ONE dataset comes out: without the snapshot a long run would read a mixture of versions and no layer could be said to describe any one of them.

## The two rules that matter most when reading any of this

1. **A table has several VERSIONS, and the default pick is not always the one
   your question wants.** `Data\<realm>\` sits above every base and locale
   archive, so for some tables the chain winner in `raw/tables/<Table>/` is the
   realm overlay's data, not what a character on a realm without an overlay
   reads. Every distinct version is decoded to
   `raw/tables/<Table>/variants/<archive-slug>/` under the same rules, and
   `raw/tables/_variants.json` lists which chain context selects which.
2. **Columns are positional and types are measured.** `f5` means column 5. A
   type is what the bytes support, recorded with the counts behind it, not what
   a name suggests.

## Searching it

```
python -m tools.find "Tide Lash"        # a string, across tables + .loc + WDB caches + binaries
python -m tools.find --id 133           # every column an integer appears in
python -m tools.find --joins-to Spell   # every column that points at Spell.f0
```
