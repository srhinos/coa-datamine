"""Recompute the damage-model coverage figure over CASTABLE (live) content.

WHY
---
The published headline - "1,151 of 1,429 damaging/healing effect slots modelable
(80.5%), 278 holes" - was measured over the CAD catalog in data/classes/, i.e.
over what the character-advancement tables LIST for a class. The catalog is not
the game: a level-60 Starcaller player proved a whole CAD tab ("Tides") does not
exist in the live talent builder. Coverage measured over the catalog therefore
counts effect slots no player can ever cast, and a hole in that dead content is
not a hole a simulator has to fill.

This script produces BOTH figures side by side over one identical pipeline:

  * CAD denominator   - every build-reachable entry in the coa-custom classes
                        (reproduces the published measurement).
  * LIVE denominator  - the same, restricted to entries the live talent-builder
                        capture proves exist.

METHOD (identical to the audit's, ported here so the number is reproducible in
this repo - parsers/coverage/{bload,denom,clsfy,measure,headline}.py in
coa-sim-handoff):

  1. Spell rows come from BASE raw/dbc/Spell.csv.gz ONLY. Never a realm overlay:
     the published 1,152 predecessor figure was an area-52 artifact and was
     retired. Rows whose column count != 234 are skipped (5 of 209,130).
  2. Denominator walk: data/classes/index.json -> classes[] with tag
     "coa-custom" (21) -> <dir>/index.json -> files[] -> entries[] of type
     Ability / Talent / TalentAbility -> each entry.spells[] x (ranks[] or the
     bare spell) = one "chain".
  3. Rank pick: the highest rank whose CAD rank.level is <= 60 (a level-60
     character cannot cast higher ranks). This moves coverage by <1pp but is
     essential for values.
  4. A slot (1..3) enters the denominator if it deals damage or heals:
     weapon effects {17,31,58,121}, direct damage {2,9,62}, heal {10,67,75,136},
     or an aura carrier {6,27,35,65,119,128,129,143} whose aura is a damage
     {3,53,89} or heal {8,20} periodic. Aura 118 is MOD_HEALING_PCT, NOT a heal
     - including it injects 77 phantom heal slots.
  5. Scaling channels per slot: W = weapon effect, P = EffectRealPointsPerLevel
     or a $ppl/$PL token bound to the slot, T = a stat*number coefficient term
     in the spell text (description + tooltip + SpellDescriptionVariables).
  6. Verdict: gear-scaling (W or T) is MODELABLE; percent-of-max effects and
     1-point tag damage are MODELABLE (nothing to model); everything else is a
     HOLE, split into dev-dead text, level-curve-only, and no-channel-at-all.

LIVENESS is NOT re-derived here. It is consumed from the `live` / `liveEvidence`
flags that tools/coa_live.py writes onto every data/classes/** entry (task
W4-14), summarised in data/classes/_live_summary.json. Rule, quoted from that
file: an entry is live if any of its own CAD spell ids is a live builder node's
spellId/spellIds member (liveDirect), failing that if any other rank of its
SpellRankData chain is (liveViaRank); otherwise it is split into `indeterminate`
(live: null - carries evidence of a non-tree acquisition path, e.g. an automatic
SkillLineAbility grant or a trainer row) and `deadCatalog` (live: false - no
evidence of any acquisition path at all).

All 21 coa-custom classes have live builder geometry, so no entry in this
denominator is `unknownNoGeometry`. Every entry is live / indeterminate / dead.

Because `indeterminate` is a genuine unknown rather than a soft yes, the strict
live figure is a LOWER bound on live coverage and the live-or-indeterminate
figure is the UPPER bound. Both are reported.

Run:  python -m analysis.coverage_live            (from the repo root)
      python analysis/coverage_live.py --no-write (report only)

Deterministic: no network, no cache, no randomness. Output is written to
data/spells/_coverage_live.json.
"""

from __future__ import annotations

import collections
import csv
import gzip
import json
import os
import re
import struct
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SPELL_CSV = os.path.join(ROOT, "raw", "dbc", "Spell.csv.gz")
SDV_CSV = os.path.join(ROOT, "raw", "dbc", "SpellDescriptionVariables.csv.gz")
CLASSES = os.path.join(ROOT, "data", "classes")
TALENTS = os.path.join(ROOT, "data", "talents", "coa")
OUT = os.path.join(ROOT, "data", "spells", "_coverage_live.json")

csv.field_size_limit(10 ** 8)

LEVEL_CAP = 60

# --------------------------------------------------------------------------
# 1. BASE Spell.dbc
# --------------------------------------------------------------------------
# Column NAMES, resolved against the header rather than hard-coded indices, so
# the loader fails loudly instead of silently mis-reading if the dump changes.
SCALAR_COLS = {
    "id": "id", "maxLevel": "maxLevel", "baseLevel": "baseLevel",
    "spellLevel": "spellLevel", "descVarId": "spellDescriptionVariableID",
}
TEXT_COLS = {"name": "name_enUS", "rank": "rank_enUS",
             "desc": "description_enUS", "tip": "tooltip_enUS"}
PER_SLOT_INT = {"eff": "effect%d", "die": "effectDieSides%d",
                "bp": "effectBasePoints%d", "aura": "effectAura%d"}
PER_SLOT_FLOAT = {"rppl": "effectRealPointsPerLevel%d"}


def _float_bits(v):
    """DBC floats are dumped as their signed-int bit pattern."""
    try:
        return struct.unpack("<f", struct.pack("<i", int(v)))[0]
    except (ValueError, struct.error):
        try:
            return float(v)
        except ValueError:
            return 0.0


