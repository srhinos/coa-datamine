"""Shared live-vs-catalog join for the CoA layer (task W4-14).

The problem this exists to solve: `data/classes/<Class>/*.json` is the CAD
*catalog* - what the client's CharacterAdvancementData tables LIST for a class -
and consumers (including this repo's own agents) keep reading it as if it were
the game. It is not. A real level-60 Starcaller proved the gap: the catalog ships
a "Tides" tree (Tide Lash, Silvercurrent, Pond, Deluge, Geyser) that does not
exist in game; that character's real trees are Moon Guard / Sentinel / Moon Priest
/ Warden / Class - exactly what the live talent-builder payload
(`data/talents/coa/`, task W4-9) says.

This module is the single implementation of "is this catalog entry actually in
the live trees", imported by BOTH writers so neither duplicates the logic:
  - `tools/build_classes.py`   owns data/classes/<Class>/* -> stamps `live` +
    `liveEvidence` per entry, `liveCounts` per class index, and writes
    data/classes/_live_summary.json.
  - `tools/build_coatalents.py` owns data/talents/coa/*     -> re-uses the payload
    extraction below (it lived there first; moved here so build_classes can read
    the SAME frozen capture without importing a builder or re-parsing the HTML a
    second time - `live_index()` is lru_cached, so the 11.8 MB page is scanned
    once per process).

Liveness rule (exact, spell-id level - no name matching in the verdict):
  live=True  reason "liveDirect"   - one of the entry's own Spells ids IS a live
                                     node's spellId/spellIds member.
  live=True  reason "liveViaRank"  - no own id matches, but another rank of the
                                     same SpellRankData chain does (the live
                                     builder node carries a different rank of the
                                     same ability than the CAD row does).
  live=None  reason "indeterminate"- not in the trees, BUT carries positive
                                     evidence of a non-tree acquisition path, so
                                     "dead content" would be a false negative.
                                     See ALT_SIGNALS / alt_acquisition_index().
  live=False reason "deadCatalog"  - not in the trees, by any rank, with no
                                     alternate-acquisition evidence at all.
  live=None  reason "unknownNoGeometry" - the class has no builder file (the 10
                                     vanilla + 11 Reborn/meta dirs); nothing is
                                     claimed either way.

Why `indeterminate` exists at all (the measured false-negative risk, task
requirement 2): the builder payload shows the TREES. An ability granted outside a
tree looks dead here while being live in game. Two such paths are visible offline
and both are measured in data/classes/_live_summary.json:
  - `skillLineAutoGrant`: the entry's spell has a SkillLineAbility row with
    acquireMethod != 0 (automatically granted, not trainer-taught). These are the
    weapon/armour proficiencies (Fist Weapons, Polearms, Plate Mail, Dual Wield,
    Auto Shot, Block, ...) plus a handful of real abilities. acquireMethod is
    stock 3.3.5 semantics and generation-independent, so this signal is
    trustworthy on its own - and it is disjoint from the live node set (0 of the
    live spell ids carry acquireMethod != 0).
  - `npcTrainerRow`: the entry's spell (or a rank of it) is taught by an
    NPCTrainer row. This one is REAL but NOT separable from dead content offline,
    and that is the honest verdict rather than a guess: NPCTrainer.dbc in this
    same client snapshot is provably CONTEMPORARY with the live generation (it
    carries rows under skill lines that exist ONLY in the live builder and not in
    the CAD tab layer at all - "Moon Guard", "Moon Priest", "Warden",
    "Headhunting" - teaching rank variants of abilities whose base rank IS a live
    node, e.g. Starcall), so a trainer row is evidence the ability is reachable
    without a tree node; but the CAD row it hangs off can equally be a retired
    duplicate. Hence live=None, not live=False and not live=True.
  - `liveNodeNameTwin`: the entry's NAME matches a live node's name in the same
    class while none of its spell ids do - the duplicate-CAD-row / spellId-variant
    drift already documented in data/talents/coa/_meta.json's `contentDrift`. The
    ability is live; whether THIS row is the live variant is unknowable offline.

Everything above is re-derived at every build; nothing here is a copied figure.
"""
import hashlib
import json
import re
from collections import defaultdict
from functools import lru_cache

from tools import config

# ---------------------------------------------------------------------------
# Payload extraction: locate + parse the embedded Next.js flight JSON.
# (Moved verbatim out of build_coatalents.py so both writers share one parser.)
# ---------------------------------------------------------------------------

_PUSH_MARKER = 'self.__next_f.push(['
_ROW_PREFIX_RE = re.compile(r"^[0-9a-f]+:")


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
            "coa_live: no self.__next_f.push(...) chunk decoded into a "
            "{classes, entriesByTab} build record - the page structure has "
            "changed since this parser was written and needs re-investigation "
            "(see this module's docstring for the extraction technique).")

    by_slug = [b for b in candidates if b.get("slug") == slug]
    if not by_slug:
        found = sorted({b.get("slug") for b in candidates})
        raise RuntimeError(
            f"coa_live: found {len(candidates)} build record(s) but none "
            f"with slug={slug!r} - available slugs: {found}")
    if len(by_slug) > 1:
        raise RuntimeError(
            f"coa_live: {len(by_slug)} build records share slug={slug!r} - "
            "ambiguous, needs re-investigation")
    return by_slug[0]


