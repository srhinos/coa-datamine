# Test-suite isolation: diagnosis

Committed (not gitignored): this is the evidence base for the isolation repair, and it
should be reviewable in the same history as the fix.

**RESOLVED.** The repair is `tests/_iso.py` (scratch roots, snapshot-only client reads, an
audit-hook guard that fails a test the moment it writes a committed root) plus
`tests/test_zz_integration.py` (the one test that rebuilds anything). Section 7's five
requirements are met, with one deliberate difference: requirement 2 is satisfied by
extracting from the SEALED SNAPSHOT rather than by re-pinning, since the pins were never
stale - see section 6. Nothing below has been rewritten to match the fix; it is the record
of what was measured before it.

Measured on branch `v5-post-merge` @ `287563fc`, client `E:\ascension-live`.
The suite is 38 plain assert scripts run as separate processes
(`Get-ChildItem tests\test_*.py | ForEach-Object { python $_.FullName }`), not pytest.
Every builder call is at **module level**, so importing a test *is* running it.
Interference is therefore entirely filesystem state, never in-process state.

---

## 0. Verdict up front

There is exactly one root cause. `work/dbc/` has **two writers with different data
sources**, and the repo's own doctrine says it should have one:

| writer | source of bytes | selection rule |
|---|---|---|
| `curate.materialize_inputs()` (via `datamine.py`) | the **sealed snapshot** (`h.table_bytes`, staged) | BASE variant — realm archives excluded |
| `extract_mpq.extract_all()` (called by 6 tests) | the **live client** `E:\ascension-live\Data` | chain winner |

`tools/curate.py` `CURATION_RULE` states the curated layer is "a pure function of the raw
layer produced by the same run of the same script, from the same snapshot … never by
reading the live client". `ENTRY_POINT_RULE` then notes the extractors "remain importable,
because the test suite rebuilds individual layers on purpose." That is the hole: the tests
use the one surface the rule was written to close.

The Ascension client auto-patches, so the live client has drifted past the sealed snapshot:

| table | sealed snapshot (pins) | live client (after `extract_all()`) | winning archive |
|---|---|---|---|
| `Spell.dbc` | 209,206 | 209,215 | `patch-T.MPQ` (**same in both**) |
| `Item.dbc` | 563,384 | 563,385 | `patch-M.MPQ` (**same in both**) |
| `SpellAffect.dbc` | 36,800 | 36,803 | `patch-S.MPQ` (**same in both**) |
| `NPCTrainer.dbc` | 13,112 | 13,113 | `patch-M.MPQ` |
| `Creature.dbc` | 127,179 | 127,179 (identical sha) | `patch-M.MPQ` |

Note the archive selection is **identical** — an early hypothesis that the realm overlay
was leaking into the base chain was tested and **disproved**. The divergence is purely
snapshot-vs-live drift.

`work/dbc/Spell.dbc` is the single best state marker:

- `a1e4285cdbc8…` = pristine / sealed snapshot (base variant)
- `215013d391aa…` = poisoned / live client

---

## 1. Side-effect inventory (test -> paths written)

30 of 38 tests write into the repo. **6 are polluters** — they repoint `work/dbc` at the
live client, and every later test that reads `work/dbc` inherits it.

### Polluters (call `extract_mpq.extract_all()` -> rewrites all 111 files in `work/dbc`)

| # | test | also writes |
|---|---|---|
| 16 | `test_extract` | `work/extract_provenance.json` |
| 19 | `test_items_layer` | `raw/dbc/itemstat/`, `data/items/`, `data/spells/`, `data/classes/`, `data/talents/coa/` |
| 27 | `test_realms` | `work/realms/` (rmtree+re-extract), `raw/realms/`, `data/realms/` |
| 34 | `test_unlistable_probe` | — |
| 35 | `test_v2_extract` | — |
| 36 | `test_v5_tables` | `data/spells/` |

### Writers under `data/` / `raw/`

