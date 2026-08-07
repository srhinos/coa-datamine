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
                                     same ability than the CAD row does) AND that
                                     chain is NAME-COHERENT. The gate is not
                                     decoration: 92 of the 1,780 resolvable
                                     SpellRankData chains (5.2%) are recycled
                                     contiguous id blocks rather than rank chains,
                                     and without it they manufacture false
                                     positives. Chain head 801667 is the proven
                                     case - rank 1 "Revitalize (Rank 1
                                     DEPRECATED)", rank 6 "Ascetic Abdication",
                                     rank 7 "Fearmonger", rank 8 "War Cry", rank 9
                                     "Umbral Glaive", rank 10 "Ice Hide", rank 11
                                     "Mirage" - so an unguarded join declared
                                     WitchDoctor's CAD "Revitalize" live because
                                     "Mirage" (501136) is a live node. Coherence =
                                     the chain's members carry at most ONE distinct
                                     Spell.dbc name; ids with no Spell.dbc row
                                     carry no name and so cannot break coherence
                                     (that is what keeps WitchHunter "Interrogate"
                                     802012 -> rank 8 501380 live, a chain whose
                                     only named member is the live node itself).
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
    and that is the honest verdict rather than a guess. NPCTrainer.dbc in this
    same client snapshot is contemporary with the live generation in at least 20
    verified instances: 166 trainer rows sit under the skill lines "Moon Guard",
    "Moon Priest", "Warden" and "Headhunting", and 20 of them teach a name-coherent
    rank variant of an ability whose base rank IS a live builder node - Shooting
    Star ranks 5-7 (skill line Warden) -> live node 800505, Prayer of Elune ranks
    2-5 (Moon Priest) -> 801987, Headhunter's Spear ranks 2-7 and Berserker Axe
    ranks 2-8 (Headhunting) -> 804137 / 804138. Two things this is NOT: it is not
    a claim that those skill-line NAMES belong only to live content
    (SkillLineAbility files the player-proven-dead Tide Lash 800380 and every
    Tides sibling under skill line 92 "Moon Priest", the live name of the very
    tree slot the tab mapping says was CAD "Tides"), and the Starcall example
    previously cited here is under skill line "Sentinel", not one of the four.
    So a trainer row is evidence the ability is reachable without a tree node;
    but the CAD row it hangs off can equally be a retired duplicate. Hence
    live=None, not live=False and not live=True.
  - `liveNodeTriggerSpell`: the entry's spell is an effectTriggerSpell{1,2,3} of a
    spell that IS a live builder node of the SAME class - i.e. the game casts it
    whenever the live node fires. Mechanistic, not statistical, which is why the
    first three probes all missed it (its base rate barely differs between dead
    and live entries, so no correlation search would surface it). Concrete: Monk
    "Light's Reach" 804907 (Spell.dbc "Transcending Strikes", rank "Trigger") is
    triggered by live node 804897; Ranger "Commander" 705078 ("Plumes of War",
    "Proc") by live node 705071; Chronomancer "Word of Balance: Mend" 806314 by
    live node 806312; Barbarian "Improved Wrist Snap" 804862 ("Jawbreaker",
    "Success!") by live node 705196. These spells fire in game, so `deadCatalog` -
    "no evidence of any acquisition path at all" - was simply false for them.
    Still live=None rather than live=True: the SPELL provably fires, but whether
    THIS CAD row is how a character gets it is a different question.
  - `liveNodeNameTwin`: the entry's NAME matches a live node's name in the same
    class while none of its spell ids do - the duplicate-CAD-row / spellId-variant
    drift already documented in data/talents/coa/_meta.json's `contentDrift`. The
    ability is live; whether THIS row is the live variant is unknowable offline.

