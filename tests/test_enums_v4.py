"""Task W4-1 gate: enum truth pass (coa-sim-handoff/DATAMINE-REQUEST.md Sec 1.5 +
analysis/enum-triage.md). Every fix and addition below was independently re-decoded
against work/dbc/Spell.dbc BASE by this task - see
.superpowers/sdd/task-w4-1-report.md for the full per-golden log. This file
re-verifies them fresh at test time (not trusted from generation time): the 4 repo
bug fixes, the canonical/COA_ lookup order, a bulk sweep of every goldenSpells entry
in enums335.ENUM_EVIDENCE, exact-value spot checks on a sample of additions, the two
statistical claims (EFF165/EFF187 miscValue validity rates), and that a rebuilt
data/spells layer actually surfaces the renamed auras/effects."""
import json, sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from tools import config, dbc, enums335, build_spells

SPELLS = {r["id"]: r for r in dbc.iter_named("Spell")}       # live BASE Spell.dbc
AURA_APPLYING = {6, 27, 35, 65, 119, 128, 129, 143}           # trap 1


def carries_effect(sid, eid):
    r = SPELLS.get(sid)
    return bool(r) and any(r[f"effect{slot}"] == eid for slot in (1, 2, 3))


def carries_aura(sid, aid):
    r = SPELLS.get(sid)
    if not r:
        return False
    return any(r[f"effectAura{slot}"] == aid and r[f"effect{slot}"] in AURA_APPLYING
               for slot in (1, 2, 3))


# ---- the 4 repo bug fixes (2 real mis-maps, 2 cosmetic) ----
assert enums335.effect_name(110) == "DESTROY_ALL_TOTEMS"       # was "DISPEL_MECHANIC"
assert enums335.effect_name(108) == "DISPEL_MECHANIC"          # was absent
assert enums335.effect_name(140) == "FORCE_CAST"                # was absent
assert enums335.effect_name(142) == "TRIGGER_SPELL_WITH_VALUE"  # was "FORCE_CAST"
assert enums335.aura_name(52) == "MOD_WEAPON_CRIT_PERCENT"      # was "MOD_CRIT_PERCENT"
assert enums335.aura_name(200) == "MOD_XP_PCT"                  # was "MOD_KILL_XP_PCT"

# bug-fix goldens, decoded fresh against live BASE (not just "id present somewhere")
tr, dt = SPELLS[36936], SPELLS[16529]        # Totemic Recall, Destroy Totems (PT)
assert tr["effect1"] == 110 and dt["effect1"] == 110
dazed, tremor, hex_ = SPELLS[1604], SPELLS[8146], SPELLS[11641]
assert any(dazed[f"effect{s}"] == 108 for s in (1, 2, 3))
assert all(tremor[f"effect{s}"] == 108 for s in (1, 2, 3))
assert any(hex_[f"effect{s}"] == 108 for s in (1, 2, 3))
pom = SPELLS[33076]                          # Prayer of Mending
assert pom["effect1"] == 142 and pom["effectTriggerSpell1"] == 41635
portal = SPELLS[17607]                       # Portal Effect: Ironforge
assert portal["effect1"] == 140 and portal["effectTriggerSpell1"] == 44089

# ---- lookup order: canonical -> COA_ overlay -> numeric fallback ----
assert enums335.effect_name(165) == "COA_MODIFY_COOLDOWN"        # COA_ overlay hit
assert enums335.aura_name(344) == "COA_MOD_ATTACK_POWER_FLAT"    # COA_ overlay hit
assert enums335.effect_name(168) == "EFFECT_168"                 # explicit do-not-guess
assert 168 not in enums335.COA_EFFECT_NAMES
assert enums335.effect_name(99999) == "EFFECT_99999"             # numeric fallback
assert enums335.aura_name(99999) == "AURA_99999"                 # numeric fallback
# canonical and COA_ namespaces must stay disjoint (a custom id can never masquerade
# as canonical, and effect_name/aura_name must never have to arbitrate a collision)
assert not (set(enums335.EFFECT_NAMES) & set(enums335.COA_EFFECT_NAMES))
assert not (set(enums335.AURA_NAMES) & set(enums335.COA_AURA_NAMES))

# ---- every id actually wired into a name table must have a documented golden in
# ENUM_EVIDENCE - no name reaches enums335.py without a transcribed, checkable golden
W4_1_EFFECT_ADDITIONS = {108, 114, 128, 129, 140, 141, 148, 149, 164}
# [W4-1 review fix] aura 71 MOD_SPELL_CRIT_CHANCE_SCHOOL: golden 300240 Curse of the
# Lich was hiding in enum-triage.md's bucket-B prose (the EFF190 discussion), not its
# own table - this task's Part-3 verification pass had already decoded aura=71
# misc=16 on that spell but missed wiring the name itself. Caught on review.
W4_1_AURA_ADDITIONS = {71, 112, 118, 149, 163, 166, 174, 175, 192, 212, 216, 220, 227,
                       232, 240, 268, 271, 280, 285, 286, 290, 303, 308}
