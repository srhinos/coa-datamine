"""Ability-identity layer -> data/abilities/ : the join across CoA's spell-id
generations.

The defect this repairs: one CoA ability exists under several unrelated spell
ids - the CAD catalog id, the trainer-taught rank ids, and the id the LIVE
talent-tree node actually carries - with no join table anywhere in the client.
Every consumer that read one generation and assumed it had the ability was
wrong; measured, only 1,963 of the 3,932 spell ids the live trees reference had
a curated record at all.

Everything below is derived from raw/ in one pass. No hand-authored names, no
hardcoded id lists, no per-ability judgement: the group key is
(classId, normalized spell name, live-node variant) and every membership carries
the evidence row that produced it.

THE VARIANT IN THE KEY (the false-merge repair)
-----------------------------------------------
(classId, name) alone is NOT an identity. Measured on this snapshot, 35 groups
contain two or more DISTINCT live builder nodes that merely share a name, 22 of
them across different tabs, and all 35 carry different base-Spell descriptions -
they are different abilities. c12:savage was one record with two live nodes:
560441 (Brutality, "Unbridled Rage now also increases your critical damage") and
705242 (Headhunting, "Born in Blood now also increases your damage"). Coverage
never noticed - every id is in the closure either way - but a consumer reading an
ability as one thing with ranks got a two-rank ability with contradictory text.

The gate is mechanical and needs no judgement: two distinct live nodes stay in
one ability only if their EFFECT SIGNATURE agrees, where a node's signature is
its own name plus, over every spell id it carries, (description, tooltip, the
three effect ids, the three effect auras, the three effect misc values, the
spell icon). Nodes whose signatures disagree are split into one record per
signature, keyed `c<class>:<name>#<lowest live spell id>`, and the siblings are
cross-referenced in `linkedKeys` (relation `liveNodeVariant`) so the split is one
hop away rather than invisible. When a group splits, the bare `c<class>:<name>`
key is left to members that no live node claims - it never silently means one of
the variants. Counted every build into _meta.json's `liveNodeVariantGate`.

SOURCES (all raw/, all this snapshot)
  liveNode   raw/talents/coa-builder-<slug>.html - the frozen capture of the
             live ascension.gg builder payload, parsed by tools/coa_live.py.
             RAW HOLDS THE PAYLOAD; data/talents/coa/ is a derived copy of the
             same parse and is deliberately not read here.
  cad        raw/content/CharacterAdvancementData.json (the account-wide CAD
             catalog - a STALE content generation, used as one generation among
             several, never as the seed of truth).
  trainer    raw/tables/NPCTrainer/ (f0 id, f1 spellId, f2 skillLine - the
             proven column map, see tools/dbc.py).
  rankChain  raw/content/SpellRankData.json (firstSpellId/rank/level/spellId).
  names      raw/tables/Spell/variants/data-patch-t-mpq/ - the BASE variant, the
             Spell.dbc a CoA character actually reads. NOT the chain winner at
             raw/tables/Spell/, which is area-52's realm overlay. Measured on
             this snapshot: all 3,932 live-node spell ids resolve in the base
             variant, 3,929 in the overlay - the overlay is missing live CoA
             content, so reading it would silently drop 3 abilities' names.
  classes    raw/tables/ChrClasses/ (f0 id, f4 name_enUS, f55 filename token).
  skill      raw/tables/SkillLineAbility/ + raw/tables/SkillLine/ - only as
             trainer-row class corroboration, see stage 3.

THE TRAPS THIS REPO HAS BEEN BURNED BY, and what is done about them
  * Dense id spaces make containment meaningless. The base Spell id space is
    209,151 ids over 1..13,977,920, but ids are not spread evenly: across the
    23 100k-blocks any of the four sources touch, occupancy averages 9.0% and
    peaks at 69.0% (block 0). A bare "this id exists in Spell.dbc" test is
    therefore worth very little and is never used as a join here - every
    membership needs a row that names a class or a chain. The measured
    densities are emitted in _meta.json's `idDensity` so a reader can see the
    size of the effect rather than take a claim for it.
  * SpellRankData contains recycled non-chains. 94 of the 2,130 chains carry
    more than one distinct spell name - contiguous id blocks reused for
    unrelated content, not rank ladders. The proven case is
    chain head 801667: rank 1 "Revitalize (Rank 1 DEPRECATED)", rank 6 "Ascetic
    Abdication", rank 7 "Fearmonger", rank 8 "War Cry", rank 9 "Umbral Glaive",
    rank 10 "Ice Hide", rank 11 "Mirage". Chain expansion is gated on name
    coherence (at most ONE distinct normalized name among the chain's members
    that resolve in the base Spell table); incoherent chains are dropped whole
    and counted.
  * `live` here is a CONQUEST OF AZEROTH claim from an EXTERNAL capture that
    drifts independently of the client snapshot - see coa_live.REALM_CAVEAT,
    copied into _meta.json.

NAME NORMALIZATION (mechanical, measured - no hand mapping)
  norm_name(s):
    1. repeatedly strip a trailing rank marker  [\\s\\-(\\[]*rank\\s*\\d+[)\\]]*$
       (case-insensitive), then strip whitespace;
    2. lowercase and delete every non-alphanumeric character.
  Why only that: the base Spell table keeps the rank in its OWN column
  (rank_enUS / f153 - "Rank 1".."Rank N", 2,985 distinct values), so a name
  almost never carries one; exactly 21 of 209,206 base names end in a "Rank N"
  marker, and those 21 are the whole reason step 1 exists. Two neighbouring
  suffix shapes are deliberately NOT stripped, because they are not the rank
  carrier and stripping them would merge distinct spells: trailing roman
  numerals ("Fire Shield II", 508 names) and trailing bare digits ("Wavestorm
  2", 3,880 names). All four counts are recomputed every build into
  _meta.json's `nameNormalization` so the rule is auditable against the snapshot
  rather than asserted.

MEMBERSHIP STAGES (a member id can carry several generations; `generation` is
the primary one by the precedence liveNode > trainer > cad > rankChain)
  1 SEED - only two generations carry a class of their own:
      liveNode  the builder node's own classId.
      cad       the CAD row's `Class` string -> ChrClasses, by normalized
                name then normalized filename token, with a leading "Reborn"
                stripped (the same mechanical rule build_classes.py uses).
  2 RANK CHAIN - for every name-coherent SpellRankData chain, every classId
    already attributed to any member is attributed to ALL of its members. This
    is what carries a trainer-taught rank ladder onto the ability whose base
    rank is a live node.
  3 TRAINER - an NPCTrainer row marks its spellId trainer-taught. When that id
    already belongs to an ability (stages 1-2) the row is a marker on the
    existing membership. When it does not, the id is admitted ONLY with
    corroborating class evidence, never on a bare name match:
      skillLineAbilityClassMask   the id's SkillLineAbility rows carry exactly
                                  one class bit, and an ability with this id's
                                  normalized name exists for that class.
      trainerSkillLineSharedWithMember
                                  the trainer row's skillLine is carried (via
                                  SkillLineAbility) by an already-attributed
                                  member of exactly one same-named ability.
    A bare name match with no class evidence is refused and lands in the
    residual as `trainerNameOnlyNoCorroboration`, with its candidate ability
    keys recorded, so the refusal is inspectable instead of invisible.

Single-writer (Amendment D): this module owns data/abilities/ exclusively and
writes nothing else. It reads raw/ only - no data/ input at all - so it is a
pure function of the snapshot.
"""
import gzip
import json
import re
from collections import Counter, defaultdict

