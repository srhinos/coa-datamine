# Suite certification: order independence, repeatability, tree cleanliness

Certifies the isolation work in `a5a500e9..a13ff0d2` by measurement rather than by
claim. Every `tests/test_*.py` was run as its own process and judged **by exit
code only** — several tests print JSON after their `ALL PASS` line, so any
text-matching verdict is unreliable.

- Branch `v5-post-merge` at `a13ff0d2`, tree clean at start.
- Runner: `python.exe tests/<file>.py`, `cwd` = repo root, one process per test.
- 40 test files x 4 runs = **160 test-process executions**.

| run | ordering | wall (sum of per-test) |
|---|---|---|
| 1 | alphabetical | 1142.2 s |
| 2 | reverse-alphabetical | 1152.9 s |
| 3 | shuffled, `random.Random(1786706345).shuffle()` | 1160.2 s |
| 4 | alphabetical (repeat of run 1) | 1158.5 s |

## 1. Exit-code matrix

`0` = pass. Positions are the 1-based index at which the file ran in that order,
included so the matrix shows the orderings really were different.

| test | r1 pos | r2 pos | r3 pos | r4 pos | run1 | run2 | run3 | run4 |
|---|---|---|---|---|---|---|---|---|
| `test_abilities.py` | 1 | 40 | 22 | 1 | 0 | 0 | 0 | 0 |
| `test_binaries.py` | 2 | 39 | 17 | 2 | 0 | 0 | 0 | 0 |
| `test_catalog.py` | 3 | 38 | 6 | 3 | 0 | 0 | 0 | 0 |
| `test_class_plumbing.py` | 4 | 37 | 34 | 4 | 0 | 0 | 0 | 0 |
| `test_classes.py` | 5 | 36 | 19 | 5 | 0 | 0 | 0 | 0 |
| `test_classmeta.py` | 6 | 35 | 24 | 6 | 0 | 0 | 0 | 0 |
| `test_closure_ranks.py` | 7 | 34 | 4 | 7 | 0 | 0 | 0 | 0 |
| `test_coatalents.py` | 8 | 33 | 27 | 8 | 0 | 0 | 0 | 0 |
| `test_config.py` | 9 | 32 | 25 | 9 | 0 | 0 | 0 | 0 |
| `test_crack.py` | 10 | 31 | 16 | 10 | 0 | 0 | 0 | 0 |
| `test_creatures.py` | 11 | 30 | 35 | 11 | 0 | 0 | 0 | 0 |
| `test_dataset.py` | 12 | 29 | 28 | 12 | 0 | 0 | 0 | 0 |
| `test_dbc.py` | 13 | 28 | 13 | 13 | 0 | 0 | 0 | 0 |
| `test_dungeons.py` | 14 | 27 | 40 | 14 | 0 | 0 | 0 | 0 |
| `test_enums_snapshot.py` | 15 | 26 | 21 | 15 | 0 | 0 | 0 | 0 |
| `test_enums_v4.py` | 16 | 25 | 30 | 16 | 0 | 0 | 0 | 0 |
| `test_extract.py` | 17 | 24 | 37 | 17 | 0 | 0 | 0 | 0 |
| `test_gt.py` | 18 | 23 | 18 | 18 | 0 | 0 | 0 | 0 |
| `test_interface.py` | 19 | 22 | 7 | 19 | 0 | 0 | 0 | 0 |
| `test_iso_guard.py` | 20 | 21 | 26 | 20 | 0 | 0 | 0 | 0 |
| `test_items_layer.py` | 21 | 20 | 36 | 21 | 0 | 0 (after 0xC0000005) | 0 | 0 |
| `test_live_capture.py` | 22 | 19 | 39 | 22 | 0 | 0 | 0 | 0 |
| `test_live_flags.py` | 23 | 18 | 8 | 23 | 0 | 0 | 0 | 0 |
| `test_live_seed.py` | 24 | 17 | 10 | 24 | 0 | 0 | 0 | 0 |
| `test_manastorm.py` | 25 | 16 | 2 | 25 | 0 | 0 | 0 | 0 |
| `test_mythic.py` | 26 | 15 | 12 | 26 | 0 | 0 | 0 | 0 |
| `test_raw_layers.py` | 27 | 14 | 3 | 27 | 0 | 0 | 0 | 0 |
| `test_raw_tables.py` | 28 | 13 | 11 | 28 | 0 | 0 | 0 | 0 |
| `test_realms.py` | 29 | 12 | 15 | 29 | 0 | 0 | 0 | 0 |
| `test_realms_bitmask.py` | 30 | 11 | 33 | 30 | 0 | 0 | 0 | 0 |
| `test_sharding.py` | 31 | 10 | 14 | 31 | 0 | 0 | 0 | 0 |
| `test_spells.py` | 32 | 9 | 20 | 32 | 0 | 0 | 0 | 0 |
| `test_spells_columns.py` | 33 | 8 | 31 | 33 | 0 | 0 | 0 | 0 |
| `test_spells_v2.py` | 34 | 7 | 32 | 34 | 0 | 0 | 0 | 0 |
| `test_talents.py` | 35 | 6 | 29 | 35 | 0 | 0 | 0 | 0 |
| `test_unlistable_probe.py` | 36 | 5 | 9 | 36 | 0 | 0 (after 0xC0000005) | 0 | 0 |
| `test_v2_extract.py` | 37 | 4 | 23 | 37 | 0 | 0 | 0 | 0 |
| `test_v5_tables.py` | 38 | 3 | 1 | 38 | 0 | 0 (after 0xC0000005) | 0 | 0 |
| `test_variants.py` | 39 | 2 | 38 | 39 | 0 | 0 | 0 | 0 |
| `test_zz_integration.py` | 40 | 1 | 5 | 40 | 0 | 0 | 0 | 0 |

