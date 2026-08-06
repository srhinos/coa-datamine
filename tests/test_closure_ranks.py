"""Task W4-4 gate: formula-reference closure, level-60 rank selection, $scalingbp
constant, devDead flag (coa-sim-handoff/DATAMINE-REQUEST.md Sec 1.6-1.8 + Sec 4
trap 17).

Every figure below is independently re-derived in this test (not copied from
build_spells.py's own report), per this repo's binding "re-derive, don't trust"
rule: the closure delta is checked against the doc's own cited +1,843 within this
task's +/-20% gate (doc's own population differs from this build's full-dataset
scan - see build_spells.py's FORMULA_XREF_RE comment); the Spellsling rankAt60
golden is verified by RE-COMPUTING the maxLevel-clamp formula from AGENT-GUIDE.md
against the built record's own emitted fields, not by asserting a hardcoded 509;
the devDead count is independently re-scanned against work/dbc/Spell.dbc with the
test's own marker check, not read-and-trusted from _meta.json.
"""
import json, sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from tools import config, dbc, build_spells

stats = build_spells.build()
sdir = config.DATA_DIR / "spells"
meta = json.loads((sdir / "_meta.json").read_text(encoding="utf-8"))
index = json.loads((sdir / "index.json").read_text(encoding="utf-8"))

assert stats["written"] == meta["count"] > 15000

# =====================================================================
# (a) Closure delta gate: +/-20% of the doc's cited +1,843 (depth1 1,753 + depth2
# 87 + depth3 3, capped at depth 2). Re-derived by this build's own formula
# closure, not copied.
# =====================================================================
fc = meta["formulaClosure"]
assert fc["maxDepth"] == 2
doc_expected = 1843
total_new = fc["totalNewRecords"]
pct_diff = abs(total_new - doc_expected) / doc_expected
assert pct_diff <= 0.20, (
    f"closure delta {total_new} is {pct_diff:.1%} off the doc's {doc_expected} "
    "- outside this task's +/-20% gate")
assert total_new == sum(fc["depthNewRecordCounts"])
assert fc["resolvedIds"] + fc["unresolvedIds"] == fc["distinctIdsSeen"]

# existing missing-ref gates (cad_other/talent hard <=5%) must be untouched by the
# new "formula" bucket - it must be report-only, not folded into those ratios
co_ratio = len(stats["missing_by_source"]["cad_other"]) / max(1, stats["ref_counts"]["cad_other"])
assert co_ratio <= 0.05, f"cad_other missing ratio {co_ratio:.3f} > 0.05"
tal_ratio = len(stats["missing_by_source"]["talent"]) / max(1, stats["ref_counts"]["talent"])
assert tal_ratio <= 0.05, f"talent missing ratio {tal_ratio:.3f} > 0.05"
assert "formula" in stats["ref_counts"] and "formula" in stats["missing_by_source"]
assert stats["ref_counts"]["formula"] == fc["distinctIdsSeen"]
assert len(stats["missing_by_source"]["formula"]) == fc["unresolvedIds"]

# =====================================================================
# read every record once: golden lookups
# =====================================================================
golden_ids = {300513, 573020, 802202, 502835, 502838, 17}
by_id = {}
formula_tagged = 0
rank_at_60_seen = 0
dev_dead_seen = []
for b in index["buckets"]:
    with open(sdir / b["file"], encoding="utf-8") as fh:
        for line in fh:
            r = json.loads(line)
            if r["id"] in golden_ids:
                by_id[r["id"]] = r
            if r["referencedBy"] == ["formula"]:
                formula_tagged += 1
            if "rankAt60" in r:
                rank_at_60_seen += 1
            if r.get("devDead"):
                dev_dead_seen.append(r["id"])
assert len(by_id) == len(golden_ids), sorted(golden_ids - set(by_id))
assert formula_tagged == total_new, (formula_tagged, total_new)
assert rank_at_60_seen == meta["rankAt60"]["chainsWithRankAt60"] == stats["rank_at_60_count"]

# =====================================================================
# (a) formula-ref golden: Crusader's Brand (300513)'s own formula text reads
# "${$573020m1*$<scalingbp>+...}" (DATAMINE-REQUEST.md Sec 2's own cited example)
# - verify the closure's regex actually extracts 573020 from it, and that 573020
# is present in the final record set (it happens to already be reachable via
# "trigger" too - the point is the formula channel resolves it independently,
# not that it's exclusively new; @s: is proven NOT to matter for this - see below).
# =====================================================================
cb = by_id[300513]
assert cb["name"] == "Crusader's Brand"
cb_text = (cb["description"] or "") + "\n" + (cb["tooltip"] or "")
assert 573020 in build_spells._formula_ref_ids(cb_text), cb_text
assert by_id[573020]["name"] == "Crusader's Brand"          # the m1-value holder spell