from tools import config, coa_live, sharding

MAX_LINES = 5000
BASE_SPELL_VARIANT = "data-patch-t-mpq"
OUT_DIRNAME = "abilities"

# Precedence for the single `generation` label on a member that carries several.
GENERATIONS = ("liveNode", "trainer", "cad", "rankChain")

_RANK_TAIL = re.compile(r"[\s\-–(\[]*\brank\s*\d+\s*[)\]]*\s*$", re.I)
_NON_ALNUM = re.compile(r"[^a-z0-9]")
_ROMAN_TAIL = re.compile(r"\s+(?:i{1,3}|iv|v|vi{1,3}|ix|x)\s*$", re.I)
_DIGIT_TAIL = re.compile(r"\s+\d+\s*$")


def norm_name(s) -> str:
    """The ability-grouping name key. See the module docstring's NAME
    NORMALIZATION block for the measured justification of every step."""
    s = (s or "").strip()
    while True:
        stripped = _RANK_TAIL.sub("", s).strip()
        if stripped == s:
            break
        s = stripped
    return _NON_ALNUM.sub("", s.lower())


def _norm(s) -> str:
    return _NON_ALNUM.sub("", (s or "").lower())


# ---------------------------------------------------------------------------
# raw/tables readers
# ---------------------------------------------------------------------------

def _table_dir(name: str):
    return config.RAW_DIR / "tables" / name


def iter_raw_table(name: str, variant: str = None):
    """Every decoded row of a raw/tables table, in shard then file order. `variant`
    selects raw/tables/<T>/variants/<slug>/ instead of the chain winner."""
    d = _table_dir(name)
    if variant:
        d = d / "variants" / variant
    if not d.is_dir():
        raise RuntimeError(f"build_abilities: {d} not found - raw/tables layer missing")
    files = sorted(d.glob("*.jsonl")) + sorted(d.glob("*.jsonl.gz"))
    if not files:
        raise RuntimeError(f"build_abilities: no shards under {d}")
    for f in files:
        op = gzip.open if f.suffix == ".gz" else open
        with op(f, "rt", encoding="utf-8") as fh:
            for line in fh:
                if line.strip():
                    yield json.loads(line)


def _read_json(path):
    return json.loads(path.read_text(encoding="utf-8-sig"))


# ---------------------------------------------------------------------------
# The layer, read back: the LIVE-truth seed for every downstream curated view
# ---------------------------------------------------------------------------

def iter_abilities():
    """Every ability record in this layer, class order then file order."""
    d = config.DATA_DIR / OUT_DIRNAME
    index = _read_json(d / "index.json")
    for cls in index["classes"]:
        for name in cls["files"]:
            for rec in _read_json(d / name)["abilities"]:
                yield rec


def live_seed() -> dict:
    """What the curated layer must be seeded from, instead of the CAD catalog.

    `liveNodeIds` is the ground truth this repo was measured against: every
    spell id a LIVE talent-tree node carries. `seedIds` is that set closed over
    ability IDENTITY - for an ability with a live node, every id in every
    generation of it (the trainer ladder, the rank chain, the catalog row) names
    the same ability and belongs in the same curated closure. That closure is
    what turns 1,963/3,932 into full coverage, and none of it is a guess: each
    membership carries the evidence row that produced it (see this module's
    stage comments).

    `byId` is the per-id evidence every curated record then stamps as `live` +
    `liveEvidence`, so a consumer never has to re-derive the join - and CAD-only
    ids get a record too, marked live:false rather than dropped."""
    live_node_ids, seed, by_id, by_class = set(), {}, {}, {}
    for a in iter_abilities():
        for m in a["members"]:
            sid = m["id"]
            by_class.setdefault((a["classId"], sid), {
                "abilityKey": a["key"], "abilityName": a["name"],
                "classId": a["classId"], "abilityLive": a["live"],
                "generation": m["generation"], "generations": m["generations"],
                "liveNodeIds": a["liveIds"], "trainerTaught": a["trainerTaught"]})
            if "liveNode" in m["generations"]:
                live_node_ids.add(sid)
            prev = by_id.get(sid)
            # An id can sit in several classes' abilities (shared/pet spells).
            # Prefer the live one, then the one with more generations behind it,
            # so the stamped evidence is the strongest available - ties broken on
            # (classId, key) so the choice is deterministic, never file order.
            cand = (a["live"], len(m["generations"]), -a["classId"], a["key"])
            if prev is None or cand > prev["_rank"]:
                by_id[sid] = {
                    "_rank": cand,
                    "abilityKey": a["key"], "abilityName": a["name"],
                    "classId": a["classId"], "abilityLive": a["live"],
                    "generation": m["generation"],
                    "generations": m["generations"],
                    "liveNodeIds": a["liveIds"],
                    "trainerTaught": a["trainerTaught"],
                }
            if a["live"]:
                seed.setdefault(sid, set()).update(m["generations"])
    for v in by_id.values():
        del v["_rank"]
    return {"liveNodeIds": live_node_ids,
            "seedIds": {k: sorted(v) for k, v in seed.items()},
            # The classes a live tree was actually CAPTURED for. Load-bearing, not
            # informational: `live: false` is only sayable about a class whose tree
            # this snapshot can see. The builder capture covers CoA's custom
            # classes; for a vanilla class it captures nothing, and reading that as
            # "Power Word: Shield is not in the game" would be inventing evidence
            # out of an absent measurement.
            "classesWithLiveGeometry": {
                int(cid) for cid, c in coa_live.live_index().get(
                    "byClassId", {}).items() if c.get("spellNodes")},
            "byId": by_id,
            # (classId, spellId) -> that class's own ability for the id. An id can
            # belong to several classes' abilities (shared and pet spells); a
            # per-class consumer must not be handed another class's verdict, and
            # `byId` deliberately collapses to one, so both indexes exist.
            "byClassMember": by_class}


