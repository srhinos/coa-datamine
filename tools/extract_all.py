"""Extract EVERY DBFilesClient table in the winning MPQ chain - no wanted list.

This is step 1 of the raw table layer. Step 2 is tools/decode_all.py, which is
also the single entry point (it runs this module when its input is missing or
stale). Run either directly:

    python -m tools.extract_all          # extraction only
    python -m tools.decode_all           # extraction (if needed) + decode

WHAT MAKES THIS DIFFERENT FROM tools/extract_mpq.py
---------------------------------------------------
tools/extract_mpq.py extracts config.WANTED_DBCS - a hand-maintained list, which
is exactly the selective-extraction failure this layer exists to end. This module
has no list. It takes every path in the chain whose directory is the client's
table directory, whatever it is called, however many there are.

NON-NEGOTIABLES
---------------
COMPLETE    Every table any listable archive names is extracted. The archives
            that cannot be listed are probed by hash table for every harvested
            name, and a hit that OUTRANKS the current winner stops the run - a
            silently-wrong winner is the failure mode being designed out. A file
            that cannot be read is recorded in the failures list with its error,
            never dropped.
MECHANICAL  Chain order is tools/inventory.discover_archives() (the same loader
            order the census used, realm overlay above the whole base chain). The
            winner of a path is the last carrier in that order. Nothing here
            knows any table by name, and no table gets special handling.
RERUNNABLE  One command, no arguments, no agent. Output is a pure function of
            the client bytes: no wall-clock time is written, everything is
            sorted, and the run's identity is the per-file sha256.
"""
import argparse
import hashlib
import json
import struct
import time
from pathlib import Path

from tools import config, layerstate, mpq, probe_unlistable, sharding
from tools.inventory import archive_id, discover_archives

OUT_DIR = config.WORK_DIR / "dbc_all"
PROVENANCE = OUT_DIR / "_extract.json"

# The client's table directory, lowercased with a trailing separator. This is a
# LOCATION in the archive namespace, not a table name - the one string this
# module needs in order to know where tables live.
TABLE_DIR = "dbfilesclient\\"

HEADER = struct.Struct("<4s4I")

READ_ATTEMPTS = 3

READER_RULE = (
    "Members are decoded by tools/mpq.py, this repo's own reader, NOT by mpyq. "
    "mpyq mis-slices two whole classes of member - one stored with no sector "
    "offset table, and one whose size is an exact multiple of the sector size - "
    "and it does it SILENTLY, returning confident wrong bytes; that defect put "
    "1,186 wrong sha256 values into the file census (see "
    "raw/recovered/corrections/). No DBC was among them, which is why this path "
    "was left on mpyq longer than the rest: 'provably harmless today' is not the "
    "same as 'read by the corrected reader', and only the second one stays true "
    "when the client changes. Every member here is additionally checked against "
    "the MD5 its own archive recorded for it by tools/crack.py's verify stage, "
    "which is an oracle outside this code."
)

READ_AGREEMENT_RULE = (
    "Every member is read until two consecutive reads of it hash the same, at "
    f"most {READ_ATTEMPTS} times. A member whose reads never agree is recorded "
    "as a failure rather than written. The reads are done by tools/mpq.py - see "
    "READER_RULE, which is part of this rule because a repeated read only "
    "guards against a NONDETERMINISTIC fault, never against a reader defect "
    "(that one returns the same wrong bytes every time and two reads agree on "
    "it perfectly).\n\n"
    "WHY, stated at the strength the evidence actually supports. One member was "
    "once written into this layer differing from its archive's own recorded "
    "bytes in 2 places out of 115 MB - same length, valid header, silently "
    "wrong rows, and a sha256 that faithfully recorded the damage. That "
    "observation is real and was never reproduced or root-caused. It sat "
    "alongside a broader claim that this machine has 'confirmed memory "
    "corruption'; that claim is NOT supported at that strength and is scoped "
    "down here - see HOST_FAULT_SCOPE in tools/crack.py. The current "
    "measurement runs the other way: tools/crack.py's verify stage decoded "
    "763,928 members and checked every one against the MD5 its own archive "
    "recorded, with 0 mismatches. So this rule is kept because it is nearly "
    "free and because the one incident was never explained - not because a "
    "hardware fault is established."
)