def load_spells():
    with gzip.open(SPELL_CSV, "rt", encoding="utf-8", errors="replace",
                   newline="") as fh:
        rd = csv.reader(fh)
        hdr = next(rd)
        if len(hdr) != 234:
            raise SystemExit("Spell.csv.gz: expected 234 columns, got %d" % len(hdr))
        col = {n: i for i, n in enumerate(hdr)}
        ints = {k: col[v] for k, v in SCALAR_COLS.items()}
        txts = {k: col[v] for k, v in TEXT_COLS.items()}
        for s in (1, 2, 3):
            for pre, pat in PER_SLOT_INT.items():
                ints["%s%d" % (pre, s)] = col[pat % s]
        flts = {}
        for s in (1, 2, 3):
            for pre, pat in PER_SLOT_FLOAT.items():
                flts["%s%d" % (pre, s)] = col[pat % s]
        out, skipped = {}, 0
        for row in rd:
            if len(row) != 234:
                skipped += 1
                continue
            d = {}
            for k, i in ints.items():
                try:
                    d[k] = int(row[i])
                except ValueError:
                    d[k] = 0
            for k, i in txts.items():
                d[k] = row[i]
            for k, i in flts.items():
                d[k] = _float_bits(row[i])
            out[d["id"]] = d
    return out, skipped


_SDV = None


def sdv():
    global _SDV
    if _SDV is None:
        _SDV = {}
        with gzip.open(SDV_CSV, "rt", encoding="utf-8", errors="replace",
                       newline="") as fh:
            rd = csv.reader(fh)
            h = next(rd)
            ci = h.index("text_enUS") if "text_enUS" in h else 1
            for row in rd:
                try:
                    _SDV[int(row[0])] = row[ci]
                except (ValueError, IndexError):
                    pass
    return _SDV


# --------------------------------------------------------------------------
# 2. Slot classification
# --------------------------------------------------------------------------
WEAPON_EFF = {17, 31, 58, 121}          # NOSCHOOL, PERCENT, WEAPON_DAMAGE, NORMALIZED
DIRECT_DMG = {2, 9, 62}                 # SCHOOL_DAMAGE, HEALTH_LEECH, POWER_BURN
HEAL_EFF = {10, 67, 75, 136}            # HEAL, HEAL_MAX_HEALTH, HEAL_MECHANICAL, HEAL_PCT
AURA_CARRIER = {6, 27, 35, 65, 119, 128, 129, 143}
DMG_AURA = {3, 53, 89}                  # PERIODIC_DAMAGE, PERIODIC_LEECH, PERIODIC_DAMAGE_PCT
HEAL_AURA = {8, 20}                     # PERIODIC_HEAL, OBS_MOD_HEALTH
PCT_EFF = {136, 67, 137}                # percent-of-max: no coefficient exists
PCT_AURA = {20}
DEAD_TEXT = re.compile(r"DOES NOT WORK|SHOULD NOT HAVE|DEPRECATED|do not use", re.I)


def slot_kind(rec, s):
    e, a = rec["eff%d" % s], rec["aura%d" % s]
    if e in WEAPON_EFF:
        return "weapon"
    if e in DIRECT_DMG:
        return "direct_damage"
    if e in HEAL_EFF:
        return "direct_heal"
    if e in AURA_CARRIER:
        if a in DMG_AURA:
            return "periodic_damage"
        if a in HEAL_AURA:
            return "periodic_heal"
    return None


def dmg_slots(rec):
    return [(s, k) for s in (1, 2, 3) if (k := slot_kind(rec, s))]


STAT = r"(?:spfi|spfr|spa|sph|spn|sps|spi|sp|bh|rap|ap|int|sta|agi|str|power)"
STATMUL_RE = re.compile(r"\$(\d*)(" + STAT + r")(?![A-Za-z0-9])\s*[*/]\s*\$?\d*\.?\d+", re.I)
NUMMUL_RE = re.compile(r"\d*\.?\d+\s*\*\s*\$(\d*)(" + STAT + r")(?![A-Za-z0-9])", re.I)
PPL_RE = re.compile(r"\$(\d*)ppl(\d?)(?![A-Za-z0-9])", re.I)
PL_RE = re.compile(r"\$(\d*)pl(?![A-Za-z0-9])", re.I)
REF_RE = re.compile(r"\$(\d*)([msowMSOW])(\d)(?![0-9])")
REF2_RE = re.compile(r"\$/\d+;\s*(?:ppl|[msowMSOW])(\d)(?![0-9])")


def brace_groups(text):
    """Brace-matched ${...} groups."""
    out, i, n = [], 0, len(text)
    while i < n - 1:
        if text[i] == "$" and text[i + 1] == "{":
            depth, j = 0, i + 1
            while j < n:
                if text[j] == "{":
                    depth += 1
                elif text[j] == "}":
                    depth -= 1
                    if depth == 0:
                        break
                j += 1
            if j < n:
                out.append(text[i:j + 1])
                i = j + 1
                continue
        i += 1
    return out


def text_of(sp, sid):
    rec = sp.get(sid)
    if not rec:
        return ""
    t = (rec["desc"] or "") + "\n" + (rec["tip"] or "")
    v = rec["descVarId"]
    if v and v in sdv():
        t += "\n" + sdv()[v]
    return t


def analyse(sp, sid):
    rec = sp.get(sid)
    if not rec:
        return None
    t = text_of(sp, sid)
    gs = brace_groups(t)
    own_stat, own_ppl = set(), set()
    unbound_stat = cross_stat = free_stat = unbound_ppl = False
    sids = str(sid)
    for g in gs:
        own, cross = set(), False
        for m in REF_RE.finditer(g):
            if m.group(1) in ("", sids):
                own.add(int(m.group(3)))
            else:
                cross = True
        for m in REF2_RE.finditer(g):
            own.add(int(m.group(1)))
        for m in PPL_RE.finditer(g):
            if m.group(1) in ("", sids):
                if m.group(2):
                    own.add(int(m.group(2)))
                    own_ppl.add(int(m.group(2)))
                else:
                    unbound_ppl = True
        has_stat = bool(STATMUL_RE.search(g) or NUMMUL_RE.search(g))
        if has_stat:
            if own:
                own_stat |= own
            elif cross:
                cross_stat = True
            else:
                unbound_stat = True
        if PL_RE.search(g):
            if own:
                own_ppl |= own
            else:
                unbound_ppl = True
    stripped = t
    for g in gs:
        stripped = stripped.replace(g, " ")
    if STATMUL_RE.search(stripped) or NUMMUL_RE.search(stripped):
        free_stat = True
    return dict(rec=rec, own_stat=own_stat, own_ppl=own_ppl,
                unbound_stat=unbound_stat, cross_stat=cross_stat,
                free_stat=free_stat, unbound_ppl=unbound_ppl, text=t, groups=gs)


