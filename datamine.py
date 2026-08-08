#!/usr/bin/env python
"""THE datamine. One script, no arguments, one traversal of the client.

    python datamine.py

WHY THIS FILE EXISTS
--------------------
The extraction used to be a chain of stage scripts driven by
`tools/extract_everything.py`. Measured, not guessed: `tools/` held 48 Python
files and TEN of them independently opened the MPQ archives. A full run
therefore walked 44.9 GB of archives roughly a dozen times over, which is why a
pass took five to six hours - and, worse, why a pass read a MIXTURE of client
versions, because the launcher patches the archives while the run is going.

This file replaces that chain. It does the whole job in two movements:

    1. SNAPSHOT   copy every data-bearing file out of the live client into
                  work/snapshot/, hashing as it copies. Nothing after this
                  point reads the live client, so the launcher can patch
                  whenever it likes and the run is unaffected. An hour-stale
                  snapshot is FINE and is the point: what matters is that one
                  client version goes in and one dataset comes out.
    2. HARVEST    open each snapshot archive exactly ONCE and, for EVERY live
                  member it names, do ALL of the work for those bytes before
                  moving on - hash it, verify it against the archive's own MD5,
                  measure its header, classify it, stage it. Cross-archive work
                  (chain resolution, variants, the catalog) happens afterwards
                  from what is already in hand, never by re-reading.

                  Every member, not just the ones that win the chain. That is
                  measured, not stylistic: reading winners only shrinks the MD5
                  oracle from all 763,928 of the client's members to 633,197,
                  and loses six PE images that exist solely as non-winning
                  copies. It costs about 30% more decompression and buys "every
                  byte in the client was looked at, once".

WHAT "ONE TRAVERSAL" MEANS HERE, EXACTLY
----------------------------------------
Every archive is opened once and once only, and that single open serves both the
structural pass and the content pass. It is achievable because all 77 archives
are opened up front and held open: an `mpq.Archive` is a file handle plus its
hash and block tables, the union of every path is resolved while they are all
open, and only then does the content pass run - so the winner of a path is known
before a single member is decompressed. 77 file handles and ~0.6 GB of tables
is a trade this machine makes happily against reading 44.9 GB a dozen times.

The claim is checked rather than asserted: every open is counted, and the run
fails loudly at the end if any archive was opened more than once.

DETERMINISM
-----------
No wall-clock time is written into any layer. Everything is sorted. The run's
identity is the per-file sha256 recorded in raw/_snapshot.json. Two runs over
the same snapshot produce byte-identical output.

NO CACHES, NO CONVERGENCE
-------------------------
There is no incremental cache, no resume, no per-archive checkpoint and no
re-read-until-stable logic anywhere in this file. Those existed because a stage
chain could die between stages and because it chased a client that moved under
it. A snapshot removes both problems, so the machinery that managed them is
gone. If the client changed since the snapshot, that is expected: the snapshot's
hashes say which bytes this dataset was built from.

FAILURE
-------
Layers are written into `raw/.staging/` and swapped in only once the whole run
succeeds, so a failed run never leaves a half-written layer behind.
"""
import hashlib
import json
import shutil
import struct
import sys
import time
from collections import Counter
from pathlib import Path

from tools import config, dbcdecode, emit, mpq
from tools.mpq import (MPQ_FILE_COMPRESS, MPQ_FILE_ENCRYPTED, MPQ_FILE_EXISTS,
                       MPQ_FILE_IMPLODE, MPQ_FILE_SECTOR_CRC,
                       MPQ_FILE_SINGLE_UNIT)

SNAPSHOT_DIR = config.WORK_DIR / "snapshot"
STAGING_DIR = config.RAW_DIR / ".staging"
SNAPSHOT_JSON = "_snapshot.json"

# The client's table directory, lowercased with a trailing separator. A LOCATION
# in the archive namespace, not a table name - the one string this file needs in
# order to know where tables live.
TABLE_DIR = "dbfilesclient\\"

# Directories under the client root that are machine state, not client content:
# the user's settings, their screenshots, their crash logs, their installed
# addons' saved variables. They are volatile between launches, so snapshotting
# them would stop a rerun on an unchanged client from reproducing.
INSTALL_STATE_DIRS = {"wtf", "screenshots", "errors", "logs"}

# The ONE thing under the user's AddOns directory that is client content rather
# than the user's own install: Ascension's launcher-managed description of their
# real API surface.
APIDOC_PREFIX = "interface/addons/apidocumentation/"

# The two members every MPQ carries that are not part of its own listfile.
MPQ_META_MEMBERS = ("(listfile)", "(attributes)", "(signature)", "(user data)")

SNAPSHOT_RULE = (
    "Every byte this dataset is built from was copied out of the live client "
    "into work/snapshot/ before any extraction began, and every layer after "
    "that point read the snapshot and never the client. The launcher patches "
    "the archives roughly hourly; without this the run would read a mixture of "
    "client versions and no layer could be said to describe any one of them. "
    "The snapshot being minutes or hours behind the live client is expected and "
    "harmless - what matters is that ONE client version goes in and ONE dataset "
    "comes out. The sha256 recorded here per file is this dataset's identity; "
    "an archive whose hash differs from the client's today simply means the "
    "client moved on, which is a fact about the client and not a defect in the "
    "dataset."
)

