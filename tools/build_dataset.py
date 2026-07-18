"""One-command pipeline: extract -> dump -> snapshot -> build -> provenance."""
import argparse, datetime, json

from tools import (config, dbc, extract_mpq, snapshot_content,
                   build_spells, build_classes, build_talents, build_dungeons)


def run(skip_extract=False, skip_dump=False) -> dict:
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
    a = ap.parse_args()
    run(skip_extract=a.skip_extract, skip_dump=a.skip_dump)
    print("build complete - raw/provenance.json updated")


if __name__ == "__main__":
    main()
