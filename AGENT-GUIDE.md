# Agent Guide - querying coa-datamine

Dataset of Ascension CoA (WoW 3.3.5a custom server) game data for porting work
(dispel logic, class buffs, raid tooling). Everything below is generated - do not
hand-edit; rerun `python -m tools.build_dataset` after a client patch instead.

> **Read this before using `data/classes/`.** It is the CAD **catalog** - what the
> client's character-advancement tables LIST - and a large part of it is not in the
> game. Of the 8,331 entries belonging to a class whose live talent trees were
> captured, **4,908 (58.9%) appear in no live tree**, including whole trees that no
> longer exist (a real level-60 Starcaller has Moon Guard / Sentinel / Moon Priest /
> Warden / Class; the catalog still lists a `Tides` tree whose abilities they cannot
> learn). Branch on each entry's **`live` / `liveEvidence`** (task W4-14) - never on
> mere presence - and read "Live vs catalog" below for what `false` vs `null` mean.

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
| `data/classes/_live_summary.json` | task W4-14: the live-vs-catalog join's own evidence file - repo-wide + per-class `liveCounts`, the payload provenance (capture date + sha256) and Vol'jin/Rexxar caveat every `live` verdict is scoped by, the measured **false-negative** analysis (which non-tree acquisition paths were tested, which separated and which did not), and the CAD-tab -> live-tab mapping with per-pair method + node-overlap evidence. Written by `build_classes.py`; `build_classmeta.py` READS its `tabMapping` rather than re-deriving it | small |
| `data/classes/<Class>/index.json` | that class's `tag`/`classId`/`realmHint`/`aliases`/`entryCount`/`unresolvedCount`/**`hasLiveGeometry`**/**`liveCounts`** (`{live, deadCatalog, liveViaRank, unknown}`, sums to `entryCount`) / **`liveCountsByReason`** (task W4-14, see "Live vs catalog" below) + `files: [{file, tab, type, cadIdRange, count}]` enumerating every shard file for the class - `aliases` (task W4-5) is `[]` for 40 of 43 classes, `[<ClassRemap token>]` for the 4 CoA-custom classes whose internal filename token isn't a trivial uppercase of their own CAD name (Runemaster/Primalist/Venomancer/KnightOfXoroth) | small |
| `data/classes/<Class>/<Tab>.json` | one spec tab's CATALOGUED abilities/talents/traits with resolved spells (`{class, tab, type: null, entries}`) - **catalogued, not necessarily in the game: read each entry's `live`/`liveEvidence` (task W4-14) before treating it as real content**; each resolved spell's `ranks[]` already carries `{spellId, rank, level}` per rank (unchanged V1 design, verified still current by task W4-4) - for level-60 rank selection, look up that chain's first-rank id in `data/spells/` instead and read its `rankAt60` field (task W4-4) rather than re-deriving the CAD-level cutoff here | small-medium |
| `data/classes/<Class>/<Tab>.<Type>.json` / `<Tab>.<Type>-<cadId-bucket>.json` | only present when a single tab's entries exceed 5,000 lines as one file (Reborn* classes' biggest tabs, plus 10 more since task W4-14) - see "Class tab sharding" below | small |
| `data/classes/<Class>/_general.json` | entries with no `Tab` (none exist in the current snapshot; the file only appears if some do) | small |
| `data/spells/index.json` | bucket manifest: `bucketSize` (10000), total `count`, `buckets: [{bucket, file, count, minId, maxId}]` | small |
| `data/spells/by-id/spells-<id//10000*10000>.jsonl` | every referenced spell in that id bucket, fully enriched, ONE JSON PER LINE, ascending id within the bucket; empty buckets are omitted - each effect carries `realPointsPerLevel`/`pointsPerComboPoint`/`spellClassMask`/`damageMultiplier`/`bonusMultiplierStock` when nonzero (task W4-3, see "Spell column completion" below), and each record carries `speed`/`equippedItem`/`maxAffectedTargets`/`casterAuraSpell`/`targetAuraSpell`/`manaPerSecond`/`targetCreatureType`/`casterAuraState`/`targetAuraState`/`stancesNot`/`missileId`/`family.flags3` unconditionally; task W4-4 adds `rankAt60` (chain's own first-rank record only, omitted when none of that chain's ranks are CAD-level<=60) and `devDead: true` (7 records, see "Formula closure, level-60 ranks..." below) when applicable | small-medium per file - stream/grep it, do not slurp |
| `data/spells/_meta.json` | counts only: `count`, `missing_ref_counts_by_source`, `ref_counts`, `dataNotes`, `by_source`, `missingRefsFile` pointer, `columnCoverage` (pointer to `_coverage.json` + summary counts), `formulaClosure`/`rankAt60`/`scalingConstants`/`devDead` (task W4-4, see "Formula closure, level-60 ranks..." below) | small |
| `data/spells/_coverage.json` | task W4-3: per-`TABLE_MAPS["Spell"]`-column `{index, kind, mapped, emitted, where}` manifest (128 mapped of 234 total fields, 124 emitted/4 mapped-not-emitted) - see "Spell column completion" below | small |
| `data/spells/_enum_evidence.json` | per-id provenance for every effect/aura enum label: `{effects, auras}` keyed by numeric id -> `{bucket, confidence, name, goldenSpells, occurrences}`, plus a `summary` block. 224 classified ids (66 effect + 158 aura) - 57 `confidence: verified` names are actually WIRED into `tools/enums335.py`'s `COA_*` maps, 2 more carry an `[INFERRED]` name and are deliberately documentation-only (never wired), and the remaining 167 are left as numeric `EFFECT_<n>`/`AURA_<n>`. Every named entry carries >=1 `goldenSpells` id you can look up in `data/spells/` to check the name yourself - **this is how you audit any enum label in this dataset** | small |
| `data/spells/_missing_refs.json` | full missing-ref id lists by source (`cad_other`/`cad_reborn`/`talent`/`rank`/`formula` - task W4-4 adds `formula`, report-only, never folded into the `cad_other`/`talent` hard gates), each source's array on ONE line | small (line count, not byte count) |
| `data/talents/<ChrClass>.json` | DBC talent trees (row/col/ranks/prereqs) - only exists for the 12 classes that have DBC talent tabs; largest is ~3.6k lines, under the gate as-is, not sharded | medium |
| `data/talents/_pet.json` | pet talent tabs (`petTalentMask` set) - not tied to a single player class | small |
| `data/talents/_unassigned.json` | talent tabs matching no classMask/petTalentMask | small |
| `data/talents/_meta.json` | tab/talent counts, per-class tab counts, unresolved rank-spell count | small |
| `data/talents/coa/<Class>.json` | task W4-9: CoA talent-tree GEOMETRY for all 21 `coa-custom` classes (153-208 nodes each) - `{class, classId, essence, tabs: [{tabId, tabName, sortOrder, entryCount, isEmpty, aeGateTiers, teGateTiers, maxReqTabAE, maxReqTabTE}], choiceGroups: [{groupId, tabId, x, y, entries: [{id,name,spellId}, ...]}], nodeCount, nodes: [{id, name, x, y, classId, tabId, sortOrder, group, flags, aeCost, teCost, spellId, spellIds, iconPath, nodeType, entryType, isPassive, maxPoints, requiredIds, requiredLevel, isStartingNode, connectedNodeIds, reqTabAE, reqTabTE, description, rankDescriptions, spellResolved}]}` - sourced from the published `https://ascension.gg/en/v2/coa-builder/voljin` builder payload (frozen by `tools/fetch_coatalents.py` into `raw/talents/`), a SEPARATE dataset from the `<ChrClass>.json` DBC trees one directory up (never collides - e.g. Barbarian has both). `spellResolved` flags whether `spellId` joins `data/spells/` - only ~53% do (real content drift vs. this repo's client snapshot, NOT a join bug - see "CoA talent tree geometry" below and `data/talents/coa/_meta.json`'s `contentDrift`). `requiredIds`/`connectedNodeIds` are de-padded (source arrays are zero-padded fixed width; `0` is never a real node id here) | small per file |
| `data/talents/coa/index.json` | class -> file, tab/node/choice-group counts per class | small |
| `data/talents/coa/_meta.json` | payload fetch provenance (url/sha256/capture time), realm caveat (Vol'Jin captured, Rexxar assumed identical/unverified), full resolve-rate cross-validation, the 84-vs-72 tab-layer reconciliation, `isStartingNode`/choice-group/connectivity findings - see "CoA talent tree geometry" below | small |
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
| `data/classes/specs.json` | `{specs: [101 ChrSpecs rows: id, name, classId\|null, className\|null, classToken, tabToken, tabStatus\|null, description, armorType, primaryStat, secondaryStat, difficulty, powerType, secondaryPowerType, f63], perClass: {32 classNames: [specIds]}, roles: {32 classNames: [role,...]}, specialAbilities: {3 classNames: {spellId, name}}, tabStatusSummary}` - owned solely by `build_classmeta.py` (Amendment D); read this file for spec/role data, never `data/classes/index.json`. `perClass`/matched-classId coverage is **32/32 as of task W4-5** (was 25/32 - the `classToken` join now falls back to `ChrClasses.filename` when the display-name join misses, see "ChrClasses filename join..." below); `classId`/`className` can still ship `null` in principle if a future client patch reintroduces a token neither join resolves. **Task W4-14** re-derives `tabStatus` against the LIVE talent builder and RENAMES its states (`{status: "inLiveBuilder"\|"cadOnly"\|"unreleased"\|"noLiveGeometry"\|"noCadClass", cadTab, liveTab, match, renamed}` per spec, `null` only when `classId`/`tabToken` themselves are missing) + `tabStatusSummary` - W4-11e's `"live"` meant only "a CAD tab with this token exists" and was routinely misread as "this tree is in the game"; see "Live vs catalog" below | small |
| `data/classes/archetypes.json` | `{archetypes: [56 CharacterCreationArchetypes rows: id, name, tagline, description, primaryStat, weaponTypes, armorTypes, iconToken, cinematicPath, abilityPreviews, races]}` - character-creation flavor presets, class-agnostic (no classId link exists in this table) | small |
| `data/classes/essence.json` | task W4-5: `{levels: [1..80], classes: [32 rows: classId, className, curveGroup ("classlessBase"\|"hero"\|"coaCustom"), abilityEssence: [80 ints], talentEssence: [80 ints]]}` (`CharacterAdvancementEssence.dbc`, 5,600 rows = 80 levels x 32 classes x 8 flag-variant rows, canonical curve = the flags-all-zero row per (classId,level) pair) - owned solely by `tools/build_essence.py`, a **new module deliberately separate from `build_classmeta.py`** (Amendment D: classmeta owns specs.json/archetypes.json only); see "Per-class Ability/Talent Essence curves..." below | small |
| `data/spells/charges.json` | standalone `SpellCharges`/`SpellChargesCategory` curation (400 charge rows / 105 categories) - **NOT attached** to any `spells.jsonl` record (join-rate 0.885 < the 0.90 attach bar, see Honest limits); `{categories: {<categoryId>: {id, raw:[f1,f2]}}, charges: [{ref, categoryId, resolvedSpellName\|null, realmResolvedIn?}], realmGapFinding}` - task W4-11f adds `realmGapFinding` (per-realm resolution of the non-joining refs) + per-row `realmResolvedIn` (only present when unresolved in base), see Honest limits | small |
| `data/spells/statSuggestions.json` | task W4-10: standalone `SpellStatSuggestions.dbc` curation (1121 rows) - **NOT attached** to any `spells.jsonl` record (its `spellId` key is proven at 99.91% join, but its payload is not - see Honest limits); `{spellIdJoinRate, suggestions: [{spellId, resolvedSpellName\|null, statCategoryRaw, f3}]}`, one-compact-record-per-line (`sharding.dump_manifest`) | small |
| `data/mythic/challenges/index.json` | one compact record per Mythic+ Challenge: `{id, name, file, difficultyToken, modeToken, featured}` (297 challenges) | small |
| `data/mythic/challenges/<id>-<slug>.json` | one challenge incl. `groups`/`levels`/`rules`/`modifiers`/`conditions`/`requirements`/`rewards`/`spells` (one-record-per-line `sharding.dump_manifest` format - the default "Adventure Mode" challenge alone aggregates ~2,000 rows across those lists) | small-medium |
| `data/mythic/challenges/_lookups.json` | `ChallengeRuleTypes`/`ModifierTypes`/`ConditionTypes`/`RequirementTypes` lookup tables (127/8/18/22 rows) | small |
| `data/mythic/challenges/_meta.json` | per-link-table `challengeId` join rates, the Challenge-7 "Nudist" golden, `conditionsFinding` | small |
| `data/mythic/keystones/index.json` + `<dungeonId>-<slug>.json` | `MythicKeystones` levels grouped per dungeon (66 resolved dungeons; `dungeonId` is the same id space as `data/dungeons/index.json`'s `id` - both key off `LFGDungeons.dbc`) | small |
| `data/mythic/keystones/_unresolved.json` | 101 `MythicKeystones` rows whose `dungeonId` doesn't resolve against `LFGDungeons.dbc` (raw, documented; overall join rate 0.9851) | small |
| `data/mythic/affixes/affixes-<id//5000*5000>.jsonl` + `index.json` | 13409 `MythicAffixes` rows; affix identity is `grantSpellId`/`effectSpells` (resolved spell names) - the brief's `ChallengeModifierTypes` name hypothesis was tested and disproven, see `tools/dbc.py` | small-medium |
| `data/mythic/scaling.json` / `timedDungeons.json` / `mapDifficulty.json` | small standalone Mythic+ tables: `MythicPlusScaling` (200 rows), `TimedDungeons` (82 rows, `dungeonName` resolved), `MapDifficulty` (685 rows, `mapName`/`lockoutMessage` resolved) | small |
| `data/items/statsByItem/index.json` + `statsByItem-<itemId//5000*5000>.jsonl` | task W4-11b: `ItemStat.dbc` per-item COVERAGE index (20,267 items) - `{itemId, rowCount, ilvls: [ownItemLevel...], rawShard}` per record; NOT a stats re-decode (`f1`/`f2` only are proven - see "Item support tables" below) | small |
| `data/items/statsByItem/_meta.json` | `count`, `provenColumns`, `itemIdJoinRate` (0.9696), `itemIdJoinRateFinding`, `scopeNote` | small |
| `raw/dbc/itemstat/index.json` + `itemstat-<itemId//50000*50000>.csv.gz` | task W4-11b: `ItemStat.dbc`'s own sharded raw dump (1,513,931 rows, 29 non-empty buckets - id-space is highly clustered, not uniform) - **the whole reason this is sharded**: one committed `raw/dbc/ItemStat.csv.gz` would be a 236MB hostile single file (see `dbc.CUSTOM_RAW_DUMP_TABLES`); header names `itemId`/`ownItemLevel` (f1/f2), rest raw `f0`,`f3`..`f38` | large |
| `raw/interface/_manifest.json` | every extracted Interface file: sorted relative path -> `{source, size, sha256}` (1553 files: 1444 archive-sourced + 109 disk-sourced, per the 2026-07-23 capture) | small |
| `raw/interface/AddOns/APIDocumentation/**` | Ascension's own API-documentation addon, copied **verbatim from the live client install** (disk copy, not an archive snapshot - it always wins any path collision against an archive-extracted file) - **their real API**, the ground-truth reference for porting agents; see "Interface/API code layer" below | large |
| `raw/interface/{AddOns,FrameXML,GlueXML,SharedXML,LibraryXML,LCDXML}/**` | every other `.lua`/`.xml`/`.toc`/`.txt`/`.md` file found under the client's `Interface\` tree across every MPQ archive (art/BLPs/sounds/models excluded - this is a code layer, not an art dump); winner per file resolved by the same chain-order rule as the DBCs | large |
| `raw/dbc/*.csv.gz` | full decoded DBC dumps (every column) | large |
| `raw/content/*.json` | verbatim client sidecar JSONs | large |
| `raw/provenance.json` | source hashes, archive resolution, build stats, top-level `headerMismatches` (must contain only the documented allowlist - today exactly one entry, `spellitemenchantmentcondition.dbc` 31 declared vs 16 actual; any NEW entry fails `tests/test_dataset.py` - see "Manastorm + realm overlays" below) | small |
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
| `data/gt/combatRatings.json` | `gtCombatRatings.dbc` (3200 rows = 32 RATING slots x 100 levels, rating-major not class-major - see "gt* combat-rating tables" below): `{ratings: [{index, name, curve: [99 floats, levels 1-99]}]}` - 17 of 32 rating slots pinned to a published WotLK name (`WEAPON_SKILL`/`DEFENSE`/`DODGE`/`PARRY`/`BLOCK`/`HIT_MELEE`/`HIT_RANGED`/`HIT_SPELL`/`CRIT_MELEE`/`CRIT_RANGED`/`CRIT_SPELL`/`CRIT_TAKEN_MELEE`/`HASTE_MELEE`/`HASTE_RANGED`/`HASTE_SPELL`/`EXPERTISE`/`ARMOR_PENETRATION`), the other 15 stay `cr<N>` (including `cr15`/`cr16`, the CRIT_TAKEN_RANGED/SPELL pair that is bit-identical to itself and so NOT individually pinnable - see below) | small |
| `data/gt/classChanceCurves.json` | 8 class-major gt tables keyed by `classId` (1-32, `ChrClasses.dbc` id): `meleeCrit`/`spellCrit`/`regenMPPerSpt`/`octRegenMP`/`regenHPPerSpt`/`octRegenHP` (`{classId, className, curve: [99 floats]}`) + `meleeCritBase`/`spellCritBase` (`{classId, className, value}`, no level dimension, 32 rows each) | small |
| `data/gt/level60.json` | convenience slice: every `combatRatings` rating's + every `classChanceCurves` table's level-60 value only (curve index 59) | small |
| `data/gt/_meta.json` | `counts` per raw gt table, `ratingNames` (the full cr-index-to-name map), `provenColumns`, `goldensReproduced`, `unresolvedRatingIndices`, and the three `caveats` (`gtOCTClassCombatRatingScalar`, `clientCopyMayDifferFromServer`, `armorPenetrationAnomaly`, `level100SlotTrap`) - see "gt* combat-rating tables" below | small |

### Class tab sharding (why three levels, not one)

Most class tabs fit in one file: `data/classes/<Class>/<Tab>.json`. A handful of
Reborn* classes' biggest tabs (e.g. RebornWarlock/Destruction, 728 entries) don't -
even though Tab is the natural semantic key, one file would run 15k-18k lines. (Task
W4-14's per-entry `live`/`liveEvidence` fields added ~5 lines per entry, which pushed
ten more borderline tabs over the gate too - Chronomancer/Duality, Monk/Fighting,
Primalist/Geomancy, Pyromancer/Draconic, Runemaster/Runic, SonOfArugal/Blood,
Stormbringer/Gifts, SunCleric/Seraphim, WitchDoctor/Shadowhunting and Warrior/Fury -
so level 2 is no longer Reborn-only. The cascade handled it with no change; `index.json`'s `files` array is
still the only thing you should enumerate shards from.) The
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
  **account-wide across all four realms**, not scoped to one. Exactly ONE realm ships
  a client-side DBC overlay - Free-Pick's `Data\area-52\patch-D.MPQ` (task W4-13; the
  CoA realms have none in the current `ascension-live` product, and none has ever
  appeared on this install, see "Realm overlays" below) - and
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
- **Talent coverage has three views now - check the right one(s).** Only 12
  classes have DBC `Talent.dbc` talent tabs (`data/talents/<ChrClass>.json`): the
  10 vanilla classes plus Barbarian and WitchDoctor. Every CoA/reborn class drives
  its talents through `CharacterAdvancementData` entries instead - iterate every
  file listed in `data/classes/<Class>/index.json`'s `files` array and look for
  entries with `type == "Talent"` or `"TalentAbility"` (or use the index's
  `entryCounts` to see the type breakdown without opening every shard). If you're
  asked "what talents does class X have" and X isn't one of the 12, `data/talents/`
  (the DBC-tree directory) will have no file for it - that's expected. **Task
  W4-9 adds a third view for the 21 `coa-custom` classes specifically**:
  `data/talents/coa/<Class>.json` carries the actual TREE GEOMETRY (positions,
  prerequisite edges, connectivity, choice-group pairings, per-tab AE/TE gate
  tiers) that neither of the other two views has - `data/classes/<Class>/*.json`'s
  CAD entries tell you an ability EXISTS and its flat cost; only `data/talents/coa/`
  tells you WHERE it sits in the tree and what unlocks it. See "CoA talent tree
  geometry" below before trusting any single field at face value - `isStartingNode`
  in particular is real but extremely sparse (only 2 of 3,618 nodes), so its
  absence on a given node says nothing about whether that node is a tree root.
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
*separate* concept - and a narrower one than this section used to claim.
`Data\area-52\patch-D.MPQ` + its `listarchive` are **Free-Pick's overlay, not "the
realm overlay"**: it is the only realm-scoped data set this product ships *right now*.
The product carries **exactly one realm overlay at a time, and which realm it is has
changed**: the legacy launcher's own installed-file manifest
(`%LOCALAPPDATA%\ProjectAscension\Config\AscensionLauncherSettings-legacy.json`,
written 2026-07-01) lists `\Data\Bronzebeard\listarchive` + `\Data\Bronzebeard\patch-D.MPQ`
and **no area-52 entry at all**; twenty-one seconds after the new patcher logged
`Directory Data/Bronzebeard is on disk but it's not in the database`, it queued the
area-52 pair. So "no CoA overlay" is a fact about this product revision, not a
permanent property of the client - a future revision could ship one, which is why
`discover_realms()` stays generic rather than hard-coding `area-52`.
`tools/config.discover_realms()` finds any `Data\<dir>\` carrying its own
`listarchive` file (excluding the base `enUS`/`Content` dirs) - a generic finder that
correctly returns exactly one name here, `area-52`.

> **Task W4-13: this is settled, not pending.** DATAMINE-REQUEST.md Sec 3 asked us to
> log into Rexxar/Vol'jin so the launcher would "materialize `Data\rexxar\`", then
> diff base vs the CoA overlay. **There is no CoA overlay to capture and no login will
> create one.** Evidence (full write-up:
> `.superpowers/sdd/task-w4-13-realm-report.md`):
> - The launcher's own patcher logs
>   (`%LOCALAPPDATA%\ProjectAscension\Logs\Agent\*.log`) show `Data/area-52/listarchive`
>   and `Data/area-52/patch-D.MPQ` written by `patcher::patch::executor::write_plans`
>   as part of the ordinary product update plan, alongside the base MPQs, on **10
>   separate patch passes**. Across every agent log on this machine the patcher wrote
>   **181 distinct `Data/` paths and exactly 2 realm-scoped ones** - both area-52.
>   The first write is 2026-07-01; the account's first Area 52 *character* dir is
>   2026-07-14. The directory is a **download**, ~2 weeks older than any Area 52
>   login. Login does not create these dirs - the patcher does.
> - The user has played **seven** realms (`WTF\Account\<acct>\`: Area 52 - Free-Pick,
>   Bronzebeard - Warcraft Reborn, Darkmoon - Season 10 Wildcard, Elune - Season 9,
>   **Rexxar - Conquest of Azeroth**, **Vol'jin - Conquest of Azeroth**, Vol'jin -
>   Stress Test), with a Rexxar session on 2026-08-06 proven by
>   `Cache\WDB\enUS\Rexxar - Conquest of Azeroth\*.wdb` (10 files rewritten 11:34:24)
>   and `Logs\connection.log` (`COP_LOGIN_CHARACTER ... result=TRUE`). Six of those
>   seven realms have no `Data\` directory. A whole-install search finds exactly one
>   `listarchive` file, ever.
> - Sec 3's claim that `CustomFunctionChecks.lua`'s realm table supplies the
>   `Data\<dir>` **slug is disproven**: `GlueXML/RealmList/RealmList.lua:161` unpacks
>   that same tuple as `name, expansionID, gamemodeID, **image**, unlocked, page,
>   index, descriptionSpell`, and `GlueXML/RealmMerge.lua:55` uses it as
>   `SetTexture("Interface\\Glues\\RealmList\\"..image)` - it is a background picture
>   (`"Area52"`, which isn't even equal to `area-52`). That table is also dead code on
>   the live client: it sits inside `if not C_RealmSelect then`, a dev fallback, and
>   `Extensions.dll` supplies the real `C_RealmSelect`. So the
>   `"Rexxar - CoA Alpha - Development"` vs `"Rexxar - Conquest of Azeroth"` key
>   mismatch Sec 3 flagged is a non-issue, not a live risk.
> - The engine *does* have a realm data-swap path (`Extensions.dll` is the only binary
>   containing `listarchive`, adjacent to `SetDataPath`, `realmdata`, and an inlined
>   Lua `AscensionRealmHotSwapOverlay` captioned `Switching realm data`) - but the
>   client's guard on it is Area-52-specific by name:
>   `GlueXML/CharacterSelect.lua:1792` is
>   `if HasVisitedArea52ThisSession() and GetRealmId() ~= 11 then` -> *"You must
>   restart your client before entering another realm."* One realm gets a named
>   one-way data latch, and it is Free-Pick.
>
> **Conclusion: CoA realms read the BASE chain, which is what this dataset is already
> built on.** Consequently **the 1,178-row base-vs-area-52 dispute is not a CoA
> authority question at all** - it measures Free-Pick's revision diverging from base,
> so "the overlay disagrees" is not evidence that base is wrong for a CoA character
> (see the overlay-diff subsection below; its numbers are unchanged and still valid,
> only their meaning is corrected).
>
> **Honest limit, unchanged:** client files cannot observe SMSG traffic. If Ascension
> pushes CoA-specific overrides **server-side over the wire**, nothing on disk would
> reveal it, and only an in-game `/dump` on a CoA character can settle that half. This
> task closes the client-file half of Sec 3's question and leaves the wire half open.

- **Chain semantics.** A realm's `listarchive` file lists that realm's own archives
  in load order; the LAST line wins on a filename collision - the identical
  later-wins rule `tools/extract_mpq.py` uses for the base chain, just scoped to one
  realm's small archive set (`tools/extract_realms.py`). area-52's DBCs are an
  OVERRIDE layer the engine can point its data path at **when you play that realm**
  (`Extensions.dll`'s `SetDataPath` + `Switching realm data` hot-swap, task W4-13),
  but this pipeline never merges the two: `work/realms/<realm>/dbc/` and `work/dbc/`
  (and their `raw/` dumps) stay two fully independent layers, one archive set apiece -
  "sits above" describes the client's own resolution order while on Free-Pick, not
  something this extractor performs, and **not** something that applies to a CoA
  session at all (see the W4-13 box above).
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
  `["extract"]["headerMismatches"]`) restores that visibility: every one of the 111
  base `config.WANTED_DBCS` tables where declared and byte-accurate field counts
  disagree is recorded there, and `tests/test_dataset.py` gates that list against an
  explicit, documented **allowlist** - a future base table that starts lying about its
  own header fails this assertion loudly rather than shipping a silently-mismatched
  dump. The allowlist is not empty: task W4-10's canary caught a real one, and
  `raw/provenance.json` ships exactly that single entry today -
  `spellitemenchantmentcondition.dbc`, `declaredFields` 31 vs `actualFields` 16 (see
  the "Simulation-adjacent spell support tables" section for why the 16-column dump is
  the true read). Do NOT widen the allowlist reflexively: a NEW entry means some base
  table's header started disagreeing with its own record size, and the right response
  is to work out which and why. Realm tables are NOT held to that gate at all - a
  realm-side mismatch is expected to happen again and is surfaced instead via the
  per-table `declaredFields` key described above.
- **`missingRefResolution` - what it proves and what it doesn't.** For each bucket in
  the BASE client's `data/spells/_missing_refs.json` (spell ids that base CAD/talent/
  rank chains reference but that are absent from the base, account-wide `Spell.dbc`
  snapshot), this field reports how many of those ids exist as a real row in the
  REALM's own `Spell.dbc` - **id-set membership only**, report-only, no pass/fail
  threshold. Measured on area-52 (re-derived from the shipped
  `data/realms/area-52/index.json`): `cad_other` 178/178 (100%), `cad_reborn`
  7119/7119 (100%), `rank` 603/2810 (21.5%), `formula` 13/182 (7.1%, the bucket task
  W4-4's closure widening added), `talent` 1/13 (7.7%). **Read this carefully before
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
(the live client patches on its own schedule). It is written by `tools/build_gt.py`,
which is wired into `tools/build_dataset.py`'s orchestrator right after the essence
stage - so `python -m tools.build_dataset` regenerates it along with everything else.
(It was NOT wired for most of v4: W4-2 landed before the stage-wiring commits, so an
otherwise-full regeneration silently skipped `data/gt/` and left it on an older client
snapshot. Fixed in the review pass; `raw/provenance.json`'s `buildStats` now carries a
`gt` key, which is what proves the two are on the same snapshot.) Every `gt*` DBC is a genuinely
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

**`RESILIENCE` is never pinned as that literal string** (DATAMINE-REQUEST.md Sec 1.1's
level-60 table lists 85.00 under that label), because in WotLK mechanics the Resilience
gear stat is surfaced through `CR_CRIT_TAKEN_MELEE`/`RANGED`/`SPELL` - `cr14`/`15`/`16`
in the same TrinityCore enum already trusted for `cr0`-`cr24` - not through a dedicated
`CR_RESILIENCE` slot. What that 85.00 anchor *does* buy is `cr14`: its level-60 value is
exactly 85.0 and that value is **unique across all 32 rating slots**, the same
evidentiary tier already used to pin `cr4` BLOCK from a level-60-only match, so
`data/gt/combatRatings.json` ships index 14 as **`CRIT_TAKEN_MELEE`** (17 named ratings
total). `cr15`/`cr16` were held to the same bar and **failed** it: their curves are
bit-identical to *each other* at every one of the 99 curated levels (they diverge only
at the excluded level-100 slot), so nothing distinguishes which is `CRIT_TAKEN_RANGED`
and which is `CRIT_TAKEN_SPELL` - they stay unnamed `cr15`/`cr16` rather than take a
coin-flip, the same discipline applied to `cr20`/`21`/`22`. Both halves are gated in
`tools/build_gt.py` (a uniqueness assert for `cr14`, an equality assert for `cr15`==
`cr16` that fires if a future patch ever splits them) and re-checked fresh in
`tests/test_gt.py`; the full reasoning is in `data/gt/_meta.json`'s
`unresolvedRatingIndices` and `goldensReproduced.cr14CritTakenMelee`.

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

> ### âš  `EffectBonusMultiplier` (f229-231, `effects[].bonusMultiplierStock`) -
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

  > **âš  The `$1s` transposition-typo trap.** The no-trailing-digit widened shape
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

> **âš  The doc's own resolution-rate figure (2,446/5,317 = 46%) does not reproduce
> here** (this build measures 4,893/5,075 = 96.4% resolved, per
> `data/spells/_meta.json`'s `formulaClosure`). Population-independent
> in principle (an id either exists in `Spell.dbc` or it doesn't), so this is most
> likely explained by client content churn between when the doc was authored and
> this snapshot - CoA's dev/test spell ids (the `500000+`/`800000+`/`900000+`/
> `1000000+`+ series that dominate these references) have been observed growing
> steadily across this repo's rebuild history (see "Regenerating after a client
> patch" below). Flagged rather than chased further - re-deriving a stale doc
> figure against a newer live snapshot is expected to diverge.

> **âš  The binder must follow `$mN`/`$sN`-style tokens into ANY effect slot, not
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

> **âš  [INFERRED] gating field - UNRESOLVED, needs an in-game `/dump`.** CAD
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
> a hedge. Track this the same way as the Â§14 in-game probe items already noted
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
tabs Time/Displacement/Duality) was Sec 13 item 20 and stayed explicitly out of
scope and untouched until task W4-11e closed it - see "specs.json vs CAD tabs
reconciliation" below.

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
**Read the result as Free-Pick-vs-base, not as a CoA authority question** (task
W4-13): the numbers below are unchanged and still valid measurements, but since CoA
realms have no client-side overlay at all and read base, "area-52 disagrees with
base on 1,176 rows" says Free-Pick's revision differs - it is not evidence that base
is wrong for a CoA character. See the W4-13 box under "Realm overlays" above.
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
> is authoritative for the disputed rows - stayed out of W4-5's scope, and task
> W4-13 has since **closed** it: there is nothing to capture, the disputed rows are
> Free-Pick's, and base is authoritative for CoA. See "Realm overlays" above).
> Wiring
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
call. W4-5 also flagged a live-client caveat it didn't chase - that `Config.wtf`'s
`"Rexxar - Conquest of Azeroth"` doesn't match `CustomFunctionChecks.lua`'s
`"Rexxar - CoA Alpha - Development"` key. **Task W4-13 chased it and the caveat
dissolves in both directions:** that Lua table is a dev-only fallback
(`if not C_RealmSelect then`) whose 4th field is a glue background texture name, not
a `Data\` slug, so the mismatch was never the mechanism; and the real mechanism is
the launcher's patcher, which ships `Data/area-52/` to every install and has never
written any other realm directory. `discover_realms()` finding only `area-52` after
weeks of CoA play is the **correct** answer, permanently - not a gap. The fixture
test above still earns its keep as a pure unit test of the finder's shape.

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
8. **`ItemStat.dbc`'s `f2` join = 1.000 (against a naive column guess) is a
   dense-id false positive.** **Task W4-11b extracted this table and re-derived
   the trap from scratch** (`ItemStat`/`Item`/`ItemSpells` are no longer absent
   from `config.WANTED_DBCS` - see "Item support tables" below) - the trap's
   SHAPE holds exactly as warned (a naive column, historically misread as the
   item id, produces a suspiciously-perfect join purely because the candidate
   values are low and dense item ids like 1..105 also exist), but the REAL keying
   is now proven, not guessed: `f1` (not `f2`) is `itemId`, golden-verified
   against item 100248 vs `itemcache.wdb`, and `f2` is `ownItemLevel` (the
   75-row-block structure), both now named in `TABLE_MAPS["ItemStat"]`. See
   "Item support tables" below for the full re-derivation - don't trust a bare
   join rate against this table's dense id space for anything beyond these two
   proven columns.
9. **`ItemSpells.dbc`'s `f1` is not the item link.** **Task W4-11c extracted
   this table and confirmed the trap exactly**: `f1` is unique per row
   (131,722/131,722 - structurally cannot be a many-spells-per-item foreign
   key) and only 55.45% resolves against `Item.dbc`; `f2 -> spellId` is the
   well-supported column (99.81% against a 1.50%-dense spell-id space, a real
   join since the target space is sparse, not the dense-id false-positive
   shape trap 8 warns about). Shipped raw + colinfo only, no `TABLE_MAPS`
   entry - see "Item support tables" below.
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

### CoA talent tree geometry (task W4-9)

DATAMINE-REQUEST.md Sec 6.1 / Sec 13 item 11: the CAD entries tell you an ability
*exists*, but not where it sits in a tree, what unlocks it, or what it competes
against. `data/talents/coa/<Class>.json` (21 files, `tools/build_coatalents.py`,
single-writer) closes that gap for all 21 `coa-custom` classes, built from the
published `https://ascension.gg/en/v2/coa-builder/voljin` builder payload (frozen
by `tools/fetch_coatalents.py` into `raw/talents/coa-builder-voljin.html` +
`_fetch.json` - a deliberate, occasional, NETWORK step kept separate from the
offline `build_dataset` pipeline, same relationship as `AddOns/APIDocumentation`
being a verbatim external capture rather than something re-derived). The page is a
Next.js "flight" payload; extraction is a from-scratch analogue of the
`coa-sim-handoff/parsers/aowow.py` Listview trick (locate an anchor, `raw_decode`
past trailing garbage) adapted to `self.__next_f.push([id,"..."])` chunks - see
`tools/build_coatalents.py`'s module docstring for the exact technique.

