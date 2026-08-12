# Agent guide: querying coa-datamine

Game data extracted from the Ascension **Conquest of Azeroth** client (WoW 3.3.5a,
custom server). Everything in this repository is generated - do not hand-edit; rerun
`python datamine.py` after a client patch.

"Start here", "Honest limits" and "Traps" are what any consumer needs before trusting an
answer: which layer answers which question, what this dataset cannot know, and the things
that silently produce wrong results. "File map" routes to a path. Everything under
"Reference" is per-layer detail, meant to be entered by section title.

## Start here

Three access layers. The question decides which one answers it:

| layer | path | what it is |
|---|---|---|
| **raw** | `raw/` + `CATALOG.md` | the whole client, extracted mechanically: 368 tables, 7,467,660 rows, 6,662 positional columns, measured types, no curation. **Ground truth** - a hit is a fact about the client, a miss means the client does not contain it. |
| **derived** | `data/` | curated views over the raw layer: spell enrichment, class rosters, ability joins, tree geometry, damage-model coverage. Convenient and opinionated; every claim it makes carries its evidence in a `_meta.json`. |
| **navigation** | `CATALOG.md`, `tools/find.py` | where does X live: per-table rows, columns, id density, inbound joins, sample text; and a search across every layer including the client's executables. |

```
python datamine.py                                     # rebuild everything, one pass, no args
python -m tools.find "Tide Lash"                       # which table/column holds a string
python -m tools.find --id 133                          # every column an integer appears in
python -m tools.find --joins-to Spell                  # which columns point at Spell.f0
python -m tools.find "Tide Lash" --variant baseChain   # ask the BASE chain, not the chain winner
python -m tools.find "listarchive" --layer binaries    # the client's own EXECUTABLES
```

`raw/README.md` covers the non-table raw layers.

### Two things `find` knows that a naive read of `data/` does not

> **A miss in the data layers is not "the client does not do this".** `find` also scans
> `raw/binaries/` - every string, every recovered Lua chunk and every PE symbol of the
> 27 PE images in the client (7 loose in the client root, 20 stored inside archives).
> The engine extension `Extensions.dll` carries `listarchive`, `SetDataPath`,
> `realmdata` and an inlined Lua chunk that builds `AscensionRealmHotSwapOverlay`, none
> of which exists in any `.lua` file or any table. If an answer depends on client
> BEHAVIOUR rather than client DATA, search there before concluding anything.

