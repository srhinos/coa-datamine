# raw/ - the client, mechanically extracted (generated)

Everything under `raw/` is written by a script in `tools/` from the client at
`E:\ascension-live`. Nothing in it is hand-authored, hand-labelled or
hand-selected: column names are positional, types are inferred by measurement,
and no wanted-list decides what is extracted. Rerunning the scripts on an
unchanged client reproduces it byte for byte.

## Start here

| layer | what it holds | open first | size | state |
| --- | --- | --- | --- | --- |
| `_inventory` | complete census of every file in the client | `raw/_inventory/README.md` | 647 files / 172.5 MB | complete |
| `tables` | every DBC table, decoded, positional f0..fN | `raw/tables/index.json` | 8,612 files / 138.3 MB | complete |
| `dbc` | raw DBC bodies as extracted from the MPQ chain | `raw/dbc/` | 210 files / 43.8 MB | - |
| `content` | loose Data\Content: JSON payloads + .loc localization | `raw/content/index.json` | 2,063 files / 76.4 MB / fileCount 82 / locRecordTotal 1,605,624 | complete |
| `interface` | Interface code layer (.lua/.xml/.toc) as bytes | `raw/interface/_manifest.json` | 1,555 files / 20.7 MB / count 1,553 | complete |
| `interface_all` | every Interface path: size, sha256, text/binary | `raw/interface_all/index.json` | 112 files / 29.8 MB / pathCount 93,437 | complete |
| `cache` | Cache\WDB server query caches, per realm | `raw/cache/index.json` | 78 files / 5.6 MB / fileCount 22 / recordTotal 45,474 | complete |
| `realms` | realm-overlay diff artifacts | `raw/realms/` | 13 files / 14.9 MB | - |
| `talents` | frozen capture of the external CoA talent builder | `raw/talents/` | 2 files / 11.9 MB | - |

## Regenerating

One command rebuilds everything, in dependency order:

```
python -m tools.build_raw            # all six stages (hours; reads the whole client)
python -m tools.build_raw --list     # the stage list + each layer's current state
python -m tools.build_raw --from decode_all   # resume at a stage
```

It is a thin runner over the six stages, which stay individually runnable. Run
them in THIS order if you run them by hand - the order is the contract, because
three of them consume another's output:

```
python -m tools.inventory            # 1 census of every file in the client (~25 min)
python -m tools.extract_all          # 2 pull DBC bodies out of the MPQ chain
python -m tools.decode_all           # 3 decode every table to raw/tables/   [needs 2]
python -m tools.extract_interface    # 4 Interface code layer -> raw/interface/
python -m tools.extract_raw_layers   # 5 content + Interface census + WDB caches [needs 1]
python -m tools.build_catalog        # 6 CATALOG.md + raw/_catalog/            [needs 3]
```

Each stage writes its own `index.json`/`README.md` describing its own rules. No
stage requires an LLM, an argument or a decision.

## Half-written layers cannot happen silently

A raw layer is trustworthy only while it carries `_complete.json`. Every extractor removes that file BEFORE it deletes anything and writes it back LAST, after all of its output, so a layer left half-written by a crash is detectable rather than silently readable. Readers and tests refuse a layer that has no sentinel. The sentinel holds no timestamp, so it does not affect byte-for-byte reproduction.

The `state` column above is that sentinel. A layer marked `no sentinel` is not
to be read: it is either mid-run or was left behind by a crash.

## What "complete" means here, exactly

Stated as a boundary rather than left as an implication:

1. **Every byte is RECORDED. Not every byte is COMMITTED.** Path, size and
   sha256 are in this repo for every file in the client. The bytes themselves
   are committed for everything except large binary media - 486,527 art files
   (53.5 GB), 56,859 sound files (9.0 GB) and the binary part of the Interface
   tree. That is a repository-size rule, applied mechanically by measurement
   (see `raw/interface_all/index.json` -> `sizeRule`), not a judgement about
   which files matter; every excluded byte is recoverable from the client and
   verifiable against the sha256 recorded here.
2. **Complete for THIS install.** The realm overlay is per-machine: this client
   carries `Data/area-52` and `Cache/WDB/enUS/'Rexxar - Conquest of Azeroth'`.
   A realm not installed here is not in this repo, and since the overlay is
   exactly where the extra live spells come from, that is a real boundary.
3. **6.4% of files cannot be decompressed** by `mpyq` at all (PKWARE/ADPCM
   variants it does not implement). They are recorded with `readable: false`
   and their error. The set is entirely binary media: zero DBC, zero JSON, zero
   `.loc`, so the DATA layer is 100% reachable today.
4. **`Interface\AddOns` on disk is out of scope** - it is the user's installed
   third-party addons, not client data. It is counted, never extracted, in
   `raw/interface_all/index.json` -> `onDiskInterfaceTree`. The one exception is
   `AddOns/APIDocumentation`, which is Ascension's own launcher-managed
   description of their API.

## The two rules that matter most when reading any of this

1. **The realm overlay outranks the whole base chain.** `Data\<realm>\` sits
   above every base and locale archive. Twelve tables - `Spell.dbc` among them -
   are won there, and the realm copy carries 14% more spells than the base one.
   The same is true of `Cache\WDB\<locale>\<realm>\` against its parent.
   Reading only the base layer silently loses live content. A LOOSE file at the
   client root outranks even that: the client reads `<root>\<path>` before it
   opens any archive, so `raw/_inventory/files.json` -> `looseOverrides` lists
   the paths whose winning bytes are on disk rather than in an MPQ.
2. **Columns are positional and types are measured.** `f5` means column 5. A
   type is what the bytes support, recorded with the counts behind it, not what
   a name suggests. Where a field layout IS named (the WDB caches), it was
   applied only because it consumed every record exactly, and even there the
   NAMES stay out of the data - they live in
   `raw/cache/_interpretation.json`, labelled as the unverified interpretation
   they are, because a permutation of same-width fields consumes the same bytes
   and so no name can be checked against the client.

## Searching it

```
python -m tools.find "Tide Lash"        # a string, across tables + .loc + WDB caches
python -m tools.find --id 133           # every column an integer appears in
python -m tools.find --joins-to Spell   # every column that points at Spell.f0
```
