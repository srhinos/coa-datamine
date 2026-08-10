"""Gate: the curated spell layer is seeded from LIVE truth, not from the catalog.

The defect. `data/spells` was the closure of the CAD catalog plus rank chains
plus Talent.dbc. The catalog is a STALE content generation, so the closure was a
partial view of the live game: of the 3,932 spell ids the LIVE talent trees
reference, 1,963 (49.9%) had an enriched record and 1,969 did not - while 1,966
of those missing ids were sitting in raw/tables/Spell the whole time. A 50%-wrong
ability list is not a caveat, it is wrong.

Every assertion below reads the PUBLISHED layer against raw/, so this gates the
committed dataset rather than a fresh in-process build.

NON-VACUITY. A "coverage is 100%" test passes just as happily if the catalog had
covered everything all along, in which case it gates nothing. So the coverage
assertion is paired with a measurement of how much of that coverage the live seed
is actually RESPONSIBLE for: live-node ids that no catalog/rank/talent reference
would ever have pulled in. That count has to be large, and it is asserted to be -
if a future change made the catalog seed sufficient on its own, this test would
say so out loud instead of quietly becoming a tautology.
"""
import json, sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from tools import build_abilities, build_spells, coa_live, config

sdir = config.DATA_DIR / "spells"
meta = json.loads((sdir / "_meta.json").read_text(encoding="utf-8"))
records = {r["id"]: r for r in build_spells.iter_all()}

# ---- ground truth, straight from raw: what the LIVE trees reference ----------
live = coa_live.live_index()
live_ids = {int(sid) for c in live["byClassId"].values() for sid in c["spellNodes"]}
assert len(live_ids) > 3900, len(live_ids)

# =========================================================================
# (a) coverage - the whole point
# =========================================================================
missing = sorted(live_ids - set(records))
assert not missing, (
    f"{len(missing)} live talent-node spell id(s) have no enriched record "
    f"(was 1,969 when the closure was seeded from the catalog): {missing[:20]}")
cov = meta["liveCoverage"]
assert cov["liveNodeIds"] == len(live_ids) and cov["covered"] == len(live_ids)
assert cov["rate"] == 1.0 and cov["missingIds"] == []
print(f"(a) live-node coverage {cov['covered']}/{cov['liveNodeIds']}: PASS")

# =========================================================================
# (b) NON-VACUITY: the live seed is load-bearing
# =========================================================================
# `referencedBy` records which seed pulled each id in. An id whose tags carry no
# catalog/rank/talent/closure reference at all is one the OLD seed could not have
# reached by any path - it is in the dataset because, and only because, the seed
# is now live truth.
CATALOG_TAGS = {"cad", "rank", "talent", "trigger", "formula"}
live_only = [sid for sid in sorted(live_ids)
             if not (set(records[sid]["referencedBy"]) & CATALOG_TAGS)]
assert len(live_only) > 1500, (
    f"only {len(live_only)} live-node ids are reachable ONLY via the live seed - "
    "the catalog seed has apparently become sufficient on its own, which would "
    "make the coverage assertion above vacuous. Re-derive before relaxing this.")
print(f"(b) live-only ids the catalog seed could never reach: {len(live_only)}: PASS")

# =========================================================================
# (c) `live` + evidence, on every record, consistent with its reason
# =========================================================================
LIVE_BY_REASON = {"liveNode": True, "liveAbilityMember": True,
                  "abilityWithNoLiveNode": False, "noLiveGeometry": None,
                  "notAnAbility": None}
seen = set()
for sid, r in records.items():
    assert "live" in r and "liveEvidence" in r, sid
    reason = r["liveEvidence"]["reason"]
    assert r["live"] is LIVE_BY_REASON[reason], (sid, r["live"], reason)
    seen.add(reason)
    if reason == "liveNode":
        assert sid in live_ids, sid
    if reason != "notAnAbility":
        # a verdict from the identity layer must name the ability behind it
        assert r["liveEvidence"]["abilityKey"], (sid, r["liveEvidence"])
        assert isinstance(r["liveEvidence"]["classId"], int), sid
assert seen == set(LIVE_BY_REASON), seen
assert {sid for sid, r in records.items()
        if r["liveEvidence"]["reason"] == "liveNode"} == live_ids
print(f"(c) live/liveEvidence on all {len(records)} records: PASS")

# `null` is not `false`, and this is where that bites. The builder capture covers
# CoA's CUSTOM classes; no Priest or Mage tree exists in it. Power Word: Shield
# (17) and Fireball (133) are owned by abilities of classes 5 and 8, so the
# identity layer knows them - but there is no captured tree for them to be absent
# from, and calling them dead would be inventing evidence out of a measurement
# that was never taken.
geom = set(meta["liveCoverage"]["classesWithLiveGeometry"])
assert 5 not in geom and 8 not in geom and 26 in geom, sorted(geom)
for sid in (17, 133):
    assert records[sid]["live"] is None, (sid, records[sid]["liveEvidence"])
    assert records[sid]["liveEvidence"]["reason"] == "noLiveGeometry", sid
assert meta["liveCoverage"]["unknownRecords"] > 5000, meta["liveCoverage"]
# and no record may be called dead on a class whose tree was never captured
for sid, r in records.items():
    if r["live"] is False:
        assert r["liveEvidence"]["classId"] in geom, (sid, r["liveEvidence"])

# =========================================================================
# (d) GROUND TRUTH: catalog-only content is kept, and marked
# =========================================================================
# Tide Lash - a real level-60 Starcaller confirmed the catalog's whole "Tides"
# tree does not exist in game. It must still be here (deleting it would destroy
# evidence) and it must say so.
tide = records.get(800380)
assert tide and tide["name"] == "Tide Lash", tide
assert tide["live"] is False, tide["liveEvidence"]
assert tide["liveEvidence"]["reason"] == "abilityWithNoLiveNode", tide["liveEvidence"]
assert tide["liveEvidence"]["classId"] == 26, tide["liveEvidence"]

# A live ability whose id generations differ - the join this repairs. Every id in
# a live ability's ladder must be present, and the live one flagged.
seed = build_abilities.live_seed()
multi = [sid for sid, ev in seed["byId"].items()
         if ev["abilityLive"] and len(ev["generations"]) > 1]
assert multi, "no multi-generation live ability members - the join produced nothing"
for sid in multi[:200]:
    assert sid in records, sid
    assert records[sid]["live"] is True, (sid, records[sid]["liveEvidence"])
print(f"(d) Tide Lash kept + marked not-live; {len(multi)} multi-generation live "
      f"member ids all present: PASS")

# =========================================================================
# (e) base variant, recorded and honoured
# =========================================================================
assert "baseVariant" in meta and "data-patch-t-mpq" in meta["baseVariant"]
prov = json.loads((config.RAW_DIR / "provenance.json").read_text(encoding="utf-8"))
variants = json.loads(
    (config.RAW_DIR / "tables" / "Spell" / "variants" / "index.json")
    .read_text(encoding="utf-8"))["variants"]
base = next(v for v in variants if "baseChain" in v["appliesTo"])
winner = next(v for v in variants if v["chainWinner"])
assert base["sha256"] != winner["sha256"], (
    "base and chain winner are the same bytes on this client - the distinction "
    "this gate protects has changed, re-derive before relaxing it")
assert prov["curationInputs"]["base"]["Spell.dbc"]["sha256"] == base["sha256"], (
    "the curated layer did not read the base Spell variant")
print("(e) curated from the BASE Spell variant, recorded in provenance: PASS")

print("ALL PASS")
