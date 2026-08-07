"""Base vs. realm-overlay Spell.dbc diff (task W4-5): coa-sim-handoff/
DATAMINE-REQUEST.md Sec 3 ("THE BIG UNRESOLVED ONE - we may be reading the wrong
realm's data") + Sec 13 item 7's prep half. Sec 3 measured area-52's overlay
against the base client chain and found the two disagree on 1,178/6,038 = 19.51%
of the CoA class set's shared spell rows - not just cosmetic text, 409 rows
disagree on raw damage numbers (effectBasePoints1). This module is the reusable
tool that reproduces that measurement (run against area-52 today, "ready for
rexxar" once a Vol'jin/Rexxar realm capture exists on this machine - Sec 13 item 7
proper, out of THIS task's scope per the brief).

CLI: `python -m tools.diff_realm_overlay <realm>` - realm must already be
extracted under work/dbc/ (base) and work/realms/<realm>/dbc/ (overlay); this
module does not extract anything itself (run tools.build_dataset or
tools.build_realms.build() first if work/realms/<realm>/dbc/Spell.dbc is missing).

Scope: "shared CoA rows" = ids in build_spells._coa_class_spell_ids() (the same
6,436-id CoA class-spell universe task W4-3 defined) present in BOTH the base
client's Spell.dbc AND the realm's own Spell.dbc - matching Sec 3's own
denominator exactly (base resolves 6,038/6,436; the overlay is a superset that
resolves all 6,436, so the intersection is base's resolved set). Per-column diff
counts are computed over every named TABLE_MAPS["Spell"] column (not just the
doc's cited top few) so a consumer can see the full shape, not just the
headline. "Damage-number disagreement" is specifically `effectBasePoints1` (f80,
the doc's own "409 rows disagree on raw damage numbers" citation - re-verified
against its own table there, same number as the f80 column-diff count, not a
separate metric). overlay-only/base-only counts are over the FULL spell id
space (not scoped to the CoA set), matching Sec 3's own 209,125/238,939/
31,498/1,684 figures.

Amendment D (single-writer ownership): this module writes exactly one new file,
data/realms/<realm>/overlay_diff.json - tools/build_realms.py remains the sole
writer of every OTHER path under data/realms/<realm>/ (index.json/_meta.json) and
all of raw/realms/<realm>/. Deliberately a separate, standalone CLI tool rather
than folded into build_realms.py's build() - the brief frames this as evidence
tooling to be run on demand against whichever realm was just captured, not a
step every base pipeline run needs (a new realm's overlay_diff.json is a REAL-WORK
follow-up decision - "which side is authoritative for the 1,178 disputed rows" -
not something to auto-regenerate silently on every rebuild)."""
import argparse, json

from tools import config, dbc, build_spells, sharding

# [Task W4-5] Sec 3's own cited area-52 figures (re-derivation target, not a copied
# assertion - this build's own snapshot has patched since the doc was written, so
# some drift is expected and reported, not hidden). +/-10% tolerance per the brief.
DOC_FIGURES = {
    "differingShared": 1178,        # of 6,038 shared CoA rows
    "descriptionDiff": 515,         # f170 description_enUS
    "bp1Diff": 409,                 # f80 effectBasePoints1 - "damage numbers"
    "nameChanges": 51,              # name_enUS literal changes
}
TOLERANCE = 0.10


def _spell_rows(dbc_dir=None):
    return {r["id"]: r for r in dbc.iter_named("Spell", dbc_dir=dbc_dir)}


def _within_tolerance(measured, doc, tolerance=TOLERANCE):
    return abs(measured - doc) <= tolerance * doc


def diff_realm(realm: str) -> dict:
    base_dir = config.WORK_DBC_DIR
    overlay_dir = config.WORK_REALMS_DIR / realm / "dbc"
    assert (overlay_dir / "Spell.dbc").is_file(), (
        f"realm {realm!r}: no extracted Spell.dbc at {overlay_dir} - run "
        "tools.build_realms.build() (or tools.build_dataset) first")

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

    doc_comparison = {
        "differingShared": {"doc": DOC_FIGURES["differingShared"], "measured": differing_shared_count,
                             "withinTolerance": _within_tolerance(differing_shared_count, DOC_FIGURES["differingShared"])},
        "descriptionDiff": {"doc": DOC_FIGURES["descriptionDiff"],
                             "measured": diff_counts.get("description_enUS", 0),
                             "withinTolerance": _within_tolerance(diff_counts.get("description_enUS", 0), DOC_FIGURES["descriptionDiff"])},
        "bp1Diff": {"doc": DOC_FIGURES["bp1Diff"], "measured": bp1_diff,
                    "withinTolerance": _within_tolerance(bp1_diff, DOC_FIGURES["bp1Diff"])},
        "nameChanges": {"doc": DOC_FIGURES["nameChanges"], "measured": len(name_changes),
                         "withinTolerance": _within_tolerance(len(name_changes), DOC_FIGURES["nameChanges"])},
    }

    return {
        "realm": realm,
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
        "docComparison": doc_comparison,
    }


def build(realm: str) -> dict:
    result = diff_realm(realm)
    out_dir = config.DATA_REALMS_DIR / realm
    out_dir.mkdir(parents=True, exist_ok=True)
    (out_dir / "overlay_diff.json").write_text(sharding.dump_manifest(result), encoding="utf-8", newline="\n")
    return result


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("realm", help="realm dir name under Data\\ (e.g. area-52)")
    args = ap.parse_args()
    result = build(args.realm)
    print(f"realm {args.realm}: {result['differingSharedCount']}/{result['sharedCount']} "
          f"shared CoA rows differ ({result['differingSharedPct']:.2%})")
    for label, cmp in result["docComparison"].items():
        flag = "OK" if cmp["withinTolerance"] else "DRIFT"
        print(f"  {label}: doc={cmp['doc']} measured={cmp['measured']} [{flag}]")
    print(f"data/realms/{args.realm}/overlay_diff.json written")


if __name__ == "__main__":
    main()
