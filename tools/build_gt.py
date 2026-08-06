"""gt* combat-rating/regen tables (task W4-2: coa-sim-handoff/DATAMINE-REQUEST.md Sec 1.1
+ Sec 13 item 1) -> data/gt/.

Amendment D (single-writer ownership): build_gt.py is the SOLE writer under data/gt/ -
build() clears and rebuilds the whole directory itself.

Full layout-proof evidence (the class-major/rating-major index formulas, the 3
block-boundary "level-100-slot" checks, every reproduced golden with exact values) lives
in tools/dbc.py's TABLE_MAPS comment block for the gt* tables and in
.superpowers/sdd/task-w4-2-report.md. This module applies that proven index arithmetic
to turn the raw single-float-per-row DBCs into curated per-rating/per-class curves; the
gates below (build_combat_ratings/build_class_tables) re-check the same golden facts at
build time so a future client patch that silently changes the layout fails loudly instead
of shipping wrong data.

Three caveats carried into every consumer of this data (see _meta.json's "caveats" key,
DATAMINE-REQUEST.md Sec 1.1's own warnings):
  1. gtOCTClassCombatRatingScalar (1024x2) has a DIFFERENT shape from every other gt*
     table here and its layout is NOT covered by this task's proof - shipped raw +
     colinfo only (tools/dbc.py leaves it UNMAPPED), no curated curve output.
  2. "Client's copy - server may differ." These values are what the CLIENT uses for
     tooltips and the character sheet. A TrinityCore-family server loads its OWN gt* DBC
     set; if CoA's server ships different values, the client would display one number
     (e.g. 14.0%/point crit) while the server computes another. Mitigation (not
     performed by this pipeline): read a level-60 character's actual crit% at a known
     crit-rating value in-game and compare against this dataset's prediction.
  3. ARMOR_PENETRATION (gtCombatRatings rating index 24) does not match the published
     WotLK constant: this table gives 11.55 at level 80 where the canonical value is
     15.39 (4.20 vs the same canonical curve's expected ~5.6ish at level 60 - CoA's
     own level-60 figure is 4.20). Every other pinned rating matches published WotLK
     to 4dp, so this is a real behavioral difference, not a layout artifact -
     [INFERRED] an Ascension rebalance or a pre-3.3.3 WotLK revision.

And the level-100-slot trap (DATAMINE-REQUEST.md Sec 1.1's closing warning): every
100-level block's slot index 99 (the "level 100" position) actually holds the START of
the NEXT block's curve, not a real level-100 value - reverified fresh at 3 block
boundaries below. Every curated curve in this module's output is therefore levels 1-99
only (99 values, indices 0-98), never 100.
"""
import json, shutil

from tools import config, dbc, sharding

LEVELS = 99  # curated curve length - levels 1-99 only, level-100-slot trap (see module docstring)

# ---- gtCombatRatings: rating-major (idx = cr*100 + level-1). 16 of 32 rating slots
# pinned to a published name; see tools/dbc.py's TABLE_MAPS comment for the full
# per-index evidence (which slots share identical curves, why WEAPON_SKILL/EXPERTISE/
# BLOCK are named despite a thinner evidence tier than the 13 level-80-anchored ones,
# and why RESILIENCE was checked and explicitly NOT pinned).
CR_NAMES = {
    0: "WEAPON_SKILL", 1: "DEFENSE", 2: "DODGE", 3: "PARRY", 4: "BLOCK",
    5: "HIT_MELEE", 6: "HIT_RANGED", 7: "HIT_SPELL",
    8: "CRIT_MELEE", 9: "CRIT_RANGED", 10: "CRIT_SPELL",
    17: "HASTE_MELEE", 18: "HASTE_RANGED", 19: "HASTE_SPELL",
    23: "EXPERTISE", 24: "ARMOR_PENETRATION",
}
CR_SLOTS = 32

