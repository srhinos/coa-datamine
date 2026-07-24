"""Creatures / quests / trainers datasets (task V2-2).

Amendment C sharding: creatures/quests are bucketed data/<name>/<name>-<id//5000*5000>.jsonl
(JSONL, one record per line) + index.json; trainers is bucketed
data/trainers/trainers-<id//2000*2000>.json (JSON, since there is no genuine trainer-NPC
grouping column to shard by identity - see below) + index.json. Each dataset also gets a
_meta.json carrying proven-column evidence and join-rate findings.

Empirical-mapping rule outcomes (full probe evidence in
.superpowers/sdd/task-v2-2-report.md, golden checks pinned in tools/dbc.py TABLE_MAPS
comments and tests/test_creatures.py):

- Creature: id (f0) and name (f2) proven by golden decode. subname was hypothesized on
  the two next-highest string_likelihood columns (f20/f21/f22 per V2-1 colinfo) but
  DISPROVEN: both goldens (Hogger, Ragnaros) carry 0 in all three, and table-wide the
  small non-zero fraction resolves to unrelated fragments/other creatures' names at a
  rate matching pure coincidence against Creature's huge shared string block. Shipped
  as subname: null, always, documented.
- Quest: id (f0) proven unique. No column clears the join-rate bar against QuestSort or
  QuestInfo ids (best real candidate ~58%, well under the required 80%/threshold).
  Shipped as sort: null, info: null, always, documented; all 28 other columns carried
  raw as f1..f28 per the brief's schema.
- NPCTrainer: id (f0), spellId (f1, 98.9% join vs Spell ids) and skillLine (f2, 99.9%
  join vs SkillLine ids + semantic name match) are proven. The brief hypothesized a
  "trainer-id low-cardinality grouping column" at f2 or f3; f2 instead proves out as
  skillLine (not trainer identity), and f3 has no provable semantics (weak/inconsistent
  join, values cluster like WotLK skill-rank breakpoints - multiples of 25 - not a
  trainer id). No trainer-NPC identity column exists in this table; the output is a
  flat per-record list (not grouped by trainerId), bucketed by NPCTrainer's own row id
  per Amendment C's literal `id//2000*2000` layout instruction.
"""
import json, shutil

from tools import config, dbc, sharding

CREATURE_BUCKET = 5000
QUEST_BUCKET = 5000
TRAINER_BUCKET = 2000


def build_creatures() -> dict:
    out_dir = config.DATA_DIR / "creatures"
    if out_dir.exists():
        shutil.rmtree(out_dir)
    out_dir.mkdir(parents=True)

    records = {}
    for r in dbc.iter_named("Creature"):
        records[r["id"]] = {"id": r["id"], "name": r["name_enUS"], "subname": None}

    # golden gate: refuse to publish if the pinned id->name facts don't hold
    assert records.get(437, {}).get("name") == "Hogger", \
        "golden creature 437 (Hogger) failed - column map is wrong, dataset aborted"
    ragnaros_ids = (8034, 8035, 31622, 32197, 32311, 41034,
                    107744, 109319, 111385, 113661, 114415)
    assert any(records.get(i, {}).get("name") == "Ragnaros" for i in ragnaros_ids), \
        "golden creature Ragnaros failed - column map is wrong, dataset aborted"

    bucketed = {}
    for rid in sorted(records):
        bucketed.setdefault(sharding.bucket_id(rid, CREATURE_BUCKET), []).append(records[rid])

    bucket_index = []
    for bkt in sorted(bucketed):
        recs = bucketed[bkt]
        fname = f"creatures-{bkt}.jsonl"
        with open(out_dir / fname, "w", encoding="utf-8", newline="\n") as fh:
            for rec in recs:
                fh.write(json.dumps(rec, ensure_ascii=False, sort_keys=True,
                                    separators=(",", ":")) + "\n")
        bucket_index.append({"bucket": bkt, "file": fname, "count": len(recs),
                              "minId": recs[0]["id"], "maxId": recs[-1]["id"]})

    index = {"bucketSize": CREATURE_BUCKET, "count": len(records), "buckets": bucket_index}
    (out_dir / "index.json").write_text(sharding.dump_manifest(index), encoding="utf-8")

    meta = {
        "count": len(records),
        "provenColumns": {
            "id": "Creature.dbc f0 - ascending unique 1..127175, golden-checked",
            "name": "Creature.dbc f2 - string_likelihood=1.0, pct_zero=0.0, golden "
                    "Hogger/Ragnaros verified",
        },
        "subnameFinding": (
            "Hypothesized on the two next-highest string_likelihood columns (f20/f21/"
            "f22 per V2-1 colinfo). DISPROVEN: both goldens (Hogger id=437/60041/92992, "
            "Ragnaros ids 8034 etc) carry raw value 0 in all three columns (no data), "
            "and table-wide only ~0.5-5% of rows have non-zero values that pass the "
            "strict string-offset test, resolving to unrelated fragments or other "
            "creatures' full names - not this row's own subname. A random-offset "
            "control against the same string block hits the strict test ~3.45% of the "
            "time, matching the observed rate - i.e. coincidence, not a real column. "
            "Shipped as subname: null for every record."
        ),
    }
    (out_dir / "_meta.json").write_text(
        json.dumps(meta, ensure_ascii=False, indent=1, sort_keys=True), encoding="utf-8")
    return {"written": len(records)}


