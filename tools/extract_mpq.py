"""Chain-order-aware extraction of wanted DBCs from the Ascension MPQ set.

Mirrors the 3.3.5 loader order that Ascension's launcher extends:
base < locale base < patch.MPQ < patch-<digit> < locale patches < patch-<letters>.
Within a tier, lexicographic. The LAST archive in chain order containing a file
wins; all other carriers are recorded as losers in the provenance so a wrong
chain assumption is visible, never silent.
"""
import hashlib, json, struct
from pathlib import Path

from mpyq import MPQArchive

from tools import config, probe_unlistable


def chain_rank(path: Path) -> tuple:
    name = path.name.lower()
    in_locale = path.parent.name.lower() == "enus"
    if not name.startswith("patch"):
        return (1 if in_locale else 0, name)
    stem = name[:-4]                      # strip ".mpq"
    suffix = stem[6:] if len(stem) > 5 else ""   # after "patch-"
    if suffix == "":
        return (2, name)
    if suffix.isdigit():
        return (3, suffix.zfill(4))
    if in_locale:                          # patch-enus.mpq < patch-enus-2.mpq < ... < patch-enus-10.mpq
        parts = suffix.rsplit("-", 1)
        num = parts[1].zfill(4) if len(parts) == 2 and parts[1].isdigit() else ""
        return (4, num)
    return (5, suffix)                     # letter patches, lexicographic


def _list_archives():
    seen, out = set(), []
    for d in config.MPQ_DIRS:
        for p in sorted(d.iterdir()):
            if p.suffix.lower() == ".mpq" and p.resolve() not in seen:
                seen.add(p.resolve())
                out.append(p)
    return sorted(out, key=chain_rank)


