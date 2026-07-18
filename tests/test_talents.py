import json, sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from tools import config
from tools import build_talents

stats = build_talents.build()
tdir = config.DATA_DIR / "talents"
meta = json.loads((tdir / "_meta.json").read_text(encoding="utf-8"))
assert stats["tabs"] == 37 and stats["talents"] == 2383
assert stats["unresolvedRankSpells"] / max(1, stats["talents"]) <= 0.05

files = sorted(p.name for p in tdir.glob("*.json") if not p.name.startswith("_"))
assert len(files) >= 10, files                    # at least the classes with talent tabs

one = json.loads((tdir / files[0]).read_text(encoding="utf-8"))
assert one["tabs"] and one["tabs"][0]["talents"]
t = one["tabs"][0]["talents"][0]
assert "row" in t and "col" in t and t["ranks"] and "name" in t["ranks"][0]
covered = {f.removesuffix(".json") for f in files}
assert meta["classTabCounts"] and sum(meta["classTabCounts"].values()) <= 37
print("ALL PASS")
