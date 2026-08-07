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

## Loose files at the client root that beat the archives

A 3.3.5 client resolves `<clientRoot>\<path>` on disk BEFORE it looks in the MPQ chain, so a loose file at the client root beats every archive that carries the same path - which is how this client ships its own ChatBubble textures and its silenced Fizzle sounds. The census therefore walks the whole client root, and a loose file whose root-relative path is also an MPQ path WINS that path: `source` becomes `loose`, `winner` becomes `<disk>`, `size`/`sha256` are the file's own, and the archive copy it displaced is preserved under `overrides` so nothing is lost. Which loose files are recorded is decided mechanically, by two conditions and no list of names: a loose file is recorded if (1) it lives under `Data\` - the client's data directory, already covered before this rule existed - or (2) its root-relative path is carried by the MPQ chain, which is what makes it an override at all. Everything else on the disk (the user's installed AddOns, WTF settings, Logs, Screenshots, the WDB caches that raw/cache owns) is machine state rather than client content, is not in the archive namespace, and is deliberately outside this census - it is also volatile between launches, so recording it would make a rerun on an unchanged client stop reproducing. `.MPQ` files themselves are skipped here because they are inventoried as archives, with their members as paths.

Paths won by a loose file here: 15
- `Interface/AddOns/Blizzard_AchievementUI/Blizzard_AchievementUI.pub`
- `Interface/AddOns/Blizzard_AuctionUI/Blizzard_AuctionUI.pub`
- `Interface/AddOns/Blizzard_BindingUI/Blizzard_BindingUI.pub`
- `Interface/AddOns/Blizzard_CombatLog/Blizzard_CombatLog.pub`
- `Interface/AddOns/Blizzard_CombatText/Blizzard_CombatText.pub`
- `Interface/AddOns/Blizzard_DebugTools/Blizzard_DebugTools.pub`
- `Interface/AddOns/Blizzard_GMChatUI/Blizzard_GMChatUI.pub`
- `Interface/AddOns/Blizzard_GuildBankUI/Blizzard_GuildBankUI.pub`
- `Interface/AddOns/Blizzard_InspectUI/Blizzard_InspectUI.pub`
- `Interface/AddOns/Blizzard_ItemSocketingUI/Blizzard_ItemSocketingUI.pub`
- `Interface/AddOns/Blizzard_MacroUI/Blizzard_MacroUI.pub`
- `Interface/AddOns/Blizzard_RaidUI/Blizzard_RaidUI.pub`
- `Interface/AddOns/Blizzard_TalentUI/Blizzard_TalentUI.pub`
- `Interface/Tooltips/chatbubble.blp`
- `Interface/Tooltips/chatbubblevertical.blp`

## Scope: the on-disk `Interface\` tree

Third-party addons the user installed. Not client data, so not extracted; counted here so the boundary is auditable. AddOns/APIDocumentation is the sole exception and is extracted by tools/extract_interface.py.