# published WotLK level-80 constants this task re-derived exactly (4dp) from a fresh
# 2026-08-06 extraction - DATAMINE-REQUEST.md Sec 1.1's "13/14 exact" golden
CR_L80_GOLDENS = {
    1: 4.9185, 2: 45.2502, 3: 45.2502, 5: 32.79, 6: 32.79, 7: 26.232,
    8: 45.906, 9: 45.906, 10: 45.906, 17: 32.79, 18: 32.79, 19: 32.79, 23: 8.1975,
}
# the 14th checked constant (the documented anomaly, not a layout failure - cr24's
# ROW IDENTITY is certain, only its VALUE diverges from the published figure)
ARMOR_PENETRATION_CR = 24
ARMOR_PENETRATION_L80_MEASURED = 11.55
ARMOR_PENETRATION_L80_PUBLISHED = 15.39
ARMOR_PENETRATION_L60_MEASURED = 4.20
# level-60-only anchors (no independent published lvl70/80 figure exists for either -
# see tools/dbc.py's comment for the evidence-tier distinction)
BLOCK_CR, BLOCK_L60_GOLDEN = 4, 5.00
WEAPON_SKILL_CR, WEAPON_SKILL_L60_GOLDEN = 0, 2.50

# ---- class-major tables: idx = (classId-1)*100 + level-1 (curves) or classId-1 (*Base) ----
CURVE_TABLES = {
    "meleeCrit": "gtChanceToMeleeCrit",
    "spellCrit": "gtChanceToSpellCrit",
    "regenMPPerSpt": "gtRegenMPPerSpt",
    "octRegenMP": "gtOCTRegenMP",
    "regenHPPerSpt": "gtRegenHPPerSpt",
    "octRegenHP": "gtOCTRegenHP",
}
BASE_TABLES = {
    "meleeCritBase": "gtChanceToMeleeCritBase",
    "spellCritBase": "gtChanceToSpellCritBase",
}

# DATAMINE-REQUEST.md Sec 1.1's CoA archetype-clone table, agi-per-1%-crit @60/@80
# (gtChanceToMeleeCrit) - reproduced exactly on this fresh extraction; the
# Warlock/Necromancer pair doubles as the brief's required spot check (bit-identical
# raw floats, not just rounded-equal).
MELEE_CRIT_GOLDENS_60_80 = {
    1: (19.88, 62.5), 6: (19.88, 62.5), 17: (19.88, 62.5), 18: (19.88, 62.5), 30: (19.88, 62.5),
    2: (19.65, 52.08), 25: (19.65, 52.08), 27: (19.65, 52.08),
    8: (22.62, 51.02), 16: (22.62, 51.02), 24: (22.62, 51.02),
    5: (21.93, 52.08), 22: (21.93, 52.08),
    9: (21.01, 50.51), 23: (21.01, 50.51),
    3: (33.22, 83.33), 15: (33.22, 83.33), 28: (33.22, 83.33),
    12: (26.83, 79.37),
    31: (18.71, 49.6),
}
WARLOCK_CID, NECROMANCER_CID = 9, 23

# gtChanceToSpellCrit: pure-physical classes read exactly 0 at every level; the
# remaining "vanilla-shaped" casters converge on the canonical WotLK constants
SPELL_CRIT_ZERO_CLASSES = {1, 4, 6, 12, 18}          # Warrior/Rogue/DeathKnight/Barbarian/Guardian
SPELL_CRIT_CANONICAL_CLASSES = {2, 3, 5, 7, 8, 9, 10}  # Paladin/Hunter/Priest/Shaman/Mage/Warlock/Hero
SPELL_CRIT_L70_GOLDEN, SPELL_CRIT_L80_GOLDEN = 80.00, 166.67


def _points_per_percent(raw: float) -> float:
    """Convert a gt table's raw 'fraction of 1%-crit granted per stat point' value into
    the brief's 'N points per 1%' figure. 0 (no scaling for this class/rating) stays 0."""
    return round(1.0 / raw / 100.0, 2) if raw else 0.0


