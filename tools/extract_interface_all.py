"""Complete census of the client's `Interface\\` tree - every path, not just code.

WHAT THIS ADDS OVER raw/interface/
----------------------------------
`tools/extract_interface.py` extracts the Interface CODE layer (.lua/.xml/.toc/
.txt/.md) as bytes. That is 1,469 of the client's **93,437** Interface paths. The
other 91,968 - almost all of them BLP textures - had no record anywhere, so
"is there an icon/texture for X" was unanswerable from this repo. This module
closes that: every Interface path in the client inventory gets a record here,
with its winning archive, uncompressed size, sha256, MPQ flags, whether it is
readable, and whether its bytes are text or binary.

THE ONE SIZE DECISION, STATED PLAINLY
-------------------------------------
Bytes are committed for every file MEASURED to be text. For files measured to be
binary, the record carries path + size + sha256 and the bytes are NOT committed.

That is a REPOSITORY SIZE decision, not a completeness decision, and the two must
not be confused: the Interface tree is 4.449 GB, of which 4.42 GB is BLP/TGA/M2/
AVI art, and committing it would put this repo 2x over its entire budget for one
directory. Nothing is being curated away - the sha256 of every one of those files
is here, so any of them can be pulled from the client on demand and verified to
be the exact file this census saw. The rule is mechanical (see TEXT_RULE) and
applies to every path identically; no extension list decides it and no human
picked which art matters.

WHAT IS DELIBERATELY OUT OF SCOPE, AND WHY IT IS COUNTED ANYWAY
--------------------------------------------------------------
`E:\\ascension-live\\Interface\\AddOns\\` on disk is the USER's installed
third-party addons, not client data - it is whatever that machine happens to have
downloaded. Only `AddOns\\APIDocumentation` is taken from there (it is Ascension's
own launcher-managed description of their real API surface; see AGENT-GUIDE.md).
The rest is counted in `onDiskInterfaceTree` in index.json - file count, bytes and
the addon names - so the exclusion is visible and auditable rather than silent.

INPUT
-----
`raw/_inventory/files/*.json`, written by `tools/inventory.py`. Every Interface
path's identity, winner and sha256 comes from there rather than from a fresh
archive walk, so this layer cannot disagree with the census it is derived from -
and the sha256 of every file this module reads is CHECKED against the inventory's,
which turns that reuse into a cross-verification instead of a leap of faith.
"""
import hashlib
import json
import time
from pathlib import Path

from mpyq import MPQArchive

from tools import config, inventory
from tools.decode_all import write_text

OUT_DIR = config.RAW_DIR / "interface_all"
PATHS_DIR = OUT_DIR / "paths"
TEXT_DIR = OUT_DIR / "text"
CODE_LAYER = config.RAW_INTERFACE_DIR

# C0 controls that are ordinary in text files.
_TEXT_CONTROLS = {0x09, 0x0A, 0x0D, 0x0C, 0x0B}
_BAD_CONTROLS = bytes(c for c in range(0x20) if c not in _TEXT_CONTROLS)
_CONTROL_BUDGET = 512          # 1 stray control byte per 512 is still text

TEXT_RULE = (
    "A file is text if its decompressed bytes contain no NUL and fewer than one "
    f"C0 control byte per {_CONTROL_BUDGET} bytes outside tab/newline/CR/FF/VT; "
    "an empty file is text. Its encoding is recorded as utf-8 when it decodes "
    "strictly as UTF-8 and latin-1 otherwise. The rule reads the bytes - no "
    "extension list, no filename pattern, and no judgment about which files "
    "matter decides it, so a .blp that really were text would be committed and "
    "a .lua that really were binary would not.")

SIZE_RULE = (
    "Bytes are committed for every file measured as text. For binary files the "
    "record carries path, uncompressed size and sha256 and the bytes stay in the "
    "client. This is a repository-size decision, not a curation decision: the "
    "Interface tree is 4.45 GB and is 99% art. Every binary file's sha256 is "
    "here, so the exact bytes this census saw can be pulled from the client and "
    "verified at any time.")


