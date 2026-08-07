"""Realm-overlay raw layer + curated evidence index (task V3-2).

raw/realms/<realm>/dbc/: for every table tools/extract_realms.py pulled out of a
realm's own archives, if base tools/dbc.py TABLE_MAPS has an entry for that table
name AND the realm file's field_count matches it exactly -> mapped dump (named
headers, same column map + layout guard as the base client's raw/dbc/<Table>.csv.gz)
via dbc.dump_table(dbc_dir=..., out_dir=...); otherwise -> dump_unmapped-style raw
CSV + colinfo.json evidence sidecar via dbc.dump_unmapped(dbc_dir=..., out_dir=...).
No new column proofs are introduced here - this task reuses base TABLE_MAPS as-is.

data/realms/<realm>/index.json: per-table {records, fields, mapped, baseRecords,
delta} (baseRecords/delta are null only for tables with no base config.WANTED_DBCS
entry of the same name at all - CharacterAdvancement/SpellRank for area-52; note
"mapped" and "has a base WANTED_DBCS entry" are independent axes -
CharacterAdvancementEssence.dbc IS a base WANTED_DBCS table [task V2-3] but has no
TABLE_MAPS column proof on either side of the overlay, so it is unmapped yet still
carries a real baseRecords/delta) plus overlay evidence: missingRefResolution (per
data/spells/_missing_refs.json bucket, how many of those base-client "referenced but
unresolved" spell ids exist as an id in the REALM's own Spell.dbc - id-set membership
only, report-only, no threshold), spellIdRange, and newSpellCount (realm Spell.dbc
ids absent from the base client's Spell.dbc).

[Review fix pass] missingRefResolution needs data/spells/_missing_refs.json. If that
file is absent, build_realm RAISES by default rather than shipping an empty dict that
reads as a measured zero (the silent degrade task W4-13 observed under a concurrent
run). allow_missing_base=True instead writes missingRefResolution: null plus a
`degraded` key naming the cause - the standalone-run escape hatch, used by this
module's __main__ but never by build_dataset.py's orchestrator.

[Task V3-2 finding] CharacterAdvancement.dbc's WDBC header declares FieldCount 179,
but its record_size only fits 173 int32 fields (692/4) - the byte-accurate value
tools/dbc.py's DBCFile now derives .fields from (see its docstring). Surfaced here as
a `declaredFields` key on that table's entry only when the two actually disagree (no
null-noise on the 11 tables where they already match).

Scope (binding, per the V3-2 brief): extraction + raw layer + overlay evidence ONLY.
NO full realm spell/class curation in this task (no per-record enrichment of realm
spells, no realm-specific class/spec mapping) - see _meta.json's futureMilestone and
AGENT-GUIDE.md.

Amendment D (single-writer ownership): this module is the SOLE writer under
raw/realms/ and data/realms/ - nothing else in this repo touches these paths. It
does NOT touch raw/provenance.json (the base pipeline's top-level file, owned by
tools/build_dataset.py's orchestrator, which wires a "realms" stage calling
this module's build() - see task V3-3)."""
import json, shutil

from tools import config, dbc, extract_realms, layerstate

MIN_NEW_SPELL_COUNT = 10000     # brief's loose pin: realm spells measured ~= +30k vs base

# [Task W4-13] Stamped onto every data/realms/<realm>/_meta.json so a consumer reading
# only the dataset cannot mistake this layer for "the realm overlay" or for CoA data.
# Evidence: .superpowers/sdd/task-w4-13-realm-report.md; summary in AGENT-GUIDE.md's
# "Realm overlays" section.
DELIVERY_MECHANISM = (
    "area-52 is Free-Pick's overlay, NOT 'the realm overlay' - it is the only "
    "realm-scoped data set the client has, for any realm. Data\\area-52\\ is written "
    "by the LAUNCHER's patcher as part of the ordinary ascension-live product update "
    "plan: across every patcher log on a reference install, 181 distinct Data/ paths "
    "were ever written and exactly 2 of them are realm-scoped, both area-52, and "
    "those writes PRECEDE any Area 52 session on that install by about two weeks. "
    "Playing a realm does NOT materialize a Data\\<realm>\\ directory: a reference "
    "install with sessions across 7 realms, including both Conquest of Azeroth "
    "realms, still has exactly one, and a whole-install search finds exactly one "
    "listarchive file. NOTE that Rexxar and Vol'jin are two realms of the SAME game "
    "mode (Conquest of Azeroth, gameMode=11), not two content sets - there is no "
    "per-realm CoA split to capture. CONSEQUENCE: CoA realms read the BASE chain, "
    "base is what this dataset is built on, and the base-vs-area-52 Spell.dbc "
    "dispute measured in overlay_diff.json is a Free-Pick-vs-base divergence, NOT a "
    "CoA authority question. HONEST LIMIT: client files cannot observe SMSG traffic "
    "- if CoA overrides are served server-side over the wire, nothing on disk would "
    "show it, and only an in-game /dump on a CoA character can settle that half."
)


