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
| `data/classes/index.json` | class roster + tags + classId map + `dir`/`index` pointers into each class's subdirectory + `chrClasses` (ChrClasses.dbc table, 32 rows, ids 1-32) + `unmatchedChrClasses` (ChrClasses rows with no CAD data: Bloodmage, Felsworn, Hero, Templar) | small |
| `data/classes/<Class>/index.json` | that class's `tag`/`classId`/`realmHint`/`entryCount`/`unresolvedCount` + `files: [{file, tab, type, cadIdRange, count}]` enumerating every shard file for the class | small |
| `data/classes/<Class>/<Tab>.json` | one spec tab's obtainable abilities/talents/traits with resolved spells (`{class, tab, type: null, entries}`) | small-medium |
| `data/classes/<Class>/<Tab>.<Type>.json` / `<Tab>.<Type>-<cadId-bucket>.json` | only present when a single tab's entries exceed 5,000 lines as one file (Reborn* classes' biggest tabs) - see "Class tab sharding" below | small |
| `data/classes/<Class>/_general.json` | entries with no `Tab` (none exist in the current snapshot; the file only appears if some do) | small |
| `data/spells/index.json` | bucket manifest: `bucketSize` (10000), total `count`, `buckets: [{bucket, file, count, minId, maxId}]` | small |
| `data/spells/by-id/spells-<id//10000*10000>.jsonl` | every referenced spell in that id bucket, fully enriched, ONE JSON PER LINE, ascending id within the bucket; empty buckets are omitted | small-medium per file - stream/grep it, do not slurp |
| `data/spells/_meta.json` | counts only: `count`, `missing_ref_counts_by_source`, `ref_counts`, `dataNotes`, `by_source`, `missingRefsFile` pointer | small |
| `data/spells/_missing_refs.json` | full missing-ref id lists by source (`cad_other`/`cad_reborn`/`talent`/`rank`), each source's array on ONE line | small (line count, not byte count) |
| `data/talents/<ChrClass>.json` | DBC talent trees (row/col/ranks/prereqs) - only exists for the 12 classes that have DBC talent tabs; largest is ~3.6k lines, under the gate as-is, not sharded | medium |
| `data/talents/_pet.json` | pet talent tabs (`petTalentMask` set) - not tied to a single player class | small |
| `data/talents/_unassigned.json` | talent tabs matching no classMask/petTalentMask | small |
| `data/talents/_meta.json` | tab/talent counts, per-class tab counts, unresolved rank-spell count | small |
| `data/dungeons/index.json` | one compact record per dungeon: `{id, name, file, mapId, isRaid, levels}` | small |
| `data/dungeons/<id>-<slug>.json` | one dungeon incl. its encounters (ordered) + reward brackets; `<slug>` = lowercase name, non-alnum runs -> `-`, collapsed, max 40 chars | small |
| `data/creatures/index.json` | bucket manifest: `bucketSize` (5000), `count` (127175), `buckets: [{bucket, file, count, minId, maxId}]` | small |
| `data/creatures/creatures-<id//5000*5000>.jsonl` | `{id, name, subname}` per `Creature.dbc` row, ONE JSON PER LINE, ascending id within bucket; `subname` is **always `null`** - probed and disproven, see Honest limits | small-medium per file |
| `data/creatures/_meta.json` | `count`, `provenColumns` (id/name proof), `subnameFinding` (the disproof writeup) | small |
| `data/quests/index.json` | bucket manifest, same shape as creatures (`bucketSize` 5000, `count` 18561) | small |
| `data/quests/quests-<id//5000*5000>.jsonl` | `{id, sort: null, info: null, f1..f28}` per `Quest.dbc` row - **this table has no string block at all** (no quest title/objective text anywhere in it, see Honest limits); `sort`/`info` are always `null` (probed and disproven); the 28 remaining columns are raw/unnamed | small-medium per file |
| `data/quests/_meta.json` | `count`, `provenColumns`, `sortInfoFinding` | small |
| `data/trainers/index.json` | bucket manifest (`bucketSize` 2000, `count` 13001) | small |
| `data/trainers/trainers-<id//2000*2000>.json` | `{bucket, count, minId, maxId, entries: [{id, spellId, name, skillLine:{id,name}\|null, f3}]}` - a **flat per-row list**, not grouped by trainer: `NPCTrainer.dbc` has no trainer-NPC identity column at all (see `trainerIdFinding` in `_meta.json`) | small |
| `data/trainers/_meta.json` | `count`, `spellJoinRate` (0.9892), `provenColumns`, `trainerIdFinding` | small |
| `data/classes/specs.json` | `{specs: [101 ChrSpecs rows: id, name, classId\|null, className\|null, classToken, tabToken, description, armorType, primaryStat, secondaryStat, difficulty, powerType, secondaryPowerType, f63], perClass: {25 classNames: [specIds]}, roles: {32 classNames: [role,...]}, specialAbilities: {3 classNames: {spellId, name}}}` - owned solely by `build_classmeta.py` (Amendment D); read this file for spec/role data, never `data/classes/index.json` | small |
| `data/classes/archetypes.json` | `{archetypes: [56 CharacterCreationArchetypes rows: id, name, tagline, description, primaryStat, weaponTypes, armorTypes, iconToken, cinematicPath, abilityPreviews, races]}` - character-creation flavor presets, class-agnostic (no classId link exists in this table) | small |
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
| `raw/provenance.json` | source hashes, archive resolution, build stats | small |

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
  when the target id space is dense (e.g. `Creature.dbc`'s ids fill 1..127175 with no
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
  ...), `meta` (non-class rows). `classId` matches ChrClasses.dbc (customs are
  ids 17-32) - this is the id used by client APIs like minimap blips; `null` means
  the CAD class has no ChrClasses row.