BUCKETS = ["WEAPON_SCALED", "PERLEVEL_SCALED", "TOOLTIP_SCALED", "FLAT", "UNRESOLVED"]


def channels(sp, sid, _cache={}):
    """-> list of (slot, kind, bucket, channel-string).

    Memoised on spell id alone, so one process must use one spell table (this
    module loads exactly one, from BASE Spell.csv.gz)."""
    if sid in _cache:
        return _cache[sid]
    a = analyse(sp, sid)
    if a is None:
        _cache[sid] = []
        return []
    rec, out = a["rec"], []
    for s, k in dmg_slots(rec):
        ch = set()
        if k == "weapon":
            ch.add("W")
        if abs(rec["rppl%d" % s]) > 1e-9 or s in a["own_ppl"]:
            ch.add("P")
        if s in a["own_stat"] or a["unbound_stat"] or a["free_stat"] or a["cross_stat"]:
            ch.add("T")
        bv = rec["bp%d" % s] + rec["die%d" % s]
        if "W" in ch:
            b = "WEAPON_SCALED"
        elif "P" in ch:
            b = "PERLEVEL_SCALED"
        elif "T" in ch:
            b = "TOOLTIP_SCALED"
        elif bv != 0:
            b = "FLAT"
        else:
            b = "UNRESOLVED"
        out.append((s, k, b, "".join(sorted(ch)) or "-"))
    _cache[sid] = out
    return out


def verdict(sp, sid, slot, chan):
    rec = sp[sid]
    e, a = rec["eff%d" % slot], rec["aura%d" % slot]
    bv = rec["bp%d" % slot] + rec["die%d" % slot]
    if "W" in chan or "T" in chan:
        return "MODELABLE:gear-coefficient"
    if e in PCT_EFF or a in PCT_AURA:
        return "MODELABLE:percent-of-max (no coefficient exists)"
    if abs(bv) <= 1 and "P" not in chan:
        return "MODELABLE:1-point tag (no damage to model)"
    if DEAD_TEXT.search(text_of(sp, sid) or ""):
        return "HOLE:dev-dead content"
    if "P" in chan:
        return "HOLE:level-curve only, no gear term"
    return "HOLE:no scaling channel at all"


def value_at_cap(rec, slot, roll="max"):
    """The repo's canonical level-60 value (AGENT-GUIDE "Spell column completion"):

        value = basePoints + dieSides + (clamp(60, baseLevel, maxLevel) - spellLevel)
                                        * realPointsPerLevel

    with `maxLevel == 0` read as the DBC "uncapped" sentinel, not a clamp toward 0.
    roll="max" gives basePoints + dieSides (the top of the roll, as the guide states
    it); roll="min" gives basePoints + 1 (the bottom). They differ only where
    dieSides > 1. Descriptive only - it plays no part in the coverage verdict.
    """
    lvl = LEVEL_CAP
    if rec["maxLevel"] > 0:
        lvl = min(lvl, rec["maxLevel"])
    lvl = max(lvl, rec["baseLevel"])
    base = rec["bp%d" % slot] + (rec["die%d" % slot] if roll == "max" else 1)
    return round(base + (lvl - rec["spellLevel"]) * rec["rppl%d" % slot], 1)


def formula_for(sp, sid, slot):
    """The authored text term bound to this slot: the ${...} group referencing
    it, else the bare $sN/$oN/$mN token (the stock Blizzard style, which carries
    no authored coefficient)."""
    a = analyse(sp, sid)
    if a is None:
        return None
    sids = str(sid)
    for g in a["groups"]:
        for m in REF_RE.finditer(g):
            if m.group(1) in ("", sids) and int(m.group(3)) == slot:
                return g
        for m in REF2_RE.finditer(g):
            if int(m.group(1)) == slot:
                return g
    m = re.search(r"\$(?:%s)?[msowMSOW]%d(?![0-9])" % (sids, slot), a["text"])
    return m.group(0) if m else None


# --------------------------------------------------------------------------
# 3. Denominator walk (+ liveness, consumed not derived)
# --------------------------------------------------------------------------
ENTRY_TYPES = ("Ability", "Talent", "TalentAbility")


def walk_chains():
    idx = json.load(open(os.path.join(CLASSES, "index.json"), encoding="utf-8"))
    coa = [c for c in idx["classes"] if c.get("tag") == "coa-custom"]
    recs, entries = [], 0
    for c in sorted(coa, key=lambda x: x["name"]):
        cdir = os.path.join(CLASSES, c["dir"].rstrip("/"))
        cidx = json.load(open(os.path.join(cdir, "index.json"), encoding="utf-8"))
        for f in cidx["files"]:
            d = json.load(open(os.path.join(cdir, f["file"]), encoding="utf-8"))
            for e in d["entries"]:
                if e.get("type") not in ENTRY_TYPES:
                    continue
                entries += 1
                ev = e.get("liveEvidence") or {}
                for s in e.get("spells") or []:
                    ranks = s.get("ranks") or []
                    chain = ([(r["rank"], r["spellId"], r.get("level")) for r in ranks]
                             if ranks else [(1, s["id"], None)])
                    recs.append(dict(
                        cls=c["name"], classId=c["classId"], tab=e.get("tab") or f.get("tab"),
                        type=e.get("type"), cadId=e.get("cadId"), entry=e.get("name"),
                        reqLevel=e.get("requiredLevel"), chain=chain,
                        live=e.get("live"), liveReason=ev.get("reason"),
                        builderTab=ev.get("builderTab"), builderNodeId=ev.get("builderNodeId"),
                        matchedSpellId=ev.get("matchedSpellId")))
    return recs, entries, len(coa)


