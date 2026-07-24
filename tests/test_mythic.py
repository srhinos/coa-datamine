"""TDD gate for task V2-5: Mythic+/Challenges pack (Challenge.dbc hub + Challenge*
link/type tables -> data/mythic/challenges/; MythicKeystones/MythicAffixes/
MythicPlusScaling/TimedDungeons/MapDifficulty -> data/mythic/*).

Amendment D (single-writer ownership): build_mythic is the sole writer under
data/mythic/ - nothing else in this repo touches that directory.

Per the empirical-mapping rule, this also pins the NEGATIVE findings documented in
.superpowers/sdd/task-v2-5-report.md and tools/dbc.py's TABLE_MAPS comments:
ChallengeConditions has no provable conditionTypeId link (its own string block is too
small to carry a per-row token the way Rules/Requirements do) - conditions ship with no
resolved type name. ChallengeSpells.f4 (populated on every row but only ~19% joins
Spell.dbc) is NOT used - f5 (sparse but 100% on its populated subset) is."""
import json, sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from tools import config
from tools import build_mythic

MAX_LINES = 5000

stats = build_mythic.build()

mdir = config.DATA_DIR / "mythic"
cdir = mdir / "challenges"

# ---- challenges: sharded data/mythic/challenges/<id>-<slug>.json + index.json ----
cidx = json.loads((cdir / "index.json").read_text(encoding="utf-8"))
assert len(cidx["challenges"]) == 297, len(cidx["challenges"])
on_disk = {p.name for p in cdir.glob("*.json")
           if p.name not in ("index.json", "_lookups.json", "_meta.json")}
listed = {c["file"] for c in cidx["challenges"]}
assert on_disk == listed, on_disk ^ listed

by_id = {}
for entry in cidx["challenges"]:
    p = cdir / entry["file"]
    n = sum(1 for _ in open(p, encoding="utf-8"))
    assert n <= MAX_LINES, (entry["file"], n)
    doc = json.loads(p.read_text(encoding="utf-8"))
    assert doc["id"] == entry["id"]
    by_id[doc["id"]] = doc
assert len(by_id) == 297

for name in ("index.json", "_lookups.json", "_meta.json"):
    n = sum(1 for _ in open(cdir / name, encoding="utf-8"))
    assert n <= MAX_LINES, (name, n)

# ---- golden 1: Challenge 5 "Partner Up!" (name/description string columns proven) ----
assert by_id[5]["name"] == "Partner Up!"
assert "party of two" in by_id[5]["description"]

# ---- golden 2: Challenge 7 "Nudist" - name/description cross-validated against
# ChallengeRuleTypes (via ChallengeRules' proven ruleTypeToken string-match link) ----
nudist = by_id[7]
assert nudist["name"] == "Nudist"
assert nudist["description"] == (
    "The breeze feels good, eh? You are unable to equip or wear armor of any kind.")
assert len(nudist["rules"]) == 1
rule = nudist["rules"][0]
assert rule["ruleTypeToken"] == "CHALLENGE_RULES_TYPE_NO_EQUIP_ARMOR"
assert rule["name"] == "No Equipping Armor"
assert rule["description"] == "You may not equip any armor."

# ---- lookups: ruleTypes/modifierTypes/conditionTypes/requirementTypes ----
lookups = json.loads((cdir / "_lookups.json").read_text(encoding="utf-8"))
assert len(lookups["ruleTypes"]) == 127
assert len(lookups["modifierTypes"]) == 8
assert len(lookups["conditionTypes"]) == 18
assert len(lookups["requirementTypes"]) == 22
rt_by_id = {r["id"]: r for r in lookups["ruleTypes"]}
assert rt_by_id[5]["token"] == "CHALLENGE_RULES_TYPE_NO_EQUIP_ARMOR"
assert rt_by_id[5]["name_enUS"] == "No Equipping Armor"

# ---- gate: >=80% of link-table challenge-id values resolve to Challenge rows ----
meta = json.loads((cdir / "_meta.json").read_text(encoding="utf-8"))
link_tables = meta["linkTables"]
for name in ("groups", "levels", "rules", "modifiers", "conditions", "requirements",
             "rewards", "featured", "spells"):
    assert link_tables[name]["challengeJoinRate"] >= 0.80, (name, link_tables[name])
assert link_tables["groupRewards"]["challengeJoinRateViaGroup"] >= 0.80

