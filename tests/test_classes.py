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


def load_class(name):
    meta = json.loads((cdir / byname[name]["index"]).read_text(encoding="utf-8"))
    entries = []
    for f in meta["files"]:
        doc = json.loads((cdir / byname[name]["dir"] / f["file"]).read_text(encoding="utf-8"))
        assert doc["class"] == name
        entries.extend(doc["entries"])
    return meta, entries


wl_meta, wl_entries = load_class("RebornWarlock")
assert wl_meta["tag"] == "reborn" and len(wl_entries) == 1719
assert wl_meta["realmHint"] == "Bronzebeard - Warcraft Reborn"
# RebornWarlock's Destruction/Affliction tabs are >5000 lines as single files - proves
# the Tab -> Type -> cadId-range cascade actually engaged, not just a no-op passthrough.
tabs = {f["tab"] for f in wl_meta["files"]}
assert len(wl_meta["files"]) > len(tabs), "expected an oversized tab to shard into >1 file"
assert any(f["cadIdRange"] for f in wl_meta["files"]), "expected a cadId-range shard"

necro_meta, necro_entries = load_class("Necromancer")
assert necro_meta["tag"] == "coa-custom" and len(necro_entries) == 427
assert isinstance(necro_meta["classId"], int) and 17 <= necro_meta["classId"] <= 32
assert necro_meta["realmHint"] == "Rexxar/Vol'jin - Conquest of Azeroth"
assert byname["Mage"]["tag"] == "vanilla"
assert byname["Mage"]["realmHint"] == "Area 52 - Free-Pick /shared"
assert "unresolvedCount" in byname["Mage"]
assert any(c["name"] == "_other" for c in index["classes"])

# every entry's spells resolved (build enforces <=5% unresolved for non-reborn classes)
some = necro_entries[0]
assert some["spells"] and all("name" in s for s in some["spells"])
assert stats["unresolved_other"] / max(1, stats["refs_other"]) <= 0.05
assert stats["unresolved_reborn"] > 0

# per-class index.json fully accounts for every shard file on disk
for f in necro_meta["files"]:
    assert (cdir / byname["Necromancer"]["dir"] / f["file"]).is_file()
assert not (cdir / "Necromancer.json").exists(), "old monolith must be gone"
assert not (cdir / "RebornWarlock.json").exists(), "old monolith must be gone"
print("ALL PASS")
