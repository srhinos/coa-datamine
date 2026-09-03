"""Chain-order rules, and the materialized base tables they decided.

This used to call `extract_mpq.extract_all()` at module level, which rewrote all
111 files in `work/dbc` from the LIVE client - the single largest source of
run-to-run nondeterminism in this suite, because the client auto-patches and
every later test reads those bytes (tests/_diagnosis.md). The extractor is still
exercised end to end, in exactly one place: tests/test_zz_integration.py runs it
against the sealed snapshot, into a scratch directory, and proves it reproduces
the committed provenance. What is left here is what this file was really for -
the pure chain_rank ordering rules, and a check that the tables the pipeline
actually materialized are the ones those rules pick.
"""
import json, struct, sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

# Read-only test: sandbox() reads client bytes from the sealed snapshot and
# arms the guard that fails this test if it writes a committed root.
from tests import _iso; _iso.sandbox()

from tools import config
from tools.extract_mpq import chain_rank

D = config.CLIENT_DIR / "Data"
# chain order: base < locale base < patch < patch-digit < locale patch < patch-letters
assert chain_rank(D / "common.MPQ") < chain_rank(D / "enUS" / "locale-enUS.MPQ")
assert chain_rank(D / "enUS" / "locale-enUS.MPQ") < chain_rank(D / "patch.MPQ")
assert chain_rank(D / "patch.MPQ") < chain_rank(D / "patch-2.MPQ")
assert chain_rank(D / "patch-2.MPQ") < chain_rank(D / "enUS" / "patch-enUS-2.MPQ")
assert chain_rank(D / "enUS" / "patch-enUS.MPQ") < chain_rank(D / "enUS" / "patch-enUS-2.MPQ")
assert chain_rank(D / "enUS" / "patch-enUS-2.MPQ") < chain_rank(D / "enUS" / "patch-enUS-10.MPQ")
assert chain_rank(D / "enUS" / "patch-enUS-2.MPQ") < chain_rank(D / "patch-A.MPQ")
assert chain_rank(D / "patch-CH.MPQ") < chain_rank(D / "patch-CHA.MPQ")
assert chain_rank(D / "patch-CHA.MPQ") < chain_rank(D / "patch-CI.MPQ")
assert chain_rank(D / "patch-T.MPQ") > chain_rank(D / "patch-S.MPQ")

# The materialized base tables: written once, by datamine.py's traversal
# (tools/curate.py materialize_inputs), out of the sealed snapshot - the single
# writer of work/dbc. Their provenance sidecar is the pin source for every count
# in this suite, so a client patch cannot turn a green suite red on its own.
inputs = json.loads((config.WORK_DIR / "curation_inputs.json")
                    .read_text(encoding="utf-8"))
base = inputs["base"]
assert set(base) == set(config.WANTED_DBCS), "all wanted DBCs materialized"
for name in config.WANTED_DBCS:
    p = config.WORK_DBC_DIR / name
    assert p.is_file(), f"missing {p} - run `python datamine.py` once"
    magic, recs, fields, recsize, strsize = struct.unpack("<4s4I", p.read_bytes()[:20])
    assert magic == b"WDBC", name
    assert p.stat().st_size == 20 + recs * recsize + strsize, f"size mismatch {name}"
    assert recs == base[name]["records"], (name, recs, base[name]["records"])
    assert fields == base[name]["declaredFields"], name

# patch-T.MPQ carries exactly one file - Spell.dbc - and the chain rules above
# are what put it on top. 234 declared fields is the load-bearing pin.
spell = base["Spell.dbc"]
assert spell["archive"].rsplit("/", 1)[-1].lower() == "patch-t.mpq", spell
assert spell["declaredFields"] == 234, spell
assert chain_rank(D / spell["archive"].rsplit("/", 1)[-1]) == chain_rank(D / "patch-T.MPQ")
print("ALL PASS")