@lru_cache(maxsize=4)
def load_build_record(slug: str = "voljin") -> tuple:
    """(build_record, provenance) for the FROZEN capture in raw/talents/. Never
    fetches - tools/fetch_coatalents.py is the separate, occasional network step."""
    html_path = config.RAW_TALENTS_DIR / f"coa-builder-{slug}.html"
    if not html_path.is_file():
        raise RuntimeError(
            f"coa_live: {html_path} not found - run "
            f"`python -m tools.fetch_coatalents --slug {slug}` first. The live/dead "
            "determination has no offline substitute: the CAD catalog alone cannot "
            "tell live content from cut content (that is the entire point of this "
            "module), so a missing payload must fail loudly rather than silently "
            "mark 27k entries unknown.")
    raw = html_path.read_bytes()
    html_text = raw.decode("utf-8", errors="replace")
    record = extract_payload(html_text, slug)
    fetch_meta_path = config.RAW_TALENTS_DIR / "_fetch.json"
    fetch_meta = (json.loads(fetch_meta_path.read_text(encoding="utf-8"))
                  if fetch_meta_path.is_file() else {})
    prov = {
        "slug": slug,
        "buildId": record.get("id"),
        "buildName": record.get("name"),
        "url": fetch_meta.get("url"),
        "capturedUtc": fetch_meta.get("capturedUtc"),
        "sha256": fetch_meta.get("sha256") or hashlib.sha256(raw).hexdigest(),
        "sha256Source": "raw/talents/_fetch.json" if fetch_meta.get("sha256")
                        else "recomputed from raw/talents/coa-builder-%s.html" % slug,
        "note": ("EXTERNAL SOURCE THAT DRIFTS - the live builder reflects current "
                 "game balance/content, independent of this repo's client snapshot. "
                 "Re-run tools/fetch_coatalents.py and diff sha256 to check for "
                 "drift; a stale capture makes `live` stale too."),
    }
    return record, prov


REALM_CAVEAT = (
    "This is the VOL'JIN builder (https://ascension.gg/en/v2/coa-builder/voljin). "
    "Rexxar - Conquest of Azeroth is a SEPARATE CoA realm whose geometry is ASSUMED "
    "IDENTICAL here but UNVERIFIED until a Rexxar capture exists - so every `live` / "
    "`liveEvidence` verdict in this dataset is a VOL'JIN verdict. data/classes/ "
    "entries are account-wide (four realms), so a Rexxar-only ability would be "
    "indistinguishable from dead content by this method."
)


def norm(s) -> str:
    return re.sub(r"[^a-z0-9]", "", (s or "").lower())


def _node_spell_ids(node):
    """A builder node's spell ids: the primary `spellId` plus every member of
    `spellIds` (the multi-spell entries - 15 of 192 on Starcaller). Zeros are
    padding, never a real id."""
    ids = [node.get("spellId")]
    ids.extend(node.get("spellIds") or ())
    return [i for i in ids if i]


@lru_cache(maxsize=4)
def live_index(slug: str = "voljin") -> dict:
    """{"provenance", "realmCaveat", "byClassId": {classId: {...}}} built from the
    frozen builder capture. Per class:
      spellNodes  {spellId: {nodeId, nodeName, tabId, tabName}}  - the live set
      nodeNamesNorm {normalizedName: nodeId}                     - name-twin probe
      tabs        [{tabId, tabName, sortOrder, entryCount}]
    """
    record, prov = load_build_record(slug)
    talents = record["talents"]
    entries_by_tab = talents["entriesByTab"]
    by_class = {}
    for c in talents["classes"]:
        cid = c["classId"]
        tabs = []
        tab_name = {}
        for t in c["tabs"]:
            key = f"{cid}:{t['tabId']}"
            tabs.append({"tabId": t["tabId"], "tabName": t["tabName"],
                         "sortOrder": t.get("sortOrder"),
                         "entryCount": len(entries_by_tab.get(key, []))})
            tab_name[t["tabId"]] = t["tabName"]
        by_class[cid] = {
            "classId": cid, "builderClassName": c.get("className"),
            "tabs": tabs, "spellNodes": {}, "nodeNamesNorm": {}, "nodeCount": 0,
            "_tabName": tab_name,
        }
    for key, ents in entries_by_tab.items():
        for e in ents:
            cl = by_class.get(e["classId"])
            if cl is None:
                continue
            cl["nodeCount"] += 1
            meta = {"nodeId": e["id"], "nodeName": e.get("name"),
                    "tabId": e["tabId"], "tabName": cl["_tabName"].get(e["tabId"])}
            for sid in _node_spell_ids(e):
                cl["spellNodes"].setdefault(sid, meta)
            cl["nodeNamesNorm"].setdefault(norm(e.get("name")), e["id"])
    for cl in by_class.values():
        cl.pop("_tabName")
    return {"provenance": prov, "realmCaveat": REALM_CAVEAT, "byClassId": by_class}


