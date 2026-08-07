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
| `tables` | every DBC table, decoded, positional f0..fN | `raw/tables/index.json` | 13,067 files / 266.2 MB | complete |
| `dbc` | raw DBC bodies as extracted from the MPQ chain | `raw/dbc/` | 210 files / 43.8 MB | - |
| `content` | loose Data\Content: JSON payloads + .loc localization | `raw/content/index.json` | 2,063 files / 76.4 MB / fileCount 82 / locRecordTotal 1,605,624 | complete |
| `interface` | Interface code layer (.lua/.xml/.toc) as bytes | `raw/interface/_manifest.json` | 1,555 files / 20.7 MB / count 1,553 | complete |
| `interface_all` | every Interface path: size, sha256, text/binary | `raw/interface_all/index.json` | 112 files / 29.8 MB / pathCount 93,437 | complete |
| `cache` | Cache\WDB server query caches, per realm | `raw/cache/index.json` | 78 files / 5.6 MB / fileCount 22 / recordTotal 45,474 | complete |
| `binaries` | the client's own executables: strings, embedded Lua, PE structure | `raw/binaries/index.json` | 1,379 files / 19.1 MB | complete |
| `recovered` | what was still opaque: deleted/encrypted members, the files the old reader could not read, CRC32+MD5+mtime per path, expanded containers | `raw/recovered/README.md` | 273 files / 131.7 MB | complete |
| `realms` | realm-overlay diff artifacts | `raw/realms/` | 13 files / 14.9 MB | - |
| `talents` | frozen capture of the external CoA talent builder | `raw/talents/` | 2 files / 11.9 MB | - |

## Regenerating

One command rebuilds everything, in dependency order, and prints what changed
since the last run:

```
python -m tools.extract_everything                    # all 8 stages (hours; reads the whole client)
python -m tools.extract_everything --list             # the stage list + each layer's current state
python -m tools.extract_everything --from decode_all  # resume at a stage
python -m tools.extract_everything --only build_catalog   # rerun exactly one stage
```

It is a thin runner over the 8 stages, which stay individually runnable. Run
them in THIS order if you run them by hand - the order is the contract, because
three of them consume another's output:

```
python -m tools.inventory           # 1 census every archive and every path in the client
python -m tools.extract_all         # 2 pull every DBFilesClient body out of the winning chain
python -m tools.decode_all          # 3 decode every table to raw/tables/, positional f0..fN
python -m tools.extract_interface   # 4 the Interface code layer, as bytes
python -m tools.extract_raw_layers  # 5 Data\Content + .loc, the Interface census, the WDB caches
python -m tools.crack               # 6 recover deleted/encrypted/undecodable members, expand containers, and verify every member against its archive's own MD5
python -m tools.extract_binaries    # 7 the client's own executables: strings, embedded Lua, PE structure
python -m tools.build_catalog       # 8 the searchable catalog over raw/tables/
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
3. **Every file in the client decodes.** The 6.4% that `raw/_inventory` still
   records as `readable: false` were never a compression problem - they are a
   defect in `mpyq`, which is not a complete MPQ reader. `tools/mpq.py` is, and
   `raw/recovered/` is the proof: 36,139 of them decode correctly, 4,906 were
   MPQ delete tombstones that carry no bytes by design, 6 are genuinely empty,
   and **0 remain unreadable**. The conclusion the old note reached - zero DBC,
   zero JSON, zero `.loc`, so the DATA layer is fully reachable - was right, and
   is now checked rather than inferred: every one of the 36,139 is binary media
   or an executable.

   The same reader found the reverse problem too. 1,271 members are stored with
   no sector offset table, `mpyq` mis-reads all of them, and 1,186 of the
   sha256s in `raw/_inventory` are therefore hashes of bytes that were never in
   the archive (music, cinematics, one nested archive - again no data file).
   `raw/recovered/corrections/` lists every one with its true hash.
   `raw/_inventory` itself is left as its own tool produces it; correcting it
   means moving `tools/inventory.py` onto `tools/mpq.py` and re-running the
   census.

   All of this is now verified against an oracle that is not another reader:
   every archive records an MD5 per member in its `(attributes)` block, and
   `python -m tools.crack --only verify` checks all **763,928** of them.
   Mismatches: 0.
4. **The client's own executables are opened too.** `raw/binaries/` holds every
   printable string, the inlined Lua and the full PE structure of every PE image
   in the client - the seven loose in the client root, and the twenty stored
   INSIDE the MPQ archives under `_archived/` (`Wow.exe`, `Launcher.exe`,
   `Battle.net.dll`, `Repair.exe` and the rest, found by reading the bytes of
   every member the archives name). This is the layer that explains where
   `listarchive`, `SetDataPath` and the realm hot-swap script actually live,
   none of which is in any shipped data file.
5. **`Interface\AddOns` on disk is out of scope** - it is the user's installed
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
python -m tools.find "Tide Lash"        # a string, across tables + .loc + WDB caches + binaries
python -m tools.find --id 133           # every column an integer appears in
python -m tools.find --joins-to Spell   # every column that points at Spell.f0
python -m tools.find "listarchive" --layer binaries   # the client's executables only
```
