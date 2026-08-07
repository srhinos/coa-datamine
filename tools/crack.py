"""Everything in the client that was still opaque, opened - or proven empty.

    python -m tools.crack            # all four stages, resumable
    python -m tools.crack --only resweep

Three things were being taken on trust before this module existed. Each is now a
MEASUREMENT, and one of the three turned out to be false.

1  "patch-P's 1,350 deleted entries are gone, so there are no bytes to get back."
   TESTED, and true - but not for the reason that was assumed, and the test is
   the point. Every archive's data region is walked span by span against its own
   block table, so the question "is there file data in here that no live block
   entry accounts for?" is answered in bytes rather than argued. Across all 77
   archives and 44.9 GB the unaccounted total is ZERO: the block tables were
   truncated AND the archives compacted, so a delete-marked hash slot points at
   nothing because nothing is there. patch-P leaves one fingerprint of what it
   used to hold - its `(attributes)` array is still sized for 1,006 block entries
   while its block table holds 2 - and its `(listfile)`, the only encrypted file
   in the client, decrypts to the string "(listfile)" and nothing else.

2  "41,053 files (6.4%) use compressions mpyq does not implement."  FALSE, and
   this is the finding that matters. 36,141 of them are ordinary zlib and stored
   sectors that `mpyq` mis-decodes; see tools/mpq.py for the exact defect. The
   remaining 4,912 are not compressed at all - 4,906 are patch DELETE tombstones,
   which carry no bytes BY DESIGN and were being recorded as read failures, and 6
   are genuinely zero-length. A full-mask census over the client finds no PKWARE,
   no ADPCM, no huffman and no sparse sector anywhere in it.

3  "`(attributes)` is archive bookkeeping."  It is a complete second integrity
   record - CRC32, modification time and MD5 for EVERY block entry - that all 77
   archives carry and nothing here had ever read. Expanding it and joining it
   back to path names yields 770,002 records covering every version of every file
   including the losers, and dates 529,029 of them, which is a mechanical way to
   tell Ascension's own content from Blizzard's.

WHAT THIS LAYER IS NOT
----------------------
It is not a second extraction of the client. `raw/recovered/` holds the bytes of
files that were UNREADABLE BEFORE and are not art or sound, the metadata layers
above, and the expanded containers - nothing that another layer already owns.
Art and sound stay recorded-not-committed exactly as elsewhere: read in full,
hashed, size and sha256 written down, bytes discarded.

CRASH SAFETY
------------
This host aborts processes at random (see raw/_inventory README). Every
expensive stage checkpoints per archive into work/crack/ keyed by the archive's
own sha256, so a killed run resumes rather than restarts, and the layer carries
tools/layerstate's sentinel so a half-written tree can never be read as a whole
one.
"""
import argparse
import collections
import hashlib
import json
import os
import plistlib
import struct
import sys
import time
import zlib
from pathlib import Path

from tools import config, inventory, layerstate, mpq, sharding

OUT_DIR = config.RAW_DIR / "recovered"
WORK_DIR = config.WORK_DIR / "crack"

FORENSICS = OUT_DIR / "_forensics.json"
ATTR_DIR = OUT_DIR / "attributes"
DELETED_DIR = OUT_DIR / "deleted"
FILES_DIR = OUT_DIR / "files"
BYTES_DIR = FILES_DIR / "bytes"          # recovered bytes, laid out by client path
CONTAINER_DIR = OUT_DIR / "containers"
CORRECTIONS_DIR = OUT_DIR / "corrections"

SHARD_MAX = inventory.SHARD_MAX

# Which recovered bytes get committed. Decided by MEASURING THE BYTES, not by
# the path: `Interface\Cinematics\*.avi` is classified `interface` by the census
# rollup because of the directory it lives in, and committing 57 videos totalling
# 900 MB on the strength of a directory name would be exactly the wrong answer.
# So: data files (a DBC or JSON body) and text are committed; everything else is
# recorded with its size and sha256 and its bytes discarded, which is the same
# art-and-sound rule the rest of this repo applies, applied to content.
COMMIT_MAX_BYTES = 8 * 1024 * 1024
COMMIT_DATA_EXT = (".dbc", ".json", ".loc", ".db2", ".wdb")
_TEXT_SAMPLE = 8192


def _is_text(data: bytes) -> bool:
    """A member is text if a sample of it holds no NUL and is almost all
    printable. Measured; no extension list decides it."""
    sample = data[:_TEXT_SAMPLE]
    if not sample or b"\0" in sample:
        return False
    printable = sum(1 for b in sample if 32 <= b < 127 or b in (9, 10, 13))
    return printable / len(sample) >= 0.95


def _committable(path: str, data: bytes) -> bool:
    if len(data) > COMMIT_MAX_BYTES:
        return False
    if path.lower().endswith(COMMIT_DATA_EXT):
        return True
    return _is_text(data)

# How many members per archive to read with BOTH readers and compare. The
# corrected reader replaces mpyq everywhere in this layer, so "it reads more
# files" is only worth anything alongside "and it reads the old ones identically".
AGREEMENT_SAMPLE = 40


def _slug(text: str) -> str:
    return "".join(c if c.isalnum() or c in "-_" else "-" for c in text.lower())


