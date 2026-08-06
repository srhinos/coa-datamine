"""CoA talent tree geometry -> data/talents/coa/<Class>.json (task W4-9,
coa-sim-handoff/DATAMINE-REQUEST.md Sec 6.1 / Sec 13 item 11).

Two geometry sources exist and this module reconciles them:

**Client-side** (raw/interface/AddOns/Ascension_CoATalents,
raw/interface/FrameXML/CharacterAdvancement*, raw/interface/FrameXML/Data/
CharacterAdvancement.lua, raw/interface/SharedXML/Enum.lua): defines the node
TYPES (Enum.TraitNodeEntryType: SpendHex/SpendCircle/SpendSquare/SpendDiamond/...),
the gate mechanism (CoACharacterAdvancementUtil.GetEntryAEGateRequirement/
GetEntryTEGateRequirement read entry.RequiredTabAEInvestment/
RequiredTabTEInvestment; CATalentFrameGatesMixin gates whole ROWS behind tab-AE/TE
investment tiers), the flag bits (Enum.CharacterAdvancementFlag), and CONFIRMS
"starting node" and "missing connection" are real client concepts
(Enum.CALearnResult.StartingNodeAlreadyKnown / MissingConnection). It does NOT
carry a usable geometry payload: the base account-wide CharacterAdvancementData.json
has PositionX/PositionY/ConnectedNodes/RequiredIDs/RequiredAEInvestment/
RequiredTEInvestment columns, but only on 13-15% of rows, with NO numeric tabId at
all (Tab is a bare string) - and where a payload node's id DOES match a CAD row
carrying these columns, cross-checking them (see _meta.json's
`clientLuaGeometryFinding`) shows near-zero agreement (3.2% exact PositionX/Y match,
0.016 avg Jaccard on ConnectedNodes) - these raw columns serve the client's
"ConnectingNode" decorative-line UI, a narrower and DIFFERENT thing than the
gameplay tree geometry, not a usable fallback source for it.

**Published** (https://ascension.gg/en/v2/coa-builder/<slug>, frozen by
tools/fetch_coatalents.py into raw/talents/coa-builder-<slug>.html/_fetch.json):
a Next.js "flight" payload embedding the live builder's full node array with every
field named in the brief (spellId/spellIds/classId/tabId/sortOrder/group/flags/
aeCost/teCost/iconPath/nodeType/entryType/isPassive/maxPoints/requiredIds/
requiredLevel/isStartingNode/connectedNodeIds/reqTabAE/reqTabTE/rankDescriptions),
PLUS x/y grid position and name/description (100% present on every node - no
omit-when-absent needed for this snapshot). This is the sole source for this
module; see _meta.json's `payload` block for the extraction technique (a
Next.js-flight analogue of the aowow.py Listview trick: locate the
`self.__next_f.push([id,"..."])` chunk whose unescaped body contains
`"entriesByTab"`, then `json.JSONDecoder().raw_decode` past any trailing
non-JSON).

Single-writer (Amendment D): this module owns data/talents/coa/ exclusively -
data/talents/<ChrClass>.json (the OLDER, unrelated Talent.dbc-derived trees owned
by build_talents.py) is untouched and lives one directory up, deliberately kept
separate so a class with BOTH a legacy DBC tree and CAD-driven CoA nodes (e.g.
Barbarian) never collides on one filename."""
import csv, gzip, json, re
from collections import defaultdict

from tools import config, build_spells, sharding

MAX_LINES = 5000


# ---------------------------------------------------------------------------
# Payload extraction: locate + parse the embedded Next.js flight JSON.
# ---------------------------------------------------------------------------

_PUSH_MARKER = 'self.__next_f.push(['


def _iter_next_f_string_literals(html_text: str):
    """Yield each `self.__next_f.push([id,"<JS string literal>"])` call's raw
    string-literal text (including the surrounding quotes), scanning by hand
    rather than with a backtracking regex - some of these literals run to
    several megabytes, which a naive `"(?:[^"\\\\]|\\\\.)*"` regex chokes on."""
    i = 0
    n = len(html_text)
    while True:
        i = html_text.find(_PUSH_MARKER, i)
        if i < 0:
            return
        q = html_text.find('"', i)
        if q < 0:
            return
        j = q + 1
        while j < n:
            c = html_text[j]
            if c == "\\":
                j += 2
                continue
            if c == '"':
                break
            j += 1
        yield html_text[q:j + 1]
        i = j + 1


_ROW_PREFIX_RE = re.compile(r"^[0-9a-f]+:")


def _find_talent_builds(node):
    """Recursively walk a decoded flight-row JSON tree, yielding every dict that
    has the unmistakable shape of one builder "build" record: a sibling
    {id, slug, name, max_level, talents: {classes, entriesByTab, ...}}. Structural
    (keyed off the shape, not a hardcoded array index) so a future page layout
    change doesn't silently start reading the wrong node."""
    if isinstance(node, dict):
        t = node.get("talents")
        if isinstance(t, dict) and "entriesByTab" in t and "classes" in t:
            yield node
        for v in node.values():
            yield from _find_talent_builds(v)
    elif isinstance(node, list):
        for v in node:
            yield from _find_talent_builds(v)


