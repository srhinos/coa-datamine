"""Complete, mechanical inventory of everything extractable from the Ascension client.

This is the census the raw extractor consumes. It answers, from the client bytes
alone and with no human judgment encoded anywhere:

  * which MPQ archives exist, in what chain order, and which of them can be listed;
  * every file path in the union of those archives, and which archive WINS it;
  * for each winning path: uncompressed size, stored size, MPQ flags, and (unless
    --skip-content-hash) the sha256 of the decompressed bytes;
  * the loose (non-MPQ) files sitting in Data\\ - Content JSON, the enUS Interface
    tree, realm listarchive files;
  * the loose files ABOVE Data\\, at the client root, that OVERRIDE an archived
    path - the client reads `<root>\\<path>` before it reads the MPQ chain, so
    those files, not the archive copies, are what it loads (see
    LOOSE_OVERRIDE_RULE);
  * how much the full raw extraction would weigh, per class.

NON-NEGOTIABLES this module is built to satisfy
-----------------------------------------------
COMPLETE      Nothing is filtered. There is no wanted-list here. Every path in
              every listable archive is recorded, and the unlistable archives are
              characterized by block-table census + hash-table probe rather than
              being skipped. A file this module cannot READ is recorded with
              readable=false and its error - never silently dropped, because a
              silent drop is exactly the failure mode being fixed.
MECHANICAL    Every field is measured. Sizes come from the MPQ block table, not
              from a table of expectations. The `class` rollup (dbc/interface/
              content-json/sound/art/other) is the ONLY derived label in the
              output; it is a REPORTING rollup over the raw per-extension and
              per-top-level-directory censuses that sit beside it in the same
              file, it is re-derivable from those, and - critically - it never
              gates what gets recorded or extracted.
RERUNNABLE    `python -m tools.inventory`. No arguments needed, no agent, no
              manual step. Output is byte-identical across runs on an unchanged
              client: everything is sorted, and no wall-clock time is written.
              The client's identity is captured as the per-archive sha256, which
              is a better provenance stamp than a timestamp anyway.
LLM-SEARCHABLE Per-path records are sharded by PATH PREFIX (see partition()) into
              a flat, greppable directory, capped at SHARD_MAX lines per file,
              with raw/_inventory/files.json as the index an agent reads first.

Chain order reuses tools/extract_mpq.chain_rank (the 3.3.5 loader order) and
extends it with a leading LAYER tier, because realm directories (Data\\<realm>\\,
discovered by their `listarchive` file) are a server-side overlay that sits above
the whole base chain - the convention tools/extract_realms.py already established.
Without that tier, area-52's patch-D.MPQ would sort into the base letter-patch
run between patch-C and patch-E and silently win base files.
"""
import argparse
import hashlib
import json
import os
import struct
import sys
import time
from pathlib import Path

from mpyq import (MPQArchive, MPQ_FILE_EXISTS, MPQ_FILE_ENCRYPTED,
                  MPQ_FILE_SINGLE_UNIT, MPQ_FILE_COMPRESS, MPQ_FILE_IMPLODE,
                  MPQ_FILE_SECTOR_CRC)

from tools import config, layerstate, probe_unlistable
from tools.extract_mpq import chain_rank

INV_DIR = config.RAW_DIR / "_inventory"
FILES_DIR = INV_DIR / "files"
SHARD_MAX = 5000            # Amendment C line cap, per shard file

# Per-archive checkpoints. NOT part of the output: these live under work/
# (gitignored) and hold nothing that is not re-derivable from the client.
HASH_CACHE_DIR = config.WORK_DIR / "inventory_hashes"
SCAN_CACHE_DIR = config.WORK_DIR / "inventory_scan"

SCAN_CACHE_RULE = (
    "Pass 1 opens all 77 archives, hashes each one whole (about 30 GB of reads) "
    "and enumerates its listfile against its block table. It is checkpointed per "
    "archive into work/inventory_scan/, keyed by the archive file's SIZE and "
    "modification time, with the sha256 it computed stored inside. A client "
    "patch rewrites the file and moves its mtime, which invalidates the entry; "
    "`--rescan` ignores the checkpoints entirely and re-reads every archive, "
    "which is the way to prove a run from the bytes alone. Unlike the pass-4 "
    "checkpoint this key is not the content hash - computing the content hash IS "
    "the cost being avoided - so it is a stat-based assumption and is called one "
    "here rather than left implicit.")

HASH_CACHE_RULE = (
    "Pass 4 decompresses and hashes every winning file in the chain - 637k "
    "files and ~62 GB - and it is the only pass long enough that finishing it "
    "in one process is a real assumption rather than a formality. It is "
    "therefore checkpointed PER ARCHIVE into work/inventory_hashes/, keyed by "
    "the archive's own sha256: an archive whose checkpoint matches its current "
    "sha256 is not re-read, so a run interrupted anywhere resumes instead of "
    "starting over, and repeated runs converge. This changes NOTHING about the "
    "output - the same client produces the same census with an empty cache or a "
    "full one, because the key is the archive's content hash and a changed "
    "archive invalidates its own checkpoint. Delete the directory to force a "
    "full re-read.")

# The `winner` of a path a loose file on disk takes from the archives. Not an
# archive id, and it cannot collide with one (archive ids are `<dir>/<name>.MPQ`).
DISK_WINNER = "<disk>"

LOOSE_OVERRIDE_RULE = (
    "A 3.3.5 client resolves `<clientRoot>\\<path>` on disk BEFORE it looks in "
    "the MPQ chain, so a loose file at the client root beats every archive that "
    "carries the same path - which is how this client ships its own ChatBubble "
    "textures and its silenced Fizzle sounds. The census therefore walks the "
    "whole client root, and a loose file whose root-relative path is also an MPQ "
    "path WINS that path: `source` becomes `loose`, `winner` becomes "
    f"`{DISK_WINNER}`, `size`/`sha256` are the file's own, and the archive copy "
    "it displaced is preserved under `overrides` so nothing is lost. Which loose "
    "files are recorded is decided mechanically, by two conditions and no list "
    "of names: a loose file is recorded if (1) it lives under `Data\\` - the "
    "client's data directory, already covered before this rule existed - or (2) "
    "its root-relative path is carried by the MPQ chain, which is what makes it "
    "an override at all. Everything else on the disk (the user's installed "
    "AddOns, WTF settings, Logs, Screenshots, the WDB caches that raw/cache owns) "
    "is machine state rather than client content, is not in the archive "
    "namespace, and is deliberately outside this census - it is also volatile "
    "between launches, so recording it would make a rerun on an unchanged client "
    "stop reproducing. `.MPQ` files themselves are skipped here because they are "
    "inventoried as archives, with their members as paths.")

