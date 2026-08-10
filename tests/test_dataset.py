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

prov = curate.run(inputs)
assert prov["clientDir"] == str(config.CLIENT_DIR)
assert set(prov["buildStats"]) == {
    "abilities", "spells", "classes", "talents", "dungeons",
    "creatures", "classmeta", "essence", "mythic",
    "manastorm", "realms", "coatalents", "items", "gt",
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

# header-invariant parity gate (task V3-3): DBCFile no longer hard-crashes on a
# declared-vs-byte-accurate field-count disagreement (needed to keep a lying
# REALM header like area-52's CharacterAdvancement.dbc readable, task V3-2) -
# that removed the old crash canary for a lying BASE header too. This is the
# replacement canary: every one of the base config.WANTED_DBCS tables must
# agree with itself, except the explicit, documented allowlist below. A future
# patch shipping a NEW base-table mismatch must still fail THIS assert loudly,
# not silently ship a mismatched dump.
#
# [Task W4-10] spellitemenchantmentcondition.dbc: the canary caught a real one -
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
ondisk = json.loads((config.RAW_DIR / "provenance.json").read_text(encoding="utf-8"))
assert ondisk["generatedUtc"].endswith("+00:00")
assert (config.REPO_ROOT / "README.md").is_file()
assert (config.REPO_ROOT / "AGENT-GUIDE.md").is_file()
print("ALL PASS")
