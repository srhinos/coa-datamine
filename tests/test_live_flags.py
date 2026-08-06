"""TDD gate for task W4-14: live-talent-builder truth joined onto the CAD catalog
(`live` / `liveEvidence` on data/classes/<Class>/*.json entries, `liveCounts` on the
per-class index, data/classes/_live_summary.json, and specs.json's re-derived
`tabStatus`).

The bug this gates against is a READING bug, so the pins are mostly about what the
data is allowed to CLAIM:

  - the ground truth is a real level-60 Starcaller player: their live trees are
    Moon Guard / Sentinel / Moon Priest / Warden / Class, and Tide Lash - which the
    CAD catalog lists under a "Tides" tree - does not exist in game. The method has
    to reproduce BOTH, by live tab NAME (not by the CAD names, which are a different
    generation) and by entry;
  - `live: false` is only ever allowed on an entry with no evidence of ANY
    acquisition path - the measured false-negative population (baseline/automatic
    grants, trainer rows, spellId-variant name twins) must land on live: null with
    reason "indeterminate" instead;
  - `tabStatus` must not be readable as "this tree is in the game" when it only
    means "a CAD tab with this token exists" - the W4-11e failure this task fixes.

Rebuilds the three writers in dependency order (classes -> coatalents -> classmeta),
matching build_dataset.py, so nothing here reads a stale artifact.
"""
import json, sys
from collections import Counter
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from tools import build_classes, build_classmeta, build_coatalents, coa_live, config

stats = build_classes.build()
build_coatalents.build()
classmeta_stats = build_classmeta.build()

cdir = config.DATA_DIR / "classes"
summary = json.loads((cdir / "_live_summary.json").read_text(encoding="utf-8"))
index = json.loads((cdir / "index.json").read_text(encoding="utf-8"))

REASONS = set(coa_live.REASONS)
LIVE_BY_REASON = {"liveDirect": True, "liveViaRank": True, "deadCatalog": False,
                  "indeterminate": None, "unknownNoGeometry": None}


def load_entries(cls):
    cidx = json.loads((cdir / cls / "index.json").read_text(encoding="utf-8"))
    out = []
    for f in cidx["files"]:
        out += json.loads((cdir / cls / f["file"]).read_text(encoding="utf-8"))["entries"]
    return cidx, out


# =========================================================================
# (a) schema: every entry carries live + liveEvidence, consistently
# =========================================================================
class_dirs = sorted(p.name for p in cdir.iterdir() if p.is_dir())
assert len(class_dirs) == 43, class_dirs

repo_reasons = Counter()
per_class_entries = {}
for cls in class_dirs:
    cidx, entries = load_entries(cls)
    per_class_entries[cls] = (cidx, entries)
    assert entries, cls
    for e in entries:
        assert "live" in e and "liveEvidence" in e, (cls, e["cadId"])
        ev = e["liveEvidence"]
        assert set(ev) >= {"reason", "matchedSpellId", "builderTab"}, (cls, e["cadId"])
        assert ev["reason"] in REASONS, ev
        assert e["live"] is LIVE_BY_REASON[ev["reason"]], (cls, e["cadId"], ev)
        # evidence must actually be evidence: a live verdict names the spell id and
        # the tab it was found in; a not-live verdict claims neither.
        if e["live"] is True:
            assert isinstance(ev["matchedSpellId"], int) and ev["builderTab"], ev
            chain = set(sum(coa_live.entry_spell_ids(e), []))
            assert ev["matchedSpellId"] in chain, (cls, e["cadId"], ev)
        else:
            assert ev["matchedSpellId"] is None and ev["builderTab"] is None, ev
        if ev["reason"] == "indeterminate":
            assert ev["signals"] and set(ev["signals"]) <= set(coa_live.ALT_SIGNALS), ev
        repo_reasons[ev["reason"]] += 1

print("(a) live/liveEvidence schema on all 43 class dirs: PASS")

