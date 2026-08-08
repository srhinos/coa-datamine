"""Committed Interface/API code-layer extraction (task V2-6).

Scans EVERY archive (same chain-order scan as extract_mpq, just a different filter:
files under `Interface\\` instead of `DBFilesClient\\`) and extracts every code payload
(`.lua .xml .toc .txt .md` - art/BLPs excluded, this is a code layer not an art dump) to
`raw/interface/<path relative to Interface\\>` - so `raw/interface/` mirrors the client's
`Interface\\` tree root directly (an archive-stored `Interface\\AddOns\\Foo\\Foo.lua`
lands at `raw/interface/AddOns/Foo/Foo.lua`). Per-file winner is resolved by
`extract_mpq.chain_rank` exactly like the DBC extractor: last archive in chain order
wins, all other carriers are just not extracted (no losers list is kept here - the DBC
extractor's provenance already demonstrates that pattern for the tables that need it).

The on-disk `CLIENT_DIR/Interface/AddOns/APIDocumentation` tree is copied in on top of
whatever the archives produced, at the SAME relative-path scheme (`AddOns/
APIDocumentation/...`) - so it WINS any collision at an identical path. This is
deliberate: APIDocumentation is the launcher-managed live copy of Ascension's actual API
surface (their real API, not a stale archive snapshot) - see AGENT-GUIDE.md.

Grouping/collision resolution is case-insensitive (matching MPQ's own case-insensitive
hash-table semantics and Windows filesystem semantics for the disk copy), but the WINNING
carrier's original stored case is what gets written to disk and used as the manifest key.

Everything is written to `raw/interface/_manifest.json`: sorted relative paths (using
os.sep, matching the extraction destination literally) -> {source, size, sha256}. Fully
a pure function of (archive contents, on-disk APIDocumentation) - no timestamps anywhere,
matching this repo's determinism rule for everything under raw/.
"""
import hashlib, json, os

from mpyq import MPQArchive

from tools import config, extract_mpq, layerstate

CODE_EXTS = {".lua", ".xml", ".toc", ".txt", ".md"}
_INTERFACE_PREFIX = "interface\\"
_PREFIX_LEN = len(_INTERFACE_PREFIX)


def _ext(name: str) -> str:
    base = name.replace("/", "\\").rsplit("\\", 1)[-1]
    if "." not in base:
        return ""
    return "." + base.rsplit(".", 1)[-1].lower()


def _collect_archive_carriers() -> tuple[dict, list]:
    """One pass over every archive's listfile: {rel_key (lowercase, relative to
    Interface\\) -> [(chain_rank, archive_path, stored_name_bytes, rel_original), ...]}.
    rel_original preserves the winner's on-disk case; rel_key is the case-insensitive
    grouping key used to resolve collisions (both within archives and later against the
    disk copy)."""
    carriers = {}
    skipped = []
    for p in extract_mpq._list_archives():
        try:
            a = MPQArchive(str(p), listfile=True)
            listed = a.files or []
        except Exception as e:
            skipped.append({"archive": p.name, "reason": f"{type(e).__name__}: {e}"})
            continue
        for stored in listed:
            original = stored.decode("latin-1", "replace").replace("/", "\\")
            lower = original.lower()
            if not lower.startswith(_INTERFACE_PREFIX):
                continue
            if _ext(lower) not in CODE_EXTS:
                continue
            rel_key = lower[_PREFIX_LEN:]
            rel_original = original[_PREFIX_LEN:]
            carriers.setdefault(rel_key, []).append(
                (extract_mpq.chain_rank(p), p, stored, rel_original))
    return carriers, skipped


def _resolve_archive_winners(carriers: dict) -> tuple[dict, int]:
    """rel_key -> (archive_path, stored_name_bytes, rel_original). Also returns the
    count of logical files that had more than one archive carrier (collisions resolved
    by chain_rank, mirroring extract_mpq's winner/loser resolution)."""
    winners = {}
    collisions = 0
    for rel_key, lst in carriers.items():
        lst.sort(key=lambda t: t[0])
        if len(lst) > 1:
            collisions += 1
        _, winner_path, stored, rel_original = lst[-1]
        winners[rel_key] = (winner_path, stored, rel_original)
    return winners, collisions


def _read_archive_entries(winners: dict) -> dict:
    """rel_key -> {"rel": rel_original, "source": archive_name, "data": bytes}."""
    by_archive = {}
    for rel_key, (archive_path, stored, rel_original) in winners.items():
        by_archive.setdefault(archive_path, []).append((rel_key, stored, rel_original))

    entries = {}
    for archive_path, items in by_archive.items():
        a = MPQArchive(str(archive_path), listfile=False)
        for rel_key, stored, rel_original in items:
            data = a.read_file(stored)
            if data is None:
                continue
            entries[rel_key] = {"rel": rel_original, "source": archive_path.name, "data": data}
    return entries


