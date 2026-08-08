"""Gate for tools/pe.py, tools/lua51.py and tools/peextract.py - the
client-binaries layer.

HOW THIS TEST TRIES NOT TO FALSE-GREEN
--------------------------------------
The thing under test is a set of FORMAT READERS, and the failure that matters is
a reader that returns confident, wrong output without raising. Asserting "it
produced 566,861 strings" cannot see that, because this repo also produced the
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

MIGRATED, 2026-08. This drove `tools/extract_binaries.py`, retired by the
single-script collapse, and it sat failing on import for a commit. The gates are
the same; the extractor is now `tools/peextract.py` driven from
`datamine.emit_binaries`, so:

  * `eb.client_binaries()` is gone - the client-root PE set is decided during
    the snapshot by reading bytes, and the layer's own `binaries` list is what
    this file checks against the client root;
  * `eb.extract_one(path, ...)` is `eb.extract_bytes(data, name, dest)`;
  * the layer covers ARCHIVED PE images too (`_archived/`), which the old
    extractor never saw, so those are checked against the traversal's staged
    copies rather than against a file in the client root.

ONE OLD GATE IS DELIBERATELY NOT REVIVED: `index["outsideRoot"]` recorded a
separate sweep for PE images outside the client root. That sweep is no longer a
sweep - every member of every archive is read anyway, so an archived PE is found
by construction and lands in `archived`. Asserting the key exists would be
asserting a vestige. The property it stood for (images outside the root are
found) is now checked directly: `archivedBinaryCount` must be non-zero and every
one of them must reproduce.
"""
import gzip
import hashlib
import json
import shutil
import sys
import tempfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from tools import config, emit, layerstate, lua51, pe, peextract as eb

FAILURES = []
OUT = config.RAW_DIR / "binaries"
SNAP = config.WORK_DIR / "snapshot"
STAGED_PE = config.WORK_DIR / "harvest" / "pe"


def check(name, condition, detail=""):
    if condition:
        print(f"  PASS  {name}")
    else:
        print(f"  FAIL  {name}   {detail}")
        FAILURES.append(name)


