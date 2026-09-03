"""Unlistable-archive provenance probe (DATAMINE-REQUEST.md
Sec 5.1 + Sec 5.2).

Sec 5.1's killer detail: patch-W, patch-WB and patch-WC sort lexicographically
ABOVE patch-T, and patch-T.MPQ contains exactly one file - DBFilesClient\\
Spell.dbc - which wins the base chain and is what the ENTIRE dataset is built
on. None of mpyq's normal chain walk can see those three archives (no
listfile), so a Spell.dbc hiding in one of them would silently outrank
patch-T and nobody would know. This file:

1. Proves tools/probe_unlistable.py's hash-table-only technique against a
   POSITIVE control (patch-T.MPQ really does carry Spell.dbc, provably
   without ever reading its listfile) and a negative control, before trusting
   it against the real unlistables.
2. Re-derives, from a live extract_mpq.extract_all() run against this
   machine's real client, that none of the 8 unlistable archives carries a
   hit that outranks its table's current winner - the forward-looking gate a
   future patch could trip.
3. Sanity-checks the Sec 5.2 census (368 distinct DBFilesClient names in the
   chain vs 77 extracted at doc-authoring time; WANTED_DBCS has since grown
   to 88 across v2/v3/v4 tasks, so only distinctDbcNamesInChain is checked
   against the doc figure, with drift tolerance)."""
import json, sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

# Read-only test: sandbox() reads client bytes from the sealed snapshot and
# arms the guard that fails this test if it writes a committed root.
from tests import _iso; _iso.sandbox()

from tools import config, probe_unlistable as probe_unlistable_mod
from tools.extract_mpq import chain_rank, _list_archives
from tools.probe_unlistable import probe_paths, discover_unlistable, probe_all, try_list

D = config.CLIENT_DIR / "Data"

# ================= 1. positive/negative controls =================

# patch-T.MPQ is itself one of the archives WITH a listfile (extract_mpq.py's
# chain walk resolves spell.dbc from it normally) - used here only as a known-
# good fixture to prove probe_paths() gets the right answer via hash-table
# lookup ALONE, independent of and without ever calling MPQArchive(...,
# listfile=True) on it.
t_result = probe_paths(D / "patch-T.MPQ",
                        [r"DBFilesClient\Spell.dbc", r"DBFilesClient\NonsenseTable123.dbc"])
assert t_result[r"DBFilesClient\Spell.dbc"] is True, t_result
assert t_result[r"DBFilesClient\NonsenseTable123.dbc"] is False, t_result

# case-insensitivity: mpyq's _hash() uppercases internally, so a differently-
# cased path must resolve identically.
t_result_lower = probe_paths(D / "patch-T.MPQ", [r"dbfilesclient\spell.dbc"])
assert t_result_lower[r"dbfilesclient\spell.dbc"] is True, t_result_lower

# patch-M.MPQ: 3 known-carried tables (all confirmed winners in
# config.WANTED_DBCS's own extraction) + 1 known-absent table.
m_result = probe_paths(D / "patch-M.MPQ", [
    r"DBFilesClient\Creature.dbc", r"DBFilesClient\Quest.dbc",
    r"DBFilesClient\gtCombatRatings.dbc", r"DBFilesClient\NoSuchTableAtAll.dbc",
])
assert m_result[r"DBFilesClient\Creature.dbc"] is True, m_result
assert m_result[r"DBFilesClient\Quest.dbc"] is True, m_result
assert m_result[r"DBFilesClient\gtCombatRatings.dbc"] is True, m_result
assert m_result[r"DBFilesClient\NoSuchTableAtAll.dbc"] is False, m_result

# ================= 2. discover the real unlistables =================

KNOWN_UNLISTABLE = {
    "patch-4.MPQ", "patch-5.MPQ", "patch-C.MPQ", "patch-CZZ.MPQ",
    "patch-W.MPQ", "patch-WB.MPQ", "patch-WC.MPQ", "patch-P.mpq",
}
discovered = {p.name for p in discover_unlistable()}
assert discovered == KNOWN_UNLISTABLE, discovered

# patch-W/WB/WC sort ABOVE patch-T in chain order - the entire reason this
# probe exists. Re-derive that ordering fact too, not just cite it.
t_rank = chain_rank(D / "patch-T.MPQ")
for name in ("patch-W.MPQ", "patch-WB.MPQ", "patch-WC.MPQ"):
    assert chain_rank(D / name) > t_rank, name

# ============== 2.5 predicate equivalence (review fix pass) ==============

# [review fix] extract_mpq.extract_all()'s chain-walk skip decision
# and probe_unlistable.discover_unlistable() must use the IDENTICAL predicate -
# a review caught them diverging (extract_all() only caught the exception
# shape; discover_unlistable() also caught a successful-open-but-empty
# .files). Both now derive from tools.probe_unlistable.try_list(); this
# re-derives that structurally, WITHOUT running the slow full extract_all()
# (no DBC read/write/hash) - just the archive-open scan, the cheap part.
all_archives = _list_archives()
extract_style_skip = {p.name for p in all_archives
                       if probe_unlistable_mod.try_list(p)[0] is None}
