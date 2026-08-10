"""Gate for data/abilities/ - the join across CoA's spell-id generations.

The claim under test is not "the builder runs"; it is that the join reaches the
generations it says it reaches, refuses the ones it says it refuses, and holds
on cases with independent proof:

  * COVERAGE - every live talent-node spell id lands in an ability. This is the
    whole point of the layer: the older data/spells curation covered 1,963 of
    the 3,932 live-node ids (49.9%), because it was seeded from the CAD catalog.
  * RANK-CHAIN GATE - SpellRankData carries recycled contiguous id blocks, not
    only rank ladders. Chain head 801667 is the proven one (rank 1 "Revitalize
    (Rank 1 DEPRECATED)" ... rank 11 "Mirage"); without the name-coherence gate
    it merges WitchDoctor's "Revitalize" into the live node "Mirage". Pinned
    both ways: the gate fires on that chain, and coherent chains still expand.
  * TRAINER LADDERS - Shooting Star (live node 800505, trainer ranks 2-7),
    Prayer of Elune (801987), Headhunter's Spear (804137) and Berserker Axe
    (804138) are ability/trainer pairs verified independently in
    tools/coa_live.py's docstring. Each must come out as ONE ability carrying
    both generations and a level-ordered ladder.
  * GROUND TRUTH - Starcaller's "Tide Lash" (800380) does not exist in game (a
    real level-60 player proved it). It must be present as CAD content and
    NOT live.
  * NO FALSE MERGES - (classId, name) is not an identity. 35 name groups hold
    two or more DISTINCT live builder nodes with different base-Spell
    descriptions (c12:savage = Brutality's 560441 "Unbridled Rage now also
    increases your critical damage" AND Headhunting's 705242 "Born in Blood now
    also increases your damage"; c19:paladintraining = Zealot's 504808 AND
    Crusader's 520009; c31:stoneskin = Geomancy's 706162/707809 AND Mountain
    King's 806583). Merged, they read as one ability with a fake rank ladder and
    contradictory text. No ability may hold two live nodes that were not proven
    the same, and the split records must stay reachable from each other.
  * NO HAND JUDGEMENT - the emitted normalization rule must reproduce the
    normalized names in the data.
"""
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from tools import build_abilities, coa_live, config

MAX_LINES = 5000

summary = build_abilities.build()
OUT = config.DATA_DIR / "abilities"
INDEX = json.loads((OUT / "index.json").read_text(encoding="utf-8"))
META = json.loads((OUT / "_meta.json").read_text(encoding="utf-8"))

RECORDS = []
for f in sorted(OUT.glob("*.json")):
    if f.name.startswith("_") or f.name == "index.json":
        continue
    RECORDS.extend(json.loads(f.read_text(encoding="utf-8"))["abilities"])
BY_KEY = {r["key"]: r for r in RECORDS}
BY_ID = {}
for r in RECORDS:
    for m in r["members"]:
        BY_ID.setdefault(m["id"], []).append(r)


def test_every_live_node_spell_id_is_joined():
    live = coa_live.live_index()
    live_ids = {sid for cl in live["byClassId"].values() for sid in cl["spellNodes"]}
    assert live_ids, "no live nodes parsed - capture missing"
    missing = sorted(sid for sid in live_ids if sid not in BY_ID)
    assert not missing, f"{len(missing)} live-node spell ids joined nothing: {missing[:20]}"
    assert summary["unjoinedBySource"]["liveNode"] == 0


def test_live_ids_carry_their_own_class():
    live = coa_live.live_index()
    for cid, cl in live["byClassId"].items():
        for sid, node in cl["spellNodes"].items():
            recs = [r for r in BY_ID[sid] if "liveNode" in
                    dict((m["id"], m) for m in r["members"])[sid]["generations"]]
            assert recs, f"{sid} has no liveNode membership"
            assert all(r["classId"] == cid for r in recs), (sid, cid)


