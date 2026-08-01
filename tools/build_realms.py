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
tools/build_dataset.py's orchestrator - wiring a "realms" stage into that
orchestrator is explicitly future work, same as V3-1's Manastorm tables)."""
import json, shutil

from tools import config, dbc, extract_realms

MIN_NEW_SPELL_COUNT = 10000     # brief's loose pin: realm spells measured ~= +30k vs base


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


def _missing_ref_resolution(realm_spell_ids: set) -> dict:
    """Report-only evidence (no threshold, honest number either way): for each
    bucket in the base client's data/spells/_missing_refs.json (ids referenced by
    CAD/talent/rank chains but absent from the base Spell.dbc snapshot), how many
    of those ids exist as a real id in THIS realm's own Spell.dbc - id-set
    membership only, cheap, and the direct evidence for "the missing spells live
    in a realm overlay". Returns {} if the base file doesn't exist on disk yet."""
    p = config.DATA_DIR / "spells" / "_missing_refs.json"
    if not p.is_file():
        return {}
    missing_by_source = json.loads(p.read_text(encoding="utf-8"))
    return {
        source: {
            "missingCount": len(ids),
            "resolvedInRealm": sum(1 for i in ids if i in realm_spell_ids),
        }
        for source, ids in missing_by_source.items()
    }


def build_realm(realm: str) -> dict:
    dbc_dir = config.WORK_REALMS_DIR / realm / "dbc"
    raw_dir = config.RAW_REALMS_DIR / realm / "dbc"
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

    index = {
        "realm": realm,
        "tables": table_info,
        "spellIdRange": [min(realm_spell_ids), max(realm_spell_ids)],
        "newSpellCount": new_spell_count,
        "missingRefResolution": _missing_ref_resolution(realm_spell_ids),
    }

    data_dir = config.DATA_REALMS_DIR / realm
    if data_dir.exists():
        shutil.rmtree(data_dir)
    data_dir.mkdir(parents=True)
    (data_dir / "index.json").write_text(
        json.dumps(index, indent=1, sort_keys=True, ensure_ascii=False), encoding="utf-8")

    meta = {
        "realm": realm,
        "mappedTables": sorted(t for t, v in table_info.items() if v["mapped"]),
        "unmappedTables": sorted(t for t, v in table_info.items() if not v["mapped"]),
        "futureMilestone": (
            "Full realm spell/class curation (per-record enrichment of realm-only "
            "spells, mapping realm CharacterAdvancement/SpellRank data onto classes "
            "the way data/classes/ does for the base client) is explicitly OUT of "
            "this task's scope. v3 delivers extraction (work/realms/) + the raw dump "
            "layer (raw/realms/) + this overlay evidence index (data/realms/) only - "
            "see AGENT-GUIDE.md."
        ),
    }
    (data_dir / "_meta.json").write_text(
        json.dumps(meta, indent=1, sort_keys=True, ensure_ascii=False), encoding="utf-8")

    return index


def build() -> dict:
    config.ensure_dirs()
    extract_realms.extract_all()
    return {realm: build_realm(realm) for realm in config.discover_realms()}


if __name__ == "__main__":
    for realm, idx in build().items():
        print(f"realm {realm}: newSpellCount={idx['newSpellCount']} "
              f"spellIdRange={idx['spellIdRange']} "
              f"missingRefResolution={idx['missingRefResolution']}")
