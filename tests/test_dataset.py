"""Gate on the CURATED layer being a derived function of raw, driven by datamine.

This test used to import `tools.build_dataset.run` - the second pipeline, the one
that re-read the live client for itself and seeded the curated layer from the CAD
catalog. There is no such module any more: `datamine.py` calls `tools.curate.run()`
over inputs `tools.curate.materialize_inputs()` wrote out of the traversal's own
staged bytes, so this re-runs curation against the LAST FULL PASS's inputs rather
than against a fresh scan of the client. `tools/curate.py` has no `__main__` and
no other caller - datamine.py remains the single entry point.
"""
import json, sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

# Read-only test: sandbox() reads client bytes from the sealed snapshot and arms
# the guard that fails this test if it writes a committed root.
from tests import _iso; _iso.sandbox()

from tools import config, curate

inputs_path = config.WORK_DIR / curate.CURATION_INPUTS_JSON
assert inputs_path.is_file(), (
    f"{inputs_path} is missing - run `python datamine.py` once; curation reads "
    "the bytes that pass materialized, and there is no second way to make them")
inputs = json.loads(inputs_path.read_text(encoding="utf-8"))

# The curated layer's inputs are the BASE variant, never the chain winner. On
# this client the chain winner for Spell.dbc is area-52's realm overlay, which is
# missing live CoA content - curating off it would silently drop live abilities.
assert all(a not in inputs["baseArchives"] for a in
           [r for v in inputs["realms"].values() for r in v["archives"]]), \
    "a realm archive leaked into the base curation context"
spell_variants = json.loads(
    (config.RAW_DIR / "tables" / "Spell" / "variants" / "index.json")
    .read_text(encoding="utf-8"))["variants"]
base_variant = next(v for v in spell_variants if "baseChain" in v["appliesTo"])
assert inputs["base"]["Spell.dbc"]["sha256"] == base_variant["sha256"], (
    "curation did not read the base Spell variant: "
    f"{inputs['base']['Spell.dbc']['sha256']} vs {base_variant['sha256']}")
assert not base_variant["chainWinner"], (
    "the base variant IS the chain winner on this client - the distinction this "
    "gate protects has changed shape, re-derive it before relaxing the test")

# This file used to CALL curate.run() - all 16 stages plus dbc.dump_all() - as an
# import side effect, which made it the widest-blast-radius writer in the suite:
# every data/ domain plus raw/tables and raw/provenance.json, rebuilt from
# whatever happened to be in work/dbc when it ran (tests/_diagnosis.md). The
# rebuild is now owned by exactly one test, tests/test_zz_integration.py, which
# runs it from the sealed snapshot into a scratch tree and proves it reproduces
# these numbers. What is asserted here is the COMMITTED provenance - a strictly
# stronger gate on the shipped artifact than re-deriving it in memory and
# checking the copy, which is what a stale committed provenance would pass.
prov = json.loads((config.RAW_DIR / "provenance.json").read_text(encoding="utf-8"))
assert prov["clientDir"] == str(_iso.LIVE_CLIENT), prov["clientDir"]
assert set(prov["buildStats"]) == {
    "abilities", "spells", "classes", "talents", "dungeons",
    "creatures", "classmeta", "essence", "mythic",
    "manastorm", "realms", "coatalents", "items", "gt",
    # both write committed files under data/ off the tree the stages above
    # produced; they were hand-run CLIs until they were folded in here, which
    # let their outputs keep a previous run's numbers through a rebuild
    "overlayDiff", "coverageLive",
}, set(prov["buildStats"])
# interface + content are RAW layers now, emitted from the snapshot by the same
# traversal - not curation stages that re-read the client.
assert "interface" not in prov["buildStats"]
assert (config.RAW_INTERFACE_DIR / "_manifest.json").is_file()
assert (config.RAW_CONTENT_DIR / "CharacterAdvancementData.json").is_file()

assert prov["curationInputs"]["base"]["Spell.dbc"]["fields"] == 234

# THE gate: the curated spell layer covers every live talent-node ability. It was
# 1,963 of 3,932 (49.9%) when the closure was seeded from the CAD catalog.
live = prov["buildStats"]["spells"]["liveCoverage"]
assert live["liveNodeIds"] > 3900, live
assert live["covered"] == live["liveNodeIds"] and live["rate"] == 1.0, live
assert live["liveRecords"] >= live["liveNodeIds"], live

