import json, sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from tools import config
from tools.build_dataset import run

prov = run(skip_extract=True, skip_dump=True)
assert prov["clientDir"] == str(config.CLIENT_DIR)
assert set(prov["buildStats"]) == {"spells", "classes", "talents", "dungeons"}
assert prov["extract"]["files"]["spell.dbc"]["fields"] == 234
ondisk = json.loads((config.RAW_DIR / "provenance.json").read_text(encoding="utf-8"))
assert ondisk["generatedUtc"].endswith("+00:00")
assert (config.REPO_ROOT / "README.md").is_file()
assert (config.REPO_ROOT / "docs" / "AGENT-GUIDE.md").is_file()
print("ALL PASS")
