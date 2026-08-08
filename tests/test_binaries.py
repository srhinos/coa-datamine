"""Gate for tools/pe.py, tools/lua51.py and tools/extract_binaries.py - the
client-binaries layer.

HOW THIS TEST TRIES NOT TO FALSE-GREEN
--------------------------------------
The thing under test is a set of FORMAT READERS, and the failure that matters is
a reader that returns confident, wrong output without raising. Asserting "it
produced 189,848 strings" cannot see that, because this repo also produced the
number. So every substantive check below is anchored to something that is not
this code:

  * THE CLIENT'S OWN BYTES. Every sampled string record is re-read from the
    binary at the offset it claims, and must be there. Every recovered Lua chunk
    file is compared against the bytes at its offset in the client. A wrong
    offset, a wrong length or a mangled decode fails here rather than looking
    plausible in a shard.
  * THE FORMAT ITSELF. `pe.selftest()` and `lua51.selftest()` build structures by
    hand and read them back, including the cases that must be REJECTED - a bare
    `\\x1bLua` header, a truncated chunk, a Lua 5.3 header.
  * NON-VACUOUSNESS. Ascension.exe contains the four magic bytes and no chunk;
    the test asserts the walker rejects it. If undump ever starts accepting the
    magic on faith, this fails.
  * REPRODUCTION. One binary is re-extracted into a temp tree and compared file
    by file, by sha256, against what is committed.

The live-client checks skip when the client is not mounted; the layer checks
skip when raw/binaries has no sentinel.
"""
# ---------------------------------------------------------------------------
# STALE - DOES NOT RUN. This file drives stage modules that no longer exist.
#
# The raw pipeline collapsed into `datamine.py` (one snapshot, one traversal);
# tools/extract_binaries.py were retired with it. The
# GATES BELOW ARE STILL THE RIGHT GATES - they are what `datamine.py` has to
# keep true - so this file is kept rather than deleted, and migrating it is
# tracked work: point the output assertions at the published `raw/` layer, and
# the reader/decoder assertions at `tools/dbcdecode.py` and `tools/emit.py`.
#
# It is left failing on import ON PURPOSE. Deleting it would quietly drop the
# specification of behaviour this repo has already paid to learn; rewriting it
# to pass without re-checking what it checks would be worse.
# ---------------------------------------------------------------------------

import hashlib
import json
import shutil
import sys
import tempfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from tools import config, extract_binaries as eb, layerstate, lua51, pe

FAILURES = []


def check(name, condition, detail=""):
    if condition:
        print(f"  PASS  {name}")
    else:
        print(f"  FAIL  {name}   {detail}")
        FAILURES.append(name)