# MPQ hash-table sentinels: 0xFFFFFFFF = slot never used, 0xFFFFFFFE = file
# deleted (slot kept alive so probe chains still terminate correctly).
HASH_EMPTY = 0xFFFFFFFF
HASH_DELETED = 0xFFFFFFFE

# The two members every MPQ carries that are not part of its own listfile. They
# are archive metadata, not client content; counted separately so "listfile count
# vs block-table EXISTS count" reconciles to zero unnamed files instead of to 2.
MPQ_META_MEMBERS = ("(listfile)", "(attributes)", "(signature)", "(user data)")

# Class rollup (see module docstring - reporting only, gates nothing). The
# per-extension and per-top-level-directory censuses emitted alongside are the
# ground truth. `content` is keyed on LOCATION (the loose Data\Content tree) as
# well as the .json extension on purpose: that tree also holds 64 .loc
# localization files, and an extension-only rule would have buried real content
# data in "other".
_SOUND_EXT = {"mp3", "wav", "ogg", "wfx"}
_ART_EXT = {"blp", "m2", "skin", "anim", "wmo", "adt", "wdt", "wdl", "bls",
            "tga", "jpg", "jpeg", "png", "gif", "bone", "tex", "mdx", "avi",
            "ttf", "icns", "zmp"}


# --------------------------------------------------------------------------
# archive discovery + chain order
# --------------------------------------------------------------------------

def discover_archives() -> list:
    """Every .MPQ under Data\\, Data\\enUS\\ and each Data\\<realm>\\, in chain
    order (weakest first, winner last). Returns dicts carrying the layer and the
    sort key so callers never have to recompute either.

    Realm archives are ordered by their realm's own `listarchive` line order -
    the realm's declared chain - and any .MPQ in a realm dir that the listarchive
    does NOT mention is still inventoried, appended after the declared ones and
    flagged, so a file the launcher dropped there cannot go unseen."""
    out = []
    for d in config.MPQ_DIRS:
        if not d.is_dir():
            continue
        for p in sorted(d.iterdir()):
            if p.is_file() and p.suffix.lower() == ".mpq":
                out.append({"path": p, "layer": "locale" if d.name.lower() == "enus"
                            else "base", "realm": None, "declared": True,
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
                        # undeclared archives sort after declared ones, never
                        # interleaved with them, and are flagged in the output
                        "rank": (1, realm, "0" if i is not None else "1",
                                 str(i if i is not None else 0).zfill(4), p.name.lower())})
    out.sort(key=lambda r: (r["rank"][0], [str(x) for x in r["rank"][1:]]))
    return out


def archive_id(path: Path) -> str:
    """Dir-qualified archive identity, e.g. 'Data/enUS/patch-enUS.MPQ'. Archive
    BASENAMES are not unique across the client (a realm dir may carry a
    patch-<letter>.MPQ whose name also exists in Data\\), so the bare name must
    never be used as a lookup key - it would silently attribute one archive's
    files to another."""
    rel = str(path.parent.relative_to(config.CLIENT_DIR)).replace("\\", "/")
    return f"{rel}/{path.name}"


def sha256_file(path: Path, chunk: int = 8 << 20) -> str:
    h = hashlib.sha256()
    with open(path, "rb") as f:
        while True:
            b = f.read(chunk)
            if not b:
                break
            h.update(b)
    return h.hexdigest()


def flag_names(flags: int) -> list:
    names = []
    for bit, name in ((MPQ_FILE_IMPLODE, "IMPLODE"), (MPQ_FILE_COMPRESS, "COMPRESS"),
                      (MPQ_FILE_ENCRYPTED, "ENCRYPTED"), (MPQ_FILE_SINGLE_UNIT, "SINGLE_UNIT"),
                      (MPQ_FILE_SECTOR_CRC, "SECTOR_CRC")):
        if flags & bit:
            names.append(name)
    return names


def _scan_cache_file(archive_id_str: str) -> Path:
    stem = "".join(c if c.isalnum() or c in "-_" else "-"
                   for c in archive_id_str.lower())
    return SCAN_CACHE_DIR / f"{stem}.json"


def _scan_key(p: Path) -> list:
    st = p.stat()
    return [st.st_size, st.st_mtime_ns]


def scan_archive_cached(rec: dict, use_cache: bool = True) -> tuple:
    """scan_archive() with a per-archive checkpoint. See SCAN_CACHE_RULE."""
    p = rec["path"]
    aid = archive_id(p)
    cf = _scan_cache_file(aid)
    key = _scan_key(p)
    if use_cache and cf.is_file():
        try:
            d = json.loads(cf.read_bytes().decode("utf-8"))
        except Exception:
            d = None
        if d and d.get("key") == key and d.get("archive", {}).get("id") == aid:
            return d["archive"], d["entries"]
    arch, entries = scan_archive(rec)
    layerstate.atomic_write(cf, json.dumps(
        {"note": SCAN_CACHE_RULE, "key": key, "archive": arch,
         "entries": entries}).encode("utf-8"))
    return arch, entries