# ---------------------------------------------------------------------------
# Alternate (non-tree) acquisition paths - the false-negative probes.
# ---------------------------------------------------------------------------

@lru_cache(maxsize=1)
def alt_acquisition_index() -> dict:
    """{"autoGrantSpellIds": frozenset, "trainerSpellIds": frozenset} - spells the
    client grants WITHOUT a talent node. See the module docstring for why each is
    a false-negative probe and why only one of the two is self-sufficient."""
    from tools import dbc  # local import: keeps this module importable without DBCs
    auto = frozenset(r["spell"] for r in dbc.iter_named("SkillLineAbility")
                     if r["acquireMethod"] != 0)
    trainer = frozenset(r["spellId"] for r in dbc.iter_named("NPCTrainer"))
    return {"autoGrantSpellIds": auto, "trainerSpellIds": trainer}


def entry_spell_ids(entry) -> tuple:
    """(ownIds, rankIds) for one data/classes CAD entry. ownIds are the ids the
    CAD row itself references; rankIds are the OTHER ranks of those spells'
    SpellRankData chains (already joined onto the entry by build_classes)."""
    own = [s["id"] for s in entry.get("spells", ())]
    own_set = set(own)
    ranks = []
    for s in entry.get("spells", ()):
        for r in (s.get("ranks") or ()):
            sid = r.get("spellId")
            if sid and sid not in own_set:
                ranks.append(sid)
    return own, ranks


ALT_SIGNALS = ("skillLineAutoGrant", "npcTrainerRow", "liveNodeNameTwin")


def alt_signals(entry, class_live, alt) -> list:
    """Which non-tree acquisition signals fire for a NOT-in-the-trees entry.
    Order is stable (ALT_SIGNALS) so the emitted evidence is deterministic."""
    own, ranks = entry_spell_ids(entry)
    chain = set(own) | set(ranks)
    out = []
    if chain & alt["autoGrantSpellIds"]:
        out.append("skillLineAutoGrant")
    if chain & alt["trainerSpellIds"]:
        out.append("npcTrainerRow")
    if norm(entry.get("name")) in class_live["nodeNamesNorm"]:
        out.append("liveNodeNameTwin")
    return out


def classify_entry(entry, class_live, alt) -> tuple:
    """(live, liveEvidence) for one CAD entry. `class_live` is
    live_index()["byClassId"][classId], or None when the class has no builder
    file at all. See the module docstring for the full rule."""
    if class_live is None:
        return None, {"reason": "unknownNoGeometry", "matchedSpellId": None,
                      "builderTab": None}
    nodes = class_live["spellNodes"]
    own, ranks = entry_spell_ids(entry)
    for sid in own:
        hit = nodes.get(sid)
        if hit:
            return True, {"reason": "liveDirect", "matchedSpellId": sid,
                          "builderTab": hit["tabName"], "builderNodeId": hit["nodeId"]}
    for sid in ranks:
        hit = nodes.get(sid)
        if hit:
            return True, {"reason": "liveViaRank", "matchedSpellId": sid,
                          "builderTab": hit["tabName"], "builderNodeId": hit["nodeId"]}
    signals = alt_signals(entry, class_live, alt)
    if signals:
        return None, {"reason": "indeterminate", "matchedSpellId": None,
                      "builderTab": None, "signals": signals}
    return False, {"reason": "deadCatalog", "matchedSpellId": None, "builderTab": None}


REASONS = ("liveDirect", "liveViaRank", "indeterminate", "deadCatalog",
           "unknownNoGeometry")

# liveCounts (per-class index.json) uses the four buckets the consumer actually
# branches on; `unknown` deliberately merges the two live=None reasons so the
# counts sum to entryCount. The full 5-way split is liveCountsByReason.
COUNT_BUCKET = {"liveDirect": "live", "liveViaRank": "liveViaRank",
                "deadCatalog": "deadCatalog", "indeterminate": "unknown",
                "unknownNoGeometry": "unknown"}


def live_counts(reason_counter) -> dict:
    out = {"live": 0, "deadCatalog": 0, "liveViaRank": 0, "unknown": 0}
    for reason, n in reason_counter.items():
        out[COUNT_BUCKET[reason]] += n
    return out


def tab_overlap(entries, class_live) -> dict:
    """{cadTabName: Counter-like {liveTabName: n}} - for each CAD tab, where its
    live-matched entries actually land in the live builder. The statistical
    cross-check on the ChrSpecs-derived tab mapping (build_classes._tab_mapping)."""
    nodes = class_live["spellNodes"]
    out = defaultdict(lambda: defaultdict(int))
    for e in entries:
        own, ranks = entry_spell_ids(e)
        for sid in own + ranks:
            hit = nodes.get(sid)
            if hit:
                out[e.get("tab") or ""][hit["tabName"]] += 1
                break
    return {k: dict(v) for k, v in out.items()}