def test_rank_chain_name_coherence_gate_fires_on_the_proven_recycled_chain():
    # 801667's members are unrelated abilities sharing a contiguous id block.
    gate = META["rankChainGate"]
    assert gate["nameIncoherent"] > 0
    heads = {e["chainHead"] for e in gate["examples"]}
    srd = json.loads((config.RAW_CONTENT_DIR / "SpellRankData.json")
                     .read_text(encoding="utf-8-sig"))
    recycled = sorted({r["spellId"] for r in srd if r["firstSpellId"] == 801667}
                      | {801667})
    assert recycled, "chain 801667 absent from this snapshot - re-pin this test"
    # "Mirage" (501136) is a live WitchDoctor node inside that block; nothing
    # else from the block may share its ability.
    mirage = BY_ID.get(501136)
    assert mirage, "live node 501136 (Mirage) missing"
    for r in mirage:
        others = {m["id"] for m in r["members"]} & set(recycled) - {501136}
        assert not others, (
            f"recycled chain 801667 leaked {sorted(others)} into {r['key']}")
    assert heads or gate["nameIncoherent"] == 0


def test_coherent_chains_still_expand():
    assert summary["stageCounts"]["rankChainMemberships"] > 0
    assert META["rankChainGate"]["coherent"] > META["rankChainGate"]["nameIncoherent"]


def test_trainer_ladders_join_the_live_node():
    for live_id, ranks in ((800505, (502295, 502296, 502297)),
                           (801987, (502348, 502349, 502350, 502351)),
                           (804137, (503402, 503403, 503404)),
                           (804138, (503408, 503409, 503410))):
        recs = BY_ID.get(live_id)
        assert recs, f"live node {live_id} missing"
        rec = next(r for r in recs if live_id in r["liveIds"])
        ids = {m["id"] for m in rec["members"]}
        assert set(ranks) <= ids, (rec["key"], sorted(ids))
        assert rec["trainerTaught"] and rec["live"]
        assert "liveNode" in rec["generations"] and "trainer" in rec["generations"]
        levels = [x["level"] for x in rec["rankLadder"]]
        assert levels == sorted(levels), rec["key"]


def test_player_proven_dead_content_is_not_live():
    recs = BY_ID.get(800380)
    assert recs, "Tide Lash 800380 missing from the layer entirely"
    for r in recs:
        assert not r["live"], f"{r['key']} claims live; a real player proved it dead"
        assert "cad" in r["generations"]


def test_no_ability_merges_two_distinct_live_nodes():
    """The false-merge gate, measured on the shipped records rather than trusted.

    An ability may carry several live-node MEMBER IDS (the same node's ranks), but
    never two distinct live node IDS unless live_node_variants() proved their
    effect signatures identical - in which case they are one record on purpose and
    the group did not split. So: zero records with several live node ids among the
    names that split, and zero anywhere the gate says it split."""
    offenders = []
    for r in RECORDS:
        nodes = {m["evidence"]["liveNode"]["nodeId"] for m in r["members"]
                 if "liveNode" in m["generations"]}
        if len(nodes) > 1:
            offenders.append((r["key"], sorted(nodes)))
    assert not offenders, f"{len(offenders)} abilities merge distinct live nodes: {offenders[:5]}"
    assert summary["abilitiesWithSeveralLiveNodeIds"] == 0

    # NON-VACUITY: the gate has to be doing work, or the assertion above is free.
    gate = META["liveNodeVariantGate"]
    assert gate["splitNameGroups"] > 20, gate["splitNameGroups"]
    assert gate["variantRecords"] >= 2 * gate["splitNameGroups"], gate
    assert gate["splitAcrossTabs"] > 0, gate
    # and the proven three, each split into its own record with its own live node
    for key, live_ids in (("c12:savage", (560441, 705242)),
                          ("c19:paladintraining", (504808, 520009)),
                          ("c31:stoneskin", (706162, 806583))):
        recs = [r for r in RECORDS if r["normName"] == key.split(":")[1]
                and r["key"].startswith(key) and r["live"]]
        assert len(recs) >= 2, (key, [r["key"] for r in recs])
        owners = {sid: r for r in recs for sid in r["liveIds"]}
        for sid in live_ids:
            assert sid in owners, (key, sid, sorted(owners))
        assert owners[live_ids[0]]["key"] != owners[live_ids[1]]["key"], key
        # siblings stay one hop apart
        for r in recs:
            sibs = {l["key"] for l in r["linkedKeys"]
                    if l["relation"] == "liveNodeVariant"}
            assert sibs, (r["key"], r["linkedKeys"])


