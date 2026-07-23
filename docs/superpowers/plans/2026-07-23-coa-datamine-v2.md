# CoA Datamine v2 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add four data packs per `docs/superpowers/specs/2026-07-23-coa-datamine-v2-design.md`: bosses/quests/trainers, class+spell metadata, Mythic+/Challenges, and the committed Ascension UI/API code layer.

**Architecture:** Same pipeline as v1. New: generic colinfo evidence dumps for unknown-layout tables, empirical golden-driven column mapping, and an Interface extraction tool.

**Tech Stack:** Python 3.12 stdlib + mpyq. Plain-python test scripts.

## Global Constraints

- All v1 global constraints (see v1 plan) remain binding: stdlib+mpyq only; determinism (no timestamps in raw/dbc|content|interface or data; gzip mtime=0); utf-8-sig for content JSONs; JSON style ensure_ascii=False + sort_keys (jsonl compact separators, small files indent=1); enUS = index 0 of 16-locale blocks; tests are `python tests\test_*.py` ending `ALL PASS`.
- **Commit style (user standing rule): ONE sentence, ONE line, NO AI attribution of any kind.** Applies to every commit in this plan.
- **Never create a PR.** Task V2-7 pushes the branch and writes a draft PR description; the user submits it.
- Verified header facts for all 54 new tables are in the v2 spec — treat as ground truth for expected_fields asserts.
- **Empirical mapping rule:** a column may be named in `TABLE_MAPS` only with golden-record proof pinned in a test; otherwise it stays `f<N>`. colinfo sidecars are the evidence trail.
- Branch: `v2-packs`. Base: b2cc4d7.

## File Structure

```
tools/config.py              +WANTED_DBCS_V2 (54 names) appended to WANTED_DBCS   [V2-1]
tools/dbc.py                 +colinfo evidence dump for unmapped tables            [V2-1]
tools/build_creatures.py     creatures/quests/trainers + dungeons enrichment       [V2-2]
tools/build_classmeta.py     specs.json / archetypes.json / index enrichment       [V2-3]
tools/build_spells.py        v2 enrichment fields (charges/tags/attrs/vars/...)    [V2-4]
tools/build_mythic.py        mythic.json + challenges.json                         [V2-5]
tools/extract_interface.py   patch-A/B Interface + disk APIDocumentation           [V2-6]
tools/build_dataset.py       orchestrate new stages                                [V2-6]
tests/test_v2_extract.py, test_creatures.py, test_classmeta.py, test_spells_v2.py,
tests/test_mythic.py, test_interface.py                                            [per task]
docs/AGENT-GUIDE.md          v2 sections                                           [V2-6]
docs/superpowers/pr-drafts/v2-packs.md                                             [V2-7]
```

---

### Task V2-1: Extend wanted list + colinfo evidence dumps

**Files:** Modify `tools/config.py`, `tools/dbc.py`; Create `tests/test_v2_extract.py`.

**Interfaces produced:** `config.WANTED_DBCS_V2` (list of the 54 v2 filenames from the spec, proper case) with `WANTED_DBCS += WANTED_DBCS_V2`; `dbc.dump_unmapped(table) -> Path` writing `raw/dbc/<table>.csv.gz` (header `f0..fN`, raw signed ints) plus `raw/dbc/<table>.colinfo.json` `{table, records, fields, string_block_size, columns:[{index, distinct, min, max, pct_zero, string_likelihood, samples:[...]}]}` (floats rounded 4dp; samples = up to 3 distinct non-empty decoded strings when string_likelihood ≥ 0.9); `dump_all()` now dumps mapped tables via `dump_table` and every other `WANTED_DBCS` table via `dump_unmapped`.

String-likelihood definition (fixed): fraction of rows where `v == 0` or (`0 < v < strblock_size` and byte at `v-1` is NUL). Tables with `string_block_size == 0` get `string_likelihood = 0.0` for all columns.