# =========================================================================
# (b) count consistency: entries -> per-class index -> summary -> build stats
# =========================================================================
for cls in class_dirs:
    cidx, entries = per_class_entries[cls]
    reasons = Counter(e["liveEvidence"]["reason"] for e in entries)
    assert cidx["liveCounts"] == coa_live.live_counts(reasons), cls
    assert sum(cidx["liveCounts"].values()) == cidx["entryCount"] == len(entries), cls
    assert set(cidx["liveCounts"]) == {"live", "deadCatalog", "liveViaRank", "unknown"}
    assert cidx["liveCountsByReason"] == {r: n for r, n in reasons.items() if n}, cls
    # a class with no builder geometry may claim NOTHING either way
    if not cidx["hasLiveGeometry"]:
        assert set(reasons) == {"unknownNoGeometry"}, (cls, reasons)
    else:
        assert "unknownNoGeometry" not in reasons, cls
    assert summary["perClass"][cls]["liveCounts"] == cidx["liveCounts"], cls

top = {c["name"]: c for c in index["classes"]}
for cls in class_dirs:
    assert top[cls]["liveCounts"] == per_class_entries[cls][0]["liveCounts"], cls

totals = summary["totals"]
assert totals["liveCountsByReason"] == dict(repo_reasons)
assert sum(totals["liveCounts"].values()) == totals["entries"] == 23709
assert totals["classesWithLiveGeometry"] == 21 and totals["classesWithoutLiveGeometry"] == 22
assert stats["liveCounts"] == totals["liveCounts"]

# the headline split, pinned with slack so real content drift moves it but a broken
# join (everything dead / everything live) fails hard
lc = totals["liveCounts"]
assert lc["live"] > 3000 and lc["deadCatalog"] > 3000 and lc["unknown"] > 15000, lc
assert totals["liveCountsByReason"]["unknownNoGeometry"] == 15378

print(f"(b) count consistency: PASS {lc}")

# =========================================================================
# (c) GROUND TRUTH - a real level-60 Starcaller
# =========================================================================
sc_idx, sc_entries = per_class_entries["Starcaller"]
sc = summary["perClass"]["Starcaller"]

# 1. the live trees are the LIVE names, not the catalog's
assert sorted(sc["liveTabs"]) == ["Class", "Moon Guard", "Moon Priest", "Sentinel",
                                  "Warden"], sc["liveTabs"]
# and the catalog names a different generation entirely - this is the whole bug
assert summary["tabMapping"]["byClass"]["Starcaller"]["cadTabs"] == [
    "AstralWarfare", "Class", "Moonbow", "Tides"]

# 2. Tide Lash does NOT exist in game. Every CAD row for it (the catalog carries 3
#    duplicate rows) must be live: false with reason deadCatalog - not indeterminate,
#    not merely absent.
tide_lash = [e for e in sc_entries if e["name"] == "Tide Lash"]
assert len(tide_lash) == 3, len(tide_lash)
for e in tide_lash:
    assert e["live"] is False and e["liveEvidence"]["reason"] == "deadCatalog", e

# the player named four more of the same tree's abilities as nonexistent
for name in ("Pond", "Deluge", "Geyser"):
    rows = [e for e in sc_entries if e["name"] == name]
    assert rows and all(e["live"] is False for e in rows), name

# 3. ~53% of Starcaller's distinct CAD spell ids appear in no live node
assert 0.50 <= sc["cadSpellIdDeadRate"] <= 0.56, sc["cadSpellIdDeadRate"]

# 4. the dead content is concentrated in the catalog-only tree: the CAD "Tides" tab
#    is majority-dead while the class overall is not
tides = [e for e in sc_entries if e["tab"] == "Tides"]
tides_dead = sum(1 for e in tides if e["live"] is not True)
assert tides_dead / len(tides) > 0.60, (tides_dead, len(tides))

# 5. the tree SLOT survived under a new name - recorded as a mapping with evidence,
#    which is how "Tides" and "Moon Priest" are allowed to coexist
tides_map = next(r for r in summary["tabMapping"]["byClass"]["Starcaller"]["mapped"]
                 if r["cadTab"] == "Tides")
assert tides_map["liveTab"] == "Moon Priest", tides_map
assert tides_map["chrSpecs"]["tabToken"] == "TIDES"
assert tides_map["nodeOverlap"]["topLiveTab"] == "Moon Priest"

print("(c) Starcaller ground truth (live tabs, Tide Lash, 53% dead rate): PASS")

