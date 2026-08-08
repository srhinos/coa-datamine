"""Gate for tools/mpq.py and the raw/recovered layer datamine.py emits.

WHY THIS TEST IS SHAPED LIKE THIS
---------------------------------
The thing being tested is a FILE FORMAT READER, and the failure mode that
actually happened here is a reader that returns confident, wrong bytes without
raising. A test that asserts "it read something" or that compares against a mock
archive this repo also built cannot see that - it is the same class of
false-green that has burned other work in this workspace.

So the assertions below are anchored to two oracles that are NOT this code:

  * every MPQ carries an `(attributes)` member holding the MD5 Blizzard's own
    packer recorded for each block entry. That is an independent statement about
    what the bytes are supposed to be, written by the tool that built the
    archive, and it is what `_verify.json` checks every read member against.
  * `mpyq`, the previous reader, on the members it CAN read. Where the two
    disagree, the archive's MD5 breaks the tie - and the test asserts on the
    direction of that tie-break, not merely that a difference exists.

The live-client checks are skipped when the client is not mounted, so the
format-level tests still run anywhere; the layer checks are skipped when
raw/recovered has no sentinel.

MIGRATED, 2026-08. This drove `tools/crack.py` and `tools/inventory.py`, both
retired by the single-script collapse, and it sat failing on import for a
commit. The format-level gates are untouched. The layer gates now read the
layer datamine.py publishes.

WHAT MOVED, AND WHAT WAS DELETED RATHER THAN QUIETLY DROPPED:

  * `_forensics.json` was deleted by the collapse and is restored by this
    change, so the byte-accounting gates below are back, checked against the
    published file rather than against a stage's return value.
  * `_verify.json` lost its compression census and its two reader-defect class
    counts in the collapse; both are restored, and the census now covers EVERY
    member the traversal read rather than the old stage's subset - so the
    zlib count is larger than the number this file used to pin.
  * `corrections/` and `files/` are GONE, and their gates with them. Both were
    already `recordTotal: 0` by construction: the census reads every member
    itself through tools/mpq.py and carries true hashes, so there was nothing
    left to recover and nothing to correct. Their real content - "no member of
    this client is unreadable" - is asserted here directly off the traversal's
    own read-error census instead, which is the same claim made about the same
    77 archives without a layer that exists only to hold a zero.
"""
import hashlib
import json
import struct
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from tools import config, emit, layerstate, mpq

OUT_DIR = config.RAW_DIR / "recovered"
FAILURES = []


def check(name, condition, detail=""):
    if condition:
        print(f"  PASS  {name}")
    else:
        print(f"  FAIL  {name}   {detail}")
        FAILURES.append(name)


def load(p: Path):
    return json.loads(p.read_bytes().decode("utf-8"))


# ==================== 1. the reader's own format tests ====================
print("format primitives (no client needed)")
check("self-test passes", mpq.selftest() == 0)

# The sector-classification rule, stated directly rather than via a whole
# archive: a sector is compressed iff it is stored SHORTER than what it must
# expand to. mpyq compares against bytes-left-in-file instead, which is the
# defect that made 35,853 files 'unreadable'.
check("a full-size stored sector is not fed to the decompressor",
      mpq.decompress(b"\x00" + b"A" * 10, 10) == b"A" * 10)

# The open ledger is what the pipeline's single-traversal guarantee is enforced
# against, and a counter that cannot count is worse than no counter - the check
# it replaced incremented once per loop iteration over a list of unique keys and
# could never fire. So: opening the same file twice must show 2. Without this,
# `datamine.check_single_open` would be green on a broken ledger.
#
# The probe must be an archive UNDER THE SNAPSHOT: `check_single_open`
# classifies a ledger key by which tree it sits in, and only snapshot keys carry
# the exactly-once rule (a nested container archive under work/ is a legitimate
# second archive). Probing with anything else would test a branch the pipeline
# never takes.
_snap_data = config.WORK_DIR / "snapshot" / "Data"
_probe = next(iter(sorted(_snap_data.glob("*.MPQ"))), None) \
    if _snap_data.is_dir() else None
if _probe is None:
    print(f"  SKIP  no snapshot archive under {_snap_data} - ledger and guard "
          f"checks skipped (run `python datamine.py`)")