def scan_archive(rec: dict) -> tuple:
    """Open one archive, census its tables, and enumerate its listfile.

    Returns (archive_record, {lowercased path: entry}). The entry keeps the
    STORED name bytes verbatim - MPQ lookups are case-insensitive but read_file
    still wants a real name, and the stored spelling is itself data.

    mpyq's get_hash_table_entry() is a linear scan of the whole hash table; used
    per file that is O(files x hash_entries) and takes hours on this client. This
    builds the (hash_a, hash_b) index once per archive instead."""
    p = rec["path"]
    arch = {
        # `id` (dir-qualified) - never the bare basename - keys every lookup.
        "id": archive_id(p), "archive": p.name,
        "dir": str(p.parent.relative_to(config.CLIENT_DIR)).replace("\\", "/"),
        "layer": rec["layer"], "realm": rec["realm"],
        "declaredInListarchive": rec["declared"],
        "chainRank": [str(x) for x in rec["rank"]],
        "archiveBytes": p.stat().st_size,
        "sha256": sha256_file(p),
    }
    files, reason = probe_unlistable.try_list(p)
    try:
        a = MPQArchive(str(p), listfile=False)
    except Exception as e:
        arch.update({"listable": False, "unlistableReason": reason,
                     "openError": f"{type(e).__name__}: {e}", "fileCount": 0,
                     "blockExistsCount": 0, "unnamedCount": 0})
        return arch, {}

    exists = [b for b in a.block_table if b.flags & MPQ_FILE_EXISTS]
    arch.update({
        "formatVersion": a.header["format_version"],
        "hashTableEntries": a.header["hash_table_entries"],
        "blockTableEntries": a.header["block_table_entries"],
        "hashSlotsUsed": sum(1 for e in a.hash_table if e.block_table_index < HASH_DELETED),
        "hashSlotsDeleteMarked": sum(1 for e in a.hash_table
                                     if e.block_table_index == HASH_DELETED),
        "blockExistsCount": len(exists),
        "blockEncryptedCount": sum(1 for b in exists if b.flags & MPQ_FILE_ENCRYPTED),
        "uncompressedBytes": sum(b.size for b in exists),
        "listable": files is not None,
    })
    if files is None:
        arch["unlistableReason"] = reason

    # metadata members present? they explain the gap between listfile count and
    # block-table EXISTS count without hand-waving it away
    meta = [m for m in MPQ_META_MEMBERS
            if (e := a.get_hash_table_entry(m)) is not None
            and e.block_table_index < HASH_DELETED]
    arch["metaMembers"] = meta

    if files is None:
        arch["fileCount"] = 0
        arch["unnamedCount"] = len(exists) - len(meta)
        a.file.close()
        return arch, {}

    index = {}
    for e in a.hash_table:
        if e.block_table_index < HASH_DELETED:
            index.setdefault((e.hash_a, e.hash_b), e.block_table_index)

    entries, unresolved = {}, []
    for raw in files:
        stored = raw.decode("latin-1", "replace").replace("/", "\\")
        if not stored:
            continue
        bi = index.get((a._hash(stored, "HASH_A"), a._hash(stored, "HASH_B")))
        if bi is None or bi >= len(a.block_table):
            unresolved.append(stored)
            continue
        b = a.block_table[bi]
        if not (b.flags & MPQ_FILE_EXISTS):
            unresolved.append(stored)
            continue
        entries[stored.lower()] = {
            "stored": stored, "size": b.size, "storedBytes": b.archived_size,
            "flags": b.flags,
        }
    arch["fileCount"] = len(entries)
    arch["listfileLines"] = len(files)
    # names in the listfile with no live block entry (stale listfile lines)
    arch["listfileUnresolved"] = sorted(unresolved)[:64]
    arch["listfileUnresolvedCount"] = len(unresolved)
    # EXISTS block entries not accounted for by a listfile name or a meta member
    arch["unnamedCount"] = len(exists) - len(entries) - len(meta)
    a.file.close()
    return arch, entries


# --------------------------------------------------------------------------
# pass-4 content-hash checkpoint (see HASH_CACHE_RULE)
# --------------------------------------------------------------------------
CHECKPOINT_EVERY = 500       # files hashed between fsyncs (see _hash_archive)


def _index_hash_table(arch) -> None:
    """Replace mpyq's per-lookup LINEAR SCAN of the hash table with a dict built
    once per archive.

    `MPQArchive.get_hash_table_entry` walks the whole hash table on every call,
    which makes reading a large archive quadratic: patch-I holds 75,963 winning
    paths against a hash table of the same order, measured at 6.2 ms per file -
    about 8 minutes for that one archive, essentially all of it scanning rather
    than decompressing. tools/extract_interface_all.py already does this; pass 4
    did not, which is most of why the census took ~25 minutes. The (hash_a,
    hash_b) pair is exactly what the scan compares, so indexing on it is
    equivalent - same lookup, same result, same first-match-wins order."""
    index = {}
    for e in arch.hash_table:
        if e.block_table_index < HASH_DELETED:
            index.setdefault((e.hash_a, e.hash_b), e)
    arch.get_hash_table_entry = lambda name: index.get(
        (arch._hash(name, "HASH_A"), arch._hash(name, "HASH_B")))

_CACHE_HITS = set()


def _cache_file(archive_id_str: str) -> Path:
    stem = "".join(c if c.isalnum() or c in "-_" else "-"
                   for c in archive_id_str.lower())
    return HASH_CACHE_DIR / f"{stem}.jsonl"


def _load_hash_cache(archive_id_str: str, archive_sha: str) -> dict:
    """Whatever of this archive has already been hashed, for THESE archive
    bytes. Keyed on the archive's own sha256, so a patched archive can never be
    served from a stale checkpoint. A trailing line a crash truncated is dropped
    rather than trusted."""
    p = _cache_file(archive_id_str)
    if not p.is_file():
        return {}
    out = {}
    with open(p, "rb") as f:
        head = f.readline()
        try:
            h = json.loads(head.decode("utf-8"))
        except Exception:
            return {}
        if (h.get("archive") != archive_id_str
                or h.get("archiveSha256") != archive_sha):
            return {}
        for raw in f:
            try:
                rec = json.loads(raw.decode("utf-8"))
            except Exception:
                break            # truncated by a kill; everything before it stands
            out[rec.pop("_path")] = rec
    if out:
        _CACHE_HITS.add(archive_id_str)
    return out