# =========================================================================
# (d) false-negative measurement - present, quantified, and ACTED ON
# =========================================================================
fn = summary["falseNegativeMeasurement"]
assert fn["entriesNotInTrees"] == (repo_reasons["deadCatalog"]
                                   + repo_reasons["indeterminate"])
assert fn["deadCatalogEntries"] == repo_reasons["deadCatalog"]
assert fn["indeterminateEntries"] == repo_reasons["indeterminate"] > 0
assert set(fn["signals"]) == set(coa_live.ALT_SIGNALS)
for sig, block in fn["signals"].items():
    assert block["entries"] > 0 and block["examples"], sig
    assert isinstance(block["separable"], bool) and block["verdict"], sig
# the automatic-grant probe is the one that separates cleanly; it must stay disjoint
# from the live set, which is what makes it trustworthy
assert fn["signals"]["skillLineAutoGrant"]["separable"] is True
alt = coa_live.alt_acquisition_index()
live_ids = {sid for c in coa_live.live_index()["byClassId"].values()
            for sid in c["spellNodes"]}
assert not (live_ids & alt["autoGrantSpellIds"]), "auto-grant probe overlaps live nodes"
# the heuristic the task suggested first is REJECTED by measurement, not by opinion:
# it fires on a large share of PROVEN-live entries, so it has no specificity
rej = fn["rejectedHeuristic"]
assert rej["rateOnProvenLiveEntries"] > 0.10, rej
assert rej["rateOnNotInTrees"] - rej["rateOnProvenLiveEntries"] < 0.20, rej

# every indeterminate entry must really carry a signal, and no deadCatalog entry may
# carry one - otherwise live:false is being guessed over a known acquisition path
for cls in class_dirs:
    cidx, entries = per_class_entries[cls]
    if not cidx["hasLiveGeometry"]:
        continue
    cl = coa_live.live_index()["byClassId"][cidx["classId"]]
    for e in entries:
        sig = coa_live.alt_signals(e, cl, alt)
        if e["liveEvidence"]["reason"] == "deadCatalog":
            assert not sig, (cls, e["cadId"], sig)
        elif e["liveEvidence"]["reason"] == "indeterminate":
            assert e["liveEvidence"]["signals"] == sig, (cls, e["cadId"])

print(f"(d) false-negative measurement: PASS "
      f"{fn['indeterminateEntries']}/{fn['entriesNotInTrees']} not-in-trees entries "
      f"({fn['indeterminateRateOfNotInTrees']:.1%}) held back as indeterminate")

# =========================================================================
# (e) provenance + the Rexxar caveat must travel with the verdicts
# =========================================================================
prov = summary["payload"]
assert prov["slug"] == "voljin" and prov["capturedUtc"], prov
assert len(prov["sha256"]) == 64, prov
assert prov["sha256"] == json.loads(
    (config.RAW_TALENTS_DIR / "_fetch.json").read_text(encoding="utf-8"))["sha256"]
assert "Rexxar" in summary["realmCaveat"] and "UNVERIFIED" in summary["realmCaveat"]
assert summary["method"]["rule"] and summary["groundTruth"]["starcallerLiveTabs"]

print("(e) payload provenance + Vol'jin/Rexxar caveat: PASS")

# =========================================================================
# (f) tab mapping: evidenced, injective, and never invented
# =========================================================================
tm = summary["tabMapping"]["byClass"]
assert len(tm) == 21
for cls, m in tm.items():
    live_names = set(m["liveTabs"])
    seen = set()
    for r in m["mapped"]:
        assert r["method"] in (None, "chrSpecsSpecName", "sameName", "nodeOverlap"), r
        if r["liveTab"] is None:
            assert r["method"] is None and r["cadTab"] in m["unmatchedCadTabs"], r
            continue
        assert r["liveTab"] in live_names, r
        assert r["liveTab"] not in seen, (cls, r)   # injective: no two CAD tabs -> one live tab
        seen.add(r["liveTab"])
        assert r["nodeOverlap"]["cadTabMatchedEntries"] >= 0
    assert set(m["unmatchedLiveTabs"]) == live_names - seen, cls