# What a non-`ok` read MEANS, in the archive's own terms. A caller that lumps
# these together reports MPQ semantics as damage - which is exactly how a patch
# tombstone came to be recorded as a read failure in raw/tables/_variants.json.
STATUS_REASON = {
    "deleted": ("an MPQ DELETE_MARKER tombstone: this archive REMOVES the path "
                "at its layer and the entry carries no bytes by design. Archive "
                "semantics, not a failed read - see raw/recovered/deleted/"),
    "empty": ("the archive records this member as zero bytes: a real entry that "
              "holds nothing - see raw/recovered/empty/"),
    "missing": "no live hash slot in this archive resolves this name",
}


def read_reason(member) -> str:
    """The recorded reason for a member that did not come back `ok`."""
    known = STATUS_REASON.get(member.status)
    if known:
        return known
    return member.detail or f"read failed with status {member.status!r}"


def read_agreed(archive, stored: str, attempts: int = READ_ATTEMPTS):
    """One member's bytes, confirmed by two agreeing reads. Returns
    (data, sha256, reason, status) - data/sha are None when there is a reason,
    and `status` is the reader's own classification of the member (see
    tools.mpq.Member), so a caller records WHAT the archive says rather than
    re-deriving it from the block entry.

    `archive` is a tools.mpq.Archive. Only the previous read's HASH is kept
    between attempts, never its bytes, so verifying a 237 MB member costs one
    copy of it in memory, not two."""
    last = None
    for _ in range(attempts):
        member = archive.read(stored)
        if not member.ok:
            return None, None, read_reason(member), member.status
        sha = hashlib.sha256(member.data).hexdigest()
        if sha == last:
            return member.data, sha, None, member.status
        last = sha
        member = None
    return None, None, (f"{attempts} reads of this member disagreed byte for "
                        f"byte - see READ_AGREEMENT_RULE"), "unstable"


def _header_facts(data: bytes) -> dict:
    """Measured WDBC header + the byte-accurate cross-checks. Nothing here is
    asserted: a declared field count that disagrees with recordSize//4 is
    recorded as a disagreement, and the body/string-block reconciliation is
    reported rather than assumed."""
    if len(data) < HEADER.size:
        return {"bytes": len(data), "truncated": True}
    magic, records, declared, rec_size, str_size = HEADER.unpack_from(data, 0)
    body_end = HEADER.size + records * rec_size
    return {
        "magic": magic.decode("latin-1"),
        "records": records,
        "declaredFields": declared,
        "recordSize": rec_size,
        "stringBlockSize": str_size,
        # recordSize is what actually determines the row stride, so it is the
        # authority; declaredFields is kept as a diagnostic.
        "actualFields": rec_size // 4,
        "trailingBytesPerRecord": rec_size % 4,
        "declaredFieldsAgrees": declared == rec_size // 4,
        "sizeReconciles": body_end + str_size == len(data),
        "bytes": len(data),
    }


