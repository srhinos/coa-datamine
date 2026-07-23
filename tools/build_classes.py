"""Group CharacterAdvancementData by class into data/classes/, joined to spells.jsonl.

Amendment A: CharacterAdvancementData.json is account-wide across four realms served
by this client (Area 52 - Free-Pick, Bronzebeard - Warcraft Reborn, Rexxar - Conquest
of Azeroth, Vol'jin - Conquest of Azeroth). Reborn*-class spell data is not
materialized in this client's Spell.dbc snapshot, so null-resolved spells on
reborn-tagged classes are an expected data reality, not a pipeline error - they are
counted separately (unresolved_reborn / refs_reborn) rather than folded into the
gated ratio (unresolved_other / refs_other).

Amendment C: each class shards into data/classes/<Class>/<Tab>.json (one file per
spec tab) + data/classes/<Class>/index.json. Entries without a Tab go to _general.json
(none exist in this snapshot, but the fallback is implemented). A handful of Reborn
tabs carry 600+ Trait entries and blow past 5,000 lines as a single file even though
the Tab is the natural semantic key; those cascade Tab -> Type (<Tab>.<Type>.json) ->
if STILL oversized (the "Trait" bucket, which alone dominates its tab), a fixed
cadId-range bucket (<Tab>.<Type>-<cadId//CADID_BUCKET*CADID_BUCKET>.json) - the
amendment's own sanctioned fallback for keys with no smaller semantic grouping.
Measured: Type alone is insufficient because Trait entries are ~95% of the oversized
tabs; a requiredLevel band is also insufficient because ~40% of those Trait entries
share literally the same RequiredLevel (mostly 1), so no level-band width shrinks
that cluster - cadId-range is the only one of the amendment's two sanctioned
mechanisms that actually gets every file under the gate."""
import json, re, shutil
from collections import Counter, defaultdict

from tools import config, dbc, build_spells, sharding

VANILLA = {"Warrior", "Paladin", "Hunter", "Rogue", "Priest", "DeathKnight",
           "Shaman", "Mage", "Warlock", "Druid"}
META = {"None", "ConquestOfAzeroth"}

REALM_HINT = {
    "reborn": "Bronzebeard - Warcraft Reborn",
    "vanilla": "Area 52 - Free-Pick /shared",
    "coa-custom": "Rexxar/Vol'jin - Conquest of Azeroth",
    "meta": None,
}

MAX_LINES = 5000
CADID_BUCKET = 2000


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
    for r in build_spells.iter_all():
        out[r["id"]] = {"id": r["id"], "name": r["name"],
                        "dispel": r["dispel"]["name"], "schools": r["schools"]}
    return out


def _dump(payload):
    text = json.dumps(payload, ensure_ascii=False, indent=1, sort_keys=True)
    return text, text.count("\n") + 1


def _shard_tab(cls, tab, entries):
    """Split one tab's entries into <=MAX_LINES files: whole tab, else by Type,
    else (only the Trait mega-buckets) by fixed cadId range. Returns a list of
    (filename, meta, text) - meta feeds the per-class index.json 'files' list."""
    tab_name = tab or "_general"
    text, lines = _dump({"class": cls, "tab": tab, "type": None, "entries": entries})
    if lines <= MAX_LINES:
        return [(f"{tab_name}.json",
                 {"file": f"{tab_name}.json", "tab": tab, "type": None,
                  "cadIdRange": None, "count": len(entries)}, text)]

    out = []
    by_type = defaultdict(list)
    for e in entries:
        by_type[e["type"] or None].append(e)
    for typ in sorted(by_type, key=lambda t: (t is None, t or "")):
        typ_entries = by_type[typ]
        typ_name = typ or "_untyped"
        text, lines = _dump({"class": cls, "tab": tab, "type": typ, "entries": typ_entries})
        if lines <= MAX_LINES:
            fname = f"{tab_name}.{typ_name}.json"
            out.append((fname, {"file": fname, "tab": tab, "type": typ,
                                "cadIdRange": None, "count": len(typ_entries)}, text))
            continue
        by_bucket = defaultdict(list)
        for e in typ_entries:
            by_bucket[sharding.bucket_id(e["cadId"], CADID_BUCKET)].append(e)
        for b in sorted(by_bucket):
            b_entries = by_bucket[b]
            text, _ = _dump({"class": cls, "tab": tab, "type": typ, "entries": b_entries})
            fname = f"{tab_name}.{typ_name}-{b}.json"
            out.append((fname, {"file": fname, "tab": tab, "type": typ,
                                "cadIdRange": [b, b + CADID_BUCKET],
                                "count": len(b_entries)}, text))
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

    # Amendment D (single-writer ownership): this builder owns only the per-class
    # subdirectories and the top-level index.json it writes below - NOT the whole
    # data/classes/ directory. build_classmeta.py's specs.json/archetypes.json live
    # alongside these and must survive a build_classes rerun untouched.
    cdir = config.DATA_DIR / "classes"
    cdir.mkdir(parents=True, exist_ok=True)
    for child in cdir.iterdir():
        if child.is_dir():
            shutil.rmtree(child)                    # drop prior per-class dirs only
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

        by_tab = defaultdict(list)
        for e in entries:
            by_tab[e["tab"] or None].append(e)
        class_dir = cdir / cls
        class_dir.mkdir()
        files_meta = []
        for tab in sorted(by_tab, key=lambda t: (t is None, t or "")):
            for fname, fmeta, text in _shard_tab(cls, tab, by_tab[tab]):
                (class_dir / fname).write_text(text, encoding="utf-8")
                files_meta.append(fmeta)

        class_index = {
            "class": cls, "tag": tag,
            "classId": chr_match["id"] if chr_match else None,
            "realmHint": realm_hint,
            "entryCount": len(entries),
            "unresolvedCount": class_unresolved,
            "entryCounts": dict(Counter(x["type"] for x in entries)),
            "files": files_meta,
        }
        (class_dir / "index.json").write_text(
            sharding.dump_manifest(class_index), encoding="utf-8")
        index_classes.append({
            "name": cls, "tag": tag,
            "classId": chr_match["id"] if chr_match else None,
            "realmHint": realm_hint,
            "dir": f"{cls}/",
            "index": f"{cls}/index.json",
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
    (cdir / "index.json").write_text(sharding.dump_manifest(index), encoding="utf-8")
    return {"classes": len(index_classes), "entries": total_entries,
            "unresolved_reborn": unresolved_reborn, "unresolved_other": unresolved_other,
            "refs_reborn": refs_reborn, "refs_other": refs_other}


if __name__ == "__main__":
    print(build())
