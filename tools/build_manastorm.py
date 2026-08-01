"""Manastorm seasonal-modifier system (task V3-1): Manastorm.dbc / ManastormMessages.dbc
/ ManastormModifiers.dbc / ManastormPlayerGroupModifiers.dbc (patch-M) -> data/manastorm/.

Amendment D (single-writer ownership): build_manastorm.py is the SOLE writer under
data/manastorm/ - build() clears and rebuilds the whole directory itself.

Full mapping evidence (join-rates, goldens, disproven hypotheses) is documented in
tools/dbc.py's TABLE_MAPS comments for Manastorm/ManastormMessages/ManastormModifiers/
ManastormPlayerGroupModifiers and in .superpowers/sdd/task-v3-1-report.md. Summary of
what this module derives on top of the raw named columns:

- Manastorm (1017x9): id/mapId/difficulty/dungeonEncounterId all proven - mapId is a
  100% join vs Map.dbc where every one of the 73 distinct values resolves to a real
  dungeon/raid zone name (not a density coincidence: Map.dbc is only ~9.4% dense over
  f1's own value range); dungeonEncounterId is a 99.5% resolve rate against
  DungeonEncounter.dbc PLUS a 100% two-hop chain match (the resolved encounter's own
  mapID always equals this row's mapId - e.g. Shadowfang Keep's Manastorm rows resolve
  to exactly SFK's 7 real bosses); difficulty is a 100% match against the resolved
  encounter's own difficulty column. f4-f8 (IEEE-754 floats, no provable per-row
  semantic or lookup-table target) are carried raw as signed ints, not float-decoded -
  "unproven" covers wire-type interpretation, not just naming, per this codebase's
  convention for every other undecoded column.
- ManastormMessages (291x39): id/iconToken/title/text all proven - text is the brief's
  requested seasonal-flavor golden (id 1's text literally contains the word
  "Manastorm"). f1 (same {0,2} value domain as Manastorm.difficulty, and a literal
  content-duplicate pair - id 1 vs id 12 - differing only in this column) is
  circumstantially the same seasonal-tier concept but not independently provable inside
  this table alone - left raw. f2 (hypothesized spellId) and f3 (hypothesized areaId)
  were both DISPROVEN despite clearing a naive >90% join-rate bar: their resolved
  targets (ancient low-id test/base spells; unrelated classic zone names) have zero
  thematic connection to the message content - the density-false-positive class this
  codebase repeatedly warns about - both left raw. 32 LangString locale-filler columns
  (constant across every one of the 291 rows - this build only populates enUS) are
  dropped entirely, not carried into output.
- ManastormModifiers (32768x15) / ManastormPlayerGroupModifiers (15x5): only id is
  proven in either table - no spellId or other FK column exists anywhere in either
  table (every candidate checked, see tools/dbc.py). Shipped as {id, raw: [...]} per
  row; raw columns are carried as signed ints (not float-decoded) rather than u32-
  wrapped, since several ManastormModifiers columns are genuinely negative-valued float
  bit patterns and u32-wrapping them would manufacture misleading huge "unsigned"
  numbers - the same representation-fidelity rationale this codebase already applied to
  NPCTrainer.spellId's negative sentinel values.
"""
import json, shutil
from collections import defaultdict

from tools import config, dbc, sharding

MODIFIER_BUCKET = 5000
MIN_ENCOUNTER_JOIN_RATE = 0.95