**Steps:**
- [ ] Write failing `tests/test_v2_extract.py`: asserts `len(config.WANTED_DBCS_V2) == 54`; runs `extract_mpq.extract_all()`; asserts all 54 files exist in `work/dbc` with WDBC magic and the spec's exact (records, fields) for at least: Creature (127175, 23), Quest (18561, 29), NPCTrainer (13001, 4), ChrSpecs (101, 65), SpellTags (488661, 3), Challenge (297, 53), SpellAlternativeCost (0, 3); then `dbc.dump_unmapped("Creature")` and asserts colinfo has ≥1 column with string_likelihood ≥ 0.9 whose samples are non-empty strings, and that CSV row count == 127175. Ends `print("ALL PASS")`.
- [ ] Run: `python tests\test_v2_extract.py` → fails (no WANTED_DBCS_V2).
- [ ] Implement config + dbc changes. `dump_unmapped` streams rows once, accumulating column stats and writing the CSV in the same pass; deterministic gzip (mtime=0) same as `dump_table`; colinfo written with indent=1, sort_keys.
- [ ] Run test → ALL PASS (extraction scan takes minutes; Creature/SpellTags dumps ~1-2 min).
- [ ] Run `python -m tools.dbc` to dump everything (v1 mapped + all v2 unmapped) — sanity-eyeball 5 colinfo files (Creature, ChrSpecs, Challenge, SpellAddon, MythicAffixes) and paste their string-likely column summaries into the report; these are V2-2..V2-5's mapping evidence.
- [ ] Commit (one line): `Add v2 wanted tables with colinfo evidence dumps`

Record counts note: if extract reveals live-drift deltas vs the spec's counts (launcher updates), small deltas are content churn — record actuals in the report and adjust the pinned numbers in the SAME commit; large deltas (>5%) = stop and investigate.

---

### Task V2-2: Creatures / quests / trainers + dungeon encounter enrichment

**Files:** Create `tools/build_creatures.py`, `tests/test_creatures.py`; Modify `tools/dbc.py` (add proven TABLE_MAPS entries), `tools/build_dungeons.py` (encounter creature links).

