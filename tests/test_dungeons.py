import json, sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from tools import config
from tools import build_dungeons

stats = build_dungeons.build()
ddir = config.DATA_DIR / "dungeons"
index = json.loads((ddir / "index.json").read_text(encoding="utf-8"))
idx_dungeons = index["dungeons"]
assert len(idx_dungeons) == 431

names = {d["name"] for d in idx_dungeons}
assert any("eadmines" in n for n in names), "Deadmines missing"
raids = [d for d in idx_dungeons if d["isRaid"]]
assert raids, "no raids classified"

ds_full = []
for d in idx_dungeons:
    p = ddir / d["file"]
    assert p.is_file(), d["file"]
    doc = json.loads(p.read_text(encoding="utf-8"))
    assert doc["id"] == d["id"] and doc["mapId"] == d["mapId"] and doc["levels"] == d["levels"]
    assert "encountersByMap" not in doc, "duplicate view must be dropped (derivable)"
    ds_full.append(doc)

withenc = [d for d in ds_full if d["encounters"]]
assert len(withenc) > 50
one = withenc[0]
assert one["encounters"][0]["name"] and "orderIndex" in one["encounters"][0]
assert not (ddir / "dungeons.json").exists(), "monolith must be deleted"
assert stats["encounters"] == 2080
assert stats["orphanEncounterMaps"] < 50
rewarded = [d for d in ds_full if d["rewards"]]
assert rewarded, "LFGData rewards not joined"

by_id = {d["id"]: d for d in ds_full}
r258 = by_id[258]["rewards"]
assert len(r258) == 17, f"dungeon 258 expected 17 reward brackets, got {len(r258)}"
levels = [r.get("MaxLevel", 0) for r in r258]
assert levels == sorted(levels), "dungeon 258 rewards not sorted ascending by MaxLevel"

# slug rule: lowercase name, non-alnum -> '-', collapsed, max 40 chars, id-prefixed
for d in idx_dungeons:
    assert d["file"].startswith(f"{d['id']}-") and d["file"].endswith(".json")
    slug = d["file"][len(f"{d['id']}-"):-len(".json")]
    assert slug == slug.lower() and len(slug) <= 40
    assert all(c.isalnum() or c == "-" for c in slug)
print("ALL PASS")