def _load_curve_table(name: str) -> list:
    """Every value in the table, in raw row order (row i's DBC position IS its index -
    the layout proof tools/dbc.py documents is entirely about row position). Reads
    full float32 precision directly via dbc.f32 rather than dbc.iter_named/TABLE_MAPS'
    "f"-kind decode, which rounds to 6 DECIMAL PLACES - fine for the larger gtCombatRatings
    curve (values up to ~1174) but a real precision loss for gtChanceToMeleeCrit's
    ~0.0001-0.0009-magnitude values (2-4 significant figures left after 6dp rounding),
    enough to move a derived '1/value/100' points-per-percent golden outside a tight
    tolerance. Curve/value fields are re-rounded to 8dp only at JSON-write time below."""
    f = dbc.DBCFile(config.WORK_DBC_DIR / f"{name}.dbc")
    assert f.fields == 1, f"{name}: expected single-float column, got {f.fields} fields"
    return [dbc.f32(row[0]) for row in f.iter_rows()]


def _class_roster() -> dict:
    return {r["id"]: r["name_enUS"] for r in dbc.iter_named("ChrClasses")}


def build_combat_ratings() -> dict:
    vals = _load_curve_table("gtCombatRatings")
    assert len(vals) == CR_SLOTS * 100, f"gtCombatRatings: {len(vals)} != {CR_SLOTS * 100}"

    blocks = [vals[cr * 100:(cr + 1) * 100] for cr in range(CR_SLOTS)]

    # ---- level-100-slot trap: reverify at 3 block boundaries (fresh, not trusted from
    # the source doc) - slot 99 of block N must equal slot 0 of block N+1 exactly ----
    for a, b in ((0, 1), (1, 2), (15, 16)):
        assert blocks[a][99] == blocks[b][0], (
            f"level-100-slot trap broke at cr{a}->cr{b}: {blocks[a][99]} != {blocks[b][0]}")

    # ---- golden gate: 13/14 published level-80 constants exact to 4dp ----
    matched = 0
    for cr, expected in CR_L80_GOLDENS.items():
        got = round(blocks[cr][79], 4)
        assert abs(got - expected) < 1e-3, f"cr{cr} lvl80 {got} != published {expected}"
        matched += 1
    assert matched == 13, matched
    # the 14th (ARMOR_PENETRATION) is the documented anomaly - MUST differ, or the
    # anomaly finding itself has silently stopped reproducing
    arp_l80 = round(blocks[ARMOR_PENETRATION_CR][79], 4)
    arp_l60 = round(blocks[ARMOR_PENETRATION_CR][59], 4)
    assert abs(arp_l80 - ARMOR_PENETRATION_L80_MEASURED) < 1e-3, arp_l80
    assert abs(arp_l60 - ARMOR_PENETRATION_L60_MEASURED) < 1e-3, arp_l60
    assert abs(arp_l80 - ARMOR_PENETRATION_L80_PUBLISHED) > 1.0, (
        "ARMOR_PENETRATION now matches the published constant - anomaly may be resolved, "
        "re-check whether it should stay documented as a caveat")

    # ---- level-60-only anchors (BLOCK unique among all 32 slots; WEAPON_SKILL by the
    # cr0-is-always-weapon-skill convention - see tools/dbc.py for the full argument) ----
    assert abs(round(blocks[BLOCK_CR][59], 4) - BLOCK_L60_GOLDEN) < 1e-3
    assert abs(round(blocks[WEAPON_SKILL_CR][59], 4) - WEAPON_SKILL_L60_GOLDEN) < 1e-3
    # BLOCK's curve must be unique (the evidentiary basis for naming it from a
    # level-60-only match) - no other slot may share it
    assert sum(1 for c in blocks if c[59] == blocks[BLOCK_CR][59]) == 1, "BLOCK curve not unique"

    ratings = []
    for cr in range(CR_SLOTS):
        ratings.append({
            "index": cr,
            "name": CR_NAMES.get(cr, f"cr{cr}"),
            "curve": [round(v, 8) for v in blocks[cr][:LEVELS]],
        })
    assert all(len(r["curve"]) == LEVELS for r in ratings)
    return {"ratings": ratings}