def classify(data: bytes) -> dict:
    """Measured text/binary verdict + the counts behind it.

    A NUL short-circuits, because 98% of this tree is art and a NUL almost
    always sits in its first few bytes - scanning 4.4 GB for control-character
    ratios that a single NUL already settles would cost minutes for nothing."""
    n = len(data)
    if n == 0:
        return {"isText": True, "encoding": "empty", "hasNul": False,
                "controlBytes": 0}
    if data.find(b"\0") >= 0:
        return {"isText": False, "encoding": None, "hasNul": True,
                "controlBytes": None}
    ctrl = n - len(data.translate(None, _BAD_CONTROLS))
    is_text = ctrl * _CONTROL_BUDGET < n
    enc = None
    if is_text:
        try:
            data.decode("utf-8")
            enc = "utf-8"
        except UnicodeDecodeError:
            enc = "latin-1"
    return {"isText": is_text, "encoding": enc, "hasNul": False,
            "controlBytes": ctrl}


def _index_hash_table(arch) -> None:
    """Replace mpyq's per-lookup LINEAR SCAN of the hash table with a dict built
    once per archive.

    `MPQArchive.get_hash_table_entry` walks the whole hash table for every call.
    patch-I holds 75,963 Interface paths against a hash table of the same order,
    which makes reading them all quadratic: measured at 6.2 ms per file, ~8
    minutes for that one archive, essentially all of it scanning rather than
    decompressing. The (hash_a, hash_b) pair is what the scan compares, so
    indexing on it is exactly equivalent - same lookup, same result, same
    first-match-wins order - and turns the walk into a dict hit."""
    index = {}
    for e in arch.hash_table:
        if e.block_table_index < 0xFFFFFFFE:
            index.setdefault((e.hash_a, e.hash_b), e)
    arch.get_hash_table_entry = lambda name: index.get(
        (arch._hash(name, "HASH_A"), arch._hash(name, "HASH_B")))


def _inventory_interface_records() -> list:
    """Every Interface path the inventory recorded, from its committed shards."""
    if not inventory.FILES_DIR.is_dir():
        raise SystemExit(
            f"FATAL: {inventory.FILES_DIR} is missing. This layer is derived from "
            f"the client inventory - run `python -m tools.inventory` first.")
    out = []
    for shard in sorted(inventory.FILES_DIR.glob("*.json")):
        for raw in shard.read_text(encoding="utf-8").splitlines():
            raw = raw.strip().rstrip(",")
            if not raw.startswith("{"):
                continue
            r = json.loads(raw)
            if r["path"].lower().startswith("interface/"):
                out.append(r)
    return out


def _on_disk_census() -> dict:
    """Count (never extract) the user's live Interface\\ tree, so the scope
    boundary is a visible number rather than an unstated omission."""
    root = config.CLIENT_DIR / "Interface"
    if not root.is_dir():
        return {"present": False}
    files = [p for p in root.rglob("*") if p.is_file()]
    addons = sorted(p.name for p in (root / "AddOns").iterdir()
                    if p.is_dir()) if (root / "AddOns").is_dir() else []
    return {"present": True, "root": str(root), "fileCount": len(files),
            "bytes": sum(p.stat().st_size for p in files),
            "addonDirs": addons, "addonDirCount": len(addons),
            "takenFromHere": ["AddOns/APIDocumentation"],
            "note": "Third-party addons the user installed. Not client data, so "
                    "not extracted; counted here so the boundary is auditable. "
                    "AddOns/APIDocumentation is the sole exception and is "
                    "extracted by tools/extract_interface.py."}


