"""Task W4-7 gate: unlistable-archive provenance probe (coa-sim-handoff/
DATAMINE-REQUEST.md Sec 5.1 + Sec 5.2).

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
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from tools import config
from tools.extract_mpq import chain_rank, extract_all
from tools.probe_unlistable import probe_paths, discover_unlistable, probe_all

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

# extract_all() runs this exact probe internally and raises SystemExit if any
# hit outranks its table's current winner - a clean return here already means
# that held. Re-derive it explicitly anyway (independent of trusting that
# extract_all() didn't silently swallow the condition) against a real,
# freshly-built provenance fragment.
prov = extract_all()
assert "unlistableProbes" in prov
assert set(prov["unlistableProbes"]) == KNOWN_UNLISTABLE, set(prov["unlistableProbes"])

zero_outranking_hits = True
for archive_name, frag in prov["unlistableProbes"].items():
    if "error" in frag:
        continue
    archive_rank = chain_rank(D / archive_name)
    for hit_path in frag["hits"]:
        base = hit_path.rsplit("\\", 1)[-1].lower()
        winner_name = prov["files"][base]["winner"]
        winner_rank = chain_rank(D / winner_name) if (D / winner_name).is_file() \
            else chain_rank(D / "enUS" / winner_name)
        if archive_rank > winner_rank:
            zero_outranking_hits = False
assert zero_outranking_hits, "an unlistable archive outranks a current table winner - FATAL"

# today's real answer is zero hits at all, everywhere - stronger than just
# zero OUTRANKING hits, and worth pinning until a patch actually adds
# something to one of these 8
total_hits = sum(len(frag.get("hits", [])) for frag in prov["unlistableProbes"].values())
assert total_hits == 0, [
    (name, frag["hits"]) for name, frag in prov["unlistableProbes"].items() if frag.get("hits")]

# ================= 5. census sanity (Sec 5.2) =================

census = prov["census"]
assert abs(census["distinctDbcNamesInChain"] - 368) <= 25, census   # doc figure +- drift
assert census["extractedCount"] == len(config.WANTED_DBCS)
# the killer fact restated as data: patch-T carries exactly the one file the
# whole dataset rests on
assert census["perArchiveDbcCounts"]["patch-T.MPQ"] == 1, census["perArchiveDbcCounts"]
assert census["distinctDbcNamesInChain"] > census["extractedCount"]   # Sec 5.2's whole point

print("ALL PASS")