def build_class_tables() -> dict:
    classes = _class_roster()
    assert len(classes) == 32, len(classes)

    curves = {}
    for out_key, table in CURVE_TABLES.items():
        vals = _load_curve_table(table)
        assert len(vals) == 32 * 100, f"{table}: {len(vals)} != 3200"
        recs = []
        for cid in range(1, 33):
            block = vals[(cid - 1) * 100:cid * 100]
            recs.append({
                "classId": cid, "className": classes[cid],
                "curve": [round(v, 8) for v in block[:LEVELS]],
            })
        assert all(len(r["curve"]) == LEVELS for r in recs)
        curves[out_key] = recs

    bases = {}
    for out_key, table in BASE_TABLES.items():
        vals = _load_curve_table(table)
        assert len(vals) == 32, f"{table}: {len(vals)} != 32 (the brief's *Base = 32 rows golden)"
        bases[out_key] = [
            {"classId": cid, "className": classes[cid], "value": round(vals[cid - 1], 8)}
            for cid in range(1, 33)
        ]

    # ---- golden gate: gtChanceToMeleeCrit archetype-clone table, agi-per-1%-crit @60/@80 ----
    melee_crit_by_class = {r["classId"]: r["curve"] for r in curves["meleeCrit"]}
    for cid, (g60, g80) in MELEE_CRIT_GOLDENS_60_80.items():
        curve = melee_crit_by_class[cid]
        got60 = _points_per_percent(curve[59])   # curve index 59 = level 60
        got80 = _points_per_percent(curve[79])   # note: curve is levels 1-99, index 79 = level 80
        assert abs(got60 - g60) < 0.01, (cid, "lvl60", got60, g60)
        assert abs(got80 - g80) < 0.01, (cid, "lvl80", got80, g80)
    # the brief's required spot check: Necromancer's melee-crit column == Warlock's,
    # bit-identical raw floats (not just rounded-equal) at every curated level
    warlock_raw = _load_curve_table("gtChanceToMeleeCrit")[(WARLOCK_CID - 1) * 100:WARLOCK_CID * 100]
    necro_raw = _load_curve_table("gtChanceToMeleeCrit")[(NECROMANCER_CID - 1) * 100:NECROMANCER_CID * 100]
    assert warlock_raw == necro_raw, "Necromancer/Warlock melee-crit curves are not bit-identical"

    # ---- golden gate: gtChanceToSpellCrit - pure-physical zero + canonical convergence ----
    spell_crit_by_class = {r["classId"]: r["curve"] for r in curves["spellCrit"]}
    for cid in SPELL_CRIT_ZERO_CLASSES:
        assert all(v == 0.0 for v in spell_crit_by_class[cid]), (cid, "expected all-zero")
    for cid in SPELL_CRIT_CANONICAL_CLASSES:
        curve = spell_crit_by_class[cid]
        got70 = _points_per_percent(curve[69])
        got80 = _points_per_percent(curve[79])
        assert abs(got70 - SPELL_CRIT_L70_GOLDEN) < 0.01, (cid, "lvl70", got70)
        assert abs(got80 - SPELL_CRIT_L80_GOLDEN) < 0.01, (cid, "lvl80", got80)

    return {"curves": curves, "bases": bases}


def build_level60_slice(cr_doc: dict, class_doc: dict) -> dict:
    """Convenience slice: every curve's level-60 value (curve index 59), plus the
    *Base tables' single flat value (no level dimension - included as-is for parity)."""
    combat_ratings = [
        {"index": r["index"], "name": r["name"], "value": r["curve"][59]}
        for r in cr_doc["ratings"]
    ]
    class_curves = {}
    for out_key, recs in class_doc["curves"].items():
        class_curves[out_key] = [
            {"classId": r["classId"], "className": r["className"], "value": r["curve"][59]}
            for r in recs
        ]
    for out_key, recs in class_doc["bases"].items():
        class_curves[out_key] = [
            {"classId": r["classId"], "className": r["className"], "value": r["value"]}
            for r in recs
        ]
    return {"combatRatings": combat_ratings, "classChanceCurves": class_curves}


