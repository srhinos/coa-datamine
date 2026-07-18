# coa-datamine

Agent-consumable dataset of Ascension **Conquest of Azeroth** game data (classes,
spells, talents, dungeons/raids), datamined from the client install.

- **Consume it:** read `docs/AGENT-GUIDE.md` first - file map, schemas, query recipes,
  and the honest-limits list (what client data can and cannot know).
- **Regenerate it:** `python -m tools.build_dataset` (client at `E:\ascension-live`,
  override with env `COA_CLIENT_DIR`). Requires Python 3.12 + `pip install mpyq`.
  Add `--skip-extract --skip-dump` to rebuild only the curated `data/` layer.
- **Verify it:** `python tests\test_config.py` ... each test script prints `ALL PASS`.

Layout: `raw/` = extracted sources (full DBC dumps as csv.gz, verbatim Content JSONs,
provenance with sha256s); `data/` = curated JSON (classes/, spells/, talents/,
dungeons/); `tools/` = the pipeline; `work/` = gitignored scratch (raw .dbc binaries).

Spec: `docs/superpowers/specs/2026-07-17-coa-datamine-design.md`.
