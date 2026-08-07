import json, sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from tools import config
from tools import build_spells

stats = build_spells.build()
sdir = config.DATA_DIR / "spells"
meta = json.loads((sdir / "_meta.json").read_text(encoding="utf-8"))
assert stats["written"] == meta["count"] > 15000, stats["written"]

co_ratio = len(stats["missing_by_source"]["cad_other"]) / max(1, stats["ref_counts"]["cad_other"])
assert co_ratio <= 0.05, f"cad_other missing ratio {co_ratio:.3f} > 0.05"
tal_ratio = len(stats["missing_by_source"]["talent"]) / max(1, stats["ref_counts"]["talent"])
assert tal_ratio <= 0.05, f"talent missing ratio {tal_ratio:.3f} > 0.05"
assert stats["ref_counts"]["cad_reborn"] > 0

# Amendment C: spells.jsonl is bucketed data/spells/by-id/spells-<id//10000*10000>.jsonl,
# manifested by data/spells/index.json (bucket -> file, count, id range).
index = json.loads((sdir / "index.json").read_text(encoding="utf-8"))
assert index["count"] == meta["count"]
assert index["bucketSize"] == 10000
assert [b["bucket"] for b in index["buckets"]] == sorted(b["bucket"] for b in index["buckets"])

by_id, count = {}, 0
for b in index["buckets"]:
    assert b["bucket"] == b["minId"] // index["bucketSize"] * index["bucketSize"]
    prev, bcount = -1, 0
    with open(sdir / b["file"], encoding="utf-8") as fh:
        for line in fh:
            r = json.loads(line)
            assert r["id"] > prev, "not sorted within bucket"           # ascending, unique
            assert b["bucket"] <= r["id"] < b["bucket"] + index["bucketSize"], "id out of bucket"
            prev = r["id"]
            count += 1
            bcount += 1
            if r["id"] in (10, 17) or r["id"] >= 100000 and len(by_id) < 10:
                by_id[r["id"]] = r
    assert bcount == b["count"]
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

# Amendment C: _meta.json keeps counts only; full missing-ref id lists live in
# _missing_refs.json (one line per source array).
assert "missing_refs_by_source" not in meta
missing = json.loads((sdir / "_missing_refs.json").read_text(encoding="utf-8"))
assert missing == stats["missing_by_source"]
for k, v in meta["missing_ref_counts_by_source"].items():
    assert v == len(stats["missing_by_source"][k])

# Single-writer survival gate. build() rmtree's data/spells/ because its shard set
# changes between runs, which silently destroyed analysis/coverage_live.py's
# _coverage_live.json on every rebuild until it was noticed missing. build() now
# carries build_spells.FOREIGN_FILES across that delete; this asserts it, and the
# `stats` call at the top of this file IS the rebuild that would have deleted them.
for _name in build_spells.FOREIGN_FILES:
    assert (sdir / _name).is_file(), (
        f"{_name} did not survive build_spells.build() - a module that does not "
        f"own data/spells/ had its output destroyed by the rmtree. See "
        f"build_spells.FOREIGN_FILES.")
assert build_spells.FOREIGN_FILES, "the survival gate must gate something"
print(f"foreign-file survival: {len(build_spells.FOREIGN_FILES)} file(s) intact")
print("ALL PASS")