def build_quests() -> dict:
    out_dir = config.DATA_DIR / "quests"
    if out_dir.exists():
        shutil.rmtree(out_dir)
    out_dir.mkdir(parents=True)

    f = dbc.DBCFile(config.WORK_DBC_DIR / "Quest.dbc")
    if f.fields != 29:
        raise dbc.LayoutError(f"Quest: field_count {f.fields} != expected 29")

    records = {}
    for row in f.iter_rows():
        rec = {"id": dbc.u32(row[0]), "sort": None, "info": None}
        for i in range(1, 29):
            rec[f"f{i}"] = dbc.u32(row[i])
        records[rec["id"]] = rec
    assert len(records) == f.records, "Quest id column is not unique - column map is wrong"

    bucketed = {}
    for rid in sorted(records):
        bucketed.setdefault(sharding.bucket_id(rid, QUEST_BUCKET), []).append(records[rid])

    bucket_index = []
    for bkt in sorted(bucketed):
        recs = bucketed[bkt]
        fname = f"quests-{bkt}.jsonl"
        with open(out_dir / fname, "w", encoding="utf-8", newline="\n") as fh:
            for rec in recs:
                fh.write(json.dumps(rec, ensure_ascii=False, sort_keys=True,
                                    separators=(",", ":")) + "\n")
        bucket_index.append({"bucket": bkt, "file": fname, "count": len(recs),
                              "minId": recs[0]["id"], "maxId": recs[-1]["id"]})

    index = {"bucketSize": QUEST_BUCKET, "count": len(records), "buckets": bucket_index}
    (out_dir / "index.json").write_text(sharding.dump_manifest(index), encoding="utf-8")

    meta = {
        "count": len(records),
        "provenColumns": {
            "id": "Quest.dbc f0 - unique across all 18561 records (no string block: "
                  "string_block_size=0, all 29 fields are numeric)",
        },
        "sortInfoFinding": (
            "Probed every one of the 28 remaining columns' join-rate against both "
            "QuestSort.dbc ids (144 records, needs >=80% per the brief) and "
            "QuestInfo.dbc ids (11 records). None clears the bar: the best real "
            "candidate (f20) tops out at 58.6%/58.2%, and the only column that "
            "nominally cleared 80%+ (f25, 88.9%) does so on only 9 non-zero rows out "
            "of 18561 - statistically meaningless. f1 (the highest-join candidate "
            "besides f20) is a bitmask/flags column (values are powers of 2, several "
            "<=600 which coincidentally fall inside QuestSort's dense low id range - "
            "not a real link). Shipped as sort: null, info: null for every record; all "
            "28 non-id columns carried raw as f1..f28."
        ),
    }
    (out_dir / "_meta.json").write_text(
        json.dumps(meta, ensure_ascii=False, indent=1, sort_keys=True), encoding="utf-8")
    return {"written": len(records)}