| # | test | builders called | paths written |
|---|---|---|---|
| 0 | `test_abilities` | `build_abilities` | `data/abilities/` |
| 2 | `test_catalog` | `build_catalog.run()` | `raw/_catalog/`, `CATALOG.md` |
| 3 | `test_class_plumbing` | `build_essence`, `build_classes`, `build_coatalents`, `build_classmeta`, `build_realms(skip_extract=True)`, `diff_realm_overlay` | `data/classes/`, `data/talents/coa/`, `raw/realms/`, `data/realms/` |
| 4 | `test_classes` | `build_classes` | `data/classes/` |
| 5 | `test_classmeta` | `build_spells`, `build_classes`, `build_coatalents`, `build_classmeta` | `data/spells/`, `data/classes/`, `data/talents/coa/` |
| 6 | `test_closure_ranks` | `build_spells` | `data/spells/` |
| 7 | `test_coatalents` | `build_coatalents` | `data/talents/coa/` |
| 10 | `test_creatures` | `build_creatures`, `build_dungeons` | `data/creatures/`, `data/quests/`, `data/trainers/`, `data/dungeons/` |
| 11 | `test_dataset` | **`curate.run()` — all 16 stages** + `dbc.dump_all()` | `raw/tables/`, `raw/provenance.json`, and **every** `data/` domain |
| 13 | `test_dungeons` | `build_dungeons` | `data/dungeons/` |
| 15 | `test_enums_v4` | `build_spells` | `data/spells/` |
| 17 | `test_gt` | `build_gt` | `data/gt/` |
| 18 | `test_interface` | `extract_interface.extract_all()` | `raw/interface/` |
| 21 | `test_live_flags` | `build_classes`, `build_coatalents`, `build_classmeta` | `data/classes/`, `data/talents/coa/` |
| 23 | `test_manastorm` | `build_manastorm` | `data/manastorm/` |
| 24 | `test_mythic` | `build_mythic` | `data/mythic/` |
| 28 | `test_realms_bitmask` | `build_classes` | `data/classes/` |
| 29 | `test_sharding` | `build_spells`, `build_classes`, `build_talents`, `build_dungeons` | `data/spells/`, `data/classes/`, `data/talents/`, `data/dungeons/` |
| 30,31,32 | `test_spells`, `test_spells_columns`, `test_spells_v2` | `build_spells` | `data/spells/` |
| 33 | `test_talents` | `build_talents` | `data/talents/` |

### Read-only (safe)

`test_binaries`, `test_config`, `test_crack`, `test_dbc`, `test_enums_snapshot`,
`test_live_capture`, `test_live_seed`, `test_raw_layers`, `test_raw_tables`,
`test_variants` — several use `tempfile` and clean up after themselves.

Aggravating factor: most builders `shutil.rmtree()` their output directory before
rewriting it (`build_spells`, `build_classes`, `build_creatures`, `build_dungeons`,
`build_gt`, `build_manastorm`, `build_realms`, `extract_realms`). That is the window in
which two concurrent runs destroyed `data/`.

---

## 2. Solo vs sequence (measured, not inferred)

Restore between runs was by named path only
(`git checkout -- data`, `git checkout -- raw`, delete untracked, plus a robocopy `/MIR`
restore of `work/dbc` + `work/realms` from a pristine snapshot — `work/` is gitignored, so
git alone cannot restore it).