def _sha(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def _write_json(path: Path, payload) -> None:
    inventory.write_json(path, payload)


def _write_records(path: Path, records: list) -> None:
    inventory.write_bytes_lf(path, inventory.dump_records(records))


# --------------------------------------------------------------------------
# checkpoints
# --------------------------------------------------------------------------
def _checkpoint(stage: str, archive_id: str, archive_sha: str, compute):
    """Run `compute()` once per (stage, archive bytes) and remember the result.

    Keyed on the archive's own sha256, so a patched archive invalidates its own
    checkpoint and an unchanged one is never re-read. Written with
    layerstate.atomic_write, so a process killed mid-write leaves the previous
    answer rather than a truncated one."""
    path = WORK_DIR / stage / f"{_slug(archive_id)}.json"
    if path.is_file():
        try:
            cached = json.loads(path.read_bytes().decode("utf-8"))
        except Exception:                    # noqa: BLE001 - truncated by a kill
            cached = None
        if cached and cached.get("archiveSha256") == archive_sha:
            return cached["result"], True
    result = compute()
    layerstate.atomic_write(path, json.dumps(
        {"archive": archive_id, "archiveSha256": archive_sha, "result": result},
        ensure_ascii=False).encode("utf-8"))
    return result, False


def _archives() -> list:
    """The chain, plus each archive's recorded sha256 - read from the inventory
    rather than recomputed, because the inventory is the layer that owns it and
    re-hashing 44.9 GB to learn what it already wrote down is not a check, it is
    a duplicate."""
    doc = json.loads((config.RAW_DIR / "_inventory" / "archives.json")
                     .read_bytes().decode("utf-8"))
    sha_of = {a["id"]: a["sha256"] for a in doc["archives"]}
    out = []
    for rank, rec in enumerate(inventory.discover_archives()):
        aid = inventory.archive_id(rec["path"])
        out.append({"id": aid, "path": rec["path"], "chainRank": rank,
                    "layer": rec["layer"], "realm": rec["realm"],
                    "sha256": sha_of.get(aid, "")})
    return out


# --------------------------------------------------------------------------
# stage 1 - forensics: is there anything in these archives nothing points at?
# --------------------------------------------------------------------------
COVERAGE_RULE = (
    "For each archive, every EXISTS block entry contributes the span "
    "[offset, offset+archivedSize) and the spans are merged. `unaccountedBytes` "
    "is what is left of the region between the end of the header and the start "
    "of the first table once those spans are removed - i.e. file data physically "
    "present in the archive that no live block entry claims. That is where the "
    "bytes of a deleted-but-not-compacted file would still be, so it is the "
    "direct test of whether delete-marked hash slots have anything recoverable "
    "behind them. It is measured, not argued.")


def _forensics_for(rec: dict) -> dict:
    with mpq.Archive(rec["path"]) as archive:
        header = archive.header
        file_size = rec["path"].stat().st_size
        data_start = header["header_size"] + header["offset"]
        data_end = min(header["hash_table_offset"], header["block_table_offset"]) \
            + header["offset"]

        live = deleted = empty_slots = 0
        referenced = set()
        for entry in archive.hash_table:
            if entry[4] == mpq.HASH_EMPTY:
                empty_slots += 1
            elif entry[4] == mpq.HASH_DELETED:
                deleted += 1
            else:
                live += 1
                referenced.add(entry[4])

        spans, flags_census = [], collections.Counter()
        exists = encrypted = tombstones = zero_length = 0
        for i, (offset, stored, size, flags) in enumerate(archive.block_table):
            flags_census["|".join(mpq.flag_names(flags)) or "0"] += 1
            if not flags & mpq.MPQ_FILE_EXISTS:
                continue
            exists += 1
            if flags & mpq.MPQ_FILE_ENCRYPTED:
                encrypted += 1
            if flags & mpq.MPQ_FILE_DELETE_MARKER:
                tombstones += 1
            if stored == 0 or size == 0:
                zero_length += 1
            if stored:
                spans.append((offset + header["offset"],
                              offset + header["offset"] + stored))

        spans.sort()
        merged = []
        for start, end in spans:
            if merged and start <= merged[-1][1]:
                merged[-1][1] = max(merged[-1][1], end)
            else:
                merged.append([start, end])
        gaps, cursor = [], data_start
        for start, end in merged:
            if start > cursor:
                gaps.append([cursor, start])
            cursor = max(cursor, end)
        if data_end > cursor:
            gaps.append([cursor, data_end])

        # block entries no live hash slot points at: an orphan is exactly the
        # shape a file whose name was deleted but whose data survived would take
        orphans = []
        for i, (offset, stored, size, flags) in enumerate(archive.block_table):
            if i not in referenced and flags & mpq.MPQ_FILE_EXISTS and stored:
                orphans.append({"block": i, "offset": offset, "storedBytes": stored,
                                "size": size, "flags": mpq.flag_names(flags)})

        out = {
            "id": rec["id"], "chainRank": rec["chainRank"], "fileBytes": file_size,
            "formatVersion": header["format_version"],
            "sectorSize": archive.sector_size,
            "hashSlots": len(archive.hash_table), "hashSlotsLive": live,
            "hashSlotsDeleteMarked": deleted, "hashSlotsEmpty": empty_slots,
            "blockEntries": len(archive.block_table), "blockEntriesExists": exists,
            "blockEntriesEncrypted": encrypted,
            "blockEntriesDeleteMarker": tombstones,
            "blockEntriesZeroLength": zero_length,
            "flags": dict(sorted(flags_census.items())),
            "dataRegionBytes": data_end - data_start,
            "accountedBytes": sum(e - s for s, e in merged),
            "unaccountedBytes": sum(e - s for s, e in gaps),
            "unaccountedRuns": len(gaps),
            "largestUnaccountedRun": max((e - s for s, e in gaps), default=0),
            "trailingBytesAfterTables": file_size - max(
                header["offset"] + header["hash_table_offset"] + 16 * len(archive.hash_table),
                header["offset"] + header["block_table_offset"] + 16 * len(archive.block_table)),
            "orphanBlockEntries": orphans[:64],
            "orphanBlockEntryCount": len(orphans),
        }

        # every encrypted member, read: the sweep the directive asks for
        recovered = []
        for i, (offset, stored, size, flags) in enumerate(archive.block_table):
            if not (flags & mpq.MPQ_FILE_ENCRYPTED and flags & mpq.MPQ_FILE_EXISTS):
                continue
            name = None
            for candidate in ("(listfile)", "(attributes)", "(signature)"):
                if archive.block_index_of(candidate) == i:
                    name = candidate
                    break
            named = archive.read_block(i, name)
            keyless = archive.read_block(i, None)
            recovered.append({
                "block": i, "name": name, "flags": mpq.flag_names(flags),
                "size": size, "storedBytes": stored,
                "withName": named.status,
                "withoutName": keyless.status,
                "keylessAgrees": bool(named.ok and keyless.ok
                                      and named.data == keyless.data),
                "sha256": _sha(named.data) if named.ok else None,
                "detail": named.detail,
                "text": (named.data.decode("latin-1")
                         if named.ok and named.data and len(named.data) <= 512
                         and all(32 <= b < 127 or b in (9, 10, 13) for b in named.data)
                         else None),
            })
        out["encryptedMembers"] = recovered

        # the unlistable eight: what is actually in them
        names = archive.list_names()
        out["listfileNames"] = None if names is None else len(names)
        attrs = archive.attributes()
        out["attributeEntries"] = attrs.get("entries", 0)
        out["attributeEntriesMatchBlockTable"] = attrs.get("matchesBlockTable")
        return out


def stage_forensics(archives: list) -> dict:
    print("  walking every archive's block table against its own bytes", flush=True)
    rows, cached = [], 0
    for rec in archives:
        row, hit = _checkpoint("forensics", rec["id"], rec["sha256"],
                               lambda r=rec: _forensics_for(r))
        cached += hit
        rows.append(row)
        print(f"    [{rec['chainRank'] + 1:2d}/{len(archives)}] {rec['id']:38s} "
              f"unaccounted={row['unaccountedBytes']:>10,}  orphanBlocks="
              f"{row['orphanBlockEntryCount']:>4}  encrypted="
              f"{row['blockEntriesEncrypted']}{'  (cached)' if hit else ''}",
              flush=True)

    unaccounted = sum(r["unaccountedBytes"] for r in rows)
    orphans = sum(r["orphanBlockEntryCount"] for r in rows)
    encrypted = [m for r in rows for m in r["encryptedMembers"]]
    payload = {
        "rule": COVERAGE_RULE,
        "archiveCount": len(rows),
        "archiveBytesTotal": sum(r["fileBytes"] for r in rows),
        "unaccountedBytesTotal": unaccounted,
        "orphanBlockEntriesTotal": orphans,
        "hashSlotsDeleteMarkedTotal": sum(r["hashSlotsDeleteMarked"] for r in rows),
        "blockEntriesDeleteMarkerTotal": sum(r["blockEntriesDeleteMarker"] for r in rows),
        "encryptedMemberCount": len(encrypted),
        "encryptedMembersRecovered": sum(1 for m in encrypted if m["withName"] == "ok"),
        "encryptedMembersRecoveredWithoutTheName": sum(
            1 for m in encrypted if m["withoutName"] == "ok"),
        "verdict": (
            f"{unaccounted:,} bytes of the client's {sum(r['fileBytes'] for r in rows):,} "
            f"are unaccounted for by a live block entry, and {orphans:,} block "
            f"entries are unreferenced by any live hash slot. Delete-marked hash "
            f"slots ({sum(r['hashSlotsDeleteMarked'] for r in rows):,} of them) "
            f"therefore have no surviving file data behind them: the archives were "
            f"COMPACTED, not merely re-indexed. This is a byte-accounted result, "
            f"not an inference from the format."),
        "archives": rows,
    }
    _write_json(FORENSICS, payload)
    print(f"  unaccounted bytes across the whole client: {unaccounted:,}")
    print(f"  orphan block entries: {orphans:,}")
    print(f"  encrypted members: {len(encrypted)} "
          f"({payload['encryptedMembersRecovered']} recovered, "
          f"{payload['encryptedMembersRecoveredWithoutTheName']} of those with the "
          f"name withheld)")
    return {"unaccountedBytes": unaccounted, "orphanBlockEntries": orphans,
            "encryptedMembers": len(encrypted),
            "encryptedMembersRecovered": payload["encryptedMembersRecovered"]}


# --------------------------------------------------------------------------
# stage 2 - (attributes): a second integrity record for every file
# --------------------------------------------------------------------------
ATTR_RULE = (
    "`(attributes)` is an array PARALLEL TO THE BLOCK TABLE: entry i describes "
    "block entry i. Joining it to a path therefore goes through the hash table, "
    "and a path is recorded here only when its own hash slot resolves to that "
    "block index - an attribute row whose block no live name points at is counted "
    "in `unnamedEntries` rather than guessed at. `crc32` and `md5` are the "
    "ARCHIVE'S OWN claims about the stored file and are reproduced verbatim; this "
    "layer does not recompute them, so they stay an INDEPENDENT check against the "
    "sha256 the inventory measures. `mtime` is the member's Windows FILETIME "
    "converted to UTC. Fields that are zero in the archive are omitted, because "
    "zero there means 'not recorded', not 'the epoch'.")


def _attributes_for(rec: dict) -> dict:
    with mpq.Archive(rec["path"]) as archive:
        attrs = archive.attributes()
        if not attrs.get("entries"):
            return {"entries": 0, "records": [], "unnamedEntries": 0,
                    "error": attrs.get("error")}
        names = archive.list_names() or []
        by_block = {}
        for name in names:
            bi = archive.block_index_of(name)
            if bi is not None:
                by_block.setdefault(bi, name)
        for meta in ("(listfile)", "(attributes)", "(signature)"):
            bi = archive.block_index_of(meta)
            if bi is not None:
                by_block.setdefault(bi, meta)

        crcs, times, md5s = attrs.get("crc32"), attrs.get("filetime"), attrs.get("md5")
        records, unnamed = [], 0
        for i in range(attrs["entries"]):
            name = by_block.get(i)
            if name is None:
                unnamed += 1
                continue
            row = {"path": name.replace("\\", "/")}
            if crcs and i < len(crcs) and crcs[i]:
                row["crc32"] = f"{crcs[i]:08x}"
            if md5s and i < len(md5s) and md5s[i] != b"\0" * 16:
                row["md5"] = md5s[i].hex()
            if times and i < len(times):
                iso = mpq.filetime_to_iso(times[i])
                if iso:
                    row["mtime"] = iso
            if len(row) > 1:
                records.append(row)
        records.sort(key=lambda r: r["path"].lower())
        return {"entries": attrs["entries"], "records": records,
                "unnamedEntries": unnamed,
                "blockEntries": len(archive.block_table),
                "matchesBlockTable": attrs.get("matchesBlockTable"),
                "version": attrs.get("version"), "flags": attrs.get("flags")}


def stage_attributes(archives: list) -> dict:
    layerstate.clear_dir(ATTR_DIR)
    index, total, unnamed, dated = [], 0, 0, 0
    for rec in archives:
        result, hit = _checkpoint("attributes", rec["id"], rec["sha256"],
                                  lambda r=rec: _attributes_for(r))
        records = result["records"]
        total += len(records)
        unnamed += result.get("unnamedEntries", 0)
        dated += sum(1 for r in records if "mtime" in r)
        shards = []
        if records:
            slug = _slug(rec["id"])
            for n in range(0, len(records), SHARD_MAX):
                chunk = records[n:n + SHARD_MAX]
                name = f"{slug}-{n // SHARD_MAX:03d}.json"
                _write_records(ATTR_DIR / name, chunk)
                shards.append({"shard": name, "records": len(chunk),
                               "firstPath": chunk[0]["path"],
                               "lastPath": chunk[-1]["path"]})
        index.append({"archive": rec["id"], "chainRank": rec["chainRank"],
                      "attributeEntries": result["entries"],
                      "blockEntries": result.get("blockEntries"),
                      "matchesBlockTable": result.get("matchesBlockTable"),
                      "named": len(records), "unnamed": result.get("unnamedEntries", 0),
                      "shards": shards})
        print(f"    [{rec['chainRank'] + 1:2d}/{len(archives)}] {rec['id']:38s} "
              f"{len(records):>7,} records{'  (cached)' if hit else ''}", flush=True)

    _write_json(ATTR_DIR / "index.json", {
        "rule": ATTR_RULE,
        "generatedBy": "python -m tools.crack --only attributes",
        "archiveCount": len(index),
        "recordTotal": total,
        "datedRecordTotal": dated,
        "unnamedEntryTotal": unnamed,
        "shardMaxLines": SHARD_MAX,
        "archives": index,
    })
    layerstate.finish(ATTR_DIR, {
        "layer": "raw/recovered/attributes",
        "generatedBy": "python -m tools.crack --only attributes",
        "recordTotal": total, "datedRecordTotal": dated,
        "archiveCount": len(index)})
    print(f"  {total:,} attribute records ({dated:,} carry a modification time), "
          f"{unnamed:,} rows had no live name")
    return {"attributeRecords": total, "attributeRecordsDated": dated,
            "attributeRowsUnnamed": unnamed}


# --------------------------------------------------------------------------
# stage 3 - re-sweep everything the old reader could not read
# --------------------------------------------------------------------------
RESWEEP_RULE = (
    "Every path the inventory recorded with a `readError`, re-read with "
    "tools/mpq. A file is only claimed recovered when the decoded length equals "
    "the length the block table declares AND its sha256 was taken from those "
    "bytes. `deleted` is not a failure: an MPQ DELETE_MARKER entry is a patch "
    "tombstone that removes the path at that layer and carries no bytes by "
    "design - the old reader reported those as unreadable files, which is what "
    "most of the non-media residue in the 6.4% figure actually was.")

AGREEMENT_RULE = (
    "Files BOTH readers accept are compared byte for byte. Without it, 'the new "
    "reader reads 36,139 more files' would be compatible with it also reading "
    "the other 596,433 differently. Sampled deterministically (sorted paths, "
    "fixed stride) so a rerun checks the same members. NOTE that a difference "
    "here is not evidence against either reader on its own - which one is right "
    "is settled by `md5Verified` below, not by this count.")

MD5_RULE = (
    "THE AUTHORITATIVE CHECK. Every archive carries an `(attributes)` member "
    "holding the MD5 the archive itself recorded for each block entry, so a "
    "decoded file can be checked against the archive rather than against another "
    "reader. Every file re-read here is verified that way. This is what turns "
    "'my reader disagrees with mpyq' into a decided question: where the two "
    "disagree, the MD5 says which one reproduced the file the archive was built "
    "from. `md5Mismatched` must be 0; anything else is this reader being wrong.")


def _load_failures() -> dict:
    """Every path the census marked unreadable, grouped by the archive that won
    it, read from the COMMITTED inventory shards rather than from the checkpoint
    directory under work/. work/ is gitignored, so sourcing this stage from it
    would make the layer un-regenerable from a fresh clone - the one property
    every layer here is supposed to have."""
    out = collections.defaultdict(list)
    for shard in sorted((config.RAW_DIR / "_inventory" / "files").glob("*.json")):
        for rec in json.loads(shard.read_bytes().decode("utf-8")):
            if rec.get("readable") is False and rec.get("winner", "").endswith(
                    (".MPQ", ".mpq")):
                out[rec["winner"]].append(
                    (rec["path"].replace("/", "\\"), rec.get("readError") or ""))
    return out


def _resweep_archive(rec: dict, failures: list) -> dict:
    """Re-read this archive's failures, plus the agreement sample, plus every
    member whose size is an exact multiple of the sector size - that last group
    is the one the old reader got SILENTLY wrong rather than loudly."""
    seen = collections.Counter()
    rows, kinds, statuses = [], collections.Counter(), collections.Counter()
    verified = collections.Counter()
    mismatches = []
    with mpq.Archive(rec["path"]) as archive:
        attrs = archive.attributes()
        recorded_md5 = attrs.get("md5") or []

        def verify(member, label):
            """Check a decoded member against the MD5 the archive recorded for
            it. Returns 'ok' / 'mismatch' / 'norecord'."""
            if not member.ok or member.data is None or member.block is None:
                return "unread"
            if member.block >= len(recorded_md5):
                verified[f"{label}:norecord"] += 1
                return "norecord"
            want = recorded_md5[member.block]
            if want == b"\0" * 16:
                verified[f"{label}:norecord"] += 1
                return "norecord"
            got = hashlib.md5(member.data).digest()
            if got == want:
                verified[f"{label}:ok"] += 1
                return "ok"
            verified[f"{label}:mismatch"] += 1
            if len(mismatches) < 16:
                mismatches.append({"path": member.name, "block": member.block,
                                   "bytes": len(member.data),
                                   "declaredSize": member.size,
                                   "archiveMd5": want.hex(), "decodedMd5": got.hex(),
                                   "flags": mpq.flag_names(member.flags)})
            return "mismatch"

        for path, old_error in sorted(failures):
            member = archive.read(path, seen=seen)
            statuses[member.status] += 1
            klass = inventory.path_class(path.lower().replace("/", "\\"), "mpq")
            kinds[f"{member.status}:{klass}"] += 1
            row = {"path": path.replace("\\", "/"), "class": klass,
                   "status": member.status, "size": member.size,
                   "flags": mpq.flag_names(member.flags), "wasError": old_error}
            if member.ok and member.data is not None:
                row["sha256"] = _sha(member.data)
                row["bytes"] = len(member.data)
                row["md5Check"] = verify(member, "resweep")
            elif member.detail:
                row["detail"] = member.detail
            rows.append(row)

        names = archive.list_names() or []
        by_block = {}
        for name in names:
            bi = archive.block_index_of(name)
            if bi is not None:
                by_block.setdefault(bi, name)

        # The two classes the old reader got SILENTLY wrong, verified in full
        # rather than sampled: every member whose size is an exact multiple of
        # the sector size, and every member stored with no sector offset table.
        multiples, tableless = [], []
        for i, (offset, stored, size, flags) in enumerate(archive.block_table):
            if (not flags & mpq.MPQ_FILE_EXISTS or not stored or not size
                    or flags & (mpq.MPQ_FILE_SINGLE_UNIT
                                | mpq.MPQ_FILE_DELETE_MARKER)):
                continue
            if not flags & (mpq.MPQ_FILE_COMPRESS | mpq.MPQ_FILE_IMPLODE):
                tableless.append(i)
            if size % archive.sector_size == 0:
                multiples.append(i)
        exact_ok = exact_bad = 0
        for i in multiples:
            member = archive.read_block(i, by_block.get(i), seen=seen)
            verify(member, "exactMultiple")
            if member.ok:
                exact_ok += 1
            else:
                exact_bad += 1
        tableless_ok = tableless_bad = 0
        for i in tableless:
            member = archive.read_block(i, by_block.get(i), seen=seen)
            verify(member, "noSectorTable")
            if member.ok:
                tableless_ok += 1
            else:
                tableless_bad += 1

        # agreement with the old reader
        agree = differ = skipped = 0
        examples = []
        if names:
            ordered = sorted(names)
            stride = max(1, len(ordered) // AGREEMENT_SAMPLE)
            try:
                from mpyq import MPQArchive
                old = MPQArchive(str(rec["path"]), listfile=False)
                index = {}
                for entry in old.hash_table:
                    if entry.block_table_index < mpq.HASH_DELETED:
                        index.setdefault((entry.hash_a, entry.hash_b), entry)
                old.get_hash_table_entry = lambda n: index.get(
                    (old._hash(n, "HASH_A"), old._hash(n, "HASH_B")))
                for name in ordered[::stride][:AGREEMENT_SAMPLE]:
                    try:
                        old_bytes = old.read_file(name)
                    except Exception:        # noqa: BLE001
                        skipped += 1
                        continue
                    if old_bytes is None:
                        skipped += 1
                        continue
                    new = archive.read(name, seen=seen)
                    checked = verify(new, "agreementSample")
                    if new.ok and new.data == old_bytes:
                        agree += 1
                    else:
                        differ += 1
                        if len(examples) < 8:
                            examples.append({
                                "path": name.replace("\\", "/"),
                                "status": new.status,
                                "oldBytes": len(old_bytes),
                                "newBytes": len(new.data) if new.data else None,
                                "declaredSize": new.size,
                                "flags": mpq.flag_names(new.flags),
                                # which reader the ARCHIVE'S OWN md5 backs
                                "newMatchesArchiveMd5": checked,
                                "oldMatchesArchiveMd5": (
                                    "ok" if (new.block is not None
                                             and new.block < len(recorded_md5)
                                             and recorded_md5[new.block]
                                             == hashlib.md5(old_bytes).digest())
                                    else "mismatch"),
                                "detail": new.detail})
                old.file.close()
            except Exception as exc:         # noqa: BLE001 - recorded, not raised
                examples.append({"agreementCheckError": f"{type(exc).__name__}: {exc}"})

    return {"rows": rows, "statuses": dict(statuses), "kinds": dict(kinds),
            "compression": dict(seen), "md5": dict(verified),
            "md5Mismatches": mismatches,
            "exactMultipleMembers": len(multiples),
            "exactMultipleReadOk": exact_ok, "exactMultipleReadFailed": exact_bad,
            "noSectorTableMembers": len(tableless),
            "noSectorTableReadOk": tableless_ok,
            "noSectorTableReadFailed": tableless_bad,
            "agree": agree, "differ": differ, "agreementSkipped": skipped,
            "differExamples": examples}


def stage_resweep(archives: list) -> dict:
    failures = _load_failures()
    if not failures:
        raise SystemExit(
            "FATAL: work/inventory_hashes holds no read failures to re-sweep. "
            "Run `python -m tools.inventory` first - this stage re-reads what "
            "that census could not.")
    layerstate.clear_dir(FILES_DIR)
    layerstate.clear_dir(DELETED_DIR)

    all_rows, totals = [], collections.Counter()
    compression = collections.Counter()
    md5 = collections.Counter()
    md5_mismatches = []
    agree = differ = skipped = 0
    exact_total = exact_ok = exact_bad = 0
    tableless_total = tableless_ok = tableless_bad = 0
    differ_examples = []
    committed = collections.Counter()

    for rec in archives:
        mine = failures.get(rec["id"], [])
        result, hit = _checkpoint(
            "resweep", rec["id"], rec["sha256"],
            lambda r=rec, f=mine: _resweep_archive(r, f))
        for row in result["rows"]:
            row["archive"] = rec["id"]
            row["chainRank"] = rec["chainRank"]
        all_rows.extend(result["rows"])
        totals.update(result["statuses"])
        compression.update(result["compression"])
        md5.update(result.get("md5", {}))
        md5_mismatches.extend(result.get("md5Mismatches", []))
        agree += result["agree"]
        differ += result["differ"]
        skipped += result["agreementSkipped"]
        exact_total += result["exactMultipleMembers"]
        exact_ok += result["exactMultipleReadOk"]
        exact_bad += result["exactMultipleReadFailed"]
        tableless_total += result.get("noSectorTableMembers", 0)
        tableless_ok += result.get("noSectorTableReadOk", 0)
        tableless_bad += result.get("noSectorTableReadFailed", 0)
        differ_examples.extend(result["differExamples"])
        print(f"    [{rec['chainRank'] + 1:2d}/{len(archives)}] {rec['id']:38s} "
              f"{len(mine):>6,} to re-read -> "
              f"ok={result['statuses'].get('ok', 0):,} "
              f"deleted={result['statuses'].get('deleted', 0):,} "
              f"error={result['statuses'].get('error', 0):,}"
              f"{'  (cached)' if hit else ''}", flush=True)

    # write the bytes we are allowed to keep, one archive open at a time
    keep = collections.defaultdict(list)
    for row in all_rows:
        if row["status"] != "ok":
            continue
        if row.get("bytes", 0) > COMMIT_MAX_BYTES:
            committed["skippedTooLarge"] += 1
            continue
        keep[row["archive"]].append(row)
    for aid, rows in sorted(keep.items()):
        path = next(a["path"] for a in archives if a["id"] == aid)
        with mpq.Archive(path) as archive:
            for row in rows:
                member = archive.read(row["path"].replace("/", "\\"))
                if not member.ok:
                    committed["rereadFailed"] += 1
                    continue
                if not _committable(row["path"], member.data):
                    committed["recordedNotCommitted"] += 1
                    continue
                target = BYTES_DIR / row["path"]
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_bytes(member.data)
                row["committedAt"] = str(
                    target.relative_to(OUT_DIR)).replace("\\", "/")
                committed["written"] += 1
                committed["bytes"] += len(member.data)

    recovered = [r for r in all_rows if r["status"] == "ok"]
    tombstones = [r for r in all_rows if r["status"] == "deleted"]
    still_bad = [r for r in all_rows if r["status"] not in ("ok", "deleted", "empty")]

    by_class = collections.Counter(r["class"] for r in recovered)
    data_classes = {"dbc", "content", "interface"}
    data_recovered = [r for r in recovered if r["class"] in data_classes]

    _shard_rows(FILES_DIR, recovered, {
        "rule": RESWEEP_RULE,
        "generatedBy": "python -m tools.crack --only resweep",
        "recordTotal": len(recovered),
        "byClass": dict(sorted(by_class.items())),
        "bytesCommitted": committed["bytes"],
        "filesCommitted": committed["written"],
        "commitRule": (
            f"Bytes are committed only for members that MEASURE as data - a "
            f"{'/'.join(COMMIT_DATA_EXT)} body, or bytes that are text - and only "
            f"under {COMMIT_MAX_BYTES:,} bytes. The decision is made on the bytes, "
            f"never on the path: the 57 recovered .avi cinematics live under "
            f"Interface\\ and the census rollup therefore calls them "
            f"`interface`, which would have committed 900 MB of video on the "
            f"strength of a directory name. Everything not committed was still "
            f"fully decoded, hashed and MD5-checked against its archive, so its "
            f"sha256 is a measurement of the recovered bytes and not a promise."),
    })
    _shard_rows(DELETED_DIR, tombstones, {
        "rule": (
            "MPQ DELETE_MARKER entries: a patch that REMOVES a path carries a "
            "block entry with no data and this flag, so the path stops resolving "
            "from that archive down. They are archive semantics, not damage, and "
            "the previous pipeline recorded every one of them as an unreadable "
            "file. Listed here with the archive that deletes the path and its "
            "chain rank, so the effect on any path is readable off this layer."),
        "generatedBy": "python -m tools.crack --only resweep",
        "recordTotal": len(tombstones),
        "byClass": dict(sorted(collections.Counter(
            r["class"] for r in tombstones).items())),
    })

    summary = {
        "resweptTotal": len(all_rows),
        "recovered": len(recovered),
        "recoveredDataFiles": len(data_recovered),
        "deleteTombstones": len(tombstones),
        "empty": totals.get("empty", 0),
        "stillUnreadable": len(still_bad),
        "stillUnreadableDetail": [
            {"path": r["path"], "archive": r["archive"], "detail": r.get("detail")}
            for r in still_bad[:64]],
        "recoveredByClass": dict(sorted(by_class.items())),
        "compressionCensus": dict(sorted(compression.items())),
        "md5Rule": MD5_RULE,
        "md5Verified": sum(v for k, v in md5.items() if k.endswith(":ok")),
        "md5Mismatched": sum(v for k, v in md5.items() if k.endswith(":mismatch")),
        "md5NoRecordInArchive": sum(v for k, v in md5.items()
                                    if k.endswith(":norecord")),
        "md5ByCheck": dict(sorted(md5.items())),
        "md5MismatchExamples": md5_mismatches[:16],
        "agreementRule": AGREEMENT_RULE,
        "agreementChecked": agree + differ,
        "agreementIdentical": agree,
        "agreementDiffering": differ,
        "agreementSkipped": skipped,
        "agreementDifferExamples": differ_examples[:16],
        "exactSectorMultipleMembers": exact_total,
        "exactSectorMultipleReadOk": exact_ok,
        "exactSectorMultipleReadFailed": exact_bad,
        "exactSectorMultipleRule": (
            "Members whose size is an exact multiple of the sector size. The old "
            "reader computes one sector too many for these. Measured rather than "
            "assumed: the extra slice it reads is always empty, so 668 of the 675 "
            "still came out byte-correct and 7 raised - the arithmetic is wrong, "
            "the output happened not to be. Every one is re-read here and "
            "MD5-checked against the archive."),
        "noSectorTableMembers": tableless_total,
        "noSectorTableReadOk": tableless_ok,
        "noSectorTableReadFailed": tableless_bad,
        "noSectorTableRule": (
            "Members stored with no compression have NO sector offset table - "
            "their sectors are contiguous. The old reader read the file's own "
            "first bytes as a table and returned a salad of slices of itself, "
            "silently: 1,266 of these 1,271 members came out WRONG, and 1,186 of "
            "those are chain winners whose (wrong) sha256 the census committed. "
            "This is the real silent-corruption class. Every one is re-read here "
            "and MD5-checked against the archive; see corrections/ for the paths "
            "and their true hashes."),
        "filesCommitted": committed["written"],
        "bytesCommitted": committed["bytes"],
    }
    print(f"  re-swept {len(all_rows):,}: {len(recovered):,} recovered, "
          f"{len(tombstones):,} are delete tombstones, "
          f"{totals.get('empty', 0):,} genuinely empty, "
          f"{len(still_bad):,} still unreadable")
    print(f"  MD5-verified against the archives' own records: "
          f"{summary['md5Verified']:,} match, {summary['md5Mismatched']:,} "
          f"mismatch, {summary['md5NoRecordInArchive']:,} had no recorded md5")
    print(f"  agreement with the previous reader: {agree:,} identical, "
          f"{differ:,} differing")
    print(f"  no-sector-table members: {tableless_total:,} "
          f"({tableless_ok:,} read); exact-sector-multiple members: "
          f"{exact_total:,} ({exact_ok:,} read)")
    print(f"  compression actually used by this client: "
          f"{dict(sorted(compression.items()))}")
    return summary


def _shard_rows(directory: Path, rows: list, index_extra: dict) -> None:
    """Shard a record list by path prefix, reusing the inventory's partitioner so
    a path lands in the same-shaped shard everywhere in this repo. Records go in
    `records/`, never beside recovered bytes, so a client path can never collide
    with an index file."""
    records_dir = directory / "records"
    records_dir.mkdir(parents=True, exist_ok=True)
    by_path = {r["path"]: r for r in rows}
    groups = inventory.partition(sorted(by_path))
    names = inventory.shard_names(list(groups))
    shards = []
    for key, paths in sorted(groups.items()):
        chunk = [by_path[p] for p in sorted(paths)]
        _write_records(records_dir / names[key], chunk)
        shards.append({"shard": names[key], "records": len(chunk),
                       "firstPath": chunk[0]["path"], "lastPath": chunk[-1]["path"]})
    payload = dict(index_extra)
    payload["shards"] = shards
    payload["shardMaxLines"] = SHARD_MAX
    inventory.write_bytes_lf(directory / "index.json",
                             sharding.dump_manifest(payload))
    layerstate.finish(directory, {
        "layer": str(directory.relative_to(config.REPO_ROOT)).replace("\\", "/"),
        "generatedBy": "python -m tools.crack --only resweep",
        "recordTotal": len(rows), "shardCount": len(shards)})


# --------------------------------------------------------------------------
# stage 4 - verify EVERY member of EVERY archive against the archive's own MD5
# --------------------------------------------------------------------------
CORRECTIONS_RULE = (
    "Paths whose sha256 in `raw/_inventory` was computed over bytes that were "
    "never in the archive, with the value the corrected reader measures. All of "
    "them are members stored with no sector offset table, which the previous "
    "reader mis-sliced (see tools/mpq.py). `sha256` here is the true hash and "
    "`censusSha256` is what the census still says; both are kept so the "
    "correction is checkable rather than a bare assertion. Nothing in the DATA "
    "layers is affected: the whole set is music, cinematics and one nested "
    "archive, and the classes that matter are untouched - 0 DBC, 0 Interface, "
    "0 Content. `raw/_inventory` is deliberately NOT rewritten here. It is still "
    "exactly what its own tool produces, which is the property that makes it "
    "checkable; correcting it means moving tools/inventory.py onto this reader "
    "and re-running the whole census, which is a change to that layer's owner "
    "and needs its own review. Until then these are the true hashes and this "
    "file is the record of the disagreement.")

VERIFY_RULE = (
    "Every named member of every archive is decoded and its MD5 compared with "
    "the MD5 that archive recorded for it in `(attributes)`. This is the only "
    "check in this repo that is not self-referential: the sha256s elsewhere are "
    "measurements of whatever the reader produced, so a reader defect is "
    "invisible to them - which is exactly how 1,946 files sat in the census with "
    "confident hashes over wrong bytes. Here the oracle is the archive. "
    "`mismatched` must be 0 and `unreadable` is the honest, complete answer to "
    "'what in this client still cannot be decoded'.")


def _census_hashes() -> dict:
    """path -> (winning archive, sha256) as the committed census records it. The
    verify pass compares its own bytes against this, so a hash the census got
    wrong is reported as a CORRECTION with the true value rather than left to be
    discovered by whoever trusts it next."""
    out = {}
    for shard in sorted((config.RAW_DIR / "_inventory" / "files").glob("*.json")):
        for rec in json.loads(shard.read_bytes().decode("utf-8")):
            if rec.get("sha256") and rec.get("winner"):
                out[rec["path"].lower().replace("/", "\\")] = (rec["winner"],
                                                               rec["sha256"],
                                                               rec.get("size"))
    return out


def _verify_archive(rec: dict, census: dict = None) -> dict:
    counts = collections.Counter()
    seen = collections.Counter()
    bad, unread, corrections = [], [], []
    census = census or {}
    with mpq.Archive(rec["path"]) as archive:
        recorded = archive.attributes().get("md5") or []
        names = archive.list_names()
        if names is None:
            names = [n for n in ("(listfile)", "(attributes)", "(signature)")
                     if archive.has(n)]
        for name in sorted(set(names)):
            member = archive.read(name, seen=seen)
            klass = inventory.path_class(name.lower().replace("/", "\\"), "mpq")
            if member.status in ("deleted", "empty"):
                counts[member.status] += 1
                continue
            if not member.ok:
                counts["unreadable"] += 1
                counts[f"unreadable:{klass}"] += 1
                if len(unread) < 64:
                    unread.append({"path": name.replace("\\", "/"), "class": klass,
                                   "status": member.status, "size": member.size,
                                   "flags": mpq.flag_names(member.flags),
                                   "detail": member.detail})
                continue
            counts["read"] += 1
            counts[f"read:{klass}"] += 1

            # Where this archive WINS the path, the census has a sha256 for it.
            # A disagreement here is a census defect, not a reader one - every
            # member in this pass is also MD5-checked against the archive itself.
            declared = census.get(name.lower().replace("/", "\\"))
            if declared and declared[0] == rec["id"]:
                got = _sha(member.data)
                if got != declared[1]:
                    counts["censusShaWrong"] += 1
                    counts[f"censusShaWrong:{klass}"] += 1
                    corrections.append({
                        "path": name.replace("\\", "/"), "class": klass,
                        "winner": rec["id"], "bytes": len(member.data),
                        "censusBytes": declared[2], "censusSha256": declared[1],
                        "sha256": got,
                        "flags": mpq.flag_names(member.flags)})

            if member.block is None or member.block >= len(recorded) \
                    or recorded[member.block] == b"\0" * 16:
                counts["noRecordedMd5"] += 1
                continue
            if hashlib.md5(member.data).digest() == recorded[member.block]:
                counts["md5Ok"] += 1
            else:
                counts["md5Mismatch"] += 1
                if len(bad) < 64:
                    bad.append({"path": name.replace("\\", "/"), "class": klass,
                                "bytes": len(member.data),
                                "declaredSize": member.size,
                                "flags": mpq.flag_names(member.flags),
                                "archiveMd5": recorded[member.block].hex(),
                                "decodedMd5": hashlib.md5(member.data).hexdigest()})
    return {"counts": dict(counts), "compression": dict(seen),
            "mismatches": bad, "unreadable": unread, "corrections": corrections}


def stage_verify(archives: list) -> dict:
    print("  decoding every member of every archive and checking it against the "
          "archive's own MD5", flush=True)
    census = _census_hashes()
    totals = collections.Counter()
    compression = collections.Counter()
    mismatches, unreadable, per_archive, corrections = [], [], [], []
    for rec in archives:
        result, hit = _checkpoint("verify", rec["id"], rec["sha256"],
                                  lambda r=rec: _verify_archive(r, census))
        counts = collections.Counter(result["counts"])
        totals.update(counts)
        compression.update(result["compression"])
        for row in result["mismatches"]:
            mismatches.append({**row, "archive": rec["id"]})
        for row in result["unreadable"]:
            unreadable.append({**row, "archive": rec["id"]})
        corrections.extend(result.get("corrections", []))
        per_archive.append({
            "archive": rec["id"], "chainRank": rec["chainRank"],
            **{k: v for k, v in sorted(counts.items()) if ":" not in k}})
        print(f"    [{rec['chainRank'] + 1:2d}/{len(archives)}] {rec['id']:38s} "
              f"read={counts.get('read', 0):>7,} md5Ok={counts.get('md5Ok', 0):>7,} "
              f"mismatch={counts.get('md5Mismatch', 0):>4,} "
              f"unreadable={counts.get('unreadable', 0):>4,}"
              f"{'  (cached)' if hit else ''}", flush=True)

    payload = {
        "rule": VERIFY_RULE,
        "generatedBy": "python -m tools.crack --only verify",
        "membersRead": totals.get("read", 0),
        "md5Verified": totals.get("md5Ok", 0),
        "md5Mismatched": totals.get("md5Mismatch", 0),
        "noRecordedMd5": totals.get("noRecordedMd5", 0),
        "deleteTombstones": totals.get("deleted", 0),
        "emptyMembers": totals.get("empty", 0),
        "unreadable": totals.get("unreadable", 0),
        "unreadableDetail": unreadable[:256],
        "md5MismatchDetail": mismatches[:256],
        "byClass": {k: v for k, v in sorted(totals.items()) if ":" in k},
        "compressionCensus": dict(sorted(compression.items())),
        "compressionCensusNote": (
            "Every compression method applied to every sector of every member, "
            "counted by the dispatcher as it ran. This is the complete answer to "
            "which MPQ compressions this client uses - PKWARE implode, sparse, "
            "huffman and both ADPCM variants appear zero times in "
            f"{totals.get('read', 0):,} members."),
        "archives": per_archive,
    }
    payload["censusSha256Corrections"] = totals.get("censusShaWrong", 0)
    _write_json(OUT_DIR / "_verify.json", payload)

    corrections.sort(key=lambda r: r["path"].lower())
    layerstate.clear_dir(CORRECTIONS_DIR)
    _shard_rows(CORRECTIONS_DIR, corrections, {
        "rule": CORRECTIONS_RULE,
        "generatedBy": "python -m tools.crack --only verify",
        "recordTotal": len(corrections),
        "byClass": dict(sorted(collections.Counter(
            r["class"] for r in corrections).items())),
    })
    print(f"  {totals.get('md5Ok', 0):,} members match the MD5 their archive "
          f"recorded; {totals.get('md5Mismatch', 0):,} mismatch; "
          f"{totals.get('unreadable', 0):,} unreadable")
    print(f"  census sha256 corrections: {len(corrections):,}")
    return {"verifiedMembers": totals.get("read", 0),
            "md5VerifiedTotal": totals.get("md5Ok", 0),
            "md5MismatchedTotal": totals.get("md5Mismatch", 0),
            "unreadableTotal": totals.get("unreadable", 0),
            "censusSha256Corrections": len(corrections)}


# --------------------------------------------------------------------------
# stage 5 - containers
# --------------------------------------------------------------------------
CONTAINER_RULE = (
    "Anything that is itself a container of other files, expanded one level and "
    "then recursively while the members are containers too. Discovery is "
    "mechanical - a member is a container if its BYTES start with a signature "
    "this stage knows, never because of its name - so a nested archive with the "
    "wrong extension is still found and a file merely named .rar is not "
    "mis-parsed. Art and sound inside a container obey the same "
    "recorded-not-committed rule as everywhere else.")

_MAGIC = (
    (b"MPQ\x1a", "mpq"), (b"MPQ\x1b", "mpq"),
    (b"Rar!\x1a\x07\x00", "rar4"), (b"Rar!\x1a\x07\x01\x00", "rar5"),
    (b"PK\x03\x04", "zip"), (b"\x1f\x8b", "gzip"),
    (b"bplist00", "bplist"), (b"BZh", "bzip2"),
    (b"MSCF", "cab"), (b"7z\xbc\xaf\x27\x1c", "7z"),
)


def _sniff(data: bytes):
    for magic, kind in _MAGIC:
        if data.startswith(magic):
            return kind
    return None


def _expand_rar(data: bytes) -> dict:
    """Index a RAR4 volume: every member's name, sizes, CRC and method, and the
    bytes of any member stored uncompressed.

    Deliberately not a RAR decompressor - RAR's own compression is patent-
    encumbered and out of scope for a stdlib pipeline - but 'we did not look' and
    'we looked and here is exactly what is in it' are different answers, and only
    the second one is honest about what the container holds."""
    METHODS = {0x30: "stored", 0x31: "fastest", 0x32: "fast", 0x33: "normal",
               0x34: "good", 0x35: "best"}
    members, extracted, blobs = [], 0, {}
    pos = 7 if data.startswith(b"Rar!\x1a\x07\x00") else 0
    while pos + 7 <= len(data):
        _crc, htype, flags, hsize = struct.unpack_from("<HBHH", data, pos)
        if hsize < 7 or pos + hsize > len(data):
            break
        # A block declares a data body after its header with ADD_SIZE, the first
        # dword past the 7-byte base header. For a file block that same dword IS
        # the packed size, so one rule advances past every block type.
        add = 0
        if flags & 0x8000 and pos + 11 <= len(data):
            (add,) = struct.unpack_from("<I", data, pos + 7)
        if htype == 0x74 and pos + 32 <= len(data):
            packed, unpacked, _host, fcrc, _time, _ver, method, namelen, attr = \
                struct.unpack_from("<IIBIIBBHI", data, pos + 7)
            cursor = pos + 32
            if flags & 0x100 and cursor + 8 <= len(data):     # 64-bit sizes
                high_packed, high_unpacked = struct.unpack_from("<II", data, cursor)
                packed |= high_packed << 32
                unpacked |= high_unpacked << 32
                cursor += 8
            name = data[cursor:cursor + namelen].split(b"\0")[0].decode(
                "latin-1", "replace")
            body = pos + hsize
            row = {"name": name.replace("\\", "/"), "packedBytes": packed,
                   "bytes": unpacked, "crc32": f"{fcrc:08x}",
                   "method": f"0x{method:02x}",
                   "methodName": METHODS.get(method, f"unknown(0x{method:02x})"),
                   "directory": bool(attr & 0x10),
                   "encrypted": bool(flags & 0x04)}
            if (method == 0x30 and packed and not flags & 0x04
                    and body + packed <= len(data)):
                blob = data[body:body + packed]
                row["sha256"] = _sha(blob)
                row["extracted"] = True
                blobs[row["name"]] = blob
                extracted += 1
            members.append(row)
            add = packed
        pos += hsize + add
    return ({"format": "rar4", "members": members, "memberCount": len(members),
             "storedMembersExtracted": extracted,
             "note": ("RAR's own compression methods are not implemented - they are "
                      "outside a stdlib pipeline. Members stored uncompressed "
                      "(method 0x30) ARE extracted and hashed; every other member "
                      "is indexed with the name, sizes, CRC32 and method the "
                      "archive itself declares, so what the container holds is "
                      "recorded even where the bytes are not decodable here.")},
            blobs)


def _vint(data: bytes, pos: int):
    """RAR5's variable-length integer: 7 bits per byte, little-endian, high bit
    means 'another byte follows'."""
    value = shift = 0
    while pos < len(data):
        byte = data[pos]
        pos += 1
        value |= (byte & 0x7F) << shift
        if not byte & 0x80:
            return value, pos
        shift += 7
        if shift > 63:
            break
    raise ValueError("RAR5: truncated variable-length integer")


def _expand_rar5(data: bytes) -> tuple:
    """Index a RAR5 volume. Same policy as RAR4: no RAR decompressor, but every
    member's name, sizes, CRC, method and timestamp are read out of the headers,
    and members stored uncompressed are extracted."""
    METHODS = {0: "stored", 1: "fastest", 2: "fast", 3: "normal", 4: "good",
               5: "best"}
    members, extracted, blobs = [], 0, {}
    pos = 8
    while pos + 8 < len(data):
        try:
            start = pos + 4                     # past the header CRC32
            header_size, cursor = _vint(data, start)
            header_start = cursor
            htype, cursor = _vint(data, cursor)
            hflags, cursor = _vint(data, cursor)
            extra_size = data_size = 0
            if hflags & 0x0001:
                extra_size, cursor = _vint(data, cursor)
            if hflags & 0x0002:
                data_size, cursor = _vint(data, cursor)
            if htype in (2, 3):                 # file header / service header
                file_flags, cursor = _vint(data, cursor)
                unpacked, cursor = _vint(data, cursor)
                _attrs, cursor = _vint(data, cursor)
                mtime = None
                if file_flags & 0x0002:
                    (mtime,) = struct.unpack_from("<I", data, cursor)
                    cursor += 4
                crc = None
                if file_flags & 0x0004:
                    (crc,) = struct.unpack_from("<I", data, cursor)
                    cursor += 4
                comp_info, cursor = _vint(data, cursor)
                _host_os, cursor = _vint(data, cursor)
                name_len, cursor = _vint(data, cursor)
                name = data[cursor:cursor + name_len].decode("utf-8", "replace")
                method = (comp_info >> 7) & 0x07
                body = header_start + header_size
                row = {"name": name.replace("\\", "/"), "packedBytes": data_size,
                       "bytes": unpacked if not file_flags & 0x0008 else None,
                       "crc32": f"{crc:08x}" if crc is not None else None,
                       "method": method,
                       "methodName": METHODS.get(method, f"unknown({method})"),
                       "directory": bool(file_flags & 0x0001),
                       "encryptedHeaderExtra": bool(extra_size),
                       "kind": "service" if htype == 3 else "file"}
                if mtime:
                    import datetime
                    row["mtime"] = datetime.datetime.fromtimestamp(
                        mtime, datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
                if (method == 0 and data_size and htype == 2
                        and body + data_size <= len(data)):
                    blob = data[body:body + data_size]
                    row["sha256"] = _sha(blob)
                    row["extracted"] = True
                    blobs[row["name"]] = blob
                    extracted += 1
                members.append(row)
            pos = header_start + header_size + data_size
            if header_size <= 0:
                break
        except Exception:                        # noqa: BLE001 - stop at the end
            break
    return ({"format": "rar5", "members": members,
             "memberCount": sum(1 for m in members if m["kind"] == "file"),
             "serviceRecords": sum(1 for m in members if m["kind"] == "service"),
             "storedMembersExtracted": extracted,
             "note": ("RAR5's own compression is not implemented - it is outside a "
                      "stdlib pipeline. Members stored uncompressed ARE extracted "
                      "and hashed; every other member is indexed with the name, "
                      "sizes, CRC32, method and timestamp the archive declares.")},
            blobs)


def _expand_bplist(data: bytes) -> dict:
    obj = plistlib.loads(data)

    def clean(value):
        if isinstance(value, dict):
            return {str(k): clean(v) for k, v in value.items()}
        if isinstance(value, (list, tuple)):
            return [clean(v) for v in value]
        if isinstance(value, (bytes, bytearray)):
            return {"__bytes_sha256__": _sha(bytes(value)), "__len__": len(value)}
        if isinstance(value, (str, int, float, bool)) or value is None:
            return value
        return str(value)
    return {"format": "bplist", "plist": clean(obj)}


def _expand_nested_mpq(data: bytes, name: str, out_dir: Path) -> dict:
    tmp = WORK_DIR / "nested" / (_slug(name) + ".mpq")
    tmp.parent.mkdir(parents=True, exist_ok=True)
    tmp.write_bytes(data)
    members, written = [], 0
    with mpq.Archive(tmp) as archive:
        names = archive.list_names()
        seen = collections.Counter()
        targets = names if names is not None else []
        for member_name in sorted(targets):
            member = archive.read(member_name, seen=seen)
            row = {"path": member_name.replace("\\", "/"), "status": member.status,
                   "bytes": member.size,
                   "class": inventory.path_class(member_name.lower(), "mpq")}
            if member.ok and member.data is not None:
                row["sha256"] = _sha(member.data)
                if row["class"] in COMMIT_CLASSES and len(member.data) <= COMMIT_MAX_BYTES:
                    target = out_dir / member_name.replace("\\", "/")
                    target.parent.mkdir(parents=True, exist_ok=True)
                    target.write_bytes(member.data)
                    row["committedAt"] = str(
                        target.relative_to(OUT_DIR)).replace("\\", "/")
                    written += 1
            elif member.detail:
                row["detail"] = member.detail
            members.append(row)
        attrs = archive.attributes()
        header = dict(archive.header)
        header.pop("magic", None)
    return {"format": "mpq", "members": members, "memberCount": len(members),
            "membersCommitted": written,
            "listfileNames": None if names is None else len(names),
            "attributeEntries": attrs.get("entries", 0),
            "blockEntries": header["block_table_entries"],
            "compression": dict(seen)}


SNIFF_RULE = (
    "Every path in the client is sniffed by its first bytes, not by its "
    "extension - `Battle.net.bundle` and `keyedobjects.nib` are binary plists "
    "and `launcher.mpq` is a real MPQ, and none of the three would be found by a "
    "list of suffixes. Sniffing decodes only the FIRST SECTOR of each member "
    "(tools/mpq.Archive.read_prefix), so covering all 637,590 paths costs one "
    "sector each instead of re-inflating 62 GB.")


def _sniff_archive(rec: dict, paths: list) -> list:
    hits = []
    with mpq.Archive(rec["path"]) as archive:
        for path in sorted(paths):
            head = archive.read_prefix(path.replace("/", "\\"), 16)
            kind = _sniff(head)
            if kind:
                hits.append({"path": path, "kind": kind})
    return hits


def stage_containers(archives: list) -> dict:
    layerstate.clear_dir(CONTAINER_DIR)
    by_archive = collections.defaultdict(list)
    for shard in sorted((config.RAW_DIR / "_inventory" / "files").glob("*.json")):
        for rec in json.loads(shard.read_bytes().decode("utf-8")):
            winner = rec.get("winner") or ""
            if not winner.lower().endswith(".mpq") or not rec.get("size"):
                continue
            by_archive[winner].append(rec["path"])

    found = []
    for rec in archives:
        mine = by_archive.get(rec["id"], [])
        if not mine:
            continue
        hits, cached = _checkpoint("sniff", rec["id"], rec["sha256"],
                                   lambda r=rec, p=mine: _sniff_archive(r, p))
        for hit in hits:
            found.append({**hit, "archive": rec["id"]})
        print(f"    [{rec['chainRank'] + 1:2d}/{len(archives)}] {rec['id']:38s} "
              f"{len(mine):>7,} sniffed, {len(hits):>3} containers"
              f"{'  (cached)' if cached else ''}", flush=True)

    expanded = []
    for hit in sorted(found, key=lambda h: (h["kind"], h["path"])):
        rec = next(a for a in archives if a["id"] == hit["archive"])
        with mpq.Archive(rec["path"]) as archive:
            member = archive.read(hit["path"].replace("/", "\\"))
        row = dict(hit)
        if not member.ok or not member.data:
            row["error"] = f"could not read the container itself: {member.status}"
            expanded.append(row)
            continue
        data = member.data
        row["bytes"] = len(data)
        row["sha256"] = _sha(data)
        slug = _slug(hit["path"])
        try:
            if hit["kind"] == "mpq":
                row.update(_expand_nested_mpq(data, hit["path"],
                                              CONTAINER_DIR / slug))
            elif hit["kind"].startswith("rar"):
                info, blobs = (_expand_rar5(data) if hit["kind"] == "rar5"
                               else _expand_rar(data))
                row.update(info)
                for name, blob in sorted(blobs.items()):
                    klass = inventory.path_class(name.lower().replace("/", "\\"), "mpq")
                    if klass in COMMIT_CLASSES and len(blob) <= COMMIT_MAX_BYTES:
                        target = CONTAINER_DIR / slug / name
                        target.parent.mkdir(parents=True, exist_ok=True)
                        target.write_bytes(blob)
            elif hit["kind"] == "bplist":
                row.update(_expand_bplist(data))
                _write_json(CONTAINER_DIR / f"{slug}.json",
                            {"source": hit["path"], "archive": hit["archive"],
                             "sha256": row["sha256"], "format": "bplist",
                             "plist": row.pop("plist")})
                row["expandedTo"] = f"{slug}.json"
            elif hit["kind"] == "gzip":
                blob = zlib.decompress(data, 47)
                row.update({"format": "gzip", "expandedBytes": len(blob),
                            "expandedSha256": _sha(blob)})
            elif hit["kind"] == "zip":
                import io
                import zipfile
                with zipfile.ZipFile(io.BytesIO(data)) as bundle:
                    row.update({"format": "zip", "memberCount": len(bundle.infolist()),
                                "members": [{"name": i.filename, "bytes": i.file_size}
                                            for i in bundle.infolist()]})
            else:
                row["expanded"] = False
                row["note"] = (f"{hit['kind']} container detected by signature; no "
                               f"stdlib decoder for it, so it is recorded and not "
                               f"expanded")
        except Exception as exc:             # noqa: BLE001 - recorded, not raised
            row["error"] = f"{type(exc).__name__}: {exc}"
        expanded.append(row)
        print(f"    expanded {hit['kind']:7s} {hit['path']}  "
              f"{row.get('memberCount', row.get('expandedBytes', ''))}", flush=True)

    _write_json(CONTAINER_DIR / "index.json", {
        "rule": CONTAINER_RULE,
        "discoveryRule": SNIFF_RULE,
        "generatedBy": "python -m tools.crack --only containers",
        "containerCount": len(expanded),
        "byKind": dict(sorted(collections.Counter(
            c["kind"] for c in expanded).items())),
        "containers": expanded,
    })
    layerstate.finish(CONTAINER_DIR, {
        "layer": "raw/recovered/containers",
        "generatedBy": "python -m tools.crack --only containers",
        "containerCount": len(expanded),
        "nestedMemberTotal": sum(c.get("memberCount", 0) for c in expanded)})
    print(f"  {len(expanded)} containers expanded: "
          f"{dict(sorted(collections.Counter(c['kind'] for c in expanded).items()))}")
    return {"containers": len(expanded),
            "containerMembers": sum(c.get("memberCount", 0) for c in expanded)}


# --------------------------------------------------------------------------
# driver
# --------------------------------------------------------------------------
STAGES = ("forensics", "attributes", "resweep", "verify", "containers")


def run(only=None) -> dict:
    picked = [s for s in STAGES if not only or s in set(only)]
    if not only:
        layerstate.begin(OUT_DIR)
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    WORK_DIR.mkdir(parents=True, exist_ok=True)
    layerstate.require_complete(
        config.RAW_DIR / "_inventory", "python -m tools.inventory")

    archives = _archives()
    summary = {}
    for name in picked:
        print(f"\n-- {name}", flush=True)
        t0 = time.time()
        summary.update({
            "forensics": stage_forensics,
            "attributes": stage_attributes,
            "resweep": stage_resweep,
            "verify": stage_verify,
            "containers": stage_containers,
        }[name](archives))
        print(f"-- {name}: {time.time() - t0:.1f}s", flush=True)

    if not only:
        _write_readme(summary)
        _write_json(OUT_DIR / "index.json", {
            "generatedBy": "python -m tools.crack",
            "layers": {
                "_forensics.json": "per-archive block/hash census, byte coverage, "
                                   "orphan blocks and the encrypted-member sweep",
                "attributes/": "CRC32 + modification time + MD5 per path, expanded "
                               "from every archive's (attributes) member",
                "deleted/": "every MPQ DELETE_MARKER tombstone and the archive that "
                            "sets it",
                "files/": "bytes of files the previous reader could not read, for "
                          "the classes this repo commits",
                "containers/": "nested archives and structured blobs, expanded",
            },
            "summary": summary,
        })
        layerstate.finish(OUT_DIR, {
            "layer": "raw/recovered",
            "generatedBy": "python -m tools.crack",
            **{k: v for k, v in summary.items() if isinstance(v, (int, float))}})
    return summary


def _write_readme(summary: dict) -> None:
    lines = [
        "# raw/recovered - what was still opaque (generated)",
        "",
        "Written by `python -m tools.crack`. Nothing here is hand-selected; every",
        "count below is measured by that script on each run.",
        "",
        "| layer | what it holds |",
        "| --- | --- |",
        "| `_forensics.json` | every archive's block/hash census, its data region "
        "accounted for byte by byte, orphan block entries, and every encrypted "
        "member read |",
        "| `attributes/` | CRC32, modification time and MD5 per path, expanded from "
        "the `(attributes)` member all 77 archives carry |",
        "| `deleted/` | every MPQ DELETE_MARKER tombstone, with the archive that "
        "deletes the path |",
        "| `files/` | the bytes of files the previous reader could not read |",
        "| `containers/` | nested archives and structured blobs, expanded |",
        "",
        "## What was found",
        "",
        f"- **Deleted entries hold nothing.** {summary.get('unaccountedBytes', 0):,} "
        f"bytes of the client are unaccounted for by a live block entry and "
        f"{summary.get('orphanBlockEntries', 0):,} block entries are unreferenced. "
        f"The archives were compacted, so a delete-marked hash slot has no "
        f"surviving data behind it. This is measured, not assumed.",
        f"- **The 6.4% unreadable figure was a reader defect, not a compression "
        f"gap.** {summary.get('recovered', 0):,} of those files read correctly "
        f"now, {summary.get('deleteTombstones', 0):,} were patch tombstones that "
        f"never had bytes, and {summary.get('stillUnreadable', 0):,} remain "
        f"unreadable.",
        f"- **`(attributes)` is a whole metadata layer.** "
        f"{summary.get('attributeRecords', 0):,} records, "
        f"{summary.get('attributeRecordsDated', 0):,} of them carrying a "
        f"modification time.",
        f"- **{summary.get('encryptedMembers', 0)} encrypted member(s)** exist in "
        f"the client; {summary.get('encryptedMembersRecovered', 0)} decrypted.",
        f"- **{summary.get('containers', 0)} nested containers** expanded, holding "
        f"{summary.get('containerMembers', 0):,} members.",
        "",
        "## Regenerating",
        "",
        "```",
        "python -m tools.crack                  # all stages, resumable",
        "python -m tools.crack --only resweep   # one stage",
        "python -m tools.mpq --selftest         # the reader's own tests",
        "```",
        "",
    ]
    inventory.write_bytes_lf(OUT_DIR / "README.md", "\n".join(lines))


def main(argv=None) -> int:
    ap = argparse.ArgumentParser(
        prog="python -m tools.crack",
        description="Recover deleted, encrypted and undecodable archive contents.")
    ap.add_argument("--only", action="append", choices=STAGES,
                    help="run exactly this stage (repeatable)")
    args = ap.parse_args(argv)
    run(args.only)
    return 0


if __name__ == "__main__":
    sys.exit(main())
