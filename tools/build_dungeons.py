"""Dungeons/raids/encounters: LFGDungeons + Map + AreaTable + DungeonEncounter + LFGData."""
import json
from collections import defaultdict

from tools import config, dbc, enums335


def build() -> dict:
    maps = {m["id"]: m for m in dbc.iter_named("Map")}
    areas = {a["id"]: a for a in dbc.iter_named("AreaTable")}
    rewards = defaultdict(list)
    for e in json.loads(
            (config.RAW_CONTENT_DIR / "LFGData.json").read_text(encoding="utf-8-sig")):
        rewards[e["DungeonId"]].append(e)
    for lst in rewards.values():
        lst.sort(key=lambda x: x.get("MaxLevel", 0))

    enc_by_map = defaultdict(list)
    enc_count = orphan = 0
    for e in dbc.iter_named("DungeonEncounter"):
        enc_count += 1
        if e["mapID"] not in maps:
            orphan += 1
        enc_by_map[(e["mapID"], e["difficulty"])].append(
            {"id": e["id"], "name": e["name_enUS"], "orderIndex": e["orderIndex"]})
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
    out_dir.mkdir(parents=True, exist_ok=True)
    doc = {
        "dungeons": dungeons,
        "encountersByMap": {
            str(mid): {str(diff): lst for (m2, diff), lst in enc_by_map.items()
                       if m2 == mid}
            for mid in sorted({m for m, _ in enc_by_map})},
    }
    (out_dir / "dungeons.json").write_text(
        json.dumps(doc, ensure_ascii=False, indent=1, sort_keys=True), encoding="utf-8")
    return {"dungeons": len(dungeons), "raids": raid_count,
            "encounters": enc_count, "orphanEncounterMaps": orphan}


if __name__ == "__main__":
    print(build())
