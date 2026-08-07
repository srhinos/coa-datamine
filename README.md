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

### One table, several versions - pick the right one

The client ships most DBC paths more than once and its loader picks one.
`raw/tables/<Table>/` is that pick, and for **10 tables it is the `Data\area-52`
realm overlay** - which is *Free-Pick's* data. A Conquest of Azeroth character has
no client data directory at all and reads the **base chain**, so for CoA questions
the chain winner is the wrong version: base `Spell` is 209,140 rows, the overlay's
is 238,939. The contested ten are `Spell`, `SkillLineAbility`, `SpellRank`,
`Talent`, `CharacterAdvancement`, `CharacterAdvancementEssence`, `SpellCharges`,
`SpellChargesCategory`, `Manastorm` and `ManastormModifiers` - exactly the tables
class and spell work depends on.

Nothing is discarded: every distinct version is decoded to
`raw/tables/<Table>/variants/<archive-slug>/` in the same shape, indexed in that
table's `index.json` and in `raw/tables/_variants.json`.

```
python -m tools.find "Tide Lash" --variant baseChain   # what a CoA character reads
python -m tools.find "Tide Lash" --variant overlay     # the realm overlay only
python -m tools.find "Tide Lash" --variant all         # every version, each labelled
```

Every hit names the version it came from, so an answer can always say which layer
it used.

### How complete this is, stated as a boundary

Everything in the client that can be extracted has been. Two exclusions, both
deliberate decisions by the repository owner, neither of them silent:

- **Art and sound: recorded, not committed.** Path, size and sha256 for every one
  of them are in this repo; the bytes (53.5 GB of art, 9.0 GB of sound) stay in the
  client. A repository-size rule applied by measurement, reversible from the client
  and checkable against the recorded hashes.
- **Install-specific data: excluded.** `WTF/`, `Logs/`, `Errors/`, `Screenshots/`,
  launcher logs and third-party addons are machine state rather than client
  content, and are volatile between launches, so including them would break
  byte-for-byte reproduction.

Everything else is in: all 368 tables plus every non-winning version of each, the
Interface code layer, `Data\Content` and `.loc`, the WDB caches, every executable's
strings/inlined Lua/PE structure, and the deleted, encrypted and nested-container
members in `raw/recovered/`. Of the 637,590 paths the census records, **4,906 are
`readable: false` and every one is an MPQ delete tombstone** - a patch entry that
removes a path and carries no bytes by design. Zero files are genuinely unreadable,
and all 763,928 members check clean against the MD5 their own archive recorded
(`python -m tools.crack --only verify`).
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
the PE structure), `recovered/` (patch tombstones, empty members, the per-member
CRC32+MD5 oracle each archive records about itself, and expanded nested archives),
`realms/`
(realm-overlay diffs), `talents/` (the pinned talent-builder capture); `data/` = the
curated derived layer; `tools/` = the pipeline; `work/` =
gitignored scratch. Every layer carries `_complete.json` - a layer without one was
left half-written by a crash and must not be read.

Spec: `docs/superpowers/specs/2026-07-17-coa-datamine-design.md`,
`docs/superpowers/specs/2026-07-23-coa-datamine-v2-design.md`,
`docs/superpowers/plans/2026-08-01-coa-datamine-v3.md`.
