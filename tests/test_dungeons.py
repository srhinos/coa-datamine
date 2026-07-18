import json, sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from tools import config
from tools import build_dungeons

stats = build_dungeons.build()
doc = json.loads((config.DATA_DIR / "dungeons" / "dungeons.json").read_text(encoding="utf-8"))
ds = doc["dungeons"]
assert len(ds) == 431
names = {d["name"] for d in ds}
assert any("eadmines" in n for n in names), "Deadmines missing"
raids = [d for d in ds if d["map"] and d["map"]["isRaid"]]
assert raids, "no raids classified"
withenc = [d for d in ds if d["encounters"]]
assert len(withenc) > 50
one = withenc[0]
assert one["encounters"][0]["name"] and "orderIndex" in one["encounters"][0]
assert doc["encountersByMap"]
assert stats["encounters"] == 2080
assert stats["orphanEncounterMaps"] < 50
rewarded = [d for d in ds if d["rewards"]]
assert rewarded, "LFGData rewards not joined"
print("ALL PASS")
