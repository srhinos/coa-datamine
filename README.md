# coa-datamine

**A complete mechanical extraction of the Ascension Conquest of Azeroth client.**
Every DBC table (all 368, not a chosen subset), the `Data\Content` JSON and `.loc`
localization store, the Interface/API Lua code layer, the WDB server caches, and a
census of every file in the install. 7.5M rows.

Nothing in `raw/` is hand-authored. Columns are positional (`f0..fN`) because
nothing here knows what a column means. Types are inferred by measurement and
shipped with the evidence behind them. No wanted-list decides what gets extracted.

## Regenerate it

```
python -m tools.extract_everything
```

One command, no arguments, no LLM, no manual step. Run it after any client patch.
It rebuilds every raw layer in dependency order and ends by printing what changed
since the last run - per-table row deltas, tables added and removed, tables whose
winning archive moved. On an unchanged client it reproduces the tree byte for byte
and says so. `--list` shows stage state, `--from <stage>` resumes, `--only <stage>`
reruns one. Client at `E:\ascension-live` (override with env `COA_CLIENT_DIR`);
Python 3.12 + `pip install mpyq`.

## Where to look first

```
python -m tools.find "Tide Lash"        # which table/column holds a string
python -m tools.find --id 133           # every column an integer appears in
python -m tools.find --joins-to Spell   # which columns point at Spell.f0
```

`CATALOG.md` is the generated index of all 368 tables - rows, columns, id density,
inbound joins, sample text - and is the right first read for "where does X live".
`raw/README.md` covers the non-table layers. `find.py` scans tables **plus** the
`.loc` store, the WDB caches and the client's own executables, because `Quest` and
`Item` carry no string column at all on this client (a tables-only search reports
"not in the client" for every quest title in the game) and because some of what the
client does - `listarchive`, `SetDataPath`, the realm hot-swap script - exists only
inside `Extensions.dll`.

## The standing rule

**The raw layer is never hand-curated.** No hand-authored column names, no
hand-transcribed enums, no hand-picked seed lists, no human judgement stored as
data. If a fact cannot be derived from the client bytes by a script that runs
without an agent, it does not belong in `raw/`. Selective extraction and curated
seeding is what let three confidently-wrong answers ship in a single session; the
raw layer exists so the complete truth is reachable without anyone deciding in
advance what matters.

---

## The derived layer (`data/`)

Curated, agent-consumable JSON built on top of the extraction - classes, spells,
talents, dungeons/raids, creatures/quests/trainers, class specs, Mythic+/Challenges.
Useful, and **narrower than the client**: it was seeded from a catalog that carries
a dead content generation. Read `AGENT-GUIDE.md`'s layer warning before trusting it
for "what can a player actually do" questions.

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

Layout: `raw/` = the mechanical extraction - `_inventory/` (census of every file in
the client), `tables/` (all 368 DBC tables decoded, positional `f0..fN`), `_catalog/`
(the generated search index behind `CATALOG.md`), `content/` (Content JSON + the
`.loc` store), `interface/` + `interface_all/` (the client's `Interface\` code tree
and a census of every path in it), `cache/` (WDB server caches), `dbc/` (raw table
bodies), `binaries/` (the client's own executables: every string, the inlined Lua,
the PE structure), `recovered/` (what no previous reader could open), `realms/`
(realm-overlay diffs), `talents/` (the pinned talent-builder capture); `data/` = the
curated derived layer; `tools/` = the pipeline; `work/` =
gitignored scratch. Every layer carries `_complete.json` - a layer without one was
left half-written by a crash and must not be read.

Spec: `docs/superpowers/specs/2026-07-17-coa-datamine-design.md`,
`docs/superpowers/specs/2026-07-23-coa-datamine-v2-design.md`,
`docs/superpowers/plans/2026-08-01-coa-datamine-v3.md`.