for eid in W4_1_EFFECT_ADDITIONS:
    ev = enums335.ENUM_EVIDENCE["effects"].get(eid)
    assert ev and ev["goldenSpells"] and ev["confidence"] == "verified", eid
for aid in W4_1_AURA_ADDITIONS:
    ev = enums335.ENUM_EVIDENCE["auras"].get(aid)
    assert ev and ev["goldenSpells"] and ev["confidence"] == "verified", aid
for eid in enums335.COA_EFFECT_NAMES:
    ev = enums335.ENUM_EVIDENCE["effects"].get(eid)
    assert ev and ev["goldenSpells"] and ev["confidence"] == "verified", eid
for aid in enums335.COA_AURA_NAMES:
    ev = enums335.ENUM_EVIDENCE["auras"].get(aid)
    assert ev and ev["goldenSpells"] and ev["confidence"] == "verified", aid

# ---- bulk-verify: EVERY goldenSpells entry in the evidence sidecar's source table
# (enums335.ENUM_EVIDENCE) actually carries that effect/aura id in live BASE
# Spell.dbc, re-decoded fresh here - not trusted from when the table was written ----
checked = 0
for eid, ev in enums335.ENUM_EVIDENCE["effects"].items():
    if not ev["goldenSpells"]:
        continue
    assert any(carries_effect(sid, eid) for sid in ev["goldenSpells"]), \
        f"effect {eid} ({ev['name']}): none of {ev['goldenSpells']} carry effect={eid}"
    checked += 1
for aid, ev in enums335.ENUM_EVIDENCE["auras"].items():
    if not ev["goldenSpells"]:
        continue
    assert any(carries_aura(sid, aid) for sid in ev["goldenSpells"]), \
        f"aura {aid} ({ev['name']}): none of {ev['goldenSpells']} carry aura={aid} " \
        f"on an aura-applying effect slot"
    checked += 1
assert checked >= 30, f"expected >=30 golden-backed evidence entries, found {checked}"

# ---- exact-value spot checks (numeric precision, not just id presence - catches a
# transcription error that happens to land in the right bucket) ----
blink_cdr = SPELLS[270151]                   # "Blink CDR"
assert blink_cdr["effect1"] == 165
assert blink_cdr["effectMiscValue1"] == 1953  # = Blink
assert blink_cdr["effectBasePoints1"] + 1 == -10000   # value = bp+1 = deltaMs

orbs = SPELLS[92709]                         # Summon Arcane Orbs
delays = sorted(orbs[f"effectBasePoints{s}"] + 1 for s in (1, 2, 3)
                 if orbs[f"effect{s}"] == 183)
assert delays == [2001, 4001, 6001]
assert len({orbs[f"effectTriggerSpell{s}"] for s in (1, 2, 3)
            if orbs[f"effect{s}"] == 183}) == 1     # same trigger spell, staggered

dread = SPELLS[300557]                       # Dread
assert dread["effectAura1"] == 354
assert dread["effectBasePoints1"] + 1 == 25
assert dread["effectTriggerSpell1"] == 300558

bloodlust = SPELLS[2825]
assert bloodlust["effectAura3"] == 192 and bloodlust["effectBasePoints3"] + 1 == 30

sword_spec = SPELLS[12814]
assert sword_spec["effectAura2"] == 333 and sword_spec["effectBasePoints2"] + 1 == 4

# [W4-1 review fix] aura 71 MOD_SPELL_CRIT_CHANCE_SCHOOL - golden 300240 Curse of the
# Lich, aura=71 on slots 2 and 3, misc=16 (Frost school mask)
curse_of_lich = SPELLS[300240]
assert curse_of_lich["effectAura2"] == 71 and curse_of_lich["effectMiscValue2"] == 16
assert curse_of_lich["effectAura3"] == 71 and curse_of_lich["effectMiscValue3"] == 16

# ---- the two statistical claims from DATAMINE-REQUEST.md Sec 1.5, re-derived
# client-wide over every BASE Spell row (not CoA-scoped) - pinned exactly ----
#
# CLIENT-DRIFT RE-PIN POINT. These four counts are measured over the LIVE base
# Spell.dbc, so a client patch moves them and this file fails without anything
# in the repo having changed. It belongs to the same documented re-pin set as
# tests/test_v5_tables.py, tests/test_sharding.py and tests/test_raw_layers.py,
# and it was missing from that list - the list lived only in a handoff document,
# so the drift set was not discoverable from the code it describes. It is named
# here as well as there for that reason.
#
# Observed 2026-08-07 after the 14:01 client patch: len(vals165) is 1553, not the
# pinned 1552. Deliberately NOT re-pinned in the audit-correction commit: these
# numbers read work/dbc, raw/tables is a patch behind it, and re-pinning one
# against the other would freeze an inconsistency. They get re-pinned together in
# the rebuild that regenerates raw/tables, which is where every other count in
# this repo is re-pinned.
charges_doc = json.loads((config.DATA_DIR / "spells" / "charges.json").read_text(encoding="utf-8"))
cat_ids = {c["id"] for c in charges_doc["categories"].values()}
vals165, vals187 = [], []
for r in SPELLS.values():
    for slot in (1, 2, 3):
        if r[f"effect{slot}"] == 165:
            vals165.append(r[f"effectMiscValue{slot}"])
        if r[f"effect{slot}"] == 187:
            vals187.append(r[f"effectMiscValue{slot}"])