> **A table has more than one version, and the default is not always the one you want.**
> The client carries several copies of most DBC paths and its loader picks one;
> `raw/tables/<Table>/` is that pick. For **10 tables** the pick comes from the realm
> overlay `Data\area-52\` - the Free-Pick realm's data - so `raw/tables/Spell/` is
> Free-Pick's 238,942-row `Spell`, while a Conquest of Azeroth character reads the base
> chain's 209,151-row one. Every version is decoded to
> `raw/tables/<Table>/variants/<archive-slug>/` in the same shape, listed under
> `variants` in that table's `index.json` and together in `raw/tables/_variants.json`
> (987 versions over 368 paths; 234 tables have more than one version, 134 exactly one).
> `--variant baseChain|overlay|all|realm:<dir>|<slug>` chooses, and every hit says which
> version it came from. **The 10 contested tables are `Spell`, `SkillLineAbility`,
> `SpellRank`, `Talent`, `CharacterAdvancement`, `CharacterAdvancementEssence`,
> `SpellCharges`, `SpellChargesCategory`, `Manastorm` and `ManastormModifiers`** -
> exactly the tables class and spell work depends on. Curated `data/` is built from the
> BASE variant for this reason: all 3,932 live talent-node spell ids resolve in base
> `Spell.dbc` and only 3,929 in the overlay.

### Four content layers: which one answers your question

Four layers describe the same abilities and **disagree with each other on purpose**.
They are not redundant copies, and only layer 4 joins them:

| Layer | Path | What it is | Size | Answers |
|---|---|---|---|---|
| **1. Spells** | `data/spells/` | every spell record reachable in the client, fully enriched - shipped, cut, dev-dead and never-implemented alike | 32,820 records | "what does spell `<id>` DO?" |
| **2. Catalog (CAD)** | `data/classes/` | what the client's character-advancement tables **LIST** for a class - an authored roster kept across content generations | 43 class dirs, 23,709 entries | "what does the client's catalog SAY about this class?" |
| **3. Live trees** | `data/talents/coa/` | the published talent-builder capture, sha256-pinned in `raw/talents/` - the tree geometry a player sees | 21 `coa-custom` classes, 3,618 nodes | "what can a player ACTUALLY train or spec into?" |
| **4. Ability identity** | `data/abilities/` | the JOIN across the id generations above - one record per ability, every spell id it exists under, which id is live, the trainer-taught rank ladder, evidence per membership | 8,784 abilities, 29,775 distinct member ids (29,874 membership rows) | "these four spell ids all say *Shooting Star* - are they one ability, and which id does the game use?" |

**Why layer 4 exists.** The same CoA ability ships under several unrelated spell ids -
the CAD catalog id, the trainer-taught rank ids, the id the live tree node carries - and
the client has no join table for them. `data/abilities/` is that join, derived
mechanically from `raw/` (group key = `(classId, normalized spell name, live-node
variant)`; every membership carries the source row that produced it). It covers **3,932
of 3,932** live-node spell ids, and `data/spells/` covers the same 3,932 because this
layer is what seeds it.

**Layer 2 is not the game.** Of the 8,331 CAD entries belonging to a class that has a
live capture, **4,908 (58.9%) appear in no live tree node** (3,460 `deadCatalog` + 1,448
`indeterminate`; re-derived at every build into `data/classes/_live_summary.json`).
Reading the catalog as reality is the single most expensive mistake available here.

**Worked example - Starcaller / Tide Lash.** The catalog gives Starcaller the tabs
`AstralWarfare` / `Class` / `Moonbow` / `Tides`. The live builder gives that class Moon
Guard / Sentinel / Moon Priest / Warden / Class. **113 of Starcaller's 213 distinct CAD
spell ids (53.1%) appear in no live node.** In the `Tides` tab specifically, `Tide Lash`,
`Pond`, `Deluge` and `Geyser` all ship `live: false` / `deadCatalog` - a player cannot
learn them - and `Silvercurrent` (503051) is reachable only through the dead entry
`Douse`.

The shape of the failure matters, because "the tree is fake" is too coarse: CAD `Tides`
and live `Moon Priest` are **the same tree slot in two content generations** (`ChrSpecs`
specId 43, tabToken `TIDES`, live name "Moon Priest" - `_live_summary.json.tabMapping`).
The slot survived; the name and most of the contents did not. 55 of the tab's 85 entries
are `deadCatalog`, 27 are `liveDirect`. You cannot resolve this by dropping tabs
wholesale, and you cannot resolve it by name - **only per entry.**

**The rule.** For any "what can a player do" question - rotation, spec UI, coverage,
ability rosters, simulation - branch on each entry's **`live` / `liveEvidence`** (`true`
/ `false` / `null`, semantics under "Live vs catalog"), never on mere presence in
`data/classes/`. `live: null` is a real unknown, not a soft no. For "what does this spell
do" questions, layer 1 alone is fine and needs no filter.

**What ignoring it costs, measured:** damage-model coverage is **80.5% over the catalog
but 89.3% over castable content**, and **74 of the 92 level-curve-only coverage holes
(80%) are not proven live** - 59 dead, 15 indeterminate.

> **Read this before using `data/classes/`.** It is the CAD **catalog** - what the
> client's character-advancement tables LIST - and a large part of it is not in the game.
> Branch on each entry's `live` / `liveEvidence`, never on mere presence. Every entry is
> also joined to the ability identity layer: `liveEvidence.identity` names the ability the
> row is a generation of - `abilityKey`, `live`, `liveNodeIds` (the ids the LIVE trees
> carry for it, which are different numbers from this entry's), `generations`,
> `trainerTaught`. That join is **evidence, not a verdict**: `live` itself stays the
> id-equality method's, because a (class, name) join was measured against proven-live
> entries and rejected as a live claim. The two are published side by side and their
> agreement counted in `_live_summary.json`'s `identityAgreement`, whose interesting cell
> is `identityLiveEntryNot` (**476** entries): the id method sees them in no live tree,
> but the ability they belong to HAS a live node under a different id. That number is the
> id-generation gap, measured.

### What one build guarantees

`python datamine.py` takes no arguments and needs no agent. It snapshots the client
first, then walks each archive exactly once, so every layer it writes describes ONE
client version - `raw/_snapshot.json` records the sha256 of every file it was built from.
Both halves are enforced in code: `mpq.OPEN_LEDGER` counts every archive open at the line
that performs it and the run refuses to publish if any archive was opened twice, and
`datamine.ClientReads` wraps the process's own file opens and fails the run if anything
reads the live client after the snapshot is sealed.

The launcher patches the archives roughly hourly, so a finished run's snapshot is
typically minutes to hours behind the live client. That is by design. There is no resume,
no incremental cache and no convergence loop; the guarantee on offer is internal
consistency - one client version in, one dataset out. For a newer one, rerun the single
command.

One script writes all of `raw/` and all of `data/`. The "nothing is hand-selected"
guarantee covers the layers listed in `raw/README.md`; `raw/dbc/` (a CSV projection of the
wanted tables), `raw/realms/` and `raw/provenance.json` are written by the same script's
curation stage, from the same snapshot, and are wanted-list-scoped by design.
`raw/talents/` is a frozen external capture, refreshed only by the occasional network step
`tools/fetch_coatalents.py` (see "Live-truth freshness").

**The curated layer is a pure function of the raw layer.** The curation stage materializes
its inputs out of the bytes the traversal already staged, seeds the spell closure from
LIVE truth (every live talent-node id, plus every trainer / rank-ladder / catalog id the
ability identity layer joins to one), and gates on covering all 3,932. Every curated spell
record carries `live` + `liveEvidence`; catalog-only content is kept and marked, never
deleted.

The live-coverage gate is an **equality, not a ratio**: if one live-node id loses its
enriched record the build aborts and names the id. Ground truth this layer is pinned
against, each enforced by a test rather than by prose:

| Pin | Claim | Where it is enforced |
|---|---|---|
| Live coverage | every live talent-node spell id has an enriched record (3,932/3,932) | `build_spells.build()` assert + `tests/test_live_seed.py` |
| Starcaller live tabs | the live trees are Moon Guard / Sentinel / Moon Priest / Warden / Class - NOT the catalog's AstralWarfare / Class / Moonbow / Tides | `tests/test_live_flags.py`, `data/classes/_live_summary.json.groundTruth` |
| Tide Lash (800380) | catalogued, not in the game: present in `data/abilities/` and `data/spells/`, `live: false` / `abilityWithNoLiveNode` - kept and marked, never deleted | `tests/test_abilities.py`, `tests/test_live_seed.py` |
| Golden spell row | id 17 = "Power Word: Shield", `dispel == 1` (column map still correct) | `build_spells.build()` assert |
| Single client version | no archive opened twice, nothing reads the live client after the snapshot seals | `mpq.OPEN_LEDGER`, `datamine.ClientReads` |

## Honest limits

These are properties of client data and of this extraction, not caveats to be softened.

### Server-side by nature - not in any client table

- **Boss scripts, loot tables, runtime spell grants and proc internals are server-side.**
  Encounter lists are names/order only.
- **Base stats and stat scaling are applied server-side.** The client ships the
  combat-rating curves (`data/gt/`) but not a character's base attributes or CoA's
  per-class modifiers. Verified by absence, not by omission: no `player_classlevelstats`
  equivalent appears anywhere in `config.WANTED_DBCS`, and a repo-wide search of `data/`
  for `baseMana`/`baseHealth`/`internalCooldown`/`procsPerMinute` turns up zero structured
  fields (the one substring hit is a spell tooltip's own `...basemana` prose). The `gt*`
  regen tables give mana/health regen-per-second curves only, not the base pool a
  percentage-of-base cost needs.
- **Proc rates - PPM, internal cooldowns, RPPM-style behaviour - are in no client table.**
  A proc's trigger condition is knowable from `EffectTriggerSpell`; its RATE is not.
- **`manaCostPct` needs base mana to resolve to a number, and it is the majority mana-cost
  channel**: **19.82%** of the 32,820 curated spells carry a nonzero `manaCostPct` versus
  **9.10%** a nonzero flat `manaCost`. Since no base-mana table exists, a
  `manaCostPct`-priced spell's actual cost is not computable from this dataset alone.
- **Quest text is server-side.** `Quest.dbc` carries **zero string data**
  (`string_block_size == 0`, verified directly) - no title, objective or completion text
  anywhere in the 18,561 `data/quests/` records, only `id` plus 28 raw numeric columns.
- **`data/creatures/` carries no level, health, armor, resistance or creature-type field
  for any of its 127,178 rows.** `{id, name, subname}` is the whole schema (`subname`
  itself always `null`, disproven); `raw/dbc/Creature.csv.gz` is display data end to end.
  Target stats have to be measured in game.

### Coefficients and damage modeling

- **This client's `bonusMultiplier`-style columns are a stock 3.3.5 channel CoA never
  wired up** (0/65 agreement with tooltip-parsed coefficients on stock content, 7/113 =
  6.2% on CoA content). `description`/`tooltip` formula text is CoA's only real
  coefficient channel; never union the two. See "`EffectBonusMultiplier`".
- **20 proven-live damage-model holes remain** out of 552 castable effect slots (89.3%
  modelable). `data/spells/_coverage_live.json`'s `liveHoles` is the actual list, with
  class, tier and formula per hole. Anything in a hole has to come from in-game
  measurement; assuming a default there invents data.
- **`effects[].realPointsPerLevel` needs the `maxLevel` clamp applied by the consumer** -
  it is a per-level *value* term, not a gear-scaling coefficient, and 85.3% of the CoA
  spells carrying it are capped below level 80. Clamp formula and frozen goldens under
  "Spell column completion".
- **`rankAt60`'s gating field is inferred and unresolved.** CAD `ranks[].level` and DBC
  `spellLevel` agree on only ~33% of rank rows and pick a different level-60 rank on 216
  of the 360 measurable multi-rank CoA chains. This field follows CAD level; that choice
  is not independently verified, and DBC `spellLevel` runs systematically higher, which
  would pick an even lower rank on the disagreeing chains. Settling it needs an in-game
  `/dump`. A real open question for absolute damage values.

### Live truth, freshness and unknowns

- **`live` is only as current as the talent-builder capture.** `raw/talents/` is one
  frozen fetch of the published CoA builder; it is the one artifact under `raw/` that is
  not on the client's clock. The gap is measured, not assumed:
  `raw/provenance.json.liveSeedDrift` and `data/abilities/_meta.json.liveSeedDrift` carry
  the capture's `capturedUtc`, the newest client-archive mtime in `raw/_snapshot.json` and
  `captureMinusSnapshotDays` between them (currently **-3.431**: the capture predates the
  newest client files, so content the client already has can read as dead). Re-run
  `tools/fetch_coatalents.py` and diff the pinned sha256 to check.
- **`live: null` is not `false`.** `notAnAbility` = no ability owns the id; `noLiveGeometry`
  = an ability owns it but no live tree was captured for that class. A missing measurement
  is not a negative result. Current split: 5,558 records `true`, 3,215 `false`, 24,047
  `null`.
- **`live: false` means "no probe fired", not "proved absent".** Four acquisition probes
  run over the 4,908 not-in-tree entries (see "Live vs catalog"); an entry with none of
  them is `false`. That is a statement about the probe set as much as about the content.
- **`CharacterAdvancementData.json` is account-wide** across the four realms this client
  serves, so Reborn\*-class spell refs resolve `null` far more often than other classes
  (7,119 of 13,901 Reborn refs = 51.2%) - a data-availability fact of the capture, not a
  pipeline bug. `data/spells/_meta.json` records the shape:
  `missing_ref_counts_by_source` per bucket (`cad_other`/`cad_reborn`/`talent`/`rank`/
  `formula`) and `ref_counts` for the denominators; full id lists in
  `data/spells/_missing_refs.json`. The build hard-gates only `cad_other` and `talent`
  (each <=5% missing; measured churn baseline `cad_other` 178/7,162 = 2.49%, with the
  recorded 2.95% baseline in `dataNotes`). `cad_reborn` misses and `rank` orphans (stale
  `SpellRankData` chains with no filterable realm/class field) are report-only; expect
  both nonzero.
- **The `Realms` bitmask on class entries is undecoded and carried raw.** The decode
  attempt failed its golden bar - see "Realms bitmask: a failed decode" and
  `data/classes/_realms_evidence.json`. No `realmFlags` field exists anywhere in this
  dataset.
- **Enum labels for uncommon effect/aura ids fall back to `EFFECT_<n>`/`AURA_<n>`; the
  numeric id is always authoritative.** `data/spells/_enum_evidence.json` carries per-id
  `{bucket, confidence, name, goldenSpells, occurrences}` for all 224 classified ids (66
  effect + 158 aura), and every named entry names at least one golden spell you can pull
  from `data/spells/` and verify by hand. Only its 57 `confidence: verified` entries are
  wired into `tools/enums335.py`; the 2 `[INFERRED]` names are recorded there and
  deliberately NOT wired, so a numeric fallback never silently becomes a guess. The
  remaining 167 stay numeric on purpose.

### Structural limits of individual datasets

- **`data/trainers/` is one row per `NPCTrainer.dbc` entry, not grouped by NPC** - that
  4-column table has no trainer-identity column at all (`trainerIdFinding` in its
  `_meta.json`).
- **Dungeon `rewards` is a LIST of level-bracket objects** sorted by `MaxLevel` ascending,
  never a single object (dungeon 258 has 17 brackets). An empty list means no `LFGData`
  reward entry exists - always iterate.
- **Only 12 classes have DBC `Talent.dbc` tabs** (10 vanilla + Barbarian + WitchDoctor);
  every other class's talents live only in CAD entries. Absence from `data/talents/` does
  not mean the class has no talents.
- **CAD covers *obtainable* abilities**; item/proc-granted spells appear only via the
  trigger closure or not at all.
- **`.loc` localization files (non-enUS) are unparsed**; enUS strings come from DBCs.
- **The formula-reference closure is depth-capped at 2, not exhaustive** - a reference
  embedded only in a depth-2-added record's own text is not followed. Measured, not
  applied: +3 records.
- **`SpellCharges` ships standalone, not attached to any spell** - `ref`-to-`Spell.dbc`
  join-rate **0.8867** (360/406), short of the 0.90 attach bar, even though the categoryId
  link to `SpellChargesCategory` is 100% proven. All 46 non-joining refs resolve as real,
  live ids in the area-52 overlay's own `Spell.dbc` (46/46, re-derived each build by
  `build_spells._charges_realm_check()`) - **zero are dead** - so this is content
  availability, not orphaned garbage; but only proven-dead refs are a legitimate exclusion
  from the bar, so the rate stands. Keyed by its own `ref`, not `spellId`; per-realm
  breakdown in `realmGapFinding`, and each non-joining row carries `realmResolvedIn`.
- **`data/spells/statSuggestions.json` ships an unproven payload column** - `spellId` is
  proven (99.91% join + an exact golden), `statCategoryRaw` is not (73.5% correlation with
  a primary-stat category, short of the naming bar). Carried raw, flagged in its own
  `_note`, attached to no `spells.jsonl` record.
- **`SpellRank.dbc` is NOT wired into the rank-chain pipeline, and it has more coverage
  than `SpellRankData.json`, which is.** 13,238 spellId rows (99.96% real, live ids) the
  JSON does not carry at all, plus an unexplained `rank` disagreement on 5.68% (565 of
  9,941 shared spellIds) that is NOT a clean off-by-one (`+1` is 47.1% of mismatches).
  Re-deriving the pipeline against the richer source would move downstream pinned counts
  dataset-wide.
- **`data/gt/` cannot prove the server uses these values** - they are the CLIENT's copy
  (tooltips, character sheet) and a TrinityCore-family server loads its own set.
  `gtOCTClassCombatRatingScalar` ships raw + colinfo only (different shape, layout
  unproven), and `gtCombatRatings`' ARMOR_PENETRATION reads 11.55 at level 80 against a
  published 15.39 - a real, unresolved behavioral difference, not a decode bug.
- **Realm overlay data is not curated into class or spell views.** `data/realms/` is
  evidence about a realm's own tables; `data/classes/` stays keyed off the base,
  account-wide catalog. See "Manastorm + realm overlays".

### Disproven mappings ship as documented `null`/raw, never a guessed value

Each was probed against the empirical-mapping bar and failed it; the pointer is listed so
the same probe can be re-run if a future patch changes the table.

- `data/creatures/*.jsonl`'s `subname` - always `null` (`_meta.json`'s `subnameFinding`;
  the candidate columns' apparent string-likeliness matched a random-offset control's
  coincidence rate, ~3.45%).
- `data/quests/*.jsonl`'s `sort`/`info` - always `null` (`_meta.json`'s `sortInfoFinding`;
  best candidate topped out at 58.6%/58.2%, short of the 80% bar).
- `data/classes/specs.json`'s `f63` - `ChrSpecs`' one low-cardinality column, tested as
  both Tank/Healer/DPS role and ordinal spec position and disproven both ways; shipped
  raw, not named `"role"`.
- `ManastormMessages`' `f3` - hypothesized areaId; 92.2% of nonzero rows join
  `AreaTable.dbc` but resolve to unrelated zones (a Zul'Gurub-themed message reading
  "Silverpine Forest"). Left raw. Its nonzero values do group messages by content pack.
- `SpellAlternativePowerType` / `SpellAddon`'s f20-f22 / `CharacterCreationPetDetails` /
  `ShapeshiftDetails` spellId candidates - all disproven, documented inline in
  `tools/dbc.py`.

### The archives themselves are fully open, checked against an oracle

Every MPQ carries an `(attributes)` member holding the MD5 its packer recorded per block
entry, so a decoded file is checked against the archive rather than against another
reader: **763,928 members across all 77 archives, 0 mismatches, 0 unreadable.**
Consequences worth knowing:

- The census (`raw/_inventory`) records **637,591 paths**, of which **4,906 are
  `readable: false`, and every one is an MPQ DELETE tombstone** - a patch entry that
  removes a path and carries no bytes by design. `raw/recovered/` holds them (4,911
  tombstone entries across archives) plus 13 genuinely empty members. Zero files are
  genuinely unreadable.
- `raw/recovered/attributes/` is a metadata layer nothing else here has: CRC32 + MD5 +
  modification time (where the archive records one) for **768,998** path/archive pairs,
  covering every version of every file including the ones that lose the chain. The
  timestamps are a mechanical way to separate Ascension's own content from Blizzard's.
- Deleted entries hold nothing recoverable, and that is a byte-level result: every
  archive's data region is walked against its own block table and **0 bytes** across
  44.9 GB are unaccounted for, with 0 orphan block entries. The client's one encrypted
  member (patch-P's `(listfile)`) decrypts - to the literal string `(listfile)`.

## Traps

Twelve things that silently produce wrong data if a consumer does not know about them.
Traps documented at length elsewhere in this file carry a pointer rather than a second
copy.

1. **`procChance` sentinel is 101, not a percentage - and 0 also means "unset", not
   "never procs".** Measured with `procChance NOT IN (0, 101)`: **8,831 = 26.9%** of the
   32,820 records carry a real value. Treat **both** 0 and 101 as "no proc-chance data".
2. **`maxLevel` clamps 85.3% of level-scaled CoA spells below level 80,** and
   `maxLevel == 0` is the "uncapped" sentinel, not a literal clamp to 0. Clamp formula and
   frozen goldens under "Spell column completion".
3. **CoA reuses Classic ability NAMES for unrelated effects - resolve by id, never by
   name.** Spell 300475 `"Expose"` is not Expose Armor (an `ADD_FLAT_MODIFIER`-family
   damage-taken/crit aura pair); spell 803477 `"Sunder"` is not Sunder Armor
   (`COA_MOD_ATTACK_POWER_FLAT`, `basePoints: -24`). A name-keyed lookup silently returns
   the wrong spell for either id.
4. **`id >= 100000` does not mean custom.** Over the 6,436-id CoA class spell set, exactly
   **86** ids are sub-100000. Key off the `data/classes/<Class>/` directory a spell was
   reached through, never an id range.
5. **Reborn contamination.** The Reborn classes' spell-id universe is **14,107** ids; the
   CoA-custom universe intersected with the vanilla one is **1** id, and with Reborn's
   **0**. Any naive "all classes" iteration over `data/classes/` pulls Reborn in - filter
   on `tag == "coa-custom"` (or `"vanilla"` for stock) explicitly.
6. **The catalog is not the game.** `data/classes/` lists content no player can reach:
   **4,908 of the 8,331 CAD entries in a class with a live capture (58.9%) are in no live
   tree.** Branch on `live`/`liveEvidence`, never on presence - and note `live` is an
   ABILITY-level claim, with `null` meaning unknown rather than no.
7. **No pretty difficulty-display-name field exists - but `difficultyToken` is usable, and
   it is `lockoutMessage` that is mostly blank.** In `data/mythic/mapDifficulty.json`
   (685 rows), `lockoutMessage` is blank 86.8% / 64.2% / 63.2% / 73.7% at
   `difficultyIndex` 0-3 (unreliable at every tier); `difficultyToken` is blank only
   58.6% / 2.5% / 0.6% / 2.6%, i.e. cleanly populated at 1-3 with raw engine constants
   (`DUNGEON_DIFFICULTY_5PLAYER_HEROIC`, `RAID_DIFFICULTY_25PLAYER_HEROIC`, ...) and sparse
   only at index 0. `data/dungeons/*.json`'s own `difficulty` is a bare 0-3 int with no
   name column (430 dungeons: 212x0, 99x1, 100x2, 19x3). **Fix:** use `difficultyToken`
   and map the enum constants to display strings yourself - nothing here does it for you.
8. **A high raw join-rate against a DENSE id space proves nothing.** `ItemStat.dbc`'s `f2`
   scores a 1.000 join against a naive column guess and is still not the item link: `f1`
   is `itemId` (golden-verified against item 100248 vs `itemcache.wdb`) and `f2` is
   `ownItemLevel`. The same shape produced several other false positives listed under
   "Empirical-mapping convention". Require a golden or a sparse target space.
9. **`ItemSpells.dbc`'s `f1` is not the item link.** `f1` is unique per row
   (131,722/131,722 - structurally cannot be a many-spells-per-item foreign key) and only
   55.45% resolves against `Item.dbc`; `f2 -> spellId` is the well-supported column
   (99.81% against a 1.50%-dense spell-id space - a real join, since the target space is
   sparse). Shipped raw + colinfo, no `TABLE_MAPS` entry.
10. **`DUMMY` effects/auras are server-side script - `basePoints` on them is meaningless.**
    **4,674 spells (14.2%)** touch a `DUMMY`/`PERIODIC_DUMMY` effect or aura. No behavior
    is recoverable from the data for those slots; only the tooltip text, if any, hints at
    what the server-side script does.
11. **`ranks[-1]` is the wrong rank at CoA's level-60 cap** - it requires level > 60 on
    most multi-rank chains and inflates values through the maxLevel clamp. Use the chain
    head's `rankAt60`; see "Formula closure, level-60 ranks".
12. **`TalentAbility` entries grant no damaging abilities.** **266** distinct rank-chains
    across the coa-custom classes, and **zero** carry a direct damaging effect/aura on any
    first-rank record - all are pure passive modifiers (golden: Barbarian *Boulderfist*
    705184, "Reduces the Energy cost of Wrecker by $s1" via an `ADD_FLAT_MODIFIER` aura).
    Correct to exclude from a damaging-ability denominator; do NOT drop them from a
    modifier/buff ingest path.

Two more that are stated fully elsewhere and are easy to trip over: **a coefficient may be
bound to a non-damaging effect slot** (see the binder note under "Formula closure"), and
**`@s:<id>` is a spellbook cross-link, not a formula reference** (deliberately not
followed; pinned in `tests/test_closure_ranks.py`). **Dev-dead content ships in the data**
and is flagged `devDead` - 7 records, see "Formula closure", part (d).

## File map

Every dataset is self-describing: `index.json` enumerates a sharded dataset's files,
`_meta.json` carries that dataset's counts, proven columns and findings, and `CATALOG.md`
covers all 368 raw tables. This table is the routing layer - open a dataset's own
`_meta.json` for schema and evidence rather than expecting it repeated here.

**Sharding rule.** No committed `data/` file is an arbitrary 10k+-line monolith: every
dataset with enough records to matter is split by a stable semantic key (per-dungeon file,
per-class-per-tab file) or a fixed id range (`id // N * N` bucket - never count-based
chunking, which reshuffles every file on insertion and destroys diff locality). Every
sharded dataset has an `index.json` manifest that fully enumerates its shard files;
manifests use a compact one-record-per-line format so a several-hundred-record index stays
small and still diffs one line per record. `tests/test_sharding.py` asserts every
`data/**/*.json(l)` file is <=5,000 lines except an explicit commented allowlist
(currently empty).

### Classes and specs

| Path | What | Caveat |
|---|---|---|
| `data/classes/index.json` | class roster + tags + classId map + `dir`/`index` pointers per class + `chrClasses` (ChrClasses.dbc, 32 rows, each carrying `filename`) + `unmatchedChrClasses` | `unmatchedChrClasses` is **`["Hero"]`** - unreleased content with no CAD class |
| `data/classes/<Class>/index.json` | that class's `tag`/`classId`/`realmHint`/`aliases`/`entryCount`/`unresolvedCount`/`hasLiveGeometry`/`liveCounts`/`liveCountsByReason`/`liveTabs`/`catalogTabs` + `files[]` enumerating every shard with its `tab`/`type`/`cadIdRange`/`count` | **enumerate trees from `liveTabs`, shards from `files`** - `catalogTabs` is the CATALOG-generation geometry (Starcaller's files offer AstralWarfare/Class/Moonbow/Tides; its live tabs are Moon Guard/Sentinel/Moon Priest/Warden/Class). `aliases` is `[]` for 40 of 43 classes |
| `data/classes/<Class>/<Tab>.json` | one spec tab's CATALOGUED abilities/talents/traits with resolved spells | read each entry's `live`/`liveEvidence` before treating it as real content; each resolved spell's `ranks[]` carries `{spellId, rank, level}`, but for level-60 rank selection read the chain's first-rank record's `rankAt60` in `data/spells/` instead |
| `data/classes/<Class>/<Tab>.<Type>[-<bucket>].json` | only when one tab exceeds 5,000 lines | see "Class tab sharding" |
| `data/classes/<Class>/_general.json` | entries with no `Tab` | none exist in the current snapshot; the file only appears if some do |
| `data/classes/_live_summary.json` | the live-vs-catalog join's evidence: repo-wide + per-class `liveCounts`, payload provenance (capture date + sha256), the false-negative measurement, `identityAgreement`, and the CAD-tab to live-tab mapping with per-pair method + node-overlap evidence | written by `build_classes.py`; `build_classmeta.py` READS its `tabMapping` rather than re-deriving it |
| `data/classes/_realms_evidence.json` | the `Realms`-bitmask decode attempt: distinct-value census (28 values / 23,709 entries), per-tag/per-bit statistics, a live duplication example, hypothesis scoring, Lua findings, verdict | **a documented failure, not a decode** - no `realmFlags` exists anywhere |
| `data/classes/specs.json` | 101 `ChrSpecs` rows + `perClass` + `roles` + `specialAbilities` + `tabStatusSummary` | **read this file for spec/role data, never `data/classes/index.json`** (single-writer rule). `perClass` coverage is 32/32; `specialAbilities` has only 3 entries (Shaman, Bloodmage, Primalist) - absence means "no special ability", not "unresolved". `tabStatus` semantics under "Live vs catalog" |
| `data/classes/archetypes.json` | 56 `CharacterCreationArchetypes` rows - character-creation flavor presets | class-agnostic: no classId link exists in this table |
| `data/classes/essence.json` | per-class Ability/Talent Essence curves, levels 1-80, 32 classes, `curveGroup` in `classlessBase`/`hero`/`coaCustom` | owned solely by `tools/build_essence.py` |

### Spells and abilities

| Path | What | Caveat |
|---|---|---|
| `data/spells/index.json` | bucket manifest: `bucketSize` 10000, `count`, `buckets[]` | |
| `data/spells/by-id/spells-<bucket>.jsonl` | every referenced spell in that id bucket, fully enriched, ONE JSON PER LINE, ascending id; empty buckets omitted | **stream or grep it, do not slurp.** Per-effect `realPointsPerLevel`/`pointsPerComboPoint`/`spellClassMask`/`damageMultiplier`/`bonusMultiplierStock` appear only when nonzero; `rankAt60` only on a chain's first-rank record |
| `data/spells/_meta.json` | counts only: `liveCoverage` (the gate), `liveSeedRule`, `liveFlagRule`, `baseVariant`, `count`, `missing_ref_counts_by_source`, `ref_counts`, `dataNotes`, `by_source`, `columnCoverage`, `formulaClosure`, `rankAt60`, `scalingConstants`, `devDead`, `enrichment` | |
| `data/spells/_coverage.json` | per-`TABLE_MAPS["Spell"]`-column `{index, kind, mapped, emitted, where}` manifest (128 mapped of 234 fields; 124 emitted) | COLUMN coverage |
| `data/spells/_coverage_live.json` | **damage-model** coverage: `figures` (three denominators), `delta`, `liveHoles` + `indeterminateHoles` (the probe list with class, builder tab/tier, formula and value at 60), `perClass`, `goldenChecks`, method notes | unrelated to `_coverage.json`. Written by `python -m tools.coverage_live`, NOT by `datamine.py`'s curation stage - see "Damage-model coverage" |
| `data/spells/_enum_evidence.json` | per-id provenance for every effect/aura enum label, 224 classified ids | **this is how to verify any enum label in this dataset** - every named entry carries at least one `goldenSpells` id |
| `data/spells/_missing_refs.json` | full missing-ref id lists by source, each array on ONE line | `formula` is report-only, never folded into the `cad_other`/`talent` hard gates |
| `data/spells/charges.json` | `SpellCharges`/`SpellChargesCategory` (406 charge rows / 106 categories) | **NOT attached** to any spell record (join-rate 0.8867 < the 0.90 bar) - keyed by its own `ref`, not `spellId` |
| `data/spells/statSuggestions.json` | `SpellStatSuggestions.dbc` (1,121 rows) | **NOT attached**: the `spellId` key is proven, the payload is not |
| `data/abilities/index.json` | ability roster: per-class file list with `abilityCount`/`live`/`multiGeneration`/`trainerTaught`, headline counts, generation-span histogram, `recordShape` | |
| `data/abilities/<classId>-<class-slug>.json` | one file per class; each ability carries `key`, `generations`, `live`/`liveIds`, `trainerTaught`/`trainerIds`, `rankLadder`, `linkedKeys`, and `members[]` whose `evidence` is keyed by generation and carries the actual source row | see "Ability identity layer" |
| `data/abilities/_meta.json` | the rules and their measurements: name normalization + the four counts behind it, the rank-chain coherence gate + incoherent examples, `idDensity`, the trainer admission rule, CAD-name-vs-spell-name agreement, live-capture provenance + `liveSeedDrift` | |
| `data/abilities/_residual-index.json` + `_residual-<bucket>.json` | every source id that joins to NOTHING (14,286 ids), one record per line | the honest remainder, mostly profession recipes and rank-chain ids no class-carrying row names |

### Talents

| Path | What | Caveat |
|---|---|---|
| `data/talents/<ChrClass>.json` | DBC talent trees (row/col/ranks/prereqs) - 12 files, 37 tabs, 2,383 talents | only the 12 classes with DBC talent tabs; largest is ~3.6k lines, under the gate as-is, not sharded |
| `data/talents/_pet.json` / `_unassigned.json` / `_meta.json` | pet talent tabs (3); tabs matching no classMask (0 today); tab/talent counts | |
| `data/talents/coa/<Class>.json` | CoA talent-tree GEOMETRY for all 21 `coa-custom` classes (153-208 nodes each): tabs with AE/TE gate tiers, `choiceGroups`, and `nodes[]` with position, `requiredIds`, `connectedNodeIds`, costs, `spellId`/`spellIds`, `spellResolved` | a SEPARATE dataset from the DBC trees one directory up (never collides - Barbarian has both). `requiredIds`/`connectedNodeIds` are de-padded (source arrays are zero-padded; `0` is never a real node id). `spellResolved` is 3,618/3,618 today and is KEPT, not retired: a refreshed capture can reintroduce a gap |
| `data/talents/coa/index.json` + `_meta.json` | class to file with counts; payload fetch provenance (url/sha256/capture time), realm caveat, resolve-rate cross-validation, the tab-count reconciliation, `isStartingNode`/choice-group/connectivity findings | see "CoA talent tree geometry" before trusting any single field at face value |

### Dungeons, creatures, quests, trainers, Mythic+

| Path | What | Caveat |
|---|---|---|
| `data/dungeons/index.json` + `<id>-<slug>.json` | 430 dungeons (109 raids); each file carries ordered `encounters` (each with a `creature` link or null) and reward brackets | `<slug>` = lowercase name, non-alnum runs collapsed to `-`, max 40 chars. `rewards` is a LIST |
| `data/creatures/index.json` + `creatures-<bucket>.jsonl` | `{id, name, subname}` per `Creature.dbc` row, one JSON per line, 127,178 rows | `id` is `Creature.dbc` **f1**, the real creature TEMPLATE ENTRY id (a sparse space up to ~11M) - **355 buckets, not 26**. `subname` is always `null` |
| `data/quests/index.json` + `quests-<bucket>.jsonl` | `{id, sort: null, info: null, f1..f28}` per `Quest.dbc` row, 18,561 rows | **this table has no string block at all** |
| `data/trainers/index.json` + `trainers-<bucket>.json` | `{id, spellId, name, skillLine, f3}`, 13,112 rows | a **flat per-row list**, not grouped by trainer; spellId join-rate 0.989 |
| `data/mythic/challenges/index.json` + `<id>-<slug>.json` + `_lookups.json` + `_meta.json` | the CoA "Challenge Mode" feature: 297 challenges with groups/levels/rules/modifiers/conditions/requirements/rewards/spells, plus the four lookup tables | largely dungeon-agnostic - don't assume a challenge relates to a specific dungeon unless its own fields say so |
| `data/mythic/keystones/index.json` + `<dungeonId>-<slug>.json` + `_unresolved.json` | `MythicKeystones` levels grouped per dungeon (6,700 rows across 65 dungeons; 101 unresolved rows kept raw, overall join 0.9851) | `dungeonId` shares the `LFGDungeons.dbc` id space with `data/dungeons/` |
| `data/mythic/affixes/*.jsonl` + `index.json` | 13,409 `MythicAffixes` rows | affix identity is `grantSpellId`/`effectSpells`; the `ChallengeModifierTypes` name hypothesis was tested and disproven |
| `data/mythic/scaling.json` / `timedDungeons.json` / `mapDifficulty.json` | `MythicPlusScaling` (200), `TimedDungeons` (81), `MapDifficulty` (685) | see trap 7 for the difficulty-label question |

### Items, Manastorm, gt*, realms

| Path | What | Caveat |
|---|---|---|
| `data/items/statsByItem/index.json` + `*.jsonl` + `_meta.json` | `ItemStat.dbc` per-item COVERAGE index (20,267 items): `{itemId, rowCount, ilvls, rawShard}` | **not a stats re-decode** - only `f1`/`f2` are proven |
| `raw/dbc/itemstat/index.json` + `itemstat-<bucket>.csv.gz` | `ItemStat.dbc`'s own sharded raw dump (1,513,931 rows, 29 non-empty buckets) | the reason it is sharded: one committed file would be a 236 MB blob. Header names `itemId`/`ownItemLevel` (f1/f2), rest raw |
| `data/manastorm/manastorm.json` / `messages.json` / `index.json` + `modifiers-*.jsonl` / `playerGroupModifiers.json` / `_meta.json` | CoA's seasonal-difficulty system: 1,017 Manastorm rows (mapName 100% join, `dungeonEncounterId` 99.51% via a gated two-hop cross-check), 291 message rows, 32,768 modifier rows, 15 player-group rows | the modifier tables are **unproven beyond `id`** - no spellId or other FK column exists in either, despite several candidates tested |
| `data/gt/combatRatings.json` | 3,200 `gtCombatRatings` rows as 32 rating slots by 99 levels | **17 of 32 slots pinned to a published WotLK name**; the other 15 stay `cr<N>` - see "gt* combat-rating tables" |
| `data/gt/classChanceCurves.json` / `level60.json` / `_meta.json` | 8 class-major gt tables keyed by `classId`; a level-60 convenience slice; counts, `ratingNames`, `provenColumns`, `goldensReproduced`, `unresolvedRatingIndices` and the caveats | curves are levels **1-99 only** - the level-100 slot is a trap |
| `data/realms/<realm>/index.json` | one realm's overlay evidence: per-table records/fields/mapped/delta, `spellIdRange`, `newSpellCount`, `missingRefResolution`, `liveNodeCoverage` | **read the framing under "Manastorm + realm overlays" before trusting `missingRefResolution`.** `liveNodeCoverage` is 3,929/3,932 on area-52 (missing 573365 / 760379 / 808082) - the measurement that decides the curated layer reads the BASE variant |
| `data/realms/<realm>/_meta.json` + `overlay_diff.json` | mapped/unmapped table lists + `futureMilestone`; and the base-vs-overlay `Spell.dbc` diff over the CoA class spell set | `overlay_diff.json` is written by the standalone CLI `python -m tools.diff_realm_overlay <realm>`, not by `build_realms.py` |
| `raw/realms/<realm>/dbc/<Table>.csv.gz` (+ `.colinfo.json`) | mapped realm tables reuse the base `TABLE_MAPS` column map and layout guard as-is; unmapped ones dump raw `f0..fN` + an evidence sidecar | zero new column proofs are introduced for realm data |

### Raw layers worth knowing by name

| Path | What |
|---|---|
| `raw/interface/_manifest.json` | every extracted Interface file: relative path to `{source, size, sha256}` (1,558 files: 1,449 archive-sourced + 109 disk-sourced) |
| `raw/interface/AddOns/APIDocumentation/**` | Ascension's own API-documentation addon, copied verbatim from the live client install (a disk copy - it always wins a path collision against an archive-extracted file). **The client's real API** |
| `raw/interface/{AddOns,FrameXML,GlueXML,SharedXML,LibraryXML,LCDXML}/**` | every other `.lua`/`.xml`/`.toc`/`.txt`/`.md` under the client's `Interface\` tree across every archive (art/BLPs/sounds/models excluded - this is a code layer); winner per file resolved by the same chain-order rule as the DBCs |
| `raw/dbc/*.csv.gz` | full decoded DBC dumps, every column |
| `raw/content/*.json` | verbatim client sidecar JSONs |
| `raw/binaries/index.json` | every PE image in the client: 7 loose in the client root (`Extensions.dll`, `Ascension.exe`, `WowError.exe`, `MMgr64.exe`, `DivxTac.dll`, `DivxDecoder.dll`, `discord_game_sdk.dll`) plus 20 stored inside the archives. A version several archives carry byte-for-byte appears once, with the rest in `origin.alsoIn`. **The layer that answers "the client does X but nothing in the data layers mentions X"** |
| `raw/binaries/<name>/strings/` | every printable run (ASCII, UTF-16LE, UTF-8) of 4+ characters, deduplicated, with every file offset, the PE section it lands in and a Lua-syntax score - reachable via `find --layer binaries` |
| `raw/binaries/<name>/lua/` | Lua recovered from the binary: `chunks/*.lua` are multi-line source runs written verbatim (`Extensions.dll`'s `AscensionRealmHotSwapOverlay` builder; `Ascension.exe`'s two inlined 5.0-compat libraries); the JSONL records add the single-line fragments the DLL concatenates scripts from. A `\x1bLua` magic that does not walk cleanly is recorded as `precompiledRejected` with its reason |
| `raw/binaries/<name>/pe.json` + `symbols/` + `resources/` | sections (`Extensions.dll` carries a `.vm_sec`), imports/delay-imports, exports, resource tree, debug directory (**PDB build paths**), certificates, Rich header, overlay |
| `raw/provenance.json` | source hashes, archive resolution, build stats (14 stage keys), `liveSeedDrift`, and top-level `headerMismatches` (must contain only the documented allowlist - today exactly one entry) |

## Reference: conventions

### Empirical-mapping convention: `f<N>` means "unproven by design"

Every table was mapped under one binding rule: **a column gets a real name in
`tools/dbc.py`'s `TABLE_MAPS` only with golden-record proof pinned in a test or an inline
comment - otherwise it stays `f<N>` (raw signed int, the column's own index)**. `f<N>` is
a deliberate, permanent signal meaning "this column's meaning was investigated and not
established", distinct from a column nobody has looked at yet.

- `raw/dbc/<Table>.colinfo.json` is the evidence trail for every unmapped table:
  per-column `distinct`/`min`/`max`/`pct_zero`/`string_likelihood` plus up to 3 decoded
  string samples for string-likely columns. Start a new hypothesis there.
- **A high raw join-rate against another table's ids is not sufficient proof when the
  target id space is dense.** Several hypotheses cleared a naive 90%+ join-rate bar and
  were still wrong (Creature `subname`, the `DungeonEncounterExtra` creature link before
  the id column was corrected, `SpellAddon`'s f20/f21/f22,
  `CharacterCreationPetDetails`/`ShapeshiftDetails`'s spellId candidate). Every proven
  column additionally has either a golden semantic check (a known name/description decodes
  correctly) or an overwhelming range/density argument. Read a `TABLE_MAPS` entry's inline
  comment before trusting a column name or re-deriving a mapping that has already been
  tried and disproven - the comments document *why*, not just *what*.
- Every dataset's `_meta.json` or module docstring carries the same evidence in prose next
  to the data it produced, so understanding why a field is `null` or missing does not
  require cross-referencing `tools/dbc.py`.

**Worked instance of the dense-id trap, both directions.** `Creature.dbc`'s `f0` is a
positional row index that shifts whenever a patch inserts rows upstream, and its fully
dense 1..127,178 range makes any bounded column "join" it at ~92%. `f1` is the real, stable
creature template entry id - 127,178 ids sparse across 1..11,001,007, golden-verified
against Hogger 448, Edwin VanCleef 639, Onyxia 10184, Ragnaros 11502. Against the corrected
id space, `DungeonEncounterExtra`'s creature column proves out: 98.57% row-level join, every
famous-boss golden resolves, fuzzy word-overlap 94.7% against a random-pairing control's
0.55%. Full evidence in `tools/build_dungeons.py`'s module docstring.

### Class tab sharding (why three levels, not one)

Most class tabs fit in one file: `data/classes/<Class>/<Tab>.json`. A handful do not - even
though Tab is the natural semantic key, one file would run 15k-18k lines
(RebornWarlock/Destruction is 728 entries, and the per-entry `live`/`liveEvidence` fields
add ~5 lines per entry). `tools/build_classes.py:_shard_tab` cascades three levels, each
used only if the previous one still overflows 5,000 lines:

1. **Whole tab** - `<Tab>.json`. The large majority of tabs.
2. **Split by entry `Type`** - `<Tab>.<Type>.json`. Insufficient alone for the worst
   offenders: `Type == "Trait"` is ~95% of the oversized tabs' entries, so splitting
   Talent/TalentAbility off barely moves the dominant bucket.
3. **Fixed `cadId` range within the Type** - `<Tab>.<Type>-<cadId//2000*2000>.json`. Used
   only for the handful of `Trait` files still over 5,000 lines after step 2. A
   `requiredLevel` band was measured and rejected: ~40% of a typical oversized Trait bucket
   shares the same `RequiredLevel` (mostly 1), so no band width shrinks that cluster.

Every shard, at any level, is self-describing (`{class, tab, type, entries}`) and listed in
that class's `index.json` `files` array with its `tab`/`type`/`cadIdRange`/`count`.
**Enumerate shards from `files`, never by guessing the split level.**

### Interface/API code layer

`raw/interface/` is a committed mirror of the client's `Interface\` tree - every
`.lua`/`.xml`/`.toc`/`.txt`/`.md` file from every archive (chain-order winner per file,
same rule as the DBCs), plus Ascension's `AddOns/APIDocumentation` addon copied verbatim
from the live client install. This is the only part of the dataset that is source *code*
rather than extracted *data* - use it when a question is about how the client implements
something rather than about game content.

**`raw/interface/AddOns/APIDocumentation/` is the client's real API** - machine-readable
documentation of every Lua global function, event, table and system available to addons
(`Documentation/*.lua`, one file per subsystem: `SpellDocumentation.lua`,
`CombatDocumentation.lua`, `UnitDocumentation.lua`, ...). For any porting question of the
form "does this API exist / what does it take / what does it return on this client", **this
is ground truth** - prefer it over assuming retail/Classic API shape, since this client
carries a mix of backported and custom systems.

### Key semantics

- **Four realms, THREE game modes, one account-wide CAD file.** This client serves four
  realms: "Area 52 - Free-Pick" (classless), "Bronzebeard - Warcraft Reborn" (the Reborn\*
  classes), and **"Rexxar - Conquest of Azeroth" and "Vol'jin - Conquest of Azeroth", which
  are two realms of the SAME mode** (`gameMode=11`), not two content sets. Treat CoA as one
  thing throughout this dataset. `CharacterAdvancementData.json` - the source of everything
  in `data/classes/` - is **account-wide across all four realms**. Exactly ONE realm ships
  a client-side DBC overlay (Free-Pick's `Data\area-52\patch-D.MPQ`), and Bronzebeard/Reborn
  spell data is not part of this snapshot's `Spell.dbc` - so Reborn-class spell references
  resolve `null` far more often than other classes (~51%). Every class file and
  `data/classes/index.json` entry carries `realmHint` and `unresolvedCount`.
- **Class tags** (`data/classes/index.json`): `vanilla` (classic 9 + DK, 10 dirs), `reborn`
  (CoA revamps of originals, 11), `coa-custom` (Necromancer, Tinker, ..., 21), `meta`
  (non-class rows, 1). `classId` matches `ChrClasses.dbc` - the 21 `coa-custom` classes are
  ids **12-32**, not just 17-32 (Barbarian / WitchDoctor / Felsworn"DemonHunter" /
  WitchHunter / Stormbringer fill 12-16) - and this is the id client APIs like minimap
  blips use. `classId` is non-null for all 21 `coa-custom` dirs; three of them
  (DemonHunter, Monk, SonOfArugal) join `ChrClasses` on `filename`, not display name - see
  "The ChrClasses.filename join". `null` classId only means a `_other`/meta row.
- **Dispels**: `spell.dispel.name` in None/Magic/Curse/Disease/Poison/... A spell is a
  dispellable buff if it applies an aura (`effects[].effect.name == "APPLY_AURA"`) and
  `dispel.id != 0`. Dispel-CAPABLE spells have `effects[].effect.name == "DISPEL"`
  (miscValue = the dispel type id it removes). **Schema differs by file**: in
  `data/spells/by-id/*.jsonl` `dispel` is the `{id, name}` object; in
  `data/classes/<Class>/<Tab>.json` each entry's `spells[].dispel` is a plain string (or
  `null`) - the summary view drops the numeric id.
- **Ranks**: `rankChain` groups spell ranks (`first` = rank-1 spell id). Class entries list
  the first-rank spell with the full chain inline. The first-rank record also carries
  `rankAt60: {spellId, rank, cadLevel}` - the top rank obtainable at CoA's level-60 cap,
  **NOT `ranks[-1]`**, which requires level > 60 on most multi-rank chains and inflates
  values badly through the maxLevel clamp. Present on 1,686 chain-head records.
- **Tooltips**: `$` tokens (e.g. `$s1`, `$d`) are raw - server formulas are not evaluated.
  `effects[].basePoints` is the DBC convention: displayed value is usually
  `basePoints + dieSides` for fixed values. Cross-spell references embedded in this text
  (`$<id>m1`, `$?s<id>`, `@ifknown:<id>`) are followed into the dataset (depth-capped at 2);
  `@s:<id>` is a spellbook cross-link and deliberately NOT followed.
- **live / liveEvidence** (every spell record): `true` = a LIVE talent-tree node carries
  this exact id (`liveEvidence.reason: liveNode`), or the ability identity layer joins it to
  an ability that has one (`liveAbilityMember` - the trainer ladder, rank chain or catalog
  row of the same ability, a different id generation). `false` = the identity layer owns the
  id, its class's live tree WAS captured, and the ability has no node in it
  (`abilityWithNoLiveNode`) - the mechanical form of "the catalog lists it, the game does
  not have it". `null` has two reasons and they are different claims: `notAnAbility` = no
  ability owns the id (stock 3.3.5 content, trigger/formula closure spells, profession
  recipes), `noLiveGeometry` = an ability owns it but no live tree was captured for that
  class. **`null` is not `false`.** `_meta.json`'s `liveCoverage.classesWithLiveGeometry`
  lists the classes `false` is sayable about at all (classIds 12-32). When an ability owns
  the id, `liveEvidence` also carries `abilityKey`/`abilityName`/`classId`/`generation`/
  `generations` and, when the ability is live, `abilityLiveIds`.
- **referencedBy**: how a spell entered the set. LIVE-truth seeds first - `live` (a live
  talent-tree node carries this id, 3,932), `liveTrainer` (1,210), `liveRank` (644),
  `liveCad` (2,065 - an id the identity layer joins to the same ABILITY as a live node).
  Then the catalog seeds, kept but not the source of truth - `cad` (13,766), `rank`
  (10,497), `talent` (5,526). Then the closure - `trigger` (4,096, via
  `EffectTriggerSpell`; often the actual buff aura behind a cast) and `formula` (1,623, via
  a description/tooltip cross-spell reference). The tag reflects how a record was **first**
  reached; an id already reachable by another path does not get a retroactive tag.
- **Blank name vs null name.** `name: ""` (blank but non-null) is a WIP-content signature
  straight from the client - 222 records ship an empty `name_enUS`, every one of them
  reached through the `talent` seed. Do not treat `""` as missing data. An id that is referenced somewhere but has no
  `Spell.dbc` row at all produces no record; those ids are listed in
  `data/spells/_missing_refs.json`.
- **Talent coverage has three views - check the right one(s).** Only 12 classes have DBC
  `Talent.dbc` tabs (`data/talents/<ChrClass>.json`): the 10 vanilla classes plus Barbarian
  and WitchDoctor. Every CoA/reborn class drives its talents through
  `CharacterAdvancementData` entries instead - iterate the files listed in
  `data/classes/<Class>/index.json` and look for `type == "Talent"`/`"TalentAbility"` (or
  read the index's `entryCounts` for the type breakdown without opening a shard). For the 21
  `coa-custom` classes there is a third view: `data/talents/coa/<Class>.json` carries the
  actual TREE GEOMETRY (positions, prerequisite edges, connectivity, choice-group pairings,
  per-tab AE/TE gate tiers) that neither of the others has. CAD entries tell you an ability
  EXISTS and its flat cost; only the geometry layer tells you WHERE it sits and what unlocks
  it.
- **Creatures/quests/trainers are id-keyed facts, not a content browser** - see "Honest
  limits" for exactly what each one does and does not carry.
- **Mythic+/Challenges** (`data/mythic/`): `challenges/` is the CoA "Challenge Mode" feature
  (rules/modifiers/conditions/rewards per challenge, not Blizzard retail Mythic+ dungeons);
  `keystones/` + `scaling.json`/`timedDungeons.json` are the separate CoA Mythic+
  dungeon-scaling system, keyed by `LFGDungeons.dbc` ids shared with `data/dungeons/`. Two
  related but distinct systems under one directory.
- **Spell v2 enrichment** (`schemaVersion: 2`): records gain `tags` (alphabetical
  display-name list, deduplicated - two `tagTypeId`s that both decode to "Priest" collapse
  into one entry; 29,331 records), `customAttr` (10 raw u32s, no further semantics proven;
  9,584), `category` (bare int, only when `Spell.category != 0` and it resolves; 7,386),
  `descriptionVariables` (resolved tooltip-math text via `spellDescriptionVariableID`;
  1,530), `addon` (`{raw: [...]}`, 22 numbers; 183), `overrideData` (`{spells: [...], raw}`;
  6) - **every one of these keys is omitted, not `null`, when the spell has no data for it**
  (check `"tags" in spell`). `charges` is deliberately not one of them.

## Reference: spells

### Spell column completion - damage-modeling columns

Fill rates below are measured over the **CoA class spell set**
(`build_spells._coa_class_spell_ids()`: every spell id, including every rank-chain id,
referenced by the 21 `coa-custom` classes - 6,436 ids, of which **6,038** have a row in
base `Spell.dbc`). Per-effect fields are emitted only on populated effect slots, so a
record-level count can be slightly lower than the raw-column count.

**`EffectRealPointsPerLevel` (f77-79, `effects[].realPointsPerLevel`).** Backing store for
the `$ppl` formula token. CoA-set fill **2,011/6,038 = 33.3%**. **IEEE-754 float bit
patterns, not integers** - decode via `struct.unpack('<f', struct.pack('<i', v))`, same as
f216-218/f229-231. Golden: stock Frostbolt (116) slot 2 `f78 = 1056964608 = 0x3F000000 =
0.5f`.

> **The `maxLevel` clamp - per-level is a *value* channel, not a gear-scaling channel.**
> `realPointsPerLevel` determines the base number at a given level; it never varies with
> gear, and **1,715 of the 2,011 CoA spells with a nonzero rppl (85.3%) are capped below
> level 80** (`0 < maxLevel < 80`). The applicable formula:
>
> ```
> value = basePoints + dieSides + (clamp(60, baseLevel, maxLevel) - spellLevel) * realPointsPerLevel
> ```
>
> **`maxLevel == 0` is the DBC "uncapped" sentinel, not a literal level-0 clamp target.**
> **137 of the 2,011 nonzero-rppl CoA spells (6.8%)** carry `maxLevel == 0` (e.g. Hellish
> Rebuke 300391, Slagforged Armor 300931, Conductive 500005). A literal reading clamps
> toward 0, which is wrong. **Correct rule: when `maxLevel == 0`, drop the upper bound from
> the clamp** (use `min(60, ...)` against 60 directly). Those 137 are excluded from the
> 85.3% figure.
>
> `maxLevel` is emitted as `levels.max`, `baseLevel` as `levels.base`, `spellLevel` as
> `levels.spell` - nothing here applies the clamp for you, and a consumer that lets
> `realPointsPerLevel` scale past a spell's own `maxLevel` silently inflates its value.
> Frozen-rppl goldens, pinned in `tests/test_spells_columns.py`: Chronomancer
> *Decomposition* (800856, bp 12, rppl 0.11, maxLevel 12) and Necromancer *Ray of Rot*
> (804535, bp 11, rppl 0.47, maxLevel 26).

**`EffectSpellClassMask` (f122-130, `effects[].spellClassMask: [a,b,c]`) - which spells a
talent modifies.** Three u32 words (a 96-bit mask) per effect slot, omitted when all three
are zero. CoA-set fill (any slot nonzero) **1,730/6,038 = 28.7%**. Golden: stock talent
Improved Fireball (11069) slot 1's `ADD_FLAT_MODIFIER` aura carries
`spellClassMask: [1, 0, 0]`, and stock Fireball (133, same `spellFamilyName` 3 = Mage)
carries `spellFamilyFlags1 = 1` - bit 0 set on both, the exact selection mechanism.

**`SpellFamilyFlags3` (f211, `family.flags3`)** - the top 32 bits of the 96-bit family
mask, which a `flags1`/`flags2`-only view silently truncates. Fill 730/6,038 = 12.1%.

**`EquippedItemSubClassMask`/`EquippedItemInventoryTypeMask` (f69/f70)** - adjacent to the
already-mapped `equippedItemClass` (f68, also emitted as `equippedItem.itemClass`; its `-1`
"any weapon" sentinel histogram over the CoA set: `-1` x5547, `2` x461, `4` x30). Fill: f69
734/6,038 = 12.2%, f70 87/6,038 = 1.4%.

**`EffectPointsPerComboPoint` (f119-121)** - combo-point scaling (Ranger has combo points).
Fill 20/6,038 = 0.33%. Golden: Rage of Bethekk (501229) slot 1, a real `SCHOOL_DAMAGE`
effect, carries `pointsPerComboPoint: 8.0`. **Adjacent trap:** Serrated Shot (500073) slot
2 carries a nonzero raw `f120` while that slot's `effect` field is 0 - a dead-slot
artifact. The per-slot convention (`if not eff: continue`) drops that slot entirely, so the
dead value never reaches output.

**`EffectDamageMultiplier` (f216-218)** - chain-damage falloff per jump. The in-game default
`1.0f` is stored explicitly, so the field is present on most records (94.6% of the CoA set);
a **non-default** value (populated slot, neither `0` nor the `1.0f` bit pattern) appears on
**407/6,038 = 6.7%**. Compare against `1.0`, not against zero.

**`spellMissileID` (f227, `missileId`)** - exactly 8/6,038 = 0.13% nonzero, all of them
Invigorating Surge ranks sharing missile 9429.

> ### `EffectBonusMultiplier` (f229-231, `effects[].bonusMultiplierStock`) - not a CoA coefficient source
>
> Extracted and emitted, and correct for **stock and Reborn content only**. It is the
> untouched Blizzard-2008 column and it **contradicts** CoA's own tooltip-authored formulas
> on the same effect slot far more often than it agrees. CoA-set fill 619/6,038 = 10.25%.
> Golden: Flash Heal (2061) `f229 = 1062115213 = 0.8069999814...` (the genuine WotLK value),
> while its `description` reads `${$m1+$BH*0.158964+$AP*0.072}` - an AP-on-heal hybrid term
> that does not exist in stock 3.3.5a.
>
> **Agreement** (regex coefficient extraction from `description`/`tooltip`, 5% tolerance,
> over effect slots carrying both a nonzero `f229-231` and a parsed stat coefficient):
> **stock 0/65 agree (0.0%)**, **CoA 7/113 = 6.2%**. Near-zero either way. Re-runnable:
> `python -m tools.bonus_multiplier_agreement` prints both lines fresh against
> `work/dbc/Spell.dbc`. Unioning `bonusMultiplierStock` with the tooltip-parsed coefficient
> produces plausible-looking wrong numbers instead of a visible gap - the tooltip formula
> (`description`/`tooltip`, preserved verbatim, never normalized) is CoA's *only* real
> coefficient channel. CoA ships zero rows in TrinityCore's `spell_bonus_data` schema; its
> i18n table still carries "Spell coefficient" labels from a system it never wired up.

**Eight already-mapped columns that a naive read misses** (`speed`,
`equippedItem.itemClass`, `maxAffectedTargets`, `casterAuraSpell`/`targetAuraSpell`,
`manaPerSecond`, `targetCreatureType`, `casterAuraState`/`targetAuraState`, `stancesNot`)
need no new column proofs - they are named in `TABLE_MAPS["Spell"]`. CoA-set fill: speed
10.90%, maxAffectedTargets 11.97%, casterAuraSpell-or-targetAuraSpell 10.33%,
manaPerSecond 0.33%, stancesNot 5.60%, targetCreatureType 0.17%. Golden: Divine Storm
(53385) `maxAffectedTargets = 4`, the real WotLK 4-target cap.

**Confirmed zero-fill columns, verified before being skipped**: f207 `maxTargetLevel`, f43
`manaCostPerLevel`, f18 `RequiresSpellFocus`, f228 `PowerDisplayId`, f224 `AreaGroupId`,
f233 `spellDifficultyID` - all **0/6,038** nonzero on the CoA class set. f18/f224/f228 are
left unmapped; f207/f43/f233 are mapped for the full raw dump but excluded from
`spells.jsonl` and flagged in `_coverage.json`.

**Omit-when-zero convention for the 5 per-effect scaling fields**
(`realPointsPerLevel`/`pointsPerComboPoint`/`spellClassMask`/`damageMultiplier`/
`bonusMultiplierStock`): each is added to an effect's dict **only when its raw DBC word is
nonzero**, unlike `basePoints`/`dieSides` (always present once a slot's `effect` is nonzero,
since 0 is meaningful there). The 11 spell-level columns stay unconditional, matching the
record's top-level convention.

### Formula closure, level-60 ranks, `$scalingbp`, devDead

**(a) Formula-reference closure.** The `cad`/`rank`/`talent` seeds plus a transitive
`trigger` closure over `EffectTriggerSpell` do not reach spell ids embedded in
`description`/`tooltip` **text** - and CoA authors its damage scaling there, heavily
cross-referencing other spells (`${$573020m1*$<scalingbp>+...}` on Crusader's Brand). A
third, **depth-capped-at-2** pass follows three forms:

- `$<id><letter(s)><n>` - e.g. `$573020m1`, `$7376S1`, plus **multi-letter tokens** like
  `$80313ppl1`/`$202137PPL1` (a cross-spell `EffectRealPointsPerLevel` reference) and
  **no-trailing-digit** tokens like `$6788d` (another spell's duration) or `$49188h`
  (another spell's proc chance). `FORMULA_XREF_STRICT_RE`/`FORMULA_XREF_WIDE_RE` in
  `tools/build_spells.py` carry the full grammar, including false-positive shapes
  deliberately not chased (`$1%`/`$2%` are literal percentages) and one that is guarded:

  > **The `$1s` transposition-typo trap.** The no-trailing-digit widened shape collides
  > with a real authoring artifact - a same-spell `$s1`/`$m1` self-value token TRANSPOSED
  > by a tooltip typo into `$1s`/`$1m`. Rejuvenation (28722) reads
  > `"Restores $s1 mana.\n$1s mana restored."` - once correct, once transposed - and
  > misparses as a reference to spell id 1 (the "UPDATE YOUR CLIENT!" placeholder row).
  > **Confirmed on 28 spells** sharing this template (Rejuvenation / Surging Mana /
  > Nature's Bounty / Adrenaline Rush / Healing Touch / Lesser Healing Wave / Consume
  > Essence / Consume Life / Elune's Touch / Revitalize / Infusion / Efficiency / Soul of
  > the Dead, across their rank chains). **Guarded by splitting the grammar**: the literal
  > single-letter-mandatory-trailing-digit shape stays unrestricted (a transposed `$s1` can
  > never produce a trailing digit, so it structurally cannot collide, and it is proven safe
  > down to 2-digit ids - Vindication 67's `$67s1`). The widened forms additionally require
  > the candidate id to have **>=3 digits**: every legitimate cross-ref this grammar
  > resolves is 3+ digits, and the transposition class is always the 1-2 digit number meant
  > to be the token's own rank/effect suffix. Canaried in `tests/test_closure_ranks.py`: no
  > id < 1000 may appear among formula-only-tagged records.
- `$?<letter(s)><id>` - also spelled `$?a<id>`/`$?S<id>`/`$?j<id>`, so the letter is
  generalized rather than hardcoded to `s`.
- `@ifknown:<id>`.

**`@s:<id>` is deliberately NOT followed** - it is a spellbook cross-link, not a formula
channel. Structurally verified: none of the three followed regexes can match an `@s:`
token - pinned in `tests/test_closure_ranks.py`.

**Closure delta**: depth 1 +1,580 / depth 2 +43 = **1,623 new records**. Of the 5,828
distinct ids the formula text references, **5,644 (96.8%) resolve** to a row in base
`Spell.dbc`; the 184 that do not are listed in `_missing_refs.json`'s `formula` bucket
(report-only, never folded into the hard gates). A depth-3 pass was measured and not
applied: **+3 records**. Full breakdown in `data/spells/_meta.json`'s `formulaClosure`.

> **A coefficient may be bound to a non-damaging effect slot.** This closure widens which
> SPELLS are in the dataset; a consumer building a coefficient binder (matching a formula's
> `$mN`/`$sN` tokens to the effect slot carrying the matching `basePoints`) must not assume
> the match sits on a damaging slot. CoA frequently binds a coefficient to a non-damaging
> slot used purely as a scaling handle - Barbarian *Gutspiller* (805832) carries `$RAP*0.4`
> on slot 2 (aura 227, a modifier) while slot 1 holds the actual bleed; *Dawnfall* carries
> `$SP*0.12` on slot 2 (aura 23, `PERIODIC_TRIGGER_SPELL`). A per-slot binder that only
> checks damaging slots reports these as unscaled holes when the coefficient is on an
> adjacent slot. This dataset does not build that binder.

**(b) `rankAt60` - level-60 rank selection.** `ranks[].level`/`.spellId` are exposed per
rank inside `data/classes/<Class>/*.json`. On the `spells.jsonl` side, the chain's own
first-rank record (`rankChain.first == id`) carries `rankAt60: {spellId, rank, cadLevel}` -
the highest rank whose CAD level is `<= 60`. Present on **1,686** chain-head records;
omitted entirely (no null-noise) for chains where even rank 1 requires CAD level > 60.

**Why it matters**: `ranks[-1]` (global top) requires level > 60 on most multi-rank CoA
chains and, through the maxLevel-clamp formula, inflates a spell's value substantially.
Worst-case golden, re-derived at test time in `tests/test_closure_ranks.py`: Runemaster
*Spellsling* (chain head 802202) - the global top is rank 12 (spellId 502838, `levels:
{base:80, spell:80, max:80}`) which clamps to **3,365**, while `rankAt60` selects rank 9
(spellId 502835, `levels: {base:68, spell:68, max:72}`, `cadLevel: 54`) which clamps to
**509**.

> **The gating field is inferred and unresolved.** CAD `ranks[].level` and DBC `spellLevel`
> agree on only **33.2%** of rank rows (746 of 2,248 measured over the coa-custom classes'
> multi-rank chains) and select a **different** level-60 rank on **216 of 360** such chains.
> `rankAt60` follows **CAD level**, on the basis that CAD is what grants a rank here; that
> is not independently verified, and DBC `spellLevel` runs systematically higher, which
> would pick an even lower rank on the disagreeing chains. Confirming the actual in-game
> gating behavior is required before trusting `rankAt60` for anything beyond "roughly which
> rank".

**(c) `$scalingbp` - named constant.** `data/spells/_meta.json`'s
`scalingConstants.scalingbp` (`SpellDescriptionVariables.dbc` row id 182, referenced by
**552** spells via the literal `$<scalingbp>` token). Coefficients are **parsed out of the
live SDV row text at build time**, not hardcoded, so a client patch that changes them fails
the build's own assert instead of silently drifting. Value table:
`0.0318@1, 0.1982@20, 0.5184@40, 0.8562@55, 0.9874@60, 1.0148@61, 1.2777@70, 1.6052@80`.

> **It is a level normaliser, NOT a stat coefficient.** It crosses 1.0 at `$PL ~= 60.46`
> and sits at **0.9874 at CoA's level-60 cap** - independent quantitative confirmation the
> content is authored at a 60 cap. A consumer multiplies a spell's `basePoints` by this
> value when that spell's formula text references `$<scalingbp>`; it carries no gear/stat
> scaling.

**(d) `devDead` flag.** Set on any record whose `description`/`tooltip` carries the literal
marker `"DOES NOT WORK, YOU SHOULD NOT HAVE IT"`. **Not** a loose "does not work" substring
match - that false-positives on ordinary tooltip caveats (Pyromancer *Pyrolate*'s "Does not
work with Elemental Destr[uction]" is real game text). Scanning every `Spell.dbc` row, not
just the build-reachable set: **exactly 7 records**, all one rank chain - Pyromancer *Flame
Swell*, spellIds 502065-502071.

### Damage-model coverage: measure it over castable content, not the catalog

**89.3% of the damaging/healing effect slots a level-60 character can actually CAST are
modelable (493 of 552); 59 are holes, 20 distinct `(spellId, slot)` pairs.** That is the
number to plan against. Regenerate with `python -m tools.coverage_live`; output lands in
`data/spells/_coverage_live.json`.

| denominator | slots | modelable | % | holes | distinct hole pairs |
|---|---:|---:|---:|---:|---:|
| CAD catalog | 1,429 | 1,151 | 80.5% | 278 | 101 |
| **live only (`live == true`)** | **552** | **493** | **89.3%** | **59** | **20** |
| live + indeterminate (`live != false`) | 1,002 | 901 | 89.9% | 101 | 36 |

The CAD figure is not wrong arithmetic - it is the same pipeline over a denominator that
includes effect slots on entries no player can cast: **65 of its 101 distinct hole pairs
(64%) exist only in `deadCatalog` content**, and of the 92 level-curve-only hole pairs,
**74 (80%) are not proven live** (59 dead, 15 indeterminate), leaving 18 units of probe
work rather than 92.

The live figure is a **lower** bound and the live+indeterminate figure an **upper** bound,
because `live: null` is a genuine unknown; liveness is **consumed** from each entry's
`live`/`liveEvidence` flag, never re-derived here. **10 of the 21 CoA classes have zero
PROVEN-LIVE holes** (DemonHunter, Guardian, Monk, Necromancer, Ranger, Reaper, Runemaster,
Starcaller, Stormbringer, SunCleric) - but "zero live holes" is not "zero holes": SunCleric
still carries 2 indeterminate holes (502394 slot 1 *Sunflare*, 502446 slot 1 *Divine
Vision*) and Monk 1 (801165 slot 3 *Temple Guardian*).

The live denominator is also mildly **over**-inclusive, measured rather than assumed small
in `livenessSource.liveDenominatorSlack`: `live` is stamped per ENTRY but consumed per
CHAIN, so 174 of the 3,630 live chains (4.8%) enter it on a spell id that is in no live
node - they ride on a sibling spell of the same multi-spell entry - and 289 live chains
measure a different rank than the matched node holds, because the rank is picked by level
(`rank.level <= 60`), not by the node.

Two consequences worth carrying:

- **SunCleric *Sunflare* (502394 slot 1) is `indeterminate`, not proven live.** Its CAD
  entries match no live builder node. Confirm a character can learn it before spending a
  measurement on it, or pick from `liveHoles`.
- Starcaller *Silvercurrent* (503051) is reached only through the `deadCatalog` entry
  *Douse* - the same content a level-60 Starcaller's tree list shows as absent. The liveness
  join and the tree list agree independently.

Method is documented in the script's module docstring and mirrored into the JSON's `method`
block: BASE `raw/dbc/Spell.csv.gz` only (never a realm overlay), the 21 `coa-custom`
classes, `Ability`/`Talent`/`TalentAbility` entries, highest rank with CAD
`rank.level <= 60`, damaging/healing slot sets (aura 118 is `MOD_HEALING_PCT`, **not** a
heal; aura 227 `PERIODIC_TRIGGER_SPELL_WITH_VALUE` is deliberately outside the denominator
and is the largest boundary uncertainty), and W/P/T scaling channels where only W and T are
gear channels. Coverage says a channel EXISTS to model - not that the number is right.

## Reference: classes and live truth

### Live vs catalog: `live` / `liveEvidence` on every CAD entry

`data/classes/` is the CAD **catalog** - what the client's character-advancement tables
LIST for a class. Every entry carries the verdict:

| field | meaning |
|---|---|
| `live: true` + `liveEvidence.reason: "liveDirect"` | one of the entry's own spell ids IS a live builder node's spell (`matchedSpellId`, `builderTab`, `builderNodeId` name the hit) |
| `live: true` + `"liveViaRank"` | no own id matched, but another rank of the same `SpellRankData` chain did **and that chain is name-coherent** |
| `live: false` + `"deadCatalog"` | not in the live trees by any rank, and **no evidence of any acquisition path this dataset can probe** - treat as cut/legacy, but read "no evidence" as exactly that, not as proof |
| `live: null` + `"indeterminate"` | not in the trees, but carries a non-tree acquisition signal (`liveEvidence.signals`) |
| `live: null` + `"unknownNoGeometry"` | the class has no builder capture at all (the 10 vanilla + Reborn/meta dirs) - nothing is claimed either way |

Matching is **spell-id equality only** - no name matching enters the verdict. Entries with
`live == true` are `liveDirect + liveViaRank`; `unknown` merges the two `live: null`
reasons so the four `liveCounts` keys sum to `entryCount`. The rule lives in
`tools/coa_live.py` and is imported by both writers (`build_classes` owns
`data/classes/**`, `build_coatalents` owns `data/talents/coa/**`) so neither can drift from
the other.

Repo-wide (re-derived every build into `_live_summary.json` and each class's `index.json`):
**3,417 liveDirect + 6 liveViaRank, 3,460 deadCatalog, 1,448 indeterminate, 15,378
unknownNoGeometry** of 23,709 entries. Restricted to the 21 classes that HAVE a builder
capture: 8,331 entries, of which **4,908 (58.9%) are not in the live trees at all**.

**`live` is an ABILITY-level claim, never a row-level one.** 781 entries flagged
`live: true` sit on CAD rows the client's OWN loader discards -
`raw/interface/FrameXML/Data/CharacterAdvancement.lua:68` skips any entry whose `Flags`
carry `Deprecated` (0x1) or `Disabled` (0x8) before the UI ever sees it. The ability is
live; it reaches the player through a sibling duplicate row, not through this one.
`entry.flags` is emitted verbatim for the row-level view. Measured every build into
`_live_summary.json.falseNegativeMeasurement.rowLevelVsAbilityLevel`, which also records
that this flag was tested as a discriminator for the 324 `liveNodeNameTwin` indeterminates
and **rejected**: it fires on 34.0% of them but also on 22.8% of proven-live rows, so it
has no specificity.

**The `liveViaRank` gate, and why it is not decoration.** `SpellRankData` contains recycled
contiguous id blocks that are not rank ladders - 94 of the 2,130 chains carry more than one
distinct spell name. Chain head 801667 runs rank 1 `Revitalize (Rank 1 DEPRECATED)`, rank 6
`Ascetic Abdication`, rank 7 `Fearmonger`, rank 8 `War Cry`, rank 9 `Umbral Glaive`, rank 10
`Ice Hide`, rank 11 `Mirage` - so an unguarded rank join would declare WitchDoctor's CAD
`Revitalize` live because `Mirage` (501136) is a live node. `liveViaRank` therefore fires
only when the chain carries **at most one distinct `Spell.dbc` name**; a rejected match is
kept as `liveEvidence.rejectedRankMatch` on the row it disqualified rather than thrown away.
Ids with no `Spell.dbc` row carry no name and so cannot break coherence - which is what
keeps WitchHunter `Interrogate` (802012, no `Spell.dbc` row) correctly live via rank 8 of
its own chain, 501380 = the live node `Brand of the Unworthy`.

**Scope of the live verdict.** The capture is the CoA-mode builder payload (served from the
`voljin` URL; Vol'jin and Rexxar are the same game mode, so there is no second realm's trees
to be missing). The real scope limit is *time*: the published builder and this repo's client
snapshot drift apart, so an ability the builder has not caught up to looks dead. That is
compounded by `data/classes/` being **account-wide** - CAD entries arrive from every mode an
account has touched, so a non-CoA entry with no CoA tree node is correctly `live: false` for
CoA while being perfectly alive elsewhere. Provenance (capture date + sha256) travels in
`_live_summary.json.payload`.

**The false-negative risk is measured.** The builder payload shows the TREES; anything CoA
grants outside a tree would look dead while being live. Four probes run over the 4,908
not-in-trees entries, all written up in `_live_summary.json.falseNegativeMeasurement`:

- **`skillLineAutoGrant`** - 183 entries (3.7%). `SkillLineAbility.acquireMethod != 0`, i.e.
  automatically granted. **Separable and trustworthy**: `acquireMethod` is stock 3.3.5
  semantics, generation-independent, and perfectly disjoint from the live node set (0 of the
  live builder's spell ids carry it). The population is overwhelmingly weapon/armour
  proficiencies (Fist Weapons, Polearms, Plate Mail, Dual Wield, Auto Shot, Block, Staves,
  Wands) - exactly the "baseline, not via a tree node" class.
- **`npcTrainerRow`** - 1,028 entries (21.0%). **Real but NOT separable offline**:
  `NPCTrainer.dbc` in this snapshot is contemporary with the live generation in at least 20
  verified instances. 166 trainer rows sit under the skill lines "Moon Guard", "Moon
  Priest", "Warden" and "Headhunting", and 20 of them teach a name-coherent rank variant of
  an ability whose base rank IS a live node: Shooting Star ranks 5-7 (Warden) -> live node
  800505, Prayer of Elune ranks 2-5 (Moon Priest) -> 801987, Headhunter's Spear ranks 2-7
  and Berserker Axe ranks 2-8 (Headhunting) -> 804137 / 804138. What this is not: it is not
  a claim that those skill-line NAMES belong only to live content - `SkillLineAbility` files
  the proven-dead Tide Lash (800380) and every `Tides` sibling under skill line 92 "Moon
  Priest", the live name of the very slot the tab mapping says was CAD "Tides". A trainer
  row is evidence of a non-tree path, but the CAD row hanging off it can equally be a
  retired duplicate.
- **`liveNodeTriggerSpell`** - 99 entries (2.0%). The entry's spell is an
  `effectTriggerSpell{1,2,3}` of a spell that IS a live node **of the same class** - the game
  casts it every time that node procs. **Mechanistic, not statistical**: its base rate barely
  differs between live and not-in-trees entries, so no correlation search would surface it.
  Examples: Monk `Light's Reach` 804907 (`Spell.dbc` "Transcending Strikes", rank "Trigger")
  from live node 804897; Ranger `Commander` 705078 ("Plumes of War", "Proc") from 705071;
  Chronomancer `Word of Balance: Mend` 806314 from 806312; Barbarian `Improved Wrist Snap`
  804862 ("Jawbreaker", "Success!") from 705196.
- **`liveNodeNameTwin`** - 324 entries (6.6%). The entry's NAME matches a live node in the
  same class while none of its spell ids do: the spellId-variant drift measured in
  `data/talents/coa/_meta.json`'s `contentDrift`. The ability is live; whether THIS row is
  the live variant is unknowable offline.

Union: **1,448 entries (29.5% of not-in-trees) ship `live: null` / `"indeterminate"` with
their firing signals listed, rather than being guessed `false`.** The remaining 3,460 carry
no acquisition evidence of any kind and are the honest `live: false` - "honest" meaning no
probe in the set above fires, which is a statement about the probe set as much as about the
content; assume a fifth path may exist. A plausible-looking heuristic - "low `requiredLevel`
+ `type == Ability`" - was tested and **rejected by measurement**: it fires on 28.4% of
not-in-trees entries but also on 16.9% of proven-live ones.

**CAD tab names and live tab names are DIFFERENT GENERATIONS** of the same tree slots
(Starcaller CAD `Tides` is live `Moon Priest`; Barbarian `Tactics` is `Headhunting`;
Chronomancer `Time` is `Artificer`). All **84** CAD (class, tab) pairs map onto a live tab in
`_live_summary.json.tabMapping`, each carrying its method and evidence: **58 by
`chrSpecsSpecName`** (a `ChrSpecs` row whose `tabToken` IS the CAD tab and whose `name` IS
the live tab - the client's own row linking the two generations) and **26 by `sameName`**.
`nodeOverlap` runs on every pair as an independent cross-check - **80/84 agree (95.2%)**,
and the 4 that do not are recorded with their counts, not resolved away. 9 live tabs have no
CAD ancestor at all: the genuinely new trees (Warden, Fleshweaver, Valkyrie, Mountain King,
Vizier, Black Knight, Dreadnought) plus the empty `None`/`Blessings` placeholders.

**`specs.json` `tabStatus`.** Each state names exactly what it asserts:

| status | meaning | count |
|---|---|---|
| `inLiveBuilder` | the spec's tree IS in the live builder; `liveTab` names it and `renamed: true` flags a live name differing from the CAD one | 70 |
| `cadOnly` | the tree exists ONLY in the catalog - no live tab maps to it | 0 today |
| `noLiveGeometry` | class has a CAD tab layer but no builder capture - liveness NOT claimed | 30 |
| `noCadClass` | class has no `data/classes/` directory at all (Hero, classId 10) | 1 |

**25 of the 70 `inLiveBuilder` specs are `renamed: true`** - browsing `data/classes/` would
give a different tree name than the player sees. The match ladder tries `ChrSpecs.name`
BEFORE `tabToken`, because `name` is the live-generation label and `tabToken` the
catalog-generation one: spec 33 is named "Artificer" with `tabToken: "TIME"`, while the live
tab literally named "Time" is a DIFFERENT tree (spec 31, `tabToken: "DISPLACEMENT"`) -
token-first silently swaps them. Spec-name matching is also what resolves VALKYR ->
"Valkyrie" and WITCHKNIGHT -> "Black Knight", which no normalized token match reaches, and
attributes HYDROMANCY to Starcaller's live "Warden" and BULWARK to Cultist's "Dreadnought".

`build_classmeta.py` READS the mapping from `_live_summary.json` rather than re-deriving it
(single-writer rule), so `build_classes.build()` must run first - asserted at build time.
`build_classmeta.build()` also requires `data/talents/coa/_meta.json`, so `datamine.curate()`
runs `build_coatalents.build()` right after `build_classes` and before
`build_talents`/`build_dungeons`/`build_creatures`/`build_classmeta`. Gated by
`tests/test_live_flags.py` (schema, count consistency, the Starcaller ground-truth pins, the
false-negative measurement, tab-mapping injectivity, the `tabStatus` states).

### Ability identity layer (`data/abilities/`)

One CoA ability exists under several unrelated spell ids across content generations, and the
client ships no join table. `tools/build_abilities.py` builds that join from `raw/` only - no
`data/` input at all, so it is a pure function of the snapshot.

**Group key** `(classId, normalized spell name, live-node variant)`. Normalization is
mechanical and re-measured every build into `_meta.json.nameNormalization`: strip trailing
`Rank N` markers (repeatedly), then lowercase and delete every non-alphanumeric character.
Nothing else is stripped - the base `Spell` table keeps the rank in its OWN column
(`rank_enUS`/f153, 2,983 distinct values), so exactly 21 of 209,151 names carry a trailing
rank marker at all; trailing roman numerals ("Fire Shield II", 508 names) and trailing bare
digits ("Wavestorm 2", 3,880) are deliberately left alone because they are not the rank
carrier and stripping them would merge distinct spells.

**Four generations**, each a member id's provenance, precedence
`liveNode > trainer > cad > rankChain` (a member can carry several):

| Generation | Source | Class evidence |
|---|---|---|
| `liveNode` | `raw/talents/coa-builder-<slug>.html` (RAW holds the payload; `data/talents/coa/` is a derived copy of the same parse and is NOT read here) | the node's own `classId` |
| `cad` | `raw/content/CharacterAdvancementData.json` | the row's `Class` string -> `ChrClasses`, normalized name then filename token, leading `Reborn` stripped |
| `rankChain` | `raw/content/SpellRankData.json` | inherited along a NAME-COHERENT chain from a member that already has one |
| `trainer` | `raw/tables/NPCTrainer/` | none of its own - see the admission rule |

**Names come from the BASE `Spell` variant**
(`raw/tables/Spell/variants/data-patch-t-mpq/`), not the chain winner at
`raw/tables/Spell/`, which is area-52's realm overlay. All 3,932 live-node spell ids resolve
in the base variant and only 3,929 in the overlay - reading the overlay silently loses live
CoA content.

**Trainer admission rule.** A trainer row always MARKS an id it already shares with another
generation. An id known only to `NPCTrainer` is admitted only with corroborating class
evidence: a single-class `SkillLineAbility` classMask, or a `skillLine` shared with an
existing member of exactly one same-named ability. A bare name match is refused and lands in
the residual as `trainerNameOnlyNoCorroboration`, candidate keys attached, so the refusal is
inspectable. Measured: **zero** live-node ids are directly taught by a trainer row - every
live/trainer link runs through the rank chain or that corroboration.

**Two traps this layer is explicitly built against**, both quantified in `_meta.json`:

- *Dense id spaces make containment meaningless.* The base `Spell` id space is 209,151 ids
  over 1..13,977,920 (1.5%), but across the 23 100k-blocks the four sources touch, occupancy
  averages **9.0%** and peaks at **69.0%**. So "this id exists in `Spell.dbc`" is never used
  as a join here - every membership needs a row that names a class or a chain.
- *`SpellRankData` contains recycled non-chains.* 94 of 2,130 chains carry more than one
  distinct spell name: contiguous id blocks reused for unrelated content. Chain expansion is
  gated on name coherence and incoherent chains are dropped whole; `tests/test_abilities.py`
  pins the gate both ways (removing the gate fails that test).

**Same ability under two names is NOT merged** - a shared member id is not proof two names
are one ability, and merging on it would cascade through the vanilla chains. Instead every
shared member id is recorded on both records as `linkedKeys` (`relation: sharedMemberId`),
one hop away. **147** abilities carry such a link; the canonical case is WitchHunter 802012,
which CAD names "Interrogate" while the live node for the same rank chain is "Brand of the
Unworthy".

**Two different abilities under ONE name is the mirror image, and it is SPLIT.**
`(classId, name)` is not an identity: **35** name groups hold two or more DISTINCT live
builder nodes, 22 of them across different tabs, and all 35 carry different base-`Spell`
descriptions - `c12:savage` would otherwise be one record holding Brutality's 560441
("Unbridled Rage now also increases your critical damage") and Headhunting's 705242 ("Born
in Blood now also increases your damage"). The gate is mechanical: two distinct live nodes
stay in one record only when their EFFECT SIGNATURE agrees (the node's own name plus, over
every spell id it carries, description / tooltip / effect triple / effect-aura triple /
effect-miscValue triple / icon). Disagreeing nodes split into one record per signature, keyed
`c<class>:<name>#<lowest live spell id>`, cross-referenced through `linkedKeys` (`relation:
liveNodeVariant`); the bare `c<class>:<name>` key of a split name is left to members no live
node claims, so it can never silently mean one of the variants. Read
`liveNodeVariant`/`liveNodeVariantOf` on a record and `_meta.json.liveNodeVariantGate` for
the full split list.

**Headline counts** (re-derived every build): 8,784 abilities, 2,865 spanning more than one
generation, 3,618 live, 657 with a rank ladder (201 of them live), 35 split names -> 71
variant records + 3 unattributed bare keys, **0** abilities holding two distinct live nodes,
14,286 residual ids joining nothing (0 of them from `liveNode`).

### CoA talent tree geometry

CAD entries tell you an ability *exists*, but not where it sits in a tree, what unlocks it,
or what it competes against. `data/talents/coa/<Class>.json` (21 files,
`tools/build_coatalents.py`) closes that gap for all 21 `coa-custom` classes, built from the
published `https://ascension.gg/en/v2/coa-builder/voljin` builder payload, frozen by
`tools/fetch_coatalents.py` into `raw/talents/coa-builder-voljin.html` + `_fetch.json` - a
deliberate, occasional NETWORK step kept separate from the offline curation stage.

**This capture is the one piece of `raw/` that is NOT on the client's clock, and therefore
the dataset's dominant residual drift risk.** Curation is a pure function of `raw/`, but
`fetch_coatalents.py` runs outside the guarded pass and cannot be folded into it - the client
has no copy of the live builder - so everything derived from `live` is only as current as the
last fetch. The gap is measured: `raw/provenance.json.liveSeedDrift` and
`data/abilities/_meta.json.liveSeedDrift` carry the capture's `capturedUtc`, the newest
client-archive mtime in `raw/_snapshot.json`, and `captureMinusSnapshotDays` between them
(negative = the capture predates the client files, so content the client already has can read
as dead). Both numbers come from committed bytes, so a rebuild reproduces them. The page is a
Next.js "flight" payload; extraction locates an anchor and `raw_decode`s past trailing garbage
in `self.__next_f.push([id,"..."])` chunks - technique in the module docstring.

**The page embeds TWO near-identical copies** of the full node set side by side (`slug`
"voljin-alpha" id 39 and "voljin" id 40 - same 3,618 nodes/ids/geometry, differing only in
tooltip description text). That is why every field name greps to exactly **7,236** raw
occurrences in the fetched HTML: 2 x 3,618, not 7,236 distinct nodes. This module uses only
the `slug="voljin"` copy.

**Resolve rates, and which one the build gates on.** Payload spell ids against the raw client
`Spell.dbc` (any row at all, 209,151 total) resolve **100%** (3,618/3,618,
`unresolvedSpellIds: []`), and against the curated `data/spells/` also **100%**. Against CAD
rows the figure is only **78.8%** (`idMatchesAnyCadRow`, 2,851/3,618) - a fact about the
catalog's id generation, not about this dataset's reach. The build gates hard on the
raw-`Spell.dbc` figure (bar 0.95) and still ships `spellResolved` per node, because a
refreshed capture against an older client snapshot could genuinely reintroduce a gap and it
must be visible per node.

**Tab counts: 84 vs 96 vs 72.** "84" (4 tabs x 21 coa-custom classes) holds exactly when
recomputed from `data/classes/` - every class has precisely 1 Class + 3 spec tab-name buckets.
The payload's "72" is a count of DISTINCT `tabId`s, a different thing: the live builder carries
**96** (classId, tabId) assignment pairs - more than 84, because 10 of 21 classes have grown a
5th or 6th tab slot since the catalog generation - which collapses to 72 purely through numeric
id REUSE: `tabId 87` ("Class") is the same id on all 21 classes' Class trees (21 assignments ->
1 id, -20), and `tabId 1` ("None") / `tabId 71` ("Blessings") each get reused (-3 / -1);
96 - 24 = 72 exactly. Of those 96 pairs, only **5** are EMPTY placeholders (WitchHunter /
Guardian / Pyromancer / SunCleric's "None" slot, Chronomancer's borrowed-but-unauthored
"Blessings" slot); 5 of the 10 grown classes (SonOfArugal, Primalist, Venomancer, Starcaller,
Cultist) gained a genuine 5th tab with real content (38-44 nodes apiece). Of the 7 spec tokens
the catalog layer carries with no CAD tab, **5 appear in the payload as shipped trees** -
SonOfArugal/FLESHWEAVER -> "Fleshweaver" (44 nodes), SunCleric/VALKYR -> "Valkyrie" (42),
Primalist/MOUNTAINKING -> "Mountain King" (40), WitchHunter/WITCHKNIGHT -> "Black Knight"
(38), Venomancer/VIZIER -> "Vizier" (41) - while Starcaller/HYDROMANCY and Cultist/BULWARK do
not appear by a matching tabName, though those two classes each picked up a different extra tab
(Starcaller "Warden" 40 nodes, Cultist "Dreadnought" 38). Full per-token table in `_meta.json`'s
`tabLayerReconciliation`.

**`isStartingNode` is PARTIALLY proven - not simply unreliable.** Only 2 of 3,618 nodes carry
it nonzero, and the two are NOT equally trustworthy. Node 7608 (Cultist "Abyssal Ward",
`isStartingNode: 1`, empty `requiredIds`) **is** a real tree root: two sibling nodes - 4040
"Obliteration" and 7512 "Dreadnought" - directly list `7608` in their own `requiredIds`. The
other nonzero entry, node 30212 (SunCleric "Hope", `isStartingNode: 127` - not a 0/1 boolean, a
genuine data anomaly), is unreferenced by anything. Separately, and not a contradiction: 96.5%
of nodes (3,493/3,618) have an EMPTY `requiredIds` - CoA's trees are gated primarily by
`reqTabAE`/`reqTabTE` per-row investment thresholds, not a classic Blizzard prerequisite chain
rooted at one flagged starting node; `requiredIds` gates only 171 refs at all (all resolving,
all same-class). `connectedNodeIds` resolve 5,488/5,490 = 99.96%. Net: `isStartingNode` is real
and correctly wired where present, far too sparse to be the general "is this a tree root"
signal - `requiredIds == []` is the broader structural proxy.

**`reqTabAE` gates the Class tree; `reqTabTE` gates every spec tree - a clean split, confirmed
against the client's own XML wiring.** `reqTabAE` is nonzero ONLY on `tabId 87` ("Class",
shared by all 21 classes) - tiers step 0 -> 9 -> 24 by row there. `reqTabTE` is nonzero on
**every spec tab** (tiers 0 -> 8 -> 23) and sits flat at 0 on the Class tab - the *opposite*
pattern, not "AE/TE both only live on the Class tree".
`raw/interface/AddOns/Ascension_CoATalents/CoATalentFrame.xml` proves it by construction: the
`$parentClassTree` frame wires `getEntryGateRequirement` to
`CoACharacterAdvancementUtil.GetEntryAEGateRequirement` and `gateCurrencyCount` to
`C_CharacterAdvancement.GetPendingTabAEInvestment`; the sibling `$parentSpecTree` frame wires
the TE equivalents instead.

**Choice groups are a real, clean structure.** Every nonzero `group` value pairs EXACTLY 2
entries (0 exceptions across 292 groups), always sharing identical `(classId, tabId, x, y)`
and differing only in `spellId`/`name` - the client's choice-node concept
(`CoATalentChoiceButtonTemplate`, `node:IsChoiceNode()`). The `choiceGroups` array surfaces
this directly so a consumer does not re-derive it from raw `group` values.

**The base CAD JSON's own geometry-shaped columns are a false friend, not a fallback.**
`CharacterAdvancementData.json` also carries
`PositionX`/`PositionY`/`ConnectedNodes`/`RequiredIDs`/`RequiredAEInvestment`/
`RequiredTEInvestment` (13-15% row coverage, no numeric tabId at all - `Tab` is a bare
string). Investigated as a possible client-Lua-only fallback source and rejected: for the
2,851/3,618 payload nodes whose `id` DOES match a CAD row, agreement is near-zero (exact
PositionX/Y match on a small minority; ConnectedNodes average Jaccard similarity ~0.02).
These columns serve the client's narrower decorative-line UI, a different thing from gameplay
tree geometry despite the matching field names.

**Which builder this is.** The payload is served from the `voljin` URL. Vol'jin and Rexxar are
two realms running the SAME game mode, so this is a **CoA-mode** capture, not a one-realm
sample: the trees are mode content, shipped in the base chain both realms read. The residual
risk is not "Rexxar might have different trees" but the ordinary one that applies to any single
fetch - the published builder can drift from the client snapshot. Re-run
`tools/fetch_coatalents.py` and diff the pinned sha256 rather than hunting for a second realm's
payload.

### Essence curves, the ChrClasses filename join, overlay-diff tooling

**(a) `CharacterAdvancementEssence` -> `data/classes/essence.json`.** Golden-proven directly
against `work/dbc/CharacterAdvancementEssence.dbc`: f1 = level (1-80), f2 = classId (1-32),
f7 = Ability Essence, f8 = Talent Essence, 5,600 rows. Goldens, all exact: the 10 non-Hero
"classless" ids (classId 1-9, 11) at level 60 = (60, 51) - the classic 51-talent-point number;
Hero (classId 10) at level 60 = (100, 51); all 21 CoA-custom classes (classId 12-32) share ONE
identical curve (L10 (1,0) -> L20 (6,5) -> L30 (11,10) -> L40 (16,15) -> L50 (21,20) -> L60
(26,25) -> L70 (31,30) -> L80 (36,35)). f3-f6 are 4 unmapped per-row flag columns (8 combos
observed); for every class except Hero, every combo at a given (classId, level) carries the
IDENTICAL AE/TE pair, so the flags are immaterial. Hero is the sole exception, carrying up to
8 DIFFERENT pairs per level (level 60 also reads (100,71)/(60,25)/(44,51)) - an inert,
unresolved finding, since Hero is not a playable CoA class in this snapshot.
`tools/build_essence.py` always selects the flags-(0,0,0,0) row, present exactly once per
(classId, level) pair (2,560 = 32 x 80, verified) and the row that reproduces every golden. It
is a **separate module** from `build_classmeta.py` (which owns `specs.json`/`archetypes.json`
only) and reads `work/dbc` alone - no dependency on `data/classes/` existing.

**(b) The `ChrClasses.filename` join.** `ChrClasses.dbc` carries a second name column,
`filename` (f55) - an internal uppercase token, DISTINCT from `name_enUS` (the display name).
**Join classes on `filename`, not on display name**: three CoA class directories
(DemonHunter / Monk / SonOfArugal) have no ChrClasses row matching their display name at all,
because their real row uses a different display name whose `filename` equals the CAD class
name - id 14 `name_enUS="Felsworn"` `filename="DEMONHUNTER"`, id 19 "Templar" -> "MONK", id 20
"Bloodmage" -> "SONOFARUGAL". Cross-checked against the client's OWN
`raw/interface/FrameXML/Data/CharacterAdvancement.lua` `ClassRemap` table (applied to every CAD
entry at load time): every one of its ~32 CAD-name -> token pairs equals this column's value
for the matched row, including the 4 cases where the token is not a trivial uppercase of the
display name (Runemaster -> SPIRITMAGE, Primalist -> WILDWALKER, Venomancer -> PROPHET, "Knight
of Xoroth" -> FLESHWARDEN) - those 4 already had a working classId, so the alias is purely
informational and surfaces as the `aliases` field. **Content sanity check**, not just string
matching: the DemonHunter CAD dir's own tab names (Class/Demonology/Felblood/Slaying) match
`ChrSpecs` rows whose `classToken == "DEMONHUNTER"` tab-for-tab (the same check holds for
Monk/Templar and SonOfArugal/Bloodmage).

Both `build_classes.py` (CAD class name -> `ChrClasses` row) and `build_classmeta.py`
(`ChrSpecs.classToken` -> `ChrClasses` row) try the display-name join first and fall back to
the filename join on a miss. Results: **21/21 `coa-custom` class directories have a non-null
`classId`**; `unmatchedChrClasses` is `["Hero"]` (unreleased content, genuinely no CAD class);
`specs.json`'s `ChrClasses` coverage is **32/32**. The `ChrSpecs.classToken` values that no
display-name join reaches (DEMONHUNTER x3, MONK x3, SONOFARUGAL x4, FLESHWARDEN x3, PROPHET x4,
WILDWALKER x4, SPIRITMAGE x3) are all filename-column tokens.

**(c) `ChrClassesRoles` roster cross-check.** `ChrClassesRoles.roleMask`, decoded directly,
agrees with `specs.json`'s `roles` field on all 31 classes the table names (Pure DPS / Tank+DPS
/ Healer+DPS / Tank+Healer+DPS): **0 mismatches**. The only `ChrClasses` row it does not cover
is Hero. Pinned as a golden set in `tests/test_class_plumbing.py`.

**(d) Base-vs-overlay `Spell.dbc` diff tooling.** `tools/diff_realm_overlay.py` (CLI:
`python -m tools.diff_realm_overlay <realm>`) measures how far area-52's realm overlay and the
base chain disagree on the shared CoA spell set. **Read the result as Free-Pick-vs-base, not as
a CoA authority question**: CoA realms have no client-side overlay and read base, so "area-52
disagrees with base on 1,176 rows" says Free-Pick's revision differs - it is not evidence that
base is wrong for a CoA character. Scope: shared CoA rows present in BOTH `Spell.dbc` files.
Measured against this snapshot: differing shared rows 1,176/6,038 = 19.48%,
`description_enUS` diff 517, `effectBasePoints1` diff 410, name changes 51 (including spell
92093 "Deadeye" -> "Houndmaster"). Per-column diff counts cover every named
`TABLE_MAPS["Spell"]` column, so `columnDiffs` shows the full shape.
`overlayOnlySpellCount`/`baseOnlySpellCount` are computed over the FULL spell id space.

**(e) `discover_realms()` fixture test.** A true unit test (not the real client install) that
`config.discover_realms()` picks up a hypothetical new realm directory: a temp `Data\` tree
with 2 fixture realm dirs (each carrying its own `listarchive`) plus an `enUS\` dir (excluded
even when given a `listarchive` - base locale dir) and a no-`listarchive` dir (not a realm),
with `config.CLIENT_DIR` monkeypatched for the duration.

### Realms bitmask: a failed decode

The CAD `Realms` bitmask was probed against the 6-realm roster (Vol'jin, Rexxar, Darkmoon,
Dawnrise, Bronzebeard, Area 52). Known-population groups were built from `data/classes`'
existing `reborn`/`vanilla`/`coa-custom`/`meta` tags, all 28 distinct `Realms` values across
the 23,709 CAD entries enumerated, and 5 candidate bit-semantics (plain per-realm bit position,
`1 << realmId`, `Enum.RealmGameMode` index, sentinel values, grouped/mode bits) scored against
the golden bar - **a bit assignment must correctly classify >=3 independent known groups**.
None did.

**Best lead, still unproven:** bit 16 is 100% present on reborn and only 0.8% on coa-custom,
and `raw/interface/SharedXML/Util/Util.lua:337-340`'s own comment independently names numeric
realm id 16 as Bronzebeard (`"10/04/2025 change malfurion realmID to bronzebeard"`). That
satisfies 1 of the 3 required groups - no numeric realm id for Vol'jin, Rexxar, Darkmoon,
Dawnrise or Area 52 exists anywhere in `raw/interface`, and the `1<<realmId` MECHANISM applying
to this field is inferred, never observed. **No bit reaches even half of coa-custom** - the
strongest signal is a 6-way tie (bits 1, 2, 6, 14, 25, 26, perfectly co-set on the same 3,828
rows) at 45.95%, and that tie tracks the CAD `Type` field almost tautologically rather than
realm membership: a content-shape/UI flag wearing a realm-shaped disguise. A concrete
duplication example (Barbarian *Polearms*, spell 200, CAD ids 7704/20078/33260 - realms
`"0"`/`"6144"`/`"100679750"` on the SAME ability) shows why: `Realms` varies WITHIN one
ability's duplicate CAD rows, not BETWEEN classes with different realm availability.

`data/classes/_realms_evidence.json` (regenerated on every `build_classes.build()`) ships the
full census, crosstabs, per-bit statistics, hypothesis scoring, verdict and every Lua citation
checked. Per the binding rule ("emit only proven bits"), **no `realmFlags` is emitted
anywhere** - the raw `realms` value on every entry is carried through unchanged. An in-game
`/dump` of a known CoA-only ability's CAD entry on both Vol'jin and Rexxar (or a server-side
query) is the only avenue left.

## Reference: other tables

### Manastorm + realm overlays

**Manastorm** (`data/manastorm/`) is CoA's seasonal-difficulty system (patch-M):
`Manastorm.dbc` rows link a map/raid + difficulty to a `DungeonEncounter.dbc` boss (the
two-hop `mapId`/`difficulty` cross-check between the two tables is what proves the link, not
the raw join-rate), `ManastormMessages.dbc` carries the seasonal unlock-flavor text shown to
players (id 1: *"You have unlocked Iskarr Village in your next Manastorm!"*), and
`ManastormModifiers.dbc`/`ManastormPlayerGroupModifiers.dbc` are unproven-beyond-`id` numeric
tables. A game-content system, distinct from the realm-overlay layer below.

**Realm overlays** (`data/realms/<realm>/`, `raw/realms/<realm>/dbc/`) are a *separate* and
narrower concept. `Data\area-52\patch-D.MPQ` + its `listarchive` are **Free-Pick's overlay,
not "the realm overlay"**: the only realm-scoped data set this product ships right now. The
product carries **exactly one realm overlay at a time, and which realm it is has changed** -
the launcher's own installed-file manifest names a `\Data\Bronzebeard\` `listarchive` +
`patch-D.MPQ` pair and no area-52 entry at all, and seconds after the patcher logged
`Directory Data/Bronzebeard is on disk but it's not in the database` it queued the area-52
pair instead. So "no CoA overlay" is a fact about this product revision, not a permanent
property of the client - which is why `tools/config.discover_realms()` stays generic (any
`Data\<dir>\` carrying its own `listarchive`, excluding the base `enUS`/`Content` dirs)
rather than hard-coding `area-52`.

> **There is no CoA overlay to capture, and no login will create one.** Evidence,
> reproducible on any install of this product:
> - The patcher logs show `Data/area-52/listarchive` and `Data/area-52/patch-D.MPQ` written
>   by `patcher::patch::executor::write_plans` as part of the ordinary product update plan,
>   alongside the base MPQs, on **10 separate patch passes**. Across every patcher log on the
>   reference install it wrote **181 distinct `Data/` paths and exactly 2 realm-scoped ones**
>   - both area-52 - and those writes PRECEDE any Area 52 session there by about two weeks.
>   The directory is a **download**: the patcher creates it, not login.
> - Playing a realm does not produce a `Data\<realm>\` directory. On an install with sessions
>   across seven realms - including **both Conquest of Azeroth realms** - six of the seven
>   have no `Data\` directory at all, and a whole-install search finds exactly one
>   `listarchive` file, ever: area-52's.
> - `CustomFunctionChecks.lua`'s realm table does not supply the `Data\<dir>` slug:
>   `GlueXML/RealmList/RealmList.lua:161` unpacks that same tuple as
>   `name, expansionID, gamemodeID, image, unlocked, page, index, descriptionSpell`, and
>   `GlueXML/RealmMerge.lua:55` uses it as
>   `SetTexture("Interface\\Glues\\RealmList\\"..image)` - a background picture (`"Area52"`,
>   not even equal to `area-52`). That table is also dead code on the live client: it sits
>   inside `if not C_RealmSelect then`, a dev fallback, and `Extensions.dll` supplies the real
>   `C_RealmSelect`.
> - The engine *does* have a realm data-swap path (`Extensions.dll` is the only binary
>   containing `listarchive`, adjacent to `SetDataPath`, `realmdata` and the inlined
>   `AscensionRealmHotSwapOverlay` chunk captioned `Switching realm data`) - but the client's
>   guard on it is Area-52-specific by name: `GlueXML/CharacterSelect.lua:1792` reads
>   `if HasVisitedArea52ThisSession() and GetRealmId() ~= 11 then` -> *"You must restart your
>   client before entering another realm."* One realm gets a named one-way data latch, and it
>   is Free-Pick.
>
> **Conclusion: CoA realms read the BASE chain, which is what this dataset is built on** - so
> the base-vs-area-52 dispute is not a CoA authority question at all; it measures Free-Pick's
> revision diverging from base. And Rexxar and Vol'jin are not two datasets: same game mode,
> `gameMode=11` in the client's own `C_RealmSelect.RealmInfo`. Where this guide says a capture
> is "Vol'jin", read it as which server the session happened to be on, not as a scope limit.
>
> **Honest limit:** client files cannot observe SMSG traffic. If CoA-specific overrides are
> pushed **server-side over the wire**, nothing on disk would reveal it, and only an in-game
> `/dump` on a CoA character can settle that half.

- **Chain semantics.** A realm's `listarchive` lists that realm's own archives in load order;
  the LAST line wins on a filename collision - the identical later-wins rule
  `tools/extract_mpq.py` uses for the base chain, scoped to one realm's small archive set
  (`tools/extract_realms.py`). area-52's DBCs are an OVERRIDE layer the engine can point its
  data path at **when you play that realm**, but this pipeline never merges the two:
  `work/realms/<realm>/dbc/` and `work/dbc/` (and their `raw/` dumps) stay two fully
  independent layers. "Sits above" describes the client's own resolution order while on
  Free-Pick, not something this extractor performs, and **not** something that applies to a
  CoA session at all.
- **Mapped vs unmapped realm tables.** `tools/build_realms.py` dumps a realm table through the
  **same base `TABLE_MAPS` column map and field-count layout guard** as the base client's own
  dump, when a base map of that name exists AND the realm file's field count matches it exactly
  (`mapped: true`) - zero new column proofs for realm data. A table with no matching base map
  (or a mismatch) dumps `dump_unmapped`-style instead (raw `f0..fN` + a `.colinfo.json`
  sidecar). On area-52, 9 of 12 extracted tables are mapped (`Spell`, `SkillLineAbility`,
  `Talent`, `SpellCharges`, `SpellChargesCategory` and all 4 Manastorm tables); 3 are unmapped
  (`CharacterAdvancement`, `CharacterAdvancementEssence`, `SpellRank`).
- **Header-invariant parity.** `DBCFile` trusts `record_size // 4` for row layout
  (byte-accurate), never the WDBC header's declared `FieldCount` - because area-52's
  `CharacterAdvancement.dbc` header DECLARES 179 fields but its `record_size` only fits 173
  (`declaredFields: 179` on that table's index entry, the sole realm-side disagreement).
  `raw/provenance.json`'s top-level `headerMismatches` records every base `config.WANTED_DBCS`
  table where declared and byte-accurate field counts disagree, and `tests/test_dataset.py`
  gates the list against an explicit allowlist. The allowlist is not empty: it holds exactly
  one entry today - `spellitemenchantmentcondition.dbc`, declared 31 vs actual 16 (the
  16-column dump is the true read). **Do NOT widen the allowlist reflexively** - a NEW entry
  means some base table's header started disagreeing with its own record size. Realm tables are
  NOT held to that gate; a realm-side mismatch is expected and surfaces via `declaredFields`.
- **`missingRefResolution` - what it proves and what it does not.** For each bucket in the BASE
  client's `data/spells/_missing_refs.json`, this field reports how many of those ids exist as a
  real row in the REALM's own `Spell.dbc` - **id-set membership only**, report-only, no
  pass/fail threshold. Measured on area-52: `cad_other` 178/178 (100%), `cad_reborn` 7,119/7,119
  (100%), `rank` 603/2,810 (21.5%), `formula` 15/184 (8.2%), `talent` 1/13 (7.7%). **Read
  carefully:** area-52's `Spell.dbc` is a superset that happens to resolve 100% of the base
  client's `cad_other` AND `cad_reborn` missing ids - real evidence of *where this content
  lives*, but **not proof those spells are realm-appropriate for area-52** (obtainable there,
  balanced there, or intended for a character playing there), only that a row with that numeric
  id exists. Area 52 is the Free-Pick realm (any class), so a broad `Spell.dbc` there is
  unsurprising; a Reborn-class spell resolving there says nothing, since Bronzebeard is that
  spell's home realm. Treat this as a lead for follow-up, not a join to build curated
  cross-realm data on. `newSpellCount` on area-52 is 31,490.
- **Out of scope by design: no realm spell/class curation.** `data/classes/` stays keyed off the
  base, account-wide `CharacterAdvancementData.json` only - nothing in `data/realms/` feeds into
  it. Turning a realm's raw overlay into a realm-scoped equivalent of `data/classes/` is a
  documented future milestone, tracked in every `data/realms/<realm>/_meta.json`'s
  `futureMilestone` field.

### gt* combat-rating tables

`data/gt/` curates the 9 `gt*` tables whose layout is proven. It is written by
`tools/build_gt.py`, which the curation stage runs right after the essence stage;
`raw/provenance.json`'s `buildStats` carries a `gt` key, which is what proves `data/gt/` and
the rest of the dataset are on the same snapshot. Every `gt*` DBC is a genuinely
single-column, ALL-FLOAT WDBC (`record_size == 4`) - the layout question was never "what does
the column mean" but "which row position maps to which class/rating/level":

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

Every 100-level block's slot 99 ("level 100") holds the START of the next block's curve, not a
real level-100 value (verified at 3 block boundaries, exact float equality) - the
**level-100-slot trap**. Curated curves are therefore levels 1-99 only, never 100. Full
per-golden re-derivation evidence (13/14 exact published level-80 combat-rating constants, the
166.67/80.00 spell-crit conversion, the 83.33/62.50/52.08 melee-crit conversion, the CoA
archetype-clone table, why 15 of 32 rating slots stay unnamed) lives in `tools/dbc.py`'s
`TABLE_MAPS` comment for these tables.

**Three caveats, load-bearing for any consumer** (also in `data/gt/_meta.json`):

1. **`gtOCTClassCombatRatingScalar` (1,024 x 2) is a different shape and NOT covered by this
   proof.** `f0` decodes as an ascending-unique row id 1-1024, indistinguishable from either
   "this table's own positional PK" or the inferred TrinityCore `(class-1)*32 + cr + 1`
   convention - both produce the same sequence with the evidence available. Left **UNMAPPED**;
   `data/gt/` ships no curated curve for it.
2. **The server may not use these values.** These are the CLIENT's copy (tooltips, character
   sheet). A TrinityCore-family server loads its own `gt*` set - if CoA's server ships different
   files, the client could display one number while the server computes another. Mitigation, not
   performed here: read a level-60 character's actual crit% at a known crit-rating value in-game
   and compare against `CRIT_MELEE`/`CRIT_RANGED`/`CRIT_SPELL`'s prediction (14.0 rating per 1%
   at level 60 here).
3. **`ARMOR_PENETRATION` (rating index 24) does not match published WotLK.** This table gives
   11.55 at level 80 where the canonical constant is 15.39 (4.20 at level 60). Every other
   pinned rating matches its published constant to 4dp, so this is a real behavioral difference,
   not a layout artifact - `[INFERRED]` an Ascension rebalance or a pre-3.3.3 revision. The
   row's *identity* is certain; only the *value* is anomalous.

**`RESILIENCE` is never pinned as that literal string**, because in WotLK mechanics the
Resilience gear stat is surfaced through `CR_CRIT_TAKEN_MELEE`/`RANGED`/`SPELL` -
`cr14`/`15`/`16` - not a dedicated `CR_RESILIENCE` slot. What the published 85.00 level-60
anchor does buy is `cr14`: its level-60 value is exactly 85.0 and that value is **unique across
all 32 rating slots**, the same evidentiary tier already used to pin `cr4` BLOCK, so index 14
ships as **`CRIT_TAKEN_MELEE`** (17 named ratings total, 15 left as `cr<N>`). `cr15`/`cr16`
were held to the same bar and **failed** it: their curves are bit-identical to *each other* at
every one of the 99 curated levels (they diverge only at the excluded level-100 slot), so
nothing distinguishes which is `CRIT_TAKEN_RANGED` and which is `CRIT_TAKEN_SPELL` - they stay
unnamed rather than take a coin-flip, the same discipline applied to `cr20`/`21`/`22`. Both
halves are gated in `tools/build_gt.py` (a uniqueness assert for `cr14`, an equality assert for
`cr15 == cr16` that fires if a future patch splits them) and re-checked fresh in
`tests/test_gt.py`. `cr11`/`cr12`/`cr13` read 10.0/10.0/8.0 at level 60, identical to
HIT_MELEE/RANGED/SPELL - structurally the "hit taken" ratings, but with no published anchor to
name them by.

`gtNPCManaCostScaler.dbc` (100 x 1) is extracted but has no class dimension and no curated
output - left UNMAPPED, raw + colinfo, same as `gtOCTClassCombatRatingScalar`.

### Spell support tables

`WANTED_DBCS_V5` adds 12 tables: `SpellAffect`, `SpellDifficulty`, `SummonProperties`,
`SpellMissile`, `SpellShapeshiftForm`, `SpellFocusObject`, `SpellRank`, `CreatureSpellData`,
`GlyphProperties`, `GlyphSlot`, `SpellStatSuggestions`, `SpellItemEnchantmentCondition` - all
12 confirmed present in the live MPQ chain (`extract_mpq.extract_all()` raises `SystemExit` on
any wanted name missing from every archive). All 12 get `raw/dbc/<Table>.csv.gz` +
`<Table>.colinfo.json`; three got curation attention.

**`SpellAffect` (36,781 rows) is legacy content, not a CoA channel.** `id`/`spellId`/
`affectedSpellId` are named in `TABLE_MAPS`: f1 -> `Spell.dbc` join 100.0000%, `|f2|` join
99.9973% (one row's absolute value does not resolve), raw unsigned f2 join 93.4528%, negative
f2 rows 2,407. Goldens reproduce (324 -> 978816; 2565 -> 47294-6; 12043 -> the
Blizzard/Hailstorm family, spanning ids 81328-81336 plus a second 281800-281808 block). CoA
coverage is low: f1 hits = 5, `|f2|` hits = 10, against ~1,269 CoA spells carrying the modifier
aura. Id-band overlap (f1 against vanilla-tagged 209, reborn 277, coa-custom 5) says the same
thing. **`EffectSpellClassMask` remains the primary CoA talent-targeting channel.**

**`SpellStatSuggestions` (1,121 rows) - key proven, payload not.** f1 (`spellId`) is proven:
99.91% join vs live `Spell.dbc` ids, and row id 1 decodes to `(1, 10, 3, 1)` - spell 10 is
Blizzard. f2 (4 values: 0/1/3/4) CORRELATES 73.5% with a
primary-stat category (0=STR / 1=AGI / 3=INT / 4=SPI, found by testing all 24 permutations
against `raw/content/SpellToStatSuggestionData.json`'s per-spell dominant stat score over their
1,078-spell overlap) - real signal, well above the 25% random baseline, but short of the naming
bar. f3 is a constant 1 on every row.

**`SpellRank` vs the already-integrated `raw/content/SpellRankData.json` - NOT identical, and
the DBC is the more complete of the two.** The JSON (13,311 rows:
`firstSpellId`/`level`/`rank`/`spellId`) is what `build_spells.py`'s
closure/`rankChain`/`rankAt60` logic reads. `SpellRank.dbc` (23,179 rows in the base variant;
`firstSpellId` 100% join, `spellId` 99.98%, `rank` range 1-25) overlaps the JSON on 9,941
spellIds (`firstSpellId` agrees 99.56%, `rank` only 94.32% - of the 565 mismatches `+1` is the
largest single bucket at 47.1%, `+2`..`+8` account for most of the rest, with a handful of
negatives and a small `+9`..`+14` tail, so this is NOT a clean off-by-one - unexplained, left
open) but additionally carries **13,238 spellId rows the JSON does not have at all**, 99.96% of
which are real, live `Spell.dbc` ids. The JSON in turn carries 3,370 rows absent from the DBC
(stale orphan rank chains). Columns are named in `TABLE_MAPS` for raw-dump clarity only -
**deliberately NOT wired into the pipeline**; `SpellRankData.json` remains the single source of
truth for rank chains until a dedicated pass re-derives every downstream pinned count against
the richer source.

The other 9 tables ship raw + colinfo only. One flag found in passing:
`SpellItemEnchantmentCondition`'s WDBC header **declares 31 fields** (the stock-WotLK
1+5x6 operand-condition shape) but its `record_size` only supports **16** - the
`headerMismatches` canary catching a BASE table. `DBCFile.fields` (`record_size // 4`) is what
the pipeline trusts, so the 16-column raw dump is a true read - left unmapped rather than
guessing which 16 of the stock 31 survived.

### Item support tables

`WANTED_DBCS_V6` adds 9 tables: `Item`, `ItemSet`, `SpellItemEnchantment`, `GemProperties`,
`ScalingStatDistribution`, `ScalingStatValues`, `RandPropPoints`, `ItemRandomSuffix`,
`ItemRandomProperties` - all confirmed present in the live MPQ chain, all shipping raw +
colinfo only. This pipeline's job for items is completeness and evidence, not owning item
acquisition.

**`Item.dbc` is an INDEX, not a stat source** - 563,379 rows x 8 fields, **zero-length string
block**, every column's `samples` empty. `f0` (the id) is unique per row and its max
(9,200,842) reproduces the cross-reference ceiling exactly. Shape matches the stock WotLK
ordering (`id, class, subclass, soundOverrideSubclass, material, displayid, inventoryType,
sheath`) - `f5` (displayid) is the only other high-cardinality column (90,622 distinct). None of
the 8 columns are named in `TABLE_MAPS` yet; a future pass can pick this up at the same
golden-proof bar.

**`ScalingStatDistribution`/`ScalingStatValues` are extracted for completeness, NOT because
they are load-bearing for CoA.** Measured against `itemcache.wdb` via `tools/wdb_item.py`: of
15,822 equippable items (`inventoryType != 0`), only **126 have `scalingStatDistribution != 0`
(0.8%)** while 11,962 (75.6%) carry explicit `statsCount > 0` instead. Level-scaling gear is a
real but marginal mechanic on this client, not the norm.

**`ItemStat.dbc` - the `f1`/`f2` keying is PROVEN.** `WANTED_DBCS_V7` adds this one table
(1,513,931 rows x 39 fields, no strings). Trap 8 is the shape to avoid here: `f0` is a unique
monotonic row id, and a naive join against `Item.dbc`'s dense ids "proves" the wrong column.
The proof that holds:

- **The golden.** Item 100248 ("Beaststalker's Belt") decoded independently from
  `Cache\WDB\enUS\itemcache.wdb` (8,393,618 bytes) via `tools/wdb_item.py`:
  `itemLevel=61 armor=277 stats=[(3,13),(5,8),(7,9),(31,10),(38,17)]`. The `ItemStat.dbc` row
  with `f1=100248 f2=61` gives `armor(f27)=277` and stat pairs
  `[(3,13),(5,8),(7,9),(31,9),(38,17)]` - **armor exact, 4 of 5 stat pairs exact, statType 31
  ("hit") off by exactly 1**. The `f2=60` row (`armor=271`, stats roughly halved) does **not**
  match - confirming `f2` is a real per-row axis.
- **The row-block structure is the primary proof, stronger than any join rate**: item 100248
  carries exactly 75 `ItemStat` rows, and the table-wide distinct-`f2` set is exactly 75 values
  (dense 1-65, then sparse `{86,88,91,94,96,98,99,101,103,105}`). The per-item row-count
  histogram (`{75: 20171, 11: 48, 12: 44, 13: 2, 16: 1, 8: 1}`, summing to exactly 20,267
  distinct `f1` values) reproduces exactly.
- **The join rate** (19,651/20,267 = 96.96% of distinct `f1` values resolve against live
  `Item.dbc` ids; max `f1` 9,200,579 vs `Item.dbc`'s max id 9,200,842) is corroborating context
  only, **not** the proof - `Item.dbc`'s id space is only ~6% dense, precisely the trap-8
  false-positive shape.

`TABLE_MAPS["ItemStat"]` names `itemId` (f1) and `ownItemLevel` (f2) only. `f3`-`f38`'s
documented layout (10 interleaved stat-type/value pairs, float damage min/max, armor, a
level-counter/price ramp) was used only to CHECK the golden, never independently named.

**Sharded raw dump + curated coverage index** (`tools/build_items.py`):
`raw/dbc/itemstat/itemstat-<itemId//50000>.csv.gz` (29 non-empty buckets - item ids cluster
hard, the `[2,050,000, 2,100,000)` band alone holds 60% of all rows, so shard sizes are uneven
by design) replaces the single 236 MB file every other table gets
(`dbc.CUSTOM_RAW_DUMP_TABLES`; `dbc.dump_all()` skips `ItemStat` entirely).
`data/items/statsByItem/` is a **coverage index**, not a stats re-decode, bucketed at **5,000**
ids - narrower than the raw layer's 50,000, because the same clustering would blow the
5,000-line gate at 50,000-wide curated buckets (the narrowest raw-id band alone holds 12,165
distinct items). `build_items.py`'s own golden gate (the 100248 75-row check + the exact
histogram, both re-derivable from `work/dbc/ItemStat.dbc` alone) mirrors `build_creatures.py`'s
"refuse to publish if the pinned facts don't hold" convention; the `itemcache.wdb` cross-check
that PROVED the keying stays a test-time-only dependency (`tests/test_items_layer.py`), not a
build-path one.

**`ItemSpells.dbc` (131,722 rows x 37 fields, no strings) - raw + colinfo only.** `f1` is
unique PER ROW - structurally it CANNOT be a many-spells-per-item link column - and its join
against live `Item.dbc` ids is weak (55.45%). `f2 -> spellId` IS well-supported: 99.81%
(131,467/131,722) against a spell id space measured at 1.50% dense - a join rate this high
against a SPARSE space is real signal, not the dense-id false positive of trap 8. No column in
this table represents the item the spell is attached to (the same "no identity-grouping column"
shape as `NPCTrainer`), so it is presently unusable for an item-level spell lookup.

**`ItemVariationData.json`** (`raw/content/`, 10,830 rows of
`{Normal, Heroic, Mythic[40], Bloodforged}` - a pure id-to-id table with no item names) maps a
variant item id back to its base item; **no join is implemented**, and the findings are pinned
in `tests/test_items_layer.py`: **`Bloodforged` has a clean, dominant `+6,000,000` offset from
`Normal` (10,022/10,495 = 95.5%) - safe as a strong prior; `Heroic`/`Mythic` do NOT** (their
dominant `+300,000`/`+200,000` clusters cover only ~23% each, the rest scattering across dozens
of smaller non-round clusters, so a real implementation needs this file as a literal lookup
table, not an arithmetic formula). A "+1,600,000 for Prestigious" offset was searched for
exhaustively (every `Normal`-vs-variant delta across all 10,495 matched rows) and **not found**.
`Normal`/`Heroic`/`Bloodforged`/`Mythic[0]` resolve 98-100% against live `Item.dbc` ids, but
only 13.3% of `Normal` ids have `ItemStat` coverage.

## Recipes

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

Only the abilities a player can actually train (add the liveness filter):

```python
live_entries = [e for e in iter_class_entries("Starcaller") if e.get("live") is True]
unknown = [e for e in iter_class_entries("Starcaller") if e.get("live") is None]
```

Which classes get spell 954876: grep `"954876"` recursively across `data/classes/*/*.json` -
every shard is self-describing, so a hit's `class`/`tab` fields tell you where it came from
without cross-referencing the index.

All encounters of a raid: read `data/dungeons/index.json`, filter `isRaid`, open each hit's
`file` and read `encounters` (already ordered).

A dungeon's reward for a given character level: open its `data/dungeons/<id>-<slug>.json` ->
`rewards` is a **list** of level-bracket objects sorted by `MaxLevel` ascending (most dungeons
have one bracket or none; dungeon 258 has 17); pick the first bracket whose `MaxLevel` is >= the
character's level, and treat an empty list as "no reward data", not an error. For encounters
grouped by map, read every dungeon file and group on `(mapId, difficulty)`.

All encounters of a Mythic+ challenge dungeon, with a best-effort creature match
(`data/dungeons/index.json`'s `id` and `data/mythic/keystones/index.json`'s `dungeonId` are the
same `LFGDungeons.dbc` id space, so they join directly - but an encounter's own `creature` field
can be null, and a name match is not guaranteed unique: Ragnaros has 11 creature-template
variants):

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
        {"encounter": e["name"],
         "creature": e.get("creature"),
         "creatureIdCandidates": creature_candidates(e["name"])}
        for e in dungeon["encounters"]
    ]
```