def rank_at_cap(chain):
    """Highest rank obtainable at the level cap, gated on the CAD rank.level
    (the CAD system is what grants the rank on Ascension). If every rank is
    gated above the cap, fall back to the lowest-level rank."""
    ok = [x for x in chain if (x[2] is None or x[2] <= LEVEL_CAP)]
    if not ok:
        ok = [min(chain, key=lambda x: (x[2] if x[2] is not None else 0))]
    return max(ok, key=lambda x: x[0])


def build_slots(sp, recs, keep):
    """keep(rec) -> bool. Returns per-(entry, slot) rows."""
    slots, dropped = [], set()
    for r in recs:
        if not keep(r):
            continue
        rk, sid, lv = rank_at_cap(r["chain"])
        if sid not in sp:
            dropped.add(sid)
            continue
        for (s, kind, bucket, chan) in channels(sp, sid):
            slots.append(dict(cls=r["cls"], type=r["type"], entry=r["entry"],
                              tab=r["tab"], cadId=r["cadId"], sid=sid, rank=rk,
                              slot=s, kind=kind, bucket=bucket, chan=chan,
                              live=r["live"], liveReason=r["liveReason"],
                              builderTab=r["builderTab"],
                              builderNodeId=r["builderNodeId"]))
    return slots, dropped


def _group(slots, key):
    """-> {value: {instances, distinctSpellSlotPairs, distinctSpells}}"""
    out = {}
    for s, k in zip(slots, key):
        d = out.setdefault(k, dict(instances=0, _pairs=set(), _spells=set()))
        d["instances"] += 1
        d["_pairs"].add((s["sid"], s["slot"]))
        d["_spells"].add(s["sid"])
    return {k: dict(instances=v["instances"],
                    distinctSpellSlotPairs=len(v["_pairs"]),
                    distinctSpells=len(v["_spells"]))
            for k, v in sorted(out.items())}


def measure(sp, slots):
    v = [verdict(sp, s["sid"], s["slot"], s["chan"]) for s in slots]
    c = collections.Counter(v)
    holes = [s for s, k in zip(slots, v) if k.startswith("HOLE")]
    n = len(slots)
    mod = sum(x for k, x in c.items() if k.startswith("MODELABLE"))
    return dict(
        slots=n,
        modelable=mod,
        modelablePct=round(100.0 * mod / n, 1) if n else 0.0,
        holes=n - mod,
        holePct=round(100.0 * (n - mod) / n, 1) if n else 0.0,
        distinctSpellSlotPairs=len({(s["sid"], s["slot"]) for s in slots}),
        holeDistinctSpellSlotPairs=len({(s["sid"], s["slot"]) for s in holes}),
        holeDistinctSpells=len({s["sid"] for s in holes}),
        distinctSpells=len({s["sid"] for s in slots}),
        entryRows=len({(s["cls"], s["cadId"], s["sid"]) for s in slots}),
        buckets={b: c2 for b, c2 in
                 ((b, sum(1 for s in slots if s["bucket"] == b)) for b in BUCKETS)},
        verdicts=dict(sorted(c.items())),
        byVerdict=_group(slots, v),
        byBucket=_group(slots, [s["bucket"] for s in slots]),
        byKind=_group(slots, [s["kind"] for s in slots]),
    ), holes


# --------------------------------------------------------------------------
# 4. Hole rows + talent-tree tier lookup
# --------------------------------------------------------------------------
def _hole_row(sp, h, rec):
    """One row per distinct (spellId, slot) hole - everything a probe needs."""
    return dict(
        spellId=h["sid"], slot=h["slot"], klass=h["cls"],
        name=rec["name"], rank=rec["rank"] or None,
        kind=h["kind"], bucket=h["bucket"], channels=h["chan"],
        verdict=verdict(sp, h["sid"], h["slot"], h["chan"]),
        liveness=("proven-live" if h["live"] is True else
                  "indeterminate" if h["live"] is None else "dead"),
        effect=rec["eff%d" % h["slot"]], aura=rec["aura%d" % h["slot"]],
        basePoints=rec["bp%d" % h["slot"]], dieSides=rec["die%d" % h["slot"]],
        realPointsPerLevel=round(rec["rppl%d" % h["slot"]], 4),
        spellLevel=rec["spellLevel"], baseLevel=rec["baseLevel"],
        maxLevel=rec["maxLevel"], valueAtCap=value_at_cap(rec, h["slot"], "max"),
        valueAtCapMinRoll=value_at_cap(rec, h["slot"], "min"),
        formula=formula_for(sp, h["sid"], h["slot"]),
        cadEntries=[], builderTabs=[], builderTiers=[], builderRequiredLevel=None)


def node_index():
    """(class, builderNodeId) -> {tab, tier(y), x, requiredLevel}, plus
    {class: {every spell id any of that class's live nodes carries}}. Both are
    CONSUMED from data/talents/coa/ - the same frozen capture the `live` flags were
    stamped from - so nothing here re-derives liveness."""
    out, live_ids = {}, {}
    if not os.path.isdir(TALENTS):
        return out, live_ids
    for fn in sorted(os.listdir(TALENTS)):
        if not fn.endswith(".json") or fn.startswith("_") or fn == "index.json":
            continue
        d = json.load(open(os.path.join(TALENTS, fn), encoding="utf-8"))
        tabs = {t["tabId"]: t["tabName"] for t in d.get("tabs", [])}
        ids = live_ids.setdefault(d["class"], set())
        for n in d.get("nodes", []):
            out[(d["class"], n["id"])] = dict(
                tab=tabs.get(n.get("tabId")), tier=n.get("y"), column=n.get("x"),
                requiredLevel=n.get("requiredLevel"), nodeName=n.get("name"),
                entryType=n.get("entryType"), maxPoints=n.get("maxPoints"))
            ids.update(i for i in [n.get("spellId")] + list(n.get("spellIds") or ())
                       if i)
    return out, live_ids


