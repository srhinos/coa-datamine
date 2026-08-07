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

- **637,590 paths** (637,486 in MPQs, 104 loose under `Data\`)
- **368 DBC tables**
- **77 archives** (8 unlistable), 44.9 GB on disk
- **67.88 GB** uncompressed if everything is extracted
- unreadable files: 4,906
- files in unlistable archives that no harvested name identified: **0**
- paths a loose file at the client root takes from the archives: **25**

## Loose files at the client root beat the whole MPQ chain

A 3.3.5 client resolves `<clientRoot>\<path>` on disk BEFORE it looks in the MPQ chain, so a loose file at the client root beats every archive that carries the same path - which is how this client ships its own ChatBubble textures and its silenced Fizzle sounds. The census therefore walks the whole client root, and a loose file whose root-relative path is also an MPQ path WINS that path: `source` becomes `loose`, `winner` becomes `<disk>`, `size`/`sha256` are the file's own, and the archive copy it displaced is preserved under `overrides` so nothing is lost. Which loose files are recorded is decided mechanically, by two conditions and no list of names: a loose file is recorded if (1) it lives under `Data\` - the client's data directory, already covered before this rule existed - or (2) its root-relative path is carried by the MPQ chain, which is what makes it an override at all. Everything else on the disk (the user's installed AddOns, WTF settings, Logs, Screenshots, the WDB caches that raw/cache owns) is machine state rather than client content, is not in the archive namespace, and is deliberately outside this census - it is also volatile between launches, so recording it would make a rerun on an unchanged client stop reproducing. `.MPQ` files themselves are skipped here because they are inventoried as archives, with their members as paths.

| path | on-disk bytes | archive bytes | archive winner | same bytes? |
| --- | ---: | ---: | --- | --- |
| `DivxDecoder.dll` | 413,696 | 413,696 | Data/enUS/base-enUS.MPQ | yes |
| `Interface/AddOns/Blizzard_AchievementUI/Blizzard_AchievementUI.pub` | 257 | 257 | Data/patch-B.MPQ | yes |
| `Interface/AddOns/Blizzard_AuctionUI/Blizzard_AuctionUI.pub` | 257 | 257 | Data/patch-B.MPQ | yes |
| `Interface/AddOns/Blizzard_BindingUI/Blizzard_BindingUI.pub` | 257 | 257 | Data/patch-B.MPQ | yes |
| `Interface/AddOns/Blizzard_CombatLog/Blizzard_CombatLog.pub` | 257 | 257 | Data/patch-B.MPQ | yes |
| `Interface/AddOns/Blizzard_CombatText/Blizzard_CombatText.pub` | 257 | 257 | Data/patch-B.MPQ | yes |
| `Interface/AddOns/Blizzard_DebugTools/Blizzard_DebugTools.pub` | 257 | 257 | Data/patch-B.MPQ | yes |
| `Interface/AddOns/Blizzard_GMChatUI/Blizzard_GMChatUI.pub` | 257 | 257 | Data/patch-B.MPQ | yes |
| `Interface/AddOns/Blizzard_GuildBankUI/Blizzard_GuildBankUI.pub` | 257 | 257 | Data/patch-B.MPQ | yes |
| `Interface/AddOns/Blizzard_InspectUI/Blizzard_InspectUI.pub` | 257 | 257 | Data/patch-B.MPQ | yes |
| `Interface/AddOns/Blizzard_ItemSocketingUI/Blizzard_ItemSocketingUI.pub` | 257 | 257 | Data/patch-B.MPQ | yes |
| `Interface/AddOns/Blizzard_MacroUI/Blizzard_MacroUI.pub` | 257 | 257 | Data/patch-B.MPQ | yes |
| `Interface/AddOns/Blizzard_RaidUI/Blizzard_RaidUI.pub` | 257 | 257 | Data/patch-B.MPQ | yes |
| `Interface/AddOns/Blizzard_TalentUI/Blizzard_TalentUI.pub` | 257 | 257 | Data/patch-B.MPQ | yes |
| `Interface/Tooltips/ChatBubble-Backdrop.blp` | 12,132 | 12,132 | Data/enUS/locale-enUS.MPQ | no |
| `Interface/Tooltips/ChatBubble-Background.blp` | 2,564 | 2,564 | Data/enUS/locale-enUS.MPQ | no |
| `Interface/Tooltips/ChatBubble-Tail.blp` | 2,564 | 2,564 | Data/enUS/locale-enUS.MPQ | no |
| `Interface/Tooltips/chatbubble.blp` | 44,900 | 44,900 | Data/patch-A.MPQ | no |
| `Interface/Tooltips/chatbubblevertical.blp` | 6,692 | 6,692 | Data/patch-A.MPQ | no |
| `Sound/Spells/Fizzle/FizzleFireA.wav` | 4,454 | 66,194 | Data/common.MPQ | no |
| `Sound/Spells/Fizzle/FizzleFrostA.wav` | 4,454 | 70,908 | Data/common.MPQ | no |
| `Sound/Spells/Fizzle/FizzleHolyA.wav` | 4,454 | 77,182 | Data/common.MPQ | no |
| `Sound/Spells/Fizzle/FizzleNatureA.wav` | 4,454 | 63,042 | Data/common.MPQ | no |
| `Sound/Spells/Fizzle/FizzleShadowA.wav` | 4,454 | 72,890 | Data/common.MPQ | no |
| `WowError.exe` | 205,824 | 220,816 | Data/enUS/base-enUS.MPQ | no |

Each of these records the DISK bytes as the winner. The archive copy it displaced is kept in full under `overrides` in the path record - nothing is dropped, it is just no longer reported as the file the client loads.

## What is not readable, and whether it matters

Every read in this census goes through tools/mpq.py, the reader whose output is verified against each archive's own `(attributes)` MD5 oracle. It used to go through `mpyq`, which mis-slices any member stored WITHOUT a sector offset table: it treats such a member's sectors as if a table were present, so the bytes it returns are not the bytes the archive holds. The crack phase measured the damage against the MD5 oracle - 1,266 of this client's 1,271 no-sector-table members were read wrong, and 1,186 of them were winning paths whose sha256 this census had published. Every one is music, cinematics, or one nested archive; no DBC, Interface or Content file is affected, which is why the derived data layers were never wrong. raw/recovered/corrections/ is the record of that disagreement, and this census now agrees with it by construction rather than by patch.

tools/mpq.py implements every compression this client's sectors actually use (zlib, bzip2, PKWARE/explode, sparse). The three it does not implement - Blizzard adaptive huffman and the two IMA ADPCM audio codecs - occur in ZERO sectors here, which the run measures rather than assumes. Anything that still cannot be read is recorded with `readable: false`, its `memberStatus` and the reader's own error - never dropped.

| unreadable by class | count |
| --- | ---: |
| art | 4,879 |
| interface | 22 |
| sound | 5 |

| reason | count |
| --- | ---: |
| deleted: patch tombstone: this layer DELETES the path; it carries no bytes | 4,906 |

Unreadable files with a DATA extension (dbc/json/lua/xml/toc/txt/loc): `{'lua': 9, 'xml': 10, 'toc': 1}`. Everything else unreadable is binary media (ogg/wav/blp/mp3/avi/...).

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
| art | 486,663 | 53.464 |
| sound | 56,859 | 8.961 |
| interface | 93,437 | 4.449 |
| dbc | 368 | 0.836 |
| content | 82 | 0.094 |
| other | 181 | 0.074 |
| **total** | **637,590** | **67.878** |

`class` is a reporting rollup only - it gates nothing. `categories.json` carries the raw `byTopLevelDir` and `byExtension` censuses it is derived from.

## Finding a path

Shards in `files/` are keyed by a character prefix of the path (capped at 5,000 records; 640 shards). A path's shard is a pure function of that path, so shard contents do not churn when the client patches. `files.json` lists each shard's `prefix`, `firstPath` and `lastPath`; grepping `files/` directly also works.
