import json, sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from tools import config
from tools import build_spells

stats = build_spells.build()
meta = json.loads((config.DATA_DIR / "spells" / "_meta.json").read_text(encoding="utf-8"))
assert stats["written"] == meta["count"] > 15000, stats["written"]

co_ratio = len(stats["missing_by_source"]["cad_other"]) / max(1, stats["ref_counts"]["cad_other"])
assert co_ratio <= 0.05, f"cad_other missing ratio {co_ratio:.3f} > 0.05"
tal_ratio = len(stats["missing_by_source"]["talent"]) / max(1, stats["ref_counts"]["talent"])
assert tal_ratio <= 0.05, f"talent missing ratio {tal_ratio:.3f} > 0.05"
assert stats["ref_counts"]["cad_reborn"] > 0

by_id, count = {}, 0
with open(config.DATA_DIR / "spells" / "spells.jsonl", encoding="utf-8") as fh:
    prev = -1
    for line in fh:
        r = json.loads(line)
        assert r["id"] > prev, "not sorted"          # ascending, unique
        prev = r["id"]
        count += 1
        if r["id"] in (10, 17) or r["id"] >= 100000 and len(by_id) < 10:
            by_id[r["id"]] = r
assert count == meta["count"]

pws = by_id[17]
assert pws["name"] == "Power Word: Shield"
assert pws["dispel"] == {"id": 1, "name": "Magic"}
assert pws["schools"] == ["Holy"]
assert any(e["aura"]["name"] == "SCHOOL_ABSORB" for e in pws["effects"]), pws["effects"]
assert pws["rankChain"] == {"first": 17, "rank": 1, "level": 10}
bliz = by_id[10]
assert bliz["name"] == "Blizzard" and bliz["schools"] == ["Frost"]
assert bliz["castTimeMs"] >= 0 and bliz["durationMs"]["base"] > 0
custom = [r for i, r in by_id.items() if i >= 100000]
assert custom and all(r["name"] for r in custom), "custom spells must have names"
print("ALL PASS")