agree = summary["tabMapping"]["methodAgreementWithNodeOverlap"]
assert agree["pairsCheckable"] == 84 and agree["rate"] > 0.90, agree
# disagreements are recorded, not resolved away
assert len(agree["disagreements"]) == agree["pairsCheckable"] - agree["agreeing"]

print(f"(f) tab mapping: PASS {agree['agreeing']}/{agree['pairsCheckable']} agree "
      f"with the independent node-overlap cross-check")

# =========================================================================
# (g) specs.json tabStatus - renamed states that cannot be misread
# =========================================================================
specs_doc = json.loads((cdir / "specs.json").read_text(encoding="utf-8"))
by_id = {s["id"]: s for s in specs_doc["specs"]}
STATES = {"inLiveBuilder", "cadOnly", "unreleased", "noLiveGeometry", "noCadClass"}
# the old, misleading vocabulary must be gone entirely
OLD = {"live", "shippedExternal", "noTabLayer"}
for s in specs_doc["specs"]:
    if s["classId"] is not None and s["tabToken"]:
        st = s["tabStatus"]
        assert st is not None and st["status"] in STATES, s
        assert st["status"] not in OLD
        assert set(st) == {"status", "cadTab", "liveTab", "match", "renamed"}, st
        if st["status"] == "inLiveBuilder":
            assert st["liveTab"] and st["match"]
            assert st["renamed"] == (st["cadTab"] is not None
                                     and st["cadTab"] != st["liveTab"])
        else:
            assert st["liveTab"] is None
    else:
        assert s["tabStatus"] is None

counts = specs_doc["tabStatusSummary"]["counts"]
assert set(counts) <= STATES and sum(counts.values()) == 101, counts
assert classmeta_stats["specs"]["tabStatusCounts"] == counts
assert counts["inLiveBuilder"] == 70 and counts["noCadClass"] == 1

# Starcaller again, at the spec layer: the tree a consumer would have called "Tides"
# is reported by its LIVE name, with the rename flagged
assert by_id[43]["tabStatus"] == {"status": "inLiveBuilder", "cadTab": "Tides",
                                  "liveTab": "Moon Priest", "match": "specName",
                                  "renamed": True}
# all four Starcaller spec trees resolve to the four the player actually has
assert {by_id[i]["tabStatus"]["liveTab"] for i in (43, 44, 45, 100)} == {
    "Moon Priest", "Sentinel", "Warden", "Moon Guard"}

# the token is the CATALOG generation and must never win over the spec name:
# Chronomancer 33 is tabToken TIME but its live tree is "Artificer", while the live
# tab literally named "Time" belongs to spec 31 (tabToken DISPLACEMENT)
assert by_id[33]["tabToken"] == "TIME" and by_id[33]["tabStatus"]["liveTab"] == "Artificer"
assert by_id[31]["tabToken"] == "DISPLACEMENT" and by_id[31]["tabStatus"]["liveTab"] == "Time"

# W4-9's two "unmatchedExtraTabs" are now attributed by mechanism (spec name), which
# is what retires Sec 11's "unreleased" list entirely
assert by_id[45]["tabStatus"]["liveTab"] == "Warden"        # Starcaller/HYDROMANCY
assert by_id[96]["tabStatus"]["liveTab"] == "Dreadnought"   # Cultist/BULWARK
assert by_id[47]["tabStatus"]["liveTab"] == "Valkyrie"      # SunCleric/VALKYR
assert by_id[97]["tabStatus"]["liveTab"] == "Black Knight"  # WitchHunter/WITCHKNIGHT

# classes with no builder capture claim nothing; Hero has no CAD directory at all
assert by_id[91]["tabStatus"]["status"] == "noLiveGeometry"      # Druid/BALANCE
assert by_id[94]["className"] == "Hero" and by_id[94]["tabStatus"]["status"] == "noCadClass"

renamed = specs_doc["tabStatusSummary"]["renamedInLiveBuilder"]
assert len(renamed) == sum(1 for s in specs_doc["specs"]
                           if s["tabStatus"] and s["tabStatus"]["renamed"])
assert len(renamed) >= 20, len(renamed)   # the misreading was widespread, not a one-off

print(f"(g) specs.json tabStatus: PASS {counts}, {len(renamed)} renamed trees")
print("test_live_flags: ALL PASS")
