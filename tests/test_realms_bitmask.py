"""TDD gate for task W4-8: attempt to decode the CAD `Realms` bitmask against the
6-realm roster (Vol'jin, Rexxar, Darkmoon, Dawnrise, Bronzebeard, Area 52) per
DATAMINE-REQUEST.md Sec 6.2 / Sec 13 item 10.

Outcome: HONEST FAILURE (explicitly allowed by the brief). No bit assignment
classifies all of the >=3 required independent known groups (reborn/Bronzebeard,
coa-custom/Vol'jin+Rexxar, vanilla/Area 52) - the strongest lead (bit 16, tied to a
real Util.lua realm-id citation for Bronzebeard) separates reborn cleanly but no
bit comes close to separating coa-custom or vanilla, and the best coa-custom
signal (bit 26) turns out to track the CAD `Type` field rather than realm
membership. Per the binding rule ("emit only proven bits"), no `realmFlags` is
emitted anywhere - raw `realms` is untouched on every data/classes/ entry. This
test therefore pins the failure-path deliverable: data/classes/_realms_evidence.json
(distinct-value census + per-bit statistics + candidate-hypothesis scoring +
verdict) and the fact that no realmFlags leaked into curated class entries."""
import json, sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from tools import config, build_classes

stats = build_classes.build()
assert stats["realmsBitmaskGoldenBarMet"] is False, stats

cdir = config.DATA_DIR / "classes"
evidence = json.loads((cdir / "_realms_evidence.json").read_text(encoding="utf-8"))

# ---- top-level shape ----
EXPECTED_KEYS = {
    "_generatedBy", "task", "realmRoster", "totalEntries", "distinctValueCount",
    "distinctValues", "tagCounts", "tagTopValues", "bitStatsByTag",
    "duplicationExample", "broaderFieldSweep", "knownAnomalies",
    "candidateHypotheses", "luaFindings", "verdict",
}
assert set(evidence) == EXPECTED_KEYS, set(evidence)
assert evidence["realmRoster"] == [
    "Vol'jin", "Rexxar", "Darkmoon", "Dawnrise", "Bronzebeard", "Area 52"]

# ---- distinct-value census: pins the enumerate-first step (brief: "probably <50
# distinct values across 23k entries") ----
assert evidence["totalEntries"] == 23709, evidence["totalEntries"]
assert evidence["distinctValueCount"] == 28, evidence["distinctValueCount"]
assert len(evidence["distinctValues"]) == 28
assert sum(d["count"] for d in evidence["distinctValues"]) == evidence["totalEntries"]
for d in evidence["distinctValues"]:
    assert set(d) == {"value", "count", "popcount", "bits"}
    assert isinstance(d["value"], str)          # raw JSON stores Realms as a string
    v = int(d["value"])
    assert d["popcount"] == bin(v).count("1") == len(d["bits"])
    assert d["bits"] == [i for i in range(32) if v & (1 << i)]
    assert 0 <= v <= 0xFFFFFFFF
# the two extremes cited throughout the brief/spec must both be present
values = {d["value"] for d in evidence["distinctValues"]}
assert {"0", "6144", "4093639647", "100679750", "4294967295"} <= values

# dominant value per known population, sanity-anchored (see report for full census)
by_value = {d["value"]: d for d in evidence["distinctValues"]}
top = max(evidence["distinctValues"], key=lambda d: d["count"])
assert top["value"] == "33679686" and top["count"] == 12486    # reborn's near-universal value

# ---- tag census matches build_classes' own tagging ----
assert evidence["tagCounts"] == {
    "reborn": 12487, "coa-custom": 8331, "vanilla": 2829, "meta": 62}
assert sum(evidence["tagCounts"].values()) == evidence["totalEntries"]
for tag, top_list in evidence["tagTopValues"].items():
    assert tag in evidence["tagCounts"]
    assert top_list == sorted(top_list, key=lambda d: -d["count"])
    assert sum(d["count"] for d in top_list) <= evidence["tagCounts"][tag]

# ---- per-bit statistics: full 0-31 coverage, each a fraction in [0, 1] ----
assert set(evidence["bitStatsByTag"]) == {str(b) for b in range(32)}
for bit, by_tag in evidence["bitStatsByTag"].items():
    assert set(by_tag) == set(evidence["tagCounts"])
    assert all(0.0 <= f <= 1.0 for f in by_tag.values())
# bit 16 = the report's best (still unproven) lead: ~100% reborn, near-zero coa-custom
assert evidence["bitStatsByTag"]["16"]["reborn"] == 1.0
assert evidence["bitStatsByTag"]["16"]["coa-custom"] < 0.05
# no bit clears anywhere near full coverage on coa-custom - the core negative result
assert max(evidence["bitStatsByTag"][str(b)]["coa-custom"] for b in range(32)) < 0.5

