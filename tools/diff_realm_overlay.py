"""Base vs. realm-overlay Spell.dbc diff.

Measures how far a realm's own Spell.dbc departs from the base client chain over
the CoA class spell set: how many shared rows disagree at all, which columns they
disagree in, and how many disagree on raw damage numbers (effectBasePoints1)
rather than on cosmetic text. It stays generic over realm names, but note
what has since been settled: **there is no CoA realm overlay to point it at.** The
product ships exactly one realm-scoped data set at a time, currently area-52's, and
that realm is Free-Pick - no Conquest of Azeroth realm has a client data directory
and no login creates one. So the row disagreement this measures is
Free-Pick-vs-base, NOT evidence about what a CoA character reads (CoA reads the
base chain). Rexxar and Vol'jin are also the same game mode, so there was never a
per-realm CoA split to diff in the first place. Kept generic because a future
product revision could ship a different overlay - see AGENT-GUIDE.md "Realm
overlays".

Scope: "shared CoA rows" = ids in build_spells._coa_class_spell_ids() (the same
6,436-id CoA class-spell universe that function defines) present in BOTH the base
client's Spell.dbc AND the realm's own Spell.dbc - the base resolves a subset of
the 6,436 and the overlay is a superset that resolves all of them, so the
intersection is base's resolved set. Per-column diff counts are computed over
every named TABLE_MAPS["Spell"] column, so a consumer can see the full shape and
not just the headline. "Damage-number disagreement" is specifically
`effectBasePoints1` (f80), read off the same column-diff table rather than
measured a second way. overlay-only/base-only counts are over the FULL spell id
space, not scoped to the CoA set.

Every figure this emits is re-derived from the two extracted Spell.dbc files on
each run. There are deliberately no pinned reproduction targets here: the client
patches roughly hourly, so a fixed expectation would encode one snapshot's
numbers as if they were invariants and fail on contact with the next patch.
tests/test_class_plumbing.py gates the STRUCTURE instead - which column ranks
top, which index effectBasePoints1 sits at, and the set arithmetic recomputed
independently from work/dbc.

Single-writer ownership: this module writes exactly one file,
data/realms/<realm>/overlay_diff.json - tools/build_realms.py remains the sole
writer of every OTHER path under data/realms/<realm>/ (index.json/_meta.json) and
all of raw/realms/<realm>/. It runs as a stage of datamine.py's pass, after the
realms stage, and has no __main__ of its own: see curate.ENTRY_POINT_RULE. It
used to be a standalone CLI, which meant a rebuild refreshed data/realms/<realm>/
while overlay_diff.json silently kept the previous run's numbers."""
import json

from tools import config, dbc, build_spells, sharding


def _spell_rows(dbc_dir=None):
    return {r["id"]: r for r in dbc.iter_named("Spell", dbc_dir=dbc_dir)}


def diff_realm(realm: str) -> dict:
    base_dir = config.WORK_DBC_DIR
    overlay_dir = config.WORK_REALMS_DIR / realm / "dbc"
    assert (overlay_dir / "Spell.dbc").is_file(), (
        f"realm {realm!r}: no extracted Spell.dbc at {overlay_dir} - run "
        "tools.build_realms.build() (or datamine.py) first")

    base = _spell_rows(base_dir)
    overlay = _spell_rows(overlay_dir)

    coa_ids = build_spells._coa_class_spell_ids()
    shared_coa = sorted(i for i in coa_ids if i in base and i in overlay)
    assert shared_coa, f"realm {realm!r}: zero shared CoA ids - is the overlay Spell.dbc real content?"

    columns = [name for name, _, _ in dbc.TABLE_MAPS["Spell"]["columns"]]
    col_index = {name: idx for name, idx, _ in dbc.TABLE_MAPS["Spell"]["columns"]}

    diff_counts = {c: 0 for c in columns}
    differing_ids = []
    for sid in shared_coa:
        b, o = base[sid], overlay[sid]
        row_differs = False
        for c in columns:
            if b[c] != o[c]:
                diff_counts[c] += 1
                row_differs = True
        if row_differs:
            differing_ids.append(sid)

    n_shared = len(shared_coa)
    column_diffs = sorted(
        ({"field": c, "index": col_index[c], "diffCount": n,
          "pct": round(n / n_shared, 4)} for c, n in diff_counts.items() if n > 0),
        key=lambda r: (-r["diffCount"], r["field"]))

    name_changes = sorted((
        {"id": sid, "baseName": base[sid]["name_enUS"], "overlayName": overlay[sid]["name_enUS"]}
        for sid in shared_coa if base[sid]["name_enUS"] != overlay[sid]["name_enUS"]
    ), key=lambda r: r["id"])

    base_ids, overlay_ids = set(base), set(overlay)
    bp1_diff = diff_counts.get("effectBasePoints1", 0)
    differing_shared_count = len(differing_ids)

    return {
        "realm": realm,
        "_note": ("Every figure here is re-derived from the base and overlay "
                  "Spell.dbc on each run; none is a pinned expectation. The "
                  "client patches often, so these move between builds by "
                  "design - compare shapes, not literals."),
        "coaIdSetSize": len(coa_ids),
        "sharedCount": n_shared,
        "differingSharedCount": differing_shared_count,
        "differingSharedPct": round(differing_shared_count / n_shared, 4),
        "damageNumberDisagreementCount": bp1_diff,
        "nameChangeCount": len(name_changes),
        "nameChanges": name_changes,
        "columnDiffs": column_diffs,
        "totalBaseSpellCount": len(base_ids),
        "totalOverlaySpellCount": len(overlay_ids),
        "overlayOnlySpellCount": len(overlay_ids - base_ids),
        "baseOnlySpellCount": len(base_ids - overlay_ids),
    }


def build(realms) -> dict:
    """Write data/realms/<realm>/overlay_diff.json for each realm. Called by
    curate.py after the realms stage, which owns the rest of that directory."""
    if isinstance(realms, str):
        realms = [realms]
    out = {}
    for realm in sorted(realms):
        result = diff_realm(realm)
        out_dir = config.DATA_REALMS_DIR / realm
        out_dir.mkdir(parents=True, exist_ok=True)
        (out_dir / "overlay_diff.json").write_text(
            sharding.dump_manifest(result), encoding="utf-8", newline="\n")
        out[realm] = {"shared": result["sharedCount"],
                      "differing": result["differingSharedCount"],
                      "damageNumberDisagreements": result["damageNumberDisagreementCount"],
                      "nameChanges": result["nameChangeCount"]}
    return out