- **Dispels**: `spell.dispel.name` in None/Magic/Curse/Disease/Poison/... A spell is
  a dispellable buff if it applies an aura (`effects[].effect.name == "APPLY_AURA"`)
  and `dispel.id != 0`. Dispel-CAPABLE spells have `effects[].effect.name == "DISPEL"`
  (miscValue = dispel type id it removes). Schema differs by file: in
  `data/spells/by-id/*.jsonl` `dispel` is the `{id, name}` object described above; in
  `data/classes/<Class>/<Tab>.json`, each entry's `spells[].dispel` is a plain string
  (or `null` when unresolved) - the summary view drops the numeric id.
- **Ranks**: `rankChain` groups spell ranks (`first` = rank-1 spell id). Class entries
  list the first-rank spell with the full chain inline.
- **Tooltips**: `$` tokens (e.g. `$s1`, `$d`) are raw - server formulas are not
  evaluated. `effects[].basePoints` is the DBC convention: displayed value is
  usually `basePoints + dieSides` for fixed values.
- **referencedBy**: how a spell entered the set - `cad` (obtainable), `rank`,
  `talent`, `trigger` (reached via EffectTriggerSpell closure; often the actual
  buff aura behind a cast).
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
  for every class), but `perClass` only lists the 25/32 that actually have `ChrSpecs`
  rows in this snapshot (the other 7 - see Honest limits - get `[]`), and
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
- `Realms` bitmask on class entries: semantics unknown, carried raw.
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
  - Every dungeon encounter's `creature` field (`data/dungeons/*.json`) - always
    `null` (`tools/build_dungeons.py`'s module docstring; the naive join-rate cleared
    92.4% but every famous-boss golden resolved to an unrelated random NPC - a false
    positive caused by `Creature.dbc`'s fully dense id space, see the empirical-mapping
    convention above).
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
- `tests/test_creatures.py`: 127175 creatures / 18561 quests / 13001 trainers
  (`Creature.dbc`/`Quest.dbc`/`NPCTrainer.dbc` record counts), trainer spellId
  join-rate >=90% (measured 0.9892)
- `tests/test_classmeta.py`: 101 specs / 56 archetypes, >=60% of the 32 `ChrClasses`
  covered by >=1 spec (measured 25/32 = 78.1%)
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