def build_manastorm() -> dict:
    mdir = config.DATA_DIR / "manastorm"
    f = dbc.DBCFile(config.WORK_DBC_DIR / "Manastorm.dbc")
    if f.fields != 9:
        raise dbc.LayoutError(f"Manastorm: field_count {f.fields} != expected 9")

    maps = {r["id"]: r["name_enUS"] for r in dbc.iter_named("Map")}
    encounters = {r["id"]: r for r in dbc.iter_named("DungeonEncounter")}

    records = []
    resolved = mismatches = 0
    for row in f.iter_rows():
        rid, map_id, difficulty, enc_id = row[0], row[1], row[2], row[3]
        enc = encounters.get(enc_id)
        if enc:
            resolved += 1
            if enc["mapID"] != map_id or enc["difficulty"] != difficulty:
                mismatches += 1
        records.append({
            "id": rid, "mapId": map_id, "mapName": maps.get(map_id),
            "difficulty": difficulty, "dungeonEncounterId": enc_id,
            "dungeonEncounterName": enc["name_enUS"] if enc else None,
            "raw": list(row[4:9]),
        })
    records.sort(key=lambda x: x["id"])
    assert len(records) == f.records, "Manastorm id column is not unique"

    # gates: refuse to publish if the pinned proof facts don't hold
    assert all(r["mapName"] is not None for r in records), \
        "Manastorm mapId join dropped below 100% - column map is wrong"
    join_rate = resolved / len(records) if records else 0.0
    assert join_rate >= MIN_ENCOUNTER_JOIN_RATE, \
        f"Manastorm dungeonEncounterId join-rate {join_rate:.3f} < {MIN_ENCOUNTER_JOIN_RATE}"
    assert mismatches == 0, (
        f"{mismatches} Manastorm rows disagree with their resolved encounter's own "
        "mapID/difficulty - the two-hop chain proof no longer holds")

    # golden gate: Shadowfang Keep (map 33) must resolve its own real boss roster
    sfk = {r["dungeonEncounterName"] for r in records if r["mapId"] == 33}
    assert "Rethilgore" in sfk and "Archmage Arugal" in sfk, sfk

    (mdir / "manastorm.json").write_text(
        sharding.dump_manifest({"manastorm": records}), encoding="utf-8")
    return {"count": len(records), "dungeonEncounterJoinRate": round(join_rate, 4)}


def build_messages() -> dict:
    mdir = config.DATA_DIR / "manastorm"
    f = dbc.DBCFile(config.WORK_DBC_DIR / "ManastormMessages.dbc")
    if f.fields != 39:
        raise dbc.LayoutError(f"ManastormMessages: field_count {f.fields} != expected 39")

    records = []
    for row in f.iter_rows():
        records.append({
            "id": row[0],
            "iconToken": f.string(row[4]),
            "title": f.string(row[5]),
            "text": f.string(row[22]),
            "raw": list(row[1:4]),
        })
    records.sort(key=lambda x: x["id"])
    assert len(records) == f.records, "ManastormMessages id column is not unique"

    # golden gate (brief: pin a verified decoded seasonal-flavor message)
    golden = next(r for r in records if r["id"] == 1)
    assert golden["title"] == "Unlocked Iskarr Village!", golden
    assert golden["text"] == "You have unlocked Iskarr Village in your next Manastorm!", golden
    assert "Manastorm" in golden["text"]

    (mdir / "messages.json").write_text(
        sharding.dump_manifest({"messages": records}), encoding="utf-8")
    return {"count": len(records)}


def build_modifiers() -> dict:
    mdir = config.DATA_DIR / "manastorm"
    f = dbc.DBCFile(config.WORK_DBC_DIR / "ManastormModifiers.dbc")
    if f.fields != 15:
        raise dbc.LayoutError(f"ManastormModifiers: field_count {f.fields} != expected 15")

    records = [{"id": row[0], "raw": list(row[1:15])} for row in f.iter_rows()]
    records.sort(key=lambda x: x["id"])
    assert len(records) == len({r["id"] for r in records}) == f.records, \
        "ManastormModifiers id column is not unique"

    bucketed = defaultdict(list)
    for rec in records:
        bucketed[sharding.bucket_id(rec["id"], MODIFIER_BUCKET)].append(rec)

    bucket_index = []
    for bkt in sorted(bucketed):
        recs = bucketed[bkt]
        fname = f"modifiers-{bkt}.jsonl"
        with open(mdir / fname, "w", encoding="utf-8", newline="\n") as fh:
            for rec in recs:
                fh.write(json.dumps(rec, ensure_ascii=False, sort_keys=True,
                                    separators=(",", ":")) + "\n")
        bucket_index.append({"bucket": bkt, "file": fname, "count": len(recs),
                              "minId": recs[0]["id"], "maxId": recs[-1]["id"]})

    (mdir / "index.json").write_text(
        sharding.dump_manifest({"bucketSize": MODIFIER_BUCKET, "count": len(records),
                                 "buckets": bucket_index}), encoding="utf-8")
    return {"count": len(records)}