else:
    _key = str(Path(_probe).resolve()).lower()
    _before = mpq.OPEN_LEDGER.get(_key, 0)
    mpq.Archive(_probe).close()
    _one = mpq.OPEN_LEDGER.get(_key, 0) - _before
    mpq.Archive(_probe).close()
    _two = mpq.OPEN_LEDGER.get(_key, 0) - _before
    check("mpq.OPEN_LEDGER counts REAL opens: one open is 1, two opens are 2 "
          "(the guarantee datamine.check_single_open enforces is not vacuous)",
          (_one, _two) == (1, 2), f"{_one}, {_two}")

    # ...and the guard built on it must actually reject the state it exists to
    # reject. A guard that has never been seen to fire is a guard nobody should
    # believe: the one this replaced counted loop iterations over a list of
    # unique keys and could not fail under any input at all.
    import datamine as D

    _scan = [{"id": "probe", "snapshot": _probe, "openError": None}]
    try:
        D.check_single_open(_scan)
        check("datamine.check_single_open REJECTS an archive opened twice",
              False, "it accepted a doubly-opened archive")
    except SystemExit as exc:
        check("datamine.check_single_open REJECTS an archive opened twice",
              "opened 2x" in str(exc), str(exc)[:120])
    mpq.OPEN_LEDGER.pop(_key, None)
    try:
        D.check_single_open(_scan)
        check("datamine.check_single_open REJECTS an archive that was never "
              "opened through mpq.Archive at all", False, "it accepted it")
    except SystemExit as exc:
        check("datamine.check_single_open REJECTS an archive that was never "
              "opened through mpq.Archive at all",
              "without going through mpq.Archive" in str(exc), str(exc)[:120])

    # the client-read guard, same treatment
    _reads = D.ClientReads(config.CLIENT_DIR).install()
    try:
        with open(_probe, "rb"):
            pass
        _pre = _reads.by_phase.get("after the snapshot", 0)
        _reads.seal()
        if config.CLIENT_DIR.is_dir():
            _live = next(iter(sorted((config.CLIENT_DIR / "Data").glob("*.MPQ"))))
            with open(_live, "rb"):
                pass
    finally:
        _reads.remove()
    check("datamine.ClientReads does not count snapshot reads as client reads",
          _pre == 0, str(_pre))
    if config.CLIENT_DIR.is_dir():
        try:
            _reads.check()
            check("datamine.ClientReads FAILS the run when the live client is "
                  "read after the snapshot is sealed", False, "it accepted it")
        except SystemExit as exc:
            check("datamine.ClientReads FAILS the run when the live client is "
                  "read after the snapshot is sealed",
                  "LIVE CLIENT" in str(exc), str(exc)[:120])

# ==================== 2. against the live client ====================
CLIENT = config.CLIENT_DIR
if not CLIENT.is_dir():
    print(f"\nclient not mounted at {CLIENT} - skipping live checks")
