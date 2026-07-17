# CoA Datamine — Design Spec

**Date:** 2026-07-17
**Status:** Approved (design approved in-session; spec pending user review)
**Repo:** `Documents\github\coa-datamine`

## Purpose

Build an agent-consumable dataset of Ascension **Conquest of Azeroth** (CoA) game data —
classes, spells, talents, dungeons/raids — datamined from the client install at
`E:\ascension-live`. Future porting agents (dispel logic, class buffs, raid frames,
minimap blips, etc.) point at this repo instead of re-mining the client each time.

v1 scope (user-selected): **classes + spells**, **dungeons + raids**, **talents**.
Explicitly deferred: items / mystic enchants / skill cards / transmog.

## Source inventory (verified 2026-07-17)

The client ships two kinds of data:

### 1. Plain-JSON sidecars — `E:\ascension-live\Data\Content\`
No MPQ extraction needed. Verified structure by direct read:

| File | Contents | Role in v1 |
|---|---|---|
| `CharacterAdvancementData.json` (7.8 MB, 23 709 entries) | `{Class, Tab, Type(Ability/Talent/Trait/TalentAbility), Spells[], RequiredLevel, Quality, AECost, Realms, Icon, Flags}` | **Authority for who-gets-what.** 41 class values: 9 vanilla, 10 `Reborn*` (+`RebornGeneral`), 21 CoA customs (Chronomancer, Necromancer, Runemaster, Starcaller, Cultist, SunCleric, Tinker, Venomancer, WitchDoctor, Primalist, Ranger, WitchHunter, Pyromancer, SonOfArugal, Barbarian, KnightOfXoroth, Monk, Guardian, DemonHunter, Stormbringer, Reaper), plus `None`/`ConquestOfAzeroth` markers |
| `SpellRankData.json` | `{firstSpellId, spellId, rank, level}` chains | Rank-chain grouping |
| `LFGData.json` | Per-`DungeonId` reward/quest tables | Join to LFGDungeons.dbc |
| `WorldMapAreaData.json` | Map/area rectangles | Dungeon→zone naming support |
| `SpellToRoleSuggestionData.json` | `{Spell, TankScore, HealerScore, DamageScore}` | Role hints per spell |
| Others (enchant/stat suggestion, SkillCard, TradeSkill, ItemVariation) | — | Out of scope v1; snapshotted only |

`Data\Content\Localization\{Spell,Item,Unit}\...\<locale>.loc` — non-enUS locales only
(enUS strings live in the DBCs). Custom `.loc` binary format, undocumented. **Not parsed
in v1**; noted as future work (Unit names could enrich encounter data).

### 2. MPQ archives — `E:\ascension-live\Data\`
Probed all 70 archives with `mpyq` (installed, works). DBC carriers:

- **`patch-M.MPQ`** — 288 DBCs incl. ChrClasses, ChrRaces, Talent, TalentTab,
  LFGDungeons, DungeonEncounter, Map, AreaTable, SkillLine, SkillLineAbility,
  SkillRaceClassInfo
- **`patch-S.MPQ`** — 48 spell-support DBCs: SpellDispelType, SpellMechanic,
  SpellDuration, SpellRange, SpellRadius, SpellCastTimes, SpellIcon, SpellRuneCost
- **`patch-T.MPQ`** — `Spell.dbc` (custom; spell IDs observed up to ~955 000)

Non-openable archives: `patch-4/5/C/CZZ/W/WB/WC.MPQ` are 131 165-byte placeholder stubs
(no listfile); `patch-P.mpq` (131 KB) is encrypted. None carry needed data; the build
records them in provenance and moves on.

