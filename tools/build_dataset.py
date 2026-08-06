"""One-command pipeline: extract -> dump -> snapshot -> build -> provenance."""
import argparse, datetime, hashlib, json

from tools import (config, dbc, extract_mpq, extract_interface, snapshot_content,
                   build_spells, build_classes, build_talents, build_dungeons,
                   build_creatures, build_classmeta, build_essence, build_mythic,
                   build_manastorm, build_realms, build_coatalents, build_items)


def run(skip_extract=False, skip_dump=False, skip_interface=False,
        skip_manastorm=False, skip_realm_extract=False) -> dict:
    config.ensure_dirs()
    if skip_extract and all((config.WORK_DBC_DIR / w).is_file()
                            for w in config.WANTED_DBCS):
        extract_prov = json.loads(
            (config.WORK_DIR / "extract_provenance.json").read_text(encoding="utf-8"))
    else:
        extract_prov = extract_mpq.extract_all()
    if not skip_dump:
        dbc.dump_all()
    content_prov = snapshot_content.snapshot()

    stats = {}
    stats["spells"] = build_spells.build()
    missing_counts = {k: len(v) for k, v in stats["spells"]["missing_by_source"].items()}
    print(f"[spells]   {stats['spells']['written']} written, "
          f"missing_by_source={missing_counts} ref_counts={stats['spells']['ref_counts']}")
    stats["classes"] = build_classes.build()
    print(f"[classes]  {stats['classes']}")
    stats["talents"] = build_talents.build()
    print(f"[talents]  {stats['talents']}")
    stats["dungeons"] = build_dungeons.build()
    print(f"[dungeons] {stats['dungeons']}")
    stats["creatures"] = build_creatures.build()
    print(f"[creatures] {stats['creatures']}")
    # Amendment D / stage order: classmeta reads spells + writes INTO data/classes/ -
    # it must run after build_classes (which owns + rebuilds that directory) or its
    # specs.json/archetypes.json get wiped by a later classes rebuild.
    stats["classmeta"] = build_classmeta.build()
    print(f"[classmeta] {stats['classmeta']}")
    # v4 (task W4-5): per-class AE/TE curves, class-adjacent but deliberately NOT
    # classmeta's (Amendment D - classmeta owns specs.json/archetypes.json only).
    # Only needs work/dbc (ChrClasses + CharacterAdvancementEssence), independent
    # of build_classes/build_classmeta's own data/classes/ output.
    stats["essence"] = build_essence.build()
    print(f"[essence]  {stats['essence']}")
    stats["mythic"] = build_mythic.build()
    print(f"[mythic]   {stats['mythic']}")

    # v4 (task W4-11b): item support tables. Only needs work/dbc (ItemStat, Item -
    # both already populated above), independent of the class/spell/dungeon stages.
    # dbc.dump_all() above already skips ItemStat's raw dump (CUSTOM_RAW_DUMP_TABLES) -
    # this is where its sharded raw/dbc/itemstat/ + data/items/statsByItem/ actually
    # get written.
    stats["items"] = build_items.build()
    print(f"[items]    {stats['items']}")

    # v4 (task W4-9): CoA talent tree geometry. Reads the FROZEN external payload
    # capture (raw/talents/coa-builder-<slug>.html, written by the separate,
    # occasional tools/fetch_coatalents.py network step - never fetched live
    # here) plus data/classes/ (build_classes, above) and data/spells/ (build_spells,
    # above) for its classId join and resolve-rate cross-validation, so it must
    # run after both.
    stats["coatalents"] = build_coatalents.build()
    print(f"[coatalents] {stats['coatalents']}")

    # v3: Manastorm (patch-M seasonal-modifier tables, task V3-1) reads only
    # config.WORK_DBC_DIR (already populated above) - no extraction step of its
    # own. skip_manastorm reuses the existing data/manastorm/_meta.json counts
    # instead of re-parsing/re-writing (mirrors --skip-interface's reuse shape).
    meta_path = config.DATA_DIR / "manastorm" / "_meta.json"
    if skip_manastorm and meta_path.is_file():
        meta = json.loads(meta_path.read_text(encoding="utf-8"))
        stats["manastorm"] = {"counts": meta["counts"], "reused": True}
    else:
        stats["manastorm"] = build_manastorm.build()
    print(f"[manastorm] {stats['manastorm']}")

    # v3: realm-overlay extraction + raw layer + overlay evidence index (task
    # V3-2). Depends on data/spells/_missing_refs.json (missingRefResolution),
    # written by the spells stage above - must stay after it. skip_realm_extract
    # mirrors --skip-extract, scoped to work/realms/ instead of work/dbc/.
    stats["realms"] = build_realms.build(skip_extract=skip_realm_extract)
    print(f"[realms]   {sorted(stats['realms'])}")

    manifest_path = config.RAW_INTERFACE_DIR / "_manifest.json"
    if skip_interface and manifest_path.is_file():
        manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
        # provenance must carry the manifest sha256 + file count on EVERY path, not
        # just a fresh extract - re-hash the existing file (cheap, no rescan needed).
        stats["interface"] = {
            "count": manifest["count"], "archiveSourced": manifest["archiveSourced"],
            "diskSourced": manifest["diskSourced"],
            "manifestSha256": hashlib.sha256(manifest_path.read_bytes()).hexdigest(),
            "reused": True,
        }
    else:
        stats["interface"] = extract_interface.extract_all()
    print(f"[interface] {stats['interface']}")

    prov = {
        "generatedUtc": datetime.datetime.now(datetime.timezone.utc)
                        .isoformat(timespec="seconds"),
        "clientDir": str(config.CLIENT_DIR),
        "extract": extract_prov,
        "content": content_prov,
        "buildStats": stats,
        # top-level convenience copy of extract_prov["headerMismatches"] (task
        # V3-3): every base table whose WDBC header's declared FieldCount
        # disagrees with its byte-accurate record_size//4 - see extract_mpq.py.
        # tests/test_dataset.py gates this at exactly [] for the base pipeline;
        # a realm table (e.g. area-52's CharacterAdvancement.dbc) legitimately
        # disagreeing is a SEPARATE, allowed thing surfaced instead as
        # data/realms/<realm>/index.json's per-table `declaredFields` key.
        "headerMismatches": extract_prov.get("headerMismatches", []),
    }
    (config.RAW_DIR / "provenance.json").write_text(
        json.dumps(prov, ensure_ascii=False, indent=1, sort_keys=True),
        encoding="utf-8")
    return prov


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--skip-extract", action="store_true",
                    help="reuse work/dbc from a previous extract")
    ap.add_argument("--skip-dump", action="store_true",
                    help="skip regenerating raw/dbc CSV dumps")
    ap.add_argument("--skip-interface", action="store_true",
                    help="reuse raw/interface/_manifest.json from a previous extract")
    ap.add_argument("--skip-manastorm", action="store_true",
                    help="reuse data/manastorm/_meta.json counts instead of rebuilding")
    ap.add_argument("--skip-realm-extract", action="store_true",
                    help="reuse work/realms/<realm>/dbc from a previous extract")
    a = ap.parse_args()
    run(skip_extract=a.skip_extract, skip_dump=a.skip_dump, skip_interface=a.skip_interface,
        skip_manastorm=a.skip_manastorm, skip_realm_extract=a.skip_realm_extract)
    print("build complete - raw/provenance.json updated")


if __name__ == "__main__":
    main()