def extract_all() -> dict:
    config.ensure_dirs()
    wanted = {w.lower(): w for w in config.WANTED_DBCS}
    carriers = {}                # lower name -> list of (rank, path, stored_name)
    skipped = []
    skipped_paths = []           # Path objects for the unlistable-archive probe below
    all_dbc_names = set()        # [Task W4-7] census (DATAMINE-REQUEST.md Sec 5.2):
    per_archive_dbc_counts = {}  # every DBFilesClient\* name seen in any LISTABLE
                                  # archive's listfile, wanted or not - this loop
                                  # already walks every listfile, so the census is free.
    for p in _list_archives():
        # [Task W4-7 review fix] shared predicate with probe_unlistable.discover_
        # unlistable() (tools/probe_unlistable.py's try_list()) - previously this
        # loop only caught the exception shape (no readable listfile at all) while
        # discover_unlistable() ALSO caught a successful-open-but-empty .files, so
        # an archive of that second shape would have silently skipped provenance,
        # census AND the hash-table probe. Both call sites now derive from the
        # same function, so they cannot drift apart again.
        files, reason = probe_unlistable.try_list(p)
        if files is None:
            skipped.append({"archive": p.name, "reason": reason})
            skipped_paths.append(p)
            continue
        archive_dbc_count = 0
        for f in files:
            fl = f.decode("latin-1", "replace").lower().replace("/", "\\")
            if fl.startswith("dbfilesclient\\"):
                base = fl.rsplit("\\", 1)[-1]
                all_dbc_names.add(base)
                archive_dbc_count += 1
                if base in wanted:
                    carriers.setdefault(base, []).append((chain_rank(p), p, f))
        if archive_dbc_count:
            per_archive_dbc_counts[p.name] = archive_dbc_count

    missing = sorted(set(wanted) - set(carriers))
    if missing:
        raise SystemExit(f"FATAL: wanted DBCs not found in any archive: {missing}")

    # [Task V3-3] "fields" (below) stays the header's DECLARED FieldCount - the
    # existing, load-bearing meaning test_extract.py already pins (spell.dbc == 234).
    # headerMismatches is new: a byte-accurate cross-check (record_size // 4, the
    # SAME derivation tools/dbc.py's DBCFile.fields trusts for row layout - see its
    # docstring and task V3-2's CharacterAdvancement.dbc finding) against that
    # declared count, for every base table. V3-2 made DBCFile stop hard-crashing on
    # a header/record_size disagreement (needed so a lying REALM header like
    # CharacterAdvancement's stays readable) - that fix quietly removed the base
    # pipeline's old crash canary for a lying BASE header too. This restores
    # visibility without reintroducing the crash: a disagreement is recorded here,
    # not swallowed, and tests/test_dataset.py gates the base list at exactly empty.
    prov = {"files": {}, "skipped_archives": skipped, "headerMismatches": []}
    by_winner = {}
    for base, lst in carriers.items():
        lst.sort(key=lambda t: t[0])
        rank, winner, stored = lst[-1]
        by_winner.setdefault(winner, []).append((base, stored, [p.name for _, p, _ in lst[:-1]]))
    # [Task W4-7] base -> the Path that won it, needed below to compare a probed
    # unlistable archive's chain_rank against the winner it might silently outrank.
    winner_path_by_base = {base: winner for winner, entries in by_winner.items()
                            for base, _stored, _losers in entries}

    for winner, entries in by_winner.items():
        a = MPQArchive(str(winner), listfile=False)
        for base, stored, losers in entries:
            data = a.read_file(stored)
            if not data or data[:4] != b"WDBC":
                raise SystemExit(f"FATAL: bad read of {base} from {winner.name}")
            out = config.WORK_DBC_DIR / wanted[base]
            out.write_bytes(data)
            _, recs, declared_fields, recsize, strsize = struct.unpack_from("<4s4I", data, 0)
            actual_fields = recsize // 4
            prov["files"][base] = {
                "winner": winner.name, "losers": losers,
                "sha256": hashlib.sha256(data).hexdigest(),
                "records": recs, "fields": declared_fields,
                "actualFields": actual_fields,
                "record_size": recsize, "bytes": len(data),
            }
            if actual_fields != declared_fields:
                prov["headerMismatches"].append({
                    "table": base, "declaredFields": declared_fields,
                    "actualFields": actual_fields,
                })

    # [Task W4-7] census (DATAMINE-REQUEST.md Sec 5.2): "368 distinct
    # DBFilesClient\* names exist in the chain against 77 extracted" - re-derived
    # live here (not copied from the doc) from the listfile walk above, which
    # already touches every listable archive for free.
    prov["census"] = {
        "distinctDbcNamesInChain": len(all_dbc_names),
        "extractedCount": len(wanted),
        "perArchiveDbcCounts": per_archive_dbc_counts,
    }

    # [Task W4-7] unlistable-archive provenance probe (DATAMINE-REQUEST.md Sec 5.1):
    # the archives that failed to open with listfile=True above (skipped_paths)
    # were invisible to the chain walk that just ran - it never saw whatever they
    # carry. Test them by hash-table lookup instead (see tools/probe_unlistable.py -
    # no listfile needed). A hit on a wanted table whose chain_rank OUTRANKS that
    # table's current winner means the chain walk picked the wrong file: structural,
    # not a warning - stop the whole pipeline rather than silently ship a dataset
    # built on the wrong Spell.dbc (or any other wanted table).
    prov["unlistableProbes"] = {}
    if skipped_paths:
        probes = probe_unlistable.probe_all(archives=skipped_paths)
        path_by_name = {p.name: p for p in skipped_paths}
        for archive_name, frag in probes.items():
            if "error" in frag:
                continue
            archive_path = path_by_name[archive_name]
            for hit_path in frag["hits"]:
                base = hit_path.rsplit("\\", 1)[-1].lower()
                winner_path = winner_path_by_base.get(base)
                if winner_path is not None and chain_rank(archive_path) > chain_rank(winner_path):
                    raise SystemExit(
                        f"FATAL: unlistable archive {archive_name} "
                        f"(chain_rank {chain_rank(archive_path)}) carries {hit_path} "
                        f"and OUTRANKS the current winner {winner_path.name} "
                        f"(chain_rank {chain_rank(winner_path)}) for that table - "
                        f"the dataset would be built on the wrong file. This is "
                        f"structural: investigate before re-running the pipeline.")
        prov["unlistableProbes"] = probes

    (config.WORK_DIR / "extract_provenance.json").write_text(
        json.dumps(prov, indent=1, sort_keys=True), encoding="utf-8", newline="\n")
    return prov


def main():
    prov = extract_all()
    for base in sorted(prov["files"]):
        e = prov["files"][base]
        flag = " COLLISION:" + ",".join(e["losers"]) if e["losers"] else ""
        print(f"{base:26s} <- {e['winner']:18s} records={e['records']:7d} fields={e['fields']:4d}{flag}")
    print(f"skipped archives: {len(prov['skipped_archives'])}")
    if prov["headerMismatches"]:
        print(f"HEADER MISMATCHES: {prov['headerMismatches']}")
    census = prov["census"]
    print(f"census: {census['distinctDbcNamesInChain']} distinct DBFilesClient names "
          f"in chain, {census['extractedCount']} extracted")
    for name, frag in sorted(prov["unlistableProbes"].items()):
        if "error" in frag:
            print(f"  unlistable probe {name}: OPEN FAILED: {frag['error']}")
        else:
            hits = ", ".join(frag["hits"]) if frag["hits"] else "(none)"
            print(f"  unlistable probe {name}: probed={frag['probedCount']} hits={hits}")


if __name__ == "__main__":
    main()