| mode | start state | result | failures |
|---|---|---|---|
| **SOLO** (pristine tree restored before each) | clean | **35 PASS / 3 FAIL** | `items_layer`, `v2_extract`, `v5_tables` |
| **SEQ 1** (alphabetical, from pristine) | clean | **34 PASS / 4 FAIL** | + `sharding` |
| **SEQ 2** (alphabetical, no restore — starts from SEQ 1's leftovers) | poisoned | **32 PASS / 6 FAIL** | + `closure_ranks`, `creatures` |

Degradation is monotonic in accumulated pollution, which is exactly the reported
"PASS=26/FAIL=11 one run, PASS=22/FAIL=16 another". **The suite's result depends on
whether a previous suite run left `work/dbc` poisoned** — the single largest source of
run-to-run nondeterminism.

Ordering detail that hides the bug on a fresh tree: alphabetically `test_dataset` (11)
runs `curate.run()` **before** the first polluter `test_extract` (16). So run 1 curates
from clean snapshot bytes. On run 2 the leftover poison is already in place when
`test_dataset` calls `dbc.dump_all()`, which re-dumps `raw/` from live-client bytes and
widens the blast radius (10 `raw/dbc/` files + 3 `data/trainers/` files flipped).

---

## 3. Three proven mechanisms

Each names the exact shared file and the exact assertion.

**(1) `test_sharding` — PASS solo, FAIL in sequence**
- Shared file: `work/dbc/Spell.dbc`
- Polluter: `tests/test_extract.py:21` `extract_all()` (idx 16 < idx 29)
- Consumer: `tools/build_spells.py:1113` `dbc.DBCFile(config.WORK_DBC_DIR / "Spell.dbc")`
  (also lines 370/384/395/407/706/712/834 for sibling DBCs)
- Assertion: `tests/test_sharding.py:125`
  `assert total == sidx["count"] == PRE_SPELL_COUNT` with `PRE_SPELL_COUNT = 32824`
- Observed: 32,827 vs 32,824. 68 `data/spells/` files change content;
  `_meta.json` shows `count 32824 -> 32827`, `formula 1624 -> 1626`, `trigger 4097 -> 4098`.

**(2) `test_closure_ranks` — PASS solo + SEQ 1, FAIL in SEQ 2**
- Shared file: `work/dbc/Spell.dbc` (left poisoned by the *previous* suite run)
- Assertion: `tests/test_closure_ranks.py:187`
  `assert sbp["referencedBySpellCount"] == 559`
- Observed: 565 vs 559. The test's own section (d) is titled "independently re-scan
  `work/dbc/Spell.dbc`" — it reads the poisoned file by name.

**(3) `test_creatures` — PASS solo + SEQ 1, FAIL in SEQ 2**
- Shared file: `work/dbc/NPCTrainer.dbc`
- Assertion: `tests/test_creatures.py:133`
  `assert total_t == tidx["count"] == stats["trainers"]["written"] == 13112  # 2026-08-09 snapshot pin`
- Observed: 13,113 vs 13,112 — precisely the live-vs-snapshot delta for `NPCTrainer.dbc`.

---

## 4. The segfault (exit 139)

**Verdict: not a genuine crash in `test_enums_v4`, and not attributable to any test's own
logic. Not reproducible at HEAD.**

- `test_enums_v4` exited **0 in 6/6 runs** (solo, SEQ 1, SEQ 2, plus 3 dedicated runs),
  stderr empty, terminating `ALL PASS`.
- Peak working set 1.87 GB against 17 GB free / 63.8 GB total — memory exhaustion is ruled out.
- No `mmap`, no `ctypes`, no `setrecursionlimit` anywhere in `tools/`. `tools/dbc.py:23` is
  `data = self.path.read_bytes()` + pure-Python `struct` — no native pointer arithmetic to
  fault. The only C code in the read path is `zlib`/`bz2` via `mpyq`, and `gzip`.
- The repo's own logs attach 139 to **different tests on different days** —
  `work/test-results.txt` has `FAIL(139) test_realms_bitmask`, `work/test-results2.txt`
  has `FAIL(139) test_items_layer (tries=3)`. A crash that migrates between unrelated tests
  is environmental, not a property of the test that happens to be holding it.
- 139 = 128+11 (SIGSEGV) is a POSIX convention; a native Windows Python fault is
  `0xC0000005` / 3221225477. These logs were produced by an MSYS/Git-Bash loop, which maps a
  Windows access violation onto SIGSEGV. So 139 here means "access violation", not a Python
  exception.

Most probable trigger, consistent with everything above: `mpyq` reading an MPQ in
`E:\ascension-live\Data` while the client's own auto-patcher rewrites it, and/or two
concurrent suite runs racing the `rmtree`-then-rewrite window. Both are consequences of the
same live-client coupling. Deliberately **not** re-provoked here — reproducing it means
running two suites concurrently, which is what destroyed `data/` before. Re-check after
isolation is fixed; if the suite no longer touches the live client, the trigger is gone.

---

## 5. The byte-identical rewrites

Confirmed and quantified. `test_spells` alone, on a pristine tree:

- tracked files **rewritten** (mtime changed): **112** (all under `data/spells/`)
- tracked files with **content** change (git): **0**

They write because `build_spells.build()` unconditionally `shutil.rmtree()`s
`data/spells/` (`tools/build_spells.py:1344`) and re-emits every shard. There is no
"write only if changed" guard anywhere in the builder layer. Output is deterministic
(sorted keys, gzip `mtime=0`), so the bytes land identical — stat-dirty, content-clean.
Harmless to correctness, but it defeats mtime-based change detection and makes
`git status` the only trustworthy cleanliness check.

Across the whole suite this is ~99 tracked `data/*.json` files, matching the report.

---

## 6. Classification of every failing test

| test | solo | seq | class | why |
|---|---|---|---|---|
| `test_items_layer` | FAIL | FAIL | **(a) real defect** | `test_items_layer.py:50` — `Item: records 563385 != 563384`. Calls `extract_all()` **itself**, so it fails on a pristine tree. It reads the live client and compares against sealed-snapshot pins. |
| `test_v2_extract` | FAIL | FAIL | **(a) real defect** | `test_v2_extract.py:35` — `NPCTrainer.dbc: got (13113,4) want (13112, 4)`. Same self-inflicted live read. |
| `test_v5_tables` | FAIL | FAIL | **(a) real defect** | `test_v5_tables.py:71` — `SpellAffect: records 36803 != 36800`. Same. |
| `test_sharding` | PASS | FAIL | **(c) isolation artifact** | mechanism (1) |
| `test_closure_ranks` | PASS | FAIL (run 2) | **(c) isolation artifact** | mechanism (2) |
| `test_creatures` | PASS | FAIL (run 2) | **(c) isolation artifact** | mechanism (3) |

**Counts: (a) = 3, (b) = 0, (c) = 3.**

On the absence of (b): these pins are **not** stale with respect to the repo's source of
truth. Every pin matches the sealed snapshot that `data/` and `raw/` were built from. They
disagree only with the *live client*, which the tests were never supposed to read
(`CURATION_RULE`). Re-pinning to 563,385 / 13,113 / 36,803 would go green today and break
again at the next Ascension patch, while cementing the live-client dependency. The pins are
correct; the live read is the defect. Hence (a), not (b).

---

## 7. What the fix has to do

1. **Restore single-writer ownership of `work/dbc`.** No test may call
   `extract_mpq.extract_all()` / `extract_realms.extract_all()` against the live client.
   Those six tests need a fixture (a sealed, committed sample of the archives they assert
   on) or must assert against the snapshot the rest of the repo is a pure function of.
2. **Make the pins snapshot-relative.** Read expected counts from
   `raw/provenance.json` `curationInputs` rather than hardcoding, so a client patch cannot
   turn a green suite red without a deliberate re-capture.
3. **Stop rebuilding shared state as an import side effect.** Builders at module level
   mean tests cannot be ordered, filtered, or parallelised. Move them into functions with a
   session-scoped fixture, or have tests read committed `data/` rather than regenerate it.
4. **Guard the rmtree window** so two runs cannot destroy `data/` (lockfile, or build into
   a temp dir and swap).
5. Only after 1–3: re-check 139 and add a cleanliness gate (`git status --porcelain` must
   be empty after a full run).