SNAPSHOT_SET_RULE = (
    "Which files are snapshotted is derived mechanically, never from a list of "
    "names: (1) every .MPQ under Data\\, Data\\enUS\\ and each realm directory "
    "(a Data\\ subdirectory carrying its own `listarchive`); (2) every loose "
    "non-archive file under Data\\; (3) every file at the client ROOT whose "
    "root-relative path is also carried by the MPQ chain, because a 3.3.5 "
    "client reads <root>\\<path> before it opens any archive and those files "
    "therefore beat the whole chain; (4) Cache\\WDB, the server's own cached "
    "answers; (5) every PE image in the client root, found by reading the bytes "
    "rather than by extension. Machine state - WTF, Screenshots, Errors, Logs "
    "and the user's installed AddOns - is deliberately excluded: it is not "
    "client content and it changes between launches, which would break "
    "reproducibility."
)

# What a non-`ok` read MEANS, in the archive's own terms. A caller that lumps
# these together reports MPQ SEMANTICS as damage - which is how a patch
# tombstone once came to be recorded as a read failure in the table layer.
STATUS_REASON = {
    "deleted": ("an MPQ DELETE_MARKER tombstone: this archive REMOVES the path "
                "at its layer and the entry carries no bytes by design. Archive "
                "semantics, not a failed read - see raw/recovered/deleted/"),
    "empty": ("the archive records this member as zero bytes: a real entry that "
              "holds nothing - see raw/recovered/empty/"),
    "missing": "no live hash slot in this archive resolves this name",
}

READ_RULE = (
    "Every member is read by tools/mpq.py, this repo's own MPQ reader, and "
    "never by mpyq. mpyq mis-slices two whole classes of member - one stored "
    "with no sector offset table, and one whose size is an exact multiple of "
    "the sector size - and does it SILENTLY, returning confident wrong bytes. "
    "Reads are additionally checked against the MD5 the archive itself records "
    "for each member in its `(attributes)` block, which is an oracle outside "
    "this code."
)


# ==========================================================================
# small shared helpers
# ==========================================================================
def write_bytes_lf(path: Path, text: str) -> None:
    """UTF-8, LF, no BOM - written as BYTES. Path.write_text() translates \\n to
    the platform's newline, which would make every file this run emits depend on
    the OS that produced it."""
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(text.encode("utf-8"))


def write_json(path: Path, payload) -> None:
    write_bytes_lf(path, json.dumps(payload, indent=1, sort_keys=True,
                                    ensure_ascii=False) + "\n")


def sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def flag_names(flags: int) -> list:
    names = []
    for bit, name in ((MPQ_FILE_IMPLODE, "IMPLODE"), (MPQ_FILE_COMPRESS, "COMPRESS"),
                      (MPQ_FILE_ENCRYPTED, "ENCRYPTED"),
                      (MPQ_FILE_SINGLE_UNIT, "SINGLE_UNIT"),
                      (MPQ_FILE_SECTOR_CRC, "SECTOR_CRC")):
        if flags & bit:
            names.append(name)
    return names


def human(n: float) -> str:
    """Decimal units, because every other number this pipeline prints and every
    figure in the generated READMEs is decimal. Mixing GiB into the summary and
    GB into the README made one run report its own snapshot as both 42.7 and
    45.9 - the same bytes, described two ways, in two files nobody would think
    to reconcile."""
    for unit in ("B", "KB", "MB", "GB", "TB"):
        if abs(n) < 1000 or unit == "TB":
            return f"{n:,.1f} {unit}" if unit != "B" else f"{int(n):,} B"
        n /= 1000
    return f"{n:.1f} TB"


class Progress:
    """One live line per archive, plus a running total. Deliberately plain
    prints: this runs for tens of minutes on a console that may not be a TTY,
    and a progress bar that needs cursor control produces unreadable logs."""

    def __init__(self, total_archives: int, t0: float):
        self.total = total_archives
        self.t0 = t0
        self.n = 0

    def archive(self, aid: str, **facts) -> None:
        self.n += 1
        bits = " ".join(f"{k}={v}" for k, v in facts.items())
        print(f"  [{self.n:2d}/{self.total}] {aid:34s} {bits}"
              f"  [{time.time() - self.t0:7.1f}s]", flush=True)

    def note(self, msg: str) -> None:
        print(f"  {msg}  [{time.time() - self.t0:7.1f}s]", flush=True)


def banner(title: str) -> None:
    print(f"\n{'=' * 78}\n== {title}\n{'=' * 78}", flush=True)


# ==========================================================================
# 1. SNAPSHOT
# ==========================================================================
def chain_rank(path: Path) -> tuple:
    """The 3.3.5 loader order for one archive filename, as a sort key.

    Weakest first: base archives by name, then `patch.mpq`, then patch-<N>
    numerically, then the locale's patch-enUS run, then patch-<LETTER>
    lexicographically. Everything is a property of the NAME and of which
    directory the file sits in, so the order is a pure function of what is on
    disk.

    Kept BYTE-IDENTICAL to the ordering the retired `tools/extract_mpq.py`
    used. This function decides which copy of a path is the one the client
    loads, so changing it silently changes the contents of every layer; it is
    reproduced here rather than improved."""
    name = path.name.lower()
    in_locale = path.parent.name.lower() == "enus"
    if not name.startswith("patch"):
        return (1 if in_locale else 0, name)
    stem = name[:-4]                             # strip ".mpq"
    suffix = stem[6:] if len(stem) > 5 else ""   # after "patch-"
    if suffix == "":
        return (2, name)
    if suffix.isdigit():
        return (3, suffix.zfill(4))
    if in_locale:      # patch-enus < patch-enus-2 < ... < patch-enus-10
        parts = suffix.rsplit("-", 1)
        num = parts[1].zfill(4) if len(parts) == 2 and parts[1].isdigit() else ""
        return (4, num)
    return (5, suffix)                           # letter patches, lexicographic


