"""One-command pipeline: extract -> dump -> snapshot -> build -> provenance."""
import argparse, datetime, hashlib, json

from tools import (config, dbc, extract_mpq, extract_interface, snapshot_content,
                   build_spells, build_classes, build_talents, build_dungeons,
                   build_creatures, build_classmeta, build_mythic)


def run(skip_extract=False, skip_dump=False, skip_interface=False) -> dict:
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
    stats["mythic"] = build_mythic.build()
    print(f"[mythic]   {stats['mythic']}")

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
    a = ap.parse_args()
    run(skip_extract=a.skip_extract, skip_dump=a.skip_dump, skip_interface=a.skip_interface)
    print("build complete - raw/provenance.json updated")


if __name__ == "__main__":
    main()