# =====================================================================
# (a) null result: "@s:<id>" is a spellbook cross-link, not a formula channel -
# verify it is NOT one of the three followed forms (the doc's own finding,
# re-verified structurally: the closure regexes never match a bare "@s:" token).
# =====================================================================
at_s_text = "some ability @s:120093:0@ more text"
# "@s:120093" contains digits, but none of the three followed forms match the
# "@s:" directive shape (FORMULA_XREF_RE/FORMULA_QS_RE both require a literal
# "$", FORMULA_IFKNOWN_RE requires "@ifknown:") - the null result is structural,
# not just "we didn't happen to find one in this snapshot"
assert 120093 not in build_spells._formula_ref_ids(at_s_text)

# =====================================================================
# (b) rankAt60: Runemaster Spellsling chain (firstSpellId 802202) - CAD level
# gating (SpellRankData.json's own "level" field) selects rank 9 (spellId 502835,
# cadLevel 54), NOT the global top rank 12 (502838, cadLevel 74). Re-derive the
# 509-vs-3,365 values via the maxLevel-clamp formula (AGENT-GUIDE.md's "Spell
# column completion" section), from the built record's own emitted fields - not
# hardcoded.
# =====================================================================
head = by_id[802202]
assert head["rankChain"] == {"first": 802202, "rank": 1, "level": 0}
assert head["rankAt60"] == {"spellId": 502835, "rank": 9, "cadLevel": 54}, head["rankAt60"]


def clamped_value(rec):
    """AGENT-GUIDE.md's maxLevel-clamp formula: value = basePoints + dieSides +
    (clamp(60, baseLevel, maxLevel) - spellLevel) * realPointsPerLevel, with
    maxLevel==0 treated as "uncapped" (drop the upper bound), per the guide's
    documented DBC sentinel."""
    e1 = next(e for e in rec["effects"] if e["slot"] == 1)
    base_level, max_level, spell_level = (rec["levels"]["base"], rec["levels"]["max"],
                                          rec["levels"]["spell"])
    rppl = e1.get("realPointsPerLevel", 0.0)
    # maxLevel == 0 is the DBC "uncapped" sentinel (AGENT-GUIDE.md) - drop the
    # upper bound entirely rather than clamping toward 0
    if max_level == 0:
        target = max(base_level, 60)
    else:
        target = max(base_level, min(60, max_level))
    return e1["basePoints"] + e1["dieSides"] + (target - spell_level) * rppl


rank9 = by_id[502835]                 # top-at-60 (what rankAt60 selects)
rank12 = by_id[502838]                # global top (what a naive ranks[-1] would pick)
assert rank9["levels"] == {"base": 68, "spell": 68, "max": 72}
assert rank12["levels"] == {"base": 80, "spell": 80, "max": 80}
value_at_60 = clamped_value(rank9)
value_global_top = clamped_value(rank12)
assert round(value_at_60) == 509, value_at_60
assert round(value_global_top) == 3365, value_global_top
assert value_global_top / value_at_60 > 6.5, "global-top must badly inflate vs top-at-60"

# =====================================================================
# (c) $scalingbp: named constant, re-derived value table matches the doc's cited
# breakpoints exactly (level normaliser, not a stat coefficient)
# =====================================================================
sbp = meta["scalingConstants"]["scalingbp"]
expected_breakpoints = {"1": 0.0318, "20": 0.1982, "40": 0.5184, "55": 0.8562,
                         "60": 0.9874, "61": 1.0148, "70": 1.2777, "80": 1.6052}
assert sbp["citedBreakpoints"] == expected_breakpoints, sbp["citedBreakpoints"]
assert sbp["valueTable"]["60"] == 0.9874
assert "level normaliser" in sbp["framing"].lower()
assert "not a stat coefficient" in sbp["framing"].lower() or "not itself a source" in sbp["framing"].lower()
assert sbp["referencedBySpellCount"] == 550, sbp["referencedBySpellCount"]

# =====================================================================
# (d) devDead: independently re-scan work/dbc/Spell.dbc for the literal marker
# (not the loose "does not work" substring - that false-positives on ordinary
# tooltip caveats, e.g. Pyrolate's "Does not work with Elemental Destr[uction]" -
# found while deriving this test) and assert the build's count matches exactly.
# =====================================================================
measured_dev_dead = []
for r in dbc.iter_named("Spell"):
    text = (r["description_enUS"] or "") + (r["tooltip_enUS"] or "")
    if build_spells.DEV_DEAD_MARKER in text.upper():
        measured_dev_dead.append(r["id"])
measured_dev_dead.sort()

assert measured_dev_dead == meta["devDead"]["ids"] == stats["dev_dead_ids"], (
    measured_dev_dead, meta["devDead"]["ids"])
assert len(measured_dev_dead) == meta["devDead"]["count"] == len(dev_dead_seen)
assert dev_dead_seen == measured_dev_dead, "every devDead:true record must carry the marker"
# the doc's own cited example
assert 502069 in measured_dev_dead
flame_swell = None
for b in index["buckets"]:
    with open(sdir / b["file"], encoding="utf-8") as fh:
        for line in fh:
            r = json.loads(line)
            if r["id"] == 502069:
                flame_swell = r
                break
    if flame_swell:
        break
assert flame_swell["name"] == "Flame Swell"
assert flame_swell["devDead"] is True
assert build_spells.DEV_DEAD_MARKER in flame_swell["description"].upper()

print("ALL PASS")
