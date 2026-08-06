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

# [Task W4-8] the 6-realm roster DATAMINE-REQUEST.md Sec 6.2 asks the `Realms`
# bitmask to be decoded against - see _realms_evidence() below.
REALM_ROSTER = ["Vol'jin", "Rexxar", "Darkmoon", "Dawnrise", "Bronzebeard", "Area 52"]

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


def _bits(v):
    return [i for i in range(32) if v & (1 << i)]


def _realms_evidence(cad) -> dict:
    """Task W4-8 (DATAMINE-REQUEST.md Sec 6.2 / Sec 13 item 10): attempt to decode
    the CAD `Realms` bitmask against REALM_ROSTER using the same reborn/vanilla/
    coa-custom class tags _tag() already computes, per the brief's golden bar - "a
    bit assignment must correctly classify >=3 independent known groups".

    Verdict (see the `verdict` key below and .superpowers/sdd/task-w4-8-report.md
    for the full writeup): FAILED the golden bar. Reborn gets a clean, if
    circumstantial, single-group signal (bit 16, backed by a client-code realm-id
    citation - see luaFindings); no bit separates coa-custom or vanilla anywhere
    close to cleanly, and the strongest coa-custom signal (bit 26) turns out to
    track the CAD `Type` field almost tautologically rather than realm membership.
    Per the binding rule ("emit only proven bits"), nothing cleared the bar, so
    NO `realmFlags` is emitted anywhere - raw `realms` is untouched on every class
    entry, unchanged from before this task."""
    groups = defaultdict(list)             # tag -> [int value, ...]
    value_counts = Counter()               # raw string value -> count
    tag_value_counts = defaultdict(Counter)
    by_spell = defaultdict(list)           # (class, spellIds) -> [{cadId, realms, name}]
    for e in cad:
        cls = e.get("Class") or "None"
        t = "meta" if cls in META else _tag(cls)
        raw = e.get("Realms", "") or "0"
        v = int(raw)
        groups[t].append(v)
        value_counts[raw] += 1
        tag_value_counts[t][raw] += 1
        if t == "coa-custom" and e.get("Type") == "Ability":
            by_spell[(cls, tuple(e.get("Spells", [])))].append(
                {"cadId": e["ID"], "realms": raw, "name": e.get("Name", ""),
                 "tab": e.get("Tab", ""), "flags": e.get("Flags", 0),
                 "icon": e.get("Icon", "")})

    total = len(cad)
    distinct = [
        {"value": val, "count": cnt, "popcount": bin(int(val)).count("1"),
         "bits": _bits(int(val))}
        for val, cnt in value_counts.most_common()
    ]

    bit_stats = {
        str(bit): {
            t: round(sum(1 for v in vs if v & (1 << bit)) / len(vs), 4) if vs else 0.0
            for t, vs in groups.items()
        }
        for bit in range(32)
    }
    tag_top_values = {
        t: [{"value": val, "count": cnt} for val, cnt in c.most_common(8)]
        for t, c in tag_value_counts.items()
    }

    # concrete duplication example (first found, sorted for determinism): a
    # coa-custom ability reached via >=3 distinct `Realms` values on separate CAD
    # rows - the doc's own Sec 0 example ("a realms:'0' Ability, a realms:'6144'
    # Ability, and a realms:'100679750' Talent") - proves the SAME ability content
    # is deliberately re-flagged per DUPLICATE ROW, not per class/realm.
    duplication_example = None
    for (cls, spell_ids), rows in sorted(by_spell.items()):
        if len({r["realms"] for r in rows}) >= 3:
            duplication_example = {"class": cls, "spellIds": list(spell_ids), "rows": rows}
            break

    best_coa_bit = max(range(32), key=lambda b: bit_stats[str(b)]["coa-custom"])
    best_coa_frac = bit_stats[str(best_coa_bit)]["coa-custom"]
    bit16 = bit_stats["16"]
    agree_8_16 = sum(1 for v in groups["reborn"] + groups["coa-custom"] + groups["vanilla"]
                     if bool(v & (1 << 8)) == bool(v & (1 << 16)))
    agree_13_16 = sum(1 for v in groups["reborn"] + groups["coa-custom"] + groups["vanilla"]
                      if bool(v & (1 << 13)) == bool(v & (1 << 16)))
    n_check = len(groups["reborn"]) + len(groups["coa-custom"]) + len(groups["vanilla"])

    hypotheses = [
        {
            "name": "plain per-realm bit position (bit N = one of the 6 roster realms)",
            "verdict": "REJECTED",
            "reason": (
                f"No bit reaches even 90% presence on coa-custom (max observed "
                f"{best_coa_frac * 100:.1f}% at bit {best_coa_bit}) despite every "
                "coa-custom entry being, by class-tag definition, available on "
                "Vol'jin+Rexxar. A true per-realm bit should sit near 100% for the "
                "whole group it names, not under half of it."),
        },
        {
            "name": "1 << realmId (numeric server realm id, e.g. GetRealmId())",
            "verdict": "UNPROVEN - best lead found, does not clear the golden bar",
            "reason": (
                "raw/interface/SharedXML/Util/Util.lua:337-340 comment says realmId "
                "5 or 8 remap to 16 for Bronzebeard text lookups ('10/04/2025 change "
                "malfurion realmID to bronzebeard'; '8 = bronzebeard ptr'), i.e. "
                "Bronzebeard's CURRENT numeric realm id is 16. Bit 16 is "
                f"{bit16['reborn'] * 100:.1f}% present on reborn and only "
                f"{bit16['coa-custom'] * 100:.1f}% on coa-custom - a clean "
                "separation for that ONE group. But this satisfies only 1 of the "
                "required >=3 independent groups: no numeric realm id for Vol'jin, "
                "Rexxar, Darkmoon, Dawnrise or Area 52 was found anywhere in "
                "raw/interface, and the 1<<realmId MECHANISM is inferred, not shown "
                "directly acting on this field anywhere in client code. Bits 8 and "
                f"13 agree with bit 16 on only {agree_8_16}/{n_check} "
                f"({agree_8_16 / n_check * 100:.2f}%) and {agree_13_16}/{n_check} "
                f"({agree_13_16 / n_check * 100:.2f}%) of entries respectively - "
                "close but not exact, so which (if any) is 'the' Bronzebeard bit "
                "vs. a coupled PTR/legacy-realm-id sibling is itself unresolved."),
        },
        {
            "name": "Enum.RealmGameMode index as bit position (SharedXML/Enum.lua:778-792)",
            "verdict": "REJECTED",
            "reason": (
                "ConquestOfAzeroth=11 and WarcraftReborn=12 are defined, but bit 11 "
                f"is set on {bit_stats['11']['reborn'] * 100:.0f}% of REBORN entries "
                "(should be ~0% under this hypothesis if it named CoA) and bit 12 is "
                f"0% on reborn but only {bit_stats['12']['coa-custom'] * 100:.1f}% on "
                "coa-custom (should be ~100% if it named Reborn/CoA respectively). "
                "Both directions contradict the hypothesis; the gameMode enum index "
                "is not the bit position."),
        },
        {
            "name": "0 / 0xFFFFFFFF as 'unrestricted' sentinels, other values as an exception list",
            "verdict": "STRUCTURAL OBSERVATION ONLY - names no realm",
            "reason": (
                "Both sentinels appear across every tag (0: reborn/coa-custom/"
                "vanilla/meta all carry it; 4294967295: coa-custom/vanilla/meta do "
                "too), consistent with 'no gating applied' semantics, but this says "
                "nothing about what an individual bit means and so cannot itself "
                "satisfy the golden bar."),
        },
        {
            "name": "grouped/mode bits: duplicate CAD rows per ability encode "
                    "authoring/UI context, not realm availability",
            "verdict": "SUPPORTED as the likely true semantics - and explains why "
                       "the realm decode fails",
            "reason": (
                "Every coa-custom class shows the SAME proportional split across "
                "the same handful of values (see duplicationExample) regardless of "
                "which class - i.e. `Realms` varies WITHIN a single ability's "
                "duplicate CAD rows, not BETWEEN classes with different realm "
                f"availability. Bit {best_coa_bit} (the best coa-custom signal) "
                "tracks the CAD `Type` field almost tautologically (nearly all "
                "Talent + TalentAbility rows carry it, plus a partial slice of "
                "Ability rows) - it reads as a content-shape/UI-context flag, not a "
                "per-realm-availability flag. The STRONGEST evidence for this: "
                "duplicationExample's 3 rows for the SAME ability also differ on "
                "`Tab` (Ancestry/Tactics/Class) and `Flags` (8193/8707/8707) - "
                "different authoring/UI placements of the identical spell, not "
                "different realm availability of it. broaderFieldSweep confirms the "
                "same tautology from three more independent angles (Quality=Poor, "
                "RequiredLevel=10, per-Tab breakdown)."),
        },
    ]

    # [Task W4-8 review follow-up] broaderFieldSweep: re-derive, on the live
    # dataset, the reviewer's independent full-field correlation sweep (Quality,
    # RequiredLevel, Tab) - every one of these resolves to the SAME Type/talent-
    # node tautology as bit 26/best_coa_bit above, not a new realm signal, but
    # they're worth surfacing as concrete numbers rather than asserted findings.
    coa = [e for e in cad if ("meta" if (e.get("Class") or "None") in META
                              else _tag(e.get("Class") or "None")) == "coa-custom"]
    poor = [e for e in coa if e.get("Quality") == "Poor"]
    poor_frac = (sum(1 for e in poor if e.get("Realms") == "100679750") / len(poor)
                if poor else 0.0)
    lvl10 = [e for e in coa if e.get("RequiredLevel") == 10]
    lvl10_frac = (sum(1 for e in lvl10 if e.get("Realms") == "100679750") / len(lvl10)
                 if lvl10 else 0.0)
    tab_frac = {}
    for e in coa:
        tab_frac.setdefault(e.get("Tab") or "", []).append(int(e.get("Realms") or 0))
    tab_frac = {
        tab: round(sum(1 for v in vs if v & (1 << best_coa_bit)) / len(vs), 4)
        for tab, vs in tab_frac.items()
    }
    other_tab_fracs = [f for t, f in tab_frac.items() if t != "Class"]
    broader_field_sweep = {
        "note": (
            "Reviewer-run correlations, re-verified against the live dataset: "
            "every one resolves back to the SAME Type/talent-node tautology "
            "identified above (hypothesis 5) - none is an independent realm "
            "signal."),
        "qualityPoor": {
            "count": len(poor),
            "fracRealms100679750": round(poor_frac, 4),
        },
        "requiredLevel10": {
            "count": len(lvl10),
            "fracRealms100679750": round(lvl10_frac, 4),
        },
        "perTabBitFraction": {
            "bit": best_coa_bit,
            "classTab": tab_frac.get("Class"),
            "otherTabsRange": [round(min(other_tab_fracs), 4),
                               round(max(other_tab_fracs), 4)] if other_tab_fracs else None,
            "otherTabsCount": len(other_tab_fracs),
        },
    }

    # [Task W4-8 review follow-up] knownAnomalies: DeathKnight's Realms
    # distribution among the 10 vanilla classes stands out - it never carries
    # the dominant vanilla value (134218784, present in all other 9) and is
    # instead dominated by near-all-1s/sparse values. Unexplained; left as a
    # documented lead for a future decode attempt, not folded into any verdict.
    vanilla_by_class = defaultdict(Counter)
    for e in cad:
        cls = e.get("Class") or "None"
        if cls in VANILLA:
            vanilla_by_class[cls][e.get("Realms", "0") or "0"] += 1
    dk_top = [v for v, _ in vanilla_by_class.get("DeathKnight", Counter()).most_common(3)]
    others_have_134218784 = {
        cls: "134218784" in c for cls, c in vanilla_by_class.items() if cls != "DeathKnight"
    }
    known_anomalies = [{
        "class": "DeathKnight",
        "finding": (
            "DeathKnight is the only one of the 10 vanilla classes with ZERO "
            "'134218784' entries (the dominant value for every other vanilla "
            "class) - its distribution is instead dominated by near-all-1s and "
            "sparse values. Unexplained; possibly a clue for a future decode "
            "attempt, not used in this task's verdict."),
        "deathKnightCount": sum(vanilla_by_class.get("DeathKnight", Counter()).values()),
        "deathKnightTop3Values": dk_top,
        "has134218784ByOtherVanillaClass": others_have_134218784,
    }]

    return {
        "_generatedBy": "tools/build_classes.py:_realms_evidence (task W4-8)",
        "task": "W4-8: decode the CAD `Realms` bitmask "
                "(DATAMINE-REQUEST.md Sec 6.2 / Sec 13 item 10)",
        "realmRoster": REALM_ROSTER,
        "totalEntries": total,
        "distinctValueCount": len(distinct),
        "distinctValues": distinct,
        "tagCounts": {t: len(vs) for t, vs in groups.items()},
        "tagTopValues": tag_top_values,
        "bitStatsByTag": bit_stats,
        "duplicationExample": duplication_example,
        "broaderFieldSweep": broader_field_sweep,
        "knownAnomalies": known_anomalies,
        "candidateHypotheses": hypotheses,
        "luaFindings": [
            {
                "file": "raw/interface/SharedXML/Enum.lua", "lines": "778-792",
                "finding": (
                    "Enum.RealmGameMode: Freepick=0, Random=1, Ironman=2, "
                    "Survivalist=3, Draft=4, Resolute=5, WildCard=6, Felforged=7, "
                    "Nightmare=8, CharacterAdvancementQualities=9, BuildDraft=10, "
                    "ConquestOfAzeroth=11, WarcraftReborn=12. "
                    "CharacterAdvancementQualities=9 explains why the CAD JSON's "
                    "own Quality/Quality_Random fields exist - a genuine, useful, "
                    "non-realms finding surfaced by this task."),
            },
            {
                "file": "raw/interface/SharedXML/Util/CustomFunctionChecks.lua",
                "lines": "31-66",
                "finding": (
                    "C_RealmSelect.RealmInfo maps realm NAME -> {realmType, "
                    "gameMode, slug, unlocked, page, index, id} for 17 dev/QA/live "
                    "realms - none named Vol'jin, Darkmoon, Dawnrise, or the "
                    "current-roster Bronzebeard/Area52/Rexxar by their LIVE names "
                    "('Rexxar - CoA Alpha - Development', not 'Rexxar - Conquest of "
                    "Azeroth' from Config.wtf). This table is stale relative to the "
                    "task's 6-realm roster and does not double as a Realms-bitmask "
                    "decode key. Rexxar's row: {0, 11, \"Rexxar\", true, 2, 2, "
                    "13977864} (gameMode=11=ConquestOfAzeroth)."),
            },
            {
                "file": "raw/interface/SharedXML/Util/Util.lua", "lines": "336-342",
                "finding": (
                    "realmId 5 or 8 remapped to 16 for '_REALM_<id>' text-key "
                    "lookups, comment: '10/04/2025 change malfurion realmID to "
                    "bronzebeard' / '8 = bronzebeard ptr' - i.e. Bronzebeard's "
                    "CURRENT numeric realm id is 16, and realm ids get reassigned/"
                    "renamed over Ascension's history (a moving target for any "
                    "static from-code decode)."),
            },
            {
                "file": "raw/interface/GlueXML/CharacterSelect.lua", "lines": "1792, 1798",
                "finding": (
                    "GetRealmId() compared against literal 11 (Area52-session "
                    "restart guard) and 8 (PTR realm check) - numeric realm ids "
                    "exist and are read at runtime, but no Lua file anywhere under "
                    "raw/interface reads the CAD `Realms` field itself (grepped "
                    "'Realms' across raw/interface/AddOns: zero hits) - it is not "
                    "client-side gated, consistent with server-side filtering "
                    "before the JSON ever reaches this snapshot."),
            },
            {
                "file": "raw/interface/FrameXML/Util/C_PVP.lua", "lines": "66-70",
                "finding": (
                    "IsLegacyWarmode(): realmID == 11 or realmID == 4 - a second, "
                    "unrelated pairing of numeric realm ids with no name attached "
                    "anywhere in the client code available here."),
            },
        ],
        "verdict": {
            "goldenBarMet": False,
            "goldenBarText": (
                "a bit assignment must correctly classify >=3 independent known "
                "groups (reborn/Bronzebeard, coa-custom/Vol'jin+Rexxar, "
                "vanilla/Area 52)"),
            "groupsSatisfied": [],
            "groupsCircumstantial": [
                "reborn (bit 16 tracks the client-code Bronzebeard realm-id "
                "citation, but is not proven - see hypotheses)"],
            "groupsUnresolved": ["coa-custom (Vol'jin/Rexxar)", "vanilla (Area 52)",
                                  "Darkmoon", "Dawnrise"],
            "realmFlagsEmitted": False,
            "authoringContextEvidence": (
                "duplicationExample's 3 CAD rows for one ability differ on `Tab` "
                "and `Flags`, not just `Realms` - direct, row-level proof that the "
                "field tracks authoring/UI placement, not realm availability."),
            "recommendedFollowUp": (
                "An in-game /dump of a known CoA-only ability's CAD entry on both "
                "Vol'jin and Rexxar (or a server-side query) is the only way left "
                "to confirm any bit's identity - offline analysis is exhausted."),
        },
    }


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
    # [Task W4-5] filename fallback join (DATAMINE-REQUEST.md Sec 11 / Sec 4 trap 6):
    # 3 CAD class dirs (DemonHunter/Monk/SonOfArugal) have no ChrClasses row matching
    # their display name at all - their content is filed under a DIFFERENT display
    # name (Felsworn/Templar/Bloodmage, ChrClasses ids 14/19/20) whose `filename`
    # column equals the CAD class name instead. Falling back to a filename join
    # (only tried when the display-name join misses) resolves all 3 - see
    # tools/dbc.py's TABLE_MAPS comment for the golden evidence.
    chr_by_filename = {_norm(c["filename"]): c for c in chr_classes}

    groups = defaultdict(list)
    for e in cad:
        cls = e.get("Class") or "None"
        groups["_other" if cls in META else cls].append(e)

    # Amendment D (single-writer ownership): this builder owns only the per-class
    # subdirectories, the top-level index.json, and (task W4-8) _realms_evidence.json
    # it writes below - NOT the whole data/classes/ directory. build_classmeta.py's
    # specs.json/archetypes.json live alongside these and must survive a
    # build_classes rerun untouched.
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
        base_cls = cls.removeprefix("Reborn") if cls.startswith("Reborn") else cls
        chr_match = None if cls == "_other" else (
            chr_by_norm.get(_norm(base_cls)) or chr_by_filename.get(_norm(base_cls)))
        # [Task W4-5] ClassRemap aliases (raw/interface/FrameXML/Data/
        # CharacterAdvancement.lua): when the matched row's `filename` token isn't
        # just an uppercase of this CAD class's own name, it's a real alias the
        # client's own ClassRemap table carries (Runemaster->SPIRITMAGE, Primalist->
        # WILDWALKER, Venomancer->PROPHET, "Knight of Xoroth"->FLESHWARDEN) - record
        # it. The 3 filename-only matches (DemonHunter/Monk/SonOfArugal) do NOT
        # alias here by construction (their filename IS their own normalized name -
        # that's how the fallback matched them in the first place).
        alias = None
        if chr_match:
            matched_norms.add(_norm(chr_match["name_enUS"]))
            if _norm(chr_match["filename"]) != _norm(base_cls):
                alias = chr_match["filename"]
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
            "aliases": [alias] if alias else [],
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
            "aliases": [alias] if alias else [],
            "realmHint": realm_hint,
            "dir": f"{cls}/",
            "index": f"{cls}/index.json",
            "entryCounts": dict(Counter(x["type"] for x in entries)),
            "unresolvedCount": class_unresolved,
        })

    index = {
        "classes": index_classes,
        "chrClasses": [{"id": c["id"], "name": c["name_enUS"], "filename": c["filename"],
                        "powerType": c["powerType"]} for c in chr_classes],
        "unmatchedChrClasses": sorted(c["name_enUS"] for c in chr_classes
                                      if _norm(c["name_enUS"]) not in matched_norms),
    }
    (cdir / "index.json").write_text(sharding.dump_manifest(index), encoding="utf-8")

    # [Task W4-8] Realms-bitmask decode attempt (DATAMINE-REQUEST.md Sec 6.2) -
    # see _realms_evidence()'s docstring for the verdict. Evidence-only: does NOT
    # touch any class entry's raw `realms` field (still e.get("Realms", "") above,
    # unchanged) since nothing cleared the golden bar.
    realms_evidence = _realms_evidence(cad)
    (cdir / "_realms_evidence.json").write_text(
        json.dumps(realms_evidence, indent=1, sort_keys=True, ensure_ascii=False),
        encoding="utf-8")

    return {"classes": len(index_classes), "entries": total_entries,
            "unresolved_reborn": unresolved_reborn, "unresolved_other": unresolved_other,
            "refs_reborn": refs_reborn, "refs_other": refs_other,
            "realmsBitmaskGoldenBarMet": realms_evidence["verdict"]["goldenBarMet"]}


if __name__ == "__main__":
    print(build())