# ---------------------------------------------------------------------------
# Sources
# ---------------------------------------------------------------------------

def load_base_spells(sig_ids=None) -> tuple:
    """({spellId: {"name", "rank", "spellLevel", "baseLevel"}}, {spellId: signature})
    from the BASE Spell variant. Column indexes are tools/dbc.py's proven Spell map
    (f136 name_enUS, f153 rank_enUS, f39 spellLevel, f38 baseLevel).

    `sig_ids` is the id set to also build an EFFECT SIGNATURE for - the live-node
    ids, and only those, because that is the only place a signature is used and
    keeping 209k descriptions resident costs memory for nothing. The signature is
    what decides whether two same-named live nodes are one ability: description
    (f170) and tooltip (f187), the effect triple (f71-73), the effect-aura triple
    (f95-97), the effect-miscValue triple (f110-112) and the icon (f133) - i.e.
    what the ability SAYS and what it DOES, both of which two unrelated abilities
    sharing a name disagree on and two ranks of one ability do not."""
    sig_ids = sig_ids or set()
    out, sigs = {}, {}
    for r in iter_raw_table("Spell", BASE_SPELL_VARIANT):
        sid = r["f0"]
        out[sid] = {"name": r.get("f136") or "", "rank": r.get("f153") or "",
                    "spellLevel": r.get("f39"), "baseLevel": r.get("f38")}
        if sid in sig_ids:
            sigs[sid] = (
                (r.get("f170") or "").strip(),
                (r.get("f187") or "").strip(),
                tuple(r.get(f"f{71 + i}") for i in range(3)),
                tuple(r.get(f"f{95 + i}") for i in range(3)),
                tuple(r.get(f"f{110 + i}") for i in range(3)),
                r.get("f133"),
            )
    return out, sigs


SIGNATURE_FIELDS = ("description_enUS/f170", "tooltip_enUS/f187",
                    "effect1-3/f71-73", "effectAura1-3/f95-97",
                    "effectMiscValue1-3/f110-112", "spellIconID/f133")


def live_node_variants(live, spells, sigs, norm_of) -> tuple:
    """Split same-named DISTINCT live nodes that are not the same ability.

    Returns ({(classId, normName, nodeId): variant}, {(classId, normName): [...]}),
    where `variant` is "" when the group holds one live node (the overwhelming
    majority - nothing changes for them) and otherwise the lowest live spell id of
    that node's signature partition, as a string.

    The rule, restated so it is checkable against the emitted evidence: group the
    class's live nodes by normalized name; inside a group, give each node the
    signature (its own name, the set over its spell ids of the SIGNATURE_FIELDS
    tuple); nodes whose signatures are equal are the same ability and stay merged,
    nodes whose signatures differ are different abilities and are split. No name
    list, no id list, no per-ability call."""
    groups = defaultdict(lambda: defaultdict(set))       # (cid,norm) -> nodeId -> sids
    node_name = {}
    node_tab = {}
    for cid, cl in live["byClassId"].items():
        for sid, node in cl["spellNodes"].items():
            n = norm_of(sid) or norm_name(node["nodeName"])
            if not n:
                continue
            groups[(cid, n)][node["nodeId"]].add(sid)
            node_name[(cid, node["nodeId"])] = (node["nodeName"] or "").strip()
            node_tab[(cid, node["nodeId"])] = node.get("tabName")

    variant_of, splits = {}, {}
    for (cid, n), nodes in sorted(groups.items()):
        if len(nodes) < 2:
            continue
        sig_of = {nid: (node_name[(cid, nid)],
                        frozenset(sigs.get(sid, ("noBaseSpellRow", sid))
                                  for sid in sorted(ids)))
                  for nid, ids in nodes.items()}
        parts = defaultdict(list)
        for nid, s in sig_of.items():
            parts[s].append(nid)
        if len(parts) < 2:
            continue
        members = []
        for _, nids in sorted(parts.items(),
                              key=lambda kv: min(min(nodes[i]) for i in kv[1])):
            sids = sorted(sid for nid in nids for sid in nodes[nid])
            var = str(sids[0])
            for nid in nids:
                variant_of[(cid, n, nid)] = var
            members.append({
                "variant": var,
                "key": f"c{cid}:{n}#{var}",
                "liveNodeIds": sorted(nids),
                "liveSpellIds": sids,
                "liveNodeNames": sorted({node_name[(cid, i)] for i in nids}),
                "tabs": sorted({node_tab[(cid, i)] for i in nids if node_tab[(cid, i)]}),
            })
        splits[(cid, n)] = members
    return variant_of, splits


def load_classes() -> tuple:
    """(byId, byNormName, byNormFilename) from raw/tables/ChrClasses."""
    by_id, by_name, by_file = {}, {}, {}
    for r in iter_raw_table("ChrClasses"):
        rec = {"classId": r["f0"], "name": r.get("f4") or "",
               "filename": r.get("f55") or ""}
        by_id[rec["classId"]] = rec
        by_name.setdefault(_norm(rec["name"]), rec)
        by_file.setdefault(_norm(rec["filename"]), rec)
    return by_id, by_name, by_file


def resolve_cad_class(cls_string, by_name, by_file):
    """CAD `Class` -> ChrClasses row, by the same mechanical rule build_classes.py
    uses: strip a leading "Reborn" (the Reborn game mode reuses the base class
    names), then normalized name, then normalized filename token. Returns
    (row_or_None, base_string)."""
    base = (cls_string or "").removeprefix("Reborn") if (cls_string or "").startswith("Reborn") \
        else (cls_string or "")
    return by_name.get(_norm(base)) or by_file.get(_norm(base)), base


# ---------------------------------------------------------------------------
# Build
# ---------------------------------------------------------------------------

class _Attrib:
    """The accumulating (classId, normName, variant) -> member-id evidence table.

    `variant` is "" for every ability whose name identifies exactly one live node
    (or none), and the live-node variant discriminator otherwise - see
    live_node_variants()."""

    def __init__(self):
        # (classId, normName, variant) -> {spellId: {"generations", "evidence"}}
        self.abilities = defaultdict(dict)
        # spellId -> set of (classId, normName, variant) it belongs to
        self.by_id = defaultdict(set)

    def add(self, class_id, norm, spell_id, generation, evidence, multi=False,
            variant=""):
        key = (class_id, norm, variant)
        m = self.abilities[key].get(spell_id)
        if m is None:
            m = {"generations": set(), "evidence": {}}
            self.abilities[key][spell_id] = m
        m["generations"].add(generation)
        if multi:
            m["evidence"].setdefault(generation, []).append(evidence)
        else:
            m["evidence"].setdefault(generation, evidence)
        self.by_id[spell_id].add(key)
        return key