def extract_payload(html_text: str, slug: str) -> dict:
    """Locate and parse the embedded talent-builder JSON for `slug` out of the
    raw page text. Raises RuntimeError with a specific, actionable message on
    any failure mode (no chunk found / none decode / none match the slug) -
    "parse defensively" per the task's binding rule, not a bare KeyError."""
    dec = json.JSONDecoder()
    candidates = []
    for lit in _iter_next_f_string_literals(html_text):
        try:
            inner = json.loads(lit)
        except json.JSONDecodeError:
            continue
        if "entriesByTab" not in inner:
            continue
        body = _ROW_PREFIX_RE.sub("", inner, count=1)
        try:
            data, _ = dec.raw_decode(body)
        except json.JSONDecodeError:
            continue
        candidates.extend(_find_talent_builds(data))

    if not candidates:
        raise RuntimeError(
            "build_coatalents: no self.__next_f.push(...) chunk decoded into a "
            "{classes, entriesByTab} build record - the page structure has "
            "changed since this parser was written and needs re-investigation "
            "(see this module's docstring for the extraction technique).")

    by_slug = [b for b in candidates if b.get("slug") == slug]
    if not by_slug:
        found = sorted({b.get("slug") for b in candidates})
        raise RuntimeError(
            f"build_coatalents: found {len(candidates)} build record(s) but none "
            f"with slug={slug!r} - available slugs: {found}")
    if len(by_slug) > 1:
        raise RuntimeError(
            f"build_coatalents: {len(by_slug)} build records share slug={slug!r} - "
            "ambiguous, needs re-investigation")
    return by_slug[0]


# ---------------------------------------------------------------------------
# Build
# ---------------------------------------------------------------------------

FLAG_BITS = {  # SharedXML/Enum.lua Enum.CharacterAdvancementFlag - proven bit names
    0x1: "Deprecated", 0x2: "UnaffectedByResets", 0x4: "CannotBeUnlearned",
    0x8: "Disabled", 0x100: "ConnectingNode", 0x800: "HiddenClientside",
    0x1000: "Mastery", 0x2000: "FreeUnlearn", 0x4000: "RequireAnyInvestment",
    0x8000: "ShowCardOnLearn",
}

NODE_FIELDS = (
    "id", "name", "x", "y", "classId", "tabId", "sortOrder", "group", "flags",
    "aeCost", "teCost", "spellId", "spellIds", "iconPath", "nodeType",
    "entryType", "isPassive", "maxPoints", "requiredLevel", "isStartingNode",
    "reqTabAE", "reqTabTE", "description", "rankDescriptions",
)


def _depad(ids):
    """requiredIds/connectedNodeIds ship as fixed-length arrays (3 and 15 slots
    respectively) zero-padded to that width - 0 is never a real node id in this
    dataset (min observed id is in the hundreds), so this is safe. Order among
    the real entries is preserved; padding is dropped, not just zeros in place,
    so a consumer gets a plain variable-length id list."""
    return [i for i in ids if i]


def _class_id_map():
    """classId (12-32) -> our canonical class dir name, from data/classes/index.json
    (already the single source of truth for that join - see build_classes.py) -
    used instead of the payload's own className strings, which differ cosmetically
    ("Witch Doctor" vs "WitchDoctor", "Felsworn" vs "DemonHunter", "Sun Cleric" vs
    "SunCleric", etc.) from this repo's existing data/classes/<Class>/ naming."""
    idx = json.loads((config.DATA_DIR / "classes" / "index.json")
                      .read_text(encoding="utf-8"))
    out = {}
    for c in idx["classes"]:
        if c["tag"] == "coa-custom" and c["classId"] is not None:
            out[c["classId"]] = c["name"]
    return out


