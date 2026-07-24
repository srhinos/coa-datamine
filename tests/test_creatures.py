"""TDD gate for task V2-2: creatures/quests/trainers + dungeon encounter enrichment.

Per the empirical-mapping rule, this test also encodes the NEGATIVE findings from the
golden-record probes documented in .superpowers/sdd/task-v2-2-report.md: Creature
subname, Quest sort/info links and the DungeonEncounterExtra creature link were all
probed and DISPROVEN (naive join-rate passed but semantic golden verification failed,
or no column cleared the join-rate bar at all) - so those fields are asserted to be
uniformly null/absent, not "resolved for at least one record"."""
import json, sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from tools import config
from tools import build_creatures, build_dungeons

MAX_LINES = 5000

stats = build_creatures.build()

# ---- creatures: sharded data/creatures/creatures-<id//5000*5000>.jsonl + index.json ----
cdir = config.DATA_DIR / "creatures"
cidx = json.loads((cdir / "index.json").read_text(encoding="utf-8"))
assert cidx["bucketSize"] == 5000
on_disk = {p.name for p in cdir.glob("*.jsonl")}
assert on_disk == {b["file"].split("/")[-1] for b in cidx["buckets"]}, on_disk

total = 0
by_id = {}
for b in cidx["buckets"]:
    p = cdir / b["file"]
    lines = (p.read_text(encoding="utf-8")).splitlines()
    assert len(lines) <= MAX_LINES
    assert len(lines) == b["count"]
    assert b["bucket"] == b["minId"] // cidx["bucketSize"] * cidx["bucketSize"]
    prev = -1
    for line in lines:
        r = json.loads(line)
        assert r["id"] > prev, "not sorted/unique within bucket"
        assert b["bucket"] <= r["id"] < b["bucket"] + cidx["bucketSize"]
        prev = r["id"]
        by_id[r["id"]] = r
        total += 1
assert total == cidx["count"] == stats["creatures"]["written"]

# creatures.jsonl line count == Creature record count (brief's gate, now summed over shards)
assert cidx["count"] == 127175, cidx["count"]

# golden creature records (verified via live probe - see report)
assert by_id[437]["name"] == "Hogger"
ragnaros_ids = [8034, 8035, 31622, 32197, 32311, 41034, 107744, 109319, 111385, 113661, 114415]
assert any(by_id[i]["name"] == "Ragnaros" for i in ragnaros_ids if i in by_id)

# subname: probed and disproven (see report) - documented as always-null, not attempted
assert all(r["subname"] is None for r in by_id.values())

cmeta = json.loads((cdir / "_meta.json").read_text(encoding="utf-8"))
assert cmeta["count"] == cidx["count"]
assert "subnameFinding" in cmeta

# ---- quests: sharded data/quests/quests-<id//5000*5000>.jsonl + index.json ----
qdir = config.DATA_DIR / "quests"
qidx = json.loads((qdir / "index.json").read_text(encoding="utf-8"))
assert qidx["bucketSize"] == 5000
on_disk = {p.name for p in qdir.glob("*.jsonl")}
assert on_disk == {b["file"].split("/")[-1] for b in qidx["buckets"]}

total_q = 0
f_keys = {f"f{i}" for i in range(1, 29)}
for b in qidx["buckets"]:
    p = qdir / b["file"]
    lines = (p.read_text(encoding="utf-8")).splitlines()
    assert len(lines) <= MAX_LINES
    assert len(lines) == b["count"]
    prev = -1
    for line in lines:
        r = json.loads(line)
        assert r["id"] > prev
        prev = r["id"]
        # "every quests.jsonl sort/info id resolves or is null" - probed and disproven,
        # so always null here (documented, not a bug)
        assert r["sort"] is None and r["info"] is None
        assert f_keys <= set(r), sorted(f_keys - set(r))
        total_q += 1
assert total_q == qidx["count"] == stats["quests"]["written"] == 18561

qmeta = json.loads((qdir / "_meta.json").read_text(encoding="utf-8"))
assert qmeta["count"] == qidx["count"]
assert "sortInfoFinding" in qmeta

# ---- trainers: sharded data/trainers/trainers-<id//2000*2000>.json + index.json ----
tdir = config.DATA_DIR / "trainers"
tidx = json.loads((tdir / "index.json").read_text(encoding="utf-8"))
assert tidx["bucketSize"] == 2000
on_disk = {p.name for p in tdir.glob("*.json") if p.name != "index.json" and p.name != "_meta.json"}
assert on_disk == {b["file"].split("/")[-1] for b in tidx["buckets"]}

total_t = joined = 0
for b in tidx["buckets"]:
    p = tdir / b["file"]
    n = sum(1 for _ in open(p, encoding="utf-8"))
    assert n <= MAX_LINES
    doc = json.loads(p.read_text(encoding="utf-8"))
    assert doc["count"] == len(doc["entries"]) == b["count"]
    for e in doc["entries"]:
        assert set(e) >= {"id", "spellId", "name", "skillLine", "f3"}
        if e["name"] is not None:
            joined += 1
        total_t += 1
assert total_t == tidx["count"] == stats["trainers"]["written"] == 13001

# gate: trainer spell join-rate >= 90%
join_rate = joined / total_t
assert join_rate >= 0.90, join_rate

tmeta = json.loads((tdir / "_meta.json").read_text(encoding="utf-8"))
assert tmeta["count"] == tidx["count"]
assert tmeta["spellJoinRate"] >= 0.90
assert "trainerIdFinding" in tmeta

# ---- dungeon encounter creature-link enrichment ----
dstats = build_dungeons.build()
assert "encounterCreatureLinks" in dstats
assert dstats["encounterCreatureLinks"] == 0, (
    "DungeonEncounterExtra creature link was probed and disproven (see report) - "
    "should be documented zero, not a silently-wrong nonzero link")

ddir = config.DATA_DIR / "dungeons"
didx = json.loads((ddir / "index.json").read_text(encoding="utf-8"))
checked = 0
for d in didx["dungeons"][:20]:
    doc = json.loads((ddir / d["file"]).read_text(encoding="utf-8"))
    for enc in doc["encounters"]:
        assert enc["creature"] is None
        checked += 1
assert checked > 0

print("ALL PASS")
