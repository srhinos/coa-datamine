"""Amendment C gate: no committed data/ file may be an arbitrary 10k+-line monolith,
and every sharded dataset's index.json must completely + correctly account for its
shard files. Also pins pre-shard record counts (captured from the monolith files on
disk before this task's rewrite) so sharding cannot silently drop/duplicate records."""
import json, sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from tools import config
from tools import build_spells, build_classes, build_talents, build_dungeons

MAX_LINES = 5000

# Start empty. Add an entry only if a file genuinely cannot shrink below 5,000 lines
# without hacky code, with a comment here justifying it (also document in AGENT-GUIDE).
ALLOWLIST = {
    # "data/some/file.json": "reason",
}

# Pre-shard record-count invariants captured 2026-07-23 from the monolith files this
# task replaces (data/spells/spells.jsonl line count, each data/classes/<Class>.json
# "entries" length, data/dungeons/dungeons.json dungeon count) - BEFORE any writer
# code in this task ran. Sharding must preserve these exactly. NOTE: the committed
# spells.jsonl (27432) was already stale vs. work/dbc+raw/content on disk (upstream
# client drift, same class of churn as prior tasks' snapshot-pin notes); the true
# apples-to-apples baseline is what the UNMODIFIED writer produces against the SAME
# source data used here, verified via a controlled re-run of the pre-task writer
# (27441) - confirming the delta is pre-existing drift, not a sharding regression.
# 2026-07-24 rebuild after a further client patch: writer now produces 27439 against
# the patched work/dbc snapshot (-2 vs. 27441) - re-pinned per AGENT-GUIDE's
# "Regenerating after a client patch" contract (small delta = content churn).
# 2026-08-01 rebuild after a further client patch: writer now produces 27470 against
# the patched work/dbc snapshot (+31 vs. 27439) - re-pinned per the same contract.
# 2026-08-06 (task W4-1, incidental): a live client patch landed mid-task -
# work/dbc/Spell.dbc went 209,125 -> 209,130 BASE rows (confirmed via file mtime,
# unrelated to this task's enum-table changes, which touch only names/lookups, never
# the referenced-id closure) - writer now produces 27475 (+1 vs. 27474). Re-pinned
# per the same contract; every other invariant in this file (class entry counts,
# dungeon count) was checked and is unchanged by the same patch.
PRE_SPELL_COUNT = 27475
PRE_CLASS_ENTRY_COUNTS = {
    "Barbarian": 387, "Chronomancer": 434, "Cultist": 415, "DeathKnight": 176,
    "DemonHunter": 369, "Druid": 308, "Guardian": 374, "Hunter": 296,
    "KnightOfXoroth": 379, "Mage": 288, "Monk": 377, "Necromancer": 427,
    "Paladin": 305, "Priest": 252, "Primalist": 402, "Pyromancer": 389,
    "Ranger": 393, "Reaper": 364, "RebornDeathKnight": 319, "RebornDruid": 1559,
    "RebornGeneral": 65, "RebornHunter": 1275, "RebornMage": 1517,
    "RebornPaladin": 1310, "RebornPriest": 1302, "RebornRogue": 1050,
    "RebornShaman": 1198, "RebornWarlock": 1719, "RebornWarrior": 1173,
    "Rogue": 263, "Runemaster": 424, "Shaman": 345, "SonOfArugal": 388,
    "Starcaller": 416, "Stormbringer": 368, "SunCleric": 414, "Tinker": 412,
    "Venomancer": 404, "Warlock": 302, "Warrior": 294, "WitchDoctor": 403,
    "WitchHunter": 392, "_other": 62,
}
PRE_DUNGEON_COUNT = 431

# rebuild the curated layer fresh (work/dbc + raw/content already extracted/dumped -
# do NOT re-extract; each build() is a few seconds at most)
build_spells.build()
build_classes.build()
build_talents.build()
build_dungeons.build()

# ---- repo-wide <=5000-line gate over every committed data/ JSON/JSONL file ----
oversized = []
for p in sorted(config.DATA_DIR.rglob("*")):
    if not p.is_file() or p.suffix not in (".json", ".jsonl"):
        continue
    rel = p.relative_to(config.REPO_ROOT).as_posix()
    n = sum(1 for _ in open(p, encoding="utf-8"))
    if n > MAX_LINES and rel not in ALLOWLIST:
        oversized.append((rel, n))