def discover_archives() -> list:
    """Every .MPQ under Data\\, Data\\enUS\\ and each realm directory, in chain
    order (weakest first, winner last).

    Realm directories are found by their own `listarchive` file and sit ABOVE
    the entire base chain - that is what the running client does, and without
    the leading tier a realm's patch-D.MPQ would sort into the base letter run
    and silently win base files. Realm archives are ordered by their realm's
    declared `listarchive` line order; any .MPQ in a realm directory the
    listarchive does NOT mention is still inventoried, appended after the
    declared ones and flagged, so a file the launcher dropped there cannot go
    unseen."""
    out = []
    for d in (config.CLIENT_DIR / "Data", config.CLIENT_DIR / "Data" / "enUS"):
        if not d.is_dir():
            continue
        for p in sorted(d.iterdir()):
            if p.is_file() and p.suffix.lower() == ".mpq":
                out.append({"path": p, "layer": "locale"
                            if d.name.lower() == "enus" else "base",
                            "realm": None, "declared": True,
                            "rank": (0,) + chain_rank(p)})

    for realm in config.discover_realms():
        rdir = config.CLIENT_DIR / "Data" / realm
        declared = [ln.strip() for ln in (rdir / "listarchive").read_text(
            encoding="utf-8", errors="replace").splitlines() if ln.strip()]
        order = {n.lower(): i for i, n in enumerate(declared)}
        for p in sorted(rdir.iterdir()):
            if not (p.is_file() and p.suffix.lower() == ".mpq"):
                continue
            i = order.get(p.name.lower())
            out.append({"path": p, "layer": "realm", "realm": realm,
                        "declared": i is not None,
                        "rank": (1, realm, "0" if i is not None else "1",
                                 str(i if i is not None else 0).zfill(4),
                                 p.name.lower())})
    out.sort(key=lambda r: (r["rank"][0], [str(x) for x in r["rank"][1:]]))
    return out


def archive_id(path: Path, root: Path) -> str:
    """Dir-qualified archive identity, e.g. 'Data/enUS/patch-enUS.MPQ'. Archive
    BASENAMES are not unique across the client - a realm directory may carry a
    patch-<letter>.MPQ whose name also exists in Data\\ - so the bare name must
    never key a lookup: it would silently attribute one archive's files to
    another."""
    rel = str(path.parent.relative_to(root)).replace("\\", "/")
    return f"{rel}/{path.name}"


def copy_and_hash(src: Path, dst: Path, chunk: int = 8 << 20) -> dict:
    """Copy one file, computing its sha256 from the SAME read. Measured at
    ~1 GB/s on this machine, so the whole 44.9 GB snapshot costs under a
    minute - cheap enough that there is no reason to be clever about it."""
    dst.parent.mkdir(parents=True, exist_ok=True)
    h = hashlib.sha256()
    n = 0
    with open(src, "rb") as fi, open(dst, "wb") as fo:
        while True:
            b = fi.read(chunk)
            if not b:
                break
            h.update(b)
            fo.write(b)
            n += len(b)
    st = src.stat()
    return {"bytes": n, "sha256": h.hexdigest(), "mtime": int(st.st_mtime_ns)}


def snapshot(progress_t0: float, reuse: bool = False) -> dict:
    """Copy every data-bearing file into work/snapshot/ and record what was
    taken. See SNAPSHOT_SET_RULE for how the set is decided.

    Returns the manifest. The snapshot is rebuilt from scratch every run: a
    PARTIALLY refreshed snapshot would be exactly the mixed-version state this
    whole design exists to eliminate, so there is no incremental path here.

    `reuse` is a development flag and nothing else. It re-reads an existing
    snapshot in place instead of re-copying it, which turns a debugging cycle
    from minutes into seconds. It is never the default: `python datamine.py`
    with no arguments always takes a fresh snapshot, because a stale one that
    nobody chose is exactly the failure this design removes."""
    banner("snapshot: copying the client's data-bearing files")
    if not config.CLIENT_DIR.is_dir():
        raise SystemExit(f"FATAL: client not found at {config.CLIENT_DIR}")

    if reuse and SNAPSHOT_DIR.is_dir():
        return _reuse_snapshot(progress_t0)

    if SNAPSHOT_DIR.exists():
        shutil.rmtree(SNAPSHOT_DIR)
    SNAPSHOT_DIR.mkdir(parents=True, exist_ok=True)

    archives = discover_archives()
    if not archives:
        raise SystemExit(f"FATAL: no .MPQ archives under {config.CLIENT_DIR}\\Data")

    prog = Progress(len(archives), progress_t0)
    files = {}
    arch_records = []
    for rec in archives:
        src = rec["path"]
        rel = str(src.relative_to(config.CLIENT_DIR)).replace("\\", "/")
        aid = archive_id(src, config.CLIENT_DIR)
        got = copy_and_hash(src, SNAPSHOT_DIR / rel)
        files[rel] = {"kind": "archive", **got}
        arch_records.append({**rec, "id": aid, "rel": rel,
                             "snapshot": SNAPSHOT_DIR / rel,
                             "sha256": got["sha256"], "bytes": got["bytes"]})
        prog.archive(aid, MB=f"{got['bytes'] / 1e6:.0f}")

    ids = {a["id"] for a in arch_records}
    if len(ids) != len(arch_records):
        raise SystemExit("FATAL: two archives share one dir-qualified id.")
    return {"files": files, "archives": arch_records}