def live_denominator_slack(recs, live_ids):
    """`live` is stamped per ENTRY but consumed per CHAIN here, and the rank this
    script measures is picked by level, not by which rank the builder node holds.
    Both are over-inclusions in the live denominator, so both get measured rather
    than asserted small.

      chainsRidingOnASibling - live chains none of whose OWN spell ids is in any
        live node of that class: the entry earned `live` on a DIFFERENT spell.
      chainsMeasuringAnotherRank - live chains that do contain the matched node's
        spell, but where rank_at_cap picks a different rank of it to measure."""
    riders = other_rank = live_chains = 0
    for r in recs:
        if r["live"] is not True:
            continue
        live_chains += 1
        ids = {x[1] for x in r["chain"]}
        if not (ids & live_ids.get(r["cls"], set())):
            riders += 1
        elif r["matchedSpellId"] is not None and r["matchedSpellId"] in ids:
            if rank_at_cap(r["chain"])[1] != r["matchedSpellId"]:
                other_rank += 1
    return {"liveChains": live_chains,
            "chainsRidingOnASibling": riders,
            "chainsRidingOnASiblingPct": round(100.0 * riders / max(1, live_chains), 1),
            "chainsMeasuringAnotherRank": other_rank,
            "chainsMeasuringAnotherRankPct": round(
                100.0 * other_rank / max(1, live_chains), 1)}