def resolve_chain(verbose: bool = True):
    """Walk every archive in chain order and resolve the winner of every path
    under the table directory. Returns (carriers, archives, unlistable).

    An archive's strength is its POSITION in discover_archives()' output, which
    is already sorted weakest-first by the loader order - so comparing positions
    is comparing chain ranks, without this module re-deriving (or having to
    agree with) how that order is computed."""
    archives = discover_archives()
    carriers, unlistable = {}, []
    t0 = time.time()
    for i, rec in enumerate(archives):
        p = rec["path"]
        aid = archive_id(p)
        files, reason = probe_unlistable.try_list(p)
        if files is None:
            unlistable.append({"archive": aid, "path": p, "reason": reason,
                               "chainRank": i})
            if verbose:
                print(f"  [{i+1:2d}/{len(archives)}] {aid:34s} UNLISTABLE ({reason})",
                      flush=True)
            continue
        found = 0
        for raw in files:
            stored = raw.decode("latin-1", "replace").replace("/", "\\")
            low = stored.lower()
            if not low.startswith(TABLE_DIR):
                continue
            found += 1
            cur = carriers.get(low)
            if cur is None:
                carriers[low] = {"stored": stored, "archive": aid, "path": p,
                                 "chainRank": i, "losers": []}
            elif i > cur["chainRank"]:
                cur["losers"].append(cur["archive"])
                cur.update({"stored": stored, "archive": aid, "path": p,
                            "chainRank": i})
            else:
                cur["losers"].append(aid)
        if verbose:
            print(f"  [{i+1:2d}/{len(archives)}] {aid:34s} tables={found:4d} "
                  f"union={len(carriers):4d}  [{time.time()-t0:5.1f}s]", flush=True)
    return carriers, archives, unlistable


def probe_unlistable_archives(carriers: dict, unlistable: list, verbose: bool = True):
    """Test every unlistable archive for every harvested table path. A hit whose
    archive outranks that path's current winner means the chain walk resolved the
    wrong file, so it is returned as a conflict and the caller stops."""
    probes, conflicts = {}, []
    names = sorted(carriers)
    for u in unlistable:
        try:
            hits = probe_unlistable.probe_paths(u["path"], names)
        except Exception as e:                       # noqa: BLE001 - recorded, not raised
            probes[u["archive"]] = {"error": f"{type(e).__name__}: {e}",
                                    "probedCount": len(names), "hits": []}
            continue
        hit = sorted(k for k, v in hits.items() if v)
        probes[u["archive"]] = {"probedCount": len(names), "hits": hit,
                                "reason": u["reason"]}
        for low in hit:
            if u["chainRank"] > carriers[low]["chainRank"]:
                conflicts.append({"path": low, "archive": u["archive"],
                                  "currentWinner": carriers[low]["archive"]})
        if verbose:
            print(f"  probe {u['archive']:34s} probed={len(names)} hits={len(hit)}",
                  flush=True)
    return probes, conflicts