def _base_record_count(table: str):
    """None if `table` has no same-named entry in base config.WANTED_DBCS (a
    realm-only table) or the base file hasn't been extracted to work/dbc/."""
    name = f"{table}.dbc"
    if name not in config.WANTED_DBCS:
        return None
    p = config.WORK_DBC_DIR / name
    if not p.is_file():
        return None
    return dbc.DBCFile(p).records


def _missing_ref_resolution(realm_spell_ids: set):
    """Report-only evidence (no threshold, honest number either way): for each
    bucket in the base client's data/spells/_missing_refs.json (ids referenced by
    CAD/talent/rank chains but absent from the base Spell.dbc snapshot), how many
    of those ids exist as a real id in THIS realm's own Spell.dbc - id-set
    membership only, cheap, and the direct evidence for "the missing spells live
    in a realm overlay".

    [Review fix pass] Returns (None, reason) instead of {} when the base file is
    absent. It USED to return a bare {}, which build_realm then shipped as an
    empty `missingRefResolution` in a published index.json - an evidence file
    with no evidence, indistinguishable from a measured zero. Task W4-13 saw
    exactly that happen for real (a concurrent build_spells rmtree of
    data/spells/ removed _missing_refs.json mid-run) and the response was
    documentation only. The degrade is now recorded in the output itself: a
    consumer sees `missingRefResolution: null` plus a `degraded` key naming the
    cause, and can never mistake it for a real measurement.
    """
    p = config.DATA_DIR / "spells" / "_missing_refs.json"
    if not p.is_file():
        return None, (f"data/spells/_missing_refs.json is absent ({p}) - the spells "
                      "stage has not run, or its output was removed mid-run (see "
                      "AGENT-GUIDE.md's one-at-a-time rule). missingRefResolution "
                      "was NOT measured on this build; it is null, not zero.")
    missing_by_source = json.loads(p.read_text(encoding="utf-8"))
    return {
        source: {
            "missingCount": len(ids),
            "resolvedInRealm": sum(1 for i in ids if i in realm_spell_ids),
        }
        for source, ids in missing_by_source.items()
    }, None