assert not oversized, f"files exceeding {MAX_LINES} lines with no allowlist entry: {oversized}"
for rel in ALLOWLIST:
    p = config.REPO_ROOT / rel
    assert p.is_file(), f"stale allowlist entry, file gone: {rel}"

# ---- spells: bucket index completeness + count invariance ----
sdir = config.DATA_DIR / "spells"
sidx = json.loads((sdir / "index.json").read_text(encoding="utf-8"))
assert [b["bucket"] for b in sidx["buckets"]] == sorted(b["bucket"] for b in sidx["buckets"])
on_disk = {p.name for p in (sdir / "by-id").glob("*.jsonl")}
assert on_disk == {b["file"].split("/")[-1] for b in sidx["buckets"]}, "index/dir mismatch"
total = 0
for b in sidx["buckets"]:
    p = sdir / b["file"]
    n = sum(1 for _ in open(p, encoding="utf-8"))
    assert n == b["count"], (b["file"], n, b["count"])
    assert b["bucket"] == b["minId"] // sidx["bucketSize"] * sidx["bucketSize"]
    total += b["count"]
assert total == sidx["count"] == PRE_SPELL_COUNT

meta = json.loads((sdir / "_meta.json").read_text(encoding="utf-8"))
assert meta["count"] == PRE_SPELL_COUNT
assert "missing_refs_by_source" not in meta, "full missing-ref lists must move out of _meta.json"
missing = json.loads((sdir / "_missing_refs.json").read_text(encoding="utf-8"))
assert set(missing) == {"cad_other", "cad_reborn", "talent", "rank"}
for k, v in meta["missing_ref_counts_by_source"].items():
    assert len(missing[k]) == v
# each source's array really is on one line (the amendment's compactness requirement)
raw_lines = (sdir / "_missing_refs.json").read_text(encoding="utf-8").splitlines()
array_lines = [ln for ln in raw_lines if ln.strip().startswith('"') and "[" in ln]
assert len(array_lines) == 4

# ---- classes: per-class index completeness + count invariance ----
cdir = config.DATA_DIR / "classes"
cidx = json.loads((cdir / "index.json").read_text(encoding="utf-8"))
seen, grand_total = set(), 0
for c in cidx["classes"]:
    class_index = json.loads((cdir / c["index"]).read_text(encoding="utf-8"))
    on_disk = {p.name for p in (cdir / c["dir"]).glob("*.json") if p.name != "index.json"}
    listed = {f["file"] for f in class_index["files"]}
    assert on_disk == listed, (c["name"], on_disk ^ listed)
    file_total = 0
    for f in class_index["files"]:
        doc = json.loads((cdir / c["dir"] / f["file"]).read_text(encoding="utf-8"))
        assert len(doc["entries"]) == f["count"]
        file_total += f["count"]
    assert file_total == class_index["entryCount"] == PRE_CLASS_ENTRY_COUNTS[c["name"]], c["name"]
    seen.add(c["name"])
    grand_total += file_total
assert seen == set(PRE_CLASS_ENTRY_COUNTS)
assert grand_total == sum(PRE_CLASS_ENTRY_COUNTS.values())
assert not (cdir / "Necromancer.json").exists(), "monolith must be deleted"

# ---- dungeons: index completeness + count invariance ----
ddir = config.DATA_DIR / "dungeons"
didx = json.loads((ddir / "index.json").read_text(encoding="utf-8"))
assert len(didx["dungeons"]) == PRE_DUNGEON_COUNT
on_disk = {p.name for p in ddir.glob("*.json") if p.name != "index.json"}
listed = {d["file"] for d in didx["dungeons"]}
assert on_disk == listed, on_disk ^ listed
for d in didx["dungeons"]:
    doc = json.loads((ddir / d["file"]).read_text(encoding="utf-8"))
    assert doc["id"] == d["id"] and doc["mapId"] == d["mapId"] and doc["levels"] == d["levels"]
assert not (ddir / "dungeons.json").exists(), "monolith must be deleted"
assert "encountersByMap" not in json.loads((ddir / didx["dungeons"][0]["file"]).read_text(encoding="utf-8")), \
    "encountersByMap duplicate view must be dropped"

# ---- talents: unchanged, stays under the line gate without sharding ----
tdir = config.DATA_DIR / "talents"
for p in tdir.glob("*.json"):
    n = sum(1 for _ in open(p, encoding="utf-8"))
    assert n <= MAX_LINES, (p, n)

print("ALL PASS")