def _key_of(key) -> str:
    """(classId, normName, variant) -> the published ability key. The variant
    suffix is the partition's lowest live spell id, so the key is stable against
    everything except that live node changing id."""
    cid, n, var = key
    return f"c{cid}:{n}#{var}" if var else f"c{cid}:{n}"


def _variant_for(A, spell_id, class_id, norm) -> str:
    """The variant an ALREADY-ATTRIBUTED id carries inside (class_id, norm), or ""
    when nothing has claimed it or two variants both have (in which case no
    evidence picks one and the bare key is the honest home)."""
    vs = {k[2] for k in A.by_id.get(spell_id, ()) if k[0] == class_id and k[1] == norm}
    return next(iter(vs)) if len(vs) == 1 else ""


def build(slug: str = "voljin") -> dict:
    live = coa_live.live_index(slug)
    live_node_ids = {sid for cl in live["byClassId"].values()
                     for sid in cl["spellNodes"]}
    spells, live_sigs = load_base_spells(live_node_ids)
    cls_by_id, cls_by_name, cls_by_file = load_classes()

    def spell_norm(sid):
        s = spells.get(sid)
        return norm_name(s["name"]) if s and s["name"] else ""

    # Which same-named live nodes are NOT the same ability. Computed before any
    # membership is recorded, because it decides the key every stage writes to.
    variant_of, variant_splits = live_node_variants(live, spells, live_sigs,
                                                    spell_norm)
    cad = _read_json(config.RAW_CONTENT_DIR / "CharacterAdvancementData.json")
    srd = _read_json(config.RAW_CONTENT_DIR / "SpellRankData.json")
    trainer_rows = [r for r in iter_raw_table("NPCTrainer")]
    skill_names = {r["f0"]: (r.get("f3") or "") for r in iter_raw_table("SkillLine")}
    sla_rows = [r for r in iter_raw_table("SkillLineAbility")]

    A = _Attrib()
    stats = Counter()
    residual = defaultdict(list)

    # ---- stage 1a: liveNode -------------------------------------------------
    live_ids_by_class = defaultdict(set)
    for cid, cl in live["byClassId"].items():
        for sid, node in cl["spellNodes"].items():
            n = spell_norm(sid)
            name_source = "baseSpell"
            if not n:
                n, name_source = norm_name(node["nodeName"]), "liveNodeName"
                stats["liveIdNoBaseSpellRow"] += 1
            if not n:
                residual["liveNodeNoName"].append({"spellId": sid, "classId": cid,
                                                   "nodeId": node["nodeId"]})
                continue
            var = variant_of.get((cid, n, node["nodeId"]), "")
            A.add(cid, n, sid, "liveNode",
                  {"nodeId": node["nodeId"], "nodeName": node["nodeName"],
                   "tabId": node["tabId"], "tabName": node["tabName"],
                   "nameSource": name_source,
                   "liveNodeVariant": var or None}, variant=var)
            live_ids_by_class[cid].add(sid)
            stats["liveMemberships"] += 1
            if var:
                stats["liveMembershipsInSplitVariant"] += 1
    live_ids = {sid for s in live_ids_by_class.values() for sid in s}

    # ---- stage 1b: cad ------------------------------------------------------
    cad_name_agree = Counter()
    cad_ids = set()
    for e in cad:
        cad_ids.update(e.get("Spells") or ())
        row_cls, base_cls = resolve_cad_class(e.get("Class"), cls_by_name, cls_by_file)
        if row_cls is None:
            for sid in (e.get("Spells") or ()):
                residual["cadUnresolvedClass"].append(
                    {"spellId": sid, "cadId": e["ID"], "cadClass": e.get("Class")})
            stats["cadRowsUnresolvedClass"] += 1
            continue
        cid = row_cls["classId"]
        for sid in (e.get("Spells") or ()):
            n = spell_norm(sid)
            name_source = "baseSpell"
            if n:
                cad_name_agree["resolved"] += 1
                if n == norm_name(e.get("Name")):
                    cad_name_agree["cadNameMatchesSpellName"] += 1
            else:
                n, name_source = norm_name(e.get("Name")), "cadRowName"
                stats["cadIdNoBaseSpellRow"] += 1
            if not n:
                residual["cadNoName"].append({"spellId": sid, "cadId": e["ID"]})
                continue
            # A catalog id in a SPLIT group belongs to the variant that already
            # owns the id (it IS one of that live node's spell ids) and to no
            # variant otherwise: the catalog says nothing about which of two
            # same-named live nodes it meant, and guessing is what produced the
            # false merges in the first place. Those land on the bare key, which
            # is why the bare key is never one of the variants.
            var = _variant_for(A, sid, cid, n)
            if var:
                stats["cadMembershipsInSplitVariant"] += 1
            elif (cid, n) in variant_splits:
                stats["cadMembershipsUnattributedInSplitGroup"] += 1
            A.add(cid, n, sid, "cad",
                  {"cadId": e["ID"], "cadName": e.get("Name"),
                   "cadClass": e.get("Class"), "tab": e.get("Tab"),
                   "type": e.get("Type"), "requiredLevel": e.get("RequiredLevel"),
                   "nameSource": name_source}, multi=True, variant=var)
            stats["cadMemberships"] += 1

    # ---- stage 2: rank chains ----------------------------------------------
    chains = defaultdict(list)
    for r in srd:
        chains[r["firstSpellId"]].append(r)
    chain_of = {}          # spellId -> list of (head, rank, level)
    chain_ids = set()
    coherent, incoherent, incoherent_examples = 0, 0, []
    for head, rows in chains.items():
        members = sorted({head} | {r["spellId"] for r in rows})
        chain_ids.update(members)
        names = {spell_norm(i) for i in members}
        names.discard("")
        if len(names) > 1:
            incoherent += 1
            if len(incoherent_examples) < 10:
                incoherent_examples.append(
                    {"chainHead": head, "distinctNames": sorted(names),
                     "memberIds": members})
            for sid in members:
                residual["rankChainNameIncoherent"].append(
                    {"spellId": sid, "chainHead": head})
            continue
        coherent += 1
        chain_name = next(iter(names)) if names else ""
        for r in rows:
            chain_of.setdefault(r["spellId"], []).append(
                {"chainHead": head, "rank": r["rank"], "level": r["level"]})
        # every classId any member already carries propagates to the whole chain.
        # The seed key carries the VARIANT too: a chain that reaches one split
        # variant's live node expands that variant's ladder, not its sibling's.
        seeds = defaultdict(set)   # (classId, variant) -> member ids that seeded it
        for sid in members:
            for (cid, n, var) in A.by_id.get(sid, ()):
                if chain_name and n != chain_name:
                    continue
                seeds[(cid, var)].add(sid)
        if not seeds and chain_name and any(A.by_id.get(sid) for sid in members):
            # a class-carrying member exists but under a DIFFERENT name than the
            # chain's - deliberately not a seed (see the name gate above); counted
            # so the conservatism is visible rather than silent.
            stats["rankChainSeedNameMismatch"] += 1
        if not seeds or not chain_name:
            continue
        for (cid, var), via in sorted(seeds.items()):
            via_id = min(via)
            for sid in members:
                rank_rows = [r for r in rows if r["spellId"] == sid]
                A.add(cid, chain_name, sid, "rankChain",
                      {"chainHead": head, "viaMemberId": via_id,
                       "rank": rank_rows[0]["rank"] if rank_rows else None,
                       "level": rank_rows[0]["level"] if rank_rows else None,
                       "chainNameCoherent": True}, variant=var)
                stats["rankChainMemberships"] += 1

    # ---- stage 3: trainer ---------------------------------------------------
    sla_by_spell = defaultdict(list)
    for r in sla_rows:
        sla_by_spell[r["f2"]].append(r)

    def class_bits(mask):
        return [i + 1 for i in range(32) if mask & (1 << i)]

    def sla_single_class(sid):
        bits = set()
        for r in sla_by_spell.get(sid, ()):
            bits.update(class_bits(r["f4"]))
        return next(iter(bits)) if len(bits) == 1 else None

    def sla_skill_lines(sid):
        return {r["f1"] for r in sla_by_spell.get(sid, ())}

    trainer_ids = set()
    trainer_by_id = defaultdict(list)
    for r in trainer_rows:
        if r["f1"] <= 0:
            residual["trainerSentinelSpellId"].append(
                {"spellId": r["f1"], "trainerRowId": r["f0"]})
            continue
        trainer_ids.add(r["f1"])
        trainer_by_id[r["f1"]].append(r)

    # ability -> the skill lines its already-attributed members carry
    ability_skill_lines = defaultdict(set)
    for key, members in A.abilities.items():
        for sid in members:
            ability_skill_lines[key] |= sla_skill_lines(sid)

    by_norm_name = defaultdict(set)
    for key in A.abilities:
        by_norm_name[key[1]].add(key)

    for sid in sorted(trainer_ids):
        rows = trainer_by_id[sid]
        existing = sorted(A.by_id.get(sid, ()))
        if existing:
            for key in existing:
                for r in rows:
                    A.add(key[0], key[1], sid, "trainer",
                          {"trainerRowId": r["f0"], "skillLine": r["f2"],
                           "skillLineName": skill_names.get(r["f2"]),
                           "attribution": "alreadyMember"}, multi=True,
                          variant=key[2])
                    stats["trainerMembershipsOnExisting"] += 1
            continue
        n = spell_norm(sid)
        if not n:
            residual["trainerNoBaseSpellRow"].append(
                {"spellId": sid, "trainerRowIds": [r["f0"] for r in rows]})
            continue
        candidates = by_norm_name.get(n) or set()
        if not candidates:
            residual["trainerNoSameNamedAbility"].append(
                {"spellId": sid, "normName": n,
                 "skillLines": sorted({r["f2"] for r in rows})})
            continue
        cid = sla_single_class(sid)
        chosen, how = None, None
        # A class-mask hit selects a class, not a variant: if that class's name
        # group SPLIT, the mask cannot say which live node the trainer teaches, so
        # the id is refused exactly as an ambiguous name match is.
        same_class = [k for k in sorted(candidates) if k[0] == cid] if cid is not None else []
        if len(same_class) == 1:
            chosen, how = same_class[0], "skillLineAbilityClassMask"
        elif len(same_class) > 1:
            stats["trainerAmbiguousAcrossLiveNodeVariants"] += 1
        if chosen is None:
            row_lines = {r["f2"] for r in rows if r["f2"]}
            shared = [k for k in sorted(candidates)
                      if row_lines & ability_skill_lines.get(k, set())]
            if len(shared) == 1:
                chosen, how = shared[0], "trainerSkillLineSharedWithMember"
        if chosen is None:
            residual["trainerNameOnlyNoCorroboration"].append(
                {"spellId": sid, "normName": n,
                 "candidateAbilities": [_key_of(k) for k in sorted(candidates)],
                 "skillLines": sorted({r["f2"] for r in rows})})
            continue
        for r in rows:
            A.add(chosen[0], chosen[1], sid, "trainer",
                  {"trainerRowId": r["f0"], "skillLine": r["f2"],
                   "skillLineName": skill_names.get(r["f2"]),
                   "attribution": how}, multi=True, variant=chosen[2])
            stats["trainerMembershipsAdmitted"] += 1

    # ---- assemble ability records ------------------------------------------
    srd_by_spell = defaultdict(list)
    for r in srd:
        srd_by_spell[r["spellId"]].append(r)

    records = []
    for (cid, n, var), members in A.abilities.items():
        member_recs = []
        raw_names = Counter()
        for sid in sorted(members):
            m = members[sid]
            s = spells.get(sid)
            if s and s["name"]:
                raw_names[s["name"]] += 1
            gens = sorted(m["generations"], key=GENERATIONS.index)
            member_recs.append({
                "id": sid,
                "name": s["name"] if s else None,
                "rank": s["rank"] if s else None,
                "spellLevel": s["spellLevel"] if s else None,
                "inBaseSpell": s is not None,
                "generation": gens[0],
                "generations": gens,
                "evidence": {g: m["evidence"][g] for g in gens},
            })
        gens_all = sorted({g for r in member_recs for g in r["generations"]},
                          key=GENERATIONS.index)
        live_members = sorted(r["id"] for r in member_recs
                              if "liveNode" in r["generations"])
        trainer_members = sorted(r["id"] for r in member_recs
                                 if "trainer" in r["generations"])
        ladder = []
        for r in member_recs:
            for row in srd_by_spell.get(r["id"], ()):
                ladder.append({"spellId": r["id"], "rank": row["rank"],
                               "level": row["level"], "chainHead": row["firstSpellId"],
                               "trainerTaught": r["id"] in trainer_members,
                               "live": r["id"] in live_members})
        ladder.sort(key=lambda x: (x["level"], x["rank"], x["spellId"]))
        display = (raw_names.most_common(1)[0][0] if raw_names else
                   next((r["name"] for r in member_recs if r["name"]), None))
        split = variant_splits.get((cid, n))
        records.append({
            "key": _key_of((cid, n, var)),
            "classId": cid,
            "class": cls_by_id[cid]["name"] if cid in cls_by_id else None,
            "name": display,
            "normName": n,
            # "" for the 99.6% of abilities whose name identifies one live node.
            # On a split name: the variant's own discriminator, or null on the
            # bare key, which holds only what no live node claimed.
            "liveNodeVariant": var or None,
            "liveNodeVariantOf": (
                {"normName": n,
                 "variantKeys": [m["key"] for m in split],
                 "unattributedKey": f"c{cid}:{n}",
                 "rule": "distinctLiveNodeEffectSignature"} if split else None),
            "generations": gens_all,
            "generationCount": len(gens_all),
            "memberCount": len(member_recs),
            "live": bool(live_members),
            "liveIds": live_members,
            "liveId": live_members[0] if live_members else None,
            "trainerTaught": bool(trainer_members),
            "trainerIds": trainer_members,
            "rankLadder": ladder,
            "rankLadderLevels": [x["level"] for x in ladder],
            "members": member_recs,
        })
    records.sort(key=lambda r: (r["classId"], r["normName"], r["key"]))

    # ---- linkedKeys: the two ways one name spans several records -------------
    # sharedMemberId - the SAME ability under two different NAMES. The group key
    #   is a name, so an ability that changed name between generations lands in
    #   two records: CAD calls WitchHunter 802012 "Interrogate" while the live
    #   node for the same rank chain is "Brand of the Unworthy". They are not
    #   merged (a shared id is not proof two names are one ability, and merging on
    #   it would cascade through the vanilla chains), but every shared member id
    #   is recorded on BOTH records so the link is one hop away instead of
    #   invisible.
    # liveNodeVariant - two DIFFERENT abilities under one name, split by
    #   live_node_variants(). They share no member id (that is what makes them
    #   different), so this is the only thing that keeps them findable from each
    #   other, and from the bare key that holds what neither claimed.
    shared = defaultdict(lambda: defaultdict(list))
    for sid, keyset in A.by_id.items():
        if len(keyset) < 2:
            continue
        ks = sorted(_key_of(k) for k in keyset)
        for k in ks:
            for other in ks:
                if other != k:
                    shared[k][other].append(sid)
    by_group = defaultdict(list)
    for r in records:
        if r["liveNodeVariantOf"]:
            by_group[(r["classId"], r["normName"])].append(r["key"])
    for r in records:
        links = {k: {"key": k, "relation": "sharedMemberId",
                     "sharedMemberIds": sorted(v)}
                 for k, v in (shared.get(r["key"]) or {}).items()}
        for sib in by_group.get((r["classId"], r["normName"]), ()):
            if sib == r["key"]:
                continue
            links.setdefault(sib, {"key": sib, "sharedMemberIds": []})
            links[sib]["relation"] = "liveNodeVariant"
        r["linkedKeys"] = [links[k] for k in sorted(links)]
    stats["abilitiesWithCrossNameLink"] = sum(
        1 for r in records
        if any(l["relation"] == "sharedMemberId" for l in r["linkedKeys"]))
    stats["abilitiesWithLiveNodeVariantLink"] = sum(
        1 for r in records
        if any(l["relation"] == "liveNodeVariant" for l in r["linkedKeys"]))

    # ---- residual ids that join to nothing ----------------------------------
    joined = set(A.by_id)
    source_ids = {"liveNode": live_ids, "cad": cad_ids,
                  "trainer": trainer_ids, "rankChain": chain_ids}
    unjoined = {k: sorted(v - joined) for k, v in source_ids.items()}
    unjoined_all = sorted(set().union(*unjoined.values()))
    reason_by_id = defaultdict(set)
    for reason, rows in residual.items():
        for row in rows:
            if row.get("spellId") in joined or row.get("spellId") is None:
                continue
            reason_by_id[row["spellId"]].add(reason)
    residual_records = []
    for sid in unjoined_all:
        residual_records.append({
            "spellId": sid,
            "name": spells[sid]["name"] if sid in spells else None,
            "inBaseSpell": sid in spells,
            "sources": [k for k in ("liveNode", "cad", "trainer", "rankChain")
                        if sid in source_ids[k]],
            "reasons": sorted(reason_by_id.get(sid, ())) or ["noClassCarryingSource"],
        })

    # ---- measurements: id density + normalization + coherence ---------------
    block = 100000
    touched = sorted({i // block for i in
                      (live_ids | cad_ids | trainer_ids | chain_ids)})
    occ = Counter(i // block for i in spells)
    dens = {str(b * block): round(occ.get(b, 0) / block, 5) for b in touched}
    density = {
        "note": ("Containment in a dense id space proves nothing, so no membership "
                 "here is decided by 'this id exists in Spell.dbc'. These are the "
                 "numbers behind that rule."),
        "baseSpellRows": len(spells),
        "baseSpellIdMax": max(spells) if spells else 0,
        "overallDensity": round(len(spells) / max(spells), 6) if spells else 0,
        "blockSize": block,
        "touchedBlocks": len(touched),
        "meanDensityInTouchedBlocks":
            round(sum(occ.get(b, 0) for b in touched) / (len(touched) * block), 5)
            if touched else 0,
        "maxDensityInTouchedBlocks": max(dens.values()) if dens else 0,
        "densityByBlockStart": dens,
    }

    names_all = [v["name"] for v in spells.values()]
    name_norm_meta = {
        "rule": ("1) repeatedly strip a trailing rank marker "
                 r"[\s\-(\[]*rank\s*\d+[)\]]*$ (case-insensitive) then strip "
                 "whitespace; 2) lowercase and delete every non-alphanumeric "
                 "character."),
        "measuredOnBaseSpellNames": len(names_all),
        "namesWithTrailingRankMarker": sum(1 for x in names_all if _RANK_TAIL.search(x or "")),
        "distinctRankColumnValues": len({v["rank"] for v in spells.values()}),
        "namesWithTrailingRomanNumeral_NOTStripped":
            sum(1 for x in names_all if _ROMAN_TAIL.search(x or "")),
        "namesWithTrailingBareDigit_NOTStripped":
            sum(1 for x in names_all if _DIGIT_TAIL.search(x or "")),
        "why": ("The base Spell table carries the rank in its own column "
                "(rank_enUS/f153), so names almost never carry one - step 1 exists "
                "for the handful that do. Roman-numeral and bare-digit suffixes are "
                "left alone deliberately: they are not the rank carrier and "
                "stripping them would merge distinct spells."),
    }

    chain_meta = {
        "chains": len(chains),
        "coherent": coherent,
        "nameIncoherent": incoherent,
        "nameIncoherentRate": round(incoherent / (coherent + incoherent), 4)
                              if (coherent + incoherent) else 0,
        "gate": ("A chain expands an ability only when its members that resolve in "
                 "the base Spell table carry at most ONE distinct normalized name. "
                 "Recycled contiguous id blocks otherwise manufacture false "
                 "memberships."),
        "examples": incoherent_examples,
    }

    variant_meta = {
        "gate": ("(classId, name) is not an identity. Two DISTINCT live builder "
                 "nodes share one record only when their effect signatures agree; "
                 "when they disagree they are different abilities and are split "
                 "into one record per signature, keyed c<class>:<name>#<lowest "
                 "live spell id>. The bare c<class>:<name> key of a split name is "
                 "reserved for members no live node claims, so it can never "
                 "silently mean one of the variants."),
        "signatureFields": list(SIGNATURE_FIELDS),
        "signatureAlsoIncludes": "the live node's own name",
        "splitNameGroups": len(variant_splits),
        "variantRecords": sum(len(v) for v in variant_splits.values()),
        "splitAcrossTabs": sum(1 for v in variant_splits.values()
                               if len({t for m in v for t in m["tabs"]}) > 1),
        "unattributedRecordsOnSplitNames": sum(
            1 for r in records if r["liveNodeVariantOf"] and not r["liveNodeVariant"]),
        "why": ("Measured on this snapshot before the gate existed: these name "
                "groups each held two or more live nodes with DIFFERENT base-Spell "
                "descriptions, i.e. different abilities merged into one record "
                "with contradictory text and a fake rank ladder. Coverage never "
                "noticed - every id was in the closure either way."),
        "groups": [{"classId": cid, "class": cls_by_id.get(cid, {}).get("name"),
                    "normName": n, "variants": v}
                   for (cid, n), v in sorted(variant_splits.items())],
    }

    multi_gen = [r for r in records if r["generationCount"] > 1]
    live_recs = [r for r in records if r["live"]]
    live_trainer = [r for r in live_recs if r["trainerTaught"]]
    multi_live_node = [r for r in live_recs
                       if len({m["evidence"]["liveNode"]["nodeId"]
                               for m in r["members"]
                               if "liveNode" in m["generations"]}) > 1]

    summary = {
        "abilities": len(records),
        "abilitiesMultiGeneration": len(multi_gen),
        "abilitiesLive": len(live_recs),
        "liveAbilitiesWithTrainerLadder": len(live_trainer),
        "abilitiesWithRankLadder": sum(1 for r in records if r["rankLadder"]),
        "abilitiesWithCrossNameLink": stats["abilitiesWithCrossNameLink"],
        "liveNodeVariantSplitNames": len(variant_splits),
        "liveNodeVariantRecords": variant_meta["variantRecords"],
        # The false-merge measurement, kept as a first-class number rather than a
        # claim: an ability holding two distinct live nodes that were NOT proven
        # the same ability. The gate exists to keep this at zero.
        "abilitiesWithSeveralLiveNodeIds": len(multi_live_node),
        # Two different numbers, kept apart because they get confused: memberIds
        # counts DISTINCT spell ids the join owns, memberRows counts membership
        # rows - an id shared by several classes' abilities (pet and shared
        # spells) is one id and several rows.
        "memberIds": len(joined),
        "memberRows": sum(r["memberCount"] for r in records),
        "unjoinedResidualIds": len(unjoined_all),
        "unjoinedBySource": {k: len(v) for k, v in unjoined.items()},
        "residualReasons": {k: len(v) for k, v in sorted(residual.items())},
        "generationCounts": dict(Counter(
            g for r in records for g in r["generations"])),
        "generationSpanHistogram": dict(sorted(Counter(
            r["generationCount"] for r in records).items())),
        "sourceIdCounts": {k: len(v) for k, v in source_ids.items()},
        "stageCounts": dict(sorted(stats.items())),
    }

    written = _emit(records, summary, density, name_norm_meta, chain_meta,
                    variant_meta, unjoined, residual, residual_records, live,
                    cls_by_id, cad_name_agree)
    summary["fileCount"] = len(written)
    return summary


# ---------------------------------------------------------------------------
# Emit
# ---------------------------------------------------------------------------

def _shard_by_id(records, key_of, list_key):
    """Split a record list into <=MAX_LINES files. The split key is a FIXED
    id-range bucket over the record's OWN anchor id (never a count chunk), so a
    record's file never changes because a neighbour grew. Returns
    [(bucketStartOrNone, records)]."""
    if sharding.dump_manifest({list_key: records}).count("\n") + 1 <= MAX_LINES:
        return [(None, records)]
    for size in (10000000, 1000000, 100000, 10000, 1000):
        buckets = defaultdict(list)
        for r in records:
            buckets[sharding.bucket_id(key_of(r), size)].append(r)
        if all(sharding.dump_manifest({list_key: v}).count("\n") + 1 <= MAX_LINES
               for v in buckets.values()):
            return sorted(buckets.items())
    raise RuntimeError("build_abilities: no id-bucket size keeps every shard under "
                       f"{MAX_LINES} lines - needs re-investigation")


def _emit(records, summary, density, name_norm_meta, chain_meta, variant_meta,
          unjoined, residual, residual_records, live, cls_by_id,
          cad_name_agree) -> list:
    out = config.DATA_DIR / OUT_DIRNAME
    out.mkdir(parents=True, exist_ok=True)
    for p in out.glob("*.json"):
        p.unlink()

    by_class = defaultdict(list)
    for r in records:
        by_class[r["classId"]].append(r)

    files, index_classes = [], []
    for cid in sorted(by_class):
        cls = cls_by_id.get(cid, {})
        slug = sharding.slugify(cls.get("name") or f"class{cid}")
        shards = _shard_by_id(by_class[cid],
                              lambda r: min(m["id"] for m in r["members"]),
                              "abilities")
        shard_meta = []
        for bucket, recs in shards:
            stem = f"{cid:02d}-{slug}" + (f"-{bucket}" if bucket is not None else "")
            fname = f"{stem}.json"
            payload = {"classId": cid, "class": cls.get("name"),
                       "abilityCount": len(recs),
                       "idBucket": bucket,
                       "abilities": recs}
            text = sharding.dump_manifest(payload)
            lines = text.count("\n") + 1
            if lines > MAX_LINES:
                raise RuntimeError(f"build_abilities: {fname} is {lines} lines")
            (out / fname).write_text(text, encoding="utf-8", newline="\n")
            shard_meta.append({"file": fname, "abilityCount": len(recs),
                               "lines": lines, "idBucket": bucket})
            files.append(fname)
        index_classes.append({
            "classId": cid, "class": cls.get("name"),
            "abilityCount": len(by_class[cid]),
            "live": sum(1 for r in by_class[cid] if r["live"]),
            "multiGeneration": sum(1 for r in by_class[cid]
                                   if r["generationCount"] > 1),
            "trainerTaught": sum(1 for r in by_class[cid] if r["trainerTaught"]),
            "files": [s["file"] for s in shard_meta],
        })

    # residual: every id a source referenced that ends up in NO ability, one
    # record per line, sharded by fixed id-range bucket like everything else.
    res_files = []
    for bucket, recs in _shard_by_id(residual_records, lambda r: r["spellId"],
                                     "residual"):
        fname = "_residual.json" if bucket is None else f"_residual-{bucket}.json"
        (out / fname).write_text(sharding.dump_manifest({
            "note": ("Ids a source referenced that end up in no ability. This is "
                     "the honest remainder of the join, not a bug list - most of "
                     "it is profession recipes (NPCTrainer's largest skill lines) "
                     "and rank-chain ids no class-carrying row ever names."),
            "idBucket": bucket,
            "count": len(recs),
            "residual": recs,
        }), encoding="utf-8", newline="\n")
        res_files.append(fname)
        files.append(fname)

    res_index = {
        "note": "Per-id residual records live in the files listed here.",
        "totalUnjoinedIds": len(residual_records),
        "unjoinedCountsBySource": {k: len(v) for k, v in sorted(unjoined.items())},
        "reasonCountsAllIds": {k: len(v) for k, v in sorted(residual.items())},
        "reasonCountsUnjoinedOnly": dict(sorted(Counter(
            reason for r in residual_records for reason in r["reasons"]).items())),
        "files": res_files,
    }
    (out / "_residual-index.json").write_text(sharding.dump_manifest(res_index),
                                              encoding="utf-8", newline="\n")
    files.append("_residual-index.json")

    meta = {
        "purpose": ("One CoA ability exists under several spell-id generations with "
                    "no join table in the client. This layer is that join, derived "
                    "mechanically from raw/ in the same pass as the rest of the "
                    "dataset."),
        "groupKey": ("(classId, normalized spell name, live-node variant) - see "
                     "nameNormalization and liveNodeVariantGate"),
        "generations": {
            "liveNode": "spell id carried by a LIVE talent-builder node (raw/talents/"
                        "coa-builder-<slug>.html)",
            "trainer": "spell id an NPCTrainer row teaches (raw/tables/NPCTrainer)",
            "cad": "spell id a CharacterAdvancementData catalog row references "
                   "(raw/content/CharacterAdvancementData.json)",
            "rankChain": "spell id reached along a name-coherent SpellRankData chain "
                         "(raw/content/SpellRankData.json)",
        },
        "generationPrecedence": list(GENERATIONS),
        "sources": {
            "liveNode": "raw/talents/coa-builder-%s.html (RAW holds the payload; "
                        "data/talents/coa/ is a derived copy of the same parse and "
                        "is not read here)" % live["provenance"]["slug"],
            "cad": "raw/content/CharacterAdvancementData.json",
            "trainer": "raw/tables/NPCTrainer/",
            "rankChain": "raw/content/SpellRankData.json",
            "names": "raw/tables/Spell/variants/%s/ - the BASE variant a CoA "
                     "character reads, NOT the area-52 realm overlay at "
                     "raw/tables/Spell/" % BASE_SPELL_VARIANT,
            "classes": "raw/tables/ChrClasses/",
            "skillCorroboration": "raw/tables/SkillLineAbility/ + raw/tables/SkillLine/",
        },
        "nameNormalization": name_norm_meta,
        "rankChainGate": chain_meta,
        "liveNodeVariantGate": variant_meta,
        "idDensity": density,
        "cadNameVsSpellName": {
            "resolvedCadSpellRefs": cad_name_agree["resolved"],
            "cadRowNameMatchesSpellName": cad_name_agree["cadNameMatchesSpellName"],
            "rate": round(cad_name_agree["cadNameMatchesSpellName"]
                          / cad_name_agree["resolved"], 4)
                    if cad_name_agree["resolved"] else None,
            "why": ("A CAD row's own Name is used as the group key ONLY when its "
                    "spell id has no base Spell row at all; this is the measured "
                    "agreement between the two when both exist."),
        },
        "trainerAdmissionRule": (
            "A trainer row always marks an id it already shares with another "
            "generation. An id known ONLY to NPCTrainer is admitted only with "
            "corroborating class evidence - a single-class SkillLineAbility "
            "classMask, or a skillLine shared with an existing member of exactly "
            "one same-named ability. A bare name match is refused and recorded in "
            "_residual.json as trainerNameOnlyNoCorroboration."),
        "liveProvenance": live["provenance"],
        "liveSeedDrift": coa_live.seed_drift(live["provenance"]["slug"]),
        "realmCaveat": coa_live.REALM_CAVEAT,
        "summary": summary,
        "classes": index_classes,
    }
    (out / "_meta.json").write_text(sharding.dump_manifest(meta),
                                    encoding="utf-8", newline="\n")
    files.append("_meta.json")

    index = {
        "abilityCount": summary["abilities"],
        "classes": index_classes,
        "counts": {k: summary[k] for k in
                   ("abilities", "abilitiesMultiGeneration", "abilitiesLive",
                    "liveAbilitiesWithTrainerLadder", "memberIds",
                    "unjoinedResidualIds")},
        "generationCounts": summary["generationCounts"],
        "generationSpanHistogram": summary["generationSpanHistogram"],
        "meta": "_meta.json",
        "residual": "_residual-index.json",
        "recordShape": ("key, classId, class, name, normName, generations, "
                        "generationCount, memberCount, live, liveIds, liveId, "
                        "trainerTaught, trainerIds, rankLadder (ordered by level "
                        "then rank), linkedKeys (same ability under another name), "
                        "members[] each with generation, generations and "
                        "per-generation evidence"),
    }
    (out / "index.json").write_text(sharding.dump_manifest(index),
                                    encoding="utf-8", newline="\n")
    files.append("index.json")
    return sorted(files)