def _reuse_snapshot(progress_t0: float) -> dict:
    """Re-read an existing snapshot from its own provenance file. Development
    only - see snapshot()'s docstring."""
    prov = json.loads((config.RAW_DIR / SNAPSHOT_JSON).read_bytes()
                      .decode("utf-8"))
    files = {k: v for k, v in prov["files"].items()}
    archives = []
    for rec in discover_archives():
        rel = str(rec["path"].relative_to(config.CLIENT_DIR)).replace("\\", "/")
        f = files.get(rel)
        if f is None:
            raise SystemExit(f"FATAL: {rel} is not in the existing snapshot; "
                             f"take a fresh one.")
        archives.append({**rec, "id": archive_id(rec["path"], config.CLIENT_DIR),
                         "rel": rel, "snapshot": SNAPSHOT_DIR / rel,
                         "sha256": f["sha256"], "bytes": f["bytes"]})
    print(f"  REUSING existing snapshot: {len(files):,} files "
          f"[{time.time() - progress_t0:.1f}s]", flush=True)
    return {"files": files, "archives": archives,
            "counts": prov.get("counts", {}),
            # carried through, not re-measured: re-taking it here would read the
            # live client and a reused-snapshot run would stop reproducing the
            # run that took the snapshot
            "onDiskInterfaceTree": prov.get("onDiskInterfaceTree",
                                            {"present": False}),
            "reused": True}


def snapshot_loose(manifest: dict, mpq_paths: set, prog: Progress) -> dict:
    """The non-archive half of the snapshot: loose Data\\ files, the client-root
    files that OVERRIDE an archived path, Cache\\WDB, and the client-root PE
    images. Runs after the archives are scanned because the override rule needs
    to know which paths the chain carries."""
    files = manifest["files"]
    root = config.CLIENT_DIR
    data_root = root / "Data"

    loose = overrides = cache = binaries = apidoc = 0
    for p in sorted(root.rglob("*")):
        if not p.is_file() or p.suffix.lower() == ".mpq":
            continue
        rel_root = str(p.relative_to(root)).replace("\\", "/")
        low = rel_root.lower()
        top = low.split("/", 1)[0]
        if top in INSTALL_STATE_DIRS:
            continue
        # A client-root file can be BOTH an archive override and a PE image -
        # `WowError.exe` is exactly that - so `isPE` is recorded alongside
        # `kind` rather than competing with it. `kind` says why the file is in
        # the snapshot at all and follows the client's own load semantics, so
        # an override stays an override; `isPE` is an independent measurement
        # and is what the binaries layer selects on.
        root_level = "/" not in rel_root
        is_pe = root_level and _looks_like_pe(p)
        kind = None
        if low.startswith("data/"):
            kind = "looseData"
        elif low.startswith("cache/wdb/"):
            kind = "cache"
        elif low.startswith(APIDOC_PREFIX):
            # Ascension's own launcher-managed description of their real API
            # surface. It lives under the user's AddOns directory but it is
            # CLIENT content, not the user's own install - and the Interface
            # code layer takes it verbatim, so it has to be frozen with
            # everything else or that layer would be reading a live tree after
            # the snapshot closed.
            kind = "apiDoc"
        elif low.replace("/", "\\") in mpq_paths:
            # a 3.3.5 client reads <root>\<path> before any archive, so this
            # file BEATS the whole chain - see SNAPSHOT_SET_RULE
            kind = "rootOverride"
        elif is_pe:
            kind = "binary"
        if kind is None:
            continue
        got = copy_and_hash(p, SNAPSHOT_DIR / rel_root)
        files[rel_root] = {"kind": kind, "isPE": is_pe, **got}
        loose += kind == "looseData"
        overrides += kind == "rootOverride"
        cache += kind == "cache"
        apidoc += kind == "apiDoc"
        binaries += is_pe

    prog.note(f"loose Data\\ files={loose}  client-root overrides={overrides}  "
              f"Cache\\WDB files={cache}  APIDocumentation files={apidoc}  "
              f"PE images={binaries}")
    manifest["counts"] = {"looseData": loose, "rootOverride": overrides,
                          "cache": cache, "apiDoc": apidoc, "binary": binaries}
    manifest["onDiskInterfaceTree"] = _on_disk_interface_census()
    return manifest


def _on_disk_interface_census() -> dict:
    """Count - never extract - the user's live `Interface\\` tree, so the scope
    boundary is a visible number rather than an unstated omission.

    Measured HERE, during the snapshot, and carried in the manifest. It is the
    one fact the layers report about something deliberately NOT snapshotted, and
    taking it later would mean a layer reading the live client after the
    snapshot closed - which breaks both the single-version guarantee and the
    byte-for-byte rerun, since the user's addons change under it."""
    root = config.CLIENT_DIR / "Interface"
    if not root.is_dir():
        return {"present": False}
    files = [p for p in root.rglob("*") if p.is_file()]
    addons = sorted(p.name for p in (root / "AddOns").iterdir() if p.is_dir()) \
        if (root / "AddOns").is_dir() else []
    return {"present": True, "root": str(root), "fileCount": len(files),
            "bytes": sum(p.stat().st_size for p in files),
            "addonDirs": addons, "addonDirCount": len(addons),
            "takenFromHere": ["AddOns/APIDocumentation"],
            "note": "Third-party addons the user installed. Not client data, "
                    "so not extracted; counted here so the boundary is "
                    "auditable. AddOns/APIDocumentation is the sole exception "
                    "and IS snapshotted, because it is Ascension's own "
                    "launcher-managed description of their API."}


def _looks_like_pe(p: Path) -> bool:
    """A PE image, decided by reading the bytes rather than by extension.
    e_lfanew is a file offset and nothing caps it, so a DOS stub longer than the
    first window would make a real PE look like it is not one - the whole file
    is read in that case rather than answering from a short read."""
    from tools import pe
    try:
        with open(p, "rb") as f:
            head = f.read(0x1000)
            if head[:2] != b"MZ":
                return False
            if not pe.is_pe(head) and len(head) >= 0x40:
                f.seek(0)
                head = f.read()
        return pe.is_pe(head)
    except OSError:
        return False