def test_split_variants_are_keyed_and_evidenced():
    for r in RECORDS:
        if not r["liveNodeVariant"]:
            continue
        assert r["key"] == f"c{r['classId']}:{r['normName']}#{r['liveNodeVariant']}"
        assert r["liveIds"] and str(min(r["liveIds"])) == r["liveNodeVariant"], r["key"]
        assert r["liveNodeVariantOf"]["variantKeys"], r["key"]
    # a bare key on a split name holds no live node at all - it can never be
    # mistaken for one of the variants
    for r in RECORDS:
        if r["liveNodeVariantOf"] and not r["liveNodeVariant"]:
            assert not r["liveIds"] and not r["live"], r["key"]


def test_normalization_rule_reproduces_the_emitted_keys():
    for r in RECORDS:
        base = f"c{r['classId']}:{r['normName']}"
        assert r["key"] == (f"{base}#{r['liveNodeVariant']}"
                            if r["liveNodeVariant"] else base)
        for m in r["members"]:
            if m["name"] and m["generation"] != "rankChain":
                # a member's own name normalizes to the group key unless it was
                # admitted namelessly along a chain
                assert build_abilities.norm_name(m["name"]) == r["normName"] or \
                    "rankChain" in m["generations"], (r["key"], m["id"], m["name"])


def test_no_source_is_joined_by_bare_id_containment():
    # every membership must carry evidence naming the row that produced it
    for r in RECORDS:
        for m in r["members"]:
            assert m["generations"], (r["key"], m["id"])
            for g in m["generations"]:
                assert m["evidence"].get(g), (r["key"], m["id"], g)


def test_density_is_measured_not_asserted():
    d = META["idDensity"]
    assert d["baseSpellRows"] > 0 and d["touchedBlocks"] > 0
    assert 0 < d["meanDensityInTouchedBlocks"] < 1
    assert d["maxDensityInTouchedBlocks"] >= d["meanDensityInTouchedBlocks"]


def test_base_spell_variant_not_the_realm_overlay():
    assert build_abilities.BASE_SPELL_VARIANT in META["sources"]["names"]
    assert "area-52" in META["sources"]["names"]


def test_live_seed_drift_is_measured_from_committed_bytes():
    """`live` straddles two clocks - the client snapshot and an out-of-band web
    capture - and the gap has to be a number in the data, not a caveat in prose."""
    d = META["liveSeedDrift"]
    assert d["capture"]["capturedUtc"] and d["capture"]["sha256"]
    assert d["clientSnapshotNewestArchiveUtc"]
    assert isinstance(d["captureMinusSnapshotDays"], float)
    assert d == coa_live.seed_drift(), "seed_drift is not reproducible"


def test_shards_stay_under_the_line_cap():
    for f in sorted(OUT.glob("*.json")):
        lines = f.read_text(encoding="utf-8").count("\n") + 1
        assert lines <= MAX_LINES, (f.name, lines)


def test_index_and_residual_agree_with_the_summary():
    assert INDEX["abilityCount"] == summary["abilities"] == len(RECORDS)
    res = json.loads((OUT / "_residual-index.json").read_text(encoding="utf-8"))
    total = 0
    for name in res["files"]:
        recs = json.loads((OUT / name).read_text(encoding="utf-8"))["residual"]
        total += len(recs)
        for r in recs:
            assert r["spellId"] not in BY_ID, r
            assert r["sources"] and r["reasons"], r
    assert total == res["totalUnjoinedIds"] == summary["unjoinedResidualIds"]


if __name__ == "__main__":
    fails = []
    for name, fn in sorted(globals().items()):
        if name.startswith("test_") and callable(fn):
            try:
                fn()
                print("PASS", name)
            except AssertionError as e:
                fails.append((name, e))
                print("FAIL", name, e)
    print(json.dumps(summary, indent=1, sort_keys=True))
    sys.exit(1 if fails else 0)