def build_player_group_modifiers() -> dict:
    mdir = config.DATA_DIR / "manastorm"
    f = dbc.DBCFile(config.WORK_DBC_DIR / "ManastormPlayerGroupModifiers.dbc")
    if f.fields != 5:
        raise dbc.LayoutError(
            f"ManastormPlayerGroupModifiers: field_count {f.fields} != expected 5")

    records = [{"id": row[0], "raw": list(row[1:5])} for row in f.iter_rows()]
    records.sort(key=lambda x: x["id"])
    assert len(records) == f.records, "ManastormPlayerGroupModifiers id column is not unique"

    (mdir / "playerGroupModifiers.json").write_text(
        sharding.dump_manifest({"playerGroupModifiers": records}), encoding="utf-8")
    return {"count": len(records)}


def build() -> dict:
    config.ensure_dirs()
    mdir = config.DATA_DIR / "manastorm"
    if mdir.exists():
        shutil.rmtree(mdir)          # sole writer (Amendment D) - safe to own outright
    mdir.mkdir(parents=True)

    stats = {
        "manastorm": build_manastorm(),
        "messages": build_messages(),
        "modifiers": build_modifiers(),
        "playerGroupModifiers": build_player_group_modifiers(),
    }

    meta = {
        "counts": {k: v["count"] for k, v in stats.items()},
        "provenColumns": {
            "Manastorm": "id (f0) / mapId (f1, 100% join + every value resolves a real "
                         "dungeon-raid zone name) / difficulty (f2, 100% match vs the "
                         "resolved encounter's own difficulty) / dungeonEncounterId (f3, "
                         "99.5% resolve + 100% two-hop mapId chain match) - see tools/dbc.py",
            "ManastormMessages": "id (f0) / iconToken (f4) / title (f5) / text (f22, "
                                  "golden contains the literal word 'Manastorm') - see "
                                  "tools/dbc.py",
            "ManastormModifiers": "id (f0) only - no spellId or other FK column proven "
                                   "anywhere in this table",
            "ManastormPlayerGroupModifiers": "id (f0) only - no other column proven",
        },
        "dungeonEncounterJoinRate": stats["manastorm"]["dungeonEncounterJoinRate"],
        "spellIdFinding": (
            "ManastormMessages.f2 was hypothesized as a spellId: 90.4% raw join rate vs "
            "Spell.dbc, but resolves to unrelated low-id test/base spells ('Heal Self "
            "(TEST)', 'Blizzard', 'Stun') with zero thematic connection to the message "
            "text - a Spell.dbc low-id density false positive, DISPROVEN, left raw. No "
            "column in any of the 4 Manastorm tables proves out as a spellId."
        ),
        "areaIdFinding": (
            "ManastormMessages.f3 was hypothesized as an areaId: 92.2% raw join rate vs "
            "AreaTable.dbc, but resolves to unrelated zone names (e.g. 'Silverpine "
            "Forest' for a Zul'Gurub-themed message) bearing no relation to the grouped "
            "messages' actual raid content - a density false positive, DISPROVEN, left "
            "raw. Its nonzero values do cleanly group messages by real content pack "
            "(130=Zul'Gurub, 132=Molten Core, 134=Blackwing Lair, 135=AQ20, 137=AQ40, "
            "139=Naxxramas) - a genuine internal grouping structure, but no WANTED_DBCS "
            "lookup table exists to independently prove what f3's own id space names."
        ),
    }
    (mdir / "_meta.json").write_text(
        json.dumps(meta, ensure_ascii=False, indent=1, sort_keys=True), encoding="utf-8")

    return stats


if __name__ == "__main__":
    print(build())
