"""Gate for tools/mpq.py and tools/crack.py - the recovery layer.

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
    archive, and it is what `_verify.json` checks all 763,928 members against.
  * `mpyq`, the previous reader, on the members it CAN read. Where the two
    disagree, the archive's MD5 breaks the tie - and the test asserts on the
    direction of that tie-break, not merely that a difference exists.

The live-client checks are skipped when the client is not mounted, so the
format-level tests still run anywhere; the layer checks are skipped when
raw/recovered has no sentinel."""
import hashlib
import json
import struct
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from tools import config, crack, layerstate, mpq

FAILURES = []


def check(name, condition, detail=""):
    if condition:
        print(f"  PASS  {name}")
    else:
        print(f"  FAIL  {name}   {detail}")
        FAILURES.append(name)


# ==================== 1. the reader's own format tests ====================
print("format primitives (no client needed)")
check("self-test passes", mpq.selftest() == 0)

# The sector-classification rule, stated directly rather than via a whole
# archive: a sector is compressed iff it is stored SHORTER than what it must
# expand to. mpyq compares against bytes-left-in-file instead, which is the
# defect that made 35,853 files 'unreadable'.
check("a full-size stored sector is not fed to the decompressor",
      mpq.decompress(b"\x00" + b"A" * 10, 10) == b"A" * 10)

# ==================== 2. against the live client ====================
CLIENT = config.CLIENT_DIR
if not CLIENT.is_dir():
    print(f"\nclient not mounted at {CLIENT} - skipping live checks")
else:
    print(f"\nlive client at {CLIENT}")
    archives = crack._archives()
    check("77 archives discovered", len(archives) == 77, str(len(archives)))

    # -- the one encrypted member in the client, both ways ------------------
    patch_p = next(a for a in archives if a["id"].lower().endswith("patch-p.mpq"))
    with mpq.Archive(patch_p["path"]) as arc:
        member = arc.read("(listfile)")
        check("patch-P's encrypted (listfile) decrypts", member.ok, member.detail)
        check("patch-P's (listfile) names no files",
              member.data == b"(listfile)\r\n", repr(member.data))
        blind = arc.read_block(arc.block_index_of("(listfile)"), None)
        check("the same member decrypts with the FILENAME WITHHELD, by "
              "recovering the key from its sector table",
              blind.ok and blind.data == member.data, blind.detail)
        attrs = arc.attributes()
        check("patch-P's (attributes) is still sized for the block table it "
              "used to have (1,006 entries vs 2 live blocks) - the only "
              "surviving trace of what it deleted",
              attrs["entries"] == 1006 and len(arc.block_table) == 2,
              f"{attrs['entries']} vs {len(arc.block_table)}")

    # -- a member with NO sector offset table ------------------------------
    # This is the silent-corruption class. Assert against the archive's MD5,
    # and assert that the OLD reader gets it wrong - a test that only checked
    # the new reader would still pass if someone reintroduced the bug in mpyq's
    # direction, because it would not know which answer is right.
    common = next(a for a in archives if a["id"] == "Data/common.MPQ")
    name = "Sound\\Music\\ZoneMusic\\Naxxramas\\NaxxramasSpiderBoss1.mp3"
    with mpq.Archive(common["path"]) as arc:
        got = arc.read(name)
        recorded = arc.attributes()["md5"][got.block]
        check("an uncompressed member (no sector offset table) decodes to its "
              "declared length", got.ok and len(got.data) == got.size,
              f"{got.status} {got.detail}")
        check("...and matches the MD5 its own archive recorded",
              hashlib.md5(got.data).digest() == recorded)
        try:
            from mpyq import MPQArchive
            old = MPQArchive(str(common["path"]), listfile=False)
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
    backup = next((a for a in archives
                   if a["id"] == "Data/enUS/backup-enUS.MPQ"), None)
    if backup:
        with mpq.Archive(backup["path"]) as arc:
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
if not layerstate.is_complete(crack.OUT_DIR):
    print("  raw/recovered has no sentinel - skipping layer checks")
else:
    state = layerstate.read(crack.OUT_DIR)
    check("no bytes in any archive are unaccounted for by a live block entry - "
          "the direct test that delete-marked hash slots hide nothing",
          state["unaccountedBytes"] == 0, str(state["unaccountedBytes"]))
    check("no block entry is unreferenced by any live hash slot",
          state["orphanBlockEntries"] == 0, str(state["orphanBlockEntries"]))
    check("every encrypted member in the client was decrypted",
          state["encryptedMembers"] == state["encryptedMembersRecovered"])
    check("nothing in the client is still unreadable",
          state["stillUnreadable"] == 0 and state["unreadableTotal"] == 0,
          f"{state['stillUnreadable']}/{state['unreadableTotal']}")
    check("every member matches the MD5 its archive recorded",
          state["md5MismatchedTotal"] == 0, str(state["md5MismatchedTotal"]))
    check("the MD5 verification covered the whole client, not a sample",
          state["md5VerifiedTotal"] > 700_000, str(state["md5VerifiedTotal"]))

    verify = json.loads((crack.OUT_DIR / "_verify.json").read_bytes().decode("utf-8"))
    census = verify["compressionCensus"]
    for method in ("pkware", "huffman", "sparse", "adpcm_mono", "adpcm_stereo"):
        check(f"the client uses no {method} sector (so an implementation of it "
              f"could not be exercised by any byte here)",
              census.get(method, 0) == 0, str(census.get(method)))
    check("the client's compression is zlib, bzip2 and stored - measured over "
          "every sector of every member",
          census.get("zlib", 0) > 1_000_000 and census.get("bzip2", 0) > 0)

    # the recovered set contains no DATA file: the standing claim, now checked
    files_index = json.loads(
        (crack.FILES_DIR / "index.json").read_bytes().decode("utf-8"))
    by_class = files_index["byClass"]
    check("36,139 previously-unreadable files were recovered",
          files_index["recordTotal"] == 36139, str(files_index["recordTotal"]))
    check("NOT ONE of them is a DBC or a Content file - the 'no data file is "
          "affected' claim, checked rather than assumed",
          by_class.get("dbc", 0) == 0 and by_class.get("content", 0) == 0,
          json.dumps(by_class))

    for layer in (crack.ATTR_DIR, crack.DELETED_DIR, crack.FILES_DIR,
                  crack.CORRECTIONS_DIR, crack.CONTAINER_DIR):
        check(f"{layer.name}/ carries its completion sentinel",
              layerstate.is_complete(layer))

print(f"\n{'ALL PASS' if not FAILURES else f'{len(FAILURES)} FAILURES: ' + ', '.join(FAILURES)}")
sys.exit(1 if FAILURES else 0)