def _hash_archive(archive_path: Path, archive_id_str: str, archive_sha: str,
                  lows: list, carriers: dict, done: dict, log) -> dict:
    """Decompress and hash every winning file this archive carries that the
    checkpoint does not already have, appending each batch to the checkpoint.

    Append-only, FLUSHED after every single file and fsynced every
    CHECKPOINT_EVERY: a process abort (which is how this host fails - it dies at
    0xC0000005 rather than raising) loses nothing already written, because the
    bytes are in the OS by then. Buffering even 500 of them was enough to make a
    run lose every hash it had just computed and restart from the same line
    forever. `lows` is sorted, so which files a resumed run still has to do is a
    function of the input, not of when the kill happened."""
    todo = [low for low in sorted(lows) if low not in done]
    if not todo:
        return done
    p = _cache_file(archive_id_str)
    p.parent.mkdir(parents=True, exist_ok=True)
    fresh = not done
    ar = MPQArchive(str(archive_path), listfile=False)
    _index_hash_table(ar)
    n = 0
    try:
        with open(p, "wb" if fresh else "ab") as cache:
            if fresh:
                cache.write(json.dumps(
                    {"note": HASH_CACHE_RULE, "archive": archive_id_str,
                     "archiveSha256": archive_sha}).encode("utf-8") + b"\n")
                cache.flush()
                os.fsync(cache.fileno())
            for low in todo:
                e = carriers[low]["e"]
                try:
                    data = ar.read_file(e["stored"])
                except Exception as ex:          # noqa: BLE001 - recorded, not raised
                    rec = {"sha256": None,
                           "readError": f"{type(ex).__name__}: {ex}"}
                else:
                    if data is None:
                        rec = {"sha256": None,
                               "readError": "read_file returned None "
                                            "(zero-length stored block)"}
                    else:
                        rec = {"sha256": hashlib.sha256(data).hexdigest(),
                               "readBytes": len(data)}
                        if low.startswith("dbfilesclient\\") and len(data) >= 20:
                            magic, nrec, nfld, rsz, ssz = struct.unpack_from(
                                "<4s4I", data, 0)
                            rec["dbc"] = {"magic": magic.decode("latin-1"),
                                          "records": nrec, "declaredFields": nfld,
                                          "recordSize": rsz,
                                          "stringBlockSize": ssz,
                                          "actualFields": rsz // 4}
                done[low] = rec
                cache.write(json.dumps({"_path": low, **rec}).encode("utf-8") + b"\n")
                cache.flush()          # out of this process on every file
                n += 1
                if n % CHECKPOINT_EVERY == 0:
                    os.fsync(cache.fileno())
                    log(f"    {archive_id_str}: {len(done)}/{len(lows)} hashed")
            cache.flush()
            os.fsync(cache.fileno())
    finally:
        ar.file.close()
    return done


# --------------------------------------------------------------------------
# classification + sharding
# --------------------------------------------------------------------------

def path_class(path: str, source: str) -> str:
    """Reporting rollup only - see module docstring. `path` is lowercased with
    backslash separators."""
    ext = path.rsplit(".", 1)[-1] if "." in path.rsplit("\\", 1)[-1] else ""
    if path.startswith("dbfilesclient\\") or ext == "dbc":
        return "dbc"
    if ext == "json" or (source == "loose" and path.startswith("content\\")):
        return "content"
    if path.startswith("interface\\"):
        return "interface"
    if path.startswith("sound\\") or ext in _SOUND_EXT:
        return "sound"
    if ext in _ART_EXT:
        return "art"
    return "other"


# Fixed, data-independent letter bands. Splitting an oversized node into ~10
# bands instead of ~40 single characters keeps small siblings merged (639 shards
# instead of 1,107, median 423 records instead of 157) WITHOUT making membership
# depend on neighbour counts: a band is a constant, so a path's band never moves.
_BANDS = ("abc", "def", "ghi", "jkl", "mno", "pqr", "stu", "vwx", "yz")
_BAND_OF = {c: b for b in _BANDS for c in b}
_BAND_OTHER = "other"           # digits, separators, punctuation


def band_of(ch: str) -> str:
    return _BAND_OF.get(ch, _BAND_OTHER)


def partition(paths: list, limit: int = SHARD_MAX) -> dict:
    """Group paths into shards keyed by a CHARACTER PREFIX of the path, each
    <= `limit` members where the paths allow it.

    Why a character prefix and not a directory prefix: directory depth cannot
    bound shard size on this client at all - Interface\\Icons alone is one flat
    directory of 75,986 files, so no amount of descending splits it. A character
    trie splits anything, and the prefix is still a readable, greppable answer to
    "which shard holds this path".

    A node that already fits becomes a shard as-is, so small directories stay
    merged into one readable file rather than exploding into thousands of stubs.
    An oversized node splits into fixed letter BANDS; a band that still does not
    fit splits again by real character and recurses.

    Every rule here is a constant or a property of the path itself, so a path's
    shard is a pure function of that path. That is the whole point: adding or
    removing files never reshuffles unrelated shards the way count-chunking does.
    Only the one prefix that actually outgrew the cap re-splits.

    Returns {(prefix, kind): [paths]}, where prefix is the character prefix and
    kind is '' (plain node), '~<band>' (band shard) or '~exact' (the single path
    that IS the prefix). The key is a TUPLE rather than a concatenated string on
    purpose: a client path containing a literal '~band' run would otherwise let
    one node's band key collide with another node's plain key, and `out[key] = `
    would silently discard a whole group - the exact class of silent loss this
    rebuild exists to eliminate."""
    out = {}
    stack = [("", sorted(paths))]
    while stack:
        prefix, group = stack.pop()
        if len(group) <= limit:
            out[(prefix, "")] = group
            continue
        d = len(prefix)
        bands, terminal = {}, []
        for pth in group:
            if d >= len(pth):       # this path IS the prefix; nothing left to split
                terminal.append(pth)
            else:
                bands.setdefault(band_of(pth[d]), []).append(pth)
        if terminal:
            out[(prefix, "~exact")] = terminal
        for b, grp in bands.items():
            if len(grp) <= limit:
                out[(prefix, "~" + b)] = grp
                continue
            chars = {}
            for pth in grp:
                chars.setdefault(pth[d], []).append(pth)
            for ch, grp2 in chars.items():
                stack.append((prefix + ch, grp2))
    return out


_SAFE = set("abcdefghijklmnopqrstuvwxyz0123456789-_~")


def _prefix_digest(key: tuple) -> str:
    return hashlib.sha256("\x00".join(key).encode("utf-8", "replace")).hexdigest()[:8]


def _shard_name_raw(key: tuple) -> str:
    prefix, kind = key
    stem = "".join(c if c in _SAFE else "-" if c == "\\"
                   else "%%%02x" % (ord(c) & 0xFF) for c in prefix.lower())
    name = (stem or "_root") + kind
    if len(name) > 120:
        name = name[:110] + "-" + _prefix_digest(key)
    return name


def shard_names(prefixes) -> dict:
    """Flat, greppable filename per prefix: path separators become '-'.
    Two DIFFERENT prefixes can flatten to the same string ('world\\maps' and a
    real directory literally named 'world-maps' both give 'world-maps'), and a
    silent collision would overwrite one shard with the other - data loss, the
    exact failure this rebuild exists to eliminate. So collisions are detected
    and every colliding member is disambiguated by its prefix digest. The result
    is still a pure function of the prefix SET, hence stable across reruns."""
    raw = {}
    for p in prefixes:
        raw.setdefault(_shard_name_raw(p), []).append(p)
    out = {}
    for name, group in raw.items():
        if len(group) == 1:
            out[group[0]] = name + ".json"
        else:
            for p in group:
                out[p] = f"{name}-{_prefix_digest(p)}.json"
    return out


def dump_records(records: list) -> str:
    """One compact record per line - diffable per record, greppable per path,
    and it keeps a 5,000-record shard at 5,002 lines instead of tens of
    thousands (the nested-indent shape the small-data-files rule rejects)."""
    lines = ["["]
    for i, r in enumerate(records):
        lines.append(" " + json.dumps(r, ensure_ascii=False, sort_keys=True,
                                      separators=(",", ":"))
                     + ("," if i < len(records) - 1 else ""))
    lines.append("]")
    return "\n".join(lines) + "\n"


def write_bytes_lf(path: Path, text: str) -> None:
    """UTF-8, LF, no BOM - written as BYTES. `Path.write_text` translates \\n to
    the platform's newline, which made every file this module emits depend on the
    OS that ran it: LF on Linux, CRLF on Windows, for identical client bytes.
    That is the same class of defect as the one that stripped CR out of
    raw/interface, and it breaks the byte-for-byte rerun guarantee."""
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(text.encode("utf-8"))


def write_json(path: Path, payload) -> None:
    write_bytes_lf(path, json.dumps(payload, indent=1, sort_keys=True,
                                    ensure_ascii=False) + "\n")


# --------------------------------------------------------------------------
# main
# --------------------------------------------------------------------------

def build(skip_content_hash: bool = False, verbose: bool = True,
          rescan: bool = False) -> dict:
    t0 = time.time()

    def log(msg):
        if verbose:
            print(msg, flush=True)

    archives = discover_archives()
    path_by_id = {archive_id(r["path"]): r["path"] for r in archives}
    if len(path_by_id) != len(archives):
        raise SystemExit("FATAL: two archives share one dir-qualified id.")
    log(f"archives discovered: {len(archives)}")

    # ---- pass 1: enumerate every archive, resolve the winner of every path ----
    arch_records, carriers = [], {}
    for i, rec in enumerate(archives):
        arch, entries = scan_archive_cached(rec, use_cache=not rescan)
        arch_records.append(arch)
        for low, e in entries.items():
            cur = carriers.get(low)
            if cur is None:
                carriers[low] = {"e": e, "rank": rec["rank"], "winner": arch["id"],
                                 "losers": []}
            elif rec["rank"] > cur["rank"]:
                cur["losers"].append(cur["winner"])
                cur.update({"e": e, "rank": rec["rank"], "winner": arch["id"]})
            else:
                cur["losers"].append(arch["id"])
        log(f"  [{i+1:2d}/{len(archives)}] {arch['archive']:26s} "
            f"listable={str(arch['listable']):5s} files={arch['fileCount']:7d} "
            f"union={len(carriers):7d}  [{time.time()-t0:6.1f}s]")

    unlistable = [a for a in arch_records if not a["listable"]]

    # ---- pass 2: probe the unlistable archives against EVERY harvested name ----
    # Not a wanted list - the full union of every path name any listable archive
    # revealed. The (hash_a, hash_b) pair for a name is archive-independent, so
    # the expensive part is computed once and reused across all probed archives.
    probe = {}
    if unlistable:
        log(f"probing {len(unlistable)} unlistable archive(s) against "
            f"{len(carriers)} harvested names + {len(MPQ_META_MEMBERS)} meta members")
        names = sorted(carriers) + list(MPQ_META_MEMBERS)
        stub = MPQArchive(str(archives[0]["path"]), listfile=False)
        keys = [(n, stub._hash(n, "HASH_A"), stub._hash(n, "HASH_B")) for n in names]
        stub.file.close()
        log(f"  hashed {len(keys)} names [{time.time()-t0:.1f}s]")
        for a in unlistable:
            p = path_by_id[a["id"]]
            try:
                ar = MPQArchive(str(p), listfile=False)
            except Exception as e:
                probe[a["id"]] = {"error": f"{type(e).__name__}: {e}",
                                  "probedCount": len(keys), "hits": []}
                continue
            idx = {}
            for e in ar.hash_table:
                if e.block_table_index < HASH_DELETED:
                    idx.setdefault((e.hash_a, e.hash_b), e.block_table_index)
            hits = []
            for n, ha, hb in keys:
                bi = idx.get((ha, hb))
                if bi is not None and ar.block_table[bi].flags & MPQ_FILE_EXISTS:
                    hits.append(n)
            live = sum(1 for b in ar.block_table if b.flags & MPQ_FILE_EXISTS)
            probe[a["id"]] = {
                "probedCount": len(keys),
                "hits": sorted(hits),
                "liveBlockEntries": live,
                # the honest residual: live files whose NAME no harvested path
                # matched. This is the only thing that can remain unknowable.
                "unidentifiedLiveEntries": live - len(hits),
                "deleteMarkedHashSlots": a.get("hashSlotsDeleteMarked"),
            }
            log(f"  {a['archive']:16s} live={live} hits={len(hits)} "
                f"unidentified={live - len(hits)}")
            ar.file.close()

    # ---- pass 3: loose (non-MPQ) files, under Data\ and at the client root ----
    # See LOOSE_OVERRIDE_RULE. Two mechanical conditions, no name list: under
    # Data\, or shadowing a path the MPQ chain carries.
    loose, overrides = {}, {}
    data_root = config.CLIENT_DIR / "Data"
    root = config.CLIENT_DIR
    for p in sorted(root.rglob("*")):
        if not p.is_file() or p.suffix.lower() == ".mpq":
            continue
        rel_root = str(p.relative_to(root)).replace("/", "\\")
        low_root = rel_root.lower()
        if low_root.startswith("data\\"):
            rel = str(p.relative_to(data_root)).replace("/", "\\")
            loose[rel.lower()] = {"stored": rel, "size": p.stat().st_size,
                                  "sha256": sha256_file(p), "path": p}
        elif low_root in carriers:
            overrides[low_root] = {"stored": rel_root, "size": p.stat().st_size,
                                   "sha256": sha256_file(p), "path": p}
    log(f"loose files under Data\\: {len(loose)}; loose client-root files that "
        f"override an archived path: {len(overrides)}  [{time.time()-t0:.1f}s]")

    # ---- pass 4: content sha256 for every winning archived file ----
    # Checkpointed per archive - see HASH_CACHE_RULE. This is the only pass long
    # enough that "the process survives to the end" is an assumption worth not
    # making; with the checkpoint a run interrupted at any point resumes.
    read_errors = {}
    if not skip_content_hash:
        sha_by_id = {a["id"]: a.get("sha256") for a in arch_records}
        by_archive = {}
        for low, c in carriers.items():
            by_archive.setdefault(c["winner"], []).append(low)
        done = cached = 0
        for aname in sorted(by_archive):
            asha = sha_by_id.get(aname)
            hits = _load_hash_cache(aname, asha)
            if len(hits) < len(by_archive[aname]):
                hits = _hash_archive(path_by_id[aname], aname, asha,
                                     by_archive[aname], carriers, hits, log)
            else:
                cached += 1
            for low, rec in hits.items():
                e = carriers[low]["e"]
                e.update(rec)
                if rec.get("readError"):
                    read_errors[rec["readError"]] = \
                        read_errors.get(rec["readError"], 0) + 1
            done += len(by_archive[aname])
            log(f"  hashed {done:7d}/{len(carriers)} (through {aname})"
                f"{' [cached]' if aname in _CACHE_HITS else ''} "
                f"[{time.time()-t0:6.1f}s]")
        log(f"  content hashes: {cached}/{len(by_archive)} archives came from "
            f"the checkpoint  [{time.time()-t0:.1f}s]")

    # ---- assemble per-path records ----
    records = []
    for low in sorted(carriers):
        c = carriers[low]
        e = c["e"]
        r = {"path": e["stored"].replace("\\", "/"), "source": "mpq",
             "winner": c["winner"], "size": e["size"], "storedBytes": e["storedBytes"],
             "class": path_class(low, "mpq"), "flags": flag_names(e["flags"])}
        if c["losers"]:
            r["losers"] = sorted(set(c["losers"]))
        if "sha256" in e:
            r["sha256"] = e["sha256"]
        if "readError" in e:
            r["readable"] = False
            r["readError"] = e["readError"]
        if "dbc" in e:
            r["dbc"] = e["dbc"]
        o = overrides.get(low)
        if o is not None:
            # The loose file wins the path. The archive copy it displaced is kept
            # in full under `overrides` - it is real data about the client, it is
            # just not what gets loaded, and reporting it as the winner is the
            # bug this branch fixes.
            r["overrides"] = {k: v for k, v in r.items()
                              if k in ("winner", "size", "storedBytes", "sha256",
                                       "flags", "losers", "readable", "readError",
                                       "dbc")}
            r.update({"source": "loose", "winner": DISK_WINNER,
                      "diskPath": o["stored"].replace("\\", "/"),
                      "size": o["size"], "sha256": o["sha256"],
                      "storedBytes": None, "flags": [],
                      "differsFromArchive": o["sha256"] != r["overrides"].get("sha256")})
            r.pop("readable", None)
            r.pop("readError", None)
            r.pop("dbc", None)
        records.append(r)
    for low in sorted(loose):
        e = loose[low]
        records.append({"path": e["stored"].replace("\\", "/"), "source": "loose",
                        "winner": None, "size": e["size"], "sha256": e["sha256"],
                        "class": path_class(low, "loose"), "flags": []})

    # ---- censuses (all three are raw measurements, no curation) ----
    def census(keyfn):
        c = {}
        for r in records:
            k = keyfn(r)
            d = c.setdefault(k, {"files": 0, "bytes": 0})
            d["files"] += 1
            d["bytes"] += r["size"]
        return dict(sorted(c.items()))

    by_class = census(lambda r: r["class"])
    by_top = census(lambda r: r["path"].split("/", 1)[0].lower()
                    if "/" in r["path"] else "_root")
    by_ext = census(lambda r: r["path"].rsplit(".", 1)[-1].lower()
                    if "." in r["path"].rsplit("/", 1)[-1] else "_noext")

    total_bytes = sum(r["size"] for r in records)
    dbc_records = [r for r in records if r["class"] == "dbc"]

    # ---- shard + write ----
    # The sentinel goes before the unlinks: from here until finish() the census
    # is not readable, and every consumer of it checks (layerstate.RULE).
    layerstate.begin(INV_DIR)
    if FILES_DIR.exists():
        for old in FILES_DIR.glob("*.json"):
            old.unlink()                      # sole writer: a path that vanished
    FILES_DIR.mkdir(parents=True, exist_ok=True)   # from the client must not linger
    by_path = {r["path"].replace("/", "\\").lower(): r for r in records}
    if len(by_path) != len(records):
        # an MPQ path and a loose Data\ path that lowercase to the same string
        # would silently collapse into one record here
        raise SystemExit(f"FATAL: path-key collision - {len(records)} records "
                         f"collapsed to {len(by_path)} keys.")
    groups = partition(list(by_path))
    sharded = sum(len(v) for v in groups.values())
    if sharded != len(by_path):
        raise SystemExit(f"FATAL: sharding lost records - partitioned {sharded} "
                         f"of {len(by_path)} paths. Refusing to write a "
                         f"silently-incomplete inventory.")
    names = shard_names(groups)
    if len(set(names.values())) != len(groups):
        raise SystemExit("FATAL: shard filename collision survived "
                         "disambiguation; one shard would overwrite another.")
    shards = []
    for key in sorted(groups):
        fn = names[key]
        rows = [by_path[p] for p in sorted(groups[key])]
        write_bytes_lf(FILES_DIR / fn, dump_records(rows))
        shards.append({"file": fn, "prefix": key[0].replace("\\", "/"),
                       "kind": key[1], "records": len(rows),
                       "firstPath": rows[0]["path"], "lastPath": rows[-1]["path"]})
    oversize = [s for s in shards if s["records"] > SHARD_MAX]

    write_json(INV_DIR / "archives.json", {
        "clientDir": str(config.CLIENT_DIR),
        "scanCheckpointRule": SCAN_CACHE_RULE,
        "archiveCount": len(arch_records),
        "listableCount": sum(1 for a in arch_records if a["listable"]),
        "unlistableCount": len(unlistable),
        "archiveBytesTotal": sum(a["archiveBytes"] for a in arch_records),
        "archives": arch_records,
    })

    write_json(INV_DIR / "files.json", {
        "note": "Index for raw/_inventory/files/*.json. Per-path records live in "
                "the shards; each shard holds one compact JSON record per line, "
                "sorted by path, keyed by the path prefix in `prefix`.",
        "recordCount": len(records),
        "mpqPathCount": len(carriers),
        "loosePathCount": len(loose),
        "looseOverrideRule": LOOSE_OVERRIDE_RULE,
        "contentHashCheckpointRule": HASH_CACHE_RULE,
        "looseOverrideCount": len(overrides),
        "looseOverrides": [
            {"path": r["path"], "size": r["size"], "sha256": r["sha256"],
             "differsFromArchive": r["differsFromArchive"],
             "archiveWinner": r["overrides"]["winner"],
             "archiveSize": r["overrides"]["size"],
             "archiveSha256": r["overrides"].get("sha256")}
            for r in records if r.get("winner") == DISK_WINNER],
        "totalUncompressedBytes": total_bytes,
        "contentHashed": not skip_content_hash,
        "unreadableCount": sum(1 for r in records if r.get("readable") is False),
        "shardMaxLines": SHARD_MAX,
        "shardCount": len(shards),
        "oversizeShards": oversize,
        "shards": shards,
    })

    projection = {
        "note": "Byte volumes are UNCOMPRESSED sizes from the MPQ block table - "
                "what a full raw extraction writes to disk. `class` is a "
                "reporting rollup; byTopLevelDir and byExtension are the raw "
                "measurements it is derived from.",
        "totalUncompressedBytes": total_bytes,
        "totalUncompressedGB": round(total_bytes / 1e9, 3),
        "exceedsTwoGB": total_bytes > 2_000_000_000,
        "twoGBBudgetOverrunBytes": max(0, total_bytes - 2_000_000_000),
        "byClass": by_class,
        "byTopLevelDir": by_top,
        "byExtension": by_ext,
        "dbcTableCount": len(dbc_records),
        "dbcUncompressedBytes": by_class.get("dbc", {}).get("bytes", 0),
    }
    write_json(INV_DIR / "categories.json", projection)

    write_json(INV_DIR / "unlistable.json", {
        "note": "Archives with no readable (listfile). Each is characterized by "
                "block-table census plus a hash-table probe of EVERY path name "
                "harvested from the listable archives. `unidentifiedLiveEntries` "
                "is the honest residual: live files no harvested name matched.",
        "unlistableArchives": [
            {k: v for k, v in a.items() if k != "sha256"} for a in unlistable],
        "probe": probe,
        "totalUnidentifiedLiveEntries": sum(
            f.get("unidentifiedLiveEntries", 0) for f in probe.values()),
    })

    write_json(INV_DIR / "dbc.json", {
        "note": "Every DBFilesClient table in the winning chain, with its WDBC "
                "header measured from the winning bytes. actualFields = "
                "recordSize//4; a disagreement with declaredFields is a lying "
                "header, recorded not swallowed.",
        "tableCount": len(dbc_records),
        "headerMismatches": sorted(
            r["path"].rsplit("/", 1)[-1] for r in dbc_records
            if "dbc" in r and r["dbc"]["actualFields"] != r["dbc"]["declaredFields"]),
        "nonWdbcMagic": sorted(
            f'{r["path"].rsplit("/", 1)[-1]}={r["dbc"]["magic"]}' for r in dbc_records
            if "dbc" in r and r["dbc"]["magic"] != "WDBC"),
        "tables": [{"table": r["path"].rsplit("/", 1)[-1], "winner": r["winner"],
                    "size": r["size"], "sha256": r.get("sha256"),
                    "losers": r.get("losers", []), **(r.get("dbc") or {})}
                   for r in sorted(dbc_records, key=lambda x: x["path"].lower())],
    })

    write_catalog()
    layerstate.finish(INV_DIR, {
        "layer": "raw/_inventory", "generatedBy": "python -m tools.inventory",
        "archiveCount": len(arch_records), "recordCount": len(records),
        "dbcTableCount": len(dbc_records), "shardCount": len(shards),
        "looseOverrideCount": len(overrides),
        "contentHashed": not skip_content_hash})

    summary = {
        "archives": len(arch_records), "unlistable": len(unlistable),
        "records": len(records), "dbcTables": len(dbc_records),
        "looseOverrides": len(overrides),
        "totalBytes": total_bytes, "shards": len(shards),
        "oversizeShards": len(oversize), "readErrors": read_errors,
        "unidentified": sum(f.get("unidentifiedLiveEntries", 0) for f in probe.values()),
        "byClass": by_class, "elapsed": round(time.time() - t0, 1),
    }
    return summary


def write_catalog() -> None:
    """Generate raw/_inventory/README.md - the entry point an agent reads first.

    Deliberately reads the emitted JSON back off disk rather than taking build()'s
    in-memory state: the catalog can then never quote a number the data does not
    actually contain, and it can be regenerated standalone. Every figure below is
    read, not written by hand."""
    arch = json.loads((INV_DIR / "archives.json").read_text(encoding="utf-8"))
    files = json.loads((INV_DIR / "files.json").read_text(encoding="utf-8"))
    cats = json.loads((INV_DIR / "categories.json").read_text(encoding="utf-8"))
    unl = json.loads((INV_DIR / "unlistable.json").read_text(encoding="utf-8"))
    dbc = json.loads((INV_DIR / "dbc.json").read_text(encoding="utf-8"))

    gb = cats["totalUncompressedBytes"] / 1e9
    L = []
    L.append("# Client inventory (generated)\n")
    L.append("Regenerate: `python -m tools.inventory`. Every file here is written "
             "by `tools/inventory.py`; nothing in it is hand-authored, and nothing "
             "in the client is filtered out of it.\n")
    L.append("## Start here\n")
    L.append("| file | what it answers |")
    L.append("| --- | --- |")
    L.append("| `archives.json` | every MPQ, its chain rank, whether it lists, "
             "its sha256 |")
    L.append("| `dbc.json` | every DBFilesClient table + its measured WDBC header |")
    L.append("| `categories.json` | how many bytes a full raw extraction costs, "
             "by class / directory / extension |")
    L.append("| `unlistable.json` | the archives with no readable `(listfile)`, "
             "and what is provably in them |")
    L.append("| `files.json` | index of the per-path shards in `files/` |")
    L.append("| `files/*.json` | one compact record per line: path, winning "
             "archive, size, sha256, flags |\n")
    L.append("## Totals\n")
    L.append(f"- **{files['recordCount']:,} paths** "
             f"({files['mpqPathCount']:,} in MPQs, {files['loosePathCount']:,} "
             f"loose under `Data\\`)")
    L.append(f"- **{dbc['tableCount']} DBC tables**")
    L.append(f"- **{arch['archiveCount']} archives** "
             f"({arch['unlistableCount']} unlistable), "
             f"{arch['archiveBytesTotal']/1e9:.1f} GB on disk")
    L.append(f"- **{gb:.2f} GB** uncompressed if everything is extracted")
    L.append(f"- unreadable files: {files['unreadableCount']:,}")
    L.append(f"- files in unlistable archives that no harvested name identified: "
             f"**{unl['totalUnidentifiedLiveEntries']}**")
    L.append(f"- paths a loose file at the client root takes from the archives: "
             f"**{files['looseOverrideCount']}**\n")

    L.append("## Loose files at the client root beat the whole MPQ chain\n")
    L.append(files["looseOverrideRule"] + "\n")
    if files["looseOverrides"]:
        L.append("| path | on-disk bytes | archive bytes | archive winner | "
                 "same bytes? |")
        L.append("| --- | ---: | ---: | --- | --- |")
        for o in files["looseOverrides"]:
            L.append(f"| `{o['path']}` | {o['size']:,} | {o['archiveSize']:,} | "
                     f"{o['archiveWinner']} | "
                     f"{'no' if o['differsFromArchive'] else 'yes'} |")
        L.append("\nEach of these records the DISK bytes as the winner. The "
                 "archive copy it displaced is kept in full under `overrides` in "
                 "the path record - nothing is dropped, it is just no longer "
                 "reported as the file the client loads.\n")
    else:
        L.append("No loose file at the client root shadows an archived path on "
                 "this install.\n")

    # Readability breakdown, re-derived from the shards themselves so it cannot
    # disagree with them. This is the number that decides whether the DATA layer
    # is fully extractable, which the bare unreadable count does not.
    ur_class, ur_reason, ur_ext = {}, {}, {}
    for shard in sorted(FILES_DIR.glob("*.json")):
        for r in json.loads(shard.read_text(encoding="utf-8")):
            if r.get("readable") is not False:
                continue
            ur_class[r["class"]] = ur_class.get(r["class"], 0) + 1
            kind = ("empty override block" if "None" in r["readError"]
                    else "compression mpyq cannot decode")
            ur_reason[kind] = ur_reason.get(kind, 0) + 1
            base = r["path"].rsplit("/", 1)[-1]
            ext = base.rsplit(".", 1)[-1].lower() if "." in base else "(none)"
            ur_ext[ext] = ur_ext.get(ext, 0) + 1
    L.append("## What is not readable, and whether it matters\n")
    L.append("`mpyq` implements only the zlib and bzip2 MPQ compressions; the "
             "client also uses PKWARE/ADPCM variants. Files it cannot decode are "
             "recorded with `readable: false` and the error - never dropped.\n")
    L.append("| unreadable by class | count |")
    L.append("| --- | ---: |")
    for k, v in sorted(ur_class.items(), key=lambda kv: -kv[1]):
        L.append(f"| {k} | {v:,} |")
    L.append("")
    L.append("| reason | count |")
    L.append("| --- | ---: |")
    for k, v in sorted(ur_reason.items(), key=lambda kv: -kv[1]):
        L.append(f"| {k} | {v:,} |")
    L.append("")
    data_ext = {e: n for e, n in ur_ext.items()
                if e in ("dbc", "json", "lua", "xml", "toc", "txt", "loc")}
    L.append(f"Unreadable files with a DATA extension (dbc/json/lua/xml/toc/txt/"
             f"loc): `{data_ext or 'none'}`. Everything else unreadable is binary "
             f"media (ogg/wav/blp/mp3/avi/...).\n")

    # Which tables a non-base layer overrides - the realm overlay outranks the
    # whole base chain, so a consumer reading only the base layer silently gets
    # different rows. Derived from dbc.json's own winners.
    layer_of = {a["id"]: a["layer"] for a in arch["archives"]}
    over = [t for t in dbc["tables"] if layer_of.get(t["winner"]) == "realm"]
    if over:
        L.append("## DBC tables won by a realm overlay, not the base chain\n")
        L.append("These sit ABOVE the entire base chain, so the base copy is NOT "
                 "what the client uses.\n")
        L.append("| table | winner | records | base copies overridden |")
        L.append("| --- | --- | ---: | ---: |")
        for t in sorted(over, key=lambda x: x["table"].lower()):
            L.append(f"| {t['table']} | {t['winner']} | {t['records']:,} | "
                     f"{len(t['losers'])} |")
        L.append("")
    L.append("## Extraction cost by class\n")
    L.append("| class | files | GB |")
    L.append("| --- | ---: | ---: |")
    for k, v in sorted(cats["byClass"].items(), key=lambda kv: -kv[1]["bytes"]):
        L.append(f"| {k} | {v['files']:,} | {v['bytes']/1e9:.3f} |")
    L.append(f"| **total** | **{files['recordCount']:,}** | **{gb:.3f}** |\n")
    L.append("`class` is a reporting rollup only - it gates nothing. "
             "`categories.json` carries the raw `byTopLevelDir` and `byExtension` "
             "censuses it is derived from.\n")
    L.append("## Finding a path\n")
    L.append(f"Shards in `files/` are keyed by a character prefix of the path "
             f"(capped at {files['shardMaxLines']:,} records; "
             f"{files['shardCount']} shards). A path's shard is a pure function "
             f"of that path, so shard contents do not churn when the client "
             f"patches. `files.json` lists each shard's `prefix`, `firstPath` "
             f"and `lastPath`; grepping `files/` directly also works.\n")
    write_bytes_lf(INV_DIR / "README.md", "\n".join(L))


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--skip-content-hash", action="store_true",
                    help="skip decompressing every file for its sha256 "
                         "(fast structural pass only; sha256 fields are omitted)")
    ap.add_argument("--rescan", action="store_true",
                    help="ignore the per-archive scan checkpoints in work/ and "
                         "re-read every archive from the client bytes")
    ap.add_argument("-q", "--quiet", action="store_true")
    args = ap.parse_args()
    s = build(skip_content_hash=args.skip_content_hash, verbose=not args.quiet,
              rescan=args.rescan)

    print("\n=== INVENTORY ===")
    print(f"archives            {s['archives']} ({s['unlistable']} unlistable)")
    print(f"paths               {s['records']}")
    print(f"DBC tables          {s['dbcTables']}")
    print(f"shards              {s['shards']} (oversize: {s['oversizeShards']})")
    print(f"loose root overrides{s['looseOverrides']:4d}")
    print(f"read errors         {sum(s['readErrors'].values())} {s['readErrors']}")
    print(f"unidentified files  {s['unidentified']}")
    for k, v in s["byClass"].items():
        print(f"  {k:14s} {v['files']:8d} files  {v['bytes']/1e9:8.3f} GB")
    gb = s["totalBytes"] / 1e9
    print(f"  {'TOTAL':14s} {s['records']:8d} files  {gb:8.3f} GB")
    if s["totalBytes"] > 2_000_000_000:
        print("\n" + "!" * 72)
        print(f"!! FULL RAW EXTRACTION WOULD BE {gb:.2f} GB "
              f"({s['totalBytes']:,} bytes) - {gb/2:.1f}x THE 2 GB BUDGET.")
        print("!! Nothing has been gitignored or dropped. This is a decision point.")
        print("!" * 72)
    print(f"elapsed {s['elapsed']}s")


if __name__ == "__main__":
    main()