# ---- duplication example: the doc's own Sec 0 claim (same ability, 3 CAD rows,
# 3 different Realms values) reproduced from the live dataset, not asserted blind ----
dup = evidence["duplicationExample"]
assert dup and dup["class"] and dup["spellIds"]
dup_values = {r["realms"] for r in dup["rows"]}
assert len(dup_values) >= 3
assert len({r["cadId"] for r in dup["rows"]}) == len(dup["rows"])   # distinct CAD rows
assert len({r["name"] for r in dup["rows"]}) == 1                   # same ability name
# [review follow-up] rows carry Tab/Flags/Icon too - the row-level proof that this
# is authoring/UI context, not realm availability: same spell, different Tab/Flags
for r in dup["rows"]:
    assert set(r) == {"cadId", "realms", "name", "tab", "flags", "icon"}, r
assert len({r["tab"] for r in dup["rows"]}) >= 2, "expected differing Tab across rows"
assert len({r["flags"] for r in dup["rows"]}) >= 1

# ---- broaderFieldSweep: reviewer-run correlations, re-verified live ----
sweep = evidence["broaderFieldSweep"]
assert set(sweep) == {"note", "qualityPoor", "requiredLevel10", "perTabBitFraction"}
assert sweep["qualityPoor"]["count"] > 0
assert sweep["qualityPoor"]["fracRealms100679750"] >= 0.9    # ~90%+ per review
assert sweep["requiredLevel10"]["count"] > 0
assert 0.0 <= sweep["requiredLevel10"]["fracRealms100679750"] <= 1.0
pt = sweep["perTabBitFraction"]
assert set(pt) == {"bit", "classTab", "otherTabsRange", "otherTabsCount"}
assert pt["classTab"] is not None and pt["classTab"] > 0.9    # Class tab standout ~99.5%
assert pt["otherTabsRange"][1] < pt["classTab"]                # every other tab well below it
assert pt["otherTabsCount"] > 0

# ---- knownAnomalies: DeathKnight's vanilla-class outlier distribution ----
anomalies = evidence["knownAnomalies"]
assert isinstance(anomalies, list) and len(anomalies) >= 1
dk = next(a for a in anomalies if a["class"] == "DeathKnight")
assert set(dk) == {"class", "finding", "deathKnightCount", "deathKnightTop3Values",
                    "has134218784ByOtherVanillaClass"}
assert dk["deathKnightCount"] > 0
assert "134218784" not in dk["deathKnightTop3Values"]
assert dk["has134218784ByOtherVanillaClass"]                   # non-empty dict
assert all(dk["has134218784ByOtherVanillaClass"].values()), dk["has134218784ByOtherVanillaClass"]

# ---- every candidate hypothesis the brief asked us to test is present ----
names = " | ".join(h["name"] for h in evidence["candidateHypotheses"])
assert "per-realm bit position" in names
assert "realmId" in names
assert "grouped" in names or "mode bits" in names
for h in evidence["candidateHypotheses"]:
    assert set(h) == {"name", "verdict", "reason"}
    assert h["reason"]
# the overall golden bar must not be reported as cleared by any hypothesis
assert not any(h["verdict"] == "PROVEN" for h in evidence["candidateHypotheses"])

# ---- Lua findings are real file citations, not placeholders ----
assert len(evidence["luaFindings"]) >= 4
for f in evidence["luaFindings"]:
    assert set(f) == {"file", "lines", "finding"}
    assert f["file"].startswith("raw/interface/")
    assert (config.REPO_ROOT / f["file"]).is_file(), f["file"]

# ---- verdict: explicit, honest failure ----
v = evidence["verdict"]
assert v["goldenBarMet"] is False
assert v["realmFlagsEmitted"] is False
assert v["groupsSatisfied"] == []
assert len(v["groupsCircumstantial"]) == 1 and "reborn" in v["groupsCircumstantial"][0]
assert set(v["groupsUnresolved"]) == {
    "coa-custom (Vol'jin/Rexxar)", "vanilla (Area 52)", "Darkmoon", "Dawnrise"}
assert v["recommendedFollowUp"]
assert "Tab" in v["authoringContextEvidence"] and "Flags" in v["authoringContextEvidence"]

# ---- binding rule: raw `realms` untouched, no `realmFlags` leaked into curated
# class entries anywhere under data/classes/ ----
index = json.loads((cdir / "index.json").read_text(encoding="utf-8"))
byname = {c["name"]: c for c in index["classes"]}
for cls_name in ("Barbarian", "RebornWarlock", "Mage"):
    meta = json.loads((cdir / byname[cls_name]["index"]).read_text(encoding="utf-8"))
    for f in meta["files"]:
        doc = json.loads((cdir / byname[cls_name]["dir"] / f["file"]).read_text(encoding="utf-8"))
        for e in doc["entries"]:
            assert "realmFlags" not in e, (cls_name, e)
            assert "realms" in e and isinstance(e["realms"], str)

print("ALL PASS")