**The page embeds TWO near-identical copies** of the full node set side by side
(`slug` "voljin-alpha" id 39 and "voljin" id 40 - same 3,618 nodes/ids/geometry,
differing only in tooltip description text). This is why every field name greps to
exactly **7,236** raw occurrences in the fetched HTML, matching the source doc's
own cited count precisely - it is 2 x 3,618, not 7,236 real distinct nodes. This
module uses only the `slug="voljin"` copy.

**Resolve-rate gate: measured against raw `Spell.dbc`, not the curated CAD/spells
join - and this matters.** A literal reading of "payload spellIds vs CAD entries"
(does each node's `spellId` appear in this repo's own captured
`CharacterAdvancementData.json`, or in `data/spells/`) resolves only **~49-53%** -
badly short of 95%. Re-measuring the SAME node set against the raw client
`Spell.dbc` table directly (any row at all, 209,130 total, regardless of whether
any CAD entry references it) resolves **100%** (3,618/3,618, `unresolvedSpellIds:
[]`). This is real, measured **content drift** between the live published builder
and this repo's client snapshot, not a
parse bug: the payload's spell ids are real, valid spells in this exact
client - they are simply not the same spellId *variant* this repo's captured CAD
JSON happens to reference for the same-looking ability (consistent with the W4-8
finding above that CoA abilities get authored as multiple duplicate CAD rows per
realm/game-mode, each potentially carrying a different spellId). Earlier builds of
this dataset reported 99.97% (3,617/3,618) with spellId 301010 "Devourer" as the one
miss; a later client patch added that row (`raw/dbc/Spell.csv.gz` went 209,125 ->
209,130 rows, see `tests/test_sharding.py`'s re-pin log) and the miss is gone. The
figures in `data/talents/coa/_meta.json`'s `contentDrift` prose are now interpolated
from the same computed block they sit beside, so they cannot drift apart again. The
build gates hard on the raw-Spell.dbc figure and ships `spellResolved: false` on every
node whose spellId does NOT resolve against the curated `data/spells/` set, so a
consumer sees the gap per-node instead of it being silently absorbed.

**The 84-vs-72 tab-count tension (recomputed fresh, not taken on faith).** Sec 11's
"84" (4 tabs x 21 coa-custom classes) still holds EXACTLY when recomputed today
from `data/classes/` - zero exceptions, every class still has precisely 1 Class +
3 spec tab-name buckets in this repo's own snapshot. The payload's "72" is a count
of DISTINCT `tabId`s, a different thing entirely: the live builder actually
carries **96** (classId,tabId) assignment pairs (MORE than 84 - 10 of 21 classes
have grown a 5th or 6th tab slot since the local capture), which collapses to 72
distinct ids purely because of numeric-id REUSE - `tabId 87` ("Class") is
literally the same id on all 21 classes' Class trees (21 assignments -> 1 id,
-20), and `tabId 1` ("None", a placeholder)/`tabId 71` ("Blessings") each get
reused once more (-3/-1); 96 - 24 = 72 exactly. Of those 96 pairs, only **5** are
EMPTY placeholders (0 entries: WitchHunter/Guardian/Pyromancer/SunCleric's "None"
slot, Chronomancer's borrowed-but-unauthored "Blessings" slot); the other **5** of
the 10 grown classes (SonOfArugal, Primalist, Venomancer, Starcaller, Cultist)
gained a genuine 5th tab with real, non-empty content (38-44 nodes apiece), not a
placeholder. Cross-checking **all 7** of Sec 11's named "unreleased" specs by
name against the payload (not just 2 of them): **5 have shipped** -
SonOfArugal/FLESHWEAVER -> "Fleshweaver" (44 nodes), SunCleric/VALKYR ->
"Valkyrie" (42 nodes), Primalist/MOUNTAINKING -> "Mountain King" (40 nodes),
WitchHunter/WITCHKNIGHT -> "Black Knight" (38 nodes), Venomancer/VIZIER ->
"Vizier" (41 nodes) all now exist as real, non-empty tabs. Only **2** of the 7
(Starcaller/HYDROMANCY, Cultist/BULWARK) don't appear by a matching tabName -
though those two classes still each picked up a *different*, unnamed-by-Sec-11
extra tab of their own (Starcaller "Warden" 40 nodes, Cultist "Dreadnought" 38
nodes). This is concrete, dated evidence that content shipped between Sec 11's
audit and this fetch, exactly the "external source that drifts" behavior the
task brief warned to expect - see `data/talents/coa/_meta.json`'s
`tabLayerReconciliation.sec11UnreleasedSpecsShipped` for the full per-token
table (a review pass caught a first draft of this section under-checking only 2
of the 7 tokens and wrongly concluding the other 5 classes hadn't grown at all).

**`isStartingNode` is PARTIALLY proven - not simply unreliable.** Only 2 of
3,618 nodes carry it nonzero, but the two are NOT equally trustworthy. Node 7608
(Cultist "Abyssal Ward", `isStartingNode: 1`, empty `requiredIds`) **is** a real
tree root exactly as the brief's suggested golden expects: two sibling nodes -
4040 "Obliteration" and 7512 "Dreadnought" - directly list `7608` in their own
`requiredIds`. The golden HOLDS for this entry (verified by re-parsing the raw
payload independently, not just trusting a prior claim about it). The other
nonzero entry, node 30212 (SunCleric "Hope", `isStartingNode: 127` - not a 0/1
boolean, a genuine data anomaly), is unreferenced by anything - that specific
value is the actual anomaly, not the flag's whole concept. Separately, and not a
contradiction: 96.5% of nodes (3,493/3,618) have an EMPTY `requiredIds` (far more
than the 2 flagged nodes) - CoA's trees are gated primarily by `reqTabAE`/
`reqTabTE` per-row investment thresholds (see the gate-split paragraph below),
not a classic Blizzard prerequisite chain rooted at one flagged starting node -
`requiredIds` only gates a small minority (171 nonzero refs) of nodes at all, and
`isStartingNode` marks only 1 of them. Net: real and correctly wired where
present, just far too sparse to be the general "is this a tree root" signal on
its own - `requiredIds == []` is the broader structural proxy for that.

**`reqTabAE` gates the Class tree; `reqTabTE` gates every spec tree - a clean
split, confirmed against the client's own XML wiring, not an inferred pattern.**
`reqTabAE` is nonzero ONLY on `tabId 87` ("Class", shared by all 21 classes) -
tiers step 0 -> 9 -> 24 by row there. `reqTabTE` is nonzero on **every spec tab**
(tiers step 0 -> 8 -> 23 by row, confirmed on every spec tab checked) and sits
flat at 0 on the Class tab - the *opposite* pattern, not "AE/TE both only live on
the Class tree." `raw/interface/AddOns/Ascension_CoATalents/CoATalentFrame.xml`
proves this by construction: the `$parentClassTree` frame (`parentKey="ClassTree"`)
wires `getEntryGateRequirement` to `CoACharacterAdvancementUtil.
GetEntryAEGateRequirement` and `gateCurrencyCount` to `C_CharacterAdvancement.
GetPendingTabAEInvestment`; the sibling `$parentSpecTree` frame
(`parentKey="SpecTree"`) wires the TE equivalents
(`GetEntryTEGateRequirement`/`GetPendingTabTEInvestment`) instead - the client
assigns AE to the Class tree and TE to the Spec tree in the XML itself, not just
in this dataset's numbers.

**Choice groups are a real, clean structure.** Every nonzero `group` value pairs
EXACTLY 2 entries (0 exceptions across 292 groups), always sharing identical
`(classId, tabId, x, y)` and differing only in `spellId`/`name` - the client's
choice-node concept (`CoACharacterAdvancementUtil.GetDisplayTemplateForEntryChoice`
/ `CoATalentChoiceButtonTemplate`; `node:IsChoiceNode()` in
`GetGateLeftAttachmentPoint`/`GetGateRightAttachmentPoint` bundles alternatives at
one shared visual anchor). `data/talents/coa/<Class>.json`'s `choiceGroups` array
surfaces this directly so a consumer doesn't have to re-derive it from raw
`group` values.

**The base CAD JSON's own geometry-shaped columns are a false friend, not a
fallback.** `CharacterAdvancementData.json` also carries `PositionX`/`PositionY`/
`ConnectedNodes`/`RequiredIDs`/`RequiredAEInvestment`/`RequiredTEInvestment`
columns (13-15% row coverage, no numeric tabId at all - `Tab` is a bare string).
Investigated as a possible client-Lua-only fallback source (per the task's binding
rule for a failed fetch) and rejected: for the 2,851/3,618 payload nodes whose `id`
DOES match a CAD row, agreement is near-zero (exact PositionX/Y match on only a
small minority; ConnectedNodes average Jaccard similarity ~0.02) - these raw CAD
columns serve the client's narrower "ConnectingNode" decorative-line UI
(`raw/interface/FrameXML/Data/CharacterAdvancement.lua`'s
`CHARACTER_ADVANCEMENT_NODES` population rule), a different thing from gameplay
tree geometry despite the matching field names.

**Realm caveat.** This is the Vol'Jin builder specifically. Rexxar - Conquest of
Azeroth is a separate CoA realm; its geometry is **assumed identical but
unverified** until a Rexxar capture exists. NB: the capture meant here is a fetch of
the Rexxar **web builder payload** (`ascension.gg/v2/builder/coa/...`) - it is a
different, still-open thing from Sec 13 item 7's client-side `Data\rexxar\` capture,
which task W4-13 closed as impossible (no CoA realm has a client data directory - see
"Realm overlays"). Full evidence, goldens, and re-derivation log:
`.superpowers/sdd/task-w4-9-report.md`.

### Simulation-adjacent spell support tables (task W4-10)

`WANTED_DBCS_V5` adds 12 tables from DATAMINE-REQUEST.md Sec 9 + Sec 13 items
13/17: `SpellAffect`, `SpellDifficulty`, `SummonProperties`, `SpellMissile`,
`SpellShapeshiftForm`, `SpellFocusObject`, `SpellRank`, `CreatureSpellData`,
`GlyphProperties`, `GlyphSlot`, `SpellStatSuggestions`,
`SpellItemEnchantmentCondition` - all 12 confirmed present in the live MPQ chain
(`extract_mpq.extract_all()` raises `SystemExit` on any wanted name missing from
every archive; it didn't). All 12 get `raw/dbc/<Table>.csv.gz` +
`<Table>.colinfo.json` evidence; only three got curation attention, per the
task's explicit scope:

**`SpellAffect` - Sec 9's provenance question is now RESOLVED: CONFIRMED.** Sec
9's own text carries the adversarial verifier's explicit refusal to confirm it
("I did not re-extract [SpellAffect.dbc]... treat its unverified assertions as
unconfirmed"). This task re-extracted fresh (2026-08-06) and independently
re-ran every numeric claim in that subsection - every one reproduced, with two
honest caveats (see `tools/dbc.py`'s `SpellAffect` TABLE_MAPS comment for the
full log):
- f1â†’Spell.dbc join 100.0000%, |f2| join 99.9973% (one row's abs value doesn't
  resolve - the doc's own "100.0%" was a rounding, not literal), raw unsigned f2
  join 93.4528%, negative f2 rows 2,407/36,779 exactly.
- All 3 goldens reproduce (324â†’978816, 2565â†’47294-6); the third (12043â†’Blizzard/
  Hailstorm) reproduces the SEMANTIC finding but the doc's quoted id range
  (81328-81332) is narrower than what's actually on disk (81328-81336 plus a
  second 281800-281808 block the doc never mentions) - a transcription gap in
  the source doc, not a re-derivation failure.
- CoA-coverage-is-low: f1 hits = 5, |f2| hits = 10 - EXACT match, though the
  denominator (CoA spells carrying the modifier aura) measured 1,269 fresh vs
  the doc's 1,295 (ordinary content drift, same class as this build's own
  Spell.dbc row-count drift).
- Id-band overlap (f1 âˆ© vanilla-tagged=209, âˆ© reborn-tagged=277,
  âˆ© coa-custom-tagged=5) and the 158/10,684 CoA-band |f2| count both reproduce
  EXACTLY. **Verdict unchanged from Sec 9's own framing: it is genuinely
  Bronzebeard/Area-52 legacy content, not a CoA table** -
  `EffectSpellClassMask` (task W4-3) remains the primary CoA talent-targeting
  channel. `id`/`spellId`/`affectedSpellId` are now named in TABLE_MAPS.

**`SpellStatSuggestions` - the Sec 5.2 "cheap win" partially pans out.** f1
(spellId) is proven: 99.91% join vs live Spell.dbc ids, and row id=1 decodes to
`(1, 10, 3, 1)` - an exact match to Sec 5.2's own cited sample ("spell 10 is
Blizzard"). f2 (4 values: 0/1/3/4) CORRELATES 73.5% with a primary-stat category
(0=STR/1=AGI/3=INT/4=SPI, found by testing all 24 permutations against
`raw/content/SpellToStatSuggestionData.json`'s per-spell dominant stat score
over their 1,078-spell overlap) - real signal, well above the 25% random
baseline, but short of this repo's naming bar. f3 is a constant 1 on every row
- zero information. Shipped standalone at `data/spells/statSuggestions.json`
(spellId proven, so the file exists; payload category kept as raw
`statCategoryRaw`, explicitly flagged unconfirmed in the file's own `_note` -
see `tools/build_spells.py`'s `_build_stat_suggestions()`), NOT attached to
`spells.jsonl` records.

**`SpellRank` vs the already-integrated `raw/content/SpellRankData.json` - NOT
identical, and the DBC is the more complete of the two.** `SpellRankData.json`
(13,311 rows: `firstSpellId`/`level`/`rank`/`spellId`) is what
`build_spells.py`'s closure/`rankChain`/`rankAt60` logic already reads - this
task did not change that. `SpellRank.dbc` (23,182 rows, columns proven:
`firstSpellId` 100% join, `spellId` 99.98% join, `rank` range 1-25 matching the
JSON's own field) overlaps the JSON on 9,945 spellIds (`firstSpellId` agrees
99.56%, `rank` agrees only 94.32% - of the 565 mismatches, `+1` is the largest
single bucket but only 47.1% (266/565); `+2`..`+8` account for another 49% and a
handful of negatives (`-1`/`-2`/`-5`, 16 rows) and a `+9`..`+14` tail (6 rows) make
up the remainder, so this is NOT a clean off-by-one - unexplained, left as an open
finding) but additionally carries **13,237 spellId rows the
JSON does not have at all**, 99.96% of which are real, live Spell.dbc ids - i.e.
meaningfully more rank-chain coverage than what the pipeline currently uses.
The JSON in turn carries 3,366 rows absent from the DBC (the already-documented
"stale orphan rank chains"). Columns are named in TABLE_MAPS for raw-dump
clarity only (same precedent as `SpellCharges`/`SpellChargesCategory`) -
**deliberately NOT wired into `build_spells.py`'s pipeline by this task**;
`SpellRankData.json` remains the single source of truth for rank chains until a
dedicated task re-derives every downstream pinned count against the richer DBC
source. See the Honest limits entry below and
`.superpowers/sdd/task-w4-10-report.md` for the full re-derivation log.

The other 9 tables (`SpellDifficulty`, `SummonProperties`, `SpellMissile`,
`SpellShapeshiftForm`, `SpellFocusObject`, `CreatureSpellData`,
`GlyphProperties`, `GlyphSlot`, `SpellItemEnchantmentCondition`) ship raw +
colinfo only - explicitly out of this task's curation scope. One flag found in
passing: `SpellItemEnchantmentCondition`'s WDBC header **declares 31 fields**
(the real stock-WotLK 1+5Ã—6 operand-condition shape) but its `record_size` only
supports **16** - `extract_mpq.py`'s `headerMismatches` caught this on a BASE
table for the first time (previously only ever seen on realm-overlay tables,
see `DBCFile`'s docstring); `DBCFile.fields` (record_size//4) is what this
pipeline trusts for row layout, so the 16-column raw dump is a true read, not a
mistake - left unmapped rather than guessing which 16 of the stock 31 survived.

### Item support tables (task W4-11)

`WANTED_DBCS_V6` adds 9 tables from DATAMINE-REQUEST.md Sec 8.1 + Sec 13 item 14:
`Item`, `ItemSet`, `SpellItemEnchantment`, `GemProperties`,
`ScalingStatDistribution`, `ScalingStatValues`, `RandPropPoints`,
`ItemRandomSuffix`, `ItemRandomProperties` - all confirmed present in the live MPQ
chain (2026-08-06 extraction). **No curation this task's first sub-commit** - every
one ships `raw/dbc/<Table>.csv.gz` + `<Table>.colinfo.json` only, same as any other
unmapped table. Per the brief, the sim's **primary** item source stays an external
`db.ascension.gg` (aowow) scrape validated against `itemcache.wdb` - this pipeline's
job is completeness/evidence, not owning item acquisition (Sec 8's own framing).

**`Item.dbc` is an INDEX, not a stat source** - re-derived directly from its own
colinfo, not just asserted from the doc: 563,335 rows Ã— 8 fields, **zero-length
string block** (`string_block_size: 0`), every column's `samples` empty (nothing
string-like at all). `f0` (the id) is unique per row and its max (9,200,842)
reproduces Sec 8.2's own cross-reference ceiling exactly. Shape matches the doc's
named ordering (`id, class, subclass, soundOverrideSubclass, material, displayid,
inventoryType, sheath`) - `f5` (displayid) is the only other high-cardinality column
(90,622 distinct), consistent with "the authoritative equippable-id and displayid
index." None of these 8 columns are named in `TABLE_MAPS` yet (out of this
sub-commit's scope) - a future task can pick this up with the same golden-proof bar
as everything else in this file.

**`ScalingStatDistribution`/`ScalingStatValues` are extracted for completeness,
NOT because they are load-bearing for CoA.** Re-measured fresh against
`itemcache.wdb` via `tools/wdb_item.py` (same parse as the ItemStat golden below):
of 15,822 equippable items (`inventoryType != 0`), only **126 have
`scalingStatDistribution != 0` (0.8%)** - an exact reproduction of Sec 8.1's own
cited 126/15,822 figure - while 11,962 (75.6%, also an exact reproduction) carry
explicit `statsCount > 0` instead. **This contradicts an earlier research claim**
that "Ascension ships level-scaling gear whose stats are not fixed on the item row;
a sim must resolve scaling items at the character's level" - level-scaling gear is
a real but marginal mechanic here, not the norm. Per Sec 8.1, this disagreement is
still only measured, not fully reconciled - **one confirming check remains open**
(why the earlier claim was made at all, e.g. a different content patch or a
misread of a different scaling system).

`ItemStat.dbc` and `ItemSpells.dbc` are deliberately **excluded** from
`WANTED_DBCS_V6` - both need real investigation (keying traps, in `ItemStat`'s case a
236MB raw body too large for a single `raw/dbc/` file) before any column gets named;
see the sub-sections below (added incrementally as this task's remaining
sub-commits land).

**`ItemStat.dbc` (task W4-11b) - Sec 8.2's `f1`/`f2` keying hypothesis is now
PROVEN, independently re-derived, not copied from the doc.** `WANTED_DBCS_V7` adds
this one table (1,513,931 rows x 39 fields, no strings). Sec 4 trap 8 warns that a
PRIOR audit misread this table's keying (mistaking `f0`, a unique monotonic row id,
for the item id - a naive join against `Item.dbc`'s low, dense ids "proved" the
wrong column). This task re-derived the correction from scratch:

- **The golden.** Item 100248 ("Beaststalker's Belt") decoded independently from
  `E:\ascension-live\Cache\WDB\enUS\itemcache.wdb` (8,393,618 bytes - byte-identical
  to the source doc's own cited size, confirming the same client snapshot) via a
  fresh `tools/wdb_item.py` parse (copied from `coa-sim-handoff/parsers/wdb_item.py`
  with attribution, see that file's header comment): `itemLevel=61 armor=277
  stats=[(3,13),(5,8),(7,9),(31,10),(38,17)]`. The `ItemStat.dbc` row with `f1=100248
  f2=61` gives `armor(f27)=277` and stat pairs `[(3,13),(5,8),(7,9),(31,9),(38,17)]` -
  **armor exact, 4 of 5 stat pairs exact, statType 31 ("hit") off by exactly 1** -
  reproducing Sec 8.2's own claim verbatim. The `f2=60` row (`armor=271`, stats
  roughly halved) does **not** match - confirming `f2` is a real per-row axis.
- **The row-block structure** is the primary proof, stronger than any join rate:
  item 100248 carries exactly 75 `ItemStat` rows, and the table-wide distinct-`f2`
  set is exactly 75 values (dense 1-65, then sparse `{86,88,91,94,96,98,99,101,103,
  105}`) - an EXACT match to Sec 8.2's cited set. The per-item row-count histogram
  (`{75: 20171, 11: 48, 12: 44, 13: 2, 16: 1, 8: 1}`, summing to exactly 20,267
  distinct `f1` values) also reproduces the doc's own histogram exactly.
- **The join rate** (19,651/20,267 = 96.96% of distinct `f1` values resolve against
  live `Item.dbc` ids, max `f1` 9,200,579 vs `Item.dbc`'s own max id 9,200,842) is
  corroborating context only, **not** the proof - `Item.dbc`'s id space is only ~6%
  dense, precisely the Sec 4 trap 8 false-positive shape this table already burned
  a prior audit on once.

`TABLE_MAPS["ItemStat"]` now names `itemId` (f1) and `ownItemLevel` (f2) only - the
letter's explicit scope. `f3`-`f38`'s documented layout (10 interleaved stat-type/
value pairs, float damage min/max, armor, a level-counter/price ramp) was used only
to CHECK the golden above, never independently named; a future task can pick up
`statType`/`statValue`/`armor`/`damage` naming with the same golden-proof bar.

**Sharded raw dump + curated coverage index** (`tools/build_items.py`, new module):
`raw/dbc/itemstat/itemstat-<itemId//50000>.csv.gz` (29 non-empty buckets - item ids
cluster hard, the `[2,050,000, 2,100,000)` band alone holds 60% of all rows, so
shard sizes are uneven by design, not a bug) replaces the single 236MB file every
other table gets (`dbc.CUSTOM_RAW_DUMP_TABLES` - `dbc.dump_all()` skips `ItemStat`
entirely; this module owns its raw evidence). `data/items/statsByItem/` is a
**coverage index**, not a stats re-decode: `{itemId, rowCount, ilvls: [...],
rawShard}` per item, bucketed at **5,000** ids (narrower than the raw layer's
50,000 - the same item-id clustering that makes shard sizes uneven would blow the
`data/` 5,000-line gate at 50,000-wide curated buckets; empirically the narrowest
raw-id band alone holds 12,165 distinct items). `build_items.py`'s own golden gate
(the 100248 75-row check + the exact histogram, both re-derivable from
`work/dbc/ItemStat.dbc` alone) mirrors `build_creatures.py`'s "refuse to publish if
the pinned facts don't hold" convention - the `itemcache.wdb` cross-check that
originally PROVED the keying stays a test-time-only dependency
(`tests/test_items_layer.py`), not a build-path one, matching how every other
external-ground-truth golden in this pipeline is used once to establish a
`TABLE_MAPS` entry and then trusted, not re-fetched on every build.

**`ItemSpells.dbc` (task W4-11c) - Sec 4 trap 9 CONFIRMED, re-derived, raw+colinfo
only.** `WANTED_DBCS_V8` adds this table (131,722 rows x 37 fields, no strings).
The trap: a naive reader could mistake `f1` for the item-link column, since it's the
lowest-index candidate and looks id-shaped. Re-derived fresh:

- **`f1` is unique PER ROW** (131,722/131,722 distinct) - structurally it CANNOT be
  a many-spells-per-item link column (an item with several attached spells would
  need `f1` to repeat), and its join against live `Item.dbc` ids is weak: 55.45%
  (doc: "only 55%"; matches at doc precision). **Not the item link.**
- **`f2` -> spellId IS well-supported**: 99.81% (131,467/131,722, exact match to the
  doc's cited figure) against a spell id space measured at 1.50%-dense (209,130 live
  ids over a much larger id ceiling) - a join rate this high against a SPARSE space
  is real signal, not the dense-id false-positive shape Sec 4 trap 8 warns about
  elsewhere in this same section.
- No column in this table represents the item the spell is attached to (same "no
  identity-grouping column" shape as `NPCTrainer`, see `build_creatures.py`'s
  `trainerIdFinding`) - it is presently unusable for an item-level spell lookup.

Shipped **raw + colinfo only**, no `TABLE_MAPS` entry - this letter's explicit
scope is documenting the trap and verifying the claims, not curation.

**`ItemVariationData.json` join design (task W4-11d) - a design doc, not an
implementation.** `analysis/itemvariation-join-design.md` documents the mapping-
rule evidence behind Sec 8.3's ask (joining a scraped aowow variant item id back to
its base item), re-derived fresh against the already-shipped
`raw/content/ItemVariationData.json` (10,830 rows, `{Normal, Heroic, Mythic[40],
Bloodforged}`, no item names - a pure id-to-id table). Headline finding:
**`Bloodforged` has a clean, dominant `+6,000,000` offset from `Normal` (95.5% of
matched rows) - safe to treat as a rule; `Heroic`/`Mythic` do NOT** (their dominant
`+300,000`/`+200,000` clusters cover only ~23% each, the rest scatters across dozens
of smaller non-round clusters - ordinary content-patch history, not a decode
failure, meaning a real implementation needs `ItemVariationData.json` as a literal
lookup table, not an arithmetic formula). The doc also reports an honest gap: the
source doc's cited "+1,600,000 for Prestigious" offset was searched for
exhaustively (every `Normal`-vs-variant delta, all 10,495 matched rows) and **not
found** - flagged as unverified-by-this-task rather than silently dropped, since
this file carries no item names to confirm or deny an aowow-side label against.
Cross-referenced against this task's own new `Item.dbc`/`ItemStat` tables:
`Normal`/`Heroic`/`Bloodforged`/`Mythic[0]` resolve 98-100% against live `Item.dbc`
ids, but only 13.3% of `Normal` ids have `ItemStat` coverage - consistent with Sec
8.2's "not a primary CoA source" verdict.

**Live vs catalog: `live` / `liveEvidence` on every CAD entry (task W4-14).**
`data/classes/` is the CAD **catalog** - what the client's character-advancement
tables LIST for a class. It is not the game, and reading it as if it were is the
single most expensive mistake a consumer of this dataset can make. A real level-60
Starcaller proved the gap: the catalog ships a whole `Tides` tree (Tide Lash,
Silvercurrent, Pond, Deluge, Geyser) that **does not exist in game**; that
character's real trees are Moon Guard / Sentinel / Moon Priest / Warden / Class -
exactly what the live talent-builder capture (`data/talents/coa/`, task W4-9) says.

Every entry now carries the verdict:

| field | meaning |
|---|---|
| `live: true` + `liveEvidence.reason: "liveDirect"` | one of the entry's own spell ids IS a live builder node's spell (`matchedSpellId`, `builderTab`, `builderNodeId` name the hit) |
| `live: true` + `"liveViaRank"` | no own id matched, but another rank of the same `SpellRankData` chain did |
| `live: false` + `"deadCatalog"` | not in the live trees by any rank, and **no evidence of any other acquisition path** - treat as cut/legacy content |
| `live: null` + `"indeterminate"` | not in the trees, but carries a non-tree acquisition signal (`liveEvidence.signals`) - see the false-negative measurement below |
| `live: null` + `"unknownNoGeometry"` | the class has no builder capture at all (the 10 vanilla + Reborn/meta dirs) - nothing is claimed either way |

Repo-wide (re-derived at every build, mirrored into `data/classes/_live_summary.json`
and each class's `index.json` as `liveCounts`): **3,417 liveDirect + 6 liveViaRank,
3,518 deadCatalog, 1,390 indeterminate, 15,378 unknownNoGeometry** of 23,709 entries.
Restricted to the 21 classes that HAVE a builder capture: 8,331 entries, of which
**4,908 (58.9%) are not in the live trees at all**. Starcaller alone: 53.1% of its
distinct CAD spell ids appear in no live node.

Matching is **spell-id equality only** - no name matching enters the verdict itself.
`live` counts only direct hits; entries with `live == true` are `live + liveViaRank`;
`unknown` merges the two `live: null` reasons so the four `liveCounts` keys sum to
`entryCount`. The rule lives in `tools/coa_live.py` and is imported by both writers
(`build_classes` owns `data/classes/**`, `build_coatalents` owns
`data/talents/coa/**`) so neither can drift from the other.

**Scope, and it is a real one:** the capture is the **Vol'jin** builder. Rexxar -
Conquest of Azeroth is a separate CoA realm assumed identical but UNVERIFIED, and
`data/classes/` entries are account-wide across four realms - so a Rexxar-only
ability is indistinguishable from dead content by this method. Provenance (capture
date + sha256) travels in `_live_summary.json.payload`; re-run
`tools/fetch_coatalents.py` and diff the sha256 to check for drift, because a stale
capture makes `live` stale too.

**The false-negative risk was MEASURED, not hand-waved.** The builder payload shows
the TREES; anything CoA grants outside a tree would look dead while being live. Three
probes were run over the 4,908 not-in-trees entries and every one is written up in
`_live_summary.json.falseNegativeMeasurement`:

- **`skillLineAutoGrant`** - 183 entries (3.7%). `SkillLineAbility.acquireMethod != 0`,
  i.e. automatically granted. **Separable and trustworthy**: `acquireMethod` is stock
  3.3.5 semantics, generation-independent, and perfectly disjoint from the live node
  set (0 of the live builder's spell ids carry it). The population is overwhelmingly
  weapon/armour proficiencies (Fist Weapons, Polearms, Plate Mail, Dual Wield, Auto
  Shot, Block, Staves, Wands) - exactly the "baseline, not via a tree node" class.
- **`npcTrainerRow`** - 1,022 entries (20.8%). **Real but NOT separable offline**, said
  plainly rather than guessed: `NPCTrainer.dbc` in this snapshot is provably
  CONTEMPORARY with the live generation (it carries rows under skill lines that exist
  ONLY in the live builder and nowhere in the CAD tab layer - "Moon Guard", "Moon
  Priest", "Warden", "Headhunting" - teaching rank variants of abilities whose base
  rank IS a live node, e.g. Starcall). So a trainer row is evidence of a non-tree
  path, but the CAD row hanging off it can equally be a retired duplicate.
- **`liveNodeNameTwin`** - 324 entries (6.6%). The entry's NAME matches a live node in
  the same class while none of its spell ids do: the spellId-variant drift already
  measured in `data/talents/coa/_meta.json`'s `contentDrift`. The ability is live;
  whether THIS row is the live variant is unknowable offline.

Union: **1,390 entries (28.3% of not-in-trees) ship `live: null` / `"indeterminate"`
with their firing signals listed, rather than being guessed `false`.** The remaining
3,518 carry no acquisition evidence of any kind and are the honest `live: false`.
The task's first suggested heuristic - "low `requiredLevel` + `type == Ability`" - was
tested and **REJECTED by measurement**: it fires on 28.4% of not-in-trees entries but
also on 16.9% of PROVEN-live ones, so it has no specificity and is used in no verdict.

**CAD tab names and live tab names are DIFFERENT GENERATIONS** of the same tree slots
(Starcaller CAD `Tides` is live `Moon Priest`; Barbarian `Tactics` is `Headhunting`;
Chronomancer `Time` is `Artificer`). All 84 CAD (class, tab) pairs map onto a live tab
in `_live_summary.json.tabMapping`, each pair carrying its method and its evidence:
**58 by `chrSpecsSpecName`** (a `ChrSpecs` row whose `tabToken` IS the CAD tab and
whose `name` IS the live tab - the client's own row linking the two generations) and
**26 by `sameName`**; `nodeOverlap` (where a CAD tab's live-matched entries actually
land) is available as a third method and is run on every pair anyway as an independent
cross-check - **80/84 agree (95.2%)**, and the 4 that do not are recorded with their
counts, not resolved away. 9 live tabs have no CAD ancestor at all: the genuinely new
trees (Warden, Fleshweaver, Valkyrie, Mountain King, Vizier, Black Knight, Dreadnought)
plus the empty `None`/`Blessings` placeholders.

**specs.json `tabStatus` re-derived and RENAMED (task W4-14) - Sec 11 / Sec 13 item
20, closed properly.** W4-11e's states were misleading in exactly the way described
above: `"live"` meant only "a CAD tab with this token exists" - a claim about the
catalog, not the game - and 93/101 specs carried it, **including Starcaller/TIDES**.
The states now name what they assert:

| status | meaning | count |
|---|---|---|
| `inLiveBuilder` | the spec's tree IS in the live builder; `liveTab` names it and `renamed: true` flags a live name differing from the CAD one | 70 |
| `cadOnly` | the tree exists ONLY in the catalog - no live tab maps to it (the state the old `"live"` was hiding) | 0 today |
| `unreleased` | named by neither layer | 0 today |
| `noLiveGeometry` | class has a CAD tab layer but no builder capture - liveness NOT claimed | 30 |
| `noCadClass` | class has no `data/classes/` directory at all (Hero, classId 10) - structural | 1 |

**25 of the 70 `inLiveBuilder` specs are `renamed: true`** - a consumer browsing
`data/classes/` would have found a different tree name than the player sees. The
match ladder tries `ChrSpecs.name` BEFORE `tabToken`, because `name` is the
live-generation label and `tabToken` is the catalog-generation one: spec 33 is named
"Artificer" with `tabToken: "TIME"`, while the live tab literally named "Time" is a
DIFFERENT tree (spec 31, `tabToken: "DISPLACEMENT"`) - token-first silently swaps
them. That same mechanism retires Sec 11's "7 of 70 specs have no CAD tab" list
entirely: all 7 resolve by spec name, including VALKYR -> "Valkyrie" and WITCHKNIGHT
-> "Black Knight" (which no normalized token match reaches) and the 2 that task W4-9
recorded as `unmatchedExtraTabs` but could not attribute - HYDROMANCY is Starcaller's
live "Warden" (spec 45's own name) and BULWARK is Cultist's "Dreadnought" (spec 96's).
W4-11e's pinned 5-token table is gone; this is a mechanism, not a list.

`build_classmeta.py` READS the mapping from `_live_summary.json` rather than
re-deriving it (Amendment D single-writer), so `build_classes.build()` must run
before it - both are asserted at build time. Gated by `tests/test_live_flags.py`
(schema, count consistency, the Starcaller ground-truth pins, the false-negative
measurement, tab-mapping injectivity, and the `tabStatus` states).

**Pipeline ordering (task W4-11e, still current)**: `build_classmeta.build()`
requires `data/talents/coa/_meta.json` and `data/classes/_live_summary.json` to
already exist (hard `assert`s), so `build_dataset.py` runs `build_coatalents.build()`
right after `build_classes` - BEFORE `build_talents`/`build_dungeons`/
`build_creatures`/`build_classmeta` (it previously ran near the end, after `mythic`).
Content-neutral for `build_coatalents` itself (its only real dependencies,
`data/classes/` and `data/spells/`, are unaffected by where `talents`/`dungeons`/
`creatures`/`classmeta`/`essence`/`mythic` fall in the stage list) - re-verified by a
full `build_dataset.run()` pass producing identical `coatalents` stats before and
after the move.

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
  the numeric id is always authoritative. To check where any single label came
  from - or why a given id was left numeric - read
  `data/spells/_enum_evidence.json`: it carries per-id `{bucket, confidence,
  name, goldenSpells, occurrences}` for all 224 classified ids, and every named
  entry names at least one golden spell you can pull from `data/spells/` and
  verify by hand. Only its 57 `confidence: verified` entries are wired into
  `tools/enums335.py`; the 2 `[INFERRED]` names are recorded there but
  deliberately NOT wired, so a numeric fallback in the data never silently
  becomes a guess.
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
  see the file map above. **Task W4-11f investigated the gap and closed the
  question, though not the join itself**: every one of the 46 base-non-joining refs
  resolves as a real, live id in the area-52 realm-overlay's own `Spell.dbc`
  (`raw/realms/area-52/dbc/Spell.csv.gz`, 46/46 = 100%, re-derived fresh each build
  via `tools/build_spells.py`'s `_charges_realm_check()`) - **zero are dead**. This
  is real content-availability (the four-realm/account-wide-CAD split, same shape
  as the `missingRefResolution` finding elsewhere in this file), not orphaned
  garbage - but per the brief's own rule, only PROVEN-DEAD refs are a legitimate
  exclusion for the attach bar, and a realm-overlay id is real content in a
  different id space by design, not evidence the base ref is wrong. With 0 refs
  provably dead, the adjusted join rate is identical to the base measurement
  (0.885) - still below 0.90, so `charges.json` stays standalone. The full
  per-realm breakdown lives in `charges.json`'s own `realmGapFinding` key (also
  summarized in `_meta.json`'s `enrichment.charges.realmGapFinding`), and each
  non-joining row now carries `realmResolvedIn: [realm names]` inline.
- **`data/talents/coa/` is Vol'Jin-only, and only ~53% of its nodes join
  `data/spells/`.** See "CoA talent tree geometry" above for the full writeup -
  Rexxar geometry is assumed identical but unverified, and the low curated-spell
  join rate is real measured content drift between the live published builder and
  this repo's client snapshot (100% of the same spellIds DO exist in raw
  `Spell.dbc`, just not always as the same variant this repo's CAD closure
  reached), not a join bug. Check `spellResolved` per node before assuming a
  tooltip's numbers are backed by this dataset's own spell enrichment.
- **`SpellRank.dbc` is NOT wired into the rank-chain pipeline, and it has MORE
  coverage than `SpellRankData.json`, which is.** Task W4-10 found this table has
  13,237 spellId rows (99.96% real, live ids) that `raw/content/SpellRankData.json`
  - the file `build_spells.py`'s closure/`rankChain`/`rankAt60` logic actually reads
  - does not carry at all, plus an unexplained `rank` disagreement on 5.68% (565)
  of the 9,945 spellIds the two sources share - NOT a clean off-by-one (`+1` is
  only 47.1% of the 565 mismatches; `+2`..`+8` plus a few negatives make up the
  rest). Re-deriving the
  pipeline against the richer DBC source would change downstream pinned counts
  dataset-wide and was out of this CONFIG-EDIT task's scope - see "Simulation-
  adjacent spell support tables" above for the full comparison.
- **`data/spells/statSuggestions.json` ships with an unproven payload column.**
  `SpellStatSuggestions.dbc`'s `spellId` key is proven (99.91% join + an exact
  golden match), which is why the file exists at all, but its `statCategoryRaw`
  value is NOT: it correlates 73.5% with a primary-stat category when
  cross-validated against `SpellToStatSuggestionData.json`, short of this repo's
  naming bar - carried raw, flagged unconfirmed in the file's own `_note`, not
  attached to any `spells.jsonl` record. See "Simulation-adjacent spell support
  tables" above.
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
- `tests/test_sharding.py`: pins the pre-shard record-count baseline (spells 28951,
  per-class entry counts, dungeons 431) so sharding can't silently drop/duplicate
  records; also the repo-wide <=5,000-line gate (empty allowlist today - re-add an
  entry here and in the allowlist if content growth ever forces one). That spells
  pin has been re-derived repeatedly as the client patched and as task W4-4's
  formula closure widened the writer's output (27432 committed -> 27441 -> 27439
  -> 27470 -> 27475 -> 28951); `test_sharding.py`'s own header carries the dated
  log of every re-pin and why
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
  27516, category 6262, customAttr 8124, descriptionVariables 1349, addon 144,
  overrideData 6, across all 28951 referenced spells - re-derived from the shipped
  `data/spells/_meta.json`'s `enrichment` block). These enrichment counts drift
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
  `newSpellCount` is gated loosely (>10000, measured 31497) rather than pinned exactly,
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
- `tests/test_coatalents.py` (task W4-9): 21 classes / 3,618 nodes / 292 choice
  groups pinned against the frozen `raw/talents/coa-builder-voljin.html` capture -
  these will only drift if that capture is refreshed via
  `tools/fetch_coatalents.py` (a deliberate, separate step, not part of
  `build_dataset`'s pipeline), not on an ordinary client-patch re-run. The
  84/96/72/24 tab-layer reconciliation numbers, the 5-of-7 Sec 11
  "unreleased spec" shipped count (`FLESHWEAVER`/`VALKYR`/`MOUNTAINKING`/
  `WITCHKNIGHT`/`VIZIER` shipped; `HYDROMANCY`/`BULWARK` not), and the
  `isStartingNode` anomaly (2 nonzero, values `{1, 127}` - node 7608's `1` IS
  referenced by siblings 4040/7512, node 30212's `127` is not) are pinned the
  same way. The spellDbc resolve-rate gate (>=0.95, measured 1.0 against the
  current 209,130-row `Spell.dbc`) DOES depend on the client's `Spell.dbc`, same
  as any other snapshot pin.
- `tests/test_dataset.py`: 14 `buildStats` keys (task W4-9 added `coatalents`;
  W4-11b added `items`; the review fix pass added `gt`, which had been an orphaned
  stage). The `headerMismatches` allowlist check over the base 111-table
  `config.WANTED_DBCS` set is a STRUCTURAL check, not a snapshot pin - see
  "Header-invariant parity" above. Don't widen the allowlist reflexively; investigate
  which base table's header started lying and why.
- `tests/test_closure_ranks.py`: task W4-4 - formula-closure delta gated at +/-20%
  of the doc's cited +1,843 (re-derived fresh each run, not a fixed pin - measured
  1,476 as of this task); `rankAt60`/`$scalingbp`/`devDead` goldens re-derived from
  `work/dbc` at test time, not hardcoded (see "Formula closure, level-60 ranks..."
  above)
- `tests/test_gt.py`: re-derives the gt* layout proof fresh from `work/dbc/gt*.dbc` at
  test time rather than pinning fixed numbers (mostly STRUCTURAL, not a snapshot pin) -
  the level-80 combat-rating constants, the spell-crit/melee-crit conversion goldens,
  the `cr14` CRIT_TAKEN_MELEE uniqueness pin and the `cr15`==`cr16` non-pin all
  re-check against whatever is on disk. A future
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

Note: the spells count above (28951) is the current pin; its history is the clearest
worked example of this drift. *Historical, superseded by the current build:* the very
first sharding baseline was set at 27441 - discovered mid-task when a controlled re-run
of the pre-sharding writer against that day's `work/dbc`/`raw/content` snapshot produced
27441 records, not the 27432 that had been committed in `data/spells/`. Re-running both
the old and new writer against identical source data confirmed the delta was pre-existing
upstream content drift (unrelated to the sharding rewrite itself), not a regression - the
same class of churn documented in past task reports (e.g. Task 9's spell 61685 rename,
Task V2-1's raw/ Spell.csv.gz +292 rows). Subsequent client patches carried it to
27475, and task W4-4's intentional formula-closure widening added the last 1,476
records (27,475 + 1,476 = 28,951) - `test_sharding.py`'s header logs each step with
its date and cause.

After regenerating against a patched client, treat the two failure modes
differently. A snapshot-pin failure with a small delta (record counts moved by
tens, not orders of magnitude; a different archive won the same DBC by one
letter) means content changed upstream - eyeball the new numbers for
sanity, then re-pin the constants to match. A structural-check failure (layout
guard fires, a golden spell's fixed fields changed, a ratio gate blows past
5%, a huge/negative count swing) means the pipeline itself broke - investigate
the extractor/builder, don't just paper over it by re-pinning.

Run builders and tests ONE AT A TIME - never two concurrently (two agents, two
shells) against this repo. The builders are single-writer by design but take no
cross-process lock, and `build_spells.build()` opens with `shutil.rmtree` on
`data/spells/` (`tools/build_spells.py`), so anything reading that tree during
another process's ~30s rebuild window dies on `FileNotFoundError`
(`charges.json`, `_missing_refs.json`) or `EOFError` on a half-written
`.csv.gz`. Two further consequences make this worse than a plain failure: the
wipe is NOT self-healing (`tests/test_enums_v4.py` reads `charges.json` before it
regenerates it, so sequential retries keep failing until you
`git checkout -- data/spells`), and `build_realms.build()` used to degrade
**silently** - it would write `data/realms/<realm>/index.json` with an empty
`missingRefResolution` rather than erroring. Task W4-13 reproduced this 6/6
concurrently vs 0/10 sequentially; despite past reports of a "segfault", exit
code is 1 with an ordinary traceback and Windows logs no python fault at all
(see `.superpowers/sdd/task-w4-13-crash-report.md`).

That second consequence is now fixed in code, not just documented: the
one-at-a-time rule still stands, but `build_realm()` **raises** when
`data/spells/_missing_refs.json` is absent instead of publishing an evidence
file with no evidence. The standalone `python -m tools.build_realms` entry point
passes `allow_missing_base=True`, which writes `missingRefResolution: null` plus
a `degraded` key naming the cause - so a zeroed run can never be mistaken for a
measured one, in the console or in the committed data. The orchestrator never
passes it (it always runs the spells stage first, so a missing base file there
means something is genuinely wrong and should be loud).
