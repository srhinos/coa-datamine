Title: v2: creatures, quests, trainers, class specs, spell metadata, Mythic+/Challenges, interface code layer

Body:

Adds four data packs on top of the v1 datamine, plus two structural reforms to
how the repo lays out its data.

## Packs

- **Creatures / quests / trainers** — `data/creatures/` (127,175 creatures),
  `data/quests/` (18,561 quests), `data/trainers/` (13,001 NPCTrainer entries,
  spellId join-rate 0.9892), and dungeon encounter → creature links where the
  join is proven.
- **Class + spec metadata** — `data/classes/specs.json`: 101 specs across 25 of
  32 `ChrClasses`, plus role coverage (Tank/Healer/DPS) for all 32 classes.
- **Spell metadata enrichment** — `spells.jsonl` schemaVersion 2 gains tags
  (26,281), category (6,034), customAttr (7,635), descriptionVariables (1,302),
  addon (133), and overrideData (6) fields across the 27,441 referenced spells.
  SpellCharges ships standalone at `data/spells/charges.json` (401 rows) rather
  than attached to spell records, since its join rate to live Spell.dbc ids
  (0.8778) falls short of the 0.90 bar this repo requires before wiring a field
  onto a spell record.
- **Mythic+/Challenges** — `data/mythic/`: 297 challenges, 13,409 affixes, and
  66 resolved dungeons across 6,801 keystones, plus scaling/timed-dungeon/
  map-difficulty tables, all link tables at >=80% join rate.
- **Interface code layer** — `raw/interface/`: 1,553 files (1,444 archive-
  sourced + 109 disk-sourced from `APIDocumentation`), committed verbatim with
  a deterministic manifest (sha256-verified) per an explicit decision to ship
  the Ascension UI/API source alongside the data.

## Structural reforms

- **Sharding** — no committed data file exceeds 5,000 lines. Large datasets
  are split per-entity (one file per dungeon/challenge) or into fixed id-range
  buckets (`id // N * N`), never count-based chunking, so files stay
  diff-local and grep-able as content grows. Every sharded dataset carries an
  `index.json` manifest mapping id/bucket to file plus summary fields.
- **Single-writer ownership** — every committed data file has exactly one
  builder responsible for writing it, and a builder may delete only the paths
  it owns. This closes a wipe hazard found during review where one builder's
  cleanup step destroyed another builder's output on a partial rebuild.

## Evidence discipline

Every column mapping in this pack is either golden-proven (a decoded value
matches a known real-world fact, e.g. a creature name or a class name) or
shipped as an honest null with its colinfo evidence trail (distinct count,
string-likelihood, sample decodes) — nothing here is a guessed column name.

## Test surface

16 test scripts, all green on a full clean regeneration from the client
archives (extract → dbc → all builders → dataset assembly).

## Review notes

- Design and amendments: `docs/superpowers/specs/2026-07-23-coa-datamine-v2-design.md`
- Task plan: `docs/superpowers/plans/2026-07-23-coa-datamine-v2.md` (see
  Amendment C for the sharding rule, Amendment D for single-writer ownership)
- Remaining documented minors (deferred, non-blocking, tracked for future
  cleanup) are listed per-task in `.superpowers/sdd/progress.md`, including:
  quest join table's omitted f13 candidate note, SpellAddon's f0 raw carry,
  Tab/Type filenames not slugified, and the `test_dataset` manifestSha256
  assert covering only the default (non-skip-interface) branch.