Row level vs ability level (the one thing `live` does NOT say): `live` is an
ABILITY-level claim. The client's own loader (raw/interface/FrameXML/Data/
CharacterAdvancement.lua:68) drops any CAD entry whose Flags carry Deprecated
(0x1) or Disabled (0x8) before the UI ever sees it, and entries flagged live=True
sit on such rows - the ability is live through a sibling duplicate row, THIS row
is not loaded. Measured every build into _live_summary.json's
falseNegativeMeasurement.rowLevelVsAbilityLevel, including the test of whether
that flag can act as a row-level discriminator for the liveNodeNameTwin
indeterminates (it cannot - see the block's verdict).

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
    "Every `live` / `liveEvidence` verdict is a CONQUEST OF AZEROTH verdict. The "
    "payload comes from the 'voljin' builder URL (https://ascension.gg/en/v2/"
    "coa-builder/voljin), but Vol'jin and Rexxar are two realms of the SAME game "
    "mode (gameMode=11) reading the same base chain, so this is a mode-wide capture "
    "and there is no per-realm CoA split - do not read 'voljin' in a filename as a "
    "scope limit. The limits that ARE real: (1) TIME - the published builder drifts "
    "from this repo's client snapshot, so content the builder has not caught up to "
    "reads as dead; (2) data/classes/ entries are account-wide across all four "
    "realms, so an entry belonging to another game mode is correctly dead FOR CoA "
    "while being alive on the mode that owns it."
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
    """Everything the non-tree probes and the rank-chain gate need out of the DBCs:

      autoGrantSpellIds   frozenset  SkillLineAbility.acquireMethod != 0
      trainerSpellIds     frozenset  NPCTrainer.spellId
      triggeredBySpellIds {triggeredSpellId: frozenset(sourceSpellIds)} - reversed
                          Spell.effectTriggerSpell{1,2,3}, so a spell can be asked
                          "what casts you?" in O(1)
      spellNameNorm       {spellId: normalized name} for the LIVEVIARANK GATE -
                          empty names are omitted, so a spell with no Spell.dbc row
                          and a spell with a blank name both read as "no name" and
                          cannot break a chain's name-coherence

    See the module docstring for why each is a false-negative probe and why only
    one of the four is self-sufficient."""
    from tools import dbc  # local import: keeps this module importable without DBCs
    auto = frozenset(r["spell"] for r in dbc.iter_named("SkillLineAbility")
                     if r["acquireMethod"] != 0)
    trainer = frozenset(r["spellId"] for r in dbc.iter_named("NPCTrainer"))
    names, triggered_by = {}, defaultdict(set)
    for r in dbc.iter_named("Spell"):
        n = norm(r["name_enUS"])
        if n:
            names[r["id"]] = n
        for slot in (1, 2, 3):
            t = r[f"effectTriggerSpell{slot}"]
            if t:
                triggered_by[t].add(r["id"])
    return {"autoGrantSpellIds": auto, "trainerSpellIds": trainer,
            "spellNameNorm": names,
            "triggeredBySpellIds": {k: frozenset(v)
                                    for k, v in triggered_by.items()}}


def chain_names_norm(spell_ids, alt) -> set:
    """The distinct non-blank normalized Spell.dbc names carried by a rank chain.
    <= 1 name means coherent - see classify_entry's liveViaRank gate."""
    n = alt["spellNameNorm"]
    return {v for v in (n.get(i) for i in spell_ids) if v}


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


ALT_SIGNALS = ("skillLineAutoGrant", "npcTrainerRow", "liveNodeTriggerSpell",
               "liveNodeNameTwin")


def alt_signals(entry, class_live, alt) -> list:
    """Which non-tree acquisition signals fire for a NOT-in-the-trees entry.
    Order is stable (ALT_SIGNALS) so the emitted evidence is deterministic - the
    three spell-id-level signals first, the name-level one last."""
    own, ranks = entry_spell_ids(entry)
    chain = set(own) | set(ranks)
    out = []
    if chain & alt["autoGrantSpellIds"]:
        out.append("skillLineAutoGrant")
    if chain & alt["trainerSpellIds"]:
        out.append("npcTrainerRow")
    if triggering_live_nodes(chain, class_live, alt):
        out.append("liveNodeTriggerSpell")
    if norm(entry.get("name")) in class_live["nodeNamesNorm"]:
        out.append("liveNodeNameTwin")
    return out


def triggering_live_nodes(chain, class_live, alt) -> set:
    """Live nodes of THIS class that cast one of `chain` as an effectTriggerSpell.
    Same-class is the point: a global trigger join would fire on any proc anywhere
    in the client and mean nothing about this class's acquisition paths."""
    srcs = set()
    trig = alt["triggeredBySpellIds"]
    for sid in chain:
        srcs |= trig.get(sid, frozenset())
    return srcs & set(class_live["spellNodes"])


def classify_entry(entry, class_live, alt) -> tuple:
    """(live, liveEvidence) for one CAD entry. `class_live` is
    live_index()["byClassId"][classId], or None when the class has no builder
    file at all. See the module docstring for the full rule."""
    if class_live is None:
        return None, {"reason": "unknownNoGeometry", "matchedSpellId": None,
                      "builderTab": None}
    nodes = class_live["spellNodes"]
    own = [s["id"] for s in entry.get("spells", ())]
    own_set = set(own)
    for sid in own:
        hit = nodes.get(sid)
        if hit:
            return True, {"reason": "liveDirect", "matchedSpellId": sid,
                          "builderTab": hit["tabName"], "builderNodeId": hit["nodeId"]}

    # Rank pass, PER SPELL so coherence is judged within one SpellRankData chain
    # (an entry may legitimately carry several differently-named spells; a chain
    # may not). A recycled id block matches a live node by accident, so a match is
    # only believed when the chain carries at most one distinct Spell.dbc name.
    rejected = None
    for s in entry.get("spells", ()):
        chain_ids = [r["spellId"] for r in (s.get("ranks") or ())
                     if r.get("spellId") and r["spellId"] not in own_set]
        hit_sid = next((sid for sid in chain_ids if sid in nodes), None)
        if hit_sid is None:
            continue
        chain_names = chain_names_norm([s["id"]] + chain_ids, alt)
        if len(chain_names) > 1:
            if rejected is None:
                rejected = {"spellId": s["id"], "wouldHaveMatched": hit_sid,
                            "distinctChainNames": sorted(chain_names)}
            continue
        hit = nodes[hit_sid]
        return True, {"reason": "liveViaRank", "matchedSpellId": hit_sid,
                      "builderTab": hit["tabName"], "builderNodeId": hit["nodeId"],
                      "chainNameCoherent": True}

    signals = alt_signals(entry, class_live, alt)
    ev = {"matchedSpellId": None, "builderTab": None}
    if rejected is not None:
        # keep the disproof attached to the row it disqualified
        ev["rejectedRankMatch"] = rejected
    if signals:
        return None, dict(ev, reason="indeterminate", signals=signals)
    return False, dict(ev, reason="deadCatalog")


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
