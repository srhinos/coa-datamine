# coa-datamine

Agent-consumable dataset of Ascension **Conquest of Azeroth** game data (classes,
spells, talents, dungeons/raids, creatures/quests/trainers, class specs, Mythic+/
Challenges) plus a committed copy of the client's own Interface/API Lua code layer,
datamined from the client install.

- **Consume it:** read `AGENT-GUIDE.md` first - file map, schemas, query recipes,
  and the honest-limits list (what client data can and cannot know).
- **Regenerate it:** `python -m tools.build_dataset` (client at `E:\ascension-live`,
  override with env `COA_CLIENT_DIR`). Requires Python 3.12 + `pip install mpyq`.
  Runs 10 stages in order (spells, classes, talents, dungeons, creatures, classmeta,
  mythic, manastorm, realms, interface) - `classmeta` must run after `classes` since
  it writes `data/classes/specs.json`/`archetypes.json` alongside (never inside) the
  directory `classes` owns; `realms` must run after `spells` since its
  `missingRefResolution` evidence reads `data/spells/_missing_refs.json`. Flags:
  `--skip-extract --skip-dump` rebuild only the curated `data/` layer from an
  existing `work/dbc` snapshot; `--skip-interface` reuses a previous
  `raw/interface/_manifest.json` instead of rescanning every MPQ archive for the
  Interface code tree (that scan is independent of `--skip-extract`/`--skip-dump` and
  takes well under a minute on this repo's archive set, but scales with however many
  archives the client install carries); `--skip-manastorm` reuses
  `data/manastorm/_meta.json`'s counts instead of re-parsing `Manastorm*.dbc`;
  `--skip-realm-extract` reuses a previous `work/realms/<realm>/dbc/` instead of
  re-reading each realm's own MPQ archives (only realms actually present on this
  machine's client are ever extracted - see AGENT-GUIDE.md's "Manastorm + realm
  overlays").
- **Verify it:** `python tests\test_config.py` ... each test script prints `ALL PASS`.
  After regenerating on a patched client, see "Regenerating after a client
  patch" in `AGENT-GUIDE.md` for which test failures are expected
  snapshot-pin drift vs. real pipeline breakage.

Layout: `raw/` = extracted sources (full DBC dumps as csv.gz, verbatim Content JSONs,
a **committed** mirror of the client's `Interface\` code tree at `raw/interface/`
incl. the live `AddOns/APIDocumentation` addon, a per-realm overlay dump at
`raw/realms/<realm>/dbc/`, provenance with sha256s); `data/` = curated JSON
(classes/, spells/, talents/, dungeons/, creatures/, quests/, trainers/, mythic/,
manastorm/, realms/); `tools/` = the pipeline; `work/` = gitignored scratch (raw
`.dbc` binaries).

Spec: `docs/superpowers/specs/2026-07-17-coa-datamine-design.md`,
`docs/superpowers/specs/2026-07-23-coa-datamine-v2-design.md`,
`docs/superpowers/plans/2026-08-01-coa-datamine-v3.md`.