discover_style_skip = {p.name for p in discover_unlistable(all_archives)}
assert extract_style_skip == discover_style_skip, (extract_style_skip, discover_style_skip)
assert extract_style_skip == KNOWN_UNLISTABLE, extract_style_skip
# try_list() itself: (files, reason) is mutually exclusive - never both set,
# never both empty - on every real archive in the chain. The Sec 5.2 census is
# accumulated in the same walk: it used to come from a full extract_all() run
# made further down this file, which rewrote all 111 files in work/dbc from the
# live client as a side effect of a probe test (tests/_diagnosis.md). Counting
# the names here re-derives it from the listfiles directly - the same derivation
# extract_all() does, one archive walk instead of two.
all_dbc_names, per_archive_dbc_counts = set(), {}
for p in all_archives:
    files, reason = try_list(p)
    assert (files is None) != (reason is None), (p.name, files, reason)
    if files is None:
        continue
    count = 0
    for f in files:
        fl = f.decode("latin-1", "replace").lower().replace("/", "\\")
        if fl.startswith("dbfilesclient\\"):
            all_dbc_names.add(fl.rsplit("\\", 1)[-1])
            count += 1
    if count:
        per_archive_dbc_counts[p.name] = count

# ================= 3. probe_all() against the real 8 =================

probes = probe_all(archives=[D / n for n in sorted(KNOWN_UNLISTABLE)])
assert set(probes) == KNOWN_UNLISTABLE, set(probes)
for name, frag in probes.items():
    assert "error" not in frag, (name, frag)   # all 8 open fine with listfile=False
    assert frag["probedCount"] == len(config.WANTED_DBCS), (name, frag["probedCount"])

# The gate: probe finds ZERO Spell.dbc in patch-W/WB/WC (expected per the doc -
# verify, that's the point) - asserted explicitly so a future patch adding one
# re-checks automatically instead of relying on silence.
for name in ("patch-W.MPQ", "patch-WB.MPQ", "patch-WC.MPQ"):
    assert r"DBFilesClient\Spell.dbc" not in probes[name]["hits"], (
        f"{name} now carries Spell.dbc - it sorts above patch-T and would "
        f"SILENTLY WIN the base chain; extract_mpq.extract_all()'s own FATAL "
        f"check should have already caught this")

# ================= 4. the forward-looking outranking gate =================

# extract_mpq.extract_all() runs this exact probe internally and raises SystemExit
# if any hit outranks its table's current winner. That call used to be made HERE -
# against the live client, rewriting all 111 files in work/dbc as a side effect of
# a probe test, and comparing snapshot-derived pins against live-client bytes
# (tests/_diagnosis.md). The gate is unchanged and still independent of trusting
# extract_all(): the probe output above is compared against the winner each table
# was actually built from, as recorded by the single writer of work/dbc.
base = json.loads((config.WORK_DIR / "curation_inputs.json")
                  .read_text(encoding="utf-8"))["base"]
winner_rank = {}
for table, rec in base.items():
    wname = rec["archive"].rsplit("/", 1)[-1]
    wpath = D / wname if (D / wname).is_file() else D / "enUS" / wname
    winner_rank[table.lower()] = chain_rank(wpath)
assert set(probes) == KNOWN_UNLISTABLE, set(probes)

zero_outranking_hits = True
for archive_name, frag in probes.items():
    if "error" in frag:
        continue
    archive_rank = chain_rank(D / archive_name)
    for hit_path in frag["hits"]:
        table = hit_path.rsplit("\\", 1)[-1].lower()
        if table in winner_rank and archive_rank > winner_rank[table]:
            zero_outranking_hits = False
assert zero_outranking_hits, "an unlistable archive outranks a current table winner - FATAL"

# today's real answer is zero hits at all, everywhere - stronger than just
# zero OUTRANKING hits, and worth pinning until a patch actually adds
# something to one of these 8
total_hits = sum(len(frag.get("hits", [])) for frag in probes.values())
assert total_hits == 0, [
    (name, frag["hits"]) for name, frag in probes.items() if frag.get("hits")]

# ================= 5. census sanity (Sec 5.2) =================

assert abs(len(all_dbc_names) - 368) <= 25, len(all_dbc_names)   # doc figure +- drift
assert len(base) == len(config.WANTED_DBCS), (len(base), len(config.WANTED_DBCS))
# the killer fact restated as data: patch-T carries exactly the one file the
# whole dataset rests on
assert per_archive_dbc_counts["patch-T.MPQ"] == 1, per_archive_dbc_counts
assert len(all_dbc_names) > len(config.WANTED_DBCS)   # Sec 5.2's whole point

print("ALL PASS")
