"""TDD gate for task V3-1: Manastorm seasonal-modifier tables (Manastorm.dbc /
ManastormMessages.dbc / ManastormModifiers.dbc / ManastormPlayerGroupModifiers.dbc,
patch-M) -> data/manastorm/.

Amendment D (single-writer ownership): build_manastorm is the sole writer under
data/manastorm/ - nothing else in this repo touches that directory.

Per the empirical-mapping rule, mapping evidence (join-rates, goldens, disproven
hypotheses) is documented in tools/dbc.py's TABLE_MAPS comments and
.superpowers/sdd/task-v3-1-report.md; this test pins the record-count snapshot
(verified headers, 2026-08-01 probe, patch-M: Manastorm 1017x9, ManastormMessages
291x39, ManastormModifiers 32768x15, ManastormPlayerGroupModifiers 15x5) and the
proven goldens: Manastorm's mapId/difficulty/dungeonEncounterId chain (Shadowfang
Keep's 7 real bosses), and ManastormMessages' seasonal-flavor text (contains the
literal word "Manastorm")."""
import json, sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from tools import config
from tools import build_manastorm

MAX_LINES = 5000

stats = build_manastorm.build()

mdir = config.DATA_DIR / "manastorm"

# ---- manastorm.json: 1017 rows, single file (brief: "one file <=5k lines OK") ----
man_doc = json.loads((mdir / "manastorm.json").read_text(encoding="utf-8"))
assert len(man_doc["manastorm"]) == 1017, len(man_doc["manastorm"])
n = sum(1 for _ in open(mdir / "manastorm.json", encoding="utf-8"))
assert n <= MAX_LINES, n

man_by_id = {r["id"]: r for r in man_doc["manastorm"]}
# golden: mapId 100% join, every value resolves a real dungeon/raid zone name
assert all(r["mapName"] for r in man_doc["manastorm"])
# golden: Shadowfang Keep (mapId 33) resolves its own real boss roster via the
# two-hop dungeonEncounterId -> DungeonEncounter.mapID chain
sfk_bosses = {r["dungeonEncounterName"] for r in man_doc["manastorm"] if r["mapId"] == 33}
assert {"Rethilgore", "Baron Silverlaine", "Commander Springvale", "Odo the Blindwatcher",
        "Fenrus the Devourer", "Wolf Master Nandos", "Archmage Arugal"} <= sfk_bosses
# golden: difficulty domain is exactly {0, 2}, matching DungeonEncounter's own values
assert {r["difficulty"] for r in man_doc["manastorm"]} == {0, 2}
for r in man_doc["manastorm"]:
    assert set(r) == {"id", "mapId", "mapName", "difficulty", "dungeonEncounterId",
                       "dungeonEncounterName", "raw"}
    assert len(r["raw"]) == 5

assert stats["manastorm"]["dungeonEncounterJoinRate"] >= 0.95, stats["manastorm"]

# ---- messages.json: 291 rows ----
msg_doc = json.loads((mdir / "messages.json").read_text(encoding="utf-8"))
assert len(msg_doc["messages"]) == 291, len(msg_doc["messages"])
n = sum(1 for _ in open(mdir / "messages.json", encoding="utf-8"))
assert n <= MAX_LINES, n

msg_by_id = {r["id"]: r for r in msg_doc["messages"]}
# golden: seasonal-flavor message text, pinned + literally mentions "Manastorm"
golden_msg = msg_by_id[1]
assert golden_msg["title"] == "Unlocked Iskarr Village!"
assert golden_msg["text"] == "You have unlocked Iskarr Village in your next Manastorm!"
assert "Manastorm" in golden_msg["text"]
assert golden_msg["iconToken"] == "inv_misc_stormdragonpale"
for r in msg_doc["messages"]:
    assert set(r) == {"id", "iconToken", "title", "text", "raw"}
    assert len(r["raw"]) == 3

# ---- playerGroupModifiers.json: 15 rows ----
pgm_doc = json.loads((mdir / "playerGroupModifiers.json").read_text(encoding="utf-8"))
assert len(pgm_doc["playerGroupModifiers"]) == 15, len(pgm_doc["playerGroupModifiers"])
n = sum(1 for _ in open(mdir / "playerGroupModifiers.json", encoding="utf-8"))
assert n <= MAX_LINES, n
for r in pgm_doc["playerGroupModifiers"]:
    assert set(r) == {"id", "raw"}
    assert len(r["raw"]) == 4

# ---- modifiers: bucketed data/manastorm/modifiers-<id//5000*5000>.jsonl + index.json ----
midx = json.loads((mdir / "index.json").read_text(encoding="utf-8"))
assert midx["bucketSize"] == 5000
on_disk = {p.name for p in mdir.glob("modifiers-*.jsonl")}
assert on_disk == {b["file"].split("/")[-1] for b in midx["buckets"]}, on_disk

total = 0
by_id = {}
for b in midx["buckets"]:
    p = mdir / b["file"]
    lines = p.read_text(encoding="utf-8").splitlines()
    assert len(lines) <= MAX_LINES
    assert len(lines) == b["count"]
    assert b["bucket"] == b["minId"] // midx["bucketSize"] * midx["bucketSize"]
    prev = -1
    for line in lines:
        r = json.loads(line)
        assert r["id"] > prev, "not sorted/unique within bucket"
        assert b["bucket"] <= r["id"] < b["bucket"] + midx["bucketSize"]
        assert set(r) == {"id", "raw"}
        assert len(r["raw"]) == 14
        prev = r["id"]
        by_id[r["id"]] = r
        total += 1
assert total == midx["count"] == 32768, midx["count"]
assert len(midx["buckets"]) == 7, len(midx["buckets"])  # 32768 rows / 5000 bucket size

meta = json.loads((mdir / "_meta.json").read_text(encoding="utf-8"))
assert meta["counts"] == {
    "manastorm": 1017, "messages": 291, "modifiers": 32768, "playerGroupModifiers": 15,
}
assert "provenColumns" in meta
assert "spellIdFinding" in meta and "spellId" in meta["spellIdFinding"]
assert "areaIdFinding" in meta and "areaId" in meta["areaIdFinding"]

print("ALL PASS")