else:
    print(f"\nlive client at {CLIENT}")
    inv = load(config.RAW_DIR / "_inventory" / "archives.json")
    archives = {a["id"]: CLIENT / a["id"] for a in inv["archives"]}
    check("77 archives discovered", len(archives) == 77, str(len(archives)))

    # -- the one encrypted member in the client, both ways ------------------
    patch_p = next(p for aid, p in archives.items()
                   if aid.lower().endswith("patch-p.mpq"))
    with mpq.Archive(patch_p) as arc:
        member = arc.read("(listfile)")
        check("patch-P's encrypted (listfile) decrypts", member.ok, member.detail)
        blind = arc.read_block(arc.block_index_of("(listfile)"), None)
        check("the same member decrypts with the FILENAME WITHHELD, by "
              "recovering the key from its sector table",
              blind.ok and blind.data == member.data, blind.detail)
        attrs = arc.attributes()
        check("patch-P's (attributes) is still sized for the block table it "
              "used to have (1,006 entries vs a handful of live blocks) - the "
              "only surviving trace of what it deleted",
              attrs["entries"] == 1006 and len(arc.block_table) < 10,
              f"{attrs['entries']} vs {len(arc.block_table)}")

    # -- a member with NO sector offset table ------------------------------
    # This is the silent-corruption class. Assert against the archive's MD5,
    # and assert that the OLD reader gets it wrong - a test that only checked
    # the new reader would still pass if someone reintroduced the bug in mpyq's
    # direction, because it would not know which answer is right.
    common = archives["Data/common.MPQ"]
    name = "Sound\\Music\\ZoneMusic\\Naxxramas\\NaxxramasSpiderBoss1.mp3"
    with mpq.Archive(common) as arc:
        got = arc.read(name)
        recorded = arc.attributes()["md5"][got.block]
        check("an uncompressed member (no sector offset table) decodes to its "
              "declared length", got.ok and len(got.data) == got.size,
              f"{got.status} {got.detail}")
        check("...and matches the MD5 its own archive recorded",
              hashlib.md5(got.data).digest() == recorded)
        try:
            from mpyq import MPQArchive
            old = MPQArchive(str(common), listfile=False)
            old_bytes = old.read_file(name)
            old.file.close()
            check("...while the previous reader returns different bytes whose "
                  "MD5 does NOT match, so the disagreement is decided by the "
                  "archive and not by preference",
                  old_bytes != got.data
                  and hashlib.md5(old_bytes).digest() != recorded,
                  f"old={len(old_bytes) if old_bytes else None} new={len(got.data)}")
        except ImportError:
            print("  SKIP  mpyq not installed - cross-reader check skipped")

    # -- ambiguous sector layouts resolve by decoding, not by order ---------
    backup = archives.get("Data/enUS/backup-enUS.MPQ")
    if backup:
        with mpq.Archive(backup) as arc:
            name = "Data\\enUS\\Documentation\\Images\\buttons\\troubleshooting.jpg"
            if arc.has(name):
                got = arc.read(name)
                recorded = arc.attributes()["md5"][got.block]
                layouts = arc._sector_layouts(16, got.size, got.flags)
                check("this member's table length genuinely fits more than one "
                      "sector layout, so choosing by search order alone is "
                      "unsound", len(layouts) > 1, str(layouts))
                check("...and the reader still lands on the layout that "
                      "reproduces the archive's own MD5",
                      got.ok and hashlib.md5(got.data).digest() == recorded,
                      f"{got.status} {got.detail}")
                check("...producing a real JPEG", got.ok
                      and got.data.startswith(b"\xff\xd8\xff"))

# ==================== 3. the committed layer ====================
print("\nthe raw/recovered layer")
if not layerstate.is_complete(OUT_DIR):
    print("  raw/recovered has no sentinel - skipping layer checks")