def build() -> dict:
    config.ensure_dirs()
    gdir = config.DATA_DIR / "gt"
    if gdir.exists():
        shutil.rmtree(gdir)          # sole writer (Amendment D) - safe to own outright
    gdir.mkdir(parents=True)

    cr_doc = build_combat_ratings()
    class_doc = build_class_tables()
    level60 = build_level60_slice(cr_doc, class_doc)

    (gdir / "combatRatings.json").write_text(
        sharding.dump_manifest({"ratings": cr_doc["ratings"]}), encoding="utf-8")

    class_chance_payload = {}
    class_chance_payload.update(class_doc["curves"])
    class_chance_payload.update(class_doc["bases"])
    (gdir / "classChanceCurves.json").write_text(
        sharding.dump_manifest(class_chance_payload), encoding="utf-8")

    (gdir / "level60.json").write_text(sharding.dump_manifest(level60), encoding="utf-8")

    counts = {
        "gtCombatRatings": len(_load_curve_table("gtCombatRatings")),
        "gtOCTClassCombatRatingScalar": dbc.DBCFile(
            config.WORK_DBC_DIR / "gtOCTClassCombatRatingScalar.dbc").records,
        "gtNPCManaCostScaler": dbc.DBCFile(
            config.WORK_DBC_DIR / "gtNPCManaCostScaler.dbc").records,
    }
    for out_key, table in {**CURVE_TABLES, **BASE_TABLES}.items():
        counts[table] = len(_load_curve_table(table))

    meta = {
        "counts": counts,
        "ratingNames": {str(r["index"]): r["name"] for r in cr_doc["ratings"]},
        "provenColumns": (
            "gtCombatRatings idx=cr*100+(level-1) (rating-major, 32 rating slots x 100 "
            "levels); gtChanceToMeleeCrit/gtChanceToSpellCrit/gtRegenMPPerSpt/gtOCTRegenMP/"
            "gtRegenHPPerSpt/gtOCTRegenHP idx=(classId-1)*100+(level-1) (class-major, "
            "classId 1-32 = ChrClasses.dbc id); gtChanceToMeleeCritBase/"
            "gtChanceToSpellCritBase idx=classId-1 (32 rows, no level dimension) - full "
            "evidence in tools/dbc.py's TABLE_MAPS comment and "
            ".superpowers/sdd/task-w4-2-report.md"
        ),
        "goldensReproduced": {
            "level80CombatRatingConstants": "13/14 exact to 4dp on a fresh 2026-08-06 "
                "extraction (matches DATAMINE-REQUEST.md Sec 1.1); the 14th is the "
                "documented ARMOR_PENETRATION anomaly, not a match failure",
            "spellCritConversion": "166.67 int/1%@80 + 80.00 int/1%@70 on Paladin/Hunter/"
                "Priest/Shaman/Mage/Warlock/Hero; Warrior/Rogue/DeathKnight/Barbarian/"
                "Guardian read exactly 0 at every level",
            "meleeCritConversion": "83.33/62.50/52.08 agi/1%@80 (Hunter/Warrior/Paladin "
                "archetype families) + the full CoA archetype-clone table (KnightOfXoroth/"
                "Guardian/Reaper=Warrior, Cultist/SunCleric=Paladin, Pyromancer/"
                "Stormbringer=Mage, Chronomancer=Priest, Necromancer=Warlock, "
                "WitchHunter/Tinker=Hunter) reproduced exactly",
            "baseTablesRowCount": "gtChanceToMeleeCritBase and gtChanceToSpellCritBase "
                "both have exactly 32 records (one per ChrClasses.dbc class)",
            "necromancerWarlockSpotCheck": "gtChanceToMeleeCrit raw float curves are "
                "bit-identical between classId 9 (Warlock) and classId 23 (Necromancer) "
                "at every one of the 99 curated levels",
        },
        "caveats": {
            "gtOCTClassCombatRatingScalar": (
                "1,024 records x 2 fields - a DIFFERENT shape from every other gt* table "
                "here, NOT covered by this task's class-major/rating-major proof. f0 "
                "decodes as an ascending-unique row id 1-1024 (row i's f0 == i+1), "
                "indistinguishable from either 'this table's own positional PK' or the "
                "brief's inferred TrinityCore (class-1)*32+cr+1 convention with the "
                "evidence available - both produce the identical 1..1024 sequence. Left "
                "UNMAPPED in tools/dbc.py (raw f0/f1 + colinfo.json evidence sidecar via "
                "dbc.dump_unmapped) - NO named curve output from this module. Needs its "
                "own golden (DATAMINE-REQUEST.md Sec 1.1 warning 1) before any future "
                "task curates it."
            ),
            "clientCopyMayDifferFromServer": (
                "These are the CLIENT's gt* values (used for tooltips and the character "
                "sheet). A TrinityCore-family server loads its OWN gt* DBC set - if CoA's "
                "server ships different files, the client could display 14.0%/point crit "
                "while the server computes something else. This pipeline cannot see "
                "server-side data (client DBCs only, see AGENT-GUIDE.md Honest limits); "
                "mitigation is an in-game check: read a level-60 character's actual crit% "
                "at a known crit-rating value and compare against gtCombatRatings' "
                "CRIT_MELEE/CRIT_RANGED/CRIT_SPELL prediction (14.0 rating per 1% at "
                "level 60 on this snapshot)."
            ),
            "armorPenetrationAnomaly": (
                f"gtCombatRatings rating index {ARMOR_PENETRATION_CR} (ARMOR_PENETRATION) "
                f"gives {ARMOR_PENETRATION_L80_MEASURED} at level 80 where the published "
                f"WotLK constant is {ARMOR_PENETRATION_L80_PUBLISHED} ("
                f"{ARMOR_PENETRATION_L60_MEASURED} at level 60). Every other pinned rating "
                "in this table matches its published constant to 4dp, so this is not a "
                "layout artifact - the row's identity (which cr slot is ARMOR_PENETRATION) "
                "is certain, only the number differs. [INFERRED] either an intentional "
                "Ascension rebalance or a pre-3.3.3 WotLK revision CoA's client build "
                "predates; unresolved, real behavioral difference if it holds at level 60."
            ),
            "level100SlotTrap": (
                "Every 100-level block in gtCombatRatings/gtChanceToMeleeCrit/"
                "gtChanceToSpellCrit/gtRegenMPPerSpt/gtOCTRegenMP/gtRegenHPPerSpt/"
                "gtOCTRegenHP's slot index 99 (displayed 'level 100') holds the START of "
                "the NEXT block's curve, not a real level-100 value - reverified at 3 "
                "fresh block boundaries in build_combat_ratings() (exact float equality, "
                "not approximate). Every curve this module emits therefore covers levels "
                "1-99 only (99 values), never a level-100 slot."
            ),
        },
        "unresolvedRatingIndices": {
            "cr14_resilience_check": (
                "DATAMINE-REQUEST.md Sec 1.1's level-60 table lists RESILIENCE=85.00, and "
                "cr14's level-60 value is exactly 85.0 - but cr14/15/16 form their own "
                "3-slot group (85.0/89.125/89.125 at level 60, converging identically by "
                "level 70) structurally consistent with CRIT_TAKEN_MELEE/RANGED/SPELL, not "
                "resilience, and no independent published level-70/80 anchor exists for "
                "RESILIENCE to disambiguate a single-level coincidence from a real "
                "identity - the same class of false positive this repo's own AGENT-GUIDE.md "
                "warns about repeatedly. Checked and explicitly NOT pinned; cr14 stays "
                "unnamed in ratingNames."
            ),
            "cr11_12_13_hitTaken": "10.0/10.0/8.0 @60, identical to HIT_MELEE/RANGED/SPELL "
                "- structurally HIT_TAKEN_MELEE/RANGED/SPELL but not independently named "
                "(no published anchor for the 'taken' ratings).",
            "cr20_21_22_weaponSkillSub": "bit-identical to cr0 WEAPON_SKILL and cr23 "
                "EXPERTISE - presumably WEAPON_SKILL_MAINHAND/OFFHAND/RANGED but no value "
                "distinguishes them from each other, left unnamed.",
            "cr25_31": "nonzero-but-unpublished (cr25) or all-zero (cr26-31) curves, no "
                "independent evidence of any kind - left unnamed.",
        },
    }
    (gdir / "_meta.json").write_text(
        json.dumps(meta, ensure_ascii=False, indent=1, sort_keys=True), encoding="utf-8")

    return {"combatRatings": len(cr_doc["ratings"]),
            "classTables": {k: len(v) for k, v in class_chance_payload.items()},
            "counts": counts}


if __name__ == "__main__":
    print(build())
