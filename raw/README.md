# raw/ - the client, mechanically extracted (generated)

Everything under `raw/` is written by a script in `tools/` from the client at
`E:\ascension-live`. Nothing in it is hand-authored, hand-labelled or
hand-selected: column names are positional, types are inferred by measurement,
and no wanted-list decides what is extracted. Rerunning the scripts on an
unchanged client reproduces it byte for byte.

## Start here

| layer | what it holds | open first | size |
| --- | --- | --- | --- |
| `_inventory` | complete census of every file in the client | `raw/_inventory/README.md` | 646 files / 173.1 MB |
| `tables` | every DBC table, decoded, positional f0..fN | `raw/tables/index.json` | 8,611 files / 138.3 MB |
| `dbc` | raw DBC bodies as extracted from the MPQ chain | `raw/dbc/` | 210 files / 43.9 MB |
| `content` | loose Data\Content: JSON payloads + .loc localization | `raw/content/index.json` | 2,062 files / 76.4 MB / fileCount 82 / locRecordTotal 1,605,624 |
| `interface` | Interface code layer (.lua/.xml/.toc) as bytes | `raw/interface/_manifest.json` | 1,554 files / 20.7 MB / count 1,553 |
| `interface_all` | every Interface path: size, sha256, text/binary | `raw/interface_all/index.json` | 111 files / 29.8 MB / pathCount 93,437 |
| `cache` | Cache\WDB server query caches, per realm | `raw/cache/index.json` | 76 files / 6.9 MB / fileCount 22 / recordTotal 45,474 |
| `realms` | realm-overlay diff artifacts | `raw/realms/` | 13 files / 14.9 MB |
| `talents` | frozen capture of the external CoA talent builder | `raw/talents/` | 2 files / 11.9 MB |

## Regenerating

```
python -m tools.inventory            # census of every file in the client (~25 min)
python -m tools.extract_all          # pull DBC bodies out of the MPQ chain
python -m tools.decode_all           # decode every table to raw/tables/
python -m tools.extract_interface    # Interface code layer -> raw/interface/
python -m tools.extract_raw_layers   # content + interface census + WDB caches
```

Each stage is independent and each writes its own `index.json`/`README.md`
describing its own rules. No stage requires an LLM, an argument or a decision.

## The two rules that matter most when reading any of this

1. **The realm overlay outranks the whole base chain.** `Data\<realm>\` sits
   above every base and locale archive. Twelve tables - `Spell.dbc` among them -
   are won there, and the realm copy carries 14% more spells than the base one.
   The same is true of `Cache\WDB\<locale>\<realm>\` against its parent.
   Reading only the base layer silently loses live content.
2. **Columns are positional and types are measured.** `f5` means column 5. A
   type is what the bytes support, recorded with the counts behind it, not what
   a name suggests. Where a field layout IS named (the WDB caches), it was
   applied only because it consumed every record exactly, and its source is
   recorded next to it.