def sha(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def load(p: Path):
    return json.loads(p.read_bytes().decode("utf-8"))


def shard_rows(d: Path, index: dict) -> list:
    rows = []
    for shard in index["shards"]:
        fp = d / shard["file"]
        raw = fp.read_bytes()
        check(f"{d.parent.name}/{d.name}: shard {shard['file']} matches its "
              f"recorded sha256", sha(raw) == shard["sha256"])
        text = (gzip.decompress(raw) if fp.suffix == ".gz" else raw).decode("utf-8")
        rows.extend(json.loads(l) for l in text.splitlines() if l.strip())
    return rows


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

# ==================== 2. against the client's own bytes ====================
# The SNAPSHOT, not the live client: the layer was built from the snapshot, so
# comparing it to a client the launcher may have patched since would fail for a
# reason that is not a defect. The snapshot's own sha256s are in
# raw/_snapshot.json and are what makes it the client's bytes.
if not SNAP.is_dir():
    print(f"\nno snapshot at {SNAP} - skipping byte-level checks "
          f"(run `python datamine.py`)")
    SOURCE = {}
else:
    print(f"\nclient bytes from the snapshot at {SNAP}")
    SOURCE = {p.name: p for p in sorted(SNAP.iterdir())
              if p.is_file() and p.read_bytes()[:2] == b"MZ"}
    check("the snapshot holds PE images at the client root", len(SOURCE) >= 2,
          str(len(SOURCE)))
    check("selection is by bytes, not by extension: every pick starts MZ and "
          "carries a PE signature",
          all(pe.is_pe(p.read_bytes()[:0x400]) for p in SOURCE.values()))

    for name, p in SOURCE.items():
        parsed = pe.parse(p.read_bytes())
        check(f"{name} parses with no unreadable structure",
              parsed["isPE"] and not parsed["notes"], str(parsed["notes"]))

    # The magic-versus-chunk distinction, on the real file that has the trap.
    asc = SOURCE.get("Ascension.exe")
    if asc is not None:
        cands = lua51.find_chunks(asc.read_bytes())
        check("Ascension.exe carries the Lua signature", len(cands) >= 1)
        check("and every one of them is REJECTED by the structure walk, so the "
              "layer never reports a compiler constant as recovered script",
              all(not c["ok"] for c in cands),
              str([c.get("reason") for c in cands]))

# ==================== 3. the committed layer ====================
if not layerstate.is_complete(OUT):
    print(f"\n{OUT} has no sentinel - skipping layer checks")
elif not SOURCE:
    print("\nno snapshot - skipping layer-versus-client checks")
else:
    print(f"\ncommitted layer at {OUT}")
    index = load(OUT / "index.json")
    check("the index names every client-root PE the snapshot holds",
          {b["name"] for b in index["binaries"]} == set(SOURCE))
    check("images stored INSIDE the archives are in the layer too - the old "
          "extractor could not see them at all",
          index["archivedBinaryCount"] > 0 and
          len(index["archived"]) == index["archivedBinaryCount"],
          str(index["archivedBinaryCount"]))
    check("every threshold the layer applied is written down next to the counts",
          all(k in index for k in ("minRunLength", "luaMinScore",
                                   "luaFragmentMinScore", "stringRule",
                                   "luaRule", "resourceRule")),
          str(sorted(k for k in ("minRunLength", "luaMinScore",
                                 "luaFragmentMinScore", "stringRule",
                                 "luaRule", "resourceRule") if k not in index)))
    check("the thresholds in the index are the ones the extractor actually used",
          index["minRunLength"] == eb.MIN_RUN
          and index["luaMinScore"] == eb.LUA_MIN_SCORE
          and index["luaFragmentMinScore"] == eb.LUA_FRAGMENT_MIN_SCORE)

    # Layer-wide rollups: a reader must be able to answer "how much Lua did this
    # client's binaries yield" without summing 27 records by hand, and the sums
    # must be the records'.
    every = index["binaries"] + index["archived"]
    check("the layer's rollups equal the sum of the per-image records",
          index["stringTotal"] == sum(b["strings"] for b in every)
          and index["luaChunkTotal"] == sum(b["luaSourceChunks"] for b in every)
          and index["luaFragmentTotal"] == sum(b["luaFragments"] for b in every)
          and index["resourceTotal"] == sum(b["resourceCount"] for b in every)
          and index["symbolTotal"] == sum(b["symbols"] for b in every),
          json.dumps({k: index[k] for k in
                      ("stringTotal", "luaChunkTotal", "luaFragmentTotal",
                       "resourceTotal", "symbolTotal")}))

    for entry in index["binaries"]:
        name = entry["name"]
        src = SOURCE.get(name)
        if src is None:
            continue
        data = src.read_bytes()
        check(f"{name}: the committed sha256 is the client's file",
              sha(data) == entry["sha256"])
        bdir = OUT / entry["dir"]

        # -- strings are re-read from the client at their own offsets --------
        six = load(bdir / "strings" / "index.json")
        rows = shard_rows(bdir / "strings", six)
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
        lix = load(bdir / "lua" / "index.json")
        for r in shard_rows(bdir / "lua", lix):
            if r["kind"] not in ("sourceChunk", "precompiled"):
                continue
            got = (bdir / "lua" / r["file"]).read_bytes()
            check(f"{name}: {r['file']} is the client's bytes at {r['off']:#x}",
                  got == data[r["off"]:r["off"] + r["bytes"]]
                  and sha(got) == r["sha256"])
        check(f"{name}: every chunk file the index lists exists",
              all((bdir / "lua" / f["file"]).is_file()
                  for f in lix["chunkFiles"]))

        # -- the overlay, which no section table entry accounts for ----------
        ov = entry.get("overlay") or {}
        if ov.get("bytesCommitted"):
            got = (bdir / ov["file"]).read_bytes()
            check(f"{name}: the overlay is the client's trailing bytes",
                  got == data[ov["offset"]:ov["offset"] + ov["bytes"]]
                  and sha(got) == ov["sha256"])

        # -- resources are the client's bytes too ----------------------------
        rix = load(bdir / "resources" / "index.json")
        for r in rix["resources"]:
            if not r.get("bytesCommitted") or not r.get("file"):
                continue
            got = (bdir / "resources" / r["file"]).read_bytes()
            check(f"{name}: resource {r['file']} matches the client",
                  got == data[r["offset"]:r["offset"] + r["bytes"]]
                  and sha(got) == r["sha256"])

    # -- archived images: their bytes came out of an archive, so the check is
    #    against what the traversal staged rather than against a file on disk
    if STAGED_PE.is_dir():
        staged = {sha(p.read_bytes()): p for p in sorted(STAGED_PE.iterdir())
                  if p.is_file()}
        missing = [a["name"] for a in index["archived"]
                   if a["sha256"] not in staged]
        check(f"every one of the {len(index['archived'])} archived PE images is "
              f"the bytes the traversal staged for it", not missing,
              str(missing[:4]))
    else:
        print(f"  SKIP  {STAGED_PE} absent - archived-image byte check skipped")

    # -- reproduction: re-extract the smallest binary and compare -------------
    smallest_name = min(index["binaries"], key=lambda b: b["bytes"])["name"]
    smallest = SOURCE[smallest_name]
    tmp = Path(tempfile.mkdtemp(prefix="coa-bin-"))
    try:
        prev_root = eb.OUT_ROOT
        eb.OUT_ROOT = tmp
        try:
            eb.extract_bytes(smallest.read_bytes(), smallest_name,
                             tmp / smallest_name, verbose=False)
        finally:
            eb.OUT_ROOT = prev_root
        committed = OUT / smallest_name
        produced_root = tmp / smallest_name
        diffs = []
        for produced in sorted(produced_root.rglob("*")):
            if not produced.is_file():
                continue
            rel = produced.relative_to(produced_root)
            other = committed / rel
            if not other.is_file() or sha(other.read_bytes()) != \
                    sha(produced.read_bytes()):
                diffs.append(str(rel))
        extra = [str(p.relative_to(committed))
                 for p in sorted(committed.rglob("*"))
                 if p.is_file()
                 and not (produced_root / p.relative_to(committed)).is_file()]
        check(f"re-extracting {smallest_name} reproduces the committed tree byte "
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