A class's specs and roles (`data/classes/specs.json`, never `index.json`):

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
        "specs": [by_id[i] for i in spec_ids],       # [] if this class has none
        "roles": sd["roles"].get(class_name, []),     # e.g. Mage -> ["DPS"]
        "specialAbility": sd["specialAbilities"].get(class_name),  # None for most classes
    }
```

## Regenerating after a client patch

The test suite mixes two kinds of check, and they fail for different reasons.

**STRUCTURAL checks** verify the pipeline itself still works: WDBC layout guards
(`dbc.LayoutError`), golden spell rows (id 17 Power Word: Shield, id 10 Blizzard -
name/dispel/school/duration fixed points), the `cad_other`/`talent` missing-ref ratio gates
(<=5%), the **live-coverage equality gate** and the ground-truth pins behind it
(`tests/test_live_seed.py`, `test_live_flags.py`, `test_abilities.py` - Starcaller's live tabs,
Tide Lash catalogued-but-not-live), and general schema asserts. The live gates are STRUCTURAL,
never snapshot pins: the live-node id count itself may move when the talent capture is
refreshed, but "some live ids have no record" is always a defect, which is why the gate is an
equality rather than a ratio.

**SNAPSHOT PINS** are exact counts calibrated to the current capture and will legitimately
drift whenever CoA ships new content:

- `tests/test_classes.py`: RebornWarlock 1719 entries / Necromancer 427 entries (summed across
  each class's shard files).
- `tests/test_talents.py`: 37 tabs / 2383 talents.
- `tests/test_dungeons.py`: 430 dungeons / 2080 encounter rows / dungeon-258 has 17 reward
  brackets. (The 2,080 is the builder's own `DungeonEncounter` row count; the shipped files
  carry 2,704 encounter entries because several `LFGDungeons` rows share a map, covering 1,677
  distinct encounter ids, 84 of those entries with `creature: null`.)
- `tests/test_extract.py`: `spell.dbc` resolves from `patch-T.MPQ`.
- `tests/test_sharding.py`: the pre-shard record-count baseline (spells 32820, per-class entry
  counts, dungeons 430) so sharding cannot silently drop or duplicate records; also the
  repo-wide <=5,000-line gate (empty allowlist today). The spells pin moves whenever the client
  patches, the formula closure widens, or the seed rule changes; that file's header carries the
  dated log of every re-pin and why.
- `tests/test_creatures.py`: 127178 creatures / 18561 quests / 13112 trainers, trainer spellId
  join-rate >=90% (measured 0.989).
- `tests/test_classmeta.py`: 101 specs / 56 archetypes, >=60% of the 32 `ChrClasses` covered by
  >=1 spec (measured 32/32 since the filename-fallback join; the >=60% floor is deliberately
  loose in case a future patch reintroduces a genuinely unmatched token;
  `test_class_plumbing.py` holds the exact 32/32 gate).
- `tests/test_spells_v2.py`: `schemaVersion: 2`; enrichment coverage counts (tags 29331,
  category 7386, customAttr 9584, descriptionVariables 1530, addon 183, overrideData 6, across
  all 32820 referenced spells). Most are gated as floors, not exact values, so treat the numbers
  as a snapshot figure, not a contract.
- `tests/test_mythic.py`: 297 challenges / 6801 keystones (65 resolved dungeons) / 13409 affixes
  / 200 scaling rows / 81 timed dungeons / 685 map-difficulty rows; every link table's
  `challengeId` join rate >=80% (lowest: `ChallengeLevels` 84.9%).
- `tests/test_crack.py`: the recovery layer. Structural, not a snapshot pin - it asserts 0
  unaccounted bytes, 0 orphan block entries, 0 MD5 mismatches over the whole client, 0
  still-unreadable members, and that the client uses no PKWARE/huffman/sparse/ADPCM sector. It
  also cross-checks `tools/mpq.py` against `mpyq` on a member the two disagree about and asserts
  the ARCHIVE'S OWN MD5 backs `tools/mpq.py` - so the test cannot pass by both readers being
  wrong together. `python -m tools.mpq --selftest` runs the format-level tests alone (no client
  needed).
- `tests/test_interface.py`: `raw/interface/_manifest.json` >=1500 files (measured 1558: 1449
  archive-sourced + 109 disk-sourced), sha256 sample check, zero non-code extensions.
- `tests/test_manastorm.py`: 1017 / 291 / 32768 / 15 rows; `dungeonEncounterJoinRate` >=0.95
  (measured 0.9951); Shadowfang Keep boss-roster and seasonal-message-text goldens.
- `tests/test_realms.py`: pins the same live-probed header facts as "Manastorm + realm overlays"
  for whichever realm(s) are present on the machine running the suite (currently area-52 only).
  `newSpellCount` is gated loosely (>10000, measured 31490) rather than pinned, since a realm's
  content churns independently of the base client's.
- `tests/test_class_plumbing.py`: `essence.json` goldens re-derived fresh from
  `work/dbc/CharacterAdvancementEssence.dbc` at test time (not hardcoded); the
  `ChrClasses.filename` join goldens (id 14/19/20) plus a cross-check against the live
  `ClassRemap` Lua table; the 21/21 `coa-custom` classId gate +
  `unmatchedChrClasses == ["Hero"]`; `specs.json` 32/32; the `ChrClassesRoles` roster
  cross-check (31/31, 0 mismatches); `tools/diff_realm_overlay.py` against area-52 gated at
  +/-10% (re-derived fresh, not pinned); the `overlay_diff.json`-survives-a-rebuild regression
  test; and a fixture-dir unit test for `config.discover_realms()`.
- `tests/test_coatalents.py`: 21 classes / 3,618 nodes / 292 choice groups pinned against the
  frozen `raw/talents/coa-builder-voljin.html` capture - these drift only if that capture is
  refreshed, not on an ordinary client-patch re-run. The 84/96/72/24 tab-layer reconciliation
  numbers, the 5-of-7 shipped spec-token count
  (`FLESHWEAVER`/`VALKYR`/`MOUNTAINKING`/`WITCHKNIGHT`/`VIZIER` present;
  `HYDROMANCY`/`BULWARK` not), and the `isStartingNode` anomaly (2 nonzero, values `{1, 127}`)
  are pinned the same way. The spellDbc resolve-rate gate (>=0.95, measured 1.0 against the
  current 209,151-row base `Spell.dbc`) DOES depend on the client.
- `tests/test_dataset.py`: 14 `buildStats` keys. The `headerMismatches` allowlist check over the
  base `config.WANTED_DBCS` set is STRUCTURAL, not a snapshot pin - do not widen the allowlist
  reflexively; investigate which base table's header started lying and why.
- `tests/test_closure_ranks.py`: the formula-closure delta, re-derived fresh each run and gated
  as a range rather than an exact count; `rankAt60`/`$scalingbp`/`devDead` goldens re-derived
  from `work/dbc` at test time, not hardcoded.
- `tests/test_gt.py`: re-derives the gt* layout proof fresh from `work/dbc/gt*.dbc` at test time
  rather than pinning fixed numbers - the level-80 combat-rating constants, the
  spell-crit/melee-crit conversion goldens, the `cr14` uniqueness pin and the `cr15 == cr16`
  non-pin all re-check against whatever is on disk. A future patch that changes a `gt*` table's
  RECORD COUNT (currently 3200/3200/32 per table) or moves the ARMOR_PENETRATION anomaly closer
  to 15.39 is worth a manual look, not a reflexive re-pin.

Interface extraction counts are snapshot pins of a different flavor: they drift with the CLIENT
install (which archive wins a given file, whether Ascension patches `APIDocumentation`), not
with game content churn, and there is no golden-record test for any single file's *content* -
only shape/count/hash-integrity gates. A big swing in `archiveSourced`, or a drop in
`AddOns/APIDocumentation`'s `.lua` count below 10, means something changed about which archives
carry the Interface tree, and is worth a manual look rather than a reflexive re-pin.

**After regenerating against a patched client, treat the two failure modes differently.** A
snapshot-pin failure with a small delta (record counts moved by tens, not orders of magnitude; a
different archive won the same DBC by one letter) means content changed upstream - eyeball the
new numbers for sanity, then re-pin. A structural-check failure (layout guard fires, a golden
spell's fixed fields changed, a ratio gate blows past 5%, a huge or negative count swing) means
the pipeline itself broke - investigate the extractor/builder rather than papering over it with
a re-pin.

### Operational rules

**Run builders and tests ONE AT A TIME** - never two concurrently (two processes, two shells)
against this repo. The builders are single-writer by design but take no cross-process lock, and
`build_spells.build()` opens with `shutil.rmtree` on `data/spells/`, so anything reading that
tree during another process's ~30s rebuild window dies on `FileNotFoundError`
(`charges.json`, `_missing_refs.json`) or `EOFError` on a half-written `.csv.gz`. The wipe is
NOT self-healing (`tests/test_enums_v4.py` reads `charges.json` before it regenerates it, so
sequential retries keep failing until `git checkout -- data/spells`). Reproduced 6/6
concurrently vs 0/10 sequentially; the failure is exit code 1 with an ordinary traceback, not a
segfault.

**A module that `rmtree`s a shared directory must NAME the files it does not own**, and a test
must assert those files survive a real `build()` - not a mock of one. Two directories have more
than one writer: `data/realms/<realm>/` holds `build_realms.py`'s `index.json`/`_meta.json`
alongside `diff_realm_overlay.py`'s `overlay_diff.json` (so `build_realm()` does
`mkdir(exist_ok=True)` + direct overwrite of its own files, never a directory wipe), and
`data/spells/` holds `coverage_live.py`'s `_coverage_live.json` alongside `build_spells.py`'s
output - `build_spells.build()` must `rmtree` that directory because its shard SET changes
between runs, so it carries `build_spells.FOREIGN_FILES` across the delete. Both survival gates
are pinned, in `tests/test_class_plumbing.py` and `tests/test_spells.py`.

**`build_realms.build()` fails loudly rather than degrading silently.** `build_realm()` raises
when `data/spells/_missing_refs.json` is absent instead of publishing an evidence file with no
evidence. A caller rebuilding this layer alone (the test suite does) passes
`allow_missing_base=True`, which writes `missingRefResolution: null` plus a `degraded` key
naming the cause - so a zeroed run can never be mistaken for a measured one. The orchestrator
never passes it.

**Long passes are checkpointed and layers are staged and swapped on success**
(`tools/layerstate.py` sentinels; every layer carries a `_complete.json`, and a layer without
one was left half-written by a crash and must not be read). This is defensive, and the reason
is real: long-running processes on this build host occasionally die at
`STATUS_ACCESS_VIOLATION` (0xC0000005) with no Python traceback - most recently at archive 61 of
77, where the same archive then processed cleanly through identical code in a fresh process. An
access violation proves a crash, not its cause. There has also been exactly one silent-corruption
incident (a member written with 2 wrong bytes out of 115 MB, same length and valid header, never
reproduced, never root-caused); the guard against that class is external and stronger than any
in-process check - every member is verified against the MD5 its own archive records
(`raw/recovered/_verify.json`; 763,928 members, 0 mismatches). If a run dies, resume from its
checkpoint rather than concluding the data is bad.