def extract(verbose: bool = True) -> dict:
    t0 = time.time()
    if verbose:
        print(f"client: {config.CLIENT_DIR}", flush=True)
    carriers, archives, unlistable = resolve_chain(verbose)
    if not carriers:
        raise SystemExit(f"FATAL: no paths under {TABLE_DIR!r} in any archive.")

    probes, conflicts = probe_unlistable_archives(carriers, unlistable, verbose)
    if conflicts:
        raise SystemExit(
            "FATAL: an archive with no readable listfile outranks the resolved "
            f"winner for {len(conflicts)} path(s): {conflicts[:5]} - the layer "
            "would be built on the wrong bytes. Structural; investigate.")

    # sole writer of OUT_DIR: a table that vanished from the client must not linger.
    # The sentinel goes first, so the window in which this directory is unreliable
    # opens BEFORE the first unlink rather than after the last write.
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    layerstate.begin(OUT_DIR)
    keep = {low.rsplit("\\", 1)[-1].lower() for low in carriers}
    for old in sorted(OUT_DIR.iterdir()):
        if old.is_file() and old.name.lower().endswith(".dbc") \
                and old.name.lower() not in keep:
            old.unlink()

    by_archive = {}
    for low, c in carriers.items():
        by_archive.setdefault(c["archive"], []).append(low)
    path_by_archive = {c["archive"]: c["path"] for c in carriers.values()}

    tables, failures = {}, []
    seen_names = {}
    done = 0
    for aid in sorted(by_archive):
        a = mpq.Archive(path_by_archive[aid])
        for low in sorted(by_archive[aid]):
            c = carriers[low]
            name = c["stored"].rsplit("\\", 1)[-1]
            clash = seen_names.setdefault(name.lower(), low)
            if clash != low:
                raise SystemExit(
                    f"FATAL: two chain paths flatten to one output file name "
                    f"{name!r}: {clash!r} and {low!r}.")
            try:
                data, sha, reason, status = read_agreed(a, c["stored"])
            except Exception as e:                   # noqa: BLE001 - recorded, not raised
                data, sha, reason, status = None, None, f"{type(e).__name__}: {e}", "error"
            if data is None:
                failures.append({"table": name, "stage": "extract",
                                 "reason": reason, "status": status,
                                 "path": c["stored"], "winner": c["archive"]})
                continue
            (OUT_DIR / name).write_bytes(data)
            tables[name] = {
                "table": name, "path": c["stored"].replace("\\", "/"),
                "winner": c["archive"], "losers": sorted(set(c["losers"])),
                "sha256": sha,
                **_header_facts(data),
            }
            done += 1
        a.close()
        if verbose:
            print(f"  read {done:4d}/{len(carriers)} (through {aid})"
                  f"  [{time.time()-t0:5.1f}s]", flush=True)

    payload = {
        "note": "Every path under the client's table directory, resolved through "
                "the full chain (realm overlay above the base chain) and written "
                "to work/dbc_all/. No wanted list: this is the whole directory. "
                "Header fields are measured; declaredFieldsAgrees=false marks a "
                "header whose field count disagrees with recordSize//4.",
        "readerRule": READER_RULE,
        "readAgreementRule": READ_AGREEMENT_RULE,
        "readAttempts": READ_ATTEMPTS,
        "clientDir": str(config.CLIENT_DIR),
        "tableDir": TABLE_DIR.replace("\\", "/"),
        "archiveCount": len(archives),
        "unlistableArchives": sorted(u["archive"] for u in unlistable),
        "unlistableProbe": probes,
        "pathCount": len(carriers),
        "extractedCount": len(tables),
        "failures": sorted(failures, key=lambda f: f["table"]),
        "headerDisagreements": sorted(
            t["table"] for t in tables.values() if not t.get("declaredFieldsAgrees", True)),
        "nonWdbcMagic": sorted(f'{t["table"]}={t.get("magic")}' for t in tables.values()
                               if t.get("magic") != "WDBC"),
        "sizeDisagreements": sorted(t["table"] for t in tables.values()
                                    if not t.get("sizeReconciles", True)),
        "unalignedRecordSize": sorted(t["table"] for t in tables.values()
                                      if t.get("trailingBytesPerRecord")),
        "totalBytes": sum(t["bytes"] for t in tables.values()),
        "tables": [tables[k] for k in sorted(tables, key=str.lower)],
    }
    # bytes, not text: Path.write_text() would translate newlines per platform
    PROVENANCE.write_bytes(sharding.dump_manifest(payload).encode("utf-8"))
    layerstate.finish(OUT_DIR, {
        "layer": "work/dbc_all", "generatedBy": "python -m tools.extract_all",
        "pathCount": payload["pathCount"],
        "extractedCount": payload["extractedCount"],
        "failureCount": len(payload["failures"]),
    })
    return payload


def load_provenance() -> dict:
    if PROVENANCE.is_file():
        return json.loads(PROVENANCE.read_text(encoding="utf-8"))
    return {}


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("-q", "--quiet", action="store_true")
    args = ap.parse_args()
    p = extract(verbose=not args.quiet)
    print("\n=== EXTRACT ===")
    print(f"paths in chain      {p['pathCount']}")
    print(f"extracted           {p['extractedCount']}  "
          f"({p['totalBytes']/1e6:.1f} MB) -> {OUT_DIR}")
    print(f"failures            {len(p['failures'])}")
    print(f"header disagreements{len(p['headerDisagreements']):4d} "
          f"{p['headerDisagreements']}")
    print(f"unaligned records   {p['unalignedRecordSize']}")
    print(f"non-WDBC magic      {p['nonWdbcMagic']}")


if __name__ == "__main__":
    main()
