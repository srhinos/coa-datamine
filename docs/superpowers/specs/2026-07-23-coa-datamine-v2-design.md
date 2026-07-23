# CoA Datamine v2 — Design Spec

**Date:** 2026-07-23  **Status:** Approved in-session (scope + design + "commit UI code" variant)
**Branch:** `v2-packs` off master @ b2cc4d7 (v1 merged via PR #1)

## Scope (user-selected, all four packs)

1. **Bosses/quests/trainers** — Creature.dbc, DungeonEncounterExtra.dbc, Quest.dbc(+QuestInfo/QuestSort), NPCTrainer.dbc → `data/creatures/`, `data/quests/`, `data/trainers/`, encounter→creature enrichment in dungeons.json.
2. **Class + spell metadata** — ChrSpecs, ChrClassesRoles, CharacterCreation* (10 tables), CharacterAdvancement* (4 support tables) → classes v2; SpellCharges(+Category), SpellCustomAttr, SpellTags(+TagTypes), SpellAlternativeCost/PowerType, OverrideSpellData, SpellDescriptionVariables, SpellAddon, SpellCategory → spells.jsonl v2.
3. **Mythic+/Challenges** — MythicAffixes, MythicKeystones, MythicPlusScaling, TimedDungeons, MapDifficulty, Challenge* (14 incl. ChallengeSpells) → `data/mythic/`.
4. **Ascension UI/API code** — patch-A/patch-B `Interface\*` (1,166 + 1,007 files) + on-disk `Interface\AddOns\APIDocumentation` → `raw/interface/`, **COMMITTED to the public repo (explicit user decision 2026-07-23)**.

## Verified header facts (probed 2026-07-23; all WDBC, size-consistent)

patch-M: Creature 127,175×23 (str 2.5 MB); DungeonEncounterExtra 2,080×4 (no str);
Quest 18,561×29 (**no string block** — quest text is not client-side; numeric+joins only);
QuestInfo 11×18; QuestSort 144×18; NPCTrainer 13,001×4 (no str); ChrSpecs 101×65;
ChrClassesRoles 32×11; CharacterCreationArchetypes 56×157; ArchetypeCategories 9×73;
ArchetypeDetails 1,120×28; ArchetypeRoles 3×71; ClassDetails 464×28; ClassGuideRoles 4×38;
ClassGuideSubroleClasses 29×4; ClassGuideSubroles 7×40; PetDetails 170×12;
ShapeshiftDetails 100×21; CharacterAdvancementCategories 51×39; ClassTypes 46×23;
Essence 5,600×9; TabTypes 94×19; MythicAffixes 13,409×16; MythicKeystones 6,801×3;
MythicPlusScaling 200×8; TimedDungeons 82×6; MapDifficulty 685×23; Challenge 297×53
(str 93 KB); ChallengeConditionTypes 18×73; ChallengeConditions 354×10; ChallengeFeatured
54×5; ChallengeGroupRewards 144×10; ChallengeGroups 1,203×3; ChallengeLevels 1,334×5;
ChallengeModifierTypes 8×37; ChallengeModifiers 2×8; ChallengeRequirementTypes 22×41;
ChallengeRequirements 2,047×9; ChallengeRewards 21,677×11; ChallengeRuleTypes 127×36;
ChallengeRules 3,646×5.
patch-S: SpellCharges 401×2; SpellChargesCategory 105×3; SpellCustomAttr 58,127×11;
SpellTags 488,661×3; SpellTagTypes 200×61; SpellAlternativeCost 0×3 (empty — dump only);
SpellAlternativePowerType 4×19; OverrideSpellData 49×12; SpellDescriptionVariables 31×2;
SpellAddon 5,598×23; SpellCategory 5,024×2; ChallengeSpells 7,702×10.
Interface carriers: patch-A AddOns=1,166 files; patch-B FrameXML=378, GlueXML=64,
AddOns=565. APIDocumentation addon is loose on disk at `Interface\AddOns\APIDocumentation`.

## Method: empirical column mapping (the core v2 difference from v1)

Most v2 tables are Ascension-invented — no stock layout exists. Rule (instrument-first):

1. **Generic dump first.** Every extracted table without a `TABLE_MAPS` entry is dumped
   as raw signed ints `f0..fN` PLUS a sidecar `raw/dbc/<table>.colinfo.json` with
   per-column evidence: distinct count, min/max, %zero, string-likelihood (fraction of
   rows where the value is a valid string-block offset: 0, or 0<v<strblock_size with
   byte v-1 == NUL), and up to 3 sample decoded strings for string-likely columns.
2. **Name columns only from evidence.** A column enters `TABLE_MAPS` when a golden
   record proves it (e.g. Creature name column = the column whose decoded string for
   some row equals "Ragnaros"/"Hogger"; id column = f0 iff ascending unique). Every
   mapped table gets golden asserts in tests. Unproven columns stay `f<N>` in curated
   output only if carried at all — no speculative names.
3. **Fail loud.** Same layout-guard discipline as v1: expected_fields asserted for
   every newly mapped table (values above), goldens gate the build.

## Outputs

- `data/creatures/creatures.jsonl` (127k rows: id, name, subname + proven columns) —
  stream, don't slurp. `data/quests/quests.jsonl` (numeric fields + QuestSort/QuestInfo
  name joins). `data/trainers/trainers.json` (grouped by trainer id; spell ids resolved
  against spells.jsonl where present). dungeons.json encounters gain creature links
  where DungeonEncounterExtra proves the relation.
- `data/classes/specs.json` (ChrSpecs + ChrClassesRoles: spec name/class/role) and
  `data/classes/archetypes.json` (CharacterCreation* curation); class index entries
  gain `specs`/`roles` where the class links.
- `spells.jsonl` v2 fields: `charges {count, categoryId, rechargeMs?}` (via
  SpellChargesCategory keyed from Spell.dbc category or proven link), `customAttr`,
  `tags [names]` (SpellTags→SpellTagTypes), `alternativePowerType`, `overrideData`,
  `descriptionVariables` (raw $var text from SpellDescriptionVariables via the already
  extracted spellDescriptionVariableID), `addon` (proven SpellAddon columns),
  `categoryCooldown` linkage. `_meta.json` schemaVersion: 2.
- `data/mythic/mythic.json` (affixes/keystones/scaling/timed dungeons joined to
  LFGDungeons/Map names) and `data/mythic/challenges.json` (Challenge + types/rules/
  conditions/rewards/groups/featured/levels/spells linked).
- `raw/interface/` — chain-order-resolved `Interface\*` from patch-A/B + verbatim
  APIDocumentation copy; provenance records per-source file counts + sha256 of a
  manifest. Committed (user decision).

## Constraints carried forward + new

- All v1 global constraints (stdlib+mpyq, determinism, utf-8-sig, JSON style, plain
  test scripts printing ALL PASS).
- **Commits: ONE sentence, ONE line, NO AI attribution** (user standing rule).
- **No PR creation** — final task pushes `v2-packs` and writes a draft PR description
  to `docs/superpowers/pr-drafts/v2-packs.md`; the user submits the PR themselves.
- Snapshot pins vs structural checks distinction documented for all new tests.

## Honest limits (new)

- Quest.dbc has no strings — quest titles/objectives remain server-side; dataset
  carries numeric quest metadata + zone/sort joins only.
- Empirically mapped columns are labeled with their evidence in colinfo sidecars;
  columns without golden proof keep `f<N>` names (unknown ≠ guessed).
- SpellAlternativeCost is empty in this snapshot (dumped for future patches).