**Method (per empirical mapping rule):** From colinfo + probes: Creature id col = f0 iff ascending unique; name/subname = the two highest string-likelihood columns, proven by goldens (name col decodes "Hogger" for some row; "Ragnaros" exists; subname col decodes a known subname e.g. "The Firelord" on Ragnaros's row — verify actual values with a probe before pinning, adjust goldens to verified reality and document). DungeonEncounterExtra f-columns: prove which column is DungeonEncounter id (⊇ join-rate ≥95% against DungeonEncounter ids) and which is creature id (join-rate against Creature ids); only link encounters if a column clears 90% join-rate — otherwise emit nothing and record the finding. NPCTrainer: identify spell-id column by ≥90% join-rate against Spell.dbc ids; trainer-id column = the low-cardinality grouping column. Quest: carry all 29 numeric columns as f<N> EXCEPT columns proven by joins (zone/sort col joins QuestSort ids ≥80%; questInfo col joins QuestInfo ids; level-ish columns stay f<N> unless proven).

**Outputs:** `data/creatures/creatures.jsonl` `{id, name, subname, ...proven}`; `data/quests/quests.jsonl` `{id, sort:{id,name}|null, info:{id,name}|null, f<N>...}`; `data/trainers/trainers.json` `{trainerId: [{spellId, name|null, ...proven}]}`; dungeons.json encounters gain `"creature": {id, name}|null`.

**Gates (in tests):** creature goldens; creatures.jsonl line count == Creature record count; trainer spell join-rate ≥90%; every quests.jsonl sort/info id resolves or is null; encounter-creature link coverage reported in `_meta` (report-only), zero links only acceptable with documented evidence.

**Steps:** failing test → probe + pin maps → implement → ALL PASS → one-line commit `Add creatures, quests and trainers datasets with encounter links`.

---

### Task V2-3: Class/spec metadata pack

**Files:** Create `tools/build_classmeta.py`, `tests/test_classmeta.py`; Modify `tools/dbc.py` (proven maps for ChrSpecs, ChrClassesRoles, and any CharacterCreation* tables actually curated).

**Method:** ChrSpecs (101×65): prove name column via golden (a decoded string equal to a known CoA spec name — probe first; candidates like "Frost", "Discipline", or custom spec names; pin what's verified), class-link column via values ⊆ ChrClasses ids 1-32 with sensible distribution, role column via low cardinality (≤4 distinct). ChrClassesRoles (32×11): f0 = class id 1-32 (verify), remaining columns carried raw + any proven role flags. CharacterCreation*: curate ONLY Archetypes/ArchetypeDetails/ClassDetails/PetDetails/ShapeshiftDetails columns provable by joins (class ids, spell ids, creature ids) or string goldens; everything else stays in colinfo/raw dumps.

**Outputs:** `data/classes/specs.json` `{specs:[{id, name, classId|null, className|null, role|f<N>, ...proven}], perClass:{<className>:[specIds]}}`; `data/classes/archetypes.json` (proven curation); `data/classes/index.json` entries gain `"specIds": [...]` where their classId links.

**Gates:** every spec classId ∈ 1-32 or null; ≥60% of the 32 ChrClasses have ≥1 spec (else stop: mapping is wrong); goldens pinned.

**Steps:** failing test → probe/pin → implement → ALL PASS → commit `Add class spec and archetype metadata from ChrSpecs and CharacterCreation tables`.

---

### Task V2-4: spells.jsonl v2 enrichment

**Files:** Modify `tools/build_spells.py`, `tools/dbc.py` (proven maps: SpellCharges, SpellChargesCategory, SpellCustomAttr, SpellTags, SpellTagTypes, SpellAlternativePowerType, OverrideSpellData, SpellDescriptionVariables, SpellAddon, SpellCategory); Create `tests/test_spells_v2.py`.

**Method:** SpellDescriptionVariables (31×2) = (id, text) — trivially proven (string col). SpellCategory (5024×2) = (spellId? categoryId?) — prove direction by join-rates against Spell ids. SpellTags (488661×3): prove spell-id column (join ≥95% vs Spell ids) and tag-id column (⊆ SpellTagTypes ids); TagTypes name column via string evidence. SpellCharges (401×2) + SpellChargesCategory (105×3): prove linkage (which column joins which) before naming; if the link to Spell.dbc rows cannot be proven ≥90%, ship the tables curated standalone in `_meta` + raw and attach nothing to spells.jsonl (document). SpellCustomAttr (58127×11): f0 spell id if join ≥95%; other 10 columns carried as raw `customAttr: [u32 ×10]`. SpellAddon (23 cols): prove f0 = spell id; carry proven columns only. OverrideSpellData/AlternativePowerType: small; prove ids, carry raw remainder.

**Outputs:** spells.jsonl records gain (only where data exists): `tags: [tagNames]`, `customAttr: [...]`, `descriptionVariables: "text"` (resolved via existing spellDescriptionVariableID), `charges: {...}` (if proven), `category2: n` (SpellCategory link, name TBD by evidence), `addon: {...proven}`, `override: {...}`, `altPowerType: {...}`. `_meta.json` schemaVersion 2 + per-enrichment coverage counts.

**Gates:** existing v1 gates unchanged and still passing; a known tagged spell golden (probe: pick a spell with ≥1 tag whose TagTypes name decodes; pin it); enrichment coverage counts reported; spells.jsonl still sorted/unique/parseable line count == _meta count.

**Steps:** failing test → probe/pin → implement → run test_spells.py AND test_spells_v2.py → ALL PASS ×2 → commit `Enrich spells.jsonl with tags, charges, custom attributes and description variables`.

---

### Task V2-5: Mythic+/Challenges pack

**Files:** Create `tools/build_mythic.py`, `tests/test_mythic.py`; Modify `tools/dbc.py` (proven maps for the Mythic*/Timed/Challenge* tables actually curated).

**Method:** Challenge.dbc (297×53, 93 KB strings) is the hub: prove name + description columns by string evidence (golden: any decoded challenge name also appearing in ChallengeRuleTypes/ModifierTypes strings or a plausible title — pin verified text exactly). ChallengeModifierTypes (8×37) and ChallengeRuleTypes (127×36) have names — prove and use as lookup tables. Link tables (Groups/Levels/Requirements/Rewards/Conditions/Featured/Spells/GroupRewards) get columns proven by join-rates (challenge id ⊆ Challenge ids; spell ids ⊆ Spell ids; item-ish reward columns stay f<N>). MythicKeystones (6801×3) / MythicAffixes (13409×16): prove dungeon/map linkage by join-rate against LFGDungeons/Map ids; affix name source = ChallengeModifierTypes if join proves it, else affix rows carried raw. TimedDungeons (82×6): prove LFGDungeons/Map link; join names.

**Outputs:** `data/mythic/challenges.json` `{challenges:[{id, name, description, rules:[...], modifiers:[...], conditions:[...], rewards:[...proven], featured:bool, levels:[...], spells:[...]}], lookups:{ruleTypes, modifierTypes, ...}}`; `data/mythic/mythic.json` `{keystones:[...], affixes:[...], scaling:[...], timedDungeons:[{...,dungeonName}]}` — proven columns named, rest f<N>.

**Gates:** ≥80% of link-table challenge-id values resolve to Challenge rows; TimedDungeons dungeon link proven or the join omitted with evidence; challenge name golden pinned.

**Steps:** failing test → probe/pin → implement → ALL PASS → commit `Add Mythic+ and Challenges datasets`.

---

### Task V2-6: Interface/API code layer + orchestrator + docs

**Files:** Create `tools/extract_interface.py`, `tests/test_interface.py`; Modify `tools/build_dataset.py` (new stages: creatures, classmeta, mythic, interface), `docs/AGENT-GUIDE.md`, `README.md`.

**extract_interface.py (complete behavior):** scan ALL archives with `extract_mpq._list_archives()`; collect files under `Interface\` (any depth); resolve per-file winner by `chain_rank`; extract to `raw/interface/<original path>` (backslashes → os.sep, original case from the stored name); ALSO copy the on-disk `CLIENT_DIR/Interface/AddOns/APIDocumentation` tree verbatim to `raw/interface/AddOns/APIDocumentation` (disk copy WINS over any archive-extracted file at the same path — it is the live launcher-managed version). Write `raw/interface/_manifest.json`: sorted relative paths with source (archive name or "disk"), size, sha256 — deterministic. Skip non-code payloads: only extract extensions `.lua .xml .toc .txt .md` (art/BLPs excluded — code layer, not art dump).

**Orchestrator:** `run()` gains stages after dungeons: `creatures`, `classmeta`, `mythic`, and `interface` (flag `--skip-interface` mirrors others); buildStats gains their stats; provenance carries interface manifest sha256 + file count.

**Docs:** AGENT-GUIDE v2 sections: new file map rows, quests-have-no-text limit, empirical-mapping/colinfo convention (`f<N>` = unproven by design), APIDocumentation pointer ("their real API" — the ground truth for porting agents), Mythic/Challenges + specs recipes (each fact-checked against disk before writing, v1 discipline). README: v2 regenerate/verify updates.

**Gates (test_interface.py):** manifest exists, ≥1,500 files, every listed sha256 matches on disk for a 25-file sample, `AddOns/APIDocumentation` present with ≥10 .lua files, zero non-code extensions in manifest; orchestrator smoke: `run(skip_extract=True, skip_dump=True)` returns buildStats with all 8 stage keys.

**Steps:** failing test → implement → ALL PASS → run full new-stage sweep (all v2 tests + full v1 suite) → commit `Add committed interface code layer, orchestrator stages and v2 docs`.

---

### Task V2-7: Full regeneration, sweep, final review, push + PR draft

- [ ] `python -m tools.build_dataset` full clean run (extract + dump + all stages).
- [ ] Run ALL tests (v1 9 + v2 5-6 scripts) sequentially → every one `ALL PASS`. Snapshot-pin drift handled per the documented convention (small delta → re-pin in same commit with note; structural failure → stop).
- [ ] Consumer spot-checks: a boss lookup by name through creatures.jsonl; one challenge with rules+rewards rendered; one class's specs; one spell showing tags+charges; APIDocumentation grep for a known API name.
- [ ] Commit dataset (one line): `Build v2 dataset from live client`
- [ ] Final whole-branch review (most capable model) over b2cc4d7..HEAD per SDD skill; fix Critical/Important; re-review.
- [ ] Push: `git push -u origin v2-packs`. Write `docs/superpowers/pr-drafts/v2-packs.md` (title + body, NO AI attribution) and commit+push it. **Do NOT create the PR — hand the draft to the user.**

## Self-Review

Spec coverage: pack 1 → V2-2; pack 2 → V2-3+V2-4; pack 3 → V2-5; pack 4 → V2-6; method/evidence rule → V2-1 (colinfo) + per-task gates; user rules (commit style, no PR) → Global Constraints + V2-7. Types: builders return stats dicts consumed by orchestrator buildStats (V2-6 lists all 8 stage keys); colinfo schema defined once in V2-1 and referenced by V2-2..V2-5. No placeholders: where exact column names are unknowable pre-evidence, the plan specifies the PROOF PROCEDURE and acceptance threshold instead — that is the deliverable contract, not a TBD.