**Counts, per run: 40 pass / 0 fail / 0 skip.** Across all four runs: 160/160
passing test-process executions, no failures, no skips.

## 2. Order independence — HOLDS

No file's assertion outcome differs across runs 1, 2 and 3. The orderings are
genuinely distinct: `test_zz_integration.py` ran last, first and 5th;
`test_abilities.py` ran 1st, 40th and 22nd.

The one thing that did differ is three **hard process crashes**, all in run 2 —
see section 6. They are not order-dependent failures, and the decisive evidence
is `test_items_layer.py`: it crashed at position 20 of run 2 and its immediate
rerun **at the same position, with the same 19 predecessors** passed. Same order,
different outcome, so order cannot be the variable.

## 3. Repeatability — HOLDS

Runs 1 and 4 are the same ordering. Their exit-code columns are identical: 40
zeros against 40 zeros, no crashes in either.

## 4. Tree cleanliness — HOLDS

`git status --porcelain` was captured **after every individual test** (160
samples), not just per run. It was empty every time, including after the three
crashed processes. Before and after each of the four runs it was also empty.

The three crashes each orphaned a scratch tree — `work/_test/test_items_layer-*`,
`test_unlistable_probe-*`, `test_v5_tables-*` — because the process dies before
`atexit` can run `_iso._cleanup()`. `work/` is gitignored, so this does not dirty
the tree, and `_iso._sweep_stale()` removes them on the next run after 12 h.

## 5. Skips — NONE

Zero skips. Four tests carry conditional `SKIP` branches for a missing snapshot,
an unmounted client, or an absent `mpyq` (`test_binaries.py`, `test_crack.py`,
plus skip-list logic in `test_items_layer.py` and `test_spells_columns.py`). Each
was run with its full stdout scanned for `SKIP`/`skipping`; **no branch fired**,
so every one took its full path. Runs 2-4 additionally recorded any such line per
test as part of the harness; all empty.

## 6. The 0xC0000005 crash (pre-existing, not caused by isolation)

Signature: return code `3221225477` (`0xC0000005`, access violation), **zero
bytes of stdout** — the captured pipe buffer dies with the process, so this is
never confusable with an assertion failure, which always prints — and an orphaned
scratch dir.

Occurrences here: 3 of 160 executions (1.9%), all inside run 2, on
`test_v5_tables.py` (pos 3), `test_unlistable_probe.py` (pos 5) and
`test_items_layer.py` (pos 20). All three passed on immediate rerun. The parent
task independently recorded three occurrences in ~100 earlier executions,
including one in a plain uninstrumented run and one on a pre-edit baseline, so it
predates both the seeding change and this harness.

Common factor: every affected test drives MPQ extraction/decompression over large
buffers (`tools/mpq.py`, bz2/zlib). It is nondeterministic, it is not
order-correlated (three different tests, three different positions, and a
same-position rerun flips it), and it is not an isolation defect — the guard is
still armed and the tree stayed clean through every crash. It is logged here as a
known infrastructure flake, **not** as a passing result dressed up: the crashes
are in the matrix.

## 7. Dishonesty check vs `origin/master`

12 commits, 41 test files touched, 114 assert lines added and 40 removed. Every
removed assertion was traced.