# ==========================================================================
# 2. HARVEST - the one traversal
# ==========================================================================
class Harvest:
    """Everything the single pass over the snapshot produced, in memory.

    This object is the whole reason the pipeline collapsed: it is what makes
    the later layers derivable WITHOUT re-reading a single archive. Anything a
    layer needs from archive bytes is put here as those bytes go past, once."""

    def __init__(self):
        self.archives = []        # per-archive census records, chain order
        self.carriers = {}        # lowercased path -> winner/losers/entry
        self.copies = {}          # lowercased table path -> every carrier
        self.opens = Counter()    # archive id -> times opened (must all be 1)
        self.table_bytes = {}     # (path, archive) -> staged .dbc file
        self.table_misses = {}    # (path, archive) -> why that copy has no bytes
        self.interface = {}       # lowercased Interface path -> record + bytes
        self.pe_members = {}      # sha256 -> archived PE image facts + bytes
        self.attributes = {}      # archive id -> per-member CRC32/MD5/mtime
        self.md5 = {"checked": 0, "ok": 0, "mismatch": 0, "noRecord": 0,
                    "mismatches": []}
        self.tombstones = []      # DELETE_MARKER entries, per archive
        self.empties = []         # genuinely zero-length members
        self.containers = []      # nested archives / RAR / bplist members
        self.read_errors = Counter()
        self.bytes_read = 0

    def release(self) -> None:
        """Drop everything only the traversal needed.

        The harvest is ~2 GB - 637k path records, 77 archives' block/hash
        tables, and the per-member CRC32/MD5/mtime arrays - and the LAST thing
        the run does is build the join catalog, which reads the decoded table
        layer off disk and needs none of it.

        Stated at the strength the evidence supports. Holding both at once made
        the catalog fail REPRODUCIBLY (twice, at the same point) with
        `TypeError: 'generator' object is not callable` on a line whose object
        is `set.add` and provably cannot be a generator; the identical code over
        the identical files in a fresh process completed all 368 tables. The
        differentiator is memory - this process held the harvest while the
        catalog built id-space sets over 7.5M rows, on a host with ~9 GB of
        commit headroom. The mechanism inside the interpreter was NOT isolated,
        so it is not asserted here. What is established: the failure is real,
        it is memory-related, and freeing what the run has finished with removes
        it. That is also the right shape independently - a disk-based analysis
        should not be competing for memory with a traversal that is over."""
        for s in self.archives:
            s["entries"] = {}
            s["attributes"] = None
        self.carriers.clear()
        self.copies.clear()
        self.table_bytes.clear()
        self.table_misses.clear()
        self.interface.clear()
        self.pe_members.clear()
        self.attributes.clear()
        self.tombstones.clear()
        self.empties.clear()


def open_all(arch_records: list, prog: Progress) -> list:
    """Open every snapshot archive ONCE and read its structure.

    They are all held open together on purpose. The winner of a path cannot be
    known until every archive's listfile has been seen, and reading a member
    before its winner is known would mean either decompressing losers for
    nothing or coming back for a second open. Holding 77 file handles and their
    hash/block tables costs well under a gigabyte on a machine with 64, which is
    a trade worth making against a dozen 44.9 GB traversals."""
    out = []
    for rec in arch_records:
        p = rec["snapshot"]
        entry = {**rec, "listable": False, "unlistableReason": None,
                 "openError": None, "archive": None, "entries": {},
                 "metaMembers": [], "attributes": None}
        try:
            a = mpq.Archive(p)
        except Exception as e:                        # noqa: BLE001 - recorded
            entry["openError"] = f"{type(e).__name__}: {e}"
            entry.update({"fileCount": 0, "blockExistsCount": 0,
                          "unnamedCount": 0})
            out.append(entry)
            prog.archive(rec["id"], OPEN="FAILED")
            continue
        entry["archive"] = a
        exists = [b for b in a.block_table if b[3] & MPQ_FILE_EXISTS]
        entry.update({
            "formatVersion": a.header["format_version"],
            "hashTableEntries": a.header["hash_table_entries"],
            "blockTableEntries": a.header["block_table_entries"],
            "hashSlotsUsed": sum(1 for e in a.hash_table
                                 if e[4] < mpq.HASH_DELETED),
            "hashSlotsDeleteMarked": sum(1 for e in a.hash_table
                                         if e[4] == mpq.HASH_DELETED),
            "blockExistsCount": len(exists),
            "blockEncryptedCount": sum(1 for b in exists
                                       if b[3] & MPQ_FILE_ENCRYPTED),
            "uncompressedBytes": sum(b[2] for b in exists),
        })
        names = a.list_names()
        entry["metaMembers"] = [m for m in MPQ_META_MEMBERS
                                if a.block_index_of(m) is not None]
        if names is None:
            entry["unlistableReason"] = "no readable (listfile) member"
            entry["fileCount"] = 0
            entry["unnamedCount"] = len(exists) - len(entry["metaMembers"])
            out.append(entry)
            prog.archive(rec["id"], listable="no", live=len(exists))
            continue

        entry["listable"] = True
        entries, unresolved = {}, []
        for stored in names:
            if not stored:
                continue
            bi = a.block_index_of(stored)
            if bi is None or bi >= len(a.block_table):
                unresolved.append(stored)
                continue
            b = a.block_table[bi]
            if not (b[3] & MPQ_FILE_EXISTS):
                unresolved.append(stored)
                continue
            entries[stored.lower()] = {"stored": stored, "size": b[2],
                                       "storedBytes": b[1], "flags": b[3],
                                       "block": bi}
        entry["entries"] = entries
        entry["fileCount"] = len(entries)
        entry["listfileLines"] = len(names)
        entry["listfileUnresolved"] = sorted(unresolved)[:64]
        entry["listfileUnresolvedCount"] = len(unresolved)
        entry["unnamedCount"] = (len(exists) - len(entries)
                                 - len(entry["metaMembers"]))
        out.append(entry)
        prog.archive(rec["id"], files=len(entries), live=len(exists))
    return out