def extract_all(verbose: bool = True) -> dict:
    t0 = time.time()
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    for old in sorted(OUT_DIR.rglob("*"), reverse=True):
        old.unlink() if old.is_file() else old.rmdir()
    PATHS_DIR.mkdir(parents=True, exist_ok=True)

    records = _inventory_interface_records()
    by_archive = {}
    for r in records:
        by_archive.setdefault(r["winner"], []).append(r)

    stats = {"text": 0, "binary": 0, "unreadable": 0, "hashMismatch": 0,
             "committed": 0, "committedBytes": 0, "inCodeLayer": 0,
             "readBytes": 0}
    mismatches = []
    out_records = []
    done = 0

    for aname in sorted(by_archive):
        apath = config.CLIENT_DIR / aname.replace("/", "\\")
        arch = MPQArchive(str(apath), listfile=False)
        _index_hash_table(arch)
        for r in by_archive[aname]:
            stored = r["path"].replace("/", "\\")
            rec = {"path": r["path"], "winner": r["winner"], "size": r["size"],
                   "storedBytes": r.get("storedBytes"), "sha256": r.get("sha256"),
                   "flags": r.get("flags", [])}
            if r.get("losers"):
                rec["losers"] = r["losers"]
            if r.get("readable") is False:
                rec.update({"readable": False, "readError": r.get("readError"),
                            "isText": None, "bytesAt": None})
                stats["unreadable"] += 1
                out_records.append(rec)
                continue
            try:
                data = arch.read_file(stored)
            except Exception as e:
                data = None
                rec["readError"] = f"{type(e).__name__}: {e}"
            if data is None:
                rec.update({"readable": False, "isText": None, "bytesAt": None})
                rec.setdefault("readError", "read_file returned None")
                stats["unreadable"] += 1
                out_records.append(rec)
                continue

            stats["readBytes"] += len(data)
            digest = hashlib.sha256(data).hexdigest()
            if r.get("sha256") and digest != r["sha256"]:
                stats["hashMismatch"] += 1
                mismatches.append({"path": r["path"], "inventory": r["sha256"],
                                   "read": digest})
            c = classify(data)
            rec.update({"readable": True, "isText": c["isText"],
                        "encoding": c["encoding"], "hasNul": c["hasNul"],
                        "controlBytes": c["controlBytes"]})
            if not c["isText"]:
                rec["bytesAt"] = None
                stats["binary"] += 1
                out_records.append(rec)
                continue

            stats["text"] += 1
            rel = r["path"].split("/", 1)[1] if "/" in r["path"] else r["path"]
            code_copy = CODE_LAYER.joinpath(*rel.split("/"))
            if code_copy.is_file() and hashlib.sha256(
                    code_copy.read_bytes()).hexdigest() == digest:
                rec["bytesAt"] = "raw/interface/" + rel
                stats["inCodeLayer"] += 1
            else:
                dest = TEXT_DIR.joinpath(*rel.split("/"))
                dest.parent.mkdir(parents=True, exist_ok=True)
                dest.write_bytes(data)
                rec["bytesAt"] = "raw/interface_all/text/" + rel
                stats["committed"] += 1
                stats["committedBytes"] += len(data)
            out_records.append(rec)
        arch.file.close()
        done += len(by_archive[aname])
        if verbose:
            print(f"  {aname:28s} {done:6d}/{len(records)} "
                  f"[{time.time() - t0:6.1f}s]")

    # ---- shard by path prefix, exactly as the inventory shards its own ----
    # Keys use the client's own backslash separators (as the inventory does), so
    # `inventory.shard_names` flattens them to '-' instead of percent-escaping a
    # forward slash into unreadable filenames.
    by_path = {r["path"].replace("/", "\\").lower(): r for r in out_records}
    if len(by_path) != len(out_records):
        raise SystemExit(f"FATAL: path-key collision - {len(out_records)} records "
                         f"collapsed to {len(by_path)} keys.")
    groups = inventory.partition(list(by_path))
    if sum(len(v) for v in groups.values()) != len(by_path):
        raise SystemExit("FATAL: sharding lost records; refusing to write a "
                         "silently-incomplete census.")
    names = inventory.shard_names(groups)
    if len(set(names.values())) != len(groups):
        raise SystemExit("FATAL: shard filename collision survived disambiguation.")
    shards = []
    for key in sorted(groups):
        rows = [by_path[p] for p in sorted(groups[key])]
        # shard_names() suffixes .json (the inventory's own shard format); this
        # layer's shards are line-per-record, so the extension says so.
        fn = names[key][:-len(".json")] + ".jsonl"
        write_text(PATHS_DIR / fn,
                   "".join(json.dumps(r, ensure_ascii=False, sort_keys=True,
                                      separators=(",", ":")) + "\n" for r in rows))
        shards.append({"file": fn, "prefix": key[0].replace("\\", "/"),
                       "kind": key[1], "records": len(rows),
                       "firstPath": rows[0]["path"], "lastPath": rows[-1]["path"],
                       "sha256": hashlib.sha256(
                           (PATHS_DIR / fn).read_bytes()).hexdigest()})

    ext = {}
    for r in out_records:
        base = r["path"].rsplit("/", 1)[-1]
        e = base.rsplit(".", 1)[-1].lower() if "." in base else "_noext"
        d = ext.setdefault(e, {"files": 0, "bytes": 0, "text": 0, "unreadable": 0})
        d["files"] += 1
        d["bytes"] += r["size"]
        d["text"] += 1 if r.get("isText") else 0
        d["unreadable"] += 0 if r.get("readable", True) else 1

    index = {
        "note": "Every path under Interface\\ in the client MPQ chain. Per-path "
                "records are in paths/*.jsonl, one compact record per line, "
                "sharded by path prefix (a path's shard is a pure function of "
                "that path). `bytesAt` says where the committed bytes live, or "
                "is null when only the hash is kept.",
        "pathCount": len(out_records),
        "totalBytes": sum(r["size"] for r in out_records),
        "textCount": stats["text"], "binaryCount": stats["binary"],
        "unreadableCount": stats["unreadable"],
        "bytesInCodeLayer": stats["inCodeLayer"],
        "bytesCommittedHere": stats["committed"],
        "bytesCommittedHereBytes": stats["committedBytes"],
        "bytesRead": stats["readBytes"],
        "sha256Mismatches": mismatches,
        "sha256MismatchCount": stats["hashMismatch"],
        "textRule": TEXT_RULE,
        "sizeRule": SIZE_RULE,
        "shardMaxRecords": inventory.SHARD_MAX,
        "shardCount": len(shards),
        "byExtension": {k: ext[k] for k in sorted(ext)},
        "onDiskInterfaceTree": _on_disk_census(),
        "shards": shards,
    }
    write_text(OUT_DIR / "index.json",
               json.dumps(index, ensure_ascii=False, indent=1, sort_keys=True) + "\n")
    write_text(OUT_DIR / "README.md", _readme(index))
    return index


