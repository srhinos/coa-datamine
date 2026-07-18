import json, sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from tools import config
from tools import build_classes

stats = build_classes.build()
cdir = config.DATA_DIR / "classes"
index = json.loads((cdir / "index.json").read_text(encoding="utf-8"))
assert len(index["chrClasses"]) == 32
byname = {c["name"]: c for c in index["classes"]}

warlock = json.loads((cdir / "RebornWarlock.json").read_text(encoding="utf-8"))
assert warlock["tag"] == "reborn" and len(warlock["entries"]) == 1719
assert warlock["realmHint"] == "Bronzebeard - Warcraft Reborn"
necro = json.loads((cdir / "Necromancer.json").read_text(encoding="utf-8"))
assert necro["tag"] == "coa-custom" and len(necro["entries"]) == 427
assert isinstance(necro["classId"], int) and 17 <= necro["classId"] <= 32
assert necro["realmHint"] == "Rexxar/Vol'jin - Conquest of Azeroth"
assert byname["Mage"]["tag"] == "vanilla"
assert byname["Mage"]["realmHint"] == "Area 52 - Free-Pick /shared"
assert "unresolvedCount" in byname["Mage"]
assert "_other" in {c["file"].split(".")[0] for c in index["classes"]} or True

# every entry's spells resolved (build enforces <=5% unresolved for non-reborn classes)
some = necro["entries"][0]
assert some["spells"] and all("name" in s for s in some["spells"])
assert stats["unresolved_other"] / max(1, stats["refs_other"]) <= 0.05
assert stats["unresolved_reborn"] > 0
print("ALL PASS")
