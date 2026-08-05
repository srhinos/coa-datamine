"""TDD gate for tasks V2-2 + V3-0: creatures/quests/trainers + dungeon encounter
enrichment.

Per the empirical-mapping rule, this test also encodes the NEGATIVE findings from the
golden-record probes documented in .superpowers/sdd/task-v2-2-report.md: Creature
subname and Quest sort/info links were probed and DISPROVEN (naive join-rate passed but
semantic golden verification failed, or no column cleared the join-rate bar at all) - so
those fields are asserted to be uniformly null/absent, not "resolved for at least one
record".

Task V3-0 (.superpowers/sdd/task-v3-0-report.md) found Creature.dbc's f0 is a POSITIONAL
row index (shifts on every patch that inserts rows upstream), not a stable entry id - f1
is the real, stable creature template entry id. Creatures are now keyed by f1 (goldens
re-pinned to canonical WotLK entry ids: Hogger 448, Edwin VanCleef 639, Onyxia 10184,
Ragnaros 11502 - stronger than the old name-only goldens). Retesting the
DungeonEncounterExtra creature-link hypothesis against f1 (instead of V2-2's dense f0
space) REVERSES the V2-2 disproof: the link is now proven (98.57% row-level join-rate,
every famous-boss golden resolves correctly), so dungeon encounters now carry a real
"creature": {id, name} link."""
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
assert cidx["count"] == 127178, cidx["count"]

# id//5000 bucket count grows a lot once keyed by f1's sparse (1..11001007) space vs the
# old fully-dense f0 (1..127178) space - a coarse regression guard on the V3-0 remap
assert len(cidx["buckets"]) >= 300, (
    "expected many more (sparse-id) buckets once creatures are keyed by f1, not f0",
    len(cidx["buckets"]))

# golden creature records - real WotLK 3.3.5 entry ids (f1), pinned + verified via live
# probe (task-v3-0-report.md); f0 (the old key) resolves these same numbers to unrelated
# NPCs (e.g. 448 -> "Demisette Cloyce"), proving the remap actually took effect
assert by_id[448]["name"] == "Hogger"
assert by_id[639]["name"] == "Edwin VanCleef"
assert by_id[10184]["name"] == "Onyxia"
assert by_id[11502]["name"] == "Ragnaros"

# subname: probed and disproven (see report) - documented as always-null, not attempted
assert all(r["subname"] is None for r in by_id.values())

cmeta = json.loads((cdir / "_meta.json").read_text(encoding="utf-8"))
assert cmeta["count"] == cidx["count"]
assert "subnameFinding" in cmeta
assert "idCorrectionFinding" in cmeta, "V3-0 f0->f1 remap must be documented in _meta.json"

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
assert total_t == tidx["count"] == stats["trainers"]["written"] == 13111

# gate: trainer spell join-rate >= 90%
join_rate = joined / total_t
assert join_rate >= 0.90, join_rate

tmeta = json.loads((tdir / "_meta.json").read_text(encoding="utf-8"))
assert tmeta["count"] == tidx["count"]
assert tmeta["spellJoinRate"] >= 0.90
assert "trainerIdFinding" in tmeta

# ---- dungeon encounter creature-link enrichment (V3-0: retested + PROVEN vs f1) ----
dstats = build_dungeons.build()
assert "encounterCreatureLinks" in dstats
link_rate = dstats["encounterCreatureLinks"] / dstats["encounters"]
assert link_rate >= 0.90, (
    "DungeonEncounterExtra creature link re-tested against Creature.dbc's real f1 "
    "entry-id space (V3-0, see task-v3-0-report.md) and proven - link rate must stay "
    f">=90%, got {link_rate:.4f}")

ddir = config.DATA_DIR / "dungeons"
didx = json.loads((ddir / "index.json").read_text(encoding="utf-8"))
found_ragnaros = False
# dedupe by encounter id - the same DungeonEncounter row can legitimately appear in
# multiple dungeon files when >1 LFGDungeons entry shares the same (mapID, difficulty)
# (pre-existing behavior, unrelated to this task), so a raw per-file sum overcounts
creature_by_encounter_id = {}
for d in didx["dungeons"]:
    doc = json.loads((ddir / d["file"]).read_text(encoding="utf-8"))
    for enc in doc["encounters"]:
        assert "creature" in enc
        if enc["creature"] is not None:
            assert set(enc["creature"]) == {"id", "name"}
        creature_by_encounter_id[enc["id"]] = enc["creature"]
        if enc["name"] == "Ragnaros":
            # golden: Ragnaros's own encounter row must carry the real Ragnaros entry id
            assert enc["creature"] == {"id": 11502, "name": "Ragnaros"}, enc["creature"]
            found_ragnaros = True
assert found_ragnaros, "Ragnaros encounter golden not found in any dungeon file"
# not every DungeonEncounter row's (mapID, difficulty) matches an LFGDungeons entry
# (pre-existing, unrelated to this task - some encounters never appear in any dungeon
# file at all), so this is a subset of dstats["encounterCreatureLinks"], not an exact
# match; still gate its own link rate independently as a second view on the same proof
seen_total = len(creature_by_encounter_id)
seen_creature_links = sum(1 for c in creature_by_encounter_id.values() if c is not None)
assert seen_creature_links <= dstats["encounterCreatureLinks"]
assert seen_creature_links / seen_total >= 0.90, seen_creature_links / seen_total

print("ALL PASS")