def build_realm(realm: str, allow_missing_base: bool = False) -> dict:
    dbc_dir = config.WORK_REALMS_DIR / realm / "dbc"
    raw_dir = config.RAW_REALMS_DIR / realm / "dbc"
    # This rmtree-then-rewrite is the same half-written-layer window every other
    # extractor here guards, and it was the ONLY raw layer without the sentinel:
    # a run killed between the delete and the last write left a truncated
    # Spell.csv.gz and four sibling tables missing, and nothing downstream could
    # tell that tree apart from a finished one. tests/test_dataset.py rewrites
    # this layer, so the window is reached by the test suite, not just by builds.
    layerstate.begin(raw_dir.parent)
    if raw_dir.exists():
        shutil.rmtree(raw_dir)
    raw_dir.mkdir(parents=True)

    tables = sorted(p.stem for p in dbc_dir.glob("*.dbc"))
    table_info = {}
    for table in tables:
        f = dbc.DBCFile(dbc_dir / f"{table}.dbc")
        spec = dbc.TABLE_MAPS.get(table)
        mapped = bool(spec and f.fields == spec["expected_fields"])
        if mapped:
            dbc.dump_table(table, dbc_dir=dbc_dir, out_dir=raw_dir)
        else:
            dbc.dump_unmapped(table, out_dir=raw_dir, dbc_dir=dbc_dir)
        base_n = _base_record_count(table)
        info = {
            "records": f.records, "fields": f.fields, "mapped": mapped,
            "baseRecords": base_n,
            "delta": (f.records - base_n) if base_n is not None else None,
        }
        # [Task V3-2 finding] dbc.DBCFile.fields is byte-accurate (record_size/4);
        # a table whose WDBC header DECLARES a different FieldCount (observed on
        # CharacterAdvancement.dbc: declared 179 vs true 173) gets that flagged here
        # rather than silently dropped - no key at all when they agree (the common
        # case, no null-noise).
        if f.declared_fields != f.fields:
            info["declaredFields"] = f.declared_fields
        table_info[table] = info

    # gate: realm Spell.dbc layout-guard passes with the base map (234 fields) -
    # a matching field count alone doesn't prove column *layout* compatibility, so
    # also golden-decode a known base spell id straight off the realm's own file.
    assert "Spell" in table_info and table_info["Spell"]["mapped"], \
        f"realm {realm}: Spell.dbc did not pass the base TABLE_MAPS layout guard"
    spell_rows = {r["id"]: r for r in dbc.iter_named("Spell", dbc_dir=dbc_dir)}
    golden = spell_rows.get(17)
    assert golden and golden["name_enUS"] == "Power Word: Shield", golden

    realm_spell_ids = set(spell_rows)
    base_spell_ids = {r["id"] for r in dbc.iter_named("Spell")}     # base client, work/dbc
    new_spell_count = len(realm_spell_ids - base_spell_ids)
    assert new_spell_count > MIN_NEW_SPELL_COUNT, (
        f"realm {realm}: newSpellCount {new_spell_count} <= {MIN_NEW_SPELL_COUNT} - "
        "overlay evidence weaker than the pinned expectation, re-verify before trusting")

    # [Review fix pass] Fail loudly by default rather than publishing an evidence
    # file with no evidence. allow_missing_base=True is the standalone-run escape
    # hatch (`python -m tools.build_realms` against a repo whose spells stage has
    # not run yet) and stamps the degrade INTO index.json so it is visible in the
    # committed data, not just in a console line nobody kept.
    missing_ref_resolution, degraded = _missing_ref_resolution(realm_spell_ids)
    if degraded and not allow_missing_base:
        raise RuntimeError(f"realm {realm}: {degraded} Pass allow_missing_base=True "
                           "to publish an explicitly-degraded index.json instead.")

    index = {
        "realm": realm,
        "tables": table_info,
        "spellIdRange": [min(realm_spell_ids), max(realm_spell_ids)],
        "newSpellCount": new_spell_count,
        "missingRefResolution": missing_ref_resolution,
    }
    if degraded:
        index["degraded"] = degraded

    # [Task W4-5 fix] Used to shutil.rmtree() the whole realm dir here before
    # rewriting - harmless while this module was the ONLY writer under
    # data/realms/<realm>/, but tools/diff_realm_overlay.py now also owns one file
    # there (overlay_diff.json) and a wholesale rmtree would silently destroy it on
    # every rebuild (the same class of bug the specs.json/archetypes.json survival
    # gate exists to catch for build_classes vs. build_classmeta). This module still
    # owns index.json/_meta.json exclusively and always rewrites them fully - it
    # just no longer nukes files it doesn't own to do so.
    data_dir = config.DATA_REALMS_DIR / realm
    data_dir.mkdir(parents=True, exist_ok=True)
    (data_dir / "index.json").write_text(
        json.dumps(index, indent=1, sort_keys=True, ensure_ascii=False), encoding="utf-8", newline="\n")

    meta = {
        "realm": realm,
        "mappedTables": sorted(t for t, v in table_info.items() if v["mapped"]),
        "unmappedTables": sorted(t for t, v in table_info.items() if not v["mapped"]),
        "deliveryMechanism": DELIVERY_MECHANISM,
        "futureMilestone": (
            "Full realm spell/class curation (per-record enrichment of realm-only "
            "spells, mapping realm CharacterAdvancement/SpellRank data onto classes "
            "the way data/classes/ does for the base client) is explicitly OUT of "
            "this task's scope. v3 delivers extraction (work/realms/) + the raw dump "
            "layer (raw/realms/) + this overlay evidence index (data/realms/) only - "
            "see AGENT-GUIDE.md's 'Manastorm + realm overlays' section (task V3-3)."
        ),
    }
    (data_dir / "_meta.json").write_text(
        json.dumps(meta, indent=1, sort_keys=True, ensure_ascii=False), encoding="utf-8", newline="\n")

    # Written last, and only when every gate above passed: a realm whose build
    # raised leaves no sentinel, which is the point.
    layerstate.finish(raw_dir.parent, {
        "layer": f"realms/{realm}",
        "generatedBy": "python -m tools.build_realms",
        "tableCount": len(table_info),
        "recordTotal": sum(v["records"] for v in table_info.values()),
        "mappedTables": sum(1 for v in table_info.values() if v["mapped"])})
    return index


def build(skip_extract: bool = False, allow_missing_base: bool = False) -> dict:
    """skip_extract mirrors the base pipeline's --skip-extract convention (task
    V3-3 orchestrator wiring): reuse an already-populated work/realms/<realm>/dbc/
    for every discovered realm instead of re-reading MPQ archives. Falls back to a
    real extract if any discovered realm has no cached dbc dir yet (first run,
    or a newly-appeared realm directory).

    allow_missing_base [review fix pass]: publish an explicitly-degraded
    index.json (missingRefResolution: null + a `degraded` reason) when
    data/spells/_missing_refs.json is absent, instead of raising. Off in the
    orchestrator - build_dataset.py always runs the spells stage first, so a
    missing base file there means something went wrong and should be loud."""
    config.ensure_dirs()
    realms = config.discover_realms()
    already_cached = realms and all(
        (config.WORK_REALMS_DIR / r / "dbc").is_dir() for r in realms)
    if not (skip_extract and already_cached):
        extract_realms.extract_all()
    layerstate.begin(config.RAW_REALMS_DIR)
    out = {realm: build_realm(realm, allow_missing_base=allow_missing_base)
           for realm in realms}
    layerstate.finish(config.RAW_REALMS_DIR, {
        "layer": "realms", "generatedBy": "python -m tools.build_realms",
        "realmCount": len(out), "realms": sorted(out),
        "recordTotal": sum(v["records"] for idx in out.values()
                           for v in idx["tables"].values())})
    return out


if __name__ == "__main__":
    # standalone convenience run - tolerate a not-yet-built data/spells/, but stamp
    # the degrade into the output so a zeroed run can't pass as a measured one
    for realm, idx in build(allow_missing_base=True).items():
        print(f"realm {realm}: newSpellCount={idx['newSpellCount']} "
              f"spellIdRange={idx['spellIdRange']} "
              f"missingRefResolution={idx['missingRefResolution']}")
