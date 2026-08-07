# Client inventory (generated)

Regenerate: `python -m tools.inventory`. Every file here is written by `tools/inventory.py`; nothing in it is hand-authored, and nothing in the client is filtered out of it.

## Start here

| file | what it answers |
| --- | --- |
| `archives.json` | every MPQ, its chain rank, whether it lists, its sha256 |
| `dbc.json` | every DBFilesClient table + its measured WDBC header |
| `categories.json` | how many bytes a full raw extraction costs, by class / directory / extension |
| `unlistable.json` | the archives with no readable `(listfile)`, and what is provably in them |
| `files.json` | index of the per-path shards in `files/` |
| `files/*.json` | one compact record per line: path, winning archive, size, sha256, flags |

## Totals

- **637,454 paths** (637,350 in MPQs, 104 loose under `Data\`)
- **368 DBC tables**
- **77 archives** (8 unlistable), 44.9 GB on disk
- **67.87 GB** uncompressed if everything is extracted
- unreadable files: 41,053
- files in unlistable archives that no harvested name identified: **0**

## What is not readable, and whether it matters

`mpyq` implements only the zlib and bzip2 MPQ compressions; the client also uses PKWARE/ADPCM variants. Files it cannot decode are recorded with `readable: false` and the error - never dropped.

| unreadable by class | count |
| --- | ---: |
| sound | 35,921 |
| art | 5,031 |
| interface | 85 |
| other | 16 |

| reason | count |
| --- | ---: |
| compression mpyq cannot decode | 36,141 |
| empty override block | 4,912 |

Unreadable files with a DATA extension (dbc/json/lua/xml/toc/txt/loc): `{'lua': 12, 'xml': 12, 'toc': 1}`. Everything else unreadable is binary media (ogg/wav/blp/mp3/avi/...).

## DBC tables won by a realm overlay, not the base chain

These sit ABOVE the entire base chain, so the base copy is NOT what the client uses.

| table | winner | records | base copies overridden |
| --- | --- | ---: | ---: |
| CharacterAdvancement.dbc | Data/area-52/patch-D.MPQ | 7,820 | 1 |
| CharacterAdvancementEssence.dbc | Data/area-52/patch-D.MPQ | 5,440 | 1 |
| Manastorm.dbc | Data/area-52/patch-D.MPQ | 1,025 | 1 |
| ManastormMessages.dbc | Data/area-52/patch-D.MPQ | 291 | 1 |
| ManastormModifiers.dbc | Data/area-52/patch-D.MPQ | 32,768 | 1 |
| ManastormPlayerGroupModifiers.dbc | Data/area-52/patch-D.MPQ | 15 | 1 |
| SkillLineAbility.dbc | Data/area-52/patch-D.MPQ | 38,542 | 5 |
| Spell.dbc | Data/area-52/patch-D.MPQ | 238,939 | 5 |
| SpellCharges.dbc | Data/area-52/patch-D.MPQ | 473 | 1 |
| SpellChargesCategory.dbc | Data/area-52/patch-D.MPQ | 108 | 1 |
| SpellRank.dbc | Data/area-52/patch-D.MPQ | 19,601 | 1 |
| Talent.dbc | Data/area-52/patch-D.MPQ | 2,368 | 4 |

## Extraction cost by class

| class | files | GB |
| --- | ---: | ---: |
| art | 486,527 | 53.457 |
| sound | 56,859 | 8.961 |
| interface | 93,437 | 4.449 |
| dbc | 368 | 0.836 |
| content | 82 | 0.094 |
| other | 181 | 0.074 |
| **total** | **637,454** | **67.870** |

`class` is a reporting rollup only - it gates nothing. `categories.json` carries the raw `byTopLevelDir` and `byExtension` censuses it is derived from.

## Finding a path

Shards in `files/` are keyed by a character prefix of the path (capped at 5,000 records; 640 shards). A path's shard is a pure function of that path, so shard contents do not churn when the client patches. `files.json` lists each shard's `prefix`, `firstPath` and `lastPath`; grepping `files/` directly also works.