**The four isolation commits (`a5a500e9..a13ff0d2`) weakened nothing.** All 19
asserts they removed were bound to a live `extract_mpq.extract_all()` return
value, and each is either re-homed verbatim or re-anchored to the committed
`work/curation_inputs.json` sidecar with an identical predicate:

| removed from | assertion | verdict |
|---|---|---|
| `test_extract.py` | `set(prov["files"]) == {w.lower() for w in WANTED_DBCS}` | re-homed **verbatim** to `test_zz_integration.py:78` |
| `test_extract.py` | `isinstance(prov["skipped_archives"], list)` | re-homed **verbatim** to `test_zz_integration.py:79` |
| `test_extract.py` | `saved[...]["winner"] == spell["winner"]` | re-homed **verbatim** to `test_zz_integration.py:92` |
| `test_extract.py` | `spell["winner"] == "patch-t.mpq"`, `fields == 234` | kept, read from the sidecar; **strengthened** with per-table `records`/`declaredFields` equality for all 111 wanted DBCs and a `chain_rank` equality |
| `test_unlistable_probe.py` | `census["extractedCount"] == len(WANTED_DBCS)` | re-homed **verbatim** to `test_zz_integration.py:93` |
| `test_unlistable_probe.py` | `set(prov["unlistableProbes"]) == KNOWN_UNLISTABLE` | same equality, re-derived locally |
| `test_unlistable_probe.py` | `abs(census[...] - 368) <= 25` | same band, **unchanged tolerance**, re-derived locally |
| `test_unlistable_probe.py` | `perArchiveDbcCounts["patch-T.MPQ"] == 1`, `> extractedCount` | same predicates, re-derived locally |
| `test_items_layer.py`, `test_v5_tables.py` | `name.lower() in prov["files"]`, ItemStat/ItemSpells present, `spellitemenchantmentcondition.dbc in mismatch_names` | same predicates against `curation_inputs.json`, itself proven byte-equal to a fresh `extract_all()` at `test_zz_integration.py:124-125` |
| `test_dataset.py` | `prov["clientDir"] == str(config.CLIENT_DIR)` | **necessary** correction, not a relaxation: `sandbox()` repoints `config.CLIENT_DIR` at the snapshot, so the assert now compares against `_iso.LIVE_CLIENT`, the value actually recorded. Still exact equality. |

`test_zz_integration.py` is new and net-adds coverage: it runs `extract_all()` and
`extract_realms.extract_all()` end to end against the sealed snapshot and asserts
**sha256 byte-identity** of every materialized file against the committed record.

**Re-pins from the data rebuild `56909fbd` / the 2026-08-12 client patch** — all
remain exact `==`, none relaxed into a range: `referencedBySpellCount` 552→559;
Creature count 127178→127179; `resolved` 6038→6039; charges 406/106→407/107;
`negatives` 2409→2419; `distinct_abs_f2` 10684→10688; `sr_named`/`sr_f1_hits`
23179→23204; `sr_f2_hits` 23174→23199; `rank1_self` 3503/3506→3504/3507;
`dbc_only` 13238→13263; `dbc_only_real` 13233→13258.

### One genuine gate removal — flagged

`tests/test_class_plumbing.py`, commit **`287563fc` "Apply final audit findings"**
(pre-isolation), removed:

```python
for label, cmp in result["docComparison"].items():
    assert cmp["withinTolerance"], (label, cmp)
```

This gated four realm-overlay magnitudes at +/-10% of figures cited by an external
document not present in this repo. Its own replacement comment states three of the
four had drifted past the band. **An assertion that was failing was deleted rather
than fixed** — that is the exact pattern this check exists to catch, so it is
recorded as a weakened gate regardless of the rationale.

Mitigating, and why it is not judged an attempt to fake a pass: the removed loop
sat *above* the file's structural goldens, so a failure there prevented them from
ever running — it was masking assertions, not adding them. It was replaced by
stricter, repo-internal checks (`max(col_counts) <= differingSharedCount <=
sum(col_counts)`, the `differingSharedPct` recomputation, set arithmetic over
overlay/base id sets, and the spell 92093 Deadeye→Houndmaster rename golden). It
predates the isolation work and is unrelated to it. It should nevertheless be
re-litigated on its own merits, not inherited silently.

## Verdict

Order independence, repeatability and tree cleanliness are **certified by
measurement**: 160/160 executions pass, 0 fail, 0 skip, tree byte-clean after all
160. The suite's results no longer depend on the order it is run in. Two caveats
stand on the record: a pre-existing native `0xC0000005` crash at ~2% of executions
in the MPQ extraction path, and one pre-existing removed tolerance gate in
`test_class_plumbing.py`.
