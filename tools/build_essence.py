"""Per-class Ability/Talent Essence curves (task W4-5): CharacterAdvancementEssence
-> data/classes/essence.json. coa-sim-handoff/DATAMINE-REQUEST.md Sec 7 + Sec 13 item 9.

Amendment D (single-writer ownership): essence.json is class-ADJACENT data, not
class/spec/archetype metadata - build_classmeta.py's docstring states it owns
specs.json/archetypes.json ONLY (Amendment D), so this is deliberately a NEW,
separate module rather than a third file bolted onto that one's scope. This module
is the sole writer of data/classes/essence.json; it does not read or write
index.json/specs.json/archetypes.json. It only needs work/dbc (ChrClasses +
CharacterAdvancementEssence), not data/classes/ - can run any time after
config.ensure_dirs(), independent of build_classes/build_classmeta's own order.

Full mapping evidence (golden probes) lives in tools/dbc.py's TABLE_MAPS comment
for CharacterAdvancementEssence. Summary: f1=level (1-80), f2=classId (1-32,
ChrClasses.dbc id), f7=Ability Essence, f8=Talent Essence. f3-f6 are 4 unmapped
per-row flag columns; every class except Hero (classId 10) carries the identical
f7/f8 pair across all its flag combos at a given level, so the flags are inert for
32 of the CoA-relevant curve - Hero (unmatched to any CAD class, see
data/classes/index.json's unmatchedChrClasses) is the sole exception, carrying up
to 8 DIFFERENT f7/f8 pairs per level across its flag combos. This module always
selects the flags-(0,0,0,0) row as the canonical curve - present exactly once for
every (classId, level) pair (2,560/2,560 verified) - which is also the row that
reproduces every golden the source doc cites."""
import json

from tools import config, dbc

FLAG_FIELDS = (3, 4, 5, 6)          # unmapped CharacterAdvancementEssence columns


def _canonical_rows():
    """Raw (level, classId, ae, te) tuples for the flags-(0,0,0,0) row of every
    (classId, level) pair. Reads the DBC directly (not dbc.iter_named) because the
    flag columns are deliberately unmapped in TABLE_MAPS - same pattern as
    build_classmeta.py's ChrSpecs f63 raw parallel-pass read."""
    f = dbc.DBCFile(config.WORK_DBC_DIR / "CharacterAdvancementEssence.dbc")
    out = []
    for row in f.iter_rows():
        if all(row[i] == 0 for i in FLAG_FIELDS):
            out.append((dbc.u32(row[1]), dbc.u32(row[2]), dbc.u32(row[7]), dbc.u32(row[8])))
    return out


def build() -> dict:
    cdir = config.DATA_DIR / "classes"
    cdir.mkdir(parents=True, exist_ok=True)

    chr_names = {c["id"]: c["name_enUS"] for c in dbc.iter_named("ChrClasses")}

    rows = _canonical_rows()
    assert len(rows) == 2560, (
        f"expected exactly one flags-(0,0,0,0) row per (classId, level) pair "
        f"(32 classes x 80 levels = 2560), got {len(rows)} - canonical-row "
        f"selection rule needs re-deriving")

    by_class = {}
    for level, class_id, ae, te in rows:
        by_class.setdefault(class_id, {})[level] = (ae, te)

    assert set(by_class) == set(range(1, 33)), (
        "CharacterAdvancementEssence must cover exactly classId 1-32", sorted(by_class))

    def curve_group(class_id):
        if class_id == 10:
            return "hero"
        if 12 <= class_id <= 32:
            return "coaCustom"
        return "classlessBase"

    classes = []
    for class_id in sorted(by_class):
        levels = by_class[class_id]
        assert set(levels) == set(range(1, 81)), (
            f"classId {class_id}: expected levels 1-80 dense, got {sorted(levels)}")
        classes.append({
            "classId": class_id,
            "className": chr_names.get(class_id),
            "curveGroup": curve_group(class_id),
            "abilityEssence": [levels[lvl][0] for lvl in range(1, 81)],
            "talentEssence": [levels[lvl][1] for lvl in range(1, 81)],
        })

    # ---- goldens, re-derived directly from the rows just read (see tools/dbc.py's
    # TABLE_MAPS comment for the full writeup) ----
    by_id = {c["classId"]: c for c in classes}
    for cid in (1, 2, 3, 4, 5, 6, 7, 8, 9, 11):        # classless, excl. Hero
        c = by_id[cid]
        assert (c["abilityEssence"][59], c["talentEssence"][59]) == (60, 51), (cid, c)
    hero = by_id[10]
    assert (hero["abilityEssence"][59], hero["talentEssence"][59]) == (100, 51), hero
    coa_curves = {(tuple(by_id[cid]["abilityEssence"]), tuple(by_id[cid]["talentEssence"]))
                  for cid in range(12, 33)}
    assert len(coa_curves) == 1, "all 21 CoA-custom classes must share one AE/TE curve"
    coa_ae, coa_te = next(iter(coa_curves))
    assert (coa_ae[59], coa_te[59]) == (26, 25), (coa_ae[59], coa_te[59])
    assert (coa_ae[9], coa_te[9]) == (1, 0)      # L10
    assert (coa_ae[19], coa_te[19]) == (6, 5)    # L20
    assert (coa_ae[69], coa_te[69]) == (31, 30)  # L70
    assert (coa_ae[79], coa_te[79]) == (36, 35)  # L80

    payload = {
        "levels": list(range(1, 81)),
        "notes": (
            "abilityEssence/talentEssence are parallel arrays indexed by levels[i] "
            "(level 1..80). Each class's row is the CharacterAdvancementEssence.dbc "
            "flags-(0,0,0,0) variant - see tools/dbc.py's TABLE_MAPS comment. "
            "classId 10 (Hero, unmatched to any CAD class) carries up to 8 DIFFERENT "
            "AE/TE curves across its other flag-combo rows (e.g. level 60 also reads "
            "(100,71)/(60,25)/(44,51) under other combos) - not carried here, since "
            "the flag columns (f3-f6) have no proven semantics and Hero is not a "
            "playable CoA class in this snapshot."
        ),
        "classes": classes,
    }
    from tools import sharding
    (cdir / "essence.json").write_text(sharding.dump_manifest(payload), encoding="utf-8", newline="\n")

    return {
        "count": len(classes),
        "coaCustomCount": sum(1 for c in classes if c["curveGroup"] == "coaCustom"),
    }


if __name__ == "__main__":
    print(build())