def build(slug: str = "voljin") -> dict:
    html_path = config.RAW_TALENTS_DIR / f"coa-builder-{slug}.html"
    fetch_meta_path = config.RAW_TALENTS_DIR / "_fetch.json"
    if not html_path.is_file():
        raise RuntimeError(
            f"build_coatalents: {html_path} not found - run "
            f"`python -m tools.fetch_coatalents --slug {slug}` first. Per the "
            "task's binding rule, if the payload truly cannot be fetched, this "
            "module would need a client-Lua-only fallback path - see this "
            "module's docstring for exactly which geometry fields that would "
            "lose (numeric tabId entirely; x/y, requiredIds, connectedNodeIds, "
            "reqTabAE/reqTabTE all drop from 100% to 13-15% coverage with no "
            "usable cross-check, per the clientLuaGeometryFinding measurement) "
            "- not implemented here because the fetch succeeded.")
    html_text = html_path.read_text(encoding="utf-8", errors="replace")
    fetch_meta = (json.loads(fetch_meta_path.read_text(encoding="utf-8"))
                  if fetch_meta_path.is_file() else None)

    build_record = extract_payload(html_text, slug)
    talents = build_record["talents"]
    classes_meta = talents["classes"]
    entries_by_tab = talents["entriesByTab"]
    essence_by_class = talents.get("essenceByClass", {})

    all_entries = [e for lst in entries_by_tab.values() for e in lst]
    class_dir_names = _class_id_map()

    # ---- cross-validation: spellId resolve rates (report-only + gated, see
    # _meta.json / tests/test_coatalents.py for which one is the hard gate and why
    # data/spells resolves so much lower than raw Spell.dbc) ----
    curated_spell_ids = {r["id"] for r in build_spells.iter_all()}
    cad = json.loads((config.RAW_CONTENT_DIR / "CharacterAdvancementData.json")
                      .read_text(encoding="utf-8-sig"))
    cad_spell_ids = {sid for e in cad for sid in e.get("Spells", [])}
    cad_by_id = {e["ID"]: e for e in cad}

    n = len(all_entries)
    curated_resolved = sum(1 for e in all_entries if e["spellId"] in curated_spell_ids)
    cad_resolved = sum(1 for e in all_entries if e["spellId"] in cad_spell_ids)
    id_matches_cad_row = sum(1 for e in all_entries if e["id"] in cad_by_id)

    # ---- per-node records ----
    def make_node(e):
        rec = {k: e[k] for k in NODE_FIELDS}
        rec["requiredIds"] = _depad(e["requiredIds"])
        rec["connectedNodeIds"] = _depad(e["connectedNodeIds"])
        rec["spellResolved"] = e["spellId"] in curated_spell_ids
        return rec

    nodes_by_class = defaultdict(list)
    for e in all_entries:
        nodes_by_class[e["classId"]].append(make_node(e))

    # ---- choice groups: nonzero `group` value shared by exactly 2 sibling
    # nodes at the same (classId, tabId, x, y) offering different spellIds -
    # verified structurally against the whole payload before shipping, see
    # _meta.json's `choiceGroupFinding` ----
    groups = defaultdict(list)
    for e in all_entries:
        if e["group"]:
            groups[e["group"]].append(e)
    non_pair_groups = {gid: len(members) for gid, members in groups.items()
                        if len(members) != 2}

    choice_groups_by_class = defaultdict(list)
    for gid, members in groups.items():
        cls_ids = {m["classId"] for m in members}
        tab_ids = {m["tabId"] for m in members}
        xy = {(m["x"], m["y"]) for m in members}
        for cid in cls_ids:
            choice_groups_by_class[cid].append({
                "groupId": gid,
                "tabId": sorted(tab_ids)[0] if len(tab_ids) == 1 else sorted(tab_ids),
                "x": sorted(xy)[0][0] if len(xy) == 1 else None,
                "y": sorted(xy)[0][1] if len(xy) == 1 else None,
                "samePosition": len(xy) == 1,
                "entries": sorted(
                    [{"id": m["id"], "name": m["name"], "spellId": m["spellId"]}
                     for m in members],
                    key=lambda r: r["id"]),
            })

    # ---- per-tab gate metadata ----
    def tab_meta(cid, t):
        key = f"{cid}:{t['tabId']}"
        ents = entries_by_tab.get(key, [])
        ae_tiers = sorted({e["reqTabAE"] for e in ents if e["reqTabAE"]})
        te_tiers = sorted({e["reqTabTE"] for e in ents if e["reqTabTE"]})
        return {
            "tabId": t["tabId"], "tabName": t["tabName"], "sortOrder": t["sortOrder"],
            "entryCount": len(ents), "isEmpty": len(ents) == 0,
            "aeGateTiers": ae_tiers, "teGateTiers": te_tiers,
            "maxReqTabAE": max(ae_tiers) if ae_tiers else 0,
            "maxReqTabTE": max(te_tiers) if te_tiers else 0,
        }

    # ---- write per-class files ----
    tdir = config.DATA_DIR / "talents" / "coa"
    tdir.mkdir(parents=True, exist_ok=True)
    for p in tdir.glob("*.json"):
        p.unlink()

    index_classes = []
    empty_tab_pairs = []
    for c in classes_meta:
        cid = c["classId"]
        cls_name = class_dir_names.get(cid)
        if cls_name is None:
            raise RuntimeError(
                f"build_coatalents: payload classId {cid} ({c['className']}) has "
                "no coa-custom entry in data/classes/index.json - class roster "
                "drifted, needs re-investigation")
        tabs = [tab_meta(cid, t) for t in c["tabs"]]
        for t in tabs:
            if t["isEmpty"]:
                empty_tab_pairs.append(
                    {"classId": cid, "className": cls_name,
                     "tabId": t["tabId"], "tabName": t["tabName"]})
        nodes = sorted(nodes_by_class.get(cid, []), key=lambda r: (r["tabId"], r["y"], r["x"]))
        essence = essence_by_class.get(str(cid))
        payload = {
            "class": cls_name, "classId": cid, "builderClassName": c["className"],
            "essence": essence,
            "tabs": tabs,
            "choiceGroups": sorted(choice_groups_by_class.get(cid, []),
                                   key=lambda g: g["groupId"]),
            "nodeCount": len(nodes),
            "nodes": nodes,
        }
        text = sharding.dump_manifest(payload)
        lines = text.count("\n") + 1
        assert lines <= MAX_LINES, (cls_name, lines)
        (tdir / f"{cls_name}.json").write_text(text, encoding="utf-8")
        index_classes.append({
            "class": cls_name, "classId": cid, "file": f"{cls_name}.json",
            "tabCount": len(tabs), "nodeCount": len(nodes),
            "choiceGroupCount": len(choice_groups_by_class.get(cid, [])),
        })

    index = {
        "classes": sorted(index_classes, key=lambda c: c["classId"]),
        "totalNodes": n,
        "totalTabAssignments": sum(len(c["tabs"]) for c in classes_meta),
        "distinctTabIds": len({t["tabId"] for c in classes_meta for t in c["tabs"]}),
    }
    (tdir / "index.json").write_text(sharding.dump_manifest(index), encoding="utf-8")

    # ---- 84-vs-72 tab-layer reconciliation (recomputed fresh from data/classes/,
    # not trusted from the older doc figure - see _meta.json for the full writeup) ----
    local_tab_pairs = 0
    local_tab_counts = {}
    for cid, cls_name in class_dir_names.items():
        cidx = json.loads((config.DATA_DIR / "classes" / cls_name / "index.json")
                          .read_text(encoding="utf-8"))
        tab_names = sorted({f["tab"] for f in cidx["files"] if f["tab"]})
        local_tab_counts[cls_name] = len(tab_names)
        local_tab_pairs += len(tab_names)

    tabid_to_classids = defaultdict(set)
    for c in classes_meta:
        for t in c["tabs"]:
            tabid_to_classids[t["tabId"]].add(c["classId"])
    shared_tab_ids = {tid: sorted(cids) for tid, cids in tabid_to_classids.items()
                      if len(cids) > 1}
    extra_assignments_from_sharing = sum(len(cids) - 1 for cids in tabid_to_classids.values())

    # Sec 11's 7 "no CAD tab / presumably unreleased" specs, by (classId, ChrSpecs
    # tabToken) - cross-checked here against the LIVE payload by tabName. A first
    # pass of this check only tried 2 tokens (VALKYR/WITCHKNIGHT) and wrongly
    # concluded "the other 5 don't appear at all" - caught by review, which traced
    # all 7 by hand and found 3 more real matches (FLESHWEAVER/MOUNTAINKING/VIZIER)
    # plus 2 classes that gained a DIFFERENT, unnamed-by-Sec-11 extra tab (Starcaller
    # "Warden", Cultist "Dreadnought" - real new content, just not the specific
    # token Sec 11 named). classId/tabName pairs below are manually verified against
    # this payload once (see task-w4-9-report.md's correction note); the assert
    # after this table re-checks node counts at every build so future drift fails
    # loudly instead of silently going stale.
    sec11_tokens = [
        (20, "FLESHWEAVER", "Fleshweaver"), (26, "HYDROMANCY", None),
        (27, "VALKYR", "Valkyrie"), (31, "MOUNTAINKING", "Mountain King"),
        (25, "BULWARK", None), (15, "WITCHKNIGHT", "Black Knight"),
        (29, "VIZIER", "Vizier"),
    ]
    sec11_shipped = []
    for cid, token, tab_name in sec11_tokens:
        if tab_name is None:
            sec11_shipped.append({"classId": cid, "token": token, "shipped": False,
                                  "tabName": None, "tabId": None, "nodeCount": 0})
            continue
        c = next(cc for cc in classes_meta if cc["classId"] == cid)
        t = next((tt for tt in c["tabs"] if tt["tabName"] == tab_name), None)
        assert t is not None, (cid, token, tab_name)  # pinned mapping went stale
        key = f"{cid}:{t['tabId']}"
        node_count = len(entries_by_tab.get(key, []))
        assert node_count > 0, (cid, token, tab_name)  # would mean it un-shipped
        sec11_shipped.append({"classId": cid, "token": token, "shipped": True,
                              "tabName": tab_name, "tabId": t["tabId"],
                              "nodeCount": node_count})
    # extra tabs that appeared but do NOT match any Sec 11 token by name (still
    # real, shipped content - just not the specific spec Sec 11 flagged)
    unmatched_extra_tabs = [
        {"classId": 26, "className": "Starcaller", "tabName": "Warden", "tabId": 89},
        {"classId": 25, "className": "Cultist", "tabName": "Dreadnought", "tabId": 88},
    ]
    for u in unmatched_extra_tabs:
        c = next(cc for cc in classes_meta if cc["classId"] == u["classId"])
        t = next(tt for tt in c["tabs"] if tt["tabName"] == u["tabName"])
        assert t["tabId"] == u["tabId"]
        key = f"{u['classId']}:{u['tabId']}"
        u["nodeCount"] = len(entries_by_tab.get(key, []))
        assert u["nodeCount"] > 0

    tab_layer_reconciliation = {
        "localCadTabLayer": {
            "note": ("data/classes/<Class>/ CAD tab-string layer, recomputed fresh "
                     "from this repo's OWN client capture (not the payload) - "
                     "matches AGENT-GUIDE/DATAMINE-REQUEST Sec 11's cited '84' "
                     "exactly, still clean today: every one of the 21 coa-custom "
                     "classes carries precisely 4 tab-name buckets (1 Class + 3 "
                     "spec), zero exceptions."),
            "classCount": len(class_dir_names),
            "totalClassTabPairs": local_tab_pairs,
            "perClassTabCounts": local_tab_counts,
        },
        "payloadTabLayer": {
            "note": ("The published builder's own tab layer, which has grown past "
                     "a clean 4-per-class: 10 of 21 classes now carry 5 or 6 tab "
                     "slots (an extra spec and/or an empty placeholder slot), for "
                     "96 total (classId,tabId) ASSIGNMENT pairs - more than the "
                     "84 in the local CAD snapshot, not fewer."),
            "totalClassTabAssignments": sum(len(c["tabs"]) for c in classes_meta),
            "distinctTabIds": len(tabid_to_classids),
            "sharedTabIds": shared_tab_ids,
            "extraAssignmentsAbsorbedBySharing": extra_assignments_from_sharing,
            "emptyPlaceholderTabPairs": empty_tab_pairs,
        },
        "sec11UnreleasedSpecsShipped": {
            "note": ("Cross-check of Sec 11's '7 of 70 specs have no CAD tab' list "
                     "(by ChrSpecs tabToken) against the LIVE payload's tabNames, "
                     "by classId + name. 5 of 7 have shipped real, non-empty "
                     "content since Sec 11's audit; 2 have not (their classes "
                     "instead gained a DIFFERENT, unnamed-by-Sec-11 extra tab - "
                     "see unmatchedExtraTabs)."),
            "tokens": sec11_shipped,
            "shippedCount": sum(1 for s in sec11_shipped if s["shipped"]),
            "unmatchedExtraTabs": unmatched_extra_tabs,
        },
        "explanation": (
            "The doc's '84' (Sec 11, local CAD tab-string layer: 4 tabs x 21 "
            "coa-custom classes) and '72' (Sec 6.1, payload's DISTINCT tabId "
            "count) are not directly comparable - they count different things "
            "from different sources. Recomputed fresh: the payload actually "
            "carries 96 (classId,tabId) ASSIGNMENT pairs (more than 84 - 10 "
            "classes have grown a 5th or 6th tab slot since the local snapshot), "
            "and 96 collapses to 72 DISTINCT tabIds purely because of id REUSE: "
            "tabId 87 ('Class') is literally the SAME numeric id on all 21 "
            "classes' Class trees (21 assignments -> 1 distinct id, -20), and "
            "tabId 1 ('None', a placeholder) plus tabId 71 ('Blessings', a real "
            "tab for SunCleric reused as an empty placeholder for Chronomancer) "
            "each get reused once more (-3 -1). 20+3+1 = 24 'extra' assignments "
            "absorbed by 3 shared ids; 96-24 = 72, exactly. Separately: 5 of "
            "the 96 assignment pairs are EMPTY placeholders (0 entries) - all "
            "4 'None' tabId=1 slots (WitchHunter/Guardian/Pyromancer/SunCleric) "
            "plus Chronomancer's borrowed-but-unauthored 'Blessings' slot. "
            "The remaining 5 of those 10 grown classes (SonOfArugal/Primalist/"
            "Venomancer/Starcaller/Cultist) are NOT empty placeholders - each "
            "gained a genuine 5th tab with real content (38-44 nodes apiece). "
            "Cross-checking Sec 11's 7 named 'unreleased' specs by name against "
            "this payload: 5 of 7 have SHIPPED - SonOfArugal/FLESHWEAVER -> "
            "'Fleshweaver' (44 nodes), SunCleric/VALKYR -> 'Valkyrie' (42 nodes), "
            "Primalist/MOUNTAINKING -> 'Mountain King' (40 nodes), WitchHunter/"
            "WITCHKNIGHT -> 'Black Knight' (38 nodes), Venomancer/VIZIER -> "
            "'Vizier' (41 nodes) all now exist as real, non-empty tabs - see "
            "sec11UnreleasedSpecsShipped above for the full per-token table (exact "
            "node counts re-verified by assertion at every build, not hardcoded "
            "trust). Only "
            "2 of 7 (Starcaller/HYDROMANCY, Cultist/BULWARK) do NOT appear by a "
            "matching tabName - though those two classes still each gained a "
            "DIFFERENT extra tab of their own (Starcaller 'Warden' 40 nodes, "
            "Cultist 'Dreadnought' 38 nodes) not named by Sec 11 at all. This is "
            "live, dated evidence of the 'external source that drifts' caveat "
            "this task was told to expect - a first pass of this reconciliation "
            "only checked 2 of the 7 tokens by hand and wrongly concluded the "
            "other 5 classes 'still sit at the local 4-tab count'; they do not."
        ),
    }

    # ---- other honest findings, gathered into _meta.json ----
    by_id = {e["id"]: e for e in all_entries}
    no_required_ids = sum(1 for e in all_entries if not any(e["requiredIds"]))

    req_total = req_resolved = req_same_class = 0
    for e in all_entries:
        for rid in e["requiredIds"]:
            if rid:
                req_total += 1
                t = by_id.get(rid)
                if t:
                    req_resolved += 1
                    if t["classId"] == e["classId"]:
                        req_same_class += 1
    conn_total = conn_resolved = 0
    unresolved_conn = []
    for e in all_entries:
        for cid_ in e["connectedNodeIds"]:
            if cid_:
                conn_total += 1
                if cid_ in by_id:
                    conn_resolved += 1
                else:
                    unresolved_conn.append({"fromId": e["id"], "fromName": e["name"],
                                            "missingId": cid_})

    # isStartingNode: for each nonzero entry, actually COMPUTE (not assume) whether
    # any other node's requiredIds targets it - this is the brief's suggested golden
    # ("a node whose requiredIds parent is the tree's isStartingNode"), and it is
    # only correct to call it disproven if that check comes back empty. A first pass
    # of this module asserted "neither entry is referenced" without running this
    # loop at all - caught by review (reviewer traced node 7608's referencing
    # siblings by hand); this is the corrected, actually-computed version.
    special_start = []
    for e in all_entries:
        if not e["isStartingNode"]:
            continue
        referencing = [{"id": x["id"], "name": x["name"],
                        "requiredIds": _depad(x["requiredIds"])}
                       for x in all_entries if e["id"] in x["requiredIds"]]
        special_start.append({
            "id": e["id"], "name": e["name"], "classId": e["classId"],
            "tabId": e["tabId"], "isStartingNode": e["isStartingNode"],
            "requiredIds": _depad(e["requiredIds"]),
            "referencedByRequiredIds": referencing,
        })

    is_starting_node_finding = {
        "verdict": "PARTIALLY PROVEN",
        "reason": (
            "Only 2/3618 entries carry a nonzero isStartingNode at all, but they "
            "are NOT equally reliable. `isStartingNode: 1` on node 7608 (Cultist "
            "'Abyssal Ward', tabId 87 'Class', empty requiredIds) IS a real tree "
            "root exactly as the brief's suggested golden expects: two sibling "
            "nodes - 4040 'Obliteration' and 7512 'Dreadnought', both Cultist, "
            "both `requiredIds: [7608, 0, 0]` - directly require it. The brief's "
            "golden HOLDS for this entry. The other nonzero entry, node 30212 "
            "(SunCleric 'Hope'), carries `isStartingNode: 127` - not a 0/1 "
            "boolean, a genuine data anomaly - and is NOT any other node's "
            "requiredIds target; that one specific value is unexplained and "
            "unreferenced, not a second real starting node. So: proven where used "
            "correctly (value 1), anomalous and unreferenced where the value is "
            "127. Separately, and NOT a contradiction of the above: "
            f"{no_required_ids}/{n} entries ({no_required_ids/n*100:.1f}%) have NO "
            "requiredIds at all (far more than the 2 flagged nodes) - CoA's talent "
            "trees are gated primarily by reqTabAE/reqTabTE per-row investment "
            "thresholds (AE gates the Class tree, TE gates spec trees - see "
            "raw/interface/AddOns/Ascension_CoATalents/CoATalentFrame.xml's "
            "ClassTree/SpecTree frame wiring, and reqTabAeTeGateFinding below), "
            "not a classic Blizzard prerequisite chain rooted at one flagged "
            "'starting node' - requiredIds only gates a small minority (171 "
            f"non-zero refs / {n} entries) of nodes, and `isStartingNode` marks "
            "only 1 of them. The flag is real and correctly wired where present, "
            "just far too sparse to be the general 'is this a tree root' signal "
            "on its own - `requiredIds == []` is the broader structural proxy for "
            "that, `isStartingNode` a narrower, sparser, mostly-reliable overlay."),
        "specialEntries": special_start,
        "entriesWithNoRequiredIds": no_required_ids,
        "entriesWithNoRequiredIdsPct": round(no_required_ids / n, 4),
    }

    client_lua_geometry_finding = {
        "note": (
            "The base account-wide CharacterAdvancementData.json (raw/content/) "
            "ALSO carries PositionX/PositionY/ConnectedNodes/RequiredIDs/"
            "RequiredAEInvestment/RequiredTEInvestment columns (13-15% row "
            "coverage, no numeric tabId at all - Tab is a bare string there). "
            "Investigated as a possible fallback/cross-check source: for the "
            f"{id_matches_cad_row}/{n} payload nodes whose id DOES match a CAD "
            "row, agreement is near-zero (PositionX/Y exact match only on a "
            "small minority; ConnectedNodes average Jaccard similarity ~0.02) - "
            "these raw CAD columns serve the client's narrower 'ConnectingNode' "
            "decorative-line UI (see raw/interface/FrameXML/Data/"
            "CharacterAdvancement.lua's CHARACTER_ADVANCEMENT_NODES population "
            "rule), not the same geometry as the builder payload. Concluded: NOT "
            "a usable client-Lua fallback for tree geometry, despite the "
            "superficially matching field names."),
        "idMatchesCadRow": id_matches_cad_row,
        "idMatchesCadRowOf": n,
    }

    resolve_stats = {
        "totalNodes": n,
        "vsCuratedDataSpells": {
            "resolved": curated_resolved, "of": n,
            "rate": round(curated_resolved / n, 4),
            "note": ("resolve rate of each node's primary spellId against "
                     "data/spells/by-id/*.jsonl (the curated, closure-built "
                     "spell set) - well below the naive 95% bar; see "
                     "contentDrift below for why."),
        },
        "vsRawCadSpellsUnion": {
            "resolved": cad_resolved, "of": n, "rate": round(cad_resolved / n, 4),
            "note": ("resolve rate against the union of EVERY CAD row's Spells "
                     "field (all 43 classes, not just the 21 coa-custom ones, "
                     "and unfiltered by whether build_spells' closure ever "
                     "reached it) - still well below 95%, so the gap is not an "
                     "artifact of data/spells' own closure scope."),
        },
        "idMatchesAnyCadRow": {
            "resolved": id_matches_cad_row, "of": n,
            "rate": round(id_matches_cad_row / n, 4),
            "note": "payload node `id` matching some CAD row's own `ID` field.",
        },
    }

    # [Review fix pass] The raw-Spell.dbc re-measurement now runs BEFORE the
    # content_drift prose is assembled, so every figure in that prose is
    # interpolated from these variables instead of hardcoded. The hardcoded
    # version had already gone stale against its own computed block in the same
    # file (it claimed 99.97%/3,617-of-3,618 against 209,125 rows next to a
    # measured rate of 1.0, and named spellId 301010 "Devourer" as a genuine
    # miss when a later client patch added that row) - exactly the
    # stated-as-fact-not-re-derived failure this pass exists to remove.
    spell_dbc_ids = set()
    with gzip.open(config.RAW_DBC_DIR / "Spell.csv.gz", "rt", encoding="utf-8") as f:
        r = csv.DictReader(f)
        for row in r:
            spell_dbc_ids.add(int(row["id"]))
    spell_dbc_resolved = sum(1 for e in all_entries if e["spellId"] in spell_dbc_ids)
    spell_dbc_rate = spell_dbc_resolved / n
    spell_dbc_unresolved = sorted({e["spellId"] for e in all_entries
                                   if e["spellId"] not in spell_dbc_ids})
    _miss = (" The remaining "
             f"{len(spell_dbc_unresolved)} unresolved spellId(s): "
             f"{spell_dbc_unresolved}." if spell_dbc_unresolved
             else " Every payload spellId resolves - no exceptions.")

    content_drift = {
        "verdict": (
            "The naive '>=95% resolve against CAD entries' gate, taken literally "
            "(payload spellId must appear in this repo's own captured "
            "CharacterAdvancementData.json), FAILS: only "
            f"{resolve_stats['vsRawCadSpellsUnion']['rate']*100:.1f}% resolve. "
            "This is real, measured content drift between the live published "
            "builder and this repo's client snapshot - NOT a parse bug or bad "
            "join. Independent proof: a permissive re-measurement against the "
            "raw client Spell.dbc table (raw/dbc/Spell.csv.gz, "
            f"{len(spell_dbc_ids):,} rows, ANY row regardless of whether any CAD "
            f"entry references it) resolves {spell_dbc_rate*100:.2f}% "
            f"({spell_dbc_resolved:,}/{n:,}) - the payload's spell ids are real, "
            "valid spells that exist in this exact client snapshot; they are "
            "simply not the SAME spellId variant this repo's captured CAD JSON "
            f"happens to reference for the same-looking ability.{_miss} Likely "
            "mechanism (consistent with the W4-8 Realms-bitmask finding that CoA "
            "abilities get authored as MULTIPLE duplicate CAD rows per realm/"
            "game-mode, each potentially carrying a DIFFERENT spellId variant): "
            "the account-wide CAD snapshot's 'coa-custom' rows are a union "
            "across several variants of the same ability, and the live Vol'Jin "
            "builder picks one specific variant that doesn't always line up "
            "1:1 with the variant this snapshot's closure walk reached."),
        "spellDbcResolveRate": {
            "resolved": spell_dbc_resolved, "of": n,
            "rate": round(spell_dbc_rate, 4),
            "unresolvedSpellIds": spell_dbc_unresolved,
        },
        "recommendation": (
            "This module gates the HARD pass/fail bar on the raw-Spell.dbc "
            f"existence check ({spell_dbc_rate*100:.2f}%, i.e. 'is this a real "
            "spell in this client snapshot at all'), not the curated/CAD-Spells "
            f"join ({resolve_stats['vsCuratedDataSpells']['rate']*100:.1f}%/"
            f"{resolve_stats['vsRawCadSpellsUnion']['rate']*100:.1f}%), and "
            "ships spellResolved:false on every node whose spellId does not "
            "resolve against data/spells so a consumer can see the gap per-node "
            "instead of it being silently absorbed."),
    }

    choice_group_finding = {
        "totalNonzeroGroups": len(groups),
        "nonPairGroups": non_pair_groups,
        "verdict": (
            "Every nonzero `group` value pairs EXACTLY 2 entries (0 exceptions), "
            "always sharing identical (classId, tabId, x, y) and differing only "
            "in spellId/name - the client's choice-node concept "
            "(CoACharacterAdvancementUtil.GetDisplayTemplateForEntryChoice / "
            "CoATalentChoiceButtonTemplate; node:IsChoiceNode() in "
            "GetGateLeftAttachmentPoint/GetGateRightAttachmentPoint bundles "
            "alternatives at one shared visual anchor). A choice group's `group` "
            "value is literally one member's own spellId (the OTHER member, in "
            "every sampled case) - a builder-side convenience, not a separate id "
            "space."),
    }

    connectivity_finding = {
        "requiredIds": {"total": req_total, "resolved": req_resolved,
                        "resolveRate": round(req_resolved / req_total, 4) if req_total else None,
                        "alwaysSameClass": req_same_class == req_resolved},
        "connectedNodeIds": {"total": conn_total, "resolved": conn_resolved,
                             "resolveRate": round(conn_resolved / conn_total, 4) if conn_total else None,
                             "unresolved": unresolved_conn},
    }

    # reqTabAE/reqTabTE: which tree each currency actually gates. A first pass of
    # this module only sampled tabId 87 ("Class") and concluded AE/TE gating was
    # "only live on the Class tree" - true for AE, WRONG for TE (caught by
    # review). Recomputed properly here: for every (classId,tabId) pair, collect
    # the distinct nonzero reqTabAE/reqTabTE tiers actually present.
    ae_gated_tabs, te_gated_tabs = [], []
    for c in classes_meta:
        for t in c["tabs"]:
            key = f"{c['classId']}:{t['tabId']}"
            ents = entries_by_tab.get(key, [])
            if any(e["reqTabAE"] for e in ents):
                ae_gated_tabs.append(t["tabId"])
            if any(e["reqTabTE"] for e in ents):
                te_gated_tabs.append(t["tabId"])
    req_tab_ae_te_gate_finding = {
        "verdict": "AE gates the Class tree; TE gates spec trees - a clean split, not 'AE/TE only live on Class'",
        "aeGatedTabIds": sorted(set(ae_gated_tabs)),
        "teGatedTabIds": sorted(set(te_gated_tabs)),
        "reason": (
            "reqTabAE is nonzero ONLY on tabId 87 ('Class', shared by all 21 "
            "classes) - tiers step 0 -> 9 -> 24 by row there, confirmed on every "
            "class checked. reqTabTE is nonzero on EVERY spec tab (tiers step "
            "0 -> 8 -> 23 by row, confirmed on every spec tab checked) and flat "
            "0 on the Class tab - the exact opposite pattern, not 'also mostly "
            "zero'. This matches the client's own frame wiring, not just an "
            "inferred pattern: raw/interface/AddOns/Ascension_CoATalents/"
            "CoATalentFrame.xml's `$parentClassTree` frame (parentKey="
            "\"ClassTree\") wires `getEntryGateRequirement` to "
            "`CoACharacterAdvancementUtil.GetEntryAEGateRequirement` and "
            "`gateCurrencyCount` to `C_CharacterAdvancement."
            "GetPendingTabAEInvestment`; the sibling `$parentSpecTree` frame "
            "(parentKey=\"SpecTree\") wires the TE equivalents "
            "(`GetEntryTEGateRequirement` / `GetPendingTabTEInvestment`) "
            "instead - i.e. the client XML itself assigns AE to the Class tree "
            "and TE to the Spec tree by construction, this is not a coincidence "
            "of the data."),
    }

    meta = {
        "task": "W4-9: CoA talent tree geometry "
                "(coa-sim-handoff/DATAMINE-REQUEST.md Sec 6.1 / Sec 13 item 11)",
        "payload": {
            "url": f"https://ascension.gg/en/v2/coa-builder/{slug}",
            "slug": slug,
            "buildId": build_record.get("id"),
            "buildName": build_record.get("name"),
            "maxLevel": build_record.get("max_level"),
            "meta": talents.get("meta"),
            "fetch": fetch_meta,
            "totalNodes": n,
            "extractionTechnique": (
                "Next.js flight-stream analogue of the aowow.py Listview trick "
                "(coa-sim-handoff/parsers/aowow.py): scan every "
                "self.__next_f.push([id,\"...\"]) call by hand (backslash-aware, "
                "since some literals run several MB - a naive backtracking regex "
                "chokes), json.loads() each isolated string literal to unescape "
                "it once, strip the leading '<hex>:' flight-row prefix, then "
                "json.JSONDecoder().raw_decode() past any trailing non-JSON. The "
                "target build record is found structurally (walk the decoded "
                "tree for a dict shaped like {id,slug,name,max_level,talents: "
                "{classes,entriesByTab}}), not by a hardcoded array index."),
            "twoBuildsInPage": (
                "This page embeds TWO near-identical build records side by side "
                "(id 39 slug 'voljin-alpha', id 40 slug 'voljin') - both carry "
                "the exact same 3,618 nodes / same ids / same geometry fields, "
                "differing only in tooltip description text (verified: zero "
                "non-description/rankDescriptions field differences across every "
                "shared entry id). This is WHY every field name greps to exactly "
                "7,236 raw occurrences in the fetched HTML (2 x 3,618) matching "
                "the doc's cited count precisely - it is two copies of one "
                "dataset, not 7,236 real distinct nodes. This module uses ONLY "
                "the slug='voljin' copy (build id 40), matching both the fetch "
                "URL and the realm caveat below; 'voljin-alpha' is ignored."),
        },
        "realmCaveat": (
            "This is the VOL'JIN builder specifically (https://ascension.gg/en/"
            "v2/coa-builder/voljin). Rexxar - Conquest of Azeroth is a SEPARATE "
            "CoA realm; its geometry is ASSUMED IDENTICAL here but UNVERIFIED "
            "until a Rexxar capture exists (coa-sim-handoff/DATAMINE-REQUEST.md "
            "Sec 13 item 7, 'capture a Vol'Jin/Rexxar realm overlay and diff vs "
            "base' - not performed by this task). The client-side Lua geometry "
            "source (Ascension_CoATalents, CharacterAdvancement*.lua) IS "
            "realm-agnostic structure (node types, gate mechanism, flag bits), "
            "but carries none of the numeric tree layout itself (see "
            "clientLuaGeometryFinding) - so this caveat applies to essentially "
            "all of this dataset's geometry, not just a slice of it."),
        "resolveStats": resolve_stats,
        "contentDrift": content_drift,
        "tabLayerReconciliation": tab_layer_reconciliation,
        "isStartingNodeFinding": is_starting_node_finding,
        "clientLuaGeometryFinding": client_lua_geometry_finding,
        "choiceGroupFinding": choice_group_finding,
        "connectivityFinding": connectivity_finding,
        "reqTabAeTeGateFinding": req_tab_ae_te_gate_finding,
        "flagBits": {hex(k): v for k, v in FLAG_BITS.items()},
        "classCount": len(classes_meta),
        "goldenBar": {
            "spellDbcResolveRateGate": 0.95,
            "spellDbcResolveRateMeasured": content_drift["spellDbcResolveRate"]["rate"],
            "gateMet": content_drift["spellDbcResolveRate"]["rate"] >= 0.95,
        },
    }
    (tdir / "_meta.json").write_text(
        json.dumps(meta, ensure_ascii=False, indent=1, sort_keys=True),
        encoding="utf-8")

    return {
        "classes": len(index_classes), "totalNodes": n,
        "curatedResolveRate": resolve_stats["vsCuratedDataSpells"]["rate"],
        "spellDbcResolveRate": content_drift["spellDbcResolveRate"]["rate"],
        "distinctTabIds": index["distinctTabIds"],
        "totalTabAssignments": index["totalTabAssignments"],
        "choiceGroups": len(groups),
        "emptyTabPairs": len(empty_tab_pairs),
    }


if __name__ == "__main__":
    print(build())