# --------------------------------------------------------------------------
# 5. Run
# --------------------------------------------------------------------------
def main(write=True):
    sp, skipped = load_spells()
    recs, entries, nclasses = walk_chains()
    nodes, live_node_spell_ids = node_index()
    slack = live_denominator_slack(recs, live_node_spell_ids)

    # NOTE the unit: recs are CHAINS (one per spell reference on a walked entry),
    # not entries. These counts are therefore NOT comparable with
    # _live_summary.json's entry-level liveCountsByReason - an entry with three
    # spells contributes three chains here and one entry there. Named
    # chainReasonCounts for exactly that reason.
    chain_reason_counts = collections.Counter(
        (r["liveReason"] or "missing") for r in recs)

    cad_slots, dropped = build_slots(sp, recs, lambda r: True)
    live_slots, _ = build_slots(sp, recs, lambda r: r["live"] is True)
    upper_slots, _ = build_slots(sp, recs, lambda r: r["live"] is not False)

    cad_fig, cad_holes = measure(sp, cad_slots)
    live_fig, live_holes = measure(sp, live_slots)
    upper_fig, _ = measure(sp, upper_slots)

    # dead-content share of the CAD hole population, as distinct (sid, slot)
    def hole_pairs(slots, only_verdict=None):
        out = set()
        for s in slots:
            v = verdict(sp, s["sid"], s["slot"], s["chan"])
            if v.startswith("HOLE") and (only_verdict is None or v == only_verdict):
                out.add((s["sid"], s["slot"]))
        return out

    cad_pairs = hole_pairs(cad_slots)
    live_pairs = hole_pairs(live_slots)
    upper_pairs = hole_pairs(upper_slots)
    dead_only_pairs = cad_pairs - upper_pairs

    # The published triage worked the "level-curve only" hole population (92
    # distinct pairs). Reconcile it against liveness the same way.
    LCO = "HOLE:level-curve only, no gear term"
    lco_cad = hole_pairs(cad_slots, LCO)
    lco_live = hole_pairs(live_slots, LCO)
    lco_upper = hole_pairs(upper_slots, LCO)

    # Golden checks against the published audit (coa-sim-handoff/analysis/
    # coverage-remeasure.md + hole-triage.md). Any FAIL means the pipeline drifted.
    cb, cv = cad_fig["byBucket"], cad_fig["byVerdict"]
    golden = [
        ("CAD damaging/healing slots", 1429, cad_fig["slots"]),
        ("CAD modelable", 1151, cad_fig["modelable"]),
        ("CAD holes", 278, cad_fig["holes"]),
        ("CAD distinct (spellId, slot) pairs", 496, cad_fig["distinctSpellSlotPairs"]),
        ("CAD distinct spells", 402, cad_fig["distinctSpells"]),
        ("CAD ability rows", 1156, cad_fig["entryRows"]),
        ("level-curve-only hole instances", 255, cv[LCO]["instances"]),
        ("level-curve-only hole distinct pairs", 92, cv[LCO]["distinctSpellSlotPairs"]),
        ("level-curve-only hole distinct spells", 87, cv[LCO]["distinctSpells"]),
        ("no-channel hole instances", 20,
         cv["HOLE:no scaling channel at all"]["instances"]),
        ("no-channel hole distinct pairs", 8,
         cv["HOLE:no scaling channel at all"]["distinctSpellSlotPairs"]),
        ("dev-dead hole instances", 3, cv["HOLE:dev-dead content"]["instances"]),
        ("WEAPON_SCALED slots", 428, cb["WEAPON_SCALED"]["instances"]),
        ("WEAPON_SCALED distinct pairs", 147, cb["WEAPON_SCALED"]["distinctSpellSlotPairs"]),
        ("PERLEVEL_SCALED slots", 795, cb["PERLEVEL_SCALED"]["instances"]),
        ("TOOLTIP_SCALED slots", 139, cb["TOOLTIP_SCALED"]["instances"]),
        ("FLAT slots", 58, cb["FLAT"]["instances"]),
        ("UNRESOLVED slots", 9, cb["UNRESOLVED"]["instances"]),
        ("entries walked", 8331, entries),
        ("chains walked", 8706, len(recs)),
    ]
    golden = [dict(check=n, expected=e, actual=a, ok=(e == a)) for n, e, a in golden]

    # ---- the live hole list ------------------------------------------------
    def hole_rows(holes):
        by_pair = {}
        for h in holes:
            key = (h["sid"], h["slot"])
            nd = nodes.get((h["cls"], h["builderNodeId"])) or {}
            if key not in by_pair:
                by_pair[key] = _hole_row(sp, h, sp[h["sid"]])
            row = by_pair[key]
            row["cadEntries"].append(dict(entry=h["entry"], tab=h["tab"],
                                          type=h["type"], cadId=h["cadId"],
                                          liveReason=h["liveReason"]))
            if nd.get("tab") and nd["tab"] not in row["builderTabs"]:
                row["builderTabs"].append(nd["tab"])
            if nd.get("tier") is not None and nd["tier"] not in row["builderTiers"]:
                row["builderTiers"].append(nd["tier"])
            if nd.get("requiredLevel") is not None:
                row["builderRequiredLevel"] = nd["requiredLevel"]
        rows = sorted(by_pair.values(),
                      key=lambda r: (r["klass"], r["spellId"], r["slot"]))
        for r in rows:
            r["cadEntryCount"] = len(r["cadEntries"])
        return rows

    hole_list = hole_rows(live_holes)
    live_pairs_set = {(r["spellId"], r["slot"]) for r in hole_list}
    upper_holes = [s for s in upper_slots
                   if verdict(sp, s["sid"], s["slot"], s["chan"]).startswith("HOLE")]
    indet_list = [r for r in hole_rows(upper_holes)
                  if (r["spellId"], r["slot"]) not in live_pairs_set]

    def per_class(slots):
        out = {}
        for cls in sorted({s["cls"] for s in slots}):
            ss = [s for s in slots if s["cls"] == cls]
            f, _h = measure(sp, ss)
            out[cls] = dict(slots=f["slots"], modelable=f["modelable"],
                            holes=f["holes"], holePct=f["holePct"],
                            holeDistinctSpellSlotPairs=f["holeDistinctSpellSlotPairs"])
        return out

    doc = {
        "_generatedBy": "analysis/coverage_live.py",
        "_task": "Recompute the damage-model coverage figure over castable (live) content.",
        "_note": ("Unrelated to data/spells/_coverage.json, which measures Spell.dbc "
                  "COLUMN coverage. This file measures how much of a CoA class's "
                  "damaging/healing effect output a simulator can model."),
        "headline": (
            "%.1f%% of the damaging/healing effect slots a level-%d character can "
            "actually CAST are modelable (%d of %d); %d are holes, %d distinct "
            "(spellId, slot) pairs."
            % (live_fig["modelablePct"], LEVEL_CAP, live_fig["modelable"],
               live_fig["slots"], live_fig["holes"],
               live_fig["holeDistinctSpellSlotPairs"])),
        "cadFigureOverstates": (
            "The CAD-denominator figure (%.1f%% modelable, %d holes, %d distinct "
            "pairs) OVERSTATES the size of the problem for a simulator, because it "
            "counts effect slots on catalog entries no player can cast. %d of its "
            "%d distinct hole pairs (%.0f%%) sit on entries with no live builder "
            "node and no evidence of any other acquisition path - dead content. "
            "Use the live figure; the CAD figure is historical."
            % (cad_fig["modelablePct"], cad_fig["holes"],
               cad_fig["holeDistinctSpellSlotPairs"], len(dead_only_pairs),
               len(cad_pairs), 100.0 * len(dead_only_pairs) / max(1, len(cad_pairs)))),
        "figures": {
            "cad": dict(cad_fig, denominator="every build-reachable entry in the 21 "
                        "coa-custom classes (the published/historical measurement)"),
            "live": dict(live_fig, denominator="entries with live == true - proven "
                         "present in the Vol'jin live talent-builder capture "
                         "(LOWER bound on live coverage)"),
            "liveOrIndeterminate": dict(upper_fig, denominator="entries with live != "
                                        "false - live plus indeterminate (carries "
                                        "evidence of a non-tree acquisition path); "
                                        "UPPER bound on live coverage"),
        },
        "delta": {
            "slotsRemovedAsNonLive": cad_fig["slots"] - live_fig["slots"],
            "slotsRemovedPct": round(100.0 * (cad_fig["slots"] - live_fig["slots"])
                                     / cad_fig["slots"], 1),
            "modelablePctCad": cad_fig["modelablePct"],
            "modelablePctLive": live_fig["modelablePct"],
            "modelablePctPointChange": round(live_fig["modelablePct"]
                                             - cad_fig["modelablePct"], 1),
            "holeDistinctPairsCad": cad_fig["holeDistinctSpellSlotPairs"],
            "holeDistinctPairsLive": live_fig["holeDistinctSpellSlotPairs"],
            "holeDistinctPairsLiveOrIndeterminate": upper_fig["holeDistinctSpellSlotPairs"],
            "holePairsOnlyInDeadContent": len(dead_only_pairs),
            "holePairsNotProvenLive": len(cad_pairs - live_pairs),
            "note": ("Hole pairs are counted distinct on (spellId, slot). The CAD "
                     "denominator carries ~3x duplication because the same ability is "
                     "reachable through several realm-variant catalog entries."),
        },
        "publishedTriagePopulation": {
            "_what": ("The published hole triage worked the 'level-curve only, no gear "
                      "term' population - the 92 distinct (spellId, slot) pairs that a "
                      "damage probe would have to target. This is that population split "
                      "by liveness."),
            "distinctPairsCad": len(lco_cad),
            "distinctPairsProvenLive": len(lco_live),
            "distinctPairsLiveOrIndeterminate": len(lco_upper),
            "distinctPairsIndeterminateOnly": len(lco_upper) - len(lco_live),
            "distinctPairsDeadOnly": len(lco_cad - lco_upper),
            "distinctPairsNotProvenLive": len(lco_cad - lco_live),
            "finding": ("%d of the %d published level-curve-only hole pairs are not "
                        "proven live (%.0f%%): %d sit only on entries with no live node "
                        "and no other acquisition path (dead), %d only on indeterminate "
                        "entries. Probe work on this population is %d units, not %d."
                        % (len(lco_cad - lco_live), len(lco_cad),
                           100.0 * len(lco_cad - lco_live) / max(1, len(lco_cad)),
                           len(lco_cad - lco_upper), len(lco_upper) - len(lco_live),
                           len(lco_live), len(lco_cad))),
        },
        "goldenChecks": {
            "_what": ("Reproduction gates against the published audit "
                      "(coa-sim-handoff/analysis/coverage-remeasure.md and "
                      "hole-triage.md). All must pass or the pipeline has drifted."),
            "allPass": all(g["ok"] for g in golden),
            "checks": golden,
        },
        "liveHoles": hole_list,
        "indeterminateHoles": indet_list,
        "probeTargets": {
            "_what": ("What a damage probe would actually have to target, and in what "
                      "order. liveHoles are proven castable. indeterminateHoles are the "
                      "additional pairs whose entries carry evidence of a non-tree "
                      "acquisition path but appear in no live builder node - confirm "
                      "the character can learn the spell BEFORE spending a probe on it."),
            "provenLive": len(hole_list),
            "indeterminate": len(indet_list),
            "deadNotWorthProbing": len(dead_only_pairs),
            "sunflareCaveat": (
                "SunCleric Sunflare (502394 slot 1) - the single spell the published "
                "triage nominated as THE probe that resolves the coefficient-source "
                "question - is `indeterminate`, not proven live: its CAD entries "
                "(cadId 6258 / 18433 / 31685) match no live builder node. It is in "
                "indeterminateHoles, not liveHoles. Verify obtainability first, or "
                "pick a proven-live target."),
            "starcallerCheck": (
                "Starcaller Silvercurrent (503051 slots 2 and 3) was a tier-A hole in "
                "the published triage. It is reached only through the CAD entry "
                "'Douse', flagged deadCatalog - i.e. exactly the content the level-60 "
                "Starcaller player reported does not exist. The liveness join and the "
                "player report agree."),
        },
        "perClass": {"cad": per_class(cad_slots), "live": per_class(live_slots)},
        "livenessSource": {
            "consumedNotDerived": True,
            "flags": "data/classes/**/<tab>.json entry.live + entry.liveEvidence",
            "summary": "data/classes/_live_summary.json",
            "writer": "tools/coa_live.py (task W4-14)",
            "capture": "data/talents/coa/** from raw/talents/coa-builder-voljin.html (sha256-pinned)",
            "chainReasonCounts": dict(sorted(chain_reason_counts.items())),
            "chainReasonCountsUnit": (
                "CHAINS (one per spell reference on a walked entry), NOT entries. "
                "Deliberately does not match _live_summary.json's entry-level "
                "liveCountsByReason - an entry carrying three spells is three rows "
                "here and one there. Was misnamed entryReasonCounts before."),
            "liveDenominatorSlack": slack,
            "caveat": ("Every live/dead verdict is a VOL'JIN verdict. Rexxar is a "
                       "separate CoA realm whose tree geometry is assumed identical "
                       "but unverified. data/classes entries are account-wide across "
                       "four realms, so a Rexxar-only ability is indistinguishable "
                       "from dead content here."),
        },
        "method": {
            "spellSource": "raw/dbc/Spell.csv.gz (BASE only - never a realm overlay)",
            "spellRowsSkippedMalformed": skipped,
            "spellRowsLoaded": len(sp),
            "classes": nclasses,
            "entriesWalked": entries,
            "chainsWalked": len(recs),
            "entryTypes": list(ENTRY_TYPES),
            "levelCap": LEVEL_CAP,
            "rankPick": "highest rank with CAD rank.level <= 60; fallback = lowest-level rank",
            "chainSpellIdsAbsentFromBaseSpellDbc": len(dropped),
            "damagingSlotDefinition": {
                "weaponEffects": sorted(WEAPON_EFF),
                "directDamageEffects": sorted(DIRECT_DMG),
                "healEffects": sorted(HEAL_EFF),
                "auraCarrierEffects": sorted(AURA_CARRIER),
                "damageAuras": sorted(DMG_AURA),
                "healAuras": sorted(HEAL_AURA),
                "excluded": ("aura 118 is MOD_HEALING_PCT, not a heal; aura 227 "
                             "PERIODIC_TRIGGER_SPELL_WITH_VALUE is out of the "
                             "denominator - the largest boundary uncertainty"),
            },
            "channels": "W = weapon effect; P = effectRealPointsPerLevel or a bound $ppl/$PL; T = a stat*number coefficient term in description + tooltip + SpellDescriptionVariables",
            "verdictRule": ("gear-scaling (W or T) = modelable; percent-of-max effects "
                            "and 1-point tag damage = modelable (nothing to model); "
                            "otherwise a hole, split dev-dead / level-curve-only / no-channel"),
            "portedFrom": ("coa-sim-handoff/parsers/coverage/{bload,denom,clsfy,measure,"
                           "headline}.py - reimplemented here so the figure is "
                           "reproducible inside this repo"),
        },
        "caveats": [
            "The live denominator is a lower bound: indeterminate entries (live: null) "
            "are excluded from it and included in liveOrIndeterminate.",
            "Coverage measures whether a scaling channel EXISTS to model, not whether "
            "the resulting number is correct.",
            "Spell ids referenced by CoA classes that have no BASE Spell.dbc row at all "
            "(they exist only in a realm overlay) are dropped from every denominator "
            "identically - see method.chainSpellIdsAbsentFromBaseSpellDbc.",
            "valueAtCap on the hole rows is descriptive metadata, not part of any "
            "verdict; it uses the guide's canonical clamp formula (basePoints + "
            "dieSides + ...), so it reads higher than the published triage table, "
            "which quoted basePoints + 1 and did not clamp on maxLevel.",
            "The live denominator is slightly OVER-inclusive in two ways, both "
            "measured in livenessSource.liveDenominatorSlack rather than assumed "
            "small: `live` is stamped per ENTRY but consumed per CHAIN, so %d of "
            "the %d live chains (%.1f%%) enter the denominator on a spell id that "
            "is in no live node - they ride on a sibling spell of the same "
            "multi-spell entry; and %d live chains measure a different rank than "
            "the one the matched builder node holds, because rank_at_cap picks the "
            "highest rank with level <= %d rather than the node's rank. Neither "
            "moves the headline materially, but both are real."
            % (slack["chainsRidingOnASibling"], slack["liveChains"],
               slack["chainsRidingOnASiblingPct"],
               slack["chainsMeasuringAnotherRank"], LEVEL_CAP),
            "Liveness itself is consumed, so its caveats travel with it: liveViaRank "
            "is gated on SpellRankData chain name-coherence (recycled contiguous id "
            "blocks otherwise manufacture false positives), and `live` is an "
            "ABILITY-level claim - a live:true entry can sit on a CAD row the "
            "client's own loader discards. See tools/coa_live.py and "
            "data/classes/_live_summary.json.falseNegativeMeasurement.",
        ],
    }

    if write:
        with open(OUT, "w", encoding="utf-8") as fh:
            json.dump(doc, fh, indent=1, sort_keys=True, ensure_ascii=False)
            fh.write("\n")

    # ---- stdout report -----------------------------------------------------
    w = sys.stdout.write
    w("=" * 92 + "\n")
    w("DAMAGE-MODEL COVERAGE at level %d - CAD catalog vs live (castable) content\n" % LEVEL_CAP)
    w("=" * 92 + "\n")
    w("spell rows %d (skipped %d) | classes %d | entries %d | chains %d\n"
      % (len(sp), skipped, nclasses, entries, len(recs)))
    w("liveness by CHAIN (not by entry): %s\n" % dict(sorted(chain_reason_counts.items())))
    w("live denominator slack: %d/%d chains ride on a sibling spell, %d measure "
      "another rank\n" % (slack["chainsRidingOnASibling"], slack["liveChains"],
                          slack["chainsMeasuringAnotherRank"]))
    w("\n%-22s %8s %10s %8s %8s %10s\n"
      % ("denominator", "slots", "modelable", "%", "holes", "hole(sid,slot)"))
    for nm, f in (("CAD catalog", cad_fig), ("LIVE only", live_fig),
                  ("live+indeterminate", upper_fig)):
        w("%-22s %8d %10d %7.1f%% %8d %10d\n"
          % (nm, f["slots"], f["modelable"], f["modelablePct"], f["holes"],
             f["holeDistinctSpellSlotPairs"]))
    w("\nbuckets (CAD):  %s\n" % cad_fig["buckets"])
    w("buckets (LIVE): %s\n" % live_fig["buckets"])
    w("\nverdicts (CAD):\n")
    for k, v in cad_fig["verdicts"].items():
        w("   %-52s %5d\n" % (k, v))
    w("verdicts (LIVE):\n")
    for k, v in live_fig["verdicts"].items():
        w("   %-52s %5d\n" % (k, v))
    w("\nhole (spellId, slot) pairs: CAD %d -> live %d (live+indet %d); "
      "%d exist only in dead content (%.0f%%)\n"
      % (len(cad_pairs), len(live_pairs), len(upper_pairs), len(dead_only_pairs),
         100.0 * len(dead_only_pairs) / max(1, len(cad_pairs))))
    w("published triage population (level-curve-only): %d pairs -> %d proven live, "
      "%d live-or-indeterminate; %d not proven live (%d dead, %d indeterminate)\n"
      % (len(lco_cad), len(lco_live), len(lco_upper), len(lco_cad - lco_live),
         len(lco_cad - lco_upper), len(lco_upper) - len(lco_live)))
    bad = [g for g in golden if not g["ok"]]
    w("\ngolden checks vs the published audit: %d/%d pass%s\n"
      % (len(golden) - len(bad), len(golden),
         "" if not bad else "  FAIL: " + ", ".join(
             "%s exp %d got %d" % (g["check"], g["expected"], g["actual"]) for g in bad)))
    for title, lst in (("LIVE HOLE LIST", hole_list),
                       ("INDETERMINATE HOLES (confirm obtainability before probing)",
                        indet_list)):
        w("\n%s (%d distinct (spellId, slot) pairs)\n" % (title, len(lst)))
        w("%-14s %8s %3s %-26s %-15s %4s %-13s %8s  %s\n"
          % ("class", "spellId", "sl", "name", "builderTab", "tier", "verdict",
             "val@60", "formula"))
        for r in lst:
            w("%-14s %8d %3d %-26s %-15s %4s %-13s %8s  %s\n"
              % (r["klass"], r["spellId"], r["slot"], (r["name"] or "")[:26],
                 ",".join(r["builderTabs"])[:15] or "-",
                 ",".join(str(t) for t in r["builderTiers"]) or "-",
                 r["verdict"][5:18], r["valueAtCap"], (r["formula"] or "(none)")[:34]))
    if write:
        w("\nwrote %s\n" % OUT)
    return doc


if __name__ == "__main__":
    main(write="--no-write" not in sys.argv)