def _disk_entries() -> dict:
    """rel_key -> {"rel": ..., "source": "disk", "data": bytes} for every code file
    under CLIENT_DIR/Interface/AddOns/APIDocumentation."""
    root = config.CLIENT_DIR / "Interface" / "AddOns" / "APIDocumentation"
    entries = {}
    if not root.is_dir():
        return entries
    interface_root = config.CLIENT_DIR / "Interface"
    for p in sorted(root.rglob("*")):
        if not p.is_file():
            continue
        if p.suffix.lower() not in CODE_EXTS:
            continue
        rel_original = str(p.relative_to(interface_root))
        rel_key = rel_original.lower()
        entries[rel_key] = {"rel": rel_original, "source": "disk", "data": p.read_bytes()}
    return entries


DATAMINE_OWNED = "python datamine.py"


def extract_all() -> dict:
    config.ensure_dirs()
    out_dir = config.RAW_INTERFACE_DIR

    # `datamine.py` emits this SAME layer, and it emits a strictly larger one:
    # it reads members with tools/mpq.py where this module still reads them with
    # mpyq, so five files this extractor cannot decode at all are present in
    # datamine's tree (1,558 files against 1,553). Running this over the top of
    # that was silent data loss - measured, not hypothesised: a build_dataset
    # run during this work deleted RaceSelect.lua/.xml, SoundOptionsFrame.lua/
    # .xml and AnimationTemplates.lua from the committed tree and rewrote the
    # manifest to match, and nothing said so.
    #
    # So this stage now DEFERS to datamine's layer instead of clobbering it. The
    # sentinel names its own producer, which is what makes the ownership check
    # possible without a flag anyone has to remember to pass.
    state = layerstate.read(out_dir) if layerstate.is_complete(out_dir) else {}
    if state.get("generatedBy") == DATAMINE_OWNED:
        mpath = out_dir / "_manifest.json"
        manifest = json.loads(mpath.read_bytes().decode("utf-8"))
        print(f"[interface] kept datamine.py's layer ({manifest['count']} "
              f"files); this extractor would write a subset of it. Regenerate "
              f"it with `{DATAMINE_OWNED}`.")
        # the SAME stats shape the extracting path returns, so every caller and
        # every gate downstream reads one contract rather than two
        return {"count": manifest["count"],
                "archiveSourced": manifest["archiveSourced"],
                "diskSourced": manifest["diskSourced"],
                "manifestSha256": hashlib.sha256(mpath.read_bytes()).hexdigest(),
                "keptExisting": True, "generatedBy": DATAMINE_OWNED}

    # The sentinel is dropped before the tree is cleared, so a run killed
    # mid-extraction leaves a layer that reads as unfinished rather than as a
    # smaller-but-plausible one.
    layerstate.clear_dir(out_dir)

    carriers, skipped = _collect_archive_carriers()
    winners, multi_archive_collisions = _resolve_archive_winners(carriers)
    entries = _read_archive_entries(winners)
    archive_sourced = len(entries)

    disk = _disk_entries()
    disk_overrode_archive = sum(1 for k in disk if k in entries)
    entries.update(disk)          # disk copy WINS any collision at the same rel path

    files_meta = {}
    for meta in entries.values():
        rel = meta["rel"].replace("\\", os.sep)
        dest = out_dir.joinpath(*rel.split(os.sep))
        dest.parent.mkdir(parents=True, exist_ok=True)
        dest.write_bytes(meta["data"])
        files_meta[rel] = {
            "source": meta["source"],
            "size": len(meta["data"]),
            "sha256": hashlib.sha256(meta["data"]).hexdigest(),
        }

    manifest = {
        "count": len(files_meta),
        "archiveSourced": archive_sourced,
        "diskSourced": len(disk),
        "files": {k: files_meta[k] for k in sorted(files_meta)},
    }
    manifest_path = out_dir / "_manifest.json"
    # bytes, not Path.write_text(): text mode translates \n to the platform's
    # newline, which would make this manifest - and the sha256 recorded for it -
    # depend on the OS that generated it. Same rule every other raw layer uses.
    manifest_path.write_bytes(
        json.dumps(manifest, ensure_ascii=False, indent=1,
                   sort_keys=True).encode("utf-8"))
    layerstate.finish(out_dir, {
        "layer": "raw/interface", "generatedBy": "python -m tools.extract_interface",
        "count": len(files_meta), "archiveSourced": archive_sourced,
        "diskSourced": len(disk)})

    return {
        "count": len(files_meta),
        "archiveSourced": archive_sourced,
        "diskSourced": len(disk),
        "diskOverrodeArchive": disk_overrode_archive,
        "multiArchiveCollisions": multi_archive_collisions,
        "skippedArchives": len(skipped),
        "manifestSha256": hashlib.sha256(manifest_path.read_bytes()).hexdigest(),
    }


def main():
    stats = extract_all()
    print(f"interface files: {stats['count']} "
          f"(archive={stats['archiveSourced']}, disk={stats['diskSourced']}, "
          f"disk-overrode-archive={stats['diskOverrodeArchive']}, "
          f"multi-archive-collisions={stats['multiArchiveCollisions']})")
    print(f"manifest sha256: {stats['manifestSha256']}")


if __name__ == "__main__":
    main()