else:
    state = layerstate.read(OUT_DIR)
    top = load(OUT_DIR / "index.json")
    forensics = load(OUT_DIR / "_forensics.json")
    verify = load(OUT_DIR / "_verify.json")

    # ---- byte accounting: the whole point of the forensics file ----------
    check("no bytes in any archive are unaccounted for by a live block entry - "
          "the direct test that delete-marked hash slots hide nothing",
          forensics["unaccountedBytesTotal"] == 0,
          str(forensics["unaccountedBytesTotal"]))
    check("no block entry is unreferenced by any live hash slot",
          forensics["orphanBlockEntriesTotal"] == 0,
          str(forensics["orphanBlockEntriesTotal"]))
    check("every encrypted member in the client was decrypted",
          forensics["encryptedMemberCount"]
          == forensics["encryptedMembersRecovered"],
          f"{forensics['encryptedMemberCount']} vs "
          f"{forensics['encryptedMembersRecovered']}")
    check("the forensics covered every archive, not a sample",
          forensics["archiveCount"] == len(forensics["archives"]) == 77,
          str(forensics["archiveCount"]))
    check("the layer summary and the forensics file agree on the same numbers",
          top["unaccountedBytes"] == forensics["unaccountedBytesTotal"]
          and top["orphanBlockEntries"] == forensics["orphanBlockEntriesTotal"]
          and state["unaccountedBytes"] == forensics["unaccountedBytesTotal"])

    # Per-archive, not just in total: a run of gaps in one archive cancelled by
    # nothing anywhere else would still sum to zero if the total were all that
    # was checked, and "sum is 0" over non-negative terms only looks strict.
    bad = [a["id"] for a in forensics["archives"]
           if a["unaccountedBytes"] or a["orphanBlockEntryCount"]]
    check("...and per archive, not merely in aggregate", not bad, str(bad[:5]))
    check("every archive's data region is fully claimed by its block table",
          all(a["accountedBytes"] == a["dataRegionBytes"]
              for a in forensics["archives"]),
          str([a["id"] for a in forensics["archives"]
               if a["accountedBytes"] != a["dataRegionBytes"]][:5]))

    check("every member matches the MD5 its archive recorded",
          verify["mismatched"] == 0, str(verify["mismatched"]))
    check("the MD5 verification covered the whole client, not a sample",
          verify["ok"] > 600_000, str(verify["ok"]))
    check("nothing in the client is unreadable: every read error the traversal "
          "recorded is MPQ SEMANTICS (a tombstone or an empty member), not a "
          "failure to decode",
          all(k.split(":", 1)[0] in ("deleted", "empty")
              for k in top["readErrors"]),
          json.dumps(top["readErrors"])[:200])

    # ---- the compression census ------------------------------------------
    census = verify["compressionCensus"]
    for method in ("pkware", "huffman", "sparse", "adpcm_mono", "adpcm_stereo"):
        check(f"the client uses no {method} sector (so an implementation of it "
              f"could not be exercised by any byte here)",
              census.get(method, 0) == 0, str(census.get(method)))
    check("the client's compression is zlib, bzip2 and stored - measured over "
          "every sector of every member the traversal read",
          census.get("zlib", 0) > 1_000_000 and census.get("bzip2", 0) > 0,
          json.dumps({k: v for k, v in census.items() if v})[:200])

    # ---- the two classes the previous reader got silently wrong ----------
    # These are measurements of the ARCHIVES, and they are what tools/mpq.py's
    # header claims in its own docstring. If the header says 1,271 and the
    # client holds a different number, one of the two is stale.
    check("every member with NO sector offset table that the traversal could "
          "name was read successfully",
          verify["noSectorTableReadFailed"] == 0
          and verify["noSectorTableReadOk"] > 1000,
          f"ok={verify['noSectorTableReadOk']} "
          f"failed={verify['noSectorTableReadFailed']}")
    check("...and the class is fully partitioned: ok + failed + unnamed equals "
          "the members counted off the block tables",
          verify["noSectorTableReadOk"] + verify["noSectorTableReadFailed"]
          + verify["noSectorTableNotNamedByListfile"]
          == verify["noSectorTableMembers"])
    check("every member whose size is an exact multiple of the sector size was "
          "read successfully",
          verify["exactSectorMultipleReadFailed"] == 0
          and verify["exactSectorMultipleReadOk"] > 100,
          f"ok={verify['exactSectorMultipleReadOk']} "
          f"failed={verify['exactSectorMultipleReadFailed']}")
    check("...and that class is fully partitioned too",
          verify["exactSectorMultipleReadOk"]
          + verify["exactSectorMultipleReadFailed"]
          + verify["exactSectorMultipleNotNamedByListfile"]
          == verify["exactSectorMultipleMembers"])

    # ------------------------------------------------------------------
    # the tombstone layer counts the CLIENT, not the census
    # ------------------------------------------------------------------
    # raw/recovered/deleted/ used to be built from the file census's read-failure
    # list, which holds one row per PATH - the winning copy. A tombstone set by an
    # archive that a higher archive then re-supplies the path from was invisible
    # to it, so the layer held 4,906 of the client's 4,911 while its own rule text
    # claimed "every MPQ DELETE_MARKER tombstone". _forensics.json counted the
    # block tables directly and said 4,911 in the same commit: the layer
    # contradicted its own sibling and nothing compared them. This does.
    deleted_ix = load(OUT_DIR / "deleted" / "index.json")
    empty_ix = load(OUT_DIR / "empty" / "index.json")
    check("the tombstone layer holds EVERY DELETE_MARKER block entry in the "
          "client, not just the ones the census could see",
          deleted_ix["count"] == forensics["blockEntriesDeleteMarkerTotal"]
          == len(deleted_ix["entries"]),
          f"{deleted_ix['count']} in the layer vs "
          f"{forensics['blockEntriesDeleteMarkerTotal']} in the block tables")
    check("the empty-member layer is enumerated, not just counted",
          empty_ix["count"] == len(empty_ix["entries"]) > 0,
          str(empty_ix["count"]))

    # ---- the (attributes) oracle is per member, not per archive ----------
    attr_ix = load(OUT_DIR / "attributes" / "index.json")
    block_total = sum(a["blockEntries"] for a in forensics["archives"])
    check("the attribute layer holds one row per BLOCK ENTRY across the whole "
          "client - the oracle is per member, not a per-archive summary",
          attr_ix["recordTotal"] == block_total,
          f"{attr_ix['recordTotal']} rows vs {block_total} block entries")

    # ---- containers are expanded, not merely detected --------------------
    cont_ix = load(OUT_DIR / "containers" / "index.json")
    # "Expanded" is not one shape, because a container is not one thing. An
    # archive (rar5, nested mpq) expands into MEMBERS; a bplist has no members
    # at all and expands into a decoded `plist` structure carried inline. An
    # earlier version of this check looked only for members and called the three
    # .nib plists unexpanded - the layer was right and the test was wrong. What
    # actually distinguishes a failure is `expanded: false` with a `reason`.
    unexpanded = [f"{c['path']}: {c.get('reason')}" for c in cont_ix["containers"]
                  if c.get("expanded") is False or c.get("reason")]
    check("no nested container was left unexpanded with a reason",
          not unexpanded, ", ".join(unexpanded[:3]))
    empty = [c["path"] for c in cont_ix["containers"]
             if not c.get("members") and c.get("plist") is None]
    check("every nested container was opened one level down, not just named - "
          "into members (rar/mpq) or a decoded structure (bplist)",
          not empty, ", ".join(empty[:3]))
    check("both container kinds are actually present, so neither branch above "
          "is vacuous",
          {c["kind"] for c in cont_ix["containers"]} >= {"bplist", "mpq"},
          str(sorted({c["kind"] for c in cont_ix["containers"]})))
    check("the container member total equals what the per-container records "
          "hold",
          cont_ix["memberTotal"] == sum(len(c.get("members") or ())
                                        for c in cont_ix["containers"]),
          str(cont_ix["memberTotal"]))

    check("recovered/ carries its completion sentinel",
          layerstate.is_complete(OUT_DIR))

    # ------------------------------------------------------------------
    # the committed bytes are the bytes this code writes
    # ------------------------------------------------------------------
    # The gap this closes, stated plainly: the layer's CONTENT was deterministic
    # and its committed BYTES were not. 215 of raw/recovered's 270 files were
    # committed with CRLF while every writer here emits LF, so re-running the
    # layer reported 208 files modified and `git diff --ignore-cr-at-eol` was
    # empty for all of them. Nothing in this file asserted anything about the
    # bytes, so nothing caught it.
    #
    # Re-reading 44.9 GB to prove a rerun is byte-identical is not a test. What
    # IS testable cheaply is the step that actually broke: feed each committed
    # shard's own records back through the writer that produced it and require
    # the bytes to come out identical. A CRLF shard fails on the first
    # comparison, and so would any drift in the serializer.
    from tools import rawshard

    shards = sorted((OUT_DIR / "attributes").rglob("*.jsonl"))
    check("there are record shards to re-serialize", bool(shards))
    mismatched = []
    for p in shards[:200]:
        raw_bytes = p.read_bytes()
        records = [json.loads(l) for l in raw_bytes.decode("utf-8").splitlines()]
        rebuilt = "".join(rawshard.line(r) + "\n" for r in records)
        if rebuilt.encode("utf-8") != raw_bytes:
            mismatched.append(p.name)
    check(f"every one of the {min(len(shards), 200)} record shards sampled "
          f"re-serializes to its own bytes, so a rerun writes what is committed",
          not mismatched, ", ".join(mismatched[:5]))

    stray = [p for p in OUT_DIR.rglob("*")
             if p.is_file() and p.suffix in (".json", ".jsonl", ".md")
             and b"\r\n" in p.read_bytes()]
    check("no CRLF in any generated file under raw/recovered",
          not stray, ", ".join(p.name for p in stray[:5]))

print(f"\n{'ALL PASS' if not FAILURES else f'{len(FAILURES)} FAILURES: ' + ', '.join(FAILURES)}")
sys.exit(1 if FAILURES else 0)
