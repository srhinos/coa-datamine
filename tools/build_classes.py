"""Group CharacterAdvancementData by class into data/classes/, joined to spells.jsonl.

Amendment A: CharacterAdvancementData.json is account-wide across four realms served
by this client (Area 52 - Free-Pick, Bronzebeard - Warcraft Reborn, Rexxar - Conquest
of Azeroth, Vol'jin - Conquest of Azeroth). Reborn*-class spell data is not
materialized in this client's Spell.dbc snapshot, so null-resolved spells on
reborn-tagged classes are an expected data reality, not a pipeline error - they are
counted separately (unresolved_reborn / refs_reborn) rather than folded into the
gated ratio (unresolved_other / refs_other)."""
import json, re
from collections import Counter, defaultdict

from tools import config, dbc

VANILLA = {"Warrior", "Paladin", "Hunter", "Rogue", "Priest", "DeathKnight",
           "Shaman", "Mage", "Warlock", "Druid"}
META = {"None", "ConquestOfAzeroth"}

REALM_HINT = {
    "reborn": "Bronzebeard - Warcraft Reborn",
    "vanilla": "Area 52 - Free-Pick /shared",
    "coa-custom": "Rexxar/Vol'jin - Conquest of Azeroth",
    "meta": None,
}


def _norm(s):
    return re.sub(r"[^a-z0-9]", "", s.lower())


def _tag(cls):
    if cls in META:
        return "meta"
    if cls.startswith("Reborn"):
        return "reborn"
    if cls in VANILLA:
        return "vanilla"
    return "coa-custom"


def _spell_min():
    out = {}
    with open(config.DATA_DIR / "spells" / "spells.jsonl", encoding="utf-8") as fh:
        for line in fh:
            r = json.loads(line)
            out[r["id"]] = {"id": r["id"], "name": r["name"],
                            "dispel": r["dispel"]["name"], "schools": r["schools"]}
    return out


def build() -> dict:
    cad = json.loads((config.RAW_CONTENT_DIR / "CharacterAdvancementData.json")
                     .read_text(encoding="utf-8-sig"))
    ranks = json.loads((config.RAW_CONTENT_DIR / "SpellRankData.json")
                       .read_text(encoding="utf-8-sig"))
    chains = defaultdict(list)
    for e in ranks:
        chains[e["firstSpellId"]].append(
            {"spellId": e["spellId"], "rank": e["rank"], "level": e["level"]})
    for c in chains.values():
        c.sort(key=lambda x: x["rank"])

    spells = _spell_min()
    chr_classes = list(dbc.iter_named("ChrClasses"))
    chr_by_norm = {_norm(c["name_enUS"]): c for c in chr_classes}

    groups = defaultdict(list)
    for e in cad:
        cls = e.get("Class") or "None"
        groups["_other" if cls in META else cls].append(e)

    cdir = config.DATA_DIR / "classes"
    cdir.mkdir(parents=True, exist_ok=True)
    index_classes, total_entries, matched_norms = [], 0, set()
    unresolved_reborn = unresolved_other = 0
    refs_reborn = refs_other = 0

    for cls in sorted(groups):
        tag = "meta" if cls == "_other" else _tag(cls)
        is_reborn = tag == "reborn"
        entries = []
        class_unresolved = 0
        for e in sorted(groups[cls], key=lambda x: (x.get("Name") or "", x["ID"])):
            resolved = []
            for sid in e.get("Spells", []):
                s = spells.get(sid)
                if is_reborn:
                    refs_reborn += 1
                else:
                    refs_other += 1
                if s is None:
                    if is_reborn:
                        unresolved_reborn += 1
                    else:
                        unresolved_other += 1
                    class_unresolved += 1
                    resolved.append({"id": sid, "name": None, "dispel": None,
                                     "schools": [], "ranks": None})
                else:
                    resolved.append(dict(s, ranks=chains.get(sid) or None))
            entries.append({
                "cadId": e["ID"], "name": e.get("Name", ""), "icon": e.get("Icon", ""),
                "tab": e.get("Tab", ""), "type": e.get("Type", ""),
                "quality": e.get("Quality", ""), "qualityCost": e.get("QualityCost", 0),
                "requiredLevel": e.get("RequiredLevel", 0), "aeCost": e.get("AECost", 0),
                "expansion": e.get("Expansion", 0), "flags": e.get("Flags", 0),
                "realms": e.get("Realms", ""), "spells": resolved,
            })
        total_entries += len(entries)
        chr_match = None if cls == "_other" else chr_by_norm.get(
            _norm(cls.removeprefix("Reborn") if cls.startswith("Reborn") else cls))
        if chr_match:
            matched_norms.add(_norm(chr_match["name_enUS"]))
        realm_hint = REALM_HINT[tag]
        payload = {"class": cls, "tag": tag,
                   "classId": chr_match["id"] if chr_match else None,
                   "realmHint": realm_hint,
                   "entries": entries}
        (cdir / f"{cls}.json").write_text(
            json.dumps(payload, ensure_ascii=False, indent=1, sort_keys=True),
            encoding="utf-8")
        index_classes.append({
            "name": cls, "tag": tag,
            "classId": chr_match["id"] if chr_match else None,
            "realmHint": realm_hint,
            "file": f"{cls}.json",
            "entryCounts": dict(Counter(x["type"] for x in entries)),
            "unresolvedCount": class_unresolved,
        })

    index = {
        "classes": index_classes,
        "chrClasses": [{"id": c["id"], "name": c["name_enUS"],
                        "powerType": c["powerType"]} for c in chr_classes],
        "unmatchedChrClasses": sorted(c["name_enUS"] for c in chr_classes
                                      if _norm(c["name_enUS"]) not in matched_norms),
    }
    (cdir / "index.json").write_text(
        json.dumps(index, ensure_ascii=False, indent=1, sort_keys=True),
        encoding="utf-8")
    return {"classes": len(index_classes), "entries": total_entries,
            "unresolved_reborn": unresolved_reborn, "unresolved_other": unresolved_other,
            "refs_reborn": refs_reborn, "refs_other": refs_other}


if __name__ == "__main__":
    print(build())