def sha(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


# ==================== 1. the readers' own format tests ====================
print("format primitives (no client needed)")
check("pe.py self-test passes", pe.selftest() == 0)
check("lua51.py self-test passes", lua51.selftest() == 0)

# The scoring rule counts DISTINCT classes, so repetition cannot carry prose.
check("a repeated keyword does not raise a run's Lua score",
      lua51.score("end end end end end end") == 1,
      str(lua51.score("end end end end end end")))
check("the score is a count of the classes it lists",
      lua51.score("local x = nil\nreturn x") == len(
          lua51.classes("local x = nil\nreturn x")))

# ==================== 2. against the live client ====================
CLIENT = config.CLIENT_DIR
if not CLIENT.is_dir():
    print(f"\nclient not mounted at {CLIENT} - skipping live checks")
else:
    print(f"\nlive client at {CLIENT}")
    binaries = eb.client_binaries()
    check("the client root holds PE images", len(binaries) >= 2, str(len(binaries)))
    check("selection is by bytes, not by extension: every pick starts MZ and "
          "carries a PE signature",
          all(pe.is_pe(p.read_bytes()[:0x400]) for p in binaries))

    for p in binaries:
        parsed = pe.parse(p.read_bytes())
        check(f"{p.name} parses with no unreadable structure",
              parsed["isPE"] and not parsed["notes"], str(parsed["notes"]))

    # The magic-versus-chunk distinction, on the real file that has the trap.
    asc = next((p for p in binaries if p.name.lower() == "ascension.exe"), None)
    if asc is not None:
        cands = lua51.find_chunks(asc.read_bytes())
        check("Ascension.exe carries the Lua signature", len(cands) >= 1)
        check("and every one of them is REJECTED by the structure walk, so the "
              "layer never reports a compiler constant as recovered script",
              all(not c["ok"] for c in cands),
              str([c.get("reason") for c in cands]))

# ==================== 3. the committed layer ====================
OUT = eb.OUT_DIR
if not layerstate.is_complete(OUT):
    print(f"\n{OUT} has no sentinel - skipping layer checks")
elif not CLIENT.is_dir():
    print("\nclient not mounted - skipping layer-versus-client checks")
else:
    print(f"\ncommitted layer at {OUT}")
    index = json.loads((OUT / "index.json").read_text(encoding="utf-8"))
    check("the index names every client-root PE",
          {b["name"] for b in index["binaries"]} ==
          {p.name for p in eb.client_binaries()})
    check("the sweep for binaries elsewhere in the client is recorded",
          "outsideRoot" in index)
    check("every threshold the layer applied is written down next to the counts",
          all(k in index for k in ("minRunLength", "luaMinScore",
                                   "luaFragmentMinScore", "stringRule",
                                   "selectionRule", "resourceRule")))

    for entry in index["binaries"]:
        name = entry["name"]
        src = CLIENT / name
        if not src.is_file():
            continue
        data = src.read_bytes()
        check(f"{name}: the committed sha256 is the client's file",
              sha(data) == entry["sha256"])

        # -- strings are re-read from the client at their own offsets --------
        six = json.loads((OUT / name / "strings" / "index.json")
                         .read_text(encoding="utf-8"))
        rows = []
        for shard in six["shards"]:
            fp = OUT / name / "strings" / shard["file"]
            if fp.suffix == ".gz":
                import gzip
                text = gzip.decompress(fp.read_bytes()).decode("utf-8")
            else:
                text = fp.read_text(encoding="utf-8")
            check(f"{name}: shard {shard['file']} matches its recorded sha256",
                  sha(fp.read_bytes()) == shard["sha256"])
            rows.extend(json.loads(l) for l in text.splitlines() if l.strip())
        check(f"{name}: shard rows total the index's count",
              len(rows) == six["rows"], f"{len(rows)} vs {six['rows']}")

        # every 97th record - a fixed stride, so the sample is deterministic and
        # spread over the whole file rather than clustered at the start
        sample = rows[::97] or rows
        bad = []
        for r in sample:
            enc = {"ascii": "ascii", "utf16le": "utf-16-le", "utf8": "utf-8"}[r["enc"]]
            want = r["text"].encode(enc)
            for off in r["off"]:
                if data[off:off + len(want)] != want:
                    bad.append((r["id"], off))
                    break
        check(f"{name}: all {len(sample)} sampled strings are at every offset "
              f"they claim, in the client's own bytes", not bad, str(bad[:3]))

        # a run must be maximal: the byte before and after cannot extend it
        edge = []
        for r in sample:
            if r["enc"] != "ascii":
                continue
            off = r["off"][0]
            before = data[off - 1:off]
            after = data[off + len(r["text"]):off + len(r["text"]) + 1]
            if (before and 0x20 <= before[0] <= 0x7E) or \
                    (after and 0x20 <= after[0] <= 0x7E):
                edge.append(r["id"])
        check(f"{name}: sampled ASCII runs are maximal - no printable byte was "
              f"left on either end", not edge, str(edge[:3]))

        check(f"{name}: no run is shorter than the stated minimum",
              all(r["len"] >= eb.MIN_RUN for r in rows))

        # -- recovered Lua is the client's bytes, verbatim -------------------
        lix = json.loads((OUT / name / "lua" / "index.json")
                         .read_text(encoding="utf-8"))
        lrows = []
        for shard in lix["shards"]:
            fp = OUT / name / "lua" / shard["file"]
            if fp.suffix == ".gz":
                import gzip
                text = gzip.decompress(fp.read_bytes()).decode("utf-8")
            else:
                text = fp.read_text(encoding="utf-8")
            lrows.extend(json.loads(l) for l in text.splitlines() if l.strip())
        for r in lrows:
            if r["kind"] not in ("sourceChunk", "precompiled"):
                continue
            fp = OUT / name / "lua" / r["file"]
            got = fp.read_bytes()
            check(f"{name}: {r['file']} is the client's bytes at {r['off']:#x}",
                  got == data[r["off"]:r["off"] + r["bytes"]]
                  and sha(got) == r["sha256"])
        check(f"{name}: every chunk file the index lists exists",
              all((OUT / name / "lua" / f["file"]).is_file()
                  for f in lix["chunkFiles"]))

        # -- the overlay, which no section table entry accounts for ----------
        ov = entry.get("overlay") or {}
        if ov.get("bytesCommitted"):
            got = (OUT / name / ov["file"]).read_bytes()
            check(f"{name}: the overlay is the client's trailing bytes",
                  got == data[ov["offset"]:ov["offset"] + ov["bytes"]]
                  and sha(got) == ov["sha256"])

        # -- resources are the client's bytes too ----------------------------
        rix = json.loads((OUT / name / "resources" / "index.json")
                         .read_text(encoding="utf-8"))
        for r in rix["resources"]:
            if not r.get("bytesCommitted") or not r.get("file"):
                continue
            got = (OUT / name / "resources" / r["file"]).read_bytes()
            check(f"{name}: resource {r['file']} matches the client",
                  got == data[r["offset"]:r["offset"] + r["bytes"]]
                  and sha(got) == r["sha256"])

    # -- reproduction: re-extract the smallest binary and compare -------------
    smallest = min(eb.client_binaries(), key=lambda p: p.stat().st_size)
    tmp = Path(tempfile.mkdtemp(prefix="coa-bin-"))
    try:
        eb.extract_one(smallest, tmp, verbose=False)
        committed = OUT / smallest.name
        diffs = []
        for produced in sorted(tmp.rglob("*")):
            if not produced.is_file():
                continue
            rel = produced.relative_to(tmp / smallest.name)
            other = committed / rel
            if not other.is_file() or sha(other.read_bytes()) != \
                    sha(produced.read_bytes()):
                diffs.append(str(rel))
        extra = [str(p.relative_to(committed)) for p in sorted(committed.rglob("*"))
                 if p.is_file() and not (tmp / smallest.name /
                                         p.relative_to(committed)).is_file()]
        check(f"re-extracting {smallest.name} reproduces the committed tree byte "
              f"for byte", not diffs and not extra, str((diffs + extra)[:4]))
    finally:
        shutil.rmtree(tmp, ignore_errors=True)

    # -- the search layer can reach it ---------------------------------------
    from tools import find
    res = find.find_string("listarchive", layers=["binaries"], limit=0)
    check("tools.find reaches the binaries layer",
          res["hitCount"] >= 1 and
          all(h["layer"] == "binaries" for h in res["hits"]),
          json.dumps(res["columns"]))

# ==========================================================================
print()
if FAILURES:
    print(f"{len(FAILURES)} FAILED: {FAILURES}")
    raise SystemExit(1)
print("all binaries-layer checks passed")