assert len(vals165) == 1552, len(vals165)
assert sum(1 for v in vals165 if v in SPELLS) == 1501
assert len(vals187) == 118, len(vals187)
assert sum(1 for v in vals187 if v in cat_ids) == 110

# ---- rebuilt data/spells layer surfaces the renamed auras/effects (brief's gate:
# "a rebuilt spells layer shows the renamed auras") ----
# INTENTIONAL, NON-HERMETIC: this call rewrites the committed data/spells/ on disk
# (same pattern test_spells_v2.py/test_sharding.py already use) - required to prove
# the rebuilt-layer gate itself, not a side effect to avoid. Running this file
# leaves data/spells/ freshly regenerated from current work/dbc + enums335.py.
build_spells.build()
by_id = {}
want = {36936, 1160, 17364, 300240}
for r in build_spells.iter_all():
    if r["id"] in want:
        by_id[r["id"]] = r
assert set(by_id) == want
assert by_id[36936]["effects"][0]["effect"]["name"] == "DESTROY_ALL_TOTEMS"
assert by_id[1160]["effects"][0]["aura"]["name"] == "COA_MOD_ATTACK_POWER_FLAT"
assert by_id[17364]["effects"][-1]["aura"]["name"] == "MOD_DAMAGE_FROM_CASTER"
lich_auras = {e["slot"]: e["aura"]["name"] for e in by_id[300240]["effects"]}
assert lich_auras[2] == "MOD_SPELL_CRIT_CHANCE_SCHOOL" and lich_auras[3] == "MOD_SPELL_CRIT_CHANCE_SCHOOL"

# ---- _enum_evidence.json sidecar: schema, counts, trap-1/trap-2 discipline ----
sdir = config.DATA_DIR / "spells"
evidence = json.loads((sdir / "_enum_evidence.json").read_text(encoding="utf-8"))
assert set(evidence) == {"effects", "auras", "_note", "summary"}
assert evidence["summary"]["effectIds"] == 66
assert evidence["summary"]["auraIds"] == 158
# [W4-1 review fix] "classified" (has a sidecar entry) vs "wired" (actually resolves
# via effect_name()/aura_name()) are distinct counts - see build_spells.py's comment
assert evidence["summary"]["classifiedIds"] == 224 == \
    evidence["summary"]["effectIds"] + evidence["summary"]["auraIds"]
assert evidence["summary"]["wiredIds"] == 57          # 31 bucket-A + 25 bucket-B + aura 71
assert evidence["summary"]["sidecarNamedIds"] == 59    # wiredIds + 2 bucket-C [INFERRED]-only
assert evidence["summary"]["numericFallbackIds"] == 167
assert evidence["summary"]["classifiedIds"] - evidence["summary"]["wiredIds"] == \
    evidence["summary"]["numericFallbackIds"]
assert evidence["summary"]["byBucket"] == {"A": 173, "B": 46, "C": 4, "unknown": 1}
assert evidence["effects"]["165"]["name"] == "COA_MODIFY_COOLDOWN"
assert evidence["effects"]["165"]["confidence"] == "verified"
assert evidence["auras"]["71"]["name"] == "MOD_SPELL_CRIT_CHANCE_SCHOOL"
assert evidence["auras"]["71"]["confidence"] == "verified"
assert evidence["auras"]["71"]["goldenSpells"] == [300240]
# trap 2: filtered occurrences must never exceed raw (inert slots only ever subtract)
for e in list(evidence["effects"].values()) + list(evidence["auras"].values()):
    assert e["occurrences"]["filtered"] <= e["occurrences"]["raw"]
# EFFECT_168 stays unnamed in the sidecar too (do-not-guess), but is classified
assert evidence["effects"]["168"]["name"] is None
assert evidence["effects"]["168"]["bucket"] == "B"
# aura 164: known gap in the source triage (present, unnamed, not in any A/B/C list)
assert evidence["auras"]["164"]["bucket"] == "unknown"
# bucket C stays uncertain/inferred, never wired into a name table
for aid in (214, 222, 312, 313):
    assert str(aid) not in enums335.COA_AURA_NAMES
    assert evidence["auras"][str(aid)]["bucket"] == "C"

print(f"ALL PASS - {checked} evidence goldens bulk-verified, "
      f"{len(W4_1_EFFECT_ADDITIONS) + len(W4_1_AURA_ADDITIONS)} bucket-A + "
      f"{len(enums335.COA_EFFECT_NAMES) + len(enums335.COA_AURA_NAMES)} bucket-B "
      f"ids wired into enums335.py")