def resolve_union(scans: list) -> tuple:
    """The winner of every path, and every carrier of every table path.

    An archive's strength is its POSITION in `scans`, which is already sorted
    weakest-first by loader order, so comparing positions is comparing chain
    ranks without re-deriving how that order is computed."""
    carriers, copies = {}, {}
    for rank, s in enumerate(scans):
        aid = s["id"]
        for low, e in s["entries"].items():
            cur = carriers.get(low)
            if cur is None:
                carriers[low] = {"e": e, "rank": rank, "winner": aid,
                                 "losers": []}
            elif rank > cur["rank"]:
                cur["losers"].append(cur["winner"])
                cur.update({"e": e, "rank": rank, "winner": aid})
            else:
                cur["losers"].append(aid)
            if low.startswith(TABLE_DIR):
                c = copies.setdefault(low, {"path": low, "stored": e["stored"],
                                            "copies": []})
                # archives disagree about the CASE of a stored path; the walk is
                # weakest-first, so overwriting leaves the winner's spelling
                c["stored"] = e["stored"]
                c["copies"].append({"archive": aid, "chainRank": rank})
    return carriers, copies


def probe_unlistable(scans: list, carriers: dict, prog: Progress) -> dict:
    """Characterise the archives with no readable listfile by probing their hash
    tables for EVERY path name the listable archives revealed.

    Not a wanted list - the full harvested union. The (hash_a, hash_b) pair for
    a name is archive-independent, so the expensive part is computed once and
    reused across every probed archive. `unidentifiedLiveEntries` is the honest
    residual: live members whose name no harvested path matched."""
    unl = [s for s in scans if not s["listable"] and s["archive"] is not None]
    if not unl:
        return {}
    names = sorted(carriers) + list(MPQ_META_MEMBERS)
    keys = [(n, mpq.hash_string(n, mpq.HASH_NAME_A),
             mpq.hash_string(n, mpq.HASH_NAME_B)) for n in names]
    prog.note(f"probing {len(unl)} unlistable archive(s) against {len(keys)} "
              f"harvested names")
    probe = {}
    for s in unl:
        a = s["archive"]
        idx = a.index
        hits = [n for n, ha, hb in keys
                if idx.get((ha, hb)) is not None
                and a.block_table[idx[(ha, hb)]][3] & MPQ_FILE_EXISTS]
        live = sum(1 for b in a.block_table if b[3] & MPQ_FILE_EXISTS)
        probe[s["id"]] = {
            "probedCount": len(keys), "hits": sorted(hits),
            "liveBlockEntries": live,
            "unidentifiedLiveEntries": live - len(hits),
            "deleteMarkedHashSlots": s.get("hashSlotsDeleteMarked"),
        }
    return probe