def _readme(ix: dict) -> str:
    top = sorted(ix["byExtension"].items(), key=lambda kv: -kv[1]["files"])[:14]
    rows = "\n".join(f"| `{k}` | {v['files']:,} | {v['bytes']/1e6:,.1f} | "
                     f"{v['text']:,} | {v['unreadable']} |" for k, v in top)
    d = ix["onDiskInterfaceTree"]
    disk = (f"- on-disk `Interface\\` tree: **{d['fileCount']:,} files** "
            f"({d['bytes']/1e6:,.0f} MB) in {d['addonDirCount']} addon "
            f"directories - counted, not extracted (see below)"
            if d.get("present") else "- on-disk `Interface\\` tree: not present")
    return f"""# Complete Interface census (generated)

Regenerate: `python -m tools.extract_interface_all`. Written by
`tools/extract_interface_all.py` from `raw/_inventory/files/` (so run
`python -m tools.inventory` first). Nothing here is hand-authored.

## Totals

- **{ix['pathCount']:,} Interface paths** ({ix['totalBytes']/1e9:.3f} GB uncompressed in the client)
- **{ix['textCount']:,} measured text**, {ix['binaryCount']:,} measured binary, {ix['unreadableCount']} unreadable
- bytes committed: {ix['bytesInCodeLayer']:,} already in `raw/interface/`, {ix['bytesCommittedHere']:,} added here ({ix['bytesCommittedHereBytes']/1e3:,.0f} KB)
- **{ix['sha256MismatchCount']} sha256 mismatches** against the inventory across {ix['bytesRead']/1e9:.2f} GB re-read and re-hashed
{disk}

## Layout

```
raw/interface_all/index.json        totals, extension census, both rules, shard map
raw/interface_all/paths/*.jsonl     every path, one compact record per line
raw/interface_all/text/**           bytes of text files raw/interface/ does not carry
```

Each path record: `path`, `winner` (archive), `size`, `sha256`, `storedBytes`,
`flags`, `readable`, `isText`, `encoding`, and `bytesAt` - the repo path holding
the bytes, or `null` when only the hash is kept.

## What decides text vs binary

{ix['textRule']}

## Why binary bytes are not committed

{ix['sizeRule']}

## Extension census

| ext | files | MB | text | unreadable |
| --- | ---: | ---: | ---: | ---: |
{rows}

## Scope: the on-disk `Interface\\` tree

{d.get('note', '')}
"""


def main():
    ix = extract_all()
    print(f"interface paths: {ix['pathCount']} "
          f"(text={ix['textCount']}, binary={ix['binaryCount']}, "
          f"unreadable={ix['unreadableCount']}, "
          f"sha256Mismatches={ix['sha256MismatchCount']})")
    print(f"bytes committed here: {ix['bytesCommittedHere']} files, "
          f"{ix['bytesCommittedHereBytes']} bytes; "
          f"{ix['bytesInCodeLayer']} already in raw/interface/")


if __name__ == "__main__":
    main()
