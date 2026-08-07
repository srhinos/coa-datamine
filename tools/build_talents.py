"""Talent trees per class from Talent.dbc + TalentTab.dbc (classMask bit = classId-1).

Talents output stays as-is (unsharded) under Amendment C: largest file is
data/talents/_meta.json at well under the 5,000-line gate - no split needed."""
import json
from collections import defaultdict

from tools import config, dbc, build_spells


def _spell_names():
    return {r["id"]: r["name"] for r in build_spells.iter_all()}


def build() -> dict:
    names = _spell_names()
    classes = {c["id"]: c["name_enUS"] for c in dbc.iter_named("ChrClasses")}
    tabs = sorted(dbc.iter_named("TalentTab"), key=lambda t: (t["orderIndex"], t["id"]))
    talents_by_tab = defaultdict(list)
    unresolved = talent_count = 0

    for t in dbc.iter_named("Talent"):
        talent_count += 1
        ranks = []
        for i in range(1, 10):
            sid = t[f"rankSpell{i}"]
            if sid:
                nm = names.get(sid)
                if nm is None:
                    unresolved += 1
                ranks.append({"spellId": sid, "name": nm})
        prereqs = [{"talentId": t[f"prereqTalent{i}"], "rank": t[f"prereqRank{i}"] + 1}
                   for i in range(1, 4) if t[f"prereqTalent{i}"]]
        talents_by_tab[t["tabID"]].append({
            "id": t["id"], "row": t["row"], "col": t["col"], "ranks": ranks,
            "prereqs": prereqs, "requiredSpellID": t["requiredSpellID"],
        })
    for lst in talents_by_tab.values():
        lst.sort(key=lambda x: (x["row"], x["col"]))

    per_class, pet_tabs, unassigned = defaultdict(list), [], []
    for tab in tabs:
        entry = {"id": tab["id"], "name": tab["name_enUS"],
                 "orderIndex": tab["orderIndex"],
                 "backgroundFile": tab["backgroundFile"],
                 "talents": talents_by_tab.get(tab["id"], [])}
        class_ids = [cid for cid in classes if tab["classMask"] & (1 << (cid - 1))]
        if tab["petTalentMask"]:
            pet_tabs.append(dict(entry, petTalentMask=tab["petTalentMask"]))
        elif class_ids:
            for cid in class_ids:
                per_class[cid].append(entry)
        else:
            unassigned.append(dict(entry, classMask=tab["classMask"]))

    tdir = config.DATA_DIR / "talents"
    tdir.mkdir(parents=True, exist_ok=True)
    files = 0
    tab_counts = {}
    for cid, class_tabs in sorted(per_class.items()):
        cname = classes[cid].replace(" ", "")
        payload = {"class": classes[cid], "classId": cid, "tabs": class_tabs}
        (tdir / f"{cname}.json").write_text(
            json.dumps(payload, ensure_ascii=False, indent=1, sort_keys=True),
            encoding="utf-8", newline="\n")
        files += 1
        tab_counts[cname] = len(class_tabs)
    (tdir / "_pet.json").write_text(
        json.dumps(pet_tabs, ensure_ascii=False, indent=1, sort_keys=True),
        encoding="utf-8", newline="\n")
    (tdir / "_unassigned.json").write_text(
        json.dumps(unassigned, ensure_ascii=False, indent=1, sort_keys=True),
        encoding="utf-8", newline="\n")
    meta = {"tabs": len(tabs), "talents": talent_count, "classFiles": files,
            "petTabs": len(pet_tabs), "unassignedTabs": len(unassigned),
            "classTabCounts": tab_counts,
            "unresolvedRankSpells": unresolved}
    (tdir / "_meta.json").write_text(
        json.dumps(meta, ensure_ascii=False, indent=1, sort_keys=True),
        encoding="utf-8", newline="\n")
    return {"tabs": len(tabs), "talents": talent_count, "files": files,
            "unresolvedRankSpells": unresolved}


if __name__ == "__main__":
    print(build())
