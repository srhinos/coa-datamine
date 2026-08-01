"""Dungeons/raids/encounters: LFGDungeons + Map + AreaTable + DungeonEncounter + LFGData.

Amendment C: one file per dungeon (data/dungeons/<id>-<slug>.json, encounters/rewards
inline) + data/dungeons/index.json {id, name, file, mapId, isRaid, levels}. The old
encountersByMap duplicate view is dropped - it's fully derivable by grouping the
per-dungeon files on (mapId, difficulty).

Task V2-2: encounters were meant to gain a "creature": {id, name}|null boss link from
DungeonEncounterExtra.dbc. Probed and DISPROVEN at the time: DungeonEncounterExtra's f0
proves out as dungeonEncounterId (98.5% join + semantic golden - resolves to real
encounter names), but its f1 (creature-id hypothesis) failed golden verification even
though it cleared the naive 90% join-rate bar against Creature.dbc's OLD f0 id column
(92.4%) - famous bosses (Ragnaros, Onyxia, Kel'Thuzad, Illidan, ...) all resolved to
unrelated random NPCs. That was a false positive caused by Creature.dbc's OLD f0 id
column being fully dense (every integer 1..127178 was a valid row-position id, so any
bounded column passed membership near-trivially); see .superpowers/sdd/task-v2-2-report.md
for the original evidence (fuzzy name-overlap 1.3%, barely above a random-pairing
control's 0.45%).

Task V3-0 (2026-08-01, .superpowers/sdd/task-v3-0-report.md): the client rebuild proved
Creature.dbc's f0 is actually a POSITIONAL row index (shifts on patches), not a stable
id - the real, stable creature entry id is f1, a genuinely SPARSE space (127178 ids
spread across 1..11001007). Retesting DungeonEncounterExtra's SAME f1 column against
Creature's corrected f1 id space REVERSES the V2-2 disproof: row-level join-rate 98.57%
(2006/2035), every famous-boss golden now resolves correctly (Ragnaros->11502,
Onyxia->10184, Kel'Thuzad->15990, Illidan Stormrage->22917, ...), fuzzy word-overlap
94.7% vs a random-pairing control's 0.55%. f2/f3 still fail even the naive join-rate bar
(~51-55%) against either table - left unmapped. Every encounter now ships a real
"creature": {id, name} (null only for the ~1.4% of DungeonEncounter rows with no
DungeonEncounterExtra row, or whose creatureId doesn't resolve)."""
import json, shutil
from collections import defaultdict

from tools import config, dbc, enums335, sharding


def build() -> dict:
    maps = {m["id"]: m for m in dbc.iter_named("Map")}
    areas = {a["id"]: a for a in dbc.iter_named("AreaTable")}
    rewards = defaultdict(list)
    for e in json.loads(
            (config.RAW_CONTENT_DIR / "LFGData.json").read_text(encoding="utf-8-sig")):
        rewards[e["DungeonId"]].append(e)
    for lst in rewards.values():
        lst.sort(key=lambda x: x.get("MaxLevel", 0))

    # V3-0: DungeonEncounterExtra.dungeonEncounterId -> creatureId, proven vs Creature's
    # corrected f1 entry-id space (see module docstring). dungeonEncounterId==0 is a
    # placeholder/sentinel (not a real DungeonEncounter id - skip it); a small minority
    # of real dungeonEncounterIds repeat across multiple rows (extra per-difficulty
    # metadata) but every repeat agrees on creatureId, so first-row-wins is safe.
    creature_names = {r["id"]: r["name_enUS"] for r in dbc.iter_named("Creature")}
    enc_creature_id = {}
    for r in dbc.iter_named("DungeonEncounterExtra"):
        eid = r["dungeonEncounterId"]
        if eid == 0 or eid in enc_creature_id:
            continue
        enc_creature_id[eid] = r["creatureId"]

    enc_by_map = defaultdict(list)
    enc_count = orphan = links = 0
    for e in dbc.iter_named("DungeonEncounter"):
        enc_count += 1
        if e["mapID"] not in maps:
            orphan += 1
        cid = enc_creature_id.get(e["id"])
        cname = creature_names.get(cid) if cid is not None else None
        creature = {"id": cid, "name": cname} if cname is not None else None
        if creature is not None:
            links += 1
        enc_by_map[(e["mapID"], e["difficulty"])].append(
            {"id": e["id"], "name": e["name_enUS"], "orderIndex": e["orderIndex"],
             "creature": creature})
    for lst in enc_by_map.values():
        lst.sort(key=lambda x: x["orderIndex"])

    dungeons, raid_count = [], 0
    for d in dbc.iter_named("LFGDungeons"):
        m = maps.get(d["mapID"])
        map_block = None
        if m:
            zone = areas.get(m["areaTableID"], {}).get("name_enUS", "")
            is_raid = m["instanceType"] == 2
            raid_count += is_raid
            map_block = {
                "name": m["name_enUS"], "directory": m["directory"],
                "instanceType": m["instanceType"],
                "instanceTypeName": enums335.INSTANCE_TYPES.get(
                    m["instanceType"], str(m["instanceType"])),
                "maxPlayers": m["maxPlayers"], "isRaid": is_raid, "zone": zone,
            }
        dungeons.append({
            "id": d["id"], "name": d["name_enUS"], "description": d["description_enUS"],
            "levels": {"min": d["minLevel"], "max": d["maxLevel"],
                       "target": d["targetLevel"], "targetMin": d["targetLevelMin"],
                       "targetMax": d["targetLevelMax"]},
            "mapId": d["mapID"], "difficulty": d["difficulty"],
            "typeId": d["typeID"],
            "typeName": enums335.LFG_TYPES.get(d["typeID"], str(d["typeID"])),
            "faction": d["faction"], "flags": d["flags"],
            "expansionLevel": d["expansionLevel"], "groupId": d["groupID"],
            "map": map_block,
            "encounters": enc_by_map.get((d["mapID"], d["difficulty"]), []),
            "rewards": rewards.get(d["id"], []),
        })
    dungeons.sort(key=lambda x: x["id"])

    out_dir = config.DATA_DIR / "dungeons"
    if out_dir.exists():
        shutil.rmtree(out_dir)                      # drop any prior monolith/shards
    out_dir.mkdir(parents=True)

    index_dungeons = []
    for d in dungeons:
        slug = sharding.slugify(d["name"])
        fname = f"{d['id']}-{slug}.json"
        (out_dir / fname).write_text(
            json.dumps(d, ensure_ascii=False, indent=1, sort_keys=True), encoding="utf-8")
        index_dungeons.append({
            "id": d["id"], "name": d["name"], "file": fname, "mapId": d["mapId"],
            "isRaid": bool(d["map"]["isRaid"]) if d["map"] else False,
            "levels": d["levels"],
        })
    (out_dir / "index.json").write_text(
        sharding.dump_manifest({"dungeons": index_dungeons}), encoding="utf-8")
    return {"dungeons": len(dungeons), "raids": raid_count,
            "encounters": enc_count, "orphanEncounterMaps": orphan,
            "encounterCreatureLinks": links}


if __name__ == "__main__":
    print(build())