# spells: challenge 25 "Fleeting" carries resolved spellId 207 (proven f5, sparse subset)
fleeting = by_id[25]
assert fleeting["name"] == "Fleeting"
spell_ids = {s["spellId"] for s in fleeting["spells"]}
assert 207 in spell_ids
tier1 = next(s for s in fleeting["spells"] if s["spellId"] == 207)
assert tier1["name"] is not None and "Fleeting" in tier1["name"]

# featured flag: at least one challenge is featured, at least one is not
assert any(c["featured"] for c in by_id.values())
assert any(not c["featured"] for c in by_id.values())

# every named field present and every array field present as a list on every challenge
for c in by_id.values():
    for key in ("id", "name", "description", "iconToken", "difficultyToken", "modeToken",
                "featured"):
        assert key in c
    for key in ("groups", "levels", "rules", "modifiers", "conditions", "requirements",
                "rewards", "spells"):
        assert isinstance(c[key], list)

# ---- keystones: per-dungeon files + index.json ----
kdir = mdir / "keystones"
kidx = json.loads((kdir / "index.json").read_text(encoding="utf-8"))
assert len(kidx["dungeons"]) == stats["keystones"]["dungeons"]
on_disk = {p.name for p in kdir.glob("*.json") if p.name not in ("index.json", "_unresolved.json")}
assert on_disk == {d["file"] for d in kidx["dungeons"]}

# golden: dungeonId 53 = Lower Scholomance, 100 keystone levels 1..100
scholo = next(d for d in kidx["dungeons"] if d["dungeonId"] == 53)
scholo_doc = json.loads((kdir / scholo["file"]).read_text(encoding="utf-8"))
assert scholo_doc["dungeonName"] == "Lower Scholomance"
assert [lv["level"] for lv in scholo_doc["levels"]] == list(range(1, 101))

assert stats["keystones"]["dungeonJoinRate"] >= 0.90, stats["keystones"]["dungeonJoinRate"]

# ---- affixes: id-bucketed jsonl + index.json ----
adir = mdir / "affixes"
aidx = json.loads((adir / "index.json").read_text(encoding="utf-8"))
assert aidx["bucketSize"] == 5000
on_disk = {p.name for p in adir.glob("*.jsonl")}
assert on_disk == {b["file"] for b in aidx["buckets"]}
total_a = 0
affix_by_id = {}
for b in aidx["buckets"]:
    p = adir / b["file"]
    lines = p.read_text(encoding="utf-8").splitlines()
    assert len(lines) <= MAX_LINES
    assert len(lines) == b["count"]
    for line in lines:
        r = json.loads(line)
        affix_by_id[r["id"]] = r
        total_a += 1
assert total_a == aidx["count"] == 13409

# golden: affix id 6 grants "Pack Tactics" (spell 80054) and effect spell 80044 "Avenger"
affix6 = affix_by_id[6]
assert affix6["grantSpellId"] == 80054
assert affix6["grantSpellName"] == "Pack Tactics"
effect_ids = {e["id"]: e["name"] for e in affix6["effectSpells"]}
assert effect_ids.get(80044) == "Avenger"

# ---- scaling / timedDungeons / mapDifficulty: small single files ----
for fname in ("scaling.json", "timedDungeons.json", "mapDifficulty.json"):
    p = mdir / fname
    n = sum(1 for _ in open(p, encoding="utf-8"))
    assert n <= MAX_LINES, (fname, n)

scaling_doc = json.loads((mdir / "scaling.json").read_text(encoding="utf-8"))
assert len(scaling_doc["scaling"]) == 200

td_doc = json.loads((mdir / "timedDungeons.json").read_text(encoding="utf-8"))
td_by_id = {r["dungeonId"]: r for r in td_doc["timedDungeons"]}
assert len(td_by_id) == 82
# golden: dungeonId 53 Lower Scholomance, timeLimitMs 1896000
assert td_by_id[53]["dungeonName"] == "Lower Scholomance"
assert td_by_id[53]["timeLimitMs"] == 1896000
# documented dev/test placeholder rows (ids 2001-2028) resolve to no dungeon name
assert td_by_id[2001]["dungeonName"] is None
assert stats["timedDungeons"]["dungeonJoinRate"] >= 0.80  # brief's gate, raw incl. test rows

md_doc = json.loads((mdir / "mapDifficulty.json").read_text(encoding="utf-8"))
assert len(md_doc["mapDifficulty"]) == 685

# ---- stats sanity ----
assert stats["challenges"]["count"] == 297
assert stats["keystones"]["count"] == 6801
assert stats["affixes"]["count"] == 13409

print("ALL PASS")