def harvest(scans: list, carriers: dict, copies: dict, staging: Path,
            prog: Progress) -> Harvest:
    """THE traversal. One pass per archive; for every member whose bytes are
    needed, every job that wants those bytes runs before the next member.

    The jobs, all fed by ONE decompression of each member:
      * sha256 for the file census
      * MD5 against the archive's own `(attributes)` oracle
      * WDBC header facts for anything under the table directory
      * staging the bytes of every table copy (winner AND variant)
      * text/binary classification and text bytes for the Interface tree
      * PE-image detection for the binaries layer
      * container detection for the recovery layer
      * DELETE_MARKER and zero-length member semantics
    """
    h = Harvest()
    h.archives = scans
    h.carriers = carriers
    h.copies = copies

    tables_dir = staging / "tables"
    iface_dir = staging / "interface"
    for d in (tables_dir, iface_dir):
        d.mkdir(parents=True, exist_ok=True)

    for rank, s in enumerate(scans):
        a = s["archive"]
        if a is None:
            continue
        h.opens[s["id"]] += 1
        s["attributes"] = attrs = _read_attributes(a)
        if attrs:
            h.attributes[s["id"]] = attrs

        # EVERY live member this archive names, not just the ones it wins.
        #
        # Reading only the winners is the tempting optimisation and it is wrong
        # in three places at once, each measured rather than guessed: the MD5
        # oracle then covers 633k of the client's 764k members instead of all of
        # them; six PE images that exist only as non-winning copies disappear
        # from the binaries layer entirely; and a nested container carried only
        # by a loser goes unseen. The extra cost is about 30% more decompression
        # on a pass that already dominates the run, which is a price worth
        # paying for "every byte in the client was looked at once".
        n_hashed = n_tables = n_iface = n_pe = 0
        for low in sorted(s["entries"]):
            e = s["entries"][low]
            stored = e["stored"]
            try:
                m = a.read(stored)
            except Exception as ex:                   # noqa: BLE001 - recorded
                _record_error(h, carriers, low, s["id"],
                              f"{type(ex).__name__}: {ex}", "error")
                continue
            data = m.data
            if not (m.ok or (m.status == "empty" and data is not None)):
                # A tombstone or an empty member is NOT recorded as a tombstone
                # or an empty HERE: the block-table sweep below enumerates both
                # completely, including entries no listfile still names, and
                # recording them in both places would double-count them.
                _record_error(h, carriers, low, s["id"],
                              f"{m.status}: {m.detail}", m.status)
                if low in copies:
                    # a table copy with no bytes still has to say WHY in the
                    # table layer's own failure list, in the archive's terms
                    h.table_misses[(low, s["id"])] = {
                        "status": m.status, "reason": STATUS_REASON.get(
                            m.status, m.detail
                            or f"read failed with status {m.status!r}")}
                continue

            h.bytes_read += len(data)
            digest = sha256_bytes(data)
            n_hashed += 1

            # --- census facts, but only for the copy that WINS this path ---
            c = carriers.get(low)
            if c is not None and c["winner"] == s["id"]:
                rec = {"sha256": digest, "readBytes": len(data)}
                if m.status != "ok":
                    rec["memberStatus"] = m.status
                if low.startswith(TABLE_DIR) and len(data) >= 20:
                    magic, nrec, nfld, rsz, ssz = struct.unpack_from(
                        "<4s4I", data, 0)
                    rec["dbc"] = {"magic": magic.decode("latin-1"),
                                  "records": nrec, "declaredFields": nfld,
                                  "recordSize": rsz, "stringBlockSize": ssz,
                                  "actualFields": rsz // 4}
                c["e"].update(rec)

            # --- MD5 against the archive's own oracle ---
            _verify_md5(h, attrs, e["block"], s["id"], stored, data)

            # --- table bytes: staged for the decode, winner and variant alike --
            if low in copies:
                dest = tables_dir / _slug(s["id"]) / stored.rsplit("\\", 1)[-1]
                dest.parent.mkdir(parents=True, exist_ok=True)
                dest.write_bytes(data)
                h.table_bytes[(low, s["id"])] = {
                    "file": dest, "sha256": digest,
                    **dbcdecode.header_facts(data)}
                n_tables += 1

            # --- Interface: classify, and keep the bytes when it is text ---
            if low.startswith("interface\\") and c is not None \
                    and c["winner"] == s["id"]:
                cls = emit.classify_text(data)
                info = {"isText": cls["isText"], "encoding": cls["encoding"],
                        "hasNul": cls["hasNul"],
                        "controlBytes": cls["controlBytes"]}
                if cls["isText"]:
                    dest = iface_dir / low.replace("\\", "/")
                    dest.parent.mkdir(parents=True, exist_ok=True)
                    dest.write_bytes(data)
                    info["staged"] = dest
                h.interface[low] = info
                n_iface += 1

            # --- PE images stored inside archives ---
            if data[:2] == b"MZ":
                from tools import pe
                if pe.is_pe(data):
                    v = h.pe_members.setdefault(digest, {
                        "sha256": digest, "bytes": len(data), "carriers": []})
                    if "file" not in v:
                        dest = staging / "pe" / f"{digest[:16]}.bin"
                        dest.parent.mkdir(parents=True, exist_ok=True)
                        dest.write_bytes(data)
                        v["file"] = dest
                    v["carriers"].append({
                        "archive": s["id"], "chainRank": rank,
                        "path": stored.replace("\\", "/")})
                    n_pe += 1

            # --- nested containers, for the recovery layer ---
            # The bytes are STAGED, not just noted: expanding a container needs
            # them, and coming back for them later would mean opening this
            # archive a second time.
            kind = emit.sniff_container(data)
            if kind:
                dest = staging / "containers" / _slug(s["id"]) / _slug(stored)
                dest.parent.mkdir(parents=True, exist_ok=True)
                dest.write_bytes(data)
                h.containers.append({"archive": s["id"],
                                     "path": stored.replace("\\", "/"),
                                     "kind": kind, "bytes": len(data),
                                     "sha256": digest, "_staged": str(dest)})
            del data

        # every block entry this archive marks as a patch tombstone, whether or
        # not the listfile still names it - real archive semantics, not damage
        _sweep_block_semantics(h, s)
        a.close()
        s["archive"] = None
        prog.archive(s["id"], hashed=n_hashed, tables=n_tables,
                     iface=n_iface, pe=n_pe,
                     read=f"{h.bytes_read / 1e9:.1f}GB")
    return h


def _slug(text: str) -> str:
    import re
    return re.sub(r"[^a-z0-9]+", "-", text.lower()).strip("-")


def _record_error(h: Harvest, carriers: dict, low: str, aid: str,
                  detail: str, status: str) -> None:
    c = carriers.get(low)
    if c is not None and c["winner"] == aid:
        c["e"].update({"readError": detail, "memberStatus": status,
                       "sha256": None})
    h.read_errors[f"{status}: {detail[:60]}"] += 1


def _read_attributes(a) -> dict:
    """The per-member CRC32 + MD5 + mtime the archive records about itself.
    This is the oracle every read here is checked against, and it is not another
    reader - it is the archive's own claim about its own bytes."""
    try:
        return a.attributes() or {}
    except Exception:                                 # noqa: BLE001 - optional
        return {}


def _verify_md5(h: Harvest, attrs: dict, block: int, aid: str, stored: str,
                data: bytes) -> None:
    """`(attributes)` is an array PARALLEL TO THE BLOCK TABLE, so the member's
    own block index is the subscript. `md5` holds raw 16-byte digests, not hex,
    and an archive that records no MD5 at all yields None here - which is a fact
    about that archive, counted, never treated as a mismatch."""
    md5s = (attrs or {}).get("md5")
    if not md5s or block >= len(md5s):
        h.md5["noRecord"] += 1
        return
    want = md5s[block]
    if not want or want == b"\0" * 16:
        h.md5["noRecord"] += 1
        return
    h.md5["checked"] += 1
    got = hashlib.md5(data).digest()
    if got == want:
        h.md5["ok"] += 1
    else:
        h.md5["mismatch"] += 1
        if len(h.md5["mismatches"]) < 64:
            h.md5["mismatches"].append({"archive": aid, "path": stored,
                                        "archiveMd5": want.hex(),
                                        "readMd5": got.hex()})


def _sweep_block_semantics(h: Harvest, s: dict) -> None:
    """DELETE_MARKER tombstones and zero-length members read straight off the
    block table, so a path a patch REMOVES is recorded as the archive semantic
    it is rather than as a failed read."""
    a = s["archive"]
    if a is None:
        return
    by_block = {e["block"]: e["stored"] for e in s["entries"].values()}
    for i, b in enumerate(a.block_table):
        flags = b[3]
        if not flags & MPQ_FILE_EXISTS:
            continue
        if flags & mpq.MPQ_FILE_DELETE_MARKER:
            h.tombstones.append({"archive": s["id"], "block": i,
                                 "path": by_block.get(i)})
        elif b[2] == 0 or b[1] == 0:
            h.empties.append({"archive": s["id"], "block": i,
                              "path": by_block.get(i)})


# ==========================================================================
# 3. DRIVER
# ==========================================================================
def main(argv=None) -> int:
    argv = sys.argv[1:] if argv is None else argv
    reuse = "--reuse-snapshot" in argv
    t0 = time.time()
    print(f"client:   {config.CLIENT_DIR}")
    print(f"repo:     {config.REPO_ROOT}")
    print(f"snapshot: {SNAPSHOT_DIR}")

    # ---- 1. snapshot ------------------------------------------------------
    t_snap = time.time()
    manifest = snapshot(t0, reuse=reuse)
    snap_archives = time.time() - t_snap

    banner("snapshot: opening every archive once")
    prog = Progress(len(manifest["archives"]), t0)
    scans = open_all(manifest["archives"], prog)
    carriers, copies = resolve_union(scans)
    prog.note(f"union: {len(carriers):,} paths, {len(copies)} table paths, "
              f"{sum(len(c['copies']) for c in copies.values())} table copies")

    if not manifest.get("reused"):
        manifest = snapshot_loose(manifest, set(carriers), prog)
    probe = probe_unlistable(scans, carriers, prog)
    snap_secs = time.time() - t_snap

    write_json(config.RAW_DIR / SNAPSHOT_JSON, {
        "note": "The exact bytes this dataset was built from.",
        "snapshotRule": SNAPSHOT_RULE,
        "snapshotSetRule": SNAPSHOT_SET_RULE,
        "clientDir": str(config.CLIENT_DIR),
        "snapshotDir": str(SNAPSHOT_DIR),
        "fileCount": len(manifest["files"]),
        "totalBytes": sum(f["bytes"] for f in manifest["files"].values()),
        "counts": manifest["counts"],
        "onDiskInterfaceTree": manifest.get("onDiskInterfaceTree",
                                            {"present": False}),
        "files": {k: manifest["files"][k] for k in sorted(manifest["files"])},
    })

    # ---- 2. harvest -------------------------------------------------------
    banner("harvest: one pass over each archive")
    t_ext = time.time()
    staging_work = config.WORK_DIR / "harvest"
    if staging_work.exists():
        shutil.rmtree(staging_work)
    staging_work.mkdir(parents=True, exist_ok=True)
    prog = Progress(len(scans), t0)
    h = harvest(scans, carriers, copies, staging_work, prog)

    # counted BEFORE the layers run, because emit_all frees the harvest on its
    # way to the catalog (see Harvest.release) and the summary would otherwise
    # report zero for work that plainly happened
    members_read = sum(1 for c in carriers.values() if c["e"].get("sha256"))

    reopened = {k: v for k, v in h.opens.items() if v != 1}
    if reopened:
        raise SystemExit(f"FATAL: {len(reopened)} archive(s) were opened more "
                         f"than once: {reopened}. The single-traversal "
                         f"guarantee is broken; refusing to report the run as "
                         f"one pass.")

    # ---- 3. emit ----------------------------------------------------------
    if STAGING_DIR.exists():
        shutil.rmtree(STAGING_DIR)
    STAGING_DIR.mkdir(parents=True, exist_ok=True)

    layers = emit.emit_all(h, manifest, probe, STAGING_DIR, staging_work,
                           SNAPSHOT_DIR, t0)

    # ---- 4. swap ----------------------------------------------------------
    banner("publishing")
    emit.publish(STAGING_DIR, config.RAW_DIR, layers)
    ext_secs = time.time() - t_ext

    # ---- 5. summary -------------------------------------------------------
    banner("summary")
    total = time.time() - t0
    snap_bytes = sum(f["bytes"] for f in manifest["files"].values())
    print(f"  archives traversed   {len(scans)} (each opened exactly once)")
    print(f"  snapshot             {len(manifest['files']):,} files, "
          f"{human(snap_bytes)}  [{snap_secs:.1f}s, "
          f"{snap_archives:.1f}s of it archives]")
    print(f"  members read         {members_read:,}")
    print(f"  bytes decompressed   {human(h.bytes_read)}")
    print(f"  md5 vs archive       checked={h.md5['checked']:,} "
          f"ok={h.md5['ok']:,} mismatch={h.md5['mismatch']}")
    for name, facts in layers.items():
        bits = ", ".join(f"{k}={v:,}" if isinstance(v, int) else f"{k}={v}"
                         for k, v in facts.items() if not k.startswith("_"))
        print(f"  {name:20s} {bits}")
    print(f"\n  WALL CLOCK           {total / 60:.1f} min "
          f"({total:.0f}s)   snapshot {snap_secs:.0f}s  |  "
          f"extract {ext_secs:.0f}s")
    return 0


if __name__ == "__main__":
    sys.exit(main())