def build_trainers() -> dict:
    out_dir = config.DATA_DIR / "trainers"
    if out_dir.exists():
        shutil.rmtree(out_dir)
    out_dir.mkdir(parents=True)

    spell_names = {r["id"]: r["name_enUS"] for r in dbc.iter_named("Spell")}
    skill_names = {r["id"]: r["name_enUS"] for r in dbc.iter_named("SkillLine")}

    f = dbc.DBCFile(config.WORK_DBC_DIR / "NPCTrainer.dbc")
    if f.fields != 4:
        raise dbc.LayoutError(f"NPCTrainer: field_count {f.fields} != expected 4")

    records = {}
    joined = 0
    # iter_named doesn't expose f3 (unmapped) - read raw rows directly, decoding the
    # mapped columns the same way _decode would, so we get both proven fields and f3.
    for row in f.iter_rows():
        rid, spell_id, skill_line = dbc.u32(row[0]), row[1], dbc.u32(row[2])
        name = spell_names.get(spell_id)
        if name is not None:
            joined += 1
        records[rid] = {
            "id": rid, "spellId": spell_id, "name": name,
            "skillLine": ({"id": skill_line, "name": skill_names.get(skill_line, "")}
                          if skill_line else None),
            "f3": dbc.u32(row[3]),
        }
    assert len(records) == f.records, "NPCTrainer id column is not unique"

    join_rate = joined / max(1, len(records))
    assert join_rate >= 0.90, f"NPCTrainer spellId join-rate {join_rate:.3f} < 0.90"

    bucketed = {}
    for rid in sorted(records):
        bucketed.setdefault(sharding.bucket_id(rid, TRAINER_BUCKET), []).append(records[rid])

    bucket_index = []
    for bkt in sorted(bucketed):
        recs = bucketed[bkt]
        fname = f"trainers-{bkt}.json"
        payload = {"bucket": bkt, "count": len(recs), "minId": recs[0]["id"],
                   "maxId": recs[-1]["id"], "entries": recs}
        (out_dir / fname).write_text(sharding.dump_manifest(payload), encoding="utf-8")
        bucket_index.append({"bucket": bkt, "file": fname, "count": len(recs),
                              "minId": recs[0]["id"], "maxId": recs[-1]["id"]})

    index = {"bucketSize": TRAINER_BUCKET, "count": len(records), "buckets": bucket_index}
    (out_dir / "index.json").write_text(sharding.dump_manifest(index), encoding="utf-8")

    meta = {
        "count": len(records),
        "spellJoinRate": round(join_rate, 4),
        "provenColumns": {
            "id": "NPCTrainer.dbc f0 - ascending unique 1..13060",
            "spellId": f"NPCTrainer.dbc f1 - {join_rate:.3f} join-rate vs Spell.dbc ids "
                       "(signed decode: ~1% of rows carry small negative sentinel "
                       "values on otherwise-empty placeholder rows, kept visible rather "
                       "than u32-wrapped into a misleading fake-looking id)",
            "skillLine": "NPCTrainer.dbc f2 - 99.9% join-rate vs SkillLine.dbc ids AND "
                         "semantic golden: resolves to real profession/talent-tree "
                         "names (Blacksmithing, Leatherworking, Tailoring, Arcane, "
                         "Holy, Feral Combat, ...)",
        },
        "trainerIdFinding": (
            "The brief hypothesized NPCTrainer's 'trainer-id column' as the low-"
            "cardinality grouping column among f2/f3. f2 instead proves out as "
            "skillLine (see provenColumns), not a trainer-NPC identity. f3 (110 "
            "distinct values, max 450) has weak/inconsistent join-rates against every "
            "lookup table tried and its populated values cluster on multiples of 25 "
            "(125, 200, 250, 275, 300, 350, 375, 400, 420) - consistent with a WotLK "
            "profession skill-rank requirement, not a trainer id - but this is "
            "circumstantial, not independently provable via a join, so it stays "
            "unmapped (raw f3). No column in this 4-field table represents a specific "
            "trainer NPC's identity; output is therefore a flat per-record list "
            "(not grouped by trainerId), bucketed by NPCTrainer's own row id per "
            "Amendment C's literal `id//2000*2000` layout instruction."
        ),
    }
    (out_dir / "_meta.json").write_text(
        json.dumps(meta, ensure_ascii=False, indent=1, sort_keys=True), encoding="utf-8")
    return {"written": len(records), "spellJoinRate": join_rate}


def build() -> dict:
    config.ensure_dirs()
    return {"creatures": build_creatures(), "quests": build_quests(),
            "trainers": build_trainers()}


if __name__ == "__main__":
    print(build())
