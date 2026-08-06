# Agent Guide - querying coa-datamine

Dataset of Ascension CoA (WoW 3.3.5a custom server) game data for porting work
(dispel logic, class buffs, raid tooling). Everything below is generated - do not
hand-edit; rerun `python -m tools.build_dataset` after a client patch instead.

## File map

**Amendment C (sharding).** No committed `data/` file is an arbitrary 10k+-line
monolith: every dataset with enough records to matter is split by a stable semantic
key (per-dungeon file, per-class-per-tab file) or a fixed id range (`id // N * N`
bucket - never count-based chunking, since that reshuffles every file's contents on
insertion and destroys diff locality). Every sharded dataset has an `index.json`
manifest that fully enumerates its shard files; `index.json` files themselves use a
compact one-record-per-line format (not the content files' `indent=1`) so a
several-hundred-record manifest stays small and still diffs one line per record. A
repo-wide test (`tests/test_sharding.py`) asserts every `data/**/*.json(l)` file is
<=5,000 lines except an explicit, commented allowlist (currently empty - nothing in
this repo needs an exemption).

| Path | What | Size class |
|---|---|---|
| `data/classes/index.json` | class roster + tags + classId map + `dir`/`index` pointers into each class's subdirectory + `chrClasses` (ChrClasses.dbc table, 32 rows, ids 1-32, each carrying `filename` - task W4-5) + `unmatchedChrClasses` (ChrClasses rows with no CAD data: **Hero only**, task W4-5 - was Bloodmage/Felsworn/Hero/Templar before the `filename`-join fix, see "ChrClasses filename join..." below) | small |
| `data/classes/_realms_evidence.json` | task W4-8: the `Realms`-bitmask decode attempt (DATAMINE-REQUEST.md Sec 6.2) - distinct-value census (28 values/23,709 entries), per-tag/per-bit statistics, a live duplication example, candidate-hypothesis scoring, Lua findings, and the verdict. **HONEST FAILURE, not a decode** - see "Realms bitmask decode attempt..." below; no `realmFlags` exists anywhere, raw `realms` on class entries is unchanged | small |
| `data/classes/<Class>/index.json` | that class's `tag`/`classId`/`realmHint`/`aliases`/`entryCount`/`unresolvedCount` + `files: [{file, tab, type, cadIdRange, count}]` enumerating every shard file for the class - `aliases` (task W4-5) is `[]` for 40 of 43 classes, `[<ClassRemap token>]` for the 4 CoA-custom classes whose internal filename token isn't a trivial uppercase of their own CAD name (Runemaster/Primalist/Venomancer/KnightOfXoroth) | small |
| `data/classes/<Class>/<Tab>.json` | one spec tab's obtainable abilities/talents/traits with resolved spells (`{class, tab, type: null, entries}`); each resolved spell's `ranks[]` already carries `{spellId, rank, level}` per rank (unchanged V1 design, verified still current by task W4-4) - for level-60 rank selection, look up that chain's first-rank id in `data/spells/` instead and read its `rankAt60` field (task W4-4) rather than re-deriving the CAD-level cutoff here | small-medium |
| `data/classes/<Class>/<Tab>.<Type>.json` / `<Tab>.<Type>-<cadId-bucket>.json` | only present when a single tab's entries exceed 5,000 lines as one file (Reborn* classes' biggest tabs) - see "Class tab sharding" below | small |
| `data/classes/<Class>/_general.json` | entries with no `Tab` (none exist in the current snapshot; the file only appears if some do) | small |
| `data/spells/index.json` | bucket manifest: `bucketSize` (10000), total `count`, `buckets: [{bucket, file, count, minId, maxId}]` | small |
| `data/spells/by-id/spells-<id//10000*10000>.jsonl` | every referenced spell in that id bucket, fully enriched, ONE JSON PER LINE, ascending id within the bucket; empty buckets are omitted - each effect carries `realPointsPerLevel`/`pointsPerComboPoint`/`spellClassMask`/`damageMultiplier`/`bonusMultiplierStock` when nonzero (task W4-3, see "Spell column completion" below), and each record carries `speed`/`equippedItem`/`maxAffectedTargets`/`casterAuraSpell`/`targetAuraSpell`/`manaPerSecond`/`targetCreatureType`/`casterAuraState`/`targetAuraState`/`stancesNot`/`missileId`/`family.flags3` unconditionally; task W4-4 adds `rankAt60` (chain's own first-rank record only, omitted when none of that chain's ranks are CAD-level<=60) and `devDead: true` (7 records, see "Formula closure, level-60 ranks..." below) when applicable | small-medium per file - stream/grep it, do not slurp |
| `data/spells/_meta.json` | counts only: `count`, `missing_ref_counts_by_source`, `ref_counts`, `dataNotes`, `by_source`, `missingRefsFile` pointer, `columnCoverage` (pointer to `_coverage.json` + summary counts), `formulaClosure`/`rankAt60`/`scalingConstants`/`devDead` (task W4-4, see "Formula closure, level-60 ranks..." below) | small |
| `data/spells/_coverage.json` | task W4-3: per-`TABLE_MAPS["Spell"]`-column `{index, kind, mapped, emitted, where}` manifest (128 mapped of 234 total fields, 124 emitted/4 mapped-not-emitted) - see "Spell column completion" below | small |
| `data/spells/_missing_refs.json` | full missing-ref id lists by source (`cad_other`/`cad_reborn`/`talent`/`rank`/`formula` - task W4-4 adds `formula`, report-only, never folded into the `cad_other`/`talent` hard gates), each source's array on ONE line | small (line count, not byte count) |
| `data/talents/<ChrClass>.json` | DBC talent trees (row/col/ranks/prereqs) - only exists for the 12 classes that have DBC talent tabs; largest is ~3.6k lines, under the gate as-is, not sharded | medium |
| `data/talents/_pet.json` | pet talent tabs (`petTalentMask` set) - not tied to a single player class | small |
| `data/talents/_unassigned.json` | talent tabs matching no classMask/petTalentMask | small |
| `data/talents/_meta.json` | tab/talent counts, per-class tab counts, unresolved rank-spell count | small |
| `data/dungeons/index.json` | one compact record per dungeon: `{id, name, file, mapId, isRaid, levels}` | small |
| `data/dungeons/<id>-<slug>.json` | one dungeon incl. its encounters (ordered, each carrying a `creature: {id, name}\|null` boss link - see Honest limits) + reward brackets; `<slug>` = lowercase name, non-alnum runs -> `-`, collapsed, max 40 chars | small |
| `data/creatures/index.json` | bucket manifest: `bucketSize` (5000), `count` (127178), `buckets: [{bucket, file, count, minId, maxId}]` - **355 buckets**, not 26: `id` is `Creature.dbc` f1 (a sparse space up to ~11M), not the old f0 row-position (see Honest limits) | small |
| `data/creatures/creatures-<id//5000*5000>.jsonl` | `{id, name, subname}` per `Creature.dbc` row, ONE JSON PER LINE, ascending id within bucket; `id` is the real, stable creature TEMPLATE ENTRY id (`Creature.dbc` f1, task V3-0) - use it to cross-reference `data/dungeons/*.json`'s `creature.id`; `subname` is **always `null`** - probed and disproven, see Honest limits | small-medium per file |
| `data/creatures/_meta.json` | `count`, `provenColumns` (id/name proof), `idCorrectionFinding` (the V3-0 f0->f1 writeup), `subnameFinding` (the disproof writeup) | small |
| `data/quests/index.json` | bucket manifest, same shape as creatures (`bucketSize` 5000, `count` 18561) | small |
| `data/quests/quests-<id//5000*5000>.jsonl` | `{id, sort: null, info: null, f1..f28}` per `Quest.dbc` row - **this table has no string block at all** (no quest title/objective text anywhere in it, see Honest limits); `sort`/`info` are always `null` (probed and disproven); the 28 remaining columns are raw/unnamed | small-medium per file |
| `data/quests/_meta.json` | `count`, `provenColumns`, `sortInfoFinding` | small |
| `data/trainers/index.json` | bucket manifest (`bucketSize` 2000, `count` 13111) | small |
| `data/trainers/trainers-<id//2000*2000>.json` | `{bucket, count, minId, maxId, entries: [{id, spellId, name, skillLine:{id,name}\|null, f3}]}` - a **flat per-row list**, not grouped by trainer: `NPCTrainer.dbc` has no trainer-NPC identity column at all (see `trainerIdFinding` in `_meta.json`) | small |
| `data/trainers/_meta.json` | `count`, `spellJoinRate` (0.9892), `provenColumns`, `trainerIdFinding` | small |
| `data/classes/specs.json` | `{specs: [101 ChrSpecs rows: id, name, classId\|null, className\|null, classToken, tabToken, description, armorType, primaryStat, secondaryStat, difficulty, powerType, secondaryPowerType, f63], perClass: {32 classNames: [specIds]}, roles: {32 classNames: [role,...]}, specialAbilities: {3 classNames: {spellId, name}}}` - owned solely by `build_classmeta.py` (Amendment D); read this file for spec/role data, never `data/classes/index.json`. `perClass`/matched-classId coverage is **32/32 as of task W4-5** (was 25/32 - the `classToken` join now falls back to `ChrClasses.filename` when the display-name join misses, see "ChrClasses filename join..." below); `classId`/`className` can still ship `null` in principle if a future client patch reintroduces a token neither join resolves | small |
| `data/classes/archetypes.json` | `{archetypes: [56 CharacterCreationArchetypes rows: id, name, tagline, description, primaryStat, weaponTypes, armorTypes, iconToken, cinematicPath, abilityPreviews, races]}` - character-creation flavor presets, class-agnostic (no classId link exists in this table) | small |
| `data/classes/essence.json` | task W4-5: `{levels: [1..80], classes: [32 rows: classId, className, curveGroup ("classlessBase"\|"hero"\|"coaCustom"), abilityEssence: [80 ints], talentEssence: [80 ints]]}` (`CharacterAdvancementEssence.dbc`, 5,600 rows = 80 levels x 32 classes x 8 flag-variant rows, canonical curve = the flags-all-zero row per (classId,level) pair) - owned solely by `tools/build_essence.py`, a **new module deliberately separate from `build_classmeta.py`** (Amendment D: classmeta owns specs.json/archetypes.json only); see "Per-class Ability/Talent Essence curves..." below | small |
| `data/spells/charges.json` | standalone `SpellCharges`/`SpellChargesCategory` curation (400 charge rows / 105 categories) - **NOT attached** to any `spells.jsonl` record (join-rate 0.885 < the 0.90 attach bar, see Honest limits); `{categories: {<categoryId>: {id, raw:[f1,f2]}}, charges: [{ref, categoryId, resolvedSpellName\|null}]}` | small |
| `data/mythic/challenges/index.json` | one compact record per Mythic+ Challenge: `{id, name, file, difficultyToken, modeToken, featured}` (297 challenges) | small |
| `data/mythic/challenges/<id>-<slug>.json` | one challenge incl. `groups`/`levels`/`rules`/`modifiers`/`conditions`/`requirements`/`rewards`/`spells` (one-record-per-line `sharding.dump_manifest` format - the default "Adventure Mode" challenge alone aggregates ~2,000 rows across those lists) | small-medium |
| `data/mythic/challenges/_lookups.json` | `ChallengeRuleTypes`/`ModifierTypes`/`ConditionTypes`/`RequirementTypes` lookup tables (127/8/18/22 rows) | small |
| `data/mythic/challenges/_meta.json` | per-link-table `challengeId` join rates, the Challenge-7 "Nudist" golden, `conditionsFinding` | small |
| `data/mythic/keystones/index.json` + `<dungeonId>-<slug>.json` | `MythicKeystones` levels grouped per dungeon (66 resolved dungeons; `dungeonId` is the same id space as `data/dungeons/index.json`'s `id` - both key off `LFGDungeons.dbc`) | small |
| `data/mythic/keystones/_unresolved.json` | 101 `MythicKeystones` rows whose `dungeonId` doesn't resolve against `LFGDungeons.dbc` (raw, documented; overall join rate 0.9851) | small |
| `data/mythic/affixes/affixes-<id//5000*5000>.jsonl` + `index.json` | 13409 `MythicAffixes` rows; affix identity is `grantSpellId`/`effectSpells` (resolved spell names) - the brief's `ChallengeModifierTypes` name hypothesis was tested and disproven, see `tools/dbc.py` | small-medium |
| `data/mythic/scaling.json` / `timedDungeons.json` / `mapDifficulty.json` | small standalone Mythic+ tables: `MythicPlusScaling` (200 rows), `TimedDungeons` (82 rows, `dungeonName` resolved), `MapDifficulty` (685 rows, `mapName`/`lockoutMessage` resolved) | small |
| `raw/interface/_manifest.json` | every extracted Interface file: sorted relative path -> `{source, size, sha256}` (1553 files: 1444 archive-sourced + 109 disk-sourced, per the 2026-07-23 capture) | small |
| `raw/interface/AddOns/APIDocumentation/**` | Ascension's own API-documentation addon, copied **verbatim from the live client install** (disk copy, not an archive snapshot - it always wins any path collision against an archive-extracted file) - **their real API**, the ground-truth reference for porting agents; see "Interface/API code layer" below | large |
| `raw/interface/{AddOns,FrameXML,GlueXML,SharedXML,LibraryXML,LCDXML}/**` | every other `.lua`/`.xml`/`.toc`/`.txt`/`.md` file found under the client's `Interface\` tree across every MPQ archive (art/BLPs/sounds/models excluded - this is a code layer, not an art dump); winner per file resolved by the same chain-order rule as the DBCs | large |
| `raw/dbc/*.csv.gz` | full decoded DBC dumps (every column) | large |
| `raw/content/*.json` | verbatim client sidecar JSONs | large |
| `raw/provenance.json` | source hashes, archive resolution, build stats, top-level `headerMismatches` (must be `[]` - see "Manastorm + realm overlays" below) | small |
| `data/manastorm/manastorm.json` | `Manastorm.dbc` rows (1017, one file - under the 5k-line gate as-is): `{id, mapId, mapName, difficulty, dungeonEncounterId, dungeonEncounterName, raw}` - `mapName` is a 100% join vs `Map.dbc`; `dungeonEncounterId` resolves >=95% (measured 99.51%) via a two-hop chain against `DungeonEncounter.dbc` whose own `mapID`/`difficulty` must agree with this row's (100% match, gated); `raw` is the 5 undecoded columns (f4-f8) | small |
| `data/manastorm/messages.json` | `ManastormMessages.dbc` rows (291): `{id, iconToken, title, text, raw}` - seasonal unlock-flavor strings (golden: id 1's `text` literally contains the word "Manastorm") | small |
| `data/manastorm/index.json` + `modifiers-<id//5000*5000>.jsonl` | `ManastormModifiers.dbc` bucket manifest + buckets (32768 rows, `bucketSize` 5000, 7 buckets): `{id, raw}` per row - only `id` is proven, no spellId or other FK column exists anywhere in this table | small-medium per file |
| `data/manastorm/playerGroupModifiers.json` | `ManastormPlayerGroupModifiers.dbc` rows (15): `{id, raw}` - only `id` is proven | small |
| `data/manastorm/_meta.json` | per-table `counts`, `provenColumns`, `dungeonEncounterJoinRate`, `spellIdFinding`/`areaIdFinding` (both DISPROVEN column hypotheses for `ManastormMessages`, left raw - see Honest limits) | small |
| `data/realms/<realm>/index.json` | one realm's overlay-evidence index (currently one realm on this install, `area-52`): per-table `{records, fields, mapped, baseRecords\|null, delta\|null}` (`declaredFields` key present only when that table's WDBC header disagrees with its own byte-accurate field count - see "Manastorm + realm overlays" below), plus `spellIdRange`, `newSpellCount` (realm-only Spell.dbc ids), `missingRefResolution` (id-membership evidence - **read the framing below before trusting this field**) | small |
| `data/realms/<realm>/_meta.json` | `mappedTables`/`unmappedTables` + `futureMilestone` (full realm spell/class curation - out of v3's scope, see below) | small |
| `data/realms/<realm>/overlay_diff.json` | task W4-5, `tools/diff_realm_overlay.py` (standalone CLI, `python -m tools.diff_realm_overlay <realm>`) - NOT written by `tools/build_realms.py` (a second, narrower single-writer boundary under the same `data/realms/<realm>/` dir, see "Base-vs-overlay Spell.dbc diff..." below): base-vs-overlay `Spell.dbc` diff over the CoA class spell set - `{realm, coaIdSetSize, sharedCount, differingSharedCount, differingSharedPct, damageNumberDisagreementCount, nameChangeCount, nameChanges: [...], columnDiffs: [...], totalBaseSpellCount, totalOverlaySpellCount, overlayOnlySpellCount, baseOnlySpellCount, docComparison}` | small |
| `raw/realms/<realm>/dbc/<Table>.csv.gz` | mapped realm tables (base `tools/dbc.py` `TABLE_MAPS` column map + layout guard reused as-is - zero new column proofs introduced for realm data) - named-header dump, same shape as `raw/dbc/<Table>.csv.gz` | large |
| `raw/realms/<realm>/dbc/<Table>.csv.gz` + `<Table>.colinfo.json` | unmapped realm tables (no same-named base `TABLE_MAPS` entry, or a field-count mismatch against it) - raw `f0..fN` dump + evidence sidecar, same shape as `dbc.dump_unmapped`'s base-table output | large |
| `data/gt/combatRatings.json` | `gtCombatRatings.dbc` (3200 rows = 32 RATING slots x 100 levels, rating-major not class-major - see "gt* combat-rating tables" below): `{ratings: [{index, name, curve: [99 floats, levels 1-99]}]}` - 16 of 32 rating slots pinned to a published WotLK name (`WEAPON_SKILL`/`DEFENSE`/`DODGE`/`PARRY`/`BLOCK`/`HIT_MELEE`/`HIT_RANGED`/`HIT_SPELL`/`CRIT_MELEE`/`CRIT_RANGED`/`CRIT_SPELL`/`HASTE_MELEE`/`HASTE_RANGED`/`HASTE_SPELL`/`EXPERTISE`/`ARMOR_PENETRATION`), the other 16 stay `cr<N>` (RESILIENCE explicitly checked and NOT pinned - a level-60-only value coincidence, see below) | small |
| `data/gt/classChanceCurves.json` | 8 class-major gt tables keyed by `classId` (1-32, `ChrClasses.dbc` id): `meleeCrit`/`spellCrit`/`regenMPPerSpt`/`octRegenMP`/`regenHPPerSpt`/`octRegenHP` (`{classId, className, curve: [99 floats]}`) + `meleeCritBase`/`spellCritBase` (`{classId, className, value}`, no level dimension, 32 rows each) | small |
| `data/gt/level60.json` | convenience slice: every `combatRatings` rating's + every `classChanceCurves` table's level-60 value only (curve index 59) | small |
| `data/gt/_meta.json` | `counts` per raw gt table, `ratingNames` (the full cr-index-to-name map), `provenColumns`, `goldensReproduced`, `unresolvedRatingIndices`, and the three `caveats` (`gtOCTClassCombatRatingScalar`, `clientCopyMayDifferFromServer`, `armorPenetrationAnomaly`, `level100SlotTrap`) - see "gt* combat-rating tables" below | small |

### Class tab sharding (why three levels, not one)

Most class tabs fit in one file: `data/classes/<Class>/<Tab>.json`. A handful of
Reborn* classes' biggest tabs (e.g. RebornWarlock/Destruction, 728 entries) don't -
even though Tab is the natural semantic key, one file would run 15k-18k lines. The
writer (`tools/build_classes.py:_shard_tab`) cascades three levels, each only used
if the previous one still overflows 5,000 lines:

1. **Whole tab** - `<Tab>.json`. Used for the large majority of tabs.
2. **Split by entry `Type`** - `<Tab>.<Type>.json` (`Talent`/`TalentAbility`/`Trait`/...).
   Insufficient by itself for the worst offenders: `Type == "Trait"` alone is ~95%
   of the oversized tabs' entries, so splitting Talent/TalentAbility off barely
   moves the needle on the dominant Trait bucket.
3. **Fixed `cadId` range within the Type** - `<Tab>.<Type>-<cadId//2000*2000>.json`.
   The remaining fallback, used only for the handful of `Trait` files still over
   5,000 lines after step 2. A `requiredLevel` band was also measured and rejected:
   ~40% of a typical oversized Trait bucket shares the exact same `RequiredLevel`
   (mostly 1), so no level-band width shrinks that cluster - it isn't a workable
   semantic key here. Fixed id ranges are the amendment's own sanctioned fallback
   for exactly this case (no smaller semantic key available), so this isn't a new
   mechanism, just the same `id // N * N` rule spells use, applied to `cadId`.

Every shard file, regardless of level, is self-describing (`{class, tab, type,
entries}`) and listed in `data/classes/<Class>/index.json`'s `files` array with its
`tab`/`type`/`cadIdRange`/`count`, so you can always find every piece of a class or
tab without guessing the split level.

### Empirical-mapping convention: `f<N>` means "unproven by design"

Every V2 table (creatures/quests/trainers/class metadata/spell enrichment/Mythic+) was
mapped under one binding rule: **a column gets a real name in `tools/dbc.py`'s
`TABLE_MAPS` only with golden-record proof pinned in a test or an inline comment -
otherwise it stays `f<N>` (raw signed int, column's own index)**. This is not laziness
or an unfinished pass - `f<N>` is a deliberate, permanent signal that means "this
column's meaning was investigated and not established," distinct from a column that
simply wasn't looked at yet. Concretely:

- `raw/dbc/<Table>.colinfo.json` (written by `dbc.dump_unmapped`, task V2-1) is the
  evidence trail for every unmapped table: per-column `distinct`/`min`/`max`/`pct_zero`/
  `string_likelihood` plus up to 3 decoded string samples for string-likely columns.
  This is where a future task's next hypothesis should start.
- A high raw join-rate against another table's ids is **not sufficient proof by itself**
  when the target id space is dense (e.g. `Creature.dbc`'s ids fill 1..127178 with no
  gaps) - several real hypotheses in this codebase cleared a naive 90%+ join-rate bar
  and were still wrong (Creature subname, the `DungeonEncounterExtra` creature link,
  `SpellAddon`'s f20/f21/f22, `CharacterCreationPetDetails`/`ShapeshiftDetails`'s spellId
  candidate). Every proven column in `tools/dbc.py` additionally has either a golden
  semantic check (a known name/description decodes correctly) or an overwhelming
  range/density argument (e.g. a value ceiling landing within 5 of the target table's
  real max id). Read a `TABLE_MAPS` entry's inline comment before trusting a column name
  or before re-deriving a mapping that's already been tried and disproven - the comments
  document *why*, not just *what*.
- Every dataset's own `_meta.json` (creatures/quests/trainers) or module docstring
  (classmeta/mythic/spells v2) carries the same evidence in plain prose next to the data
  it produced, so you don't have to cross-reference `tools/dbc.py` just to understand why
  a field is `null` or missing.

### Interface/API code layer

`raw/interface/` is a **committed** mirror of the client's `Interface\` directory tree -
every `.lua`/`.xml`/`.toc`/`.txt`/`.md` file from every MPQ archive (chain-order winner
per file, same rule as the DBCs), plus Ascension's `AddOns/APIDocumentation` addon copied
verbatim from the live client install (that copy always wins - it's the launcher-managed
live version, not a possibly-stale archive snapshot). This is the only part of the
dataset that is source *code*, not extracted *data* - use it when a question is about how
the client actually implements something (a Lua function, an XML frame template, an
addon's TOC dependencies) rather than about game content.

**`raw/interface/AddOns/APIDocumentation/` is Ascension's real API** - Blizzard's/
Ascension's own machine-readable documentation of every Lua global function, event,
table and system available to addons (`Documentation/*.lua`, one file per subsystem:
`SpellDocumentation.lua`, `CombatDocumentation.lua`, `UnitDocumentation.lua`, ...). For
any porting-agent question of the form "does this API exist / what does it take / what
does it return on this client," **this is ground truth** - prefer it over assuming
retail/Classic API shape, since Ascension's client carries a mix of backported and
custom systems (see the WoW-addon-porting projects' own hard-learned lesson: assuming
unaudited retail API parity is a recurring source of live-client crashes).

- **Four realms, one account-wide CAD file.** This client serves four realms:
  "Area 52 - Free-Pick" (classless), "Bronzebeard - Warcraft Reborn" (the Reborn*
  classes), "Rexxar - Conquest of Azeroth", and "Vol'jin - Conquest of Azeroth".
  `CharacterAdvancementData.json` - the source of everything in `data/classes/` - is
  **account-wide across all four realms**, not scoped to one. Each realm ships its
  own DBC overrides separately (e.g. `Data\area-52\patch-D.MPQ` for Area 52), and
  **Bronzebeard/Reborn's spell data is not part of this client snapshot's
  `Spell.dbc`**. Consequence: Reborn-class spell references resolve as `null` in
  class files far more often than other classes (~51% of Reborn* refs) - this is a
  data-availability fact of the snapshot, not a pipeline bug. Every class file and
  `data/classes/index.json` entry carries `realmHint`
  (`"Bronzebeard - Warcraft Reborn"` / `"Area 52 - Free-Pick /shared"` /
  `"Rexxar/Vol'jin - Conquest of Azeroth"` / `null` for meta rows) and
  `unresolvedCount` so you can tell at a glance whether a class's gaps are expected
  (reborn) or worth investigating (anything else).
- **Class tags** (`data/classes/index.json`): `vanilla` (classic 9 + DK), `reborn`
  (CoA revamps of originals, e.g. RebornWarlock), `coa-custom` (Necromancer, Tinker,
  ...), `meta` (non-class rows). `classId` matches ChrClasses.dbc (the 21
  `coa-custom` classes are ids 12-32, not just 17-32 - Barbarian/WitchDoctor/
  Felsworn"DemonHunter"/WitchHunter/Stormbringer fill 12-16) - this is the id used
  by client APIs like minimap blips. As of task W4-5, `classId` is non-null for
  **21/21** `coa-custom` dirs (previously 18/21 - 3 dirs matched via a
  `ChrClasses.filename` fallback join, see "ChrClasses filename join..." below);
  `null` still means genuinely no ChrClasses row at all (only relevant to `_other`/
  meta rows now, not any real class).
- **Dispels**: `spell.dispel.name` in None/Magic/Curse/Disease/Poison/... A spell is
  a dispellable buff if it applies an aura (`effects[].effect.name == "APPLY_AURA"`)
  and `dispel.id != 0`. Dispel-CAPABLE spells have `effects[].effect.name == "DISPEL"`
  (miscValue = dispel type id it removes). Schema differs by file: in
  `data/spells/by-id/*.jsonl` `dispel` is the `{id, name}` object described above; in
  `data/classes/<Class>/<Tab>.json`, each entry's `spells[].dispel` is a plain string
  (or `null` when unresolved) - the summary view drops the numeric id.
- **Ranks**: `rankChain` groups spell ranks (`first` = rank-1 spell id). Class entries
  list the first-rank spell with the full chain inline. **Task W4-4**: the
  first-rank record also carries `rankAt60: {spellId, rank, cadLevel}` - the top
  rank obtainable at CoA's level-60 cap, NOT `ranks[-1]`/the chain's last entry (see
  "Formula closure, level-60 ranks..." below - `ranks[-1]` requires level > 60 on
  most multi-rank chains and inflates values badly through the maxLevel-clamp
  formula).
- **Tooltips**: `$` tokens (e.g. `$s1`, `$d`) are raw - server formulas are not
  evaluated. `effects[].basePoints` is the DBC convention: displayed value is
  usually `basePoints + dieSides` for fixed values. **Task W4-4**: cross-spell
  references embedded in this text (`$<id>m1`, `$?s<id>`, `@ifknown:<id>`) are now
  followed into the dataset (depth-capped at 2) - see "Formula closure..." below;
  `@s:<id>` is a spellbook cross-link, deliberately NOT followed.
- **referencedBy**: how a spell entered the set - `cad` (obtainable), `rank`,
  `talent`, `trigger` (reached via EffectTriggerSpell closure; often the actual
  buff aura behind a cast), `formula` (task W4-4: reached via a description/tooltip
  cross-spell reference, depth-capped at 2 - see "Formula closure..." below).
- **Blank name vs. null name.** A spell can be present with `name: ""` (blank but
  non-null) - this is a WIP-content signature straight from the client (e.g. 222
  Talent-rank spells ship with an empty `name_enUS` in this snapshot). That is
  different from `name: null`, which means the id was referenced somewhere but has
  no row at all in this snapshot's `Spell.dbc` (see the four-realm note above).
  Don't treat `""` as missing data - it's a real, if unfinished, spell row.
- **Talent coverage has two views - check both.** Only 12 classes have DBC
  `Talent.dbc` talent tabs (`data/talents/<ChrClass>.json`): the 10 vanilla classes
  plus Barbarian and WitchDoctor. Every other CoA custom/reborn class drives its
  talents through `CharacterAdvancementData` entries instead - iterate every file
  listed in `data/classes/<Class>/index.json`'s `files` array and look for entries
  with `type == "Talent"` or `"TalentAbility"` (or use the index's `entryCounts`
  to see the type breakdown without opening every shard). If you're asked "what
  talents does class X have" and X isn't one of the 12, `data/talents/` will have
  no file for it - that's expected; the answer lives in the class's CAD entry
  shards, not the DBC talent tree.
- **Creatures/quests/trainers are id-keyed facts, not a quest/trainer content
  browser.** `data/creatures/` gives `id`/`name` only (`subname` is always `null`,
  disproven - see Honest limits). `data/quests/` gives `id` plus 28 raw numeric columns
  and no text of any kind - there is no quest title, objective, or category name
  anywhere in this dataset (see Honest limits). `data/trainers/` gives one row per
  `NPCTrainer.dbc` entry (`spellId`/`name`/`skillLine`), not grouped by an actual
  trainer NPC - there is no trainer-identity column in the source table at all.
- **Mythic+/Challenges pack** (`data/mythic/`): `challenges/` is the CoA "Challenge
  Mode" feature (name/description/rules/modifiers/conditions/requirements/rewards/
  featured spells per challenge, not Blizzard retail Mythic+ dungeons); `keystones/`
  and `scaling.json`/`timedDungeons.json` are the separate CoA Mythic+ dungeon-scaling
  system, keyed by `LFGDungeons.dbc` ids shared with `data/dungeons/`. These are two
  related but distinct systems living under one directory - don't assume a
  `data/mythic/challenges/*` entry has anything to do with a specific dungeon unless
  its own fields say so (most don't; challenges are largely dungeon-agnostic modifiers).
- **Class specs/roles/archetypes** (`data/classes/specs.json` /`archetypes.json`,
  owned solely by `build_classmeta.py` per Amendment D - never edited by
  `build_classes.py` or present in `index.json`): coverage differs per key inside
  `specs.json` - `roles` covers all 32 `ChrClasses` (`ChrClassesRoles.dbc` has a row
  for every class), and (as of task W4-5's `ChrClasses.filename` fallback join)
  `perClass` now also covers all 32 - it used to list only 25/32 before that join
  existed, because 7 classes' `ChrSpecs.classToken` values were filename-column
  tokens (DEMONHUNTER/MONK/SONOFARUGAL/FLESHWARDEN/PROPHET/WILDWALKER/SPIRITMAGE),
  not display names, and silently missed the display-name-only join. And
  `specialAbilities` only has an entry for the 3 classes with a nonzero
  `specialAbilitySpellId` (Shaman, Bloodmage, Primalist) - absence there means
  "no special ability," not "unresolved." `archetypes.json` is character-*creation*
  flavor content (races/weapon-armor preferences/ability-preview text for the
  "Choose your Archetype" screen) - it has no `classId` link at all, it's
  class-agnostic by design.
- **Spell v2 enrichment** (`data/spells/by-id/*.jsonl`, `schemaVersion: 2` in
  `_meta.json`): records gain `tags` (alphabetical display-name list, deduplicated -
  two different `tagTypeId`s that both decode to "Priest" collapse into one entry),
  `customAttr` (10 raw u32s, no further semantics proven), `category` (bare int, only
  when `Spell.category != 0` and it resolves), `descriptionVariables` (resolved
  tooltip-math text via `spellDescriptionVariableID`), `addon` (`{raw: [...]}`, 22
  numbers), `overrideData` (`{spells: [...], raw}`) - **every one of these keys is
  omitted, not `null`, when the spell has no data for it** (check `"tags" in spell`,
  don't assume a default). `charges` is deliberately **not** one of these keys - see
  `data/spells/charges.json` above and Honest limits.

### Manastorm + realm overlays

**Manastorm** (`data/manastorm/`) is CoA's seasonal-difficulty system (patch-M):
`Manastorm.dbc` rows link a map/raid + difficulty to a `DungeonEncounter.dbc` boss
(the two-hop `mapId`/`difficulty` cross-check between the two tables is what proves
the link, not just the raw join-rate - see the `_meta.json` `provenColumns` note),
`ManastormMessages.dbc` carries the seasonal unlock-flavor text shown to players
(e.g. id 1: *"You have unlocked Iskarr Village in your next Manastorm!"*), and
`ManastormModifiers.dbc`/`ManastormPlayerGroupModifiers.dbc` are unproven-beyond-`id`
numeric tables (no spellId or other FK column exists in either, despite several
candidates tested - see `tools/dbc.py`'s `TABLE_MAPS` comments). This is a
game-content system, distinct from the realm-overlay layer below.

**Realm overlays** (`data/realms/<realm>/`, `raw/realms/<realm>/dbc/`) are a
*separate* concept: this client serves four realms (see the "Four realms, one
account-wide CAD file" note above), and each realm ships its **own** small DBC
archive set under `Data\<realm>\` on top of the shared base chain - e.g. area-52's
`Data\area-52\patch-D.MPQ`. `tools/config.discover_realms()` finds any `Data\<dir>\`
that carries its own `listarchive` file (excluding the base client's `enUS`/`Content`
dirs); **only realms actually present on THIS machine's client install are
extracted - a realm this install doesn't carry on disk is out of scope, by user
decision (2026-08-01), not a gap to fill later.** On this install that means exactly
one realm, `area-52` ("Area 52 - Free-Pick") - the other three realms named in the
four-realm note (Bronzebeard/Rexxar/Vol'jin) have no `listarchive` directory here and
so contribute nothing to `data/realms/`.

- **Chain semantics.** A realm's `listarchive` file lists that realm's own archives
  in load order; the LAST line wins on a filename collision - the identical
  later-wins rule `tools/extract_mpq.py` uses for the base chain, just scoped to one
  realm's small archive set (`tools/extract_realms.py`). A realm's DBCs are a
  server-side OVERRIDE layer that sits above the base chain by definition, but this
  pipeline never merges the two: `work/realms/<realm>/dbc/` and `work/dbc/` (and
  their `raw/` dumps) stay two fully independent layers, one archive set apiece -
  "sits above" describes the game server's own resolution order, not something this
  extractor performs.
- **Mapped vs. unmapped realm tables.** `tools/build_realms.py` dumps a realm table
  through the **same base `tools/dbc.py` `TABLE_MAPS` column map and field-count
  layout guard** as the base client's own dump, when a base map of that name exists
  AND the realm file's field count matches it exactly (`data/realms/<realm>/index.json`'s
  `mapped: true`) - zero new column proofs are introduced for realm data in v3. A
  table with no matching base map (or a field-count mismatch) dumps `dump_unmapped`-
  style instead (raw `f0..fN` + a `.colinfo.json` evidence sidecar), `mapped: false`.
  On area-52, 9 of 12 extracted tables are mapped (`Spell`, `SkillLineAbility`,
  `Talent`, `SpellCharges`, `SpellChargesCategory`, and all 4 Manastorm tables); 3 are
  unmapped (`CharacterAdvancement`, `CharacterAdvancementEssence`, `SpellRank` - none
  of the three has a same-named base `TABLE_MAPS` column proof to reuse).
- **Header-invariant parity.** `tools/dbc.py`'s `DBCFile` trusts `record_size // 4`
  for row layout (byte-accurate), never the WDBC header's own declared `FieldCount` -
  a deliberate task V3-2 change, because area-52's `CharacterAdvancement.dbc` header
  DECLARES 179 fields but its `record_size` only fits 173 (`declaredFields: 179` on
  that table's `index.json` entry, the sole disagreement across every base + realm
  table probed so far). That fix is why a lying header no longer hard-crashes the
  reader - but it also removed the base pipeline's old crash canary for a lying
  **base** header. `raw/provenance.json`'s top-level `headerMismatches` list (also at
  `["extract"]["headerMismatches"]`) restores that visibility: every one of the 77
  base `config.WANTED_DBCS` tables where declared and byte-accurate field counts
  disagree is recorded there, and `tests/test_dataset.py` gates that list at exactly
  `[]` - a future base table that starts lying about its own header fails this
  assertion loudly rather than shipping a silently-mismatched dump. Realm tables are
  NOT held to that gate - a realm-side mismatch is expected to happen again and is
  surfaced instead via the per-table `declaredFields` key described above.
- **`missingRefResolution` - what it proves and what it doesn't.** For each bucket in
  the BASE client's `data/spells/_missing_refs.json` (spell ids that base CAD/talent/
  rank chains reference but that are absent from the base, account-wide `Spell.dbc`
  snapshot), this field reports how many of those ids exist as a real row in the
  REALM's own `Spell.dbc` - **id-set membership only**, report-only, no pass/fail
  threshold. Measured on area-52: `cad_other` 181/181 (100%), `cad_reborn` 7119/7119
  (100%), `rank` 605/2812 (21.5%), `talent` 1/13 (7.7%). **Read this carefully before
  treating it as more than it is:** area-52's `Spell.dbc` is a superset that happens
  to resolve 100% of the base client's `cad_other` AND `cad_reborn` missing ids - that
  is real evidence of *where this content lives* (a realm-side snapshot carries rows
  the shared/account-wide snapshot doesn't), but it is **not proof that those spells
  are realm-appropriate for area-52** (obtainable there, balanced there, or intended
  for a character actually playing there) - only that a row with that numeric id
  exists. Area 52 is the "Free-Pick" realm (any class), so a broad `Spell.dbc` there
  is unsurprising on its own; a Reborn-class spell resolving here says nothing about
  whether it's meant to be cast by an Area-52 character, since Bronzebeard - not
  Area 52 - is that spell's actual home realm per the four-realm note above. Treat
  `missingRefResolution` as a lead for follow-up investigation, not a join you can
  build curated cross-realm data on top of as-is.
- **Out of scope, by design: no realm spell/class curation in v3.** `data/classes/`
  stays keyed off the base, account-wide `CharacterAdvancementData.json` only -
  nothing in `data/realms/` feeds into it. Turning a realm's raw overlay
  (`raw/realms/<realm>/dbc/`) into a realm-scoped equivalent of `data/classes/`
  (per-record spell enrichment, realm-specific class/spec mapping) is a **documented
  future milestone**, not implemented here - tracked in every
  `data/realms/<realm>/_meta.json`'s `futureMilestone` field, which points back to
  this section.

### gt* combat-rating tables

`data/gt/` (task W4-2, patch-M/patch-S) curates the 9 `gt*` tables whose layout this
task proved, from a fresh extraction independent of the source spec's own snapshot
(the live client patches on its own schedule). Every `gt*` DBC is a genuinely
single-column, ALL-FLOAT WDBC (`record_size == 4`) - the layout question was never
"what does the column mean" but "which row position maps to which class/rating/level":

```
idx = (classId - 1) * 100 + (level - 1)   # gtChanceToMeleeCrit / gtChanceToSpellCrit /
                                           # gtRegenMPPerSpt / gtOCTRegenMP /
                                           # gtRegenHPPerSpt / gtOCTRegenHP (class-major,
                                           # classId 1-32 is the real ChrClasses.dbc id)
idx = classId - 1                         # gtChanceToMeleeCritBase / gtChanceToSpellCritBase
                                           # (32 rows, no level dimension)
idx = cr * 100 + (level - 1)              # gtCombatRatings (RATING-major - the "class"
                                           # slot holds a rating index, not a ChrClasses id)
```

Every 100-level block's slot 99 ("level 100") holds the START of the next block's curve,
not a real level-100 value (reverified at 3 block boundaries, exact float equality) - the
**level-100-slot trap**. `data/gt/`'s curated curves are therefore levels 1-99 only (99
values), never 100. Full per-golden re-derivation evidence (13/14 exact published
level-80 combat-rating constants, the 166.67/80.00 spell-crit conversion, the
83.33/62.50/52.08 melee-crit conversion, the CoA archetype-clone table, why 16 of
`gtCombatRatings`' 32 rating slots stay unnamed `cr<N>`) lives in `tools/dbc.py`'s
`TABLE_MAPS` comment for these tables and `.superpowers/sdd/task-w4-2-report.md`.

**Three caveats, load-bearing for any consumer** (also in `data/gt/_meta.json`'s
`caveats` key, verbatim-in-spirit from DATAMINE-REQUEST.md Sec 1.1's own warnings):

1. **`gtOCTClassCombatRatingScalar` (1,024 x 2) is a different shape and NOT covered by
   this proof.** `f0` decodes as an ascending-unique row id 1-1024, indistinguishable
   from either "this table's own positional PK" or the brief's inferred TrinityCore
   `(class-1)*32 + cr + 1` convention - both produce the same 1..1024 sequence with the
   evidence available. Left **UNMAPPED** in `tools/dbc.py` (raw `f0`/`f1` +
   `colinfo.json`, same as any other unproven table) - `data/gt/` ships **no** curated
   curve for it. Needs its own golden before a future task curates it.
2. **The server may not use these values.** These are the CLIENT's copy (tooltips,
   character sheet). A TrinityCore-family server loads its own `gt*` DBC set - if CoA's
   server ships different files, the client could display one number while the server
   computes another. This pipeline cannot see server-side data (client DBCs only).
   Mitigation, not performed here: read a level-60 character's actual crit% at a known
   crit-rating value in-game and compare against `CRIT_MELEE`/`CRIT_RANGED`/
   `CRIT_SPELL`'s prediction (14.0 rating per 1% at level 60 on this snapshot).
3. **`ARMOR_PENETRATION` (gtCombatRatings rating index 24) does not match published
   WotLK.** This table gives 11.55 at level 80 where the canonical constant is 15.39
   (4.20 at level 60). Every other pinned rating matches its published constant to 4dp,
   so this is a real behavioral difference, not a layout artifact - `[INFERRED]` an
   Ascension rebalance or a pre-3.3.3 WotLK revision. The row's *identity* (which `cr`
   slot is ARMOR_PENETRATION) is certain; only the *value* is anomalous.

`RESILIENCE` (DATAMINE-REQUEST.md Sec 1.1's level-60 table lists 85.00) was explicitly
checked and **not** pinned: `cr14`'s level-60 value is exactly 85.0, but `cr14`/`15`/`16`
form their own 3-slot group structurally consistent with `CRIT_TAKEN_MELEE/RANGED/SPELL`,
and no independent published level-70/80 anchor exists to tell a single-level coincidence
apart from a real identity - the same class of false positive this file warns about
elsewhere (Creature.subname, DungeonEncounterExtra, SpellAddon f20-22). Left unnamed
`cr14` in `data/gt/combatRatings.json`; the full reasoning is in `_meta.json`'s
`unresolvedRatingIndices`.

`gtNPCManaCostScaler.dbc` (100x1) is extracted (`config.WANTED_DBCS_V4`) per the source
spec's "may be worth taking" note, but has no class dimension and no curated output in
`data/gt/` - this task only extracted it for a future task to pick up (left UNMAPPED,
raw + colinfo, same as `gtOCTClassCombatRatingScalar`).

### Spell column completion (task W4-3) - damage-modeling columns

`coa-sim-handoff/DATAMINE-REQUEST.md` Sec 1.2-1.4 identified the single biggest
blocker to a DPS simulator built on this dataset: columns this pipeline already
extracts from `Spell.dbc` but drops before `build_spells._record` writes a row.
Every fill-rate/golden claim below was **independently re-derived** against
`work/dbc/Spell.dbc` (not copied from the source doc) over the **"CoA class set"**
(`build_spells._coa_class_spell_ids()`): every spell id, including every rank-chain
id, referenced by the 21 `coa-custom`-tagged classes in `data/classes/`, intersected
with live `Spell.dbc` ids. This set reproduces the doc's own headline counts
**exactly** - 6,436 total ids / 6,038 resolved in base `Spell.dbc` (matches Sec 3's
"base resolves 6,038/6,436" verbatim) - which is why the per-column percentages below
also land on or within ~0.4pp of the doc's cited figures; see
`.superpowers/sdd/task-w4-3-report.md` for the full per-column log.

**`EffectRealPointsPerLevel` (f77-79, `effects[].realPointsPerLevel`) - the highest-
value single addition.** Backing store for the `$ppl` formula token. Re-derived
CoA-set fill: **2,012/6,038 = 33.3223%**, an exact match (same numerator and
denominator) to the doc's own 2,012/6,038 = 33.32%. (The doc separately claims this
is present on 61.1% of *build-reachable, level-60-rank-selected* damaging/healing
slots - a narrower population this task did not re-derive; not repeated here as a
re-derived fact.) **IEEE-754 float bit patterns, not integers** (Sec 1.5 trap 3) -
decode via `struct.unpack('<f', struct.pack('<i', v))`, same as f216-218/f229-231.
Golden: stock Frostbolt (116) slot 2 `f78 = 1056964608 = 0x3F000000 = 0.5f`.

> **The `maxLevel` clamp - per-level is a *value* channel, not a gear-scaling
> channel.** `realPointsPerLevel` determines the base number at a given level; it
> never varies with gear, and **85.2% of the 2,012 CoA spells with a nonzero rppl
> are capped below level 80** (`maxLevel` < 80) - so at CoA's level-60 cap, most of
> these terms are either fully live, partially live, or entirely frozen, never
> "ramping past the cap." The applicable formula:
>
> ```
> value = basePoints + dieSides + (clamp(60, baseLevel, maxLevel) - spellLevel) * realPointsPerLevel
> ```
>
> **`maxLevel == 0` is the DBC "uncapped" sentinel, not a literal level-0 clamp
> target.** Re-derived directly against `work/dbc/Spell.dbc`: **138 of the 2,012
> nonzero-rppl CoA spells (6.86%) carry `maxLevel == 0`** (e.g. Hellish Rebuke
> 300391, Slagforged Armor 300931, Conductive 500005). A literal reading of
> `clamp(60, baseLevel, maxLevel)` with `maxLevel = 0` clamps toward 0, which is
> wrong - these spells are uncapped, not capped at level 0. **The correct rule:
> when `maxLevel == 0`, treat it as "no cap" and use `min(60, ...)` against 60
> directly (i.e. drop the upper bound from the clamp, not set it to 0)** - these 138
> spells are already correctly excluded from the 85.2%-capped-below-80 figure above
> (that figure only counts spells where `0 < maxLevel < 80`), so no other number in
> this section needs revising; this is a documentation-only correction for anyone
> implementing the clamp formula themselves.
>
> `maxLevel` is already emitted as `levels.max`, `baseLevel` as `levels.base`,
> `spellLevel` as `levels.spell` - nothing in this dataset applies the clamp for you;
> a naive consumer that lets `realPointsPerLevel` scale past a spell's own `maxLevel`
> (or mishandles the `maxLevel == 0` sentinel above) silently inflates or deflates its
> value. Frozen-rppl examples re-verified directly against `work/dbc/Spell.dbc` and
> pinned as goldens in `tests/test_spells_columns.py`: Chronomancer *Decomposition*
> (800856, bp 12, rppl 0.11, maxLevel 12) and Necromancer *Ray of Rot* (804535, bp
> 11, rppl 0.47, maxLevel 26).

**`EffectSpellClassMask` (f122-130, `effects[].spellClassMask: [a,b,c]`) - which
spells a talent modifies.** Three u32 words (a 96-bit mask) per effect slot, omitted
entirely when all three are zero. Re-derived CoA-set fill (any slot nonzero):
**1,728/6,038 = 28.6187%**, matching the doc's "28.62% overall" exactly. Golden:
stock talent Improved Fireball (11069) slot 1's `ADD_FLAT_MODIFIER` aura carries
`spellClassMask: [1, 0, 0]`; stock Fireball (133, same `spellFamilyName` 3 = Mage)
carries `spellFamilyFlags1 = 1` - bit 0 set on both, the exact selection mechanism
the doc describes.

**`SpellFamilyFlags3` (f211, `family.flags3`)** - the curated table previously
exposed only `flags1`/`flags2`, silently truncating the 96-bit family mask's top 32
bits. Re-derived fill 730/6,038 = 12.0901%, matching the doc's 12.09%.

**`EquippedItemSubClassMask`/`EquippedItemInventoryTypeMask` (f69/f70,
`equippedItem.subClassMask`/`.inventoryTypeMask`)** - adjacent to the already-mapped
`equippedItemClass` (f68, now also emitted as `equippedItem.itemClass`; its `-1`
"any weapon" sentinel histogram re-derived exactly: `-1` x5547, `2` x461, `4` x30 on
the CoA class set). Re-derived fill: f69 734/6,038 = 12.1563% (doc 12.16%), f70
87/6,038 = 1.4409% (doc 1.44%).

**`EffectPointsPerComboPoint` (f119-121, `effects[].pointsPerComboPoint`)** - combo-
point scaling (Ranger has combo points). Re-derived fill 20/6,038 = 0.3312%, matching
the doc's 0.33%. Golden: Rage of Bethekk (501229) slot 1, a real `SCHOOL_DAMAGE`
effect, carries `pointsPerComboPoint: 8.0`. **Trap encountered while picking this
golden:** Serrated Shot (500073) slot 2 carries a nonzero raw `f120` word too, but
that slot's `effect` field is 0 (no real effect there) - a dead-slot artifact, same
class as the aura-byte trap documented in `tools/enums335.py`'s evidence sidecar.
This repo's pre-existing per-slot convention (`if not eff: continue` in
`build_spells._record`, unchanged by this task) already drops that slot's data
entirely, so the dead value never reaches the output.

**`EffectDamageMultiplier` (f216-218, `effects[].damageMultiplier`)** - chain-damage
falloff per jump. Re-derived (gated on populated-effect slots, `!= 1.0f` default):
507/6,038 = 8.3968%, within 0.4pp of the doc's "8.00% non-default" (methodology-
sensitive - a literal `!= 0` raw-value test over-counts empty slots, whose raw field
is `0`, not the in-game default `1.0`).

**`spellMissileID` (f227, `missileId`)** - pairs with the (out-of-scope)
`SpellMissile.dbc` ask. Re-derived: exactly 8/6,038 = 0.1325% nonzero, matching the
doc's "0.13% (8 spells)" down to the literal count - all 8 are Invigorating Surge
ranks sharing missile 9429.

> ### ⚠ `EffectBonusMultiplier` (f229-231, `effects[].bonusMultiplierStock`) -
> **do NOT treat as a CoA coefficient source**
>
> Extracted and emitted (correct for **stock and Reborn content only**), but it is
> the **untouched Blizzard-2008 column** and **contradicts** CoA's own tooltip-
> authored formulas on the same effect slot far more often than it agrees. Re-
> derived CoA-set fill: 619/6,038 = 10.2517% (doc 10.25%). Golden: Flash Heal (2061)
> `f229 = 1062115213 = 0.8069999814... ~ 0.807` (the genuine WotLK value), while its
> `description` reads `${$m1+$BH*0.158964+$AP*0.072}` - an AP-on-heal hybrid term
> that does not exist in stock 3.3.5a.
>
> **Agreement, re-derived this task** (rough regex-based coefficient extraction from
> `description`/`tooltip` text, 5% tolerance, effect slots carrying both a nonzero
> `f229-231` and a parsed stat coefficient): **stock 0/65 agree (0.0%)**, **CoA
> 7/113 = 6.2% agree** - both land on the doc's own conclusion (stock 0/37 = 0.0%,
> CoA 4/63 = 6.3%) even though the exact counts differ (different snapshot, cruder
> parser): **near-zero agreement either way.** Re-runnable:
> `python -m analysis.w4_3_bonus_multiplier_agreement` (`analysis/`, repo root) -
> not hardcoded here, prints these same two lines fresh against `work/dbc/Spell.dbc`.
> A consumer that unions
> `bonusMultiplierStock` with the tooltip-parsed coefficient will silently produce
> plausible-looking wrong numbers instead of a visible gap - the tooltip formula
> (`description`/`tooltip`, preserved verbatim, never normalized) is CoA's *only*
> real coefficient channel; see Sec 2's classless-vs-CoA `bonus_data` schema finding
> for why (CoA ships zero rows in TrinityCore's `spell_bonus_data` schema; its i18n
> table still carries the "Spell coefficient" labels from a system it never wired up).

**Sec 1.3's 8 already-mapped-but-dropped columns** (`speed`, `equippedItem.itemClass`,
`maxAffectedTargets`, `casterAuraSpell`/`targetAuraSpell`, `manaPerSecond`,
`targetCreatureType`, `casterAuraState`/`targetAuraState`, `stancesNot`) needed zero
new column proofs - they were already named in `TABLE_MAPS["Spell"]`, just never
read by `_record`. Re-derived fill rates (all within the doc's cited figures, see
`.superpowers/sdd/task-w4-3-report.md`): speed 10.90%, maxAffectedTargets 11.97%,
casterAuraSpell/targetAuraSpell 10.33%, manaPerSecond 0.33%. Golden: Divine Storm
(53385) `maxAffectedTargets = 4`, the real WotLK 4-target cap.

**Confirmed zero-fill skip list re-verified before skipping** (Sec 1.4): f207
`maxTargetLevel`, f43 `manaCostPerLevel`, f18 `RequiresSpellFocus`, f228
`PowerDisplayId`, f224 `AreaGroupId`, f233 `spellDifficultyID` - all **0/6,038**
nonzero on the CoA class set, re-verified directly against `work/dbc/Spell.dbc`
before being left unmapped (f18/f224/f228) or mapped-but-unemitted (f207/f43/f233,
already-named columns kept in `TABLE_MAPS` for `raw/dbc/Spell.csv.gz`'s full dump but
excluded from `spells.jsonl` and flagged as such in `_coverage.json`).

**Omit-when-zero convention for the 5 new per-effect fields** (`realPointsPerLevel`/
`pointsPerComboPoint`/`spellClassMask`/`damageMultiplier`/`bonusMultiplierStock`):
each is added to an effect's dict **only when its raw DBC word is nonzero**, unlike
`basePoints`/`dieSides`/etc. above them (always present once a slot's `effect` is
nonzero, since 0 is itself a meaningful value there). This matters most for
`damageMultiplier`/`bonusMultiplierStock`, whose true "no data here" DBC sentinel is
a literal `0.0` float bit pattern - distinct from their in-game default of `1.0`
(`0x3F800000`), which - when actually authored - is kept and emitted, not treated as
absent. The 11 spell-level columns (`speed` through `missileId` above) stay
unconditional, matching this record's pre-existing top-level convention
(`manaCost`/`procChance`/etc. are never omitted at 0 either) - they're single
scalars per spell, not 3x-duplicated per effect slot, so there's no null-noise
concern from keeping them always-present.

### Formula closure, level-60 ranks, $scalingbp, devDead (task W4-4)

`coa-sim-handoff/DATAMINE-REQUEST.md` Sec 1.6-1.8 + Sec 4 trap 17. Closes the
curation graph over description/tooltip cross-spell references, adds a level-60
rank-selection convenience field, surfaces CoA's global level-normalising constant,
and flags dev-dead content. See `.superpowers/sdd/task-w4-4-report.md` for the full
re-derivation log.

**(a) Formula-reference closure.** The pre-existing closure (`cad`/`rank`/`talent`
sources, then a transitive `trigger` closure over `EffectTriggerSpell`) never
followed spell ids embedded in `description`/`tooltip` **text** - and CoA authors
its damage scaling there (Sec 2), heavily cross-referencing other spells
(`${$573020m1*$<scalingbp>+...}` on Crusader's Brand). This task adds a third,
**depth-capped-at-2** closure pass over three followed forms:

- `$<id><letter(s)><n>` - e.g. `$573020m1`, `$7376S1`, and (found while
  re-deriving the doc's own grammar against `work/dbc/Spell.dbc` - the doc states
  a single-letter shape, but that undercounted the doc's own depth-1/depth-2 yield
  by roughly a third) **multi-letter tokens** like `$80313ppl1`/`$202137PPL1`
  (a cross-spell `EffectRealPointsPerLevel` reference) and **no-trailing-digit**
  tokens like `$6788d` (another spell's duration) or `$49188h` (another spell's
  proc chance). `tools/build_spells.py`'s `FORMULA_XREF_STRICT_RE`/
  `FORMULA_XREF_WIDE_RE` docstrings have the full grammar-widening writeup,
  including the false-positive traps that were deliberately **not** chased
  (`$1%`/`$2%` are literal percentages, not spell ids - a size-based heuristic to
  tell them apart from real refs would be exactly this repo's own "dense-id
  join-rate lies" trap) and one that WAS caught by review and fixed:

  > **⚠ The `$1s` transposition-typo trap.** The no-trailing-digit widened shape
  > collides with a different real authoring artifact - a same-spell `$s1`/`$m1`
  > self-value token, TRANSPOSED by a tooltip typo into `$1s`/`$1m` (digit-then-
  > letter instead of letter-then-digit). Rejuvenation (28722) reads `"Restores
  > $s1 mana.\n$1s mana restored."` twice in the same tooltip - once correct,
  > once transposed - and misparses as "a reference to spell id 1" (the "UPDATE
  > YOUR CLIENT!" placeholder row). **Confirmed on 28 spells** sharing this exact
  > template (Rejuvenation/Surging Mana/Nature's Bounty/Adrenaline Rush/Healing
  > Touch/Lesser Healing Wave/Consume Essence/Consume Life/Elune's Touch/
  > Revitalize/Infusion/Efficiency/Soul of the Dead, across their rank chains).
  > Harmless in the current snapshot only because id 1 (and the similar
  > self-referencing `$10d`/`$66d` cases - Blizzard and Invisibility citing their
  > own id instead of the bare `$d` token) were already closure-reachable before
  > this widening ran - luck, not design. **Fixed by splitting the grammar**: the
  > doc's literal single-letter-mandatory-trailing-digit shape (`FORMULA_XREF_
  > STRICT_RE`) stays completely unrestricted - a transposed `$s1` can never
  > produce a trailing digit, so this shape structurally cannot collide, and it's
  > proven safe down to 2-digit ids (Vindication 67's `$67s1`, a genuine external
  > cross-ref). The remaining widened forms (`FORMULA_XREF_WIDE_RE`: multi-letter
  > tokens, no-trailing-digit tokens, the `/N;` infix) additionally require the
  > candidate id to have **>=3 digits** - every legitimate cross-ref this widened
  > grammar actually resolves in this dataset is 3+ digits; the transposition-typo
  > class is always the same 1-2 digit number that was meant to be the token's own
  > rank/effect suffix. Re-measured after the fix: closure delta unchanged (1,476
  > new records - the filtered ids were all either already-reachable self-refs or
  > unresolvable garbage, never a genuinely new record). Canaried in
  > `tests/test_closure_ranks.py`: no id < 1000 may appear among formula-only-
  > tagged records.
- `$?<letter(s)><id>` - the doc cites `$?s<id>`; re-derivation found the same
  conditional-reference construct also spelled `$?a<id>`/`$?S<id>`/`$?j<id>`, so
  the letter is generalized rather than hardcoded to `s`.
- `@ifknown:<id>`.

**`@s:<id>` is deliberately NOT followed** - the doc proved it is a spellbook
cross-link, not a formula channel (following it changed zero coverage buckets in
the source audit). Structurally re-verified here too: none of the three followed
regexes above can ever match an `@s:` token (they require a literal `$` or
`@ifknown:`, never a bare `@s:`) - pinned in `tests/test_closure_ranks.py`.

New records are tagged `referencedBy: ["formula"]`; an id already reachable by
another path (e.g. `573020` above is also reachable via `trigger`) does **not**
get a retroactive `formula` tag - the tag reflects how a record was **first**
reached, unchanged from the pre-existing `cad`/`rank`/`talent`/`trigger` convention.

**Re-derived closure delta**: depth 1 +1,433 / depth 2 +43 = **1,476 new records**
(27,475 -> 28,951), within this task's own **+/-20% gate** of the doc's cited
+1,843 (depth1 1,753 + depth2 87 + depth3 3, capped at depth 2). The remaining gap
is expected, not a bug: this closure runs over the **full current dataset** (stock
3.3.5a + CoA + rank + talent + trigger, ~27,475 records), a superset of the doc's
own narrower "CoA set" measurement population - the same "our closure is a
superset, exact reproduction isn't the goal" pattern seen throughout this project
(see task W4-3's fill-rate re-derivations for the earlier instances). A would-be
depth 3 was measured (not applied): **+3 new records** - an exact match to the
doc's own cited depth-3 marginal yield, a reassuring cross-check that the widened
grammar above is finding the intended reference set. Full breakdown in
`data/spells/_meta.json`'s `formulaClosure` block.

> **⚠ The doc's own resolution-rate figure (2,446/5,317 = 46%) does not reproduce
> here** (this build measures 4,895/5,077 = 96.4% resolved). Population-independent
> in principle (an id either exists in `Spell.dbc` or it doesn't), so this is most
> likely explained by client content churn between when the doc was authored and
> this snapshot - CoA's dev/test spell ids (the `500000+`/`800000+`/`900000+`/
> `1000000+`+ series that dominate these references) have been observed growing
> steadily across this repo's rebuild history (see "Regenerating after a client
> patch" below). Flagged rather than chased further - re-deriving a stale doc
> figure against a newer live snapshot is expected to diverge.

> **⚠ The binder must follow `$mN`/`$sN`-style tokens into ANY effect slot, not
> only damaging ones** (Sec 1.6) - this closure widens which SPELLS are in the
> dataset, but a future consumer building a coefficient binder (matching a
> formula's `$mN`/`$sN` tokens to the effect slot that actually carries the
> matching `basePoints`) must not assume the match sits on a damaging slot. CoA
> frequently binds a coefficient to a non-damaging slot used purely as a scaling
> handle - Barbarian *Gutspiller* (805832) carries `$RAP*0.4` on slot 2 (aura 227,
> a modifier), while slot 1 holds the actual bleed; *Dawnfall* carries `$SP*0.12`
> on slot 2 (aura 23, `PERIODIC_TRIGGER_SPELL`). A naive per-slot binder that only
> checks damaging slots reports these as unscaled holes when the coefficient is
> right there on an adjacent slot. This dataset does not build that binder (out of
> scope - "the sim writes the evaluator," Sec 2); it is documented here so nobody
> re-discovers it the hard way.

**(b) `rankAt60` - level-60 rank selection.** `ranks[].level`/`.spellId` are
already exposed per rank inside `data/classes/<Class>/*.json` (`chains` in
`build_classes.py`, unchanged by this task). This task adds a **convenience field
on the `spells.jsonl` side**: `rankAt60: {spellId, rank, cadLevel}` on the chain's
own first-rank record (`rankChain.first == id`) - the highest rank whose CAD level
(`SpellRankData.json`'s own `level` field) is `<= 60`. Omitted entirely (no
null-noise) for the 47 chains (of 2,130 total) where even rank 1 requires CAD
level > 60 - stock 61-80 content with no level-60-reachable rank at all.

**Why this matters**: `ranks[-1]` (global top) requires level > 60 on the large
majority of multi-rank CoA chains and, applied through the `maxLevel`-clamp
formula above, inflates a spell's value by a **median 1.54x, max 6.61x** (Sec
1.7). Worst-case golden, re-derived: Runemaster *Spellsling* chain (head id
802202) - global top is rank 12 (spellId 502838, `levels: {base:80, spell:80,
max:80}`) which clamps to **value 3,365**; `rankAt60` correctly selects rank 9
(spellId 502835, `levels: {base:68, spell:68, max:72}`, `cadLevel: 54`) which
clamps to **value 509** - the doc's own cited 3,365-vs-509 pair, re-derived here
independently via the maxLevel-clamp formula from this record's own emitted
fields, not copied. Pinned in `tests/test_closure_ranks.py`.

> **⚠ [INFERRED] gating field - UNRESOLVED, needs an in-game `/dump`.** CAD
> `ranks[].level` and DBC `spellLevel` agree on only **32.0%** of rank rows and
> pick a **different** level-60 rank on **512 of 920** CoA chains (Sec 1.7). This
> field follows **CAD level**, on the doc's own reasoning that CAD is what grants
> a rank on Ascension - not independently verified by this task, and DBC
> `spellLevel` runs systematically higher (mean +3.03), which would pick an even
> lower rank on the disagreeing chains. **A consumer needs the actual in-game
> gating behavior confirmed (does the character's obtainable rank follow the CAD
> entry's level or `Spell.dbc`'s own `spellLevel`?) before trusting `rankAt60` for
> anything beyond the "roughly which rank" level** - this is a real, load-bearing
> unresolved question for absolute damage values on ~55% of multi-rank chains, not
> a hedge. Track this the same way as the §14 in-game probe items already noted
> elsewhere in this guide.

**(c) `$scalingbp` - named constant.** `data/spells/_meta.json`'s
`scalingConstants.scalingbp` block (`SpellDescriptionVariables.dbc` row id 182,
referenced by **550** spells via the literal `$<scalingbp>` token - both figures
re-derived fresh against `work/dbc`, matching the doc's cited 550 exactly).
Coefficients are **parsed out of the live SDV row text** at build time (not
hardcoded), so a client patch that changes them fails the build's own `assert`
instead of silently drifting. Re-derived value table matches the doc's cited
breakpoints exactly: `0.0318@1, 0.1982@20, 0.5184@40, 0.8562@55, 0.9874@60,
1.0148@61, 1.2777@70, 1.6052@80`.

> **Framing: a level normaliser, NOT a stat coefficient.** It crosses 1.0 at
> `$PL ~= 60.46` and sits at **0.9874 at CoA's level-60 cap** - independent
> quantitative confirmation the content is authored at a 60 cap. A consumer
> multiplies a spell's `basePoints` by this value when that spell's formula text
> references `$<scalingbp>`; it carries no gear/stat scaling of its own and should
> never be described as "the CoA scaling curve."

**(d) `devDead` flag.** Set on any record whose `description`/`tooltip` carries
the literal marker text `"DOES NOT WORK, YOU SHOULD NOT HAVE IT"` (Sec 4 trap 17).
**Not** a loose `"does not work"` substring match - that false-positives on
ordinary tooltip caveats (Pyromancer *Pyrolate*'s "Does not work with Elemental
Destr[uction]" is real game text, not dev-dead content; found while deriving this
flag). Re-derived by scanning every `Spell.dbc` row (not just the build-reachable
set): **exactly 7 records**, all one rank chain - Pyromancer *Flame Swell*,
spellIds 502065-502071. The doc's own cited count ("Three such slots") measures a
different, narrower unit (build-reachable, level-60-rank-selected **damaging
effect slots**, not spell records) and is not directly comparable to this
per-record flag - this task's count is independently re-derived and re-verified in
`tests/test_closure_ranks.py`, not copied from the doc.

### Per-class Ability/Talent Essence curves, ChrClasses filename join, realm-overlay diff tooling (task W4-5)

`coa-sim-handoff/DATAMINE-REQUEST.md` Sec 7 (essence + `ChrClassesRoles` goldens),
Sec 11 (`specs.json` inconsistency / the filename fix), Sec 3 (the realm-overlay
dispute numbers), Sec 4 trap 6, Sec 13 items 9+12+7(prep).

**(a) `CharacterAdvancementEssence` -> `data/classes/essence.json`.** Golden-proven
directly against `work/dbc/CharacterAdvancementEssence.dbc` (not copied from the
doc): f1=level (1-80), f2=classId (1-32), f7=Ability Essence, f8=Talent Essence.
Re-derived goldens, all exact: classless classId 1-9/11 (the 10 non-Hero
"classless" ids) @ level 60 = (60, 51) - "the classic 51-talent-point number";
Hero (classId 10) @ level 60 = (100, 51); all 21 CoA-custom classes (classId
12-32) share ONE identical curve (L10 (1,0) -> L20 (6,5) -> L30 (11,10) -> L40
(16,15) -> L50 (21,20) -> L60 (26,25) -> L70 (31,30) -> L80 (36,35)). f3-f6 are 4
unmapped per-row flag columns (8 combos observed) - for every class except Hero,
every flag combo at a given (classId, level) carries the IDENTICAL AE/TE pair, so
the flags are immaterial; Hero (unmatched to any CAD class - see
`unmatchedChrClasses` below) is the sole exception, carrying up to 8 DIFFERENT
AE/TE pairs per level across its combos (e.g. level 60 also reads
(100,71)/(60,25)/(44,51) under other combos) - an inert, unresolved finding since
Hero isn't a playable CoA class in this snapshot. `tools/build_essence.py` always
selects the flags-(0,0,0,0) row, present exactly once per (classId, level) pair
(2,560/2,560 = 32 x 80, verified) and the row that reproduces every doc golden.

> **Amendment D note.** `essence.json` is class-*adjacent* data, not class/spec/
> archetype metadata - `build_classmeta.py`'s own docstring states it owns
> `specs.json`/`archetypes.json` **only**. Rather than silently widening that
> module's scope, this task added a **new**, single-purpose module,
> `tools/build_essence.py`, wired into `tools/build_dataset.py`'s orchestrator
> right after the classmeta stage. It only reads `work/dbc` (ChrClasses +
> CharacterAdvancementEssence) - no dependency on `data/classes/` existing.

**(b) `ChrClasses.filename` join - the fix for Sec 4 trap 6.** `ChrClasses.dbc`
carries a second name column, `filename` (f55, already a `TABLE_MAPS` entry before
this task but never wired through anywhere) - an internal uppercase token,
DISTINCT from `name_enUS` (the display name). Three CoA class directories
(DemonHunter/Monk/SonOfArugal) have no ChrClasses row matching their display name
at all, because their real ChrClasses row uses a DIFFERENT display name whose
`filename` equals the CAD class name instead: id14 name_enUS="Felsworn"
filename="DEMONHUNTER", id19 "Templar"->"MONK", id20 "Bloodmage"->"SONOFARUGAL" -
golden-proven directly against `work/dbc/ChrClasses.dbc`, exact match to the doc's
cited mapping. **Doubly cross-checked** against the client's OWN
`raw/interface/FrameXML/Data/CharacterAdvancement.lua` `ClassRemap` table (applied
to every `CharacterAdvancementData` entry at load time, `data.Class =
ClassRemap[data.Class]`): every one of its ~32 CAD-name -> token pairs equals this
column's value for the matched row, including the 4 cases where the token isn't a
trivial uppercase of the display name (Runemaster->SPIRITMAGE,
Primalist->WILDWALKER, Venomancer->PROPHET, "Knight of Xoroth"->FLESHWARDEN) -
these 4 already had a working classId (matched by display name, since their CAD
name IS a ChrClasses display name), so the alias is purely informational and
surfaces as `data/classes/<Class>/index.json` / the top-level `classes[]` entry's
`aliases` field. **Content sanity check** (not just id/string matching): the
DemonHunter CAD dir's own tab names (Class/Demonology/Felblood/Slaying) match
`ChrSpecs` rows whose `classToken=="DEMONHUNTER"` tab-for-tab
(FELBLOOD/SLAYING/DEMONOLOGY) - real content agreement, confirming the DemonHunter
dir genuinely IS Felsworn's data, not a coincidental string join (same check holds
for Monk/Templar and SonOfArugal/Bloodmage).

Both `tools/build_classes.py` (CAD class name -> `ChrClasses` row) and
`tools/build_classmeta.py` (`ChrSpecs.classToken` -> `ChrClasses` row) now try the
display-name join first, falling back to the filename join only on a miss.
Results: **21/21 `coa-custom`-tagged class directories now have a non-null
`classId`** (was 18/21); `data/classes/index.json`'s `unmatchedChrClasses` shrank
from `[Bloodmage, Felsworn, Hero, Templar]` to `[Hero]` (the only ChrClasses row
with genuinely no matching CAD class - Hero is unreleased content); `specs.json`'s
`ChrClasses` coverage went from **25/32 to 32/32** - all 24 previously-unmatched
`ChrSpecs.classToken` values (DEMONHUNTER x3, MONK x3, SONOFARUGAL x4, FLESHWARDEN
x3, PROPHET x4, WILDWALKER x4, SPIRITMAGE x3) turned out to be filename-column
tokens, not display names. This closes the join-level half of Sec 11's "specs.json
is inconsistent... no classId-linked rows for Knight of Xoroth/Venomancer/
Primalist/Runemaster/DemonHunter/Monk/SonOfArugal" finding - the deeper
spec-NAMING disagreement that section also describes (specs.json's own spec names
disagreeing with the CAD tab layer, e.g. Chronomancer Time/Infinite/Artificer vs.
tabs Time/Displacement/Duality) is Sec 13 item 20, explicitly out of this task's
scope and deliberately untouched.

**(c) `ChrClassesRoles` roster cross-check (Sec 7).** This task re-derived the
doc's own published role roster (Pure DPS / Tank+DPS / Healer+DPS /
Tank+Healer+DPS, 31 named classes) against `specs.json`'s `roles` field - unchanged
V2-3 code, `ChrClassesRoles.roleMask` decoded directly. **Full agreement, 0
mismatches** - the only ChrClasses row the doc's roster doesn't cover is Hero
(same unreleased/unmatched class as above), not a disagreement. Per this task's
binding rule ("change nothing if they agree"), `build_classmeta.py`'s role logic
is untouched - this is a verification pass, documented as a golden set in
`tests/test_class_plumbing.py` rather than a code change.

**(d) Base-vs-overlay `Spell.dbc` diff tooling.** `tools/diff_realm_overlay.py`
(CLI: `python -m tools.diff_realm_overlay <realm>`) reproduces Sec 3's dispute
measurement - the finding that area-52's realm overlay and the base client chain
disagree on a real fraction of the shared CoA spell set, not just cosmetically.
Scope: "shared CoA rows" = `build_spells._coa_class_spell_ids()` (the same
6,436-id CoA class-spell universe task W4-3 defined) present in BOTH the base
client's `Spell.dbc` and the realm's own `Spell.dbc`. Run against area-52 (today's
only extracted realm) and re-derives Sec 3's own cited numbers closely (**not**
copied, measured fresh against this snapshot - some drift is expected and
reported, not hidden): differing shared rows 1,176/6,038 = 19.48% (doc: 1,178/
6,038 = 19.51%), `description_enUS` diff 517 (doc 515), `effectBasePoints1`
("damage numbers") diff 410 (doc 409), name changes 51 (doc 51, **exact** -
includes the doc's own literal example, spell 92093 "Deadeye"->"Houndmaster").
All four land inside this task's +/-10% tolerance gate. Per-column diff counts are
computed over every named `TABLE_MAPS["Spell"]` column, not just the doc's cited
top few, so `data/realms/<realm>/overlay_diff.json`'s `columnDiffs` shows the full
shape. `overlayOnlySpellCount`/`baseOnlySpellCount` are computed over the FULL
spell id space (not scoped to the CoA set), matching Sec 3's own
209,130(doc:209,125)/238,939(exact)/31,497(doc:31,498)/1,688(doc:1,684) figures.

> **Amendment D note, and a bug this task found+fixed.** `overlay_diff.json` is a
> SECOND file under `data/realms/<realm>/` with its own single writer
> (`tools/diff_realm_overlay.py`) alongside `tools/build_realms.py`'s
> `index.json`/`_meta.json` - deliberately a standalone CLI tool, not folded into
> `build_realms.py`'s `build()`, since which realm to diff and when is an on-demand
> decision (Sec 13 item 7 proper - capturing Vol'jin/Rexxar and deciding which side
> is authoritative for the disputed rows - stays out of this task's scope). Wiring
> this up surfaced a real bug: `tools/build_realms.py`'s `build_realm()` used to
> `shutil.rmtree()` the WHOLE `data/realms/<realm>/` directory before rewriting its
> own 2 files - harmless while it was the sole writer there, but it would have
> silently destroyed `overlay_diff.json` on every rebuild (the same class of bug
> the `specs.json`/`archetypes.json` survival gate exists to catch for
> `build_classes` vs. `build_classmeta`). Fixed to `mkdir(parents=True,
> exist_ok=True)` + direct overwrite of just its own 2 files; the survival gate is
> pinned in `tests/test_class_plumbing.py`.

**(e) `discover_realms()` fixture-dir test.** Sec 13 item 7's prep half - a true
unit test (not the real client install) that `config.discover_realms()` picks up
a hypothetical new realm directory: a temp `Data\` tree with 2 fixture realm dirs
(each carrying its own `listarchive` file) plus an `enUS\` dir (even given its own
`listarchive`, still excluded - base locale dir) and a no-`listarchive` dir (not a
realm), `config.CLIENT_DIR` monkeypatched to the temp root for the duration of the
call. Also a live-client caveat this task didn't chase further: `Config.wtf`'s
literal realm name (`"Rexxar - Conquest of Azeroth"`) does not match
`CustomFunctionChecks.lua`'s realm-table key
(`"Rexxar - CoA Alpha - Development"`) - if that mismatch means the launcher never
materializes a `Data\rexxar\` directory on login, `discover_realms()` would
correctly find nothing to extract even after logging into Rexxar; worth checking
directly against the live client when Sec 13 item 7 is picked up.

## Traps (task W4-6)

`coa-sim-handoff/DATAMINE-REQUEST.md` Sec 4 lists 17 traps found by the
sim-handoff audit - things that silently produce wrong data if a consumer
doesn't know about them. Numbered to match the source doc so you can
cross-reference directly. Every number below was independently re-measured
against `work/dbc`/`data/` before being written down (full doc-vs-remeasured
table in `.superpowers/sdd/task-w4-6-report.md`); several traps are already
documented at length elsewhere in this file, and those get a one-line
pointer here instead of a second, driftable copy.

1. **`procChance` sentinel is 101, not a percentage - and 0 also means
   "unset," not "never procs."** Re-measured over the curated dataset with
   `procChance NOT IN (0, 101)`: **6,453** real values on the pre-formula-
   closure population (27,475 records, this task's own earlier snapshot) -
   confirms the doc's cited 6,452 to within 1 (expected snapshot drift, not a
   discrepancy - my first pass wrongly used `!= 101` alone and a wrong
   population, see the report's correction note). On the **current**
   28,951-record dataset (post task W4-4 formula closure) that's **6,822 =
   23.56%** - diluted, not contradicted, by the 1,476 formula-closure adds
   (most of which are non-proc reference targets). The field is already
   emitted unconditionally; `build_spells.py`'s
   `_SPELL_COLUMN_COVERAGE["procChance"]` comment ("sentinel 101 = unset, not
   a percentage - see AGENT-GUIDE.md") has pointed here since task W4-3 - this
   entry is what makes that pointer resolve to something. Treat **both** 0
   and 101 as "no proc-chance data," never as a literal 0%/101% chance.
2. **`maxLevel` clamps 85.2% of level-scaled CoA spells below level 80.**
   Already fully documented, with the clamp formula, the `maxLevel == 0`
   "uncapped" sentinel correction, and frozen-value goldens - see "Spell
   column completion (task W4-3)" above, the `EffectRealPointsPerLevel` entry.
3. **CoA reuses Classic ability NAMES for unrelated effects - resolve by id,
   never by name.** Re-verified against `work/dbc/Spell.dbc`: spell 300475
   `"Expose"` is not Expose Armor (an `ADD_FLAT_MODIFIER`-family "damage
   taken from the Felsworn / crit vs this target" aura pair); spell 803477
   `"Sunder"` is not Sunder Armor (`COA_MOD_ATTACK_POWER_FLAT`,
   `basePoints: -24`, exact match to the doc's cited value). A name-keyed
   lookup silently returns the wrong spell for either id.
4. **`id >= 100000` does not mean custom.** Re-derived over the 6,436-id CoA
   class set (`build_spells._coa_class_spell_ids()`): exactly **86** ids are
   sub-100000 - an exact match to the doc's cited count. Key off the
   `data/classes/<Class>/` directory a spell was reached through, never an
   id range.
5. **Reborn contamination.** Re-derived directly against `data/classes/`:
   Reborn's own spell-id universe is **14,107** ids (exact match to the
   doc), CoA intersected with stock/vanilla = **1** id, CoA intersected with
   Reborn = **0** ids (both exact matches). Already documented at length in "Four realms, one
   account-wide CAD file" above; the doc's "~51% unresolved refs" figure
   re-derives to 51.2% there too (`data/spells/_meta.json`'s `cad_reborn`
   7,119/13,901 missing). Any naive "all classes" iteration over
   `data/classes/` still pulls Reborn in - filter on `tag == "coa-custom"`
   (or `"vanilla"` for stock) explicitly.
6. **Three CoA class dirs used to read `classId == null`** (DemonHunter,
   Monk, SonOfArugal) - **fixed since task W4-5, no longer a live trap.**
   Verified on disk: `data/classes/index.json` now gives DemonHunter classId
   14, Monk 19, SonOfArugal 20; `unmatchedChrClasses` is down to `["Hero"]`
   (the one ChrClasses row with genuinely no CAD class). See "ChrClasses
   filename join..." above for the fix. Kept here only so the old advice
   ("code keyed on classId silently drops 3 of 21 classes") isn't
   rediscovered as if still true.
7. **No pretty difficulty-display-name field exists - but `difficultyToken`
   is a usable engine-constant field, and it's `lockoutMessage` that's mostly
   blank.** The doc's specific "Normal blank / Heroic populated with '5
   Player (Heroic)' / Mythic blank" pattern doesn't reproduce against either
   field this pipeline extracts, but the two fields split cleanly once
   measured separately: `data/mythic/mapDifficulty.json`'s
   **`lockoutMessage`** is blank 86.8%/64.2%/63.2%/73.7% at
   `difficultyIndex` 0-3 (unreliable at every tier, matching my first pass -
   that number was for this field only). **`difficultyToken`** is blank only
   **58.6%/2.5%/0.6%/2.6%** at 0-3 - i.e. cleanly *populated* at indices 1-3
   with raw engine constants (`DUNGEON_DIFFICULTY_5PLAYER_HEROIC`,
   `DUNGEON_DIFFICULTY_5PLAYER_EPIC`, `RAID_DIFFICULTY_10PLAYER_HEROIC`,
   `RAID_DIFFICULTY_25PLAYER_HEROIC`, ...), sparse only at index 0 (the
   common "no separate difficulty" case). `data/dungeons/*.json`'s own
   `difficulty` is a bare 0-3 int with no name column at all (431 dungeons:
   212x0, 99x1, 101x2, 19x3) - a separate, unrelated field from either of the
   two above. **Actionable fix:** don't reach for `lockoutMessage` as a
   display label (it's a rare in-fiction lockout string, not a name); use
   `difficultyToken` and map its enum constants to a display string yourself
   (`DUNGEON_DIFFICULTY_5PLAYER_HEROIC` -> "Heroic", etc.) - nothing in this
   dataset does that mapping for you.
8. **`ItemStat.dbc`'s `f2` join = 1.000 is a dense-id false positive.** Not
   currently extracted by this pipeline (`ItemStat`/`Item`/`ItemSpells` are
   all absent from `config.WANTED_DBCS` - Sec 13 items 14-15, out of every W4
   task's scope). Carried forward as-cited, unverifiable from this repo's own
   data since the table isn't on disk here - but it's the textbook instance
   of this repo's own "dense-id join-rate lies" pattern (see the `f<N>`
   convention section above): `f2`'s values are 1..105 and item ids 1..105
   exist, so a naive join looks perfect purely by coincidence. If a future
   task extracts `ItemStat`, re-derive this from scratch rather than trusting
   the cited join rate.
9. **`ItemSpells.dbc`'s `f1` is not the item link.** Same not-yet-extracted
   caveat as trap 8. Per the source doc: `f1` is unique per row (so it can't
   be a many-spells-per-item foreign key) and only 55% resolves against
   `Item.dbc`; `f2 -> spellId` is the well-supported column (99.81% against a
   sparse spell-id space). Whoever extracts this table should apply the same
   "a high join rate against a dense id space proves nothing" skepticism as
   trap 8.
10. **aowow's 1,000-row list cap is silent data loss.** Not exercised by this
    pipeline - no aowow scraping happens in `coa-datamine` itself, that's a
    `coa-sim-handoff`-side concern (`parsers/aowow.py` there). Documented
    here only so a future consumer building on top of an aowow scrape doesn't
    rediscover it: any list response returning exactly 1,000 rows is almost
    certainly truncated (check the `itemsfound`/`_truncated` fields and
    subdivide the query); `minle`/`maxle` filter item level, not required
    level; a bare `ub=<class>` URL param is silently ignored.
11. **`DUMMY` effects/auras are server-side script - `basePoints` on them is
    meaningless.** Re-measured against the current curated dataset (28,951
    records): 4,231 spells (14.61%) touch a `DUMMY`/`PERIODIC_DUMMY` effect
    or aura (doc's snapshot: 3,920/27,474 = 14.3% - consistent growth, same
    order, not a discrepancy). No behavior is recoverable from the data for
    these slots; only the tooltip text, if any, hints at what the server-side
    script actually does.
12. **`ranks[-1]` is the wrong rank at CoA's level-60 cap.** Already fully
    documented, including the median 1.54x/max 6.61x inflation and the
    `rankAt60` fix - see "Formula closure, level-60 ranks..." above, part (b).
13. **A coefficient may be bound to a non-damaging effect slot.** Already
    documented - see "Formula closure..." above, the "binder must follow
    `$mN`/`$sN`-style tokens into ANY effect slot" callout (Barbarian
    *Gutspiller*/*Dawnfall* goldens).
14. **`@s:<id>` is a spellbook cross-link, not a formula reference.** Already
    documented - see "Formula closure..." above: this repo's closure
    deliberately does not follow it, and structurally cannot conflate it with
    the regexes that ARE followed (pinned in `tests/test_closure_ranks.py`).
15. **The `realms` bitmask is undecoded - and task W4-8 tried and failed.**
    Every distinct value (28 across 23,709 CAD entries), every bit's
    presence-fraction across the reborn/coa-custom/vanilla/meta tags, and 5
    candidate hypotheses (plain per-realm bit, `1 << realmId`,
    `Enum.RealmGameMode` index, sentinel values, grouped/mode bits) were
    tested against the golden bar (">=3 independent known groups correctly
    classified") - none passed. Best lead: bit 16 is 100% present on reborn
    and 0.8% on coa-custom, and `Util.lua:337-340`'s own comment names
    numeric realm id 16 as Bronzebeard - but that satisfies only 1 of the 3
    required groups, and the `1<<realmId` mechanism itself is inferred, not
    observed. No bit reaches even half of coa-custom - the best coa-custom
    signal (a 6-way tie at 45.95%) turns out to track the CAD `Type` field
    almost tautologically, not realm membership. Full writeup: `data/classes/
    _realms_evidence.json` + `.superpowers/sdd/task-w4-8-report.md`. Still
    true; further decoding (Sec 6.2, Sec 13 item 10) needs an in-game `/dump`
    - offline analysis is exhausted.
16. **`TalentAbility` entries grant no damaging abilities.** Re-derived from
    scratch over every `coa-custom`-tagged class's `TalentAbility` CAD
    entries: **266** distinct rank-chains (exact match to the doc), and
    **zero** of them carry a direct damaging effect/aura (`SCHOOL_DAMAGE`,
    `WEAPON_DAMAGE`, `PERIODIC_DAMAGE`, ...) on any rank's first-rank record -
    confirms the doc's "all 266 chains are pure passive modifiers" claim
    exactly. The per-effect-name breakdown is close to but doesn't exactly
    reproduce the doc's cited counts (methodology-sensitive - which slot(s)
    of a multi-effect spell get counted); the golden example reproduces
    verbatim: Barbarian *Boulderfist* (705184) reads "Reduces the Energy cost
    of Wrecker by $s1" via an `ADD_FLAT_MODIFIER` aura. Correct to exclude
    these from a damaging-ability denominator, but don't drop them from a
    modifier/buff ingest path - nothing in this dataset serves that path
    today.
17. **Dev-dead content ships in the data.** Already documented, including the
    literal marker text and this task's own re-derivation correcting the
    doc's "three such slots" (a narrower, damaging-slot-only unit) to **7
    records** at the per-record level - see "Formula closure..." above, part
    (d), and the `devDead` flag.

### Realms bitmask decode attempt (task W4-8)

DATAMINE-REQUEST.md Sec 6.2 / Sec 13 item 10 asked for the CAD `Realms` bitmask to
be decoded against the 6-realm roster (Vol'jin, Rexxar, Darkmoon, Dawnrise,
Bronzebeard, Area 52). Built known-population groups from `data/classes`' existing
`reborn`/`vanilla`/`coa-custom`/`meta` tags, enumerated all 28 distinct `Realms`
values across the 23,709 CAD entries, and scored 5 candidate bit-semantics (plain
per-realm bit position, `1 << realmId`, `Enum.RealmGameMode` index, sentinel
values, grouped/mode bits) against the golden bar - **a bit assignment must
correctly classify >=3 independent known groups**. None did.

**Best lead, still unproven:** bit 16 is 100% present on reborn and only 0.8% on
coa-custom, and `raw/interface/SharedXML/Util/Util.lua:337-340`'s own comment
independently names numeric realm id 16 as Bronzebeard (`"10/04/2025 change
malfurion realmID to bronzebeard"`). That satisfies only 1 of the 3 required
groups - no numeric realm id for Vol'jin, Rexxar, Darkmoon, Dawnrise, or Area 52
exists anywhere in `raw/interface`, and the `1<<realmId` MECHANISM applying to
this specific field is inferred, never observed directly. **No bit reaches even
half of coa-custom** - the strongest coa-custom signal is a 6-way tie (bits 1, 2,
6, 14, 25, 26, perfectly co-set on the same 3,828 rows) at 45.95%, and that tie
turns out to track the CAD `Type` field almost tautologically (nearly every
Talent/TalentAbility row, plus a slice of Ability rows) rather than realm
membership - it is a content-shape/UI-context flag wearing a realm-shaped
disguise. A concrete duplication example (Barbarian *Polearms*, spell 200, CAD ids
7704/20078/33260 - realms `"0"`/`"6144"`/`"100679750"` on the SAME ability) shows
why: `Realms` varies WITHIN one ability's duplicate CAD rows, not BETWEEN classes
with different (but by-definition-identical) realm availability.

**Deliverable:** `data/classes/_realms_evidence.json` (`tools/build_classes.py`'s
`_realms_evidence()`, single-writer, regenerates on every `build_classes.build()`
run) ships the full census/crosstabs/per-bit-statistics/hypothesis-scoring/verdict,
plus every Lua citation checked. Full narrative:
`.superpowers/sdd/task-w4-8-report.md`. Per the binding rule ("emit only proven
bits"), **no `realmFlags` is emitted anywhere** - raw `realms` on every
`data/classes/<Class>/*.json` entry is byte-identical to before this task.
Follow-up: an in-game `/dump` of a known CoA-only ability's CAD entry on both
Vol'jin and Rexxar (or a server-side query) is the only avenue left - offline
analysis is exhausted.

## Recipes (PowerShell / Python)

All spells across the whole dataset (helper for the recipes below):

```python
import json

def iter_all_spells():
    idx = json.load(open(r"data/spells/index.json", encoding="utf-8"))
    for b in idx["buckets"]:
        for line in open(rf"data/spells/{b['file']}", encoding="utf-8"):
            yield json.loads(line)

def iter_class_entries(cls):
    idx = json.load(open(rf"data/classes/{cls}/index.json", encoding="utf-8"))
    for f in idx["files"]:
        doc = json.load(open(rf"data/classes/{cls}/{f['file']}", encoding="utf-8"))
        yield from doc["entries"]
```

All spells of a class that apply a Magic-dispellable aura:

```python
ids = set()
for e in iter_class_entries("Necromancer"):
    for s in e["spells"]:
        ids.add(s["id"])
        for r in (s.get("ranks") or []):
            ids.add(r["spellId"])
hits = [(sp["id"], sp["name"]) for sp in iter_all_spells()
        if sp["id"] in ids and sp["dispel"]["id"] == 1
        and any(e["effect"]["name"] == "APPLY_AURA" for e in sp["effects"])]
```

Which classes get spell 954876: grep `"954876"` recursively across
`data/classes/*/*.json` (every shard is self-describing, so a hit's `class`/`tab`
fields tell you where it came from without cross-referencing the index).

All encounters of a raid: read `data/dungeons/index.json`, filter `isRaid`, open
each hit's `file` and read `encounters` (already ordered).

A dungeon's reward for a given character level: open its `data/dungeons/<id>-<slug>.json`
(id looked up via `index.json`) -> `rewards` is a **list** of level-bracket objects
sorted by `MaxLevel` ascending (most dungeons have one bracket or none - 4 dungeons
have several, e.g. dungeon id 258 has 17); pick the first bracket whose `MaxLevel`
is >= the character's level, and treat an empty list as "no reward data", not an
error. The old `encountersByMap` duplicate view is gone - if you need encounters
grouped by map instead of by dungeon, derive it by reading every dungeon file and
grouping on `(mapId, difficulty)`.

All encounters of a Mythic+ challenge dungeon, with a best-effort creature match
(`data/dungeons/index.json`'s `id` and `data/mythic/keystones/index.json`'s
`dungeonId` are the same `LFGDungeons.dbc` id space, so they join directly - but
`DungeonEncounterExtra`'s creature-id column was probed and disproven [Honest limits],
so every encounter's own `creature` field is always `null`; the closest available
signal is a **name match**, not a proven FK, and is not guaranteed unique - e.g.
Ragnaros has 11 creature-template variants):

```python
import json

def mythic_dungeon_encounters(dungeon_id):
    kidx = json.load(open(r"data/mythic/keystones/index.json", encoding="utf-8"))
    keystone = next(d for d in kidx["dungeons"] if d["dungeonId"] == dungeon_id)

    didx = json.load(open(r"data/dungeons/index.json", encoding="utf-8"))
    dungeon_file = next(d["file"] for d in didx["dungeons"] if d["id"] == dungeon_id)
    dungeon = json.load(open(rf"data/dungeons/{dungeon_file}", encoding="utf-8"))

    by_name = {}   # lazily populated from data/creatures/ on first use
    def creature_candidates(name):
        if not by_name:
            cidx = json.load(open(r"data/creatures/index.json", encoding="utf-8"))
            for b in cidx["buckets"]:
                for line in open(rf"data/creatures/{b['file']}", encoding="utf-8"):
                    r = json.loads(line)
                    by_name.setdefault(r["name"], []).append(r["id"])
        return by_name.get(name, [])

    return keystone, [
        {"encounter": e["name"], "creatureIdCandidates": creature_candidates(e["name"])}
        for e in dungeon["encounters"]
    ]
```

A class's specs and roles (`data/classes/specs.json`, not `index.json` -
Amendment D moved spec/role data there):

```python
import json

def class_specs_and_roles(class_name):
    cidx = json.load(open(r"data/classes/index.json", encoding="utf-8"))
    class_id = next(c["classId"] for c in cidx["classes"] if c["name"] == class_name)

    sd = json.load(open(r"data/classes/specs.json", encoding="utf-8"))
    spec_ids = sd["perClass"].get(class_name, [])
    by_id = {s["id"]: s for s in sd["specs"]}
    return {
        "classId": class_id,
        "specs": [by_id[i] for i in spec_ids],       # [] if this class has none - see Honest limits
        "roles": sd["roles"].get(class_name, []),     # e.g. Mage -> ["DPS"]
        "specialAbility": sd["specialAbilities"].get(class_name),  # None for most classes
    }
```

## Honest limits

- Client data cannot see server-side logic: boss scripts, loot tables, runtime
  spell grants, proc internals. Encounter lists are names/order only.
- `CharacterAdvancementData.json` is account-wide across the four realms this
  client serves (see Key semantics above); Reborn*-class spell refs are expected
  to resolve `null` far more often than other classes in this snapshot - that's a
  data-availability fact of the capture, not a pipeline bug.
  `data/spells/_meta.json` records the shape precisely: `missing_ref_counts_by_source`
  gives the count per bucket (`cad_other` / `cad_reborn` / `talent` / `rank`) and
  `ref_counts` gives the denominator for each; the full id lists themselves live in
  `data/spells/_missing_refs.json` (kept out of `_meta.json` so it stays small - each
  source's array is on one line there). The build only hard-gates
  `cad_other` and `talent` (each must resolve to <=5% missing - measured churn
  baseline was `cad_other` 211/7162 = 2.95% on 2026-07-17, i.e. real named
  custom-class abilities absent from this snapshot's `Spell.dbc`, recorded in
  `dataNotes`). `cad_reborn` misses and `rank` orphans (stale `SpellRankData`
  chains with no filterable realm/class field) are report-only, not gated -
  expect both to be nonzero on every build.
- `Realms` bitmask on class entries: semantics unknown, carried raw. Task W4-8
  tried to decode it against the 6-realm roster and failed the golden bar - see
  trap 15 above and `data/classes/_realms_evidence.json` for the full attempt
  (distinct-value census, per-bit statistics, candidate-hypothesis scoring, Lua
  findings). No `realmFlags` exists anywhere in this dataset.
- Enum labels for uncommon effect/aura ids fall back to `EFFECT_<n>`/`AURA_<n>`;
  the numeric id is always authoritative.
- `.loc` localization files (non-enUS) are unparsed; enUS strings come from DBCs.
- CAD covers *obtainable* abilities; item/proc-granted spells appear only via the
  trigger closure or not at all.
- Dungeon `rewards` is a **list** of level-bracket objects sorted by `MaxLevel`
  ascending, never a single object - `LFGData.json` carries multiple reward rows
  for 4 dungeons (id 258: 17 brackets; 259/417/465: 2 each). An empty list means
  no LFGData reward entry exists for that dungeon at all; always iterate it, never
  assume exactly one row.
- Only 12 classes have DBC `Talent.dbc` talent tabs (10 vanilla + Barbarian +
  WitchDoctor); every other class's talents live only in CAD entries
  (`type == "Talent"`/`"TalentAbility"` across that class's `data/classes/<Class>/*.json`
  shards) - absence from `data/talents/` does not mean the class has no talents.
- **Quest text is server-side, not in this dataset.** `Quest.dbc` carries **zero
  string data** (`string_block_size == 0`, verified directly) - there is no title,
  objective text, or completion text anywhere in the 18561 `data/quests/` records,
  only `id` plus 28 raw numeric columns. If you need quest text, it lives in the
  server's own quest-template data, which this pipeline (client-side DBCs + Content
  JSONs only) cannot see.
- **`data/creatures/` has no level, health, armor, resistance, or
  creature-type field for any of its 127,178 rows - by design, not omission.**
  `{id, name, subname}` is the whole schema (`subname` itself is always
  `null` - see the disproven-mappings list below); `raw/dbc/Creature.csv.gz`
  is entirely display data end to end, verified directly. This is genuinely
  server-side content on a 3.3.5 client, the same class of gap as quest text
  above - a DPS simulator needs to measure target stats in game, this
  pipeline (client-side DBCs only) cannot see them.
- **No base stats, no PPM, and no internal cooldown anywhere in client
  data (task W4-6, DATAMINE-REQUEST.md Sec 11).** Base mana/health/primary-stat
  tables and crit/dodge/parry intercepts (a `player_classlevelstats`
  equivalent) are server-side only on 3.3.5 - verified by absence, not just by
  omission: no such table appears anywhere in `config.WANTED_DBCS`, and a
  repo-wide search of `data/` for `baseMana`/`baseHealth`/`internalCooldown`/
  `procsPerMinute` turns up zero structured fields (the one substring hit is a
  spell tooltip's own `...basemana` prose, not a value). Likewise no PPM field
  and no internal-cooldown field exist in any extracted table - the `gt*`
  regen tables (see "gt* combat-rating tables" above) give mana/health
  regen-per-second curves only, not the base pool a percentage-of-base cost
  needs. `coa-sim-handoff/gtdbc/charbaseinfo.dbc` is shipped there as a
  possible partial source for base stats and is worth a future task's look -
  it is not extracted or evaluated by this pipeline today.
- **`manaCostPct` needs base mana to resolve to an actual number - and it's
  the majority mana-cost channel, not the minority one.** Re-derived directly
  against `work/dbc/Spell.dbc`: on the current curated dataset (28,951
  records, post-task-W4-4 formula closure) **20.30%** of spells carry a
  nonzero `manaCostPct` vs **8.65%** a nonzero flat `manaCost`. Measured on
  the pre-W4-4-closure population instead (27,475 records - the snapshot
  shape the source doc's own figure was measured against), these read
  **21.12%/9.04%**, an almost-exact match to the doc's cited 21.1%/9.0%; the
  further drift on the current 28,951-record figure is the formula-closure
  records task W4-4 added, not new mana-cost content. Since no base-mana
  table exists anywhere (see the bullet above), a `manaCostPct`-priced
  spell's actual mana cost is **not computable from this dataset alone** for
  what is the majority mana-cost channel, not an edge case.
- **`effects[].bonusMultiplierStock` is a trap for CoA damage modeling** - correct
  for stock/Reborn content only, near-zero agreement with CoA's own tooltip-authored
  coefficient on the same slot (re-derived this task: stock 0/65, CoA 7/113 = 6.2% -
  see "Spell column completion" above). Never union it with the tooltip-parsed
  coefficient; the `description`/`tooltip` formula text is CoA's only real
  coefficient channel.
- **`effects[].realPointsPerLevel` needs the `maxLevel` clamp applied by the
  consumer** - it is a per-level *value* term, not a gear-scaling coefficient, and
  85.2% of the CoA spells that carry it are capped below level 80. See "Spell column
  completion" above for the clamp formula and frozen-value goldens.
- **`rankAt60`'s gating field is [INFERRED]-CAD, UNRESOLVED** - CAD `ranks[].level`
  and DBC `spellLevel` pick a different level-60 rank on 512 of 920 CoA chains; this
  field follows CAD level on the doc's own reasoning (not independently verified),
  needs an in-game `/dump` to confirm. See "Formula closure, level-60 ranks..."
  above - this is a real open question for absolute damage values, not a hedge.
- **The formula-reference closure is depth-capped at 2, not exhaustive** - a
  reference embedded only in a depth-2-added record's own text (i.e. a would-be
  depth 3) is not followed. Measured but not applied: +3 records - see "Formula
  closure..." above.
- **Disproven mappings ship as documented `null`/raw, never a guessed value** - each
  was probed against the empirical-mapping rule's bar and failed it; the
  `_meta.json`/`TABLE_MAPS` comment pointer is listed so you can re-run the same
  probe methodology if a future client patch changes the underlying table:
  - `data/creatures/*.jsonl`'s `subname` - always `null` (`data/creatures/_meta.json`'s
    `subnameFinding`; the two candidate columns' apparent string-likeliness matched a
    random-offset control's coincidence rate, ~3.45%).
  - `data/quests/*.jsonl`'s `sort`/`info` - always `null` (`data/quests/_meta.json`'s
    `sortInfoFinding`; best real candidate topped out at 58.6%/58.2% join-rate,
    short of the 80% bar).
  - ~~Every dungeon encounter's `creature` field - always `null`~~ **REVERSED in task
    V3-0** (2026-08-01): the V2-2 disproof above joined against `Creature.dbc`'s OLD f0
    column, which turned out to be a positional row index, not a stable id (see the
    `data/creatures/` row above) - its fully-dense 1..127178 range is exactly why the
    naive join-rate false-positived at 92.4% while every golden failed. Retested against
    the corrected f1 entry-id space (genuinely sparse, 127178 ids across 1..11001007),
    the SAME column proves out: 98.57% row-level join-rate, every famous-boss golden
    resolves correctly. `data/dungeons/*.json` encounters now carry a real
    `creature: {id, name}` (null for ~4.5% of encounters - 93/2080: 64 (3.08%)
    have no matching `DungeonEncounterExtra` row at all, 29 (1.39%) have an
    unresolved `creatureId`) - see
    `tools/build_dungeons.py`'s module docstring and
    `.superpowers/sdd/task-v3-0-report.md` for the full evidence.
  - `data/classes/specs.json`'s `f63` field - ChrSpecs' one low-cardinality column,
    tested as both Tank/Healer/DPS role and ordinal spec position and disproven both
    ways (`tools/dbc.py`'s `ChrSpecs` comment); shipped raw, not named `"role"`.
  - `SpellAlternativePowerType`/`SpellAddon`'s f20-f22/`CharacterCreationPetDetails`
    and `ShapeshiftDetails`' spellId candidates - all disproven, documented inline in
    `tools/dbc.py`.
- **`SpellCharges` is shipped standalone, not attached to any spell.** Its spellId
  join-rate against live `Spell.dbc` ids is **0.885** (354/400) - short of the 0.90
  bar the brief set specifically for attaching a `charges` field to `spells.jsonl`
  records, even though the categoryId link to `SpellChargesCategory` is 100% proven
  and a large majority of the resolved rows mention "charge" in their own tooltip
  text (strong circumstantial support that the mapping itself is right, just short
  of the stated bar). The 400 rows are still fully usable at `data/spells/charges.json`, keyed by
  their own `ref` (not called `spellId`, since the link wasn't proven to that bar) -
  see the file map above.
- **`data/gt/` cannot prove the server uses these values.** `gt*` tables are the
  CLIENT's copy (tooltips, character sheet); a TrinityCore-family server loads its own
  set and this pipeline has no way to see server-side data. `gtOCTClassCombatRatingScalar`
  ships raw + colinfo only (different shape, layout unproven - see "gt* combat-rating
  tables" above), and `gtCombatRatings`' ARMOR_PENETRATION rating reads 11.55 at level 80
  against a published 15.39 - a real, unresolved behavioral difference, not a bug in this
  pipeline's decode.

## Regenerating after a client patch

The test suite mixes two different kinds of check, and they fail for different
reasons. STRUCTURAL checks verify the pipeline itself still works: WDBC layout
guards (`dbc.LayoutError`), golden spell rows (id 17 Power Word: Shield, id 10
Blizzard - name/dispel/school/duration fixed points), the `cad_other`/`talent`
missing-ref ratio gates (<=5%), and general schema asserts (field counts,
sort order, required keys). SNAPSHOT PINS, by contrast, are exact counts
calibrated to this repo's 2026-07-17 capture and will legitimately drift
whenever CoA ships new content:

- `tests/test_classes.py`: RebornWarlock 1719 entries / Necromancer 427 entries
  (summed across each class's shard files, per `data/classes/<Class>/index.json`)
- `tests/test_talents.py`: 37 tabs / 2383 talents
- `tests/test_dungeons.py`: 431 dungeons / 2080 encounters / dungeon-258 has 17
  reward brackets
- `tests/test_extract.py`: `spell.dbc` resolves from `patch-T.MPQ`
- `tests/test_sharding.py`: pins the pre-shard record-count baseline (spells 27441,
  per-class entry counts, dungeons 431) so sharding can't silently drop/duplicate
  records; also the repo-wide <=5,000-line gate (empty allowlist today - re-add an
  entry here and in the allowlist if content growth ever forces one)
- `tests/test_creatures.py`: 127178 creatures / 18561 quests / 13111 trainers
  (`Creature.dbc`/`Quest.dbc`/`NPCTrainer.dbc` record counts), trainer spellId
  join-rate >=90% (measured 0.9892)
- `tests/test_classmeta.py`: 101 specs / 56 archetypes, >=60% of the 32 `ChrClasses`
  covered by >=1 spec (measured, as of task W4-5's filename-fallback join, 32/32 =
  100% - was 25/32 = 78.1% before it; the >=60% floor is deliberately kept loose
  rather than tightened to ==32, in case a future client patch reintroduces a
  genuinely unmatched token - see `tests/test_class_plumbing.py` for the exact
  32/32 gate)
- `tests/test_spells_v2.py`: `schemaVersion: 2`; enrichment coverage counts (tags
  26281, category 6034, customAttr 7635, descriptionVariables 1302, addon 133,
  overrideData 6, all of 27441 referenced spells). These enrichment counts drift
  with client patches like the other snapshot pins above; `test_spells_v2.py`
  itself gates most of them as floors (e.g. `descriptionVariables > 1000`), not
  exact values, so treat the numbers here as a snapshot figure, not a contract.
- `tests/test_mythic.py`: 297 challenges / 6801 keystones (66 resolved dungeons) /
  13409 affixes / 200 scaling rows / 82 timed dungeons / 685 map-difficulty rows;
  every link table's `challengeId` join rate >=80% (lowest: `ChallengeLevels` 84.9%)
- `tests/test_interface.py`: `raw/interface/_manifest.json` >=1500 files (measured
  1553: 1444 archive-sourced + 109 disk-sourced `APIDocumentation`), sha256 sample
  check, zero non-code extensions
- `tests/test_manastorm.py`: 1017 Manastorm / 291 ManastormMessages / 32768
  ManastormModifiers / 15 ManastormPlayerGroupModifiers rows; `dungeonEncounterJoinRate`
  gated >=0.95 (measured 0.9951); Shadowfang Keep boss-roster + seasonal-message-text
  goldens
- `tests/test_realms.py`: pins the same live-probed header facts as this file's
  "Manastorm + realm overlays" section for whichever realm(s) are actually present on
  the machine running the suite (currently area-52 only - see that section for why);
  its own module docstring already warns these may drift slightly with a future
  client patch, same re-pin treatment as every other snapshot pin here.
  `newSpellCount` is gated loosely (>10000, measured 31498) rather than pinned exactly,
  since a realm's own content churns independently of the base client's.
  `CharacterAdvancementEssence` moved from its `UNMAPPED_TABLES` set to
  `MAPPED_TABLES` in task W4-5 (gained a real `TABLE_MAPS` column proof) - the one
  intended change to this file's own expectations from that task.
- `tests/test_class_plumbing.py` (task W4-5): `data/classes/essence.json` goldens
  re-derived fresh from `work/dbc/CharacterAdvancementEssence.dbc` at test time
  (not hardcoded); the `ChrClasses.filename` join goldens (id14/19/20) plus a
  cross-check against the live `ClassRemap` Lua table; 21/21 `coa-custom` classId
  gate + `unmatchedChrClasses == ["Hero"]`; `specs.json` 32/32 coverage gate; the
  `ChrClassesRoles` roster cross-check (31/31 doc-listed classes, 0 mismatches);
  `tools/diff_realm_overlay.py` run against area-52, gated at +/-10% of Sec 3's
  cited numbers (re-derived fresh, not pinned - report exact per the task's own
  gate); the `overlay_diff.json`-survives-a-`build_realms`-rerun regression test
  for the bug this task found+fixed; a true fixture-dir unit test for
  `config.discover_realms()` (temp `Data\` tree, not the real client install).
- `tests/test_dataset.py`: 11 `buildStats` keys (task W4-5 added `essence`);
  `headerMismatches == []` for the base
  77-table `config.WANTED_DBCS` set is a STRUCTURAL check, not a snapshot pin - see
  "Header-invariant parity" above. Don't re-pin a nonzero list; investigate which base
  table's header started lying and why.
- `tests/test_closure_ranks.py`: task W4-4 - formula-closure delta gated at +/-20%
  of the doc's cited +1,843 (re-derived fresh each run, not a fixed pin - measured
  1,476 as of this task); `rankAt60`/`$scalingbp`/`devDead` goldens re-derived from
  `work/dbc` at test time, not hardcoded (see "Formula closure, level-60 ranks..."
  above)
- `tests/test_gt.py`: re-derives the gt* layout proof fresh from `work/dbc/gt*.dbc` at
  test time rather than pinning fixed numbers (mostly STRUCTURAL, not a snapshot pin) -
  the level-80 combat-rating constants, the spell-crit/melee-crit conversion goldens,
  and the `cr14`/RESILIENCE non-pin all re-check against whatever is on disk. A future
  client patch that changes a `gt*` table's RECORD COUNT (currently 3200/3200/32 per
  table) or moves the ARMOR_PENETRATION anomaly's value closer to the published 15.39
  constant is worth a manual look - see "gt* combat-rating tables" above - not a
  reflexive re-pin, since the whole point of this file is to catch exactly that kind of
  silent layout drift.

Interface extraction counts are also snapshot pins in the sense above, but of a
different flavor: they drift with the CLIENT install (which archive wins a given
`.lua`/`.xml` file, whether Ascension patches `APIDocumentation`), not with game
content churn, and there is no golden-record test for any single file's *content* -
only shape/count/hash-integrity gates. A big swing in `archiveSourced` or a drop in
`AddOns/APIDocumentation`'s `.lua` count below 10 means something changed about which
archives carry the Interface tree (or the on-disk client install itself) and is worth
a manual look, not a reflexive re-pin.

Note: the spells count above (27441) already reflects one round of exactly this kind
of drift - discovered mid-task when a controlled re-run of the pre-sharding writer
against the current `work/dbc`/`raw/content` snapshot produced 27441 records, not the
27432 that had been committed in `data/spells/`. Re-running both the old and new
writer against identical source data confirmed the delta was pre-existing upstream
content drift (unrelated to the sharding rewrite itself), not a regression - the same
class of churn documented in past task reports (e.g. Task 9's spell 61685 rename,
Task V2-1's raw/ Spell.csv.gz +292 rows).

After regenerating against a patched client, treat the two failure modes
differently. A snapshot-pin failure with a small delta (record counts moved by
tens, not orders of magnitude; a different archive won the same DBC by one
letter) means content changed upstream - eyeball the new numbers for
sanity, then re-pin the constants to match. A structural-check failure (layout
guard fires, a golden spell's fixed fields changed, a ratio gate blows past
5%, a huge/negative count swing) means the pipeline itself broke - investigate
the extractor/builder, don't just paper over it by re-pinning.
