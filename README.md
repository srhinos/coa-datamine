# coa-datamine

Agent-consumable dataset of Ascension **Conquest of Azeroth** game data (classes,
spells, talents, dungeons/raids, creatures/quests/trainers, class specs, Mythic+/
Challenges) plus a committed copy of the client's own Interface/API Lua code layer,
datamined from the client install.

- **Consume it:** read `docs/AGENT-GUIDE.md` first - file map, schemas, query recipes,
  and the honest-limits list (what client data can and cannot know).
- **Regenerate it:** `python -m tools.build_dataset` (client at `E:\ascension-live`,
  override with env `COA_CLIENT_DIR`). Requires Python 3.12 + `pip install mpyq`.
  Runs 8 stages in order (spells, classes, talents, dungeons, creatures, classmeta,
  mythic, interface) - `classmeta` must run after `classes` since it writes
  `data/classes/specs.json`/`archetypes.json` alongside (never inside) the directory
  `classes` owns. Flags: `--skip-extract --skip-dump` rebuild only the curated `data/`
  layer from an existing `work/dbc` snapshot; `--skip-interface` reuses a previous
  `raw/interface/_manifest.json` instead of rescanning every MPQ archive for the
  Interface code tree (that scan is independent of `--skip-extract`/`--skip-dump` and
  takes well under a minute on this repo's archive set, but scales with however many
  archives the client install carries).
- **Verify it:** `python tests\test_config.py` ... each test script prints `ALL PASS`.
  After regenerating on a patched client, see "Regenerating after a client
  patch" in `docs/AGENT-GUIDE.md` for which test failures are expected
  snapshot-pin drift vs. real pipeline breakage.

Layout: `raw/` = extracted sources (full DBC dumps as csv.gz, verbatim Content JSONs,
a **committed** mirror of the client's `Interface\` code tree at `raw/interface/`
incl. the live `AddOns/APIDocumentation` addon, provenance with sha256s); `data/` =
curated JSON (classes/, spells/, talents/, dungeons/, creatures/, quests/, trainers/,
mythic/); `tools/` = the pipeline; `work/` = gitignored scratch (raw `.dbc` binaries).

Spec: `docs/superpowers/specs/2026-07-17-coa-datamine-design.md`,
`docs/superpowers/specs/2026-07-23-coa-datamine-v2-design.md`.