# header-invariant parity gate: DBCFile no longer hard-crashes on a
# declared-vs-byte-accurate field-count disagreement (needed to keep a lying
# REALM header like area-52's CharacterAdvancement.dbc readable) -
# that removed the old crash canary for a lying BASE header too. This is the
# replacement canary: every one of the base config.WANTED_DBCS tables must
# agree with itself, except the explicit, documented allowlist below. A future
# patch shipping a NEW base-table mismatch must still fail THIS assert loudly,
# not silently ship a mismatched dump.
#
# spellitemenchantmentcondition.dbc: the canary caught a real one -
# its WDBC header DECLARES 31 fields (the stock-WotLK 1+5x6 operand-condition
# shape) but record_size only backs 16. Confirmed on a fresh 2026-08-06
# extraction (not a one-off glitch); DBCFile.fields (record_size//4) is what
# this pipeline trusts for row layout, so the 16-column raw dump is correct, not
# a bug - see tools/dbc.py's TABLE_MAPS comment and AGENT-GUIDE.md's
# "Simulation-adjacent spell support tables" section for the full writeup.
_ALLOWED_HEADER_MISMATCHES = {
    "spellitemenchantmentcondition.dbc": {"declaredFields": 31, "actualFields": 16},
}
for m in prov["headerMismatches"]:
    allowed = _ALLOWED_HEADER_MISMATCHES.get(m["table"])
    assert allowed == {"declaredFields": m["declaredFields"], "actualFields": m["actualFields"]}, \
        f"unexpected/changed header mismatch: {m}"
assert {m["table"] for m in prov["headerMismatches"]} == set(_ALLOWED_HEADER_MISMATCHES), \
    prov["headerMismatches"]
# THE SINGLE ENTRY POINT, enforced instead of claimed. `python -m
# tools.build_spells` used to be a live second entry point: it rewrites part of
# data/ from whatever work/dbc and data/abilities happen to be on disk, and
# build_abilities.live_seed() reads data/abilities BACK from disk, so a
# standalone builder run could be seeded by a stale abilities layer - the exact
# two-pipeline drift this whole change set exists to remove. The four retired
# client-reading extractors are the same surface: their STAGES left the pipeline,
# their CLIs did not. No __main__ in any of them; they stay importable because
# the test suite rebuilds individual layers deliberately.
#
# `fetch_coatalents` joined this list when the live-truth capture was folded into
# the pass: it was the LAST module that both wrote into raw/ and could be run on
# its own (`python -m tools.fetch_coatalents`), and running it on its own is what
# let `live` sit days behind the raw layer with nothing noticing. `dbc` joined it
# for the same reason in smaller print - `python -m tools.dbc` ran dump_all()
# over whatever was in work/dbc and rewrote raw/dbc outside the pass.
#
# `coverage_live` and `diff_realm_overlay` joined it last: each WRITES a
# committed file under data/ (spells/_coverage_live.json and
# realms/<realm>/overlay_diff.json) that the pass did not produce at all, so a
# rebuild refreshed everything around them while their outputs kept the previous
# run's numbers - and nothing failed, because each file's internal gates are
# checked against figures stored in that same file. Both are now stages of
# curate.run(); the CLIs are gone rather than merely discouraged.
_NO_MAIN = sorted((config.REPO_ROOT / "tools").glob("build_*.py")) + [
    config.REPO_ROOT / "tools" / f"{m}.py" for m in
    ("curate", "extract_mpq", "extract_realms", "extract_interface",
     "snapshot_content", "fetch_coatalents", "dbc",
     "coverage_live", "diff_realm_overlay")]
_with_main = [p.name for p in _NO_MAIN
              if "if __name__" in p.read_text(encoding="utf-8")]
assert not _with_main, (
    f"{_with_main} still carry a __main__ - a second way to rewrite data/ "
    "outside datamine.py's guarded pass")
assert len([p for p in _NO_MAIN if p.name.startswith("build_")]) >= 15, _NO_MAIN

# ...and the same check the other way round, so a NEW entry point cannot appear
# unremarked. Every remaining __main__ under tools/ is named here with what it
# writes; the rule the list encodes is "a module that writes a COMMITTED layer
# has no __main__". Every entry below is now read-only or writes only to
# gitignored work/ - there is no longer a committed file whose only generator
# sits outside datamine.py's pass.
_CLI_TOOLS = {
    "bonus_multiplier_agreement.py": "read-only analysis, prints",
    "find.py": "read-only search over raw/",
    "lua51.py": "read-only bytecode reader",
    "mpq.py": "read-only archive reader",
    "pe.py": "read-only PE reader",
    "probe_unlistable.py": "writes work/ only, which is gitignored",
    "wdb_item.py": "read-only WDB reader",
}
_all_mains = {p.name for p in sorted((config.REPO_ROOT / "tools").glob("*.py"))
              if "if __name__" in p.read_text(encoding="utf-8")}
assert _all_mains == set(_CLI_TOOLS), (
    "the set of tools/ entry points changed: "
    f"new={sorted(_all_mains - set(_CLI_TOOLS))} "
    f"gone={sorted(set(_CLI_TOOLS) - _all_mains)}")
assert prov["entryPointRule"] and "no builder" in prov["entryPointRule"]

# The residual drift class is DISCLOSED AND MEASURED: `live` comes from an
# out-of-band web capture on its own clock, not from the client snapshot.
drift = prov["liveSeedDrift"]
assert drift["capture"]["capturedUtc"] and drift["capture"]["sha256"]
assert isinstance(drift["captureMinusSnapshotDays"], float), drift
assert "fetch_coatalents" in drift["capturedBy"]

assert prov["generatedUtc"].endswith("+00:00")
assert (config.REPO_ROOT / "README.md").is_file()
assert (config.REPO_ROOT / "AGENT-GUIDE.md").is_file()
print("ALL PASS")