Realm confirmed from `WTF\Config.wtf`: **Rexxar — Conquest of Azeroth**.
`Data\area-52\` is a different realm's patch dir; ignored.

## Approach

**JSON-first, DBC-enriched** (approved over full-relational-DBC and in-game-scrape
alternatives): CharacterAdvancementData drives class membership; DBCs enrich spell
records; dungeons come from DBC joins + LFGData.json. Raw DBC dumps are kept so a
relational model stays possible later without re-extraction.

## Architecture

Three-stage deterministic pipeline, one entry point, idempotent:

```
[1 extract]  MPQs --mpyq--> raw DBC bytes        (tools/extract_mpq.py)
[2 decode]   DBC bytes --> raw/dbc/*.csv.gz      (tools/dbc.py)
             Data\Content JSONs --> raw/content/  (verbatim snapshot + sha256)
[3 build]    raw/* --> data/* curated JSON        (tools/build_dataset.py)
```

### Repo layout

```
coa-datamine/
  README.md                   what this is, how to regenerate, layout map
  tools/
    extract_mpq.py            chain-order-aware extraction (see below)
    dbc.py                    generic WDBC reader + per-table column maps
    build_dataset.py          orchestrator + inline sanity checks
  raw/
    dbc/*.csv.gz              full dumps of the ~20 relevant DBCs
    content/*.json            snapshot of Data\Content sources
    provenance.json           source file sha256s, archive→file resolution, timestamps
  data/
    classes/index.json        roster: class name, realm tag (CoA/classless), counts
    classes/<Class>.json      per-class spell entries (schema below)
    spells/spells.json        all referenced spells, fully enriched
    talents/<Class>.json      talent tree per class
    dungeons/dungeons.json    dungeons + raids + encounters
  docs/
    AGENT-GUIDE.md            query recipes, classID↔name table, caveats/limits
    superpowers/specs/        this spec
```

### Component: `tools/extract_mpq.py`

- Scans **all** archives in `Data\` and `Data\enUS\` (locale patches can override DBCs).
- Builds the patch-chain order: base archives < locale bases < `patch.MPQ` <
  `patch-<digit>` < locale patches (`patch-enUS-<n>`) < `patch-<letters>`
  (lexicographic, shorter-prefix-first, matching the 3.3.5 loader that Ascension's
  launcher extends). For every wanted file, the **latest** archive in chain order wins;
  every multi-archive collision is logged into `provenance.json` with the loser
  archives listed, so a wrong chain assumption is visible, not silent — if the probe's
  single-carrier finding holds (each wanted DBC in exactly one custom patch), order
  never actually decides anything.
- Extracts only `DBFilesClient\*.dbc` in the wanted-list (~20 tables).

### Component: `tools/dbc.py`

- Generic WDBC v1 reader: header `(magic, record_count, field_count, record_size,
  string_block_size)`, records as int32 grid + string-block offsets.
- Per-table column maps for the 3.3.5 layouts we consume (Spell, ChrClasses, Talent,
  TalentTab, LFGDungeons, DungeonEncounter, Map, AreaTable, SkillLine, SkillLineAbility,
  SpellDispelType, SpellMechanic, SpellDuration, SpellRange, SpellRadius,
  SpellCastTimes, SpellIcon).
- **Layout guard:** asserts `field_count`/`record_size` against the expected stock
  layout. On mismatch (Ascension may have widened tables), the reader fails loudly with
  both numbers; the column map is then re-verified manually against golden records
  before any derived output is produced. No silent column-shift tolerated.
- Dumps every decoded table to `raw/dbc/<name>.csv.gz` with named headers.

### Component: `tools/build_dataset.py`

Joins, in order:

1. **spells.json** — for every spell ID referenced by CharacterAdvancementData,
   SpellRankData, or Talent.dbc ranks: id, name, subtext/rank, tooltip (description +
   aura description, raw `$`-token form), school mask (+decoded names), dispel type
   (id + name from SpellDispelType.dbc), mechanic (id + name), attributes (raw ints),
   cast time, duration, range, power type/cost, effect triplets (Effect, EffectAura,
   BasePoints, Amplitude, targets — ids + decoded enum names from bundled 3.3.5 enum
   tables), icon path, role scores from SpellToRoleSuggestionData.
2. **classes/** — group CharacterAdvancementData by `Class`; each entry: CAD fields +
   resolved spell summary + rank chain (from SpellRankData). `Realms` bitmask carried
   raw with an `unknown-semantics` note. Index tags each class CoA-custom / Reborn /
   vanilla.
3. **talents/** — Talent.dbc rows joined to TalentTab.dbc (tab name, class linkage) and
   cross-checked against CAD `Type=Talent/TalentAbility` entries; both views emitted
   (DBC tree structure + CAD talent list) since CoA may drive talents from either.
4. **dungeons.json** — LFGDungeons.dbc (name, level ranges, type, expansion, flags)
   joined to Map.dbc (instance map, max players, raid flag), AreaTable.dbc (zone names),
   DungeonEncounter.dbc (ordered encounters per map+difficulty), LFGData.json rewards.
   Raid vs dungeon classification from Map.dbc instance type.

### `docs/AGENT-GUIDE.md`

Written for a future porting agent: file map, JSON schemas, classID↔name table (from
patched ChrClasses.dbc), query recipes ("all magic-dispellable buffs a class can cast",
"all encounters in dungeon X", "which classes get spell Y"), plus the honest-limits
list below.

## Honest limits (documented, not hidden)

- Client data cannot see **server-side** logic: boss ability scripts, loot, runtime
  spell grants, aura scripting. Encounter lists are names/order only.
- `Realms` bitmask semantics unknown — carried raw.
- Tooltip `$` tokens are kept raw (no server-side formula evaluation).
- `.loc` localization format unparsed in v1.
- CAD is authoritative for *obtainable* abilities; spells granted by procs/items/hidden
  auras appear only in spells.json if referenced elsewhere.

## Validation (build fails loudly, never emits plausible-but-wrong)

- **Layout guard** on every DBC (above).
- **Golden spells:** spell 17 must decode as "Power Word: Shield" with Magic dispel
  type; spell 10 = "Blizzard"; ≥1 high-ID custom spell (e.g. 954876 from SkillCardData)
  must resolve to a non-empty name.
- **Referential integrity:** every CAD `Spells[]` ID resolves in Spell.dbc (misses
  reported with counts; build fails if >1% missing); every DungeonEncounter map ID
  exists in Map.dbc; every talent's spell ranks resolve.
- **Chain-order check:** if any wanted DBC resolves from an unexpected archive, the
  collision report surfaces it.
- **Counts sanity:** class count ≥ 30; per-class spell counts within ±20% of CAD entry
  counts observed in recon (e.g. RebornWarlock ≈ 1 719 entries).

Verification is fully offline file-parsing — no in-game confirmation gate required
(unlike pixel/interaction addon work).

## Regeneration

`python tools/build_dataset.py` re-runs the whole pipeline against the live install
path (configurable, default `E:\ascension-live`). Output is deterministic; provenance
records source hashes so a diff of `raw/` shows exactly what a game patch changed.

## Out of scope / future

- Items, mystic enchants, skill cards, transmog (deferred by user).
- `.loc` parsing (unit names → encounter enrichment).
- SQLite relational view over raw dumps.
- In-game spot-check addon.
