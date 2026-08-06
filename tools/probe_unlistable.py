"""Hash-table-only provenance probe for MPQ archives that carry no readable
listfile (task W4-7; coa-sim-handoff/DATAMINE-REQUEST.md Sec 5.1). Closes a
real hole in tools/extract_mpq.py's chain walk: 8 archives in the client's
MPQ set (patch-4/5/C/CZZ/W/WB/WC + patch-P) cannot be enumerated by mpyq, so
extract_mpq.py's chain walk never sees anything they carry - it can only
compare archives it CAN list. The killer detail: patch-W, patch-WB and
patch-WC sort lexicographically ABOVE patch-T, and patch-T.MPQ contains
exactly one file, DBFilesClient\\Spell.dbc, which wins the base chain today
and is what the entire dataset rests on. A Spell.dbc hiding in any of those
three would silently outrank it and nobody would know.

Technique: an MPQ file's presence is fully determined by its hash-table entry
- (hash_a, hash_b), computed from the UPPERCASED backslash path via MPQ's
fixed hash function - independent of the '(listfile)' member, which is just
another file in the archive (and the one that fails to read/decrypt on all 8
of these). mpyq's MPQArchive, opened with listfile=False, still reads and
decrypts the hash and block tables: the decrypt key for '(hash table)' /
'(block table)' is a well-known fixed-string key, a completely different
mechanism from per-file content encryption (the thing that actually breaks
patch-P.mpq - MPQ_FILE_ENCRYPTED on its stored files' block entries raises
NotImplementedError only when mpyq tries to read FILE CONTENT, never when it
reads the hash/block tables themselves). So a known path's existence is
testable with zero enumeration via
MPQArchive(path, listfile=False).get_hash_table_entry(path)."""
import json

from mpyq import MPQArchive, MPQ_FILE_EXISTS

from tools import config


def try_list(archive_path):
    """The single unlistable-archive predicate: attempt MPQArchive(archive_path,
    listfile=True). Returns (files, reason) - files is the archive's non-empty
    listfile on success, reason is None; on ANY failure files is None and
    reason is a short string. Two failure shapes are both "unlistable" and
    MUST be treated identically by every caller (tools/extract_mpq.py's chain
    walk and discover_unlistable() below alike - a review of task W4-7 caught
    the walk checking only the first): the open/read raising (no readable
    '(listfile)' member, or an encrypted one - mpyq's own read_file returns
    None or raises, and either way the constructor's `.splitlines()` blows
    up), OR a successful open whose .files comes back empty/None (a present
    but empty (listfile) member - no exception, but nothing to enumerate)."""
    try:
        a = MPQArchive(str(archive_path), listfile=True)
        files = a.files
    except Exception as e:
        return None, f"{type(e).__name__}: {e}"
    if not files:
        return None, "empty listfile"
    return files, None


def probe_paths(archive_path, paths) -> dict:
    """Test existence of each of `paths` (DBFilesClient\\Name.dbc style,
    any case - mpyq's _hash uppercases internally) inside `archive_path`,
    via hash-table lookup only. No listfile read, no file content read.
    Returns {path: bool}.

    A hit requires BOTH a matching hash-table entry AND that entry's
    block-table row carrying MPQ_FILE_EXISTS. The sentinel
    block_table_index values 0xFFFFFFFF (hash slot never used) and
    0xFFFFFFFE (file deleted, slot kept alive for probe-chain continuation)
    are excluded - a raw hash-table scan without this check would report a
    deleted-but-not-overwritten file as present."""
    archive = MPQArchive(str(archive_path), listfile=False)
    out = {}
    for path in paths:
        entry = archive.get_hash_table_entry(path)
        hit = False
        if entry is not None and entry.block_table_index < 0xFFFFFFFE:
            block = archive.block_table[entry.block_table_index]
            hit = bool(block.flags & MPQ_FILE_EXISTS)
        out[path] = hit
    return out


def discover_unlistable(archives=None) -> list:
    """Archives tools/extract_mpq.py's chain walk cannot enumerate - built on
    try_list() above, the SAME predicate extract_mpq.extract_all() now uses
    for its own skip decision, so the two never drift apart again. Independent
    of tools/extract_mpq.py's own skipped_archives bookkeeping so this module
    works standalone; `archives` lets a caller (e.g. extract_mpq.extract_all(),
    which already did this exact scan) pass the list it already has instead of
    re-opening every archive a second time."""
    if archives is None:
        from tools.extract_mpq import _list_archives
        archives = _list_archives()
    return [p for p in archives if try_list(p)[0] is None]


def probe_all(archives=None, extra_paths=()) -> dict:
    """Probe every config.WANTED_DBCS path (+ extra_paths, always including
    DBFilesClient\\Spell.dbc explicitly per the brief, though it is already
    in WANTED_DBCS) against each archive in `archives` (default:
    discover_unlistable()). Returns {archive_name: {"probedCount": int,
    "hits": [path, ...]}}, or {"error": "...", "probedCount": int,
    "hits": []} for an archive mpyq cannot even open with listfile=False -
    the honest-failure path the brief calls out for patch-P.mpq (its hash
    table decrypts fine via the fixed-key mechanism above, so this branch
    is not expected to fire for it today, but is not assumed away)."""
    if archives is None:
        archives = discover_unlistable()
    paths = sorted({f"DBFilesClient\\{w}" for w in config.WANTED_DBCS}
                   | {"DBFilesClient\\Spell.dbc"} | set(extra_paths))
    out = {}
    for p in archives:
        try:
            result = probe_paths(p, paths)
        except Exception as e:
            out[p.name] = {"error": f"{type(e).__name__}: {e}",
                            "probedCount": len(paths), "hits": []}
            continue
        out[p.name] = {"probedCount": len(paths),
                        "hits": sorted(k for k, v in result.items() if v)}
    return out


def main():
    prov = probe_all()
    for name in sorted(prov):
        frag = prov[name]
        if "error" in frag:
            print(f"{name:16s} OPEN FAILED: {frag['error']}")
            continue
        hit_str = ", ".join(frag["hits"]) if frag["hits"] else "(none)"
        print(f"{name:16s} probed={frag['probedCount']:3d} hits={hit_str}")
    config.WORK_DIR.mkdir(parents=True, exist_ok=True)
    (config.WORK_DIR / "probe_unlistable.json").write_text(
        json.dumps(prov, indent=1, sort_keys=True), encoding="utf-8")


if __name__ == "__main__":
    main()
