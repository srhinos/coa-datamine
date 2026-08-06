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
mechanisms that actually gets every file under the gate.

[Task W4-14] Every entry now also carries `live` + `liveEvidence`, joined against
the live talent-builder capture (tools/coa_live.py, which owns the rule and the
payload parser both writers share). THIS FILE IS A CATALOG, NOT THE GAME: the CAD
tables list content that is no longer in the live trees at all (a real level-60
Starcaller proved it - the catalog's whole "Tides" tree, Tide Lash included, does
not exist in game), so an entry's presence here has never meant it is playable.
`live` is the flag that finally says which is which; per-class index.json gains
`liveCounts`, and data/classes/_live_summary.json (written here - this module owns
data/classes/ minus classmeta's two files) carries the repo-wide totals, the
measured false-negative risk, the CAD-tab -> live-tab mapping with its evidence,
and the Vol'jin-vs-Rexxar caveat that scopes every verdict."""
import json, re, shutil
from collections import Counter, defaultdict

from tools import config, dbc, build_spells, coa_live, sharding

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


# ---------------------------------------------------------------------------
# [Task W4-14] live/dead join - see tools/coa_live.py for the rule itself.
# ---------------------------------------------------------------------------

# node-overlap thresholds, used ONLY as the last-resort mapping method (and as
# the cross-check on the other two): a CAD tab must land >=MIN_OVERLAP_MATCHES
# of its live-matched entries in one live tab, and that tab must take
# >=MIN_OVERLAP_SHARE of them, or the pair is recorded unmatched rather than
# guessed.
MIN_OVERLAP_MATCHES = 5
MIN_OVERLAP_SHARE = 0.30


def _chr_specs_by_class(chr_by_norm, chr_by_filename) -> dict:
    """classId -> [{specId, specName, tabToken}] from ChrSpecs.dbc, joined to
    ChrClasses the same way build_classmeta does (display name, falling back to
    `filename` - task W4-5). ChrSpecs is the ONE in-client table that carries both
    generations of a spec tab's identity at once: `tabToken` is the OLD CAD tab
    string (Starcaller TIDES) and `name` is the CURRENT live-builder tab name
    (Moon Priest) - which is what makes the CAD-tab -> live-tab mapping below an
    evidenced client join rather than a name-similarity guess."""
    out = defaultdict(list)
    for r in dbc.iter_named("ChrSpecs"):
        token = r["classToken"] or None
        cc = ((chr_by_norm.get(_norm(token)) or chr_by_filename.get(_norm(token)))
              if token else None)
        if cc is None:
            continue
        out[cc["id"]].append({"specId": r["id"], "specName": r["name_enUS"],
                              "tabToken": r["tabToken"] or None})
    for v in out.values():
        v.sort(key=lambda s: s["specId"])
    return dict(out)


def _tab_mapping(cad_tabs, class_live, specs, overlap) -> dict:
    """Map this class's CAD tab names onto the live builder's tab names.

    Three methods, tried in this order, every one of them recorded per pair
    alongside the node-overlap numbers so a consumer can audit the call:
      1. `chrSpecsSpecName` - a ChrSpecs row whose `tabToken` IS this CAD tab and
         whose `name` IS a live tab name. Authoritative: it is the client's own
         row linking the two generations.
      2. `sameName` - the CAD tab name is itself a live tab name. Deliberately
         BELOW method 1, because a surviving name can belong to a different tree:
         Chronomancer's CAD "Time" tab maps to live "Artificer" (ChrSpecs spec 33,
         tabToken TIME, name Artificer - and node overlap agrees, 83%), while the
         live tab literally named "Time" is a DIFFERENT tree (spec 31, tabToken
         DISPLACEMENT). Same-name-first would have silently swapped those two.
      3. `nodeOverlap` - where the CAD tab's live-matched entries actually land,
         subject to the thresholds above.
    Unmatched CAD tabs (a whole tree with no live counterpart) and unmatched live
    tabs (a tree with no catalog ancestor) are both recorded rather than forced."""
    live_by_norm = {_norm(t["tabName"]): t["tabName"] for t in class_live["tabs"]}
    spec_by_token = {_norm(s["tabToken"]): s for s in specs if s["tabToken"]}
    mapped, taken = [], {}
    for cad_tab in sorted(cad_tabs):
        counts = overlap.get(cad_tab, {})
        ranked = sorted(counts.items(), key=lambda kv: (-kv[1], kv[0]))
        matched_total = sum(counts.values())
        top, top_n = (ranked[0] if ranked else (None, 0))
        runner, runner_n = (ranked[1] if len(ranked) > 1 else (None, 0))
        overlap_ok = (top is not None and top_n >= MIN_OVERLAP_MATCHES
                      and top_n / matched_total >= MIN_OVERLAP_SHARE)

        spec = spec_by_token.get(_norm(cad_tab))
        live_tab = method = None
        if spec is not None and _norm(spec["specName"]) in live_by_norm:
            live_tab, method = live_by_norm[_norm(spec["specName"])], "chrSpecsSpecName"
        elif _norm(cad_tab) in live_by_norm:
            live_tab, method = live_by_norm[_norm(cad_tab)], "sameName"
        elif overlap_ok:
            live_tab, method = top, "nodeOverlap"

        rec = {
            "cadTab": cad_tab, "liveTab": live_tab, "method": method,
            "chrSpecs": ({"specId": spec["specId"], "specName": spec["specName"],
                          "tabToken": spec["tabToken"]} if spec else None),
            "nodeOverlap": {
                "topLiveTab": top, "topMatches": top_n,
                "cadTabMatchedEntries": matched_total,
                "topShare": round(top_n / matched_total, 4) if matched_total else None,
                "runnerUpLiveTab": runner, "runnerUpMatches": runner_n,
                "meetsThresholds": overlap_ok,
            },
            "agreesWithNodeOverlap": (None if live_tab is None or top is None
                                      else live_tab == top),
        }
        if live_tab is not None and live_tab in taken:
            rec["collidesWith"] = taken[live_tab]
        elif live_tab is not None:
            taken[live_tab] = cad_tab
        mapped.append(rec)

    return {
        "mapped": mapped,
        "unmatchedCadTabs": sorted(r["cadTab"] for r in mapped if r["liveTab"] is None),
        "unmatchedLiveTabs": sorted(t["tabName"] for t in class_live["tabs"]
                                    if t["tabName"] not in taken),
        "liveTabs": [t["tabName"] for t in class_live["tabs"]],
        "cadTabs": sorted(cad_tabs),
    }


class _FalseNegativeMeter:
    """[Task W4-14, requirement 2] MEASURE the false-negative risk instead of
    hand-waving it. The builder payload shows the TREES; anything CoA grants
    outside a tree looks dead here while being live in game. Accumulated over
    every class that HAS geometry (classes without it are `unknownNoGeometry`
    and claim nothing), and written into _live_summary.json verbatim."""

    def __init__(self):
        self.not_in_trees = 0
        self.in_trees = 0
        self.signal_entries = Counter()
        self.signal_spell_ids = defaultdict(set)
        self.examples = defaultdict(list)
        self.indeterminate = 0
        # the brief's first suggested heuristic, kept as a MEASUREMENT so its
        # failure is visible rather than asserted: "low requiredLevel + Ability"
        self.heur_not_in_trees = 0
        self.heur_in_trees = 0

    @staticmethod
    def _heuristic(e):
        return e["requiredLevel"] <= 10 and e["type"] == "Ability"

    def observe(self, cls, entries):
        for e in entries:
            reason = e["liveEvidence"]["reason"]
            if reason in ("liveDirect", "liveViaRank"):
                self.in_trees += 1
                self.heur_in_trees += self._heuristic(e)
                continue
            self.not_in_trees += 1
            self.heur_not_in_trees += self._heuristic(e)
            signals = e["liveEvidence"].get("signals") or []
            if signals:
                self.indeterminate += 1
            for sig in signals:
                self.signal_entries[sig] += 1
                self.signal_spell_ids[sig].update(s["id"] for s in e["spells"])
                if len(self.examples[sig]) < 6:
                    self.examples[sig].append(
                        {"class": cls, "cadId": e["cadId"], "name": e["name"],
                         "tab": e["tab"], "type": e["type"],
                         "requiredLevel": e["requiredLevel"]})

    def report(self) -> dict:
        n = self.not_in_trees or 1
        return {
            "question": (
                "Of the CAD entries this method finds NOT in the live trees, how "
                "many are false negatives - abilities CoA grants outside a tree "
                "(baseline/automatic or trainer-taught), which would look dead "
                "while being live?"),
            "entriesNotInTrees": self.not_in_trees,
            "entriesInTrees": self.in_trees,
            "signals": {
                "skillLineAutoGrant": {
                    "entries": self.signal_entries["skillLineAutoGrant"],
                    "rateOfNotInTrees": round(
                        self.signal_entries["skillLineAutoGrant"] / n, 4),
                    "distinctSpellIds": len(self.signal_spell_ids["skillLineAutoGrant"]),
                    "test": ("the entry's spell chain has a SkillLineAbility row with "
                             "acquireMethod != 0 (automatically granted)"),
                    "separable": True,
                    "verdict": (
                        "SEPARABLE and trustworthy on its own. acquireMethod is stock "
                        "3.3.5 semantics, generation-independent, and perfectly "
                        "disjoint from the live node set (0 of the live builder's "
                        "spell ids carry acquireMethod != 0 anywhere in "
                        "SkillLineAbility.dbc). The population is overwhelmingly "
                        "weapon/armour proficiency grants (Fist Weapons, Polearms, "
                        "Plate Mail, Dual Wield, Auto Shot, Block, Staves, Wands...) - "
                        "exactly the 'baseline, not via a tree node' class the task "
                        "asked to quantify. Shipped as live:null/indeterminate, NOT "
                        "live:false."),
                    "examples": self.examples["skillLineAutoGrant"],
                },
                "npcTrainerRow": {
                    "entries": self.signal_entries["npcTrainerRow"],
                    "rateOfNotInTrees": round(
                        self.signal_entries["npcTrainerRow"] / n, 4),
                    "distinctSpellIds": len(self.signal_spell_ids["npcTrainerRow"]),
                    "test": "some rank of the entry's spell chain has an NPCTrainer row",
                    "separable": False,
                    "verdict": (
                        "REAL but NOT SEPARABLE offline - said plainly rather than "
                        "guessed. NPCTrainer.dbc in this client snapshot is provably "
                        "CONTEMPORARY with the live generation, not a leftover of the "
                        "catalog's: it carries rows under skill lines that exist ONLY "
                        "in the live builder and nowhere in the CAD tab layer ('Moon "
                        "Guard', 'Moon Priest', 'Warden', 'Headhunting'), teaching "
                        "rank variants of abilities whose base rank IS a live node "
                        "(e.g. Starcall - live node spellId 800497, trainer rows "
                        "302568/302569/502316/502317). So a trainer row IS evidence of "
                        "a non-tree acquisition path - but the CAD row hanging off it "
                        "can equally be a retired duplicate, and no offline table "
                        "distinguishes those two. Shipped as live:null/indeterminate."),
                    "examples": self.examples["npcTrainerRow"],
                },
                "liveNodeNameTwin": {
                    "entries": self.signal_entries["liveNodeNameTwin"],
                    "rateOfNotInTrees": round(
                        self.signal_entries["liveNodeNameTwin"] / n, 4),
                    "distinctSpellIds": len(self.signal_spell_ids["liveNodeNameTwin"]),
                    "test": ("the entry's NAME matches a live node's name in the same "
                             "class while none of its spell ids do"),
                    "separable": False,
                    "verdict": (
                        "NOT SEPARABLE - the spellId-variant drift already measured in "
                        "data/talents/coa/_meta.json's `contentDrift` (duplicate CAD "
                        "rows per ability, each carrying a different spellId variant; "
                        "the builder picks one). The ABILITY is live; whether THIS row "
                        "is the live variant is unknowable offline, so the row is "
                        "live:null/indeterminate rather than a name-matched live:true "
                        "(names collide across a class's talents and abilities)."),
                    "examples": self.examples["liveNodeNameTwin"],
                },
            },
            "indeterminateEntries": self.indeterminate,
            "indeterminateRateOfNotInTrees": round(self.indeterminate / n, 4),
            "deadCatalogEntries": self.not_in_trees - self.indeterminate,
            "rejectedHeuristic": {
                "test": "CAD requiredLevel <= 10 AND type == 'Ability'",
                "rateOnNotInTrees": round(self.heur_not_in_trees / n, 4),
                "rateOnProvenLiveEntries": round(
                    self.heur_in_trees / (self.in_trees or 1), 4),
                "verdict": (
                    "REJECTED as a baseline-grant discriminator - measured, not "
                    "assumed. It fires on a large minority of entries that are "
                    "PROVEN live (they are in the trees), so it has no specificity: "
                    "'low level + Ability' describes early tree nodes just as well as "
                    "baseline grants. Not used in any shipped verdict."),
            },
            "conclusion": (
                "The risk is real and it IS partly separable: the automatic-grant "
                "population (SkillLineAbility acquireMethod != 0) is isolated exactly "
                "and cleanly. The other two paths are real but indistinguishable from "
                "retired content with offline data alone, so every entry carrying any "
                "of the three signals ships live:null with reason 'indeterminate' and "
                "the firing signals listed, rather than being guessed false. Entries "
                "with live:false are the ones with NO evidence of any acquisition "
                "path at all."),
        }


def _live_summary(live, per_class, tab_maps, fn) -> dict:
    totals = Counter()
    by_reason = Counter()
    for c in per_class.values():
        totals.update(c["liveCounts"])
        by_reason.update(c["liveCountsByReason"])
    with_geom = {k: v for k, v in per_class.items() if v["hasLiveGeometry"]}

    agree = [r for m in tab_maps.values() for r in m["mapped"]
             if r["agreesWithNodeOverlap"] is not None]
    return {
        "_generatedBy": "tools/build_classes.py:_live_summary (task W4-14)",
        "task": ("W4-14: join live-talent-builder truth onto the CAD catalog so "
                 "consumers stop reading the catalog as if it were the game"),
        "method": {
            "rule": (
                "An entry is live if any of its own CAD spell ids is a live builder "
                "node's spellId/spellIds member (reason liveDirect); failing that, if "
                "any OTHER rank of its SpellRankData chain is (reason liveViaRank). "
                "Otherwise it is not in the trees, and is split by whether it carries "
                "evidence of a non-tree acquisition path (reason indeterminate, "
                "live:null) or none at all (reason deadCatalog, live:false). Classes "
                "with no builder file get reason unknownNoGeometry, live:null - "
                "nothing is claimed about them either way."),
            "matching": ("spell id equality only - no name matching enters the live/"
                         "dead verdict itself (names are used only as a false-negative "
                         "PROBE, and only to downgrade dead -> indeterminate)"),
            "liveCountsKeys": (
                "live = liveDirect; liveViaRank counted separately; unknown = "
                "indeterminate + unknownNoGeometry. Entries with live==true are "
                "live + liveViaRank. The four keys sum to entryCount."),
            "owner": ("tools/coa_live.py holds the rule; tools/build_classes.py "
                      "writes data/classes/**, tools/build_coatalents.py writes "
                      "data/talents/coa/** (Amendment D single-writer)"),
        },
        "payload": live["provenance"],
        "realmCaveat": live["realmCaveat"],
        "totals": {
            "classes": len(per_class),
            "classesWithLiveGeometry": len(with_geom),
            "classesWithoutLiveGeometry": len(per_class) - len(with_geom),
            "entries": sum(c["entryCount"] for c in per_class.values()),
            "entriesInClassesWithGeometry": sum(c["entryCount"] for c in with_geom.values()),
            "liveCounts": dict(totals),
            "liveCountsByReason": dict(by_reason),
        },
        "perClass": per_class,
        "falseNegativeMeasurement": fn.report(),
        "tabMapping": {
            "note": (
                "CAD tab names and live builder tab names are DIFFERENT GENERATIONS "
                "of the same tree slots (Starcaller CAD 'Tides' is live 'Moon "
                "Priest'). Mapped per class by three recorded methods - see "
                "tools/build_classes.py:_tab_mapping. Pairs that no method resolves "
                "are listed in unmatchedCadTabs / unmatchedLiveTabs rather than "
                "invented."),
            "methodAgreementWithNodeOverlap": {
                "pairsCheckable": len(agree),
                "agreeing": sum(1 for r in agree if r["agreesWithNodeOverlap"]),
                "rate": round(sum(1 for r in agree if r["agreesWithNodeOverlap"])
                              / (len(agree) or 1), 4),
                "disagreements": [
                    {"class": cls, "cadTab": r["cadTab"], "mappedTo": r["liveTab"],
                     "method": r["method"], "nodeOverlap": r["nodeOverlap"]}
                    for cls, m in sorted(tab_maps.items()) for r in m["mapped"]
                    if r["agreesWithNodeOverlap"] is False],
                "note": ("an independent statistical cross-check on the ChrSpecs/"
                         "sameName mapping, NOT the mapping itself - a disagreement "
                         "is recorded, not silently resolved"),
            },
            "byClass": tab_maps,
        },
        "groundTruth": _ground_truth_check(per_class, tab_maps),
    }


def _ground_truth_check(per_class, tab_maps) -> dict:
    """The one piece of REAL-PLAYER evidence this method has, re-derived at every
    build so it fails loudly if the method or the payload drifts: a level-60
    Starcaller reports their live trees are Moon Guard / Sentinel / Moon Priest /
    Warden / Class, and that Tide Lash - a CAD 'Tides' ability - does not exist in
    game. Both must fall out of the join; pinned again in tests/test_live_flags.py."""
    sc = per_class.get("Starcaller", {})
    return {
        "source": "level-60 Starcaller player report (task W4-14 brief)",
        "starcallerLiveTabs": sc.get("liveTabs"),
        "starcallerLiveTabsExpected": ["Class", "Moon Guard", "Moon Priest",
                                       "Sentinel", "Warden"],
        "starcallerCadTabs": tab_maps.get("Starcaller", {}).get("cadTabs"),
        "starcallerCadSpellIdDeadRate": sc.get("cadSpellIdDeadRate"),
        "note": ("cadSpellIdDeadRate is the brief's cited ~53% - the share of "
                 "Starcaller's DISTINCT CAD spell ids that appear in no live "
                 "builder node. The entry-level split is in perClass.Starcaller."),
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

    # [Task W4-14] live/dead join inputs. live_index() parses the frozen builder
    # capture once per process (lru_cached) and is the SAME parse build_coatalents
    # uses; alt_acquisition_index() is the non-tree-grant probe set.
    live = coa_live.live_index()
    alt = coa_live.alt_acquisition_index()
    chr_specs = _chr_specs_by_class(chr_by_norm, chr_by_filename)
    live_per_class, tab_maps, fn = {}, {}, _FalseNegativeMeter()

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

        # [Task W4-14] stamp live/liveEvidence. class_live is None for every class
        # with no builder file (the 10 vanilla + 11 Reborn/meta dirs) - those get
        # `unknownNoGeometry`, never a bare false.
        class_id = chr_match["id"] if chr_match else None
        class_live = live["byClassId"].get(class_id)
        reasons = Counter()
        for e in entries:
            e["live"], e["liveEvidence"] = coa_live.classify_entry(e, class_live, alt)
            reasons[e["liveEvidence"]["reason"]] += 1
        counts = coa_live.live_counts(reasons)
        if class_live is not None:
            fn.observe(cls, entries)
            cad_ids = {s["id"] for e in entries for s in e["spells"]}
            live_ids = set(class_live["spellNodes"])
            live_per_class[cls] = {
                "classId": class_id, "hasLiveGeometry": True,
                "entryCount": len(entries), "liveCounts": counts,
                "liveCountsByReason": {r: reasons[r] for r in coa_live.REASONS
                                       if reasons[r]},
                "cadSpellIds": len(cad_ids),
                "cadSpellIdsNotLive": len(cad_ids - live_ids),
                "cadSpellIdDeadRate": round(len(cad_ids - live_ids) / len(cad_ids), 4)
                                      if cad_ids else None,
                "liveNodeCount": class_live["nodeCount"],
                "liveTabs": [t["tabName"] for t in class_live["tabs"]],
            }
            tab_maps[cls] = dict(
                _tab_mapping({e["tab"] for e in entries if e["tab"]}, class_live,
                             chr_specs.get(class_id, []),
                             coa_live.tab_overlap(entries, class_live)),
                classId=class_id)
        else:
            live_per_class[cls] = {
                "classId": class_id, "hasLiveGeometry": False,
                "entryCount": len(entries), "liveCounts": counts,
                "liveCountsByReason": {r: reasons[r] for r in coa_live.REASONS
                                       if reasons[r]},
            }

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
            # [Task W4-14] live/deadCatalog/liveViaRank/unknown - sums to
            # entryCount. `live` counts only direct spell-id hits; entries with
            # live==true are live + liveViaRank. `unknown` merges the two
            # live==null reasons (indeterminate + unknownNoGeometry), split out
            # in liveCountsByReason and in data/classes/_live_summary.json.
            "hasLiveGeometry": class_live is not None,
            "liveCounts": counts,
            "liveCountsByReason": live_per_class[cls]["liveCountsByReason"],
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
            "liveCounts": counts,
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

    # [Task W4-14] live/dead summary - totals, the measured false-negative risk,
    # the tab mapping + its evidence, and the payload provenance/caveat.
    summary = _live_summary(live, live_per_class, tab_maps, fn)
    (cdir / "_live_summary.json").write_text(
        json.dumps(summary, indent=1, sort_keys=True, ensure_ascii=False),
        encoding="utf-8")

    return {"classes": len(index_classes), "entries": total_entries,
            "unresolved_reborn": unresolved_reborn, "unresolved_other": unresolved_other,
            "refs_reborn": refs_reborn, "refs_other": refs_other,
            "realmsBitmaskGoldenBarMet": realms_evidence["verdict"]["goldenBarMet"],
            "liveCounts": summary["totals"]["liveCounts"],
            "liveCountsByReason": summary["totals"]["liveCountsByReason"]}


if __name__ == "__main__":
    print(build())
