import json, sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from tools import config
from tools.build_dataset import run

prov = run(skip_extract=True, skip_dump=True)
assert prov["clientDir"] == str(config.CLIENT_DIR)
assert set(prov["buildStats"]) == {
    "spells", "classes", "talents", "dungeons",
    "creatures", "classmeta", "essence", "mythic", "interface",
    "manastorm", "realms", "coatalents", "items", "gt",
}
assert prov["extract"]["files"]["spell.dbc"]["fields"] == 234
assert "manifestSha256" in prov["buildStats"]["interface"]
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
assert prov["extract"]["headerMismatches"] == prov["headerMismatches"]
ondisk = json.loads((config.RAW_DIR / "provenance.json").read_text(encoding="utf-8"))
assert ondisk["generatedUtc"].endswith("+00:00")
assert (config.REPO_ROOT / "README.md").is_file()
assert (config.REPO_ROOT / "AGENT-GUIDE.md").is_file()
print("ALL PASS")
