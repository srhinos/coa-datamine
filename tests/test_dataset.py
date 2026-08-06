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
    "manastorm", "realms",
}
assert prov["extract"]["files"]["spell.dbc"]["fields"] == 234
assert "manifestSha256" in prov["buildStats"]["interface"]
# header-invariant parity gate (task V3-3): DBCFile no longer hard-crashes on a
# declared-vs-byte-accurate field-count disagreement (needed to keep a lying
# REALM header like area-52's CharacterAdvancement.dbc readable, task V3-2) -
# that removed the old crash canary for a lying BASE header too. This is the
# replacement canary: every one of the 77 base config.WANTED_DBCS tables must
# agree with itself. A future patch shipping a base table whose header lies
# must fail THIS assert loudly, not silently ship a mismatched dump.
assert prov["headerMismatches"] == [], prov["headerMismatches"]
assert prov["extract"]["headerMismatches"] == []
ondisk = json.loads((config.RAW_DIR / "provenance.json").read_text(encoding="utf-8"))
assert ondisk["generatedUtc"].endswith("+00:00")
assert (config.REPO_ROOT / "README.md").is_file()
assert (config.REPO_ROOT / "AGENT-GUIDE.md").is_file()
print("ALL PASS")
