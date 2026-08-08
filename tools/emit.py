"""Layer writers for `datamine.py`.

WHAT THIS IS, AND WHAT IT IS NOT
--------------------------------
Not a stage chain. Nothing here opens an archive, walks the client or decides
what to extract - `datamine.py` did all of that once, and every function in this
module is handed what the single traversal already holds. Split out of
`datamine.py` only because one file carrying both the traversal and ten layer
writers is harder to read than two, and the driver is the interesting half.

Every writer is a pure function of the harvest plus the snapshot on disk, writes
into a STAGING directory, and reports the counts it measured. `publish()` swaps
staging over `raw/` once the whole run has succeeded, so a failure never leaves a
half-written layer for the next reader to mistake for a finished one.
"""
import base64
import gc
import hashlib
import json
import os
import re
import shutil
import time
from collections import Counter
from pathlib import Path

from tools import config, dbcdecode, layerstate, loc, rawshard, sharding, wdb

SHARD_MAX = 5000

# ---------------------------------------------------------------- rules
LOOSE_OVERRIDE_RULE = (
    "A 3.3.5 client resolves `<clientRoot>\\<path>` on disk BEFORE it looks in "
    "the MPQ chain, so a loose file at the client root beats every archive that "
    "carries the same path - which is how this client ships its own ChatBubble "
    "textures and its silenced Fizzle sounds. A loose file whose root-relative "
    "path is also an MPQ path WINS that path: `source` becomes `loose`, "
    "`winner` becomes `<disk>`, `size`/`sha256` are the file's own, and the "
    "archive copy it displaced is preserved under `overrides` so nothing is "
    "lost.")

TEXT_RULE = (
    "A file is text if its decompressed bytes contain no NUL and fewer than one "
    "C0 control byte per 512 bytes outside tab/newline/CR/FF/VT; an empty file "
    "is text. Its encoding is recorded as utf-8 when it decodes strictly as "
    "UTF-8 and latin-1 otherwise. The rule reads the bytes - no extension list, "
    "no filename pattern, and no judgment about which files matter decides it.")

SIZE_RULE = (
    "Bytes are committed for every file measured as text. For binary files the "
    "record carries path, uncompressed size and sha256 and the bytes stay in "
    "the client. This is a repository-size decision, not a curation decision: "
    "the Interface tree is 4.45 GB and is 99% art. Every binary file's sha256 "
    "is here, so the exact bytes this census saw can be pulled from the client "
    "and verified at any time.")

VARIANT_RULE = (
    "One version per DISTINCT sha256 among the copies of a path, not one per "
    "carrying archive: byte-identical copies in several archives are ONE "
    "version, listed once under the highest-ranked archive that carries those "
    "bytes with the rest recorded in `alsoIn`. The chain winner keeps its place "
    "at raw/tables/<T>/ and is listed with `chainWinner` true; every other "
    "version is decoded into raw/tables/<T>/variants/<slug>/ by the same "
    "decoder, so the two are comparable byte for byte. `rowDelta` is this "
    "version's record count minus the chain winner's.")

CONTEXT_RULE = (
    "A chain context is a set of archives a running client actually loads, "
    "enumerated from the client's own directory layout rather than from a list: "
    "`baseChain` is every archive in the base and locale directories - what a "
    "character reads when no realm overlay applies - and there is one further "
    "context per realm directory found, holding that same base set plus the "
    "archives that realm's `listarchive` declares. A version APPLIES TO a "
    "context when its archive is the highest-ranked carrier of that path inside "
    "it. A version that is the highest-ranked carrier in no context at all is "
    "still decoded - it is real client data - and is marked shadowed.")

TOMBSTONE_RULE = (
    "An MPQ DELETE_MARKER entry is a patch REMOVING a path at its layer. It "
    "carries no bytes by design, so it is archive semantics rather than a "
    "failed read, and it is enumerated here rather than counted as damage.")

MD5_RULE = (
    "Every member read by the traversal is checked against the MD5 the archive "
    "itself records for it in its `(attributes)` block - an oracle outside this "
    "code and outside the reader. `noRecord` counts members whose archive keeps "
    "no MD5 for them, which is a property of that archive, not a failure.")

COVERAGE_RULE = (
    "For each archive, every EXISTS block entry contributes the span "
    "[offset, offset+archivedSize) and the spans are merged. `unaccountedBytes` "
    "is what is left of the region between the end of the header and the start "
    "of the first table once those spans are removed - i.e. file data physically "
    "present in the archive that no live block entry claims. That is where the "
    "bytes of a deleted-but-not-compacted file would still be, so it is the "
    "direct test of whether delete-marked hash slots have anything recoverable "
    "behind them. It is measured, not argued.")

DEFECT_CLASS_RULE = (
    "The two classes of member the previous reader (mpyq) returned confident "
    "WRONG bytes for, counted per archive so the claim in tools/mpq.py's header "
    "is a measurement of THIS client rather than a remembered number: a member "
    "stored with no sector offset table (neither COMPRESS nor IMPLODE), and a "
    "member whose uncompressed size is an exact multiple of the sector size. "
    "`readOk`/`readFailed` are how this run's reader did on them. "
    "`notNamedByListfile` is the honest residual - block entries in these "
    "classes that no listfile names, so the traversal had no path to read them "
    "by; they are counted, not read, because reading by block index would mean "
    "decompressing bytes a second time.")

INTERPRETATION_NOTE = (
    "position -> TrinityCore field name, per magic. UNVERIFIED by construction: "
    "a permutation of same-width fields consumes the same bytes, so no name here "
    "can be checked against the client. Read values out of `fN`; use these names "
    "to form a hypothesis, then test it.")

_SOUND_EXT = {"mp3", "wav", "ogg", "wfx"}
_ART_EXT = {"blp", "m2", "skin", "anim", "wmo", "adt", "wdt", "wdl", "bls",
            "tga", "jpg", "jpeg", "png", "gif", "bone", "tex", "mdx", "avi",
            "ttf", "icns", "zmp"}

DISK_WINNER = "<disk>"
BASE_CONTEXT = "baseChain"
VARIANT_SUBDIR = "variants"

_TEXT_CONTROLS = {0x09, 0x0A, 0x0D, 0x0C, 0x0B}
_BAD_CONTROLS = bytes(c for c in range(0x20) if c not in _TEXT_CONTROLS)
_CONTROL_BUDGET = 512

_SLUG = re.compile(r"[^a-z0-9]+")
_SAFE = set("abcdefghijklmnopqrstuvwxyz0123456789-_~")
_BANDS = ("abc", "def", "ghi", "jkl", "mno", "pqr", "stu", "vwx", "yz")
_BAND_OF = {c: b for b in _BANDS for c in b}


# ==========================================================================
# shared helpers
# ==========================================================================
def write_bytes_lf(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(text.encode("utf-8"))


def write_json(path: Path, payload) -> None:
    write_bytes_lf(path, json.dumps(payload, indent=1, sort_keys=True,
                                    ensure_ascii=False) + "\n")


def slug(text: str) -> str:
    return _SLUG.sub("-", text.lower()).strip("-")


def classify_text(data: bytes) -> dict:
    """Measured text/binary verdict + the counts behind it. See TEXT_RULE.

    A NUL short-circuits, because most of this client is art and a NUL almost
    always sits in its first few bytes - scanning gigabytes for control-byte
    ratios that a single NUL already settles costs minutes for nothing."""
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


_CONTAINER_MAGIC = (
    (b"MPQ\x1a", "mpq"), (b"Rar!\x1a\x07\x00", "rar"),
    (b"Rar!\x1a\x07\x01\x00", "rar5"), (b"PK\x03\x04", "zip"),
    (b"bplist00", "bplist"), (b"7z\xbc\xaf\x27\x1c", "7z"),
)


def sniff_container(data: bytes):
    """Is this member itself an archive? Detected by MAGIC, not by extension,
    so a nested container under any name is found. Returns the kind or None."""
    if len(data) < 8:
        return None
    for magic, kind in _CONTAINER_MAGIC:
        if data[:len(magic)] == magic:
            return kind
    return None


def path_class(path: str, source: str) -> str:
    """Reporting rollup ONLY - it gates nothing. The per-extension and
    per-top-level-directory censuses emitted beside it are the ground truth."""
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


def band_of(ch: str) -> str:
    return _BAND_OF.get(ch, "other")


def partition(paths: list, limit: int = SHARD_MAX) -> dict:
    """Group paths into shards keyed by a CHARACTER PREFIX of the path.

    Directory depth cannot bound shard size on this client at all -
    Interface\\Icons alone is one flat directory of 76k files - so a character
    trie is used instead. Every rule is a constant or a property of the path
    itself, so a path's shard is a pure function of that path: adding or
    removing files never reshuffles unrelated shards the way count-chunking
    does. The key is a TUPLE because a client path containing a literal '~band'
    run would otherwise let one node's band key collide with another's."""
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
            if d >= len(pth):
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


def _prefix_digest(key: tuple) -> str:
    return hashlib.sha256("\x00".join(key).encode("utf-8", "replace")
                          ).hexdigest()[:8]


def _shard_name_raw(key: tuple) -> str:
    prefix, kind = key
    stem = "".join(c if c in _SAFE else "-" if c == "\\"
                   else "%%%02x" % (ord(c) & 0xFF) for c in prefix.lower())
    name = (stem or "_root") + kind
    if len(name) > 120:
        name = name[:110] + "-" + _prefix_digest(key)
    return name


def shard_names(prefixes) -> dict:
    """Flat, greppable filename per prefix. Two DIFFERENT prefixes can flatten
    to the same string, and a silent collision would overwrite one shard with
    another - so collisions are detected and disambiguated by prefix digest."""
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
    and it keeps a 5,000-record shard at 5,002 lines rather than tens of
    thousands of nested-indent lines."""
    lines = ["["]
    for i, r in enumerate(records):
        lines.append(" " + json.dumps(r, ensure_ascii=False, sort_keys=True,
                                      separators=(",", ":"))
                     + ("," if i < len(records) - 1 else ""))
    lines.append("]")
    return "\n".join(lines) + "\n"


def _census(records: list, keyfn):
    c = {}
    for r in records:
        k = keyfn(r)
        d = c.setdefault(k, {"files": 0, "bytes": 0})
        d["files"] += 1
        d["bytes"] += r["size"]
    return dict(sorted(c.items()))


# ==========================================================================
# raw/_inventory
# ==========================================================================
def emit_inventory(h, manifest: dict, probe: dict, out: Path) -> dict:
    """The census: every archive, every path, the winner of every path, and the
    sha256 of the winning bytes. Everything here was measured by the traversal;
    nothing is re-read."""
    inv = out / "_inventory"
    files_dir = inv / "files"
    files_dir.mkdir(parents=True, exist_ok=True)

    arch_records = []
    for rank, s in enumerate(h.archives):
        rec = {"id": s["id"], "archive": s["path"].name,
               "dir": str(s["path"].parent.relative_to(config.CLIENT_DIR)
                          ).replace("\\", "/"),
               "layer": s["layer"], "realm": s["realm"],
               "declaredInListarchive": s["declared"],
               "chainRank": [str(x) for x in s["rank"]],
               "archiveBytes": s["bytes"], "sha256": s["sha256"],
               "listable": s["listable"], "fileCount": s.get("fileCount", 0),
               "blockExistsCount": s.get("blockExistsCount", 0),
               "unnamedCount": s.get("unnamedCount", 0),
               "metaMembers": s.get("metaMembers", [])}
        for k in ("formatVersion", "hashTableEntries", "blockTableEntries",
                  "hashSlotsUsed", "hashSlotsDeleteMarked",
                  "blockEncryptedCount", "uncompressedBytes", "listfileLines",
                  "listfileUnresolved", "listfileUnresolvedCount",
                  "unlistableReason", "openError"):
            if s.get(k) is not None:
                rec[k] = s[k]
        arch_records.append(rec)

    # ---- loose files: under Data\, and the client-root overrides ----
    loose, overrides = {}, {}
    snap = manifest["files"]
    for rel, f in snap.items():
        if f["kind"] == "looseData":
            sub = rel.split("/", 1)[1]
            loose[sub.lower().replace("/", "\\")] = {
                "stored": sub.replace("/", "\\"), "size": f["bytes"],
                "sha256": f["sha256"]}
        elif f["kind"] == "rootOverride":
            overrides[rel.lower().replace("/", "\\")] = {
                "stored": rel.replace("/", "\\"), "size": f["bytes"],
                "sha256": f["sha256"]}

    records = []
    for low in sorted(h.carriers):
        c = h.carriers[low]
        e = c["e"]
        r = {"path": e["stored"].replace("\\", "/"), "source": "mpq",
             "winner": c["winner"], "size": e["size"],
             "storedBytes": e["storedBytes"],
             "class": path_class(low, "mpq"),
             "flags": _flag_names(e["flags"])}
        if c["losers"]:
            r["losers"] = sorted(set(c["losers"]))
        if e.get("sha256"):
            r["sha256"] = e["sha256"]
        if e.get("readError"):
            r["readable"] = False
            r["readError"] = e["readError"]
        if e.get("memberStatus"):
            r["memberStatus"] = e["memberStatus"]
        if e.get("dbc"):
            r["dbc"] = e["dbc"]
        o = overrides.get(low)
        if o is not None:
            r["overrides"] = {k: v for k, v in r.items()
                              if k in ("winner", "size", "storedBytes",
                                       "sha256", "flags", "losers", "readable",
                                       "readError", "memberStatus", "dbc")}
            r.update({"source": "loose", "winner": DISK_WINNER,
                      "diskPath": o["stored"].replace("\\", "/"),
                      "size": o["size"], "sha256": o["sha256"],
                      "storedBytes": None, "flags": [],
                      "differsFromArchive":
                          o["sha256"] != r["overrides"].get("sha256")})
            for k in ("readable", "readError", "memberStatus", "dbc"):
                r.pop(k, None)
        records.append(r)
    for low in sorted(loose):
        e = loose[low]
        records.append({"path": e["stored"].replace("\\", "/"),
                        "source": "loose", "winner": None, "size": e["size"],
                        "sha256": e["sha256"],
                        "class": path_class(low, "loose"), "flags": []})

    by_class = _census(records, lambda r: r["class"])
    by_top = _census(records, lambda r: r["path"].split("/", 1)[0].lower()
                     if "/" in r["path"] else "_root")
    by_ext = _census(records, lambda r: r["path"].rsplit(".", 1)[-1].lower()
                     if "." in r["path"].rsplit("/", 1)[-1] else "_noext")
    total_bytes = sum(r["size"] for r in records)
    dbc_records = [r for r in records if r["class"] == "dbc"]

    by_path = {r["path"].replace("/", "\\").lower(): r for r in records}
    if len(by_path) != len(records):
        raise SystemExit(f"FATAL: path-key collision - {len(records)} records "
                         f"collapsed to {len(by_path)} keys.")
    groups = partition(list(by_path))
    if sum(len(v) for v in groups.values()) != len(by_path):
        raise SystemExit("FATAL: sharding lost records. Refusing to write a "
                         "silently-incomplete inventory.")
    names = shard_names(groups)
    if len(set(names.values())) != len(groups):
        raise SystemExit("FATAL: shard filename collision survived "
                         "disambiguation; one shard would overwrite another.")
    shards = []
    for key in sorted(groups):
        rows = [by_path[p] for p in sorted(groups[key])]
        write_bytes_lf(files_dir / names[key], dump_records(rows))
        shards.append({"file": names[key], "prefix": key[0].replace("\\", "/"),
                       "kind": key[1], "records": len(rows),
                       "firstPath": rows[0]["path"],
                       "lastPath": rows[-1]["path"]})

    write_json(inv / "archives.json", {
        "clientDir": str(config.CLIENT_DIR),
        "archiveCount": len(arch_records),
        "listableCount": sum(1 for a in arch_records if a["listable"]),
        "unlistableCount": sum(1 for a in arch_records if not a["listable"]),
        "archiveBytesTotal": sum(a["archiveBytes"] for a in arch_records),
        "archives": arch_records})

    write_json(inv / "files.json", {
        "note": "Index for raw/_inventory/files/*.json. Per-path records live "
                "in the shards; each shard holds one compact JSON record per "
                "line, sorted by path, keyed by the path prefix in `prefix`.",
        "recordCount": len(records),
        "mpqPathCount": len(h.carriers),
        "loosePathCount": len(loose),
        "looseOverrideRule": LOOSE_OVERRIDE_RULE,
        "looseOverrideCount": len(overrides),
        "looseOverrides": [
            {"path": r["path"], "size": r["size"], "sha256": r["sha256"],
             "differsFromArchive": r["differsFromArchive"],
             "archiveWinner": r["overrides"]["winner"],
             "archiveSize": r["overrides"]["size"],
             "archiveSha256": r["overrides"].get("sha256")}
            for r in records if r.get("winner") == DISK_WINNER],
        "totalUncompressedBytes": total_bytes,
        "contentHashed": True,
        "unreadableCount": sum(1 for r in records if r.get("readable") is False),
        "shardMaxLines": SHARD_MAX,
        "shardCount": len(shards),
        "oversizeShards": [s for s in shards if s["records"] > SHARD_MAX],
        "shards": shards})

    write_json(inv / "categories.json", {
        "note": "Byte volumes are UNCOMPRESSED sizes from the MPQ block table - "
                "what a full raw extraction writes to disk. `class` is a "
                "reporting rollup; byTopLevelDir and byExtension are the raw "
                "measurements it is derived from.",
        "totalUncompressedBytes": total_bytes,
        "totalUncompressedGB": round(total_bytes / 1e9, 3),
        # GitHub refuses a push whose pack exceeds 2 GB, so "would a full raw
        # extraction fit in a repository" is the decision this whole layer
        # exists to inform. Stating the answer and the overrun is the point of
        # measuring the bytes at all; without them the reader has to know the
        # limit and do the subtraction.
        "exceedsTwoGB": total_bytes > 2_000_000_000,
        "twoGBBudgetOverrunBytes": max(0, total_bytes - 2_000_000_000),
        "byClass": by_class, "byTopLevelDir": by_top, "byExtension": by_ext,
        "dbcTableCount": len(dbc_records),
        "dbcUncompressedBytes": by_class.get("dbc", {}).get("bytes", 0)})

    write_json(inv / "unlistable.json", {
        "note": "Archives with no readable (listfile). Each is characterized by "
                "block-table census plus a hash-table probe of EVERY path name "
                "harvested from the listable archives. `unidentifiedLiveEntries`"
                " is the honest residual: live files no harvested name matched.",
        "unlistableArchives": [{k: v for k, v in a.items() if k != "sha256"}
                               for a in arch_records if not a["listable"]],
        "probe": probe,
        "totalUnidentifiedLiveEntries": sum(
            f.get("unidentifiedLiveEntries", 0) for f in probe.values())})

    write_json(inv / "dbc.json", {
        "note": "Every DBFilesClient table in the winning chain, with its WDBC "
                "header measured from the winning bytes. actualFields = "
                "recordSize//4; a disagreement with declaredFields is a lying "
                "header, recorded not swallowed.",
        "tableCount": len(dbc_records),
        "headerMismatches": sorted(
            r["path"].rsplit("/", 1)[-1] for r in dbc_records
            if "dbc" in r
            and r["dbc"]["actualFields"] != r["dbc"]["declaredFields"]),
        "nonWdbcMagic": sorted(
            f'{r["path"].rsplit("/", 1)[-1]}={r["dbc"]["magic"]}'
            for r in dbc_records
            if "dbc" in r and r["dbc"]["magic"] != "WDBC"),
        "tables": [{"table": r["path"].rsplit("/", 1)[-1],
                    "winner": r["winner"], "size": r["size"],
                    "sha256": r.get("sha256"), "losers": r.get("losers", []),
                    **(r.get("dbc") or {})}
                   for r in sorted(dbc_records,
                                   key=lambda x: x["path"].lower())]})

    _inventory_readme(inv, records, arch_records, by_class, probe, shards,
                      total_bytes, overrides)
    layerstate.finish(inv, {
        "layer": "raw/_inventory", "generatedBy": "python datamine.py",
        "archiveCount": len(arch_records), "recordCount": len(records),
        "dbcTableCount": len(dbc_records), "shardCount": len(shards),
        "looseOverrideCount": len(overrides), "contentHashed": True})
    return {"paths": len(records), "archives": len(arch_records),
            "dbcTables": len(dbc_records), "shards": len(shards),
            "GB": round(total_bytes / 1e9, 2)}


def _flag_names(flags: int) -> list:
    from tools.mpq import (MPQ_FILE_COMPRESS, MPQ_FILE_ENCRYPTED,
                           MPQ_FILE_IMPLODE, MPQ_FILE_SECTOR_CRC,
                           MPQ_FILE_SINGLE_UNIT)
    names = []
    for bit, name in ((MPQ_FILE_IMPLODE, "IMPLODE"),
                      (MPQ_FILE_COMPRESS, "COMPRESS"),
                      (MPQ_FILE_ENCRYPTED, "ENCRYPTED"),
                      (MPQ_FILE_SINGLE_UNIT, "SINGLE_UNIT"),
                      (MPQ_FILE_SECTOR_CRC, "SECTOR_CRC")):
        if flags & bit:
            names.append(name)
    return names


def _inventory_readme(inv: Path, records, arch_records, by_class, probe,
                      shards, total_bytes, overrides) -> None:
    gb = total_bytes / 1e9
    ur_class, ur_reason = {}, {}
    for r in records:
        if r.get("readable") is not False:
            continue
        ur_class[r["class"]] = ur_class.get(r["class"], 0) + 1
        kind = r.get("memberStatus") or "error"
        detail = (r.get("readError") or "").split(":", 1)[-1].strip()
        ur_reason[f"{kind}: {detail[:80]}"] = \
            ur_reason.get(f"{kind}: {detail[:80]}", 0) + 1
    L = ["# Client inventory (generated)\n",
         "Regenerate: `python datamine.py`. Every file here is written from the "
         "snapshot in `work/snapshot/`; nothing in it is hand-authored, and "
         "nothing in the client is filtered out of it.\n",
         "## Start here\n",
         "| file | what it answers |", "| --- | --- |",
         "| `archives.json` | every MPQ, its chain rank, whether it lists, its "
         "sha256 |",
         "| `dbc.json` | every DBFilesClient table + its measured WDBC header |",
         "| `categories.json` | how many bytes a full raw extraction costs, by "
         "class / directory / extension |",
         "| `unlistable.json` | the archives with no readable `(listfile)` |",
         "| `files.json` | index of the per-path shards in `files/` |",
         "| `files/*.json` | one compact record per line: path, winning "
         "archive, size, sha256, flags |\n",
         "## Totals\n",
         f"- **{len(records):,} paths**",
         f"- **{sum(1 for r in records if r['class'] == 'dbc')} DBC tables**",
         f"- **{len(arch_records)} archives** "
         f"({sum(1 for a in arch_records if not a['listable'])} unlistable), "
         f"{sum(a['archiveBytes'] for a in arch_records) / 1e9:.1f} GB on disk",
         f"- **{gb:.2f} GB** uncompressed if everything is extracted",
         f"- unreadable files: {sum(ur_class.values()):,}",
         f"- files in unlistable archives that no harvested name identified: "
         f"**{sum(f.get('unidentifiedLiveEntries', 0) for f in probe.values())}**",
         f"- paths a loose file at the client root takes from the archives: "
         f"**{len(overrides)}**\n",
         "## Loose files at the client root beat the whole MPQ chain\n",
         LOOSE_OVERRIDE_RULE + "\n",
         "## What is not readable, and whether it matters\n",
         "| unreadable by class | count |", "| --- | ---: |"]
    for k, v in sorted(ur_class.items(), key=lambda kv: -kv[1]):
        L.append(f"| {k} | {v:,} |")
    L.append("")
    L.append("| reason | count |")
    L.append("| --- | ---: |")
    for k, v in sorted(ur_reason.items(), key=lambda kv: -kv[1]):
        L.append(f"| {k} | {v:,} |")
    L.append("")
    L.append("## Extraction cost by class\n")
    L.append("| class | files | GB |")
    L.append("| --- | ---: | ---: |")
    for k, v in sorted(by_class.items(), key=lambda kv: -kv[1]["bytes"]):
        L.append(f"| {k} | {v['files']:,} | {v['bytes'] / 1e9:.3f} |")
    L.append(f"| **total** | **{len(records):,}** | **{gb:.3f}** |\n")
    L.append(f"Shards in `files/` are keyed by a character prefix of the path "
             f"(capped at {SHARD_MAX:,} records; {len(shards)} shards). A "
             f"path's shard is a pure function of that path, so shard contents "
             f"do not churn when the client patches.\n")
    write_bytes_lf(inv / "README.md", "\n".join(L))


# ==========================================================================
# raw/tables  (winners + every variant)
# ==========================================================================
def build_contexts(scans: list) -> list:
    """CONTEXT_RULE, as code. Reads only each archive's layer and realm, both of
    which discovery derives from where the file sits on disk."""
    base = {s["id"] for s in scans if s["layer"] != "realm"}
    realms = sorted({s["realm"] for s in scans
                     if s["layer"] == "realm" and s["realm"]})
    out = [{"context": BASE_CONTEXT, "archives": base}]
    for r in realms:
        out.append({"context": f"realm:{r}",
                    "archives": base | {s["id"] for s in scans
                                        if s["realm"] == r}})
    return out


def emit_tables(h, out: Path, t0: float) -> dict:
    """Decode every table the client ships - the chain winner AND every distinct
    non-winning version - from bytes the traversal already staged.

    A path can be carried by several archives and the chain picks one. The other
    copies are not history: this client's realm directory sits above the whole
    base chain, so for a path the overlay carries, the chain winner is the
    OVERLAY's table and the table a character outside that realm reads is a
    different file. Both are decoded, by the same decoder, under the same
    rules."""
    tdir = out / "tables"
    tdir.mkdir(parents=True, exist_ok=True)
    contexts = build_contexts(h.archives)
    rank_of = {s["id"]: i for i, s in enumerate(h.archives)}
    meta = {s["id"]: s for s in h.archives}

    records, failures = [], []
    indexes = {}
    n = 0
    for low in sorted(h.copies):
        c = h.copies[low]
        stem = c["stored"].rsplit("\\", 1)[-1]
        stem = stem[:-4] if stem.lower().endswith(".dbc") else stem
        if stem.lower() in dbcdecode.RESERVED_NAMES:
            failures.append({"table": c["stored"].rsplit("\\", 1)[-1],
                             "stage": "decode",
                             "reason": "name is reserved by the filesystem"})
            continue
        have = [(cp["archive"], h.table_bytes[(low, cp["archive"])])
                for cp in c["copies"] if (low, cp["archive"]) in h.table_bytes]
        for cp in c["copies"]:
            if (low, cp["archive"]) in h.table_bytes:
                continue
            # In the ARCHIVE's own terms. Lumping these together reports MPQ
            # semantics as damage: a DELETE_MARKER is a patch REMOVING the
            # path, which is not a failed read at all.
            miss = h.table_misses.get((low, cp["archive"]), {})
            failures.append({"table": c["stored"].rsplit("\\", 1)[-1],
                             "path": c["stored"], "archive": cp["archive"],
                             "stage": "read",
                             "status": miss.get("status", "error"),
                             "reason": miss.get("reason",
                                                "copy could not be read")})
        if not have:
            continue
        have.sort(key=lambda x: rank_of[x[0]])
        winner_aid, winner_facts = have[-1]

        by_sha = {}
        for aid, facts in have:
            by_sha.setdefault(facts["sha256"], []).append(aid)
        selected = {}
        for ctx in contexts:
            inside = [aid for aid, _ in have if aid in ctx["archives"]]
            if inside:
                top = max(inside, key=lambda a: rank_of[a])
                sha = next(f["sha256"] for a, f in have if a == top)
                selected.setdefault(sha, []).append(ctx["context"])

        versions = []
        for sha, aids in by_sha.items():
            aids = sorted(aids, key=lambda a: rank_of[a])
            rep = aids[-1]
            facts = next(f for a, f in have if a == rep)
            ctxs = sorted(selected.get(sha, []))
            versions.append({
                "slug": slug(rep), "archive": rep, "chainRank": rank_of[rep],
                "layer": meta[rep]["layer"], "realm": meta[rep]["realm"],
                "sha256": sha, "rows": facts.get("records", 0),
                "columns": (facts.get("actualFields", 0)
                            + facts.get("trailingBytesPerRecord", 0)),
                "recordSize": facts.get("recordSize"),
                "stringBlockSize": facts.get("stringBlockSize"),
                "sourceBytes": facts.get("bytes", 0),
                "chainWinner": sha == winner_facts["sha256"],
                "appliesTo": ctxs,
                "appliesToNote": (
                    f"selected by chain context(s): {', '.join(ctxs)}" if ctxs
                    else f"shadowed: {rep} carries these bytes but is outranked "
                         f"in every chain context, so no client selects them"),
                "alsoIn": aids[:-1], "_file": facts["file"]})
        versions.sort(key=lambda v: (-v["chainRank"], v["sha256"]))
        wrows = next(v["rows"] for v in versions if v["chainWinner"])
        for v in versions:
            v["rowDelta"] = v["rows"] - wrows
            v["path"] = (f"raw/tables/{stem}/" if v["chainWinner"]
                         else f"raw/tables/{stem}/{VARIANT_SUBDIR}/{v['slug']}/")

        for v in versions:
            dest = (tdir / stem if v["chainWinner"]
                    else tdir / stem / VARIANT_SUBDIR / v["slug"])
            source = {"winner": v["archive"], "losers": v["alsoIn"],
                      "sha256": v["sha256"], "bytes": v["sourceBytes"]}
            try:
                ix = dbcdecode.decode_table(
                    c["stored"].rsplit("\\", 1)[-1], source, dest,
                    v["_file"].read_bytes())
            except Exception as e:                    # noqa: BLE001 - recorded
                failures.append({"table": c["stored"].rsplit("\\", 1)[-1],
                                 "archive": v["archive"], "stage": "decode",
                                 "reason": f"{type(e).__name__}: {e}"})
                v["_index"] = None
                continue
            v["_index"] = ix
            if v["chainWinner"]:
                indexes[stem] = ix
        records.append({"table": stem,
                        "file": c["stored"].rsplit("\\", 1)[-1],
                        "clientPath": c["stored"].replace("\\", "/"),
                        "copyCount": len(c["copies"]),
                        "readableCopyCount": len(have),
                        "versionCount": len(versions),
                        "carriedBy": [cp["archive"] for cp in c["copies"]],
                        "versions": versions})
        n += 1
        if n % 40 == 0:
            print(f"  decoded {n}/{len(h.copies)} tables "
                  f"[{time.time() - t0:7.1f}s]", flush=True)

    layer = _write_table_indexes(tdir, records, indexes, contexts, rank_of,
                                 failures)
    layerstate.finish(tdir, {
        "layer": "raw/tables", "generatedBy": "python datamine.py",
        "tableCount": layer["tableCount"], "totalRows": layer["totalRows"],
        "totalShards": layer["totalShards"],
        "failureCount": layer["failureCount"], "partial": False,
        "variantTableCount": layer["tablesWithVariants"],
        "variantCount": layer["variantCount"],
        "variantRowCount": layer["variantRows"]})
    return {"tables": layer["tableCount"], "rows": layer["totalRows"],
            "shards": layer["totalShards"], "variants": layer["variantCount"],
            "failures": layer["failureCount"]}


def _version_record(v: dict) -> dict:
    rec = {k: v[k] for k in ("slug", "archive", "chainRank", "layer", "realm",
                             "sha256", "rows", "columns", "sourceBytes",
                             "chainWinner", "appliesTo", "appliesToNote",
                             "alsoIn", "rowDelta", "path")}
    ix = v.get("_index")
    if ix is not None:
        rec.update({"decodedRows": ix["rows"], "shards": ix["shardCount"],
                    "storedBytes": ix["storedBytes"], "format": ix["format"]})
    return rec


def _write_table_indexes(tdir: Path, records, indexes, contexts, rank_of,
                         failures) -> dict:
    contested, multi = [], []
    added_rows = added_stored = 0
    rows = stored = plain = shard_count = 0
    str_bytes = str_orphan = 0
    kinds, formats = Counter(), Counter()
    table_rows = []

    for r in records:
        stem = r["table"]
        ipath = tdir / stem / "index.json"
        if not ipath.is_file():
            continue
        index = json.loads(ipath.read_bytes().decode("utf-8"))
        vrows = [_version_record(v) for v in r["versions"]]
        for v in r["versions"]:
            if not v["chainWinner"] and v.get("_index"):
                added_rows += v["_index"]["rows"]
                added_stored += v["_index"]["storedBytes"]
        index.update({"variantCount": len(vrows), "variantRule": VARIANT_RULE,
                      "contextRule": CONTEXT_RULE, "variants": vrows})
        write_bytes_lf(ipath, sharding.dump_manifest(index))

        if len(vrows) > 1:
            vdir = tdir / stem / VARIANT_SUBDIR
            vdir.mkdir(parents=True, exist_ok=True)
            write_bytes_lf(vdir / "index.json", sharding.dump_manifest({
                "note": "Every distinct version of this table in the client. "
                        "The chain winner is decoded one directory up; every "
                        "other version is decoded in the subdirectory named by "
                        "its `slug`, by the same decoder under the same rules.",
                "table": stem, "file": r["file"], "variantRule": VARIANT_RULE,
                "contextRule": CONTEXT_RULE, "copyCount": r["copyCount"],
                "versionCount": r["versionCount"],
                "carriedBy": r["carriedBy"], "variants": vrows}))
            multi.append(r)

        sel = {}
        for v in r["versions"]:
            for ctx in v["appliesTo"]:
                sel[ctx] = v
        base = sel.get(BASE_CONTEXT)
        others = {k: v for k, v in sel.items() if k != BASE_CONTEXT}
        if base and any(v["sha256"] != base["sha256"] for v in others.values()):
            win = next(v for v in r["versions"] if v["chainWinner"])
            contested.append({
                "table": stem, "baseContext": BASE_CONTEXT,
                "baseArchive": base["archive"], "baseSha256": base["sha256"],
                "baseRows": base["rows"], "basePath": base["path"],
                "overlayContexts": sorted(others),
                "overlayArchive": sorted({v["archive"] for v in others.values()}),
                "overlayRows": sorted({v["rows"] for v in others.values()}),
                "chainWinnerArchive": win["archive"],
                "chainWinnerRows": win["rows"],
                "rowDeltaBaseMinusWinner": base["rows"] - win["rows"]})

        ix = indexes.get(stem)
        if ix is None:
            continue
        rows += ix["rows"]
        stored += ix["storedBytes"]
        plain += ix["plainBytes"]
        shard_count += ix["shardCount"]
        kinds.update(ix["inferredCounts"])
        formats[ix["format"]] += 1
        str_bytes += ix["stringBlockSize"]
        str_orphan += ix["unreferencedStringBytes"]
        win = next(v for v in r["versions"] if v["chainWinner"])
        table_rows.append({
            "table": stem, "file": ix["file"], "rows": ix["rows"],
            "columns": ix["columns"], "shards": ix["shardCount"],
            "storedBytes": ix["storedBytes"], "plainBytes": ix["plainBytes"],
            "format": ix["format"],
            "shardKey": ix["shardKey"]["column"] or ix["shardKey"]["mode"],
            "oversizeShards": len(ix["oversizeShards"]),
            "winner": win["archive"]})

    write_bytes_lf(tdir / "_failures.json", sharding.dump_manifest({
        "note": "Every table the client names is either decoded or listed here "
                "with its reason. An empty list means zero silent drops.",
        "statusRule": (
            "`status` is the reader's classification of the member, so a copy "
            "that is not a table is reported as what the archive says it is. "
            "`deleted` is an MPQ DELETE_MARKER tombstone - the patch REMOVES "
            "the path, which is archive semantics and NOT a read failure, and "
            "every one is enumerated in raw/recovered/deleted/. `empty` is a "
            "real entry holding zero bytes. Only `error` is a read that "
            "actually failed."),
        "count": len(failures),
        "byStatus": dict(sorted(Counter(f.get("status", "error")
                                        for f in failures).items())),
        "failures": sorted(failures,
                           key=lambda f: (f["table"], f["stage"]))}))

    total_versions = sum(r["versionCount"] for r in records)
    variants = {
        "note": "Every table the client ships in more than one version, and "
                "which chain context selects each. Tables absent from this list "
                "have exactly one version, already decoded at raw/tables/<T>/. "
                "Read `contextRule` before reading `appliesTo`: a version is not "
                "'the' table, it is the table SOME client configuration reads.",
        "generatedBy": "python datamine.py",
        "variantRule": VARIANT_RULE, "contextRule": CONTEXT_RULE,
        "clientDir": str(config.CLIENT_DIR),
        "contexts": [{"context": c["context"],
                      "archives": sorted(c["archives"],
                                         key=lambda a: rank_of[a])}
                     for c in contexts],
        "carrierArchives": sorted({a for r in records for a in r["carriedBy"]},
                                  key=lambda a: rank_of[a]),
        "pathCount": len(records),
        "copyCount": sum(r["copyCount"] for r in records),
        "versionCount": total_versions,
        "tablesWithOneVersion": len(records) - len(multi),
        "tablesWithVariants": len(multi),
        "variantsBeyondWinner": total_versions - len(records),
        "variantRowsDecoded": added_rows, "variantStoredBytes": added_stored,
        "realmContestedCount": len(contested),
        "realmContested": sorted(contested, key=lambda r: r["table"].lower()),
        "failureCount": len(failures),
        "failures": sorted(failures, key=lambda f: (f.get("table", ""),
                                                    f.get("archive", ""))),
        "tables": [{"table": r["table"], "file": r["file"],
                    "copyCount": r["copyCount"],
                    "versionCount": r["versionCount"],
                    "carriedBy": r["carriedBy"],
                    "variants": [_version_record(v) for v in r["versions"]]}
                   for r in sorted(multi, key=lambda r: r["table"].lower())]}
    write_bytes_lf(tdir / "_variants.json", sharding.dump_manifest(variants))

    catalog = {
        "note": "Every table in the client, decoded to positional columns "
                "f0..fN. Start here: each record points at raw/tables/<table>/, "
                "which holds index.json (shard map), <table>.colinfo.json "
                "(per-column measurement + inferred type) and the shards "
                "themselves. See README.md for the rules.",
        "tableCount": len(table_rows), "censusTableCount": len(records),
        "failureCount": len(failures), "totalRows": rows,
        "totalShards": shard_count, "plainBytes": plain, "storedBytes": stored,
        "stringBlockBytes": str_bytes, "unreferencedStringBytes": str_orphan,
        "inferredColumnCounts": dict(sorted(kinds.items())),
        "tablesByFormat": dict(sorted(formats.items())),
        "shardRule": dbcdecode.SHARD_RULE,
        "compressionRule": dbcdecode.COMPRESSION_RULE,
        "inferenceRule": dbcdecode.INFERENCE_RULE,
        "variantIndex": "_variants.json", "variantRule": VARIANT_RULE,
        "tablesWithVariants": variants["tablesWithVariants"],
        # Two numbers, one for each question a reader actually has, because ONE
        # of them was reported alone and got read as the other. `variantCount`
        # is versions BEYOND the chain winner - what `variants/` subdirectories
        # hold. `decodedVersionTotal` is every decoded copy of every table,
        # winners included, and is the number that answers "how many distinct
        # tables were decoded out of this client". They differ by exactly the
        # 368 chain winners, and the arithmetic is spelled out rather than left
        # to be rediscovered.
        "variantCount": variants["variantsBeyondWinner"],
        "decodedVersionTotal": variants["versionCount"],
        "versionCountRule": (
            f"{variants['versionCount']} decoded versions = "
            f"{len(records)} chain winners (one per table path) + "
            f"{variants['variantsBeyondWinner']} further versions under "
            f"variants/. {variants['tablesWithVariants']} table paths ship in "
            f"more than one version; {len(records) - len(multi)} ship in "
            f"exactly one."),
        "variantRows": variants["variantRowsDecoded"],
        "variantStoredBytes": variants["variantStoredBytes"],
        "realmContestedTables": [r["table"] for r in variants["realmContested"]],
        "tables": table_rows}
    write_bytes_lf(tdir / "index.json", sharding.dump_manifest(catalog))
    _tables_readme(tdir, catalog, variants, failures)
    return catalog


def _tables_readme(tdir: Path, cat: dict, var: dict, failures: list) -> None:
    L = ["# Raw client tables (generated)\n",
         "Regenerate: `python datamine.py`. Every byte under this directory is "
         "decoded from the snapshot in `work/snapshot/`. Nothing is "
         "hand-authored, no table is treated specially, and no table is left "
         "out.\n",
         "## Totals\n",
         f"- **{cat['tableCount']} tables** decoded of "
         f"{cat['censusTableCount']} table paths in the client",
         f"- **{cat['failureCount']} failures** (`_failures.json`)",
         f"- **{cat['totalRows']:,} rows** in {cat['totalShards']:,} shards",
         f"- **{cat['storedBytes'] / 1e6:.1f} MB** on disk "
         f"({cat['plainBytes'] / 1e6:.1f} MB uncompressed)",
         f"- **{cat['stringBlockBytes']:,} string-block bytes**: "
         f"{cat['stringBlockBytes'] - cat['unreferencedStringBytes']:,} reached "
         f"by a decoded record, {cat['unreferencedStringBytes']:,} referenced "
         f"by no column and written out verbatim to `<Table>.strings.json`",
         f"- **{var['versionCount']} versions** of those tables: "
         f"{var['tablesWithVariants']} paths are shipped in more than one "
         f"version by the chain, and all {var['variantsBeyondWinner']} extra "
         f"versions are decoded too ({var['variantRowsDecoded']:,} further "
         f"rows, {var['variantStoredBytes'] / 1e6:.1f} MB)\n",
         "## Layout\n", "```",
         "raw/tables/index.json          every table: rows, columns, shards, bytes",
         "raw/tables/_failures.json      anything not decoded, and why",
         "raw/tables/_variants.json      every table shipped in more than one version",
         "raw/tables/<Table>/index.json  shard map + `variants`: every version",
         "raw/tables/<Table>/<Table>.colinfo.json",
         "                               per column: measurement + inferred type",
         "raw/tables/<Table>/<lo>-<hi>.jsonl[.gz]",
         "                               one record per line: {\"f0\":..,\"f1\":..}",
         "raw/tables/<Table>/variants/<archive-slug>/",
         "                               a NON-winning version, same rules",
         "```\n", "## Versions\n", CONTEXT_RULE + "\n", VARIANT_RULE + "\n",
         f"`_variants.json` lists all {var['tablesWithVariants']} of them. "
         f"{var['realmContestedCount']} are contested between the base chain "
         f"and a realm overlay - the ones where reading the chain winner means "
         f"reading another realm's table:\n",
         "| table | base rows | base archive | overlay rows | overlay archive |",
         "| --- | ---: | --- | ---: | --- |"]
    for r in var["realmContested"]:
        L.append(f"| {r['table']} | {r['baseRows']:,} | {r['baseArchive']} | "
                 f"{', '.join(f'{n:,}' for n in r['overlayRows'])} | "
                 f"{', '.join(r['overlayArchive'])} |")
    L.append("")
    L.append("## Reading a record\n")
    L.append("Keys are positional. `f5` is the value of column 5 under the type "
             "the measurement implies; `f5i` is the raw int when `f5` was "
             "decoded as a string; `f5s` is the decoded string when `f5` was "
             "decoded as an int and the column is nonetheless a valid "
             "string-offset column. Nothing is lost either way, and a float is "
             "emitted exactly, so its four bytes are recoverable from it.\n")
    L.append("## How a type is decided\n")
    L.append(cat["inferenceRule"] + "\n")
    L.append("| inferred | columns |")
    L.append("| --- | ---: |")
    for k, v in sorted(cat["inferredColumnCounts"].items(),
                       key=lambda kv: -kv[1]):
        L.append(f"| {k} | {v:,} |")
    L.append("")
    L.append("## Sharding\n")
    L.append(cat["shardRule"] + "\n")
    L.append("## Compression\n")
    L.append(cat["compressionRule"] + "\n")
    L.append("## Largest tables\n")
    L.append("| table | rows | columns | shards | MB stored |")
    L.append("| --- | ---: | ---: | ---: | ---: |")
    for r in sorted(cat["tables"], key=lambda r: -r["rows"])[:15]:
        L.append(f"| {r['table']} | {r['rows']:,} | {r['columns']} | "
                 f"{r['shards']} | {r['storedBytes'] / 1e6:.1f} |")
    L.append("")
    if failures:
        L.append("## Failures\n")
        L.append("| table | stage | reason |")
        L.append("| --- | --- | --- |")
        for f in sorted(failures, key=lambda f: f.get("table", "")):
            L.append(f"| {f.get('table')} | {f.get('stage')} | "
                     f"{f.get('reason')} |")
        L.append("")
    write_bytes_lf(tdir / "README.md", "\n".join(L) + "\n")


# ==========================================================================
# raw/content
# ==========================================================================
def emit_content(snapshot_dir: Path, out: Path) -> dict:
    """`Data\\Content`: Ascension's own JSON payloads, copied verbatim, plus the
    undocumented `.loc` binary localization store, decoded by tools/loc.py -
    which accepts a decode only if it consumes the file exactly.

    Walks the WHOLE tree and records EVERY file, including extensions nobody
    anticipated and files of zero length. A file with no decoder is written to
    the index with `decoded: false`, never omitted."""
    cdir = out / "content"
    src = snapshot_dir / "Data" / "Content"
    cdir.mkdir(parents=True, exist_ok=True)
    if not src.is_dir():
        raise SystemExit(f"FATAL: {src} is not in the snapshot")

    entries, groups, failures = [], {}, []
    for p in sorted(x for x in src.rglob("*") if x.is_file()):
        parts = p.relative_to(src).parts
        data = p.read_bytes()
        rec = {"path": "/".join(parts), "bytes": len(data),
               "sha256": hashlib.sha256(data).hexdigest()}
        if p.suffix.lower() == ".loc":
            entity = "/".join(parts[1:-1])
            locale = parts[-1].rsplit(".", 1)[0]
            try:
                rows = loc.read(data)
            except loc.LocError as e:
                rec.update({"kind": "loc", "decoded": False, "error": str(e),
                            "evidence": e.evidence})
                failures.append(rec)
                entries.append(rec)
                continue
            texts = [{"id": rid, "text": t} for rid, t in rows]
            frag = rawshard.write_group(cdir / "localization" / entity / locale,
                                        texts, lambda r: r["id"])
            rec.update({"kind": "loc", "decoded": True, "records": len(texts),
                        "entity": entity, "locale": locale,
                        "nonEmpty": sum(1 for t in texts if t["text"]),
                        "dir": f"localization/{entity}/{locale}",
                        "shardCount": frag["shardCount"],
                        "format": frag["format"],
                        "storedBytes": frag["storedBytes"]})
            groups[f"{entity}/{locale}"] = {
                "entity": entity, "locale": locale, "source": "/".join(parts),
                "keyField": "id", "textField": "text", "records": len(texts),
                "sourceBytes": len(data), **frag}
        elif p.suffix.lower() == ".json" and len(parts) == 1:
            (cdir / parts[-1]).write_bytes(data)      # verbatim, byte for byte
            rec.update({"kind": "json", "decoded": True,
                        "copiedTo": parts[-1]})
        else:
            rec.update({"kind": "unhandled", "decoded": False,
                        "error": "no decoder for this extension/location; "
                                 "bytes are on the client and hashed here"})
            failures.append(rec)
        entries.append(rec)

    locs = [e for e in entries if e["kind"] == "loc"]
    index = {
        "note": "Every file under Data\\Content, decoded or not. `localization` "
                "shards live under localization/<Entity>/<Field>/<locale>/.",
        "clientDir": str(config.CLIENT_DIR), "fileCount": len(entries),
        "jsonCount": sum(1 for e in entries if e["kind"] == "json"),
        "locCount": len(locs),
        "unhandledCount": sum(1 for e in entries if e["kind"] == "unhandled"),
        "failureCount": len(failures),
        "locRecordTotal": sum(e.get("records", 0) for e in locs),
        "sourceBytes": sum(e["bytes"] for e in entries),
        "locFormat": loc.FORMAT, "locValidation": loc.VALIDATION,
        "shardRule": rawshard.SHARD_RULE,
        "compressionRule": rawshard.COMPRESSION_RULE,
        "files": entries,
        "localizationGroups": [groups[k] for k in sorted(groups)],
        "failures": failures}
    write_json(cdir / "index.json", index)
    write_bytes_lf(cdir / "README.md", f"""# Loose client content (generated)

Regenerate: `python datamine.py`. Extracted from the snapshot of
`Data\\Content`. Nothing here is hand-authored and nothing in that tree is
filtered out of it.

## Totals

- **{index['fileCount']} files** in the client tree ({index['sourceBytes'] / 1e6:.1f} MB)
- **{index['jsonCount']} JSON payloads**, copied verbatim, byte for byte
- **{index['locCount']} `.loc` localization files**, {index['locRecordTotal']:,} records decoded
- **{index['failureCount']} failures** (`index.json` -> `failures`)

## The `.loc` format

Undocumented in the client and nowhere else. Decoded, not guessed:

```
{index['locFormat']}
```

{index['locValidation']}

## Sharding and compression

{index['shardRule']}

{index['compressionRule']}
""")
    layerstate.finish(cdir, {
        "layer": "raw/content", "generatedBy": "python datamine.py",
        "fileCount": index["fileCount"], "locCount": index["locCount"],
        "locRecordTotal": index["locRecordTotal"],
        "failureCount": index["failureCount"]})
    return {"files": index["fileCount"], "loc": index["locCount"],
            "locRecords": index["locRecordTotal"]}


# ==========================================================================
# raw/interface + raw/interface_all
# ==========================================================================
CODE_EXTS = {".lua", ".xml", ".toc", ".txt", ".md"}


def override_map(manifest: dict) -> dict:
    """{lowercased backslash path -> snapshot-relative file} for every loose
    client-root file that BEATS the MPQ chain. Computed once and handed to every
    layer that reports a winner, so the census and the Interface layer cannot
    disagree about which bytes the client actually loads."""
    return {rel.lower().replace("/", "\\"): rel
            for rel, f in manifest["files"].items()
            if f["kind"] == "rootOverride"}


def emit_interface(h, snapshot_dir: Path, work: Path, out: Path,
                   overrides: dict, boundary: dict) -> dict:
    """Two layers off one set of harvested bytes.

    `raw/interface/` is the CODE layer - the .lua/.xml/.toc/.txt/.md the client
    actually runs, as bytes, mirroring the client's Interface\\ tree. On top of
    the archive copies goes the launcher-managed `AddOns/APIDocumentation` tree
    from disk, which WINS any collision: it is Ascension's own live description
    of their real API surface, not a stale archive snapshot.

    `raw/interface_all/` is the CENSUS - every Interface path, code or art, with
    its winner, size, sha256 and a measured text/binary verdict. Bytes are
    committed for text and not for art; see SIZE_RULE."""
    idir = out / "interface"
    adir = out / "interface_all"
    paths_dir = adir / "paths"
    idir.mkdir(parents=True, exist_ok=True)
    paths_dir.mkdir(parents=True, exist_ok=True)
    staged = work / "interface"

    files_meta = {}
    archive_sourced = 0
    out_records = []
    stats = Counter()

    for low in sorted(h.interface):
        c = h.carriers[low]
        e = c["e"]
        info = h.interface[low]
        rel = e["stored"][len("Interface\\"):] if len(e["stored"]) > 10 \
            else e["stored"]
        rec = {"path": e["stored"].replace("\\", "/"), "winner": c["winner"],
               "size": e["size"], "storedBytes": e["storedBytes"],
               "sha256": e.get("sha256"), "flags": _flag_names(e["flags"]),
               "readable": True, "isText": info["isText"],
               "encoding": info["encoding"], "hasNul": info["hasNul"],
               "controlBytes": info["controlBytes"]}
        if c["losers"]:
            rec["losers"] = sorted(set(c["losers"]))

        # A loose file at the client root beats the whole chain, so for those
        # paths the bytes the client LOADS are on disk and the archive copy is
        # not what this layer should describe. Reporting the archive copy here
        # while the census reports the disk copy would put the two layers into
        # silent disagreement about the same path.
        disk_rel = overrides.get(low)
        if disk_rel is not None:
            data = (snapshot_dir / disk_rel).read_bytes()
            cls = classify_text(data)
            info = {"isText": cls["isText"], "encoding": cls["encoding"],
                    "hasNul": cls["hasNul"], "controlBytes": cls["controlBytes"]}
            rec.update({"source": "loose", "diskPath": disk_rel,
                        "winner": DISK_WINNER, "size": len(data),
                        "storedBytes": None, "flags": [],
                        "sha256": hashlib.sha256(data).hexdigest(),
                        "overrides": {"winner": c["winner"],
                                      "size": e["size"],
                                      "sha256": e.get("sha256")},
                        "isText": info["isText"],
                        "encoding": info["encoding"],
                        "hasNul": info["hasNul"],
                        "controlBytes": info["controlBytes"]})
        if not info["isText"]:
            rec["bytesAt"] = None
            stats["binary"] += 1
            out_records.append(rec)
            continue
        stats["text"] += 1
        data = (snapshot_dir / disk_rel).read_bytes() if disk_rel is not None \
            else info["staged"].read_bytes()
        ext = "." + rel.rsplit(".", 1)[-1].lower() if "." in rel else ""
        if ext in CODE_EXTS:
            dest = idir.joinpath(*rel.replace("\\", "/").split("/"))
            dest.parent.mkdir(parents=True, exist_ok=True)
            dest.write_bytes(data)
            files_meta[rel.replace("/", os.sep)] = {
                "source": c["winner"].rsplit("/", 1)[-1], "size": len(data),
                "sha256": hashlib.sha256(data).hexdigest()}
            archive_sourced += 1
            rec["bytesAt"] = "raw/interface/" + rel.replace("\\", "/")
            stats["inCodeLayer"] += 1
        else:
            dest = adir / "text" / rel.replace("\\", "/")
            dest.parent.mkdir(parents=True, exist_ok=True)
            dest.write_bytes(data)
            rec["bytesAt"] = "raw/interface_all/text/" + rel.replace("\\", "/")
            stats["committed"] += 1
            stats["committedBytes"] += len(data)
        out_records.append(rec)

    # unreadable Interface paths still get a census row
    for low, c in h.carriers.items():
        if not low.startswith("interface\\") or low in h.interface:
            continue
        e = c["e"]
        out_records.append({
            "path": e["stored"].replace("\\", "/"), "winner": c["winner"],
            "size": e["size"], "storedBytes": e["storedBytes"],
            "sha256": e.get("sha256"), "flags": _flag_names(e["flags"]),
            "readable": False, "readError": e.get("readError"),
            "isText": None, "bytesAt": None})
        stats["unreadable"] += 1

    # The launcher-managed APIDocumentation tree - Ascension's own description
    # of their real API surface - taken from the SNAPSHOT, not from the live
    # client. It wins any collision with an archive copy at the same path,
    # deliberately: the archive copy is a stale snapshot of the same thing.
    disk = 0
    apidoc = snapshot_dir / "Interface" / "AddOns" / "APIDocumentation"
    if apidoc.is_dir():
        iroot = snapshot_dir / "Interface"
        for p in sorted(apidoc.rglob("*")):
            if not p.is_file() or p.suffix.lower() not in CODE_EXTS:
                continue
            rel = str(p.relative_to(iroot))
            data = p.read_bytes()
            dest = idir.joinpath(*rel.replace("\\", "/").split("/"))
            dest.parent.mkdir(parents=True, exist_ok=True)
            dest.write_bytes(data)
            files_meta[rel] = {"source": "disk", "size": len(data),
                               "sha256": hashlib.sha256(data).hexdigest()}
            disk += 1

    write_bytes_lf(idir / "_manifest.json", json.dumps(
        {"count": len(files_meta), "archiveSourced": archive_sourced,
         "diskSourced": disk,
         "files": {k: files_meta[k] for k in sorted(files_meta)}},
        ensure_ascii=False, indent=1, sort_keys=True))
    layerstate.finish(idir, {
        "layer": "raw/interface", "generatedBy": "python datamine.py",
        "count": len(files_meta), "archiveSourced": archive_sourced,
        "diskSourced": disk})

    # ---- the census shards ----
    by_path = {r["path"].replace("/", "\\").lower(): r for r in out_records}
    groups = partition(list(by_path))
    names = shard_names(groups)
    shards = []
    for key in sorted(groups):
        rows = [by_path[p] for p in sorted(groups[key])]
        fn = names[key][:-len(".json")] + ".jsonl"
        write_bytes_lf(paths_dir / fn, "".join(
            json.dumps(r, ensure_ascii=False, sort_keys=True,
                       separators=(",", ":")) + "\n" for r in rows))
        shards.append({"file": fn, "prefix": key[0].replace("\\", "/"),
                       "kind": key[1], "records": len(rows),
                       "firstPath": rows[0]["path"],
                       "lastPath": rows[-1]["path"],
                       "sha256": hashlib.sha256(
                           (paths_dir / fn).read_bytes()).hexdigest()})

    ext = {}
    for r in out_records:
        base = r["path"].rsplit("/", 1)[-1]
        e2 = base.rsplit(".", 1)[-1].lower() if "." in base else "_noext"
        d = ext.setdefault(e2, {"files": 0, "bytes": 0, "text": 0,
                                "unreadable": 0})
        d["files"] += 1
        d["bytes"] += r["size"]
        d["text"] += 1 if r.get("isText") else 0
        d["unreadable"] += 0 if r.get("readable", True) else 1

    index = {
        "note": "Every path under Interface\\ in the client MPQ chain. Per-path "
                "records are in paths/*.jsonl, one compact record per line, "
                "sharded by path prefix. `bytesAt` says where the committed "
                "bytes live, or is null when only the hash is kept.",
        "pathCount": len(out_records),
        "totalBytes": sum(r["size"] for r in out_records),
        "textCount": stats["text"], "binaryCount": stats["binary"],
        "unreadableCount": stats["unreadable"],
        "bytesInCodeLayer": stats["inCodeLayer"],
        "bytesCommittedHere": stats["committed"],
        "bytesCommittedHereBytes": stats["committedBytes"],
        "textRule": TEXT_RULE, "sizeRule": SIZE_RULE,
        "shardMaxRecords": SHARD_MAX, "shardCount": len(shards),
        "byExtension": {k: ext[k] for k in sorted(ext)},
        "looseOverrideRule": LOOSE_OVERRIDE_RULE,
        "looseOverrides": sorted(r["path"] for r in out_records
                                 if r.get("source") == "loose"),
        "installStateBoundary": boundary,
        "shards": shards}
    write_json(adir / "index.json", index)
    write_bytes_lf(adir / "README.md", f"""# Complete Interface census (generated)

Regenerate: `python datamine.py`.

## Totals

- **{index['pathCount']:,} Interface paths** ({index['totalBytes'] / 1e9:.3f} GB uncompressed in the client)
- **{index['textCount']:,} measured text**, {index['binaryCount']:,} measured binary, {index['unreadableCount']} unreadable
- bytes committed: {index['bytesInCodeLayer']:,} in `raw/interface/`, {index['bytesCommittedHere']:,} added here

## What decides text vs binary

{TEXT_RULE}

## Why binary bytes are not committed

{SIZE_RULE}
""")
    layerstate.finish(adir, {
        "layer": "raw/interface_all", "generatedBy": "python datamine.py",
        "pathCount": index["pathCount"], "textCount": index["textCount"],
        "binaryCount": index["binaryCount"],
        "unreadableCount": index["unreadableCount"]})
    return {"code": len(files_meta), "paths": len(out_records),
            "text": stats["text"], "binary": stats["binary"]}


# ==========================================================================
# raw/cache
# ==========================================================================
RAW_EMBED_MAX = 1 << 16


def emit_cache(snapshot_dir: Path, out: Path) -> dict:
    """`Cache\\WDB` - the SERVER's own answers, cached verbatim by the client.

    Item.dbc carries no stats at all, so itemcache.wdb is the only client-side
    source of item stats, damage, sockets and item level. And they are PER
    REALM: a realm subdirectory is not a copy of the base cache, it is what that
    realm served, so the two are never merged."""
    kdir = out / "cache"
    src = snapshot_dir / "Cache" / "WDB"
    kdir.mkdir(parents=True, exist_ok=True)
    if not src.is_dir():
        return {"files": 0, "records": 0}

    entries, failures = [], []
    for p in sorted(x for x in src.rglob("*") if x.is_file()):
        parts = p.relative_to(src).parts
        data = p.read_bytes()
        group = "/".join(slug(x) for x in parts[:-1]) or "root"
        name = slug(parts[-1].rsplit(".", 1)[0])
        rec = {"path": "/".join(parts), "group": group, "name": parts[-1],
               "bytes": len(data),
               "sha256": hashlib.sha256(data).hexdigest()}
        head = wdb.sniff(data)
        rec["header"] = head
        rows, tier, extra = None, None, {}
        if head.get("hasWdbHeader"):
            magic = head["magic"]
            try:
                res = wdb.decode_blocks(data, magic)
            except wdb.WdbError as e:
                res = {"decoded": False, "records": [], "fields": [],
                       "failure": {"reason": f"{type(e).__name__}: {e}"}}
            if res["decoded"]:
                rows, tier = res["records"], "schema"
                extra = {"fields": res["fields"], "fieldsAreMeasured": True,
                         "interpretationAt": "_interpretation.json#" + magic,
                         "schemaSource": wdb.SCHEMA_SOURCE.get(magic)}
            else:
                extra = {"schemaFailure": res["failure"],
                         "schemaSource": wdb.SCHEMA_SOURCE.get(magic)}
                try:
                    rows, tier = wdb.dump_blocks(data), "blocks"
                except wdb.WdbError as e:
                    extra["blockWalkFailure"] = f"{type(e).__name__}: {e}"
        else:
            flat = wdb.sniff_flat(data)
            rec["flat"] = {k: v for k, v in flat.items() if k != "records"}
            if flat["decoded"]:
                rows, tier = flat["records"], "flat"
                extra = {"columns": flat["columns"],
                         "columnTypes": flat["columnTypes"],
                         "recordSize": flat["recordSize"]}
        if rows is None:
            tier = "raw"
            if len(data) <= RAW_EMBED_MAX:
                extra["bytesBase64"] = base64.b64encode(data).decode("ascii")
                extra["bytesCommitted"] = True
            else:
                extra["bytesCommitted"] = False
                extra["note"] = ("no decoder matched and the file exceeds "
                                 f"{RAW_EMBED_MAX} bytes, so only its hash is "
                                 f"here")
            failures.append({"path": rec["path"], "tier": tier, **extra})
        else:
            key = "_entry" if tier in ("schema", "blocks") else "f0"
            frag = rawshard.write_group(
                kdir / group / name, rows,
                lambda r, k=key: int(r.get(k, 0)) & 0xFFFFFFFF)
            extra["keyField"] = key
            extra.update({"dir": f"{group}/{name}",
                          "shardCount": frag["shardCount"],
                          "format": frag["format"],
                          "storedBytes": frag["storedBytes"]})
            rec["records"] = len(rows)
        rec["tier"] = tier
        rec.update(extra)
        entries.append(rec)

    groups = {}
    for e in entries:
        g = groups.setdefault(e["group"], {"files": 0, "records": 0,
                                           "bytes": 0})
        g["files"] += 1
        g["records"] += e.get("records", 0)
        g["bytes"] += e["bytes"]

    index = {
        "note": "Every file under Cache\\WDB. Decoded records live in "
                "<group>/<name>/<lo>-<hi>.jsonl[.gz], one record per line, "
                "keyed by the block entry id (`_entry`) for WDB caches and by "
                "f0 for the flat Ascension caches. Columns are POSITIONAL "
                "(f0..fN) in every tier: the layout is measured, the field "
                "names are not, so the names live in _interpretation.json and "
                "never in the data. <group> keeps each realm's cache separate "
                "from the base one - they are different data.",
        "clientCacheDir": str(config.CLIENT_DIR / "Cache" / "WDB"),
        "fileCount": len(entries),
        "recordTotal": sum(e.get("records", 0) for e in entries),
        "sourceBytes": sum(e["bytes"] for e in entries),
        "tierCounts": {t: sum(1 for e in entries if e["tier"] == t)
                       for t in ("schema", "blocks", "flat", "raw")},
        "groups": {k: groups[k] for k in sorted(groups)},
        "validationRule": wdb.VALIDATION_RULE,
        "interpretationRule": wdb.INTERPRETATION_RULE,
        "flatRule": wdb.FLAT_RULE, "shardRule": rawshard.SHARD_RULE,
        "compressionRule": rawshard.COMPRESSION_RULE,
        "schemaSources": wdb.SCHEMA_SOURCE, "files": entries,
        "failures": failures}
    write_json(kdir / "index.json", index)
    write_json(kdir / "_interpretation.json", wdb.interpretation_index())
    write_bytes_lf(kdir / "README.md", f"""# Client query caches (generated)

Regenerate: `python datamine.py`. Extracted from the snapshot of `Cache\\WDB`.

This is the ONE layer whose source is not static client files, so it is also the
one that reproduces byte for byte only against the same `Cache\\WDB` tree:
playing the game appends to that cache. Everywhere else "unchanged client" means
"unchanged archives"; here it means "unchanged cache too".

## Totals

- **{index['fileCount']} files**, {index['sourceBytes'] / 1e6:.1f} MB
- **{index['recordTotal']:,} records** decoded
- tiers: {json.dumps(index['tierCounts'])}

## How a field layout earns the right to be used

{index['validationRule']}

## The field names, and why they are not in the data

{index['interpretationRule']}
""")
    layerstate.finish(kdir, {
        "layer": "raw/cache", "generatedBy": "python datamine.py",
        "fileCount": index["fileCount"], "recordTotal": index["recordTotal"],
        "tierCounts": index["tierCounts"]})
    return {"files": index["fileCount"], "records": index["recordTotal"]}


# ==========================================================================
# raw/recovered
# ==========================================================================
def emit_recovered(h, out: Path) -> dict:
    """What the archives say about themselves, and what is not ordinary content:
    the per-member CRC32/MD5/mtime oracle, the patch tombstones, the genuinely
    empty members, and the nested containers.

    This layer used to be six checkpointed stages that between them re-opened
    every archive several times. All of it is now a by-product of the single
    traversal: the MD5 verification happened as each member was decompressed,
    and the tombstones came off the block tables that were already in memory."""
    rdir = out / "recovered"
    rdir.mkdir(parents=True, exist_ok=True)

    # ---- the MD5/CRC32/mtime oracle, per member, not just per archive ----
    # The summary alone would throw away the thing that makes this layer worth
    # having: an independent integrity record for every single member, which is
    # what any future claim about the client's bytes gets checked against.
    from tools import mpq as _mpq
    attr_rows, total, dated, unnamed = [], 0, 0, 0
    by_archive = {s["id"]: s for s in h.archives}
    for aid in sorted(h.attributes):
        a = h.attributes[aid]
        if not a.get("present") or not a.get("entries"):
            attr_rows.append({"archive": aid, "entries": 0,
                              "note": a.get("error") or "no (attributes) member"})
            continue
        s = by_archive[aid]
        names = {e["block"]: e["stored"].replace("\\", "/")
                 for e in s["entries"].values()}
        crcs, times, md5s = a.get("crc32"), a.get("filetime"), a.get("md5")
        rows = []
        # CLIPPED TO THE BLOCK TABLE. The array is parallel to it, so a
        # subscript past its end names no member - and some of this client's
        # archives do carry a longer `(attributes)` member than their block
        # table (1,004 entries in total). Emitting those would be emitting rows
        # about files that do not exist.
        n_rows = min(a["entries"], s.get("blockTableEntries") or a["entries"])
        for i in range(n_rows):
            rec = {"block": i, "path": names.get(i)}
            if rec["path"] is None:
                unnamed += 1
            if crcs is not None and i < len(crcs):
                rec["crc32"] = crcs[i]
            if md5s is not None and i < len(md5s):
                rec["md5"] = md5s[i].hex()
            if times is not None and i < len(times) and times[i]:
                rec["mtime"] = _mpq.filetime_to_iso(times[i])
                dated += 1
            rows.append(rec)
        total += len(rows)
        frag = rawshard.write_group(rdir / "attributes" / slug(aid), rows,
                                    lambda r: r["block"])
        attr_rows.append({
            "archive": aid, "entries": a["entries"], "rows": n_rows,
            "blockTableEntries": s.get("blockTableEntries"),
            "matchesBlockTable": a.get("matchesBlockTable"),
            "hasCrc32": crcs is not None, "hasFiletime": times is not None,
            "hasMd5": md5s is not None, "dir": slug(aid),
            "shardCount": frag["shardCount"], "format": frag["format"],
            "storedBytes": frag["storedBytes"]})
    write_json(rdir / "attributes" / "index.json", {
        "note": "The per-member CRC32 + Windows FILETIME + MD5 each archive "
                "records about itself, in an array PARALLEL TO ITS BLOCK TABLE - "
                "so the subscript is the member's own block index, which is why "
                "a row can be present for a block no listfile names (`path` "
                "null). This is the oracle every read in this run was checked "
                "against, and it is not another reader: it is the archive's own "
                "claim about its own bytes.",
        "md5Rule": MD5_RULE, "keyField": "block",
        "archiveCount": len(attr_rows), "recordTotal": total,
        "recordsDated": dated, "rowsUnnamed": unnamed,
        "shardRule": rawshard.SHARD_RULE,
        "compressionRule": rawshard.COMPRESSION_RULE,
        "archives": attr_rows})

    tomb = sorted(h.tombstones, key=lambda r: (r["archive"], r.get("block", 0)))
    write_json(rdir / "deleted" / "index.json", {
        "note": "MPQ DELETE_MARKER entries: paths a patch layer REMOVES.",
        "tombstoneRule": TOMBSTONE_RULE, "count": len(tomb),
        "byArchive": dict(sorted(Counter(r["archive"] for r in tomb).items())),
        "entries": tomb})

    empt = sorted(h.empties, key=lambda r: (r["archive"], r.get("block", 0)))
    write_json(rdir / "empty" / "index.json", {
        "note": "Members the archive records as zero bytes: real entries that "
                "hold nothing. Distinct from a tombstone, which carries no "
                "bytes by design, and from a failed read.",
        "count": len(empt), "entries": empt})

    # ---- nested containers, EXPANDED, not merely detected ----
    # "There is a RAR in here" is not an extraction. Each container is opened
    # one level down (and recursively while its members are containers too) and
    # its index written, so what the client actually ships inside them is on the
    # record rather than behind a magic number.
    from tools import container as ctn
    cdir = rdir / "containers"
    ctn.OUT_DIR = cdir            # so `committedAt` is expressed layer-relative
    ctn.WORK_DIR = config.WORK_DIR / "containers"
    # One entry per DISTINCT sha256, the same rule the table and binary layers
    # use. Four of this client's containers are shipped byte-identically in both
    # base-enUS.MPQ and backup-enUS.MPQ; expanding each twice would double the
    # layer and report one file as two.
    by_sha = {}
    for c in sorted(h.containers, key=lambda c: (c["archive"], c["path"])):
        by_sha.setdefault(c["sha256"], []).append(c)
    expanded, members = [], 0
    for digest in sorted(by_sha):
        group = by_sha[digest]
        c = group[0]
        rec = dict(c)
        if len(group) > 1:
            rec["alsoIn"] = [{"archive": g["archive"], "path": g["path"]}
                             for g in group[1:]]
        dest = cdir / slug(c["archive"]) / slug(c["path"])
        try:
            data = Path(c["_staged"]).read_bytes()
            if c["kind"] in ("rar", "rar4"):
                res = ctn._expand_rar(data)
            elif c["kind"] == "rar5":
                res = ctn._expand_rar5(data)[0]
            elif c["kind"] == "bplist":
                res = ctn._expand_bplist(data)
            elif c["kind"] == "mpq":
                res = ctn._expand_nested_mpq(data, c["path"], dest)
            else:
                res = {"expanded": False,
                       "reason": f"no expander for {c['kind']!r}"}
        except Exception as e:                        # noqa: BLE001 - recorded
            res = {"expanded": False,
                   "reason": f"{type(e).__name__}: {e}"}
        rec.pop("_staged", None)
        rec.update(res)
        n = len(res.get("members") or ())
        members += n
        if res.get("members"):
            write_json(dest / "index.json",
                       {"note": "One nested container, expanded.",
                        "container": c["path"], "archive": c["archive"],
                        "kind": c["kind"], "memberCount": n,
                        "members": res["members"]})
            rec["dir"] = f"{slug(c['archive'])}/{slug(c['path'])}"
        expanded.append(rec)
    write_json(cdir / "index.json", {
        "note": "Members whose own bytes are an archive - detected by MAGIC, "
                "not by extension, so a nested container under any name is "
                "found and a file merely NAMED .rar is not mis-parsed.",
        "containerRule": ctn.CONTAINER_RULE,
        "count": len(expanded), "memberTotal": members,
        "byKind": dict(sorted(Counter(c["kind"] for c in expanded).items())),
        "containers": expanded})

    # ---- byte-coverage forensics, per archive ----------------------------
    # Dropped when the pipeline collapsed and restored here. It is a measurement
    # of the ARCHIVES, not of the retired reader or the retired stage chain:
    # what the block tables account for, what they do not, and whether anything
    # survives behind a delete-marked hash slot. All of it comes off tables the
    # single traversal already had in memory, so it costs no second read.
    frows = [h.forensics[k] for k in sorted(h.forensics)]
    unaccounted = sum(r["unaccountedBytes"] for r in frows)
    orphans = sum(r["orphanBlockEntryCount"] for r in frows)
    encrypted = [m for r in frows for m in r["encryptedMembers"]]
    archive_bytes = sum(r["fileBytes"] for r in frows)
    delete_marked = sum(r["hashSlotsDeleteMarked"] for r in frows)
    write_json(rdir / "_forensics.json", {
        "note": "Every archive walked against its own bytes: what its block "
                "table accounts for, what nothing points at, and what its "
                "encrypted members turn out to be.",
        "rule": COVERAGE_RULE,
        "archiveCount": len(frows), "archiveBytesTotal": archive_bytes,
        "unaccountedBytesTotal": unaccounted,
        "orphanBlockEntriesTotal": orphans,
        "hashSlotsDeleteMarkedTotal": delete_marked,
        "blockEntriesDeleteMarkerTotal": sum(
            r["blockEntriesDeleteMarker"] for r in frows),
        "encryptedMemberCount": len(encrypted),
        "encryptedMembersRecovered": sum(1 for m in encrypted
                                         if m["withName"] == "ok"),
        "encryptedMembersRecoveredWithoutTheName": sum(
            1 for m in encrypted if m["withoutName"] == "ok"),
        "verdict": (
            f"{unaccounted:,} bytes of the client's {archive_bytes:,} are "
            f"unaccounted for by a live block entry, and {orphans:,} block "
            f"entries are unreferenced by any live hash slot. Delete-marked "
            f"hash slots ({delete_marked:,} of them) therefore have no "
            f"surviving file data behind them: the archives were COMPACTED, "
            f"not merely re-indexed. This is a byte-accounted result, not an "
            f"inference from the format."),
        "archives": frows})

    # ---- what the reader actually did, per compression method -------------
    # The compression census and the two defect-class counts are measurements of
    # the ARCHIVES too. They went missing with the mpyq agreement sample, which
    # genuinely is moot now - these are not: they say which methods this
    # client's sectors are stored with, and how the two member classes that
    # silently broke the old reader behaved under this one.
    dsum = Counter()
    per_archive = {}
    for aid in sorted(h.defects):
        per_archive[aid] = h.defects[aid]
        for cls, facts in h.defects[aid].items():
            for k, v in facts.items():
                dsum[f"{cls}.{k}"] += v
    write_json(rdir / "_verify.json", {
        "note": "Every member the traversal decompressed, checked against the "
                "MD5 its own archive records for it - plus what it took to "
                "decompress them and how the two historically mis-read member "
                "classes behaved.",
        "md5Rule": MD5_RULE, "checked": h.md5["checked"], "ok": h.md5["ok"],
        "mismatched": h.md5["mismatch"], "noRecordInArchive": h.md5["noRecord"],
        "mismatches": h.md5["mismatches"],
        "compressionCensusNote":
            "One count per SECTOR expanded, naming the method tools/mpq.py "
            "used for it, over every member the traversal read - not a sample. "
            "`stored(...)` entries are sectors that were not compressed at all; "
            "a `sectorSize N override` entry is a member whose declared sector "
            "size did not hold and was re-derived.",
        "compressionCensus": dict(sorted(h.compression.items())),
        "defectClassRule": DEFECT_CLASS_RULE,
        "noSectorTableMembers": dsum["noSectorTable.members"],
        "noSectorTableReadOk": dsum["noSectorTable.readOk"],
        "noSectorTableReadFailed": dsum["noSectorTable.readFailed"],
        "noSectorTableNotNamedByListfile":
            dsum["noSectorTable.notNamedByListfile"],
        "exactSectorMultipleMembers": dsum["exactSectorMultiple.members"],
        "exactSectorMultipleReadOk": dsum["exactSectorMultiple.readOk"],
        "exactSectorMultipleReadFailed": dsum["exactSectorMultiple.readFailed"],
        "exactSectorMultipleNotNamedByListfile":
            dsum["exactSectorMultiple.notNamedByListfile"],
        "defectClassesByArchive": per_archive})

    write_json(rdir / "index.json", {
        "note": "What was not ordinary content, and what the archives say about "
                "themselves.",
        "attributeArchives": len(attr_rows), "attributeRecords": total,
        "deleteTombstones": len(tomb), "emptyMembers": len(empt),
        # the DISTINCT containers, matching containers/index.json. Counting
        # carriers here and distinct containers there would have this layer
        # disagreeing with itself about the same fact.
        "containers": len(expanded), "containerCarriers": len(h.containers),
        "containerMembers": members,
        "md5Verified": h.md5["ok"], "md5Mismatched": h.md5["mismatch"],
        "unaccountedBytes": unaccounted, "orphanBlockEntries": orphans,
        "encryptedMembers": len(encrypted),
        "encryptedMembersRecovered": sum(1 for m in encrypted
                                         if m["withName"] == "ok"),
        "readErrors": dict(sorted(h.read_errors.items()))})
    write_bytes_lf(rdir / "README.md", f"""# Recovered / archive forensics (generated)

Regenerate: `python datamine.py`.

- `attributes/` - the CRC32 + MD5 + mtime each archive records per member. The
  oracle everything else is checked against.
- `deleted/` - **{len(tomb):,}** patch tombstones: paths a patch layer REMOVES.
- `empty/` - **{len(empt)}** genuinely zero-length members.
- `containers/` - **{len(h.containers)}** members whose bytes are themselves an archive.
- `_forensics.json` - every archive walked against its own bytes: **{unaccounted:,}**
  bytes unaccounted for by a live block entry, **{orphans:,}** orphan block entries,
  **{len(encrypted)}** encrypted member(s).
- `_verify.json` - **{h.md5['ok']:,}** members verified against their archive's own MD5,
  **{h.md5['mismatch']}** mismatched, plus the per-sector compression census.

## The tombstone rule

{TOMBSTONE_RULE}

## The MD5 rule

{MD5_RULE}

## What the byte accounting proves

{COVERAGE_RULE}
""")
    layerstate.finish(rdir, {
        "layer": "raw/recovered", "generatedBy": "python datamine.py",
        "deleteTombstones": len(tomb), "emptyMembers": len(empt),
        "attributeRecords": total, "containers": len(expanded),
        "containerMembers": members, "md5Verified": h.md5["ok"],
        "md5Mismatched": h.md5["mismatch"],
        "unaccountedBytes": unaccounted, "orphanBlockEntries": orphans})
    return {"tombstones": len(tomb), "empty": len(empt),
            "containers": len(expanded), "containerMembers": members,
            "md5ok": h.md5["ok"], "md5bad": h.md5["mismatch"],
            "unaccountedBytes": unaccounted, "orphanBlocks": orphans}


# ==========================================================================
# raw/binaries
# ==========================================================================
def emit_binaries(h, snapshot_dir: Path, work: Path, out: Path) -> dict:
    """The client's own executables: every printable string, the inlined Lua and
    the full PE structure - for the images in the client root AND the ones
    stored INSIDE the archives, which the traversal found by reading the bytes
    of every member rather than by trusting an extension.

    This is the layer that explains where `listarchive`, `SetDataPath` and the
    realm hot-swap script actually live, none of which is in any shipped data
    file."""
    from tools import pe, peextract as eb

    bdir = out / "binaries"
    bdir.mkdir(parents=True, exist_ok=True)
    eb.OUT_ROOT = bdir            # so each summary's `dir` is repo-relative
    summaries, archived = [], []

    # the client-root images, straight out of the snapshot
    for p in sorted(snapshot_dir.iterdir()):
        if not p.is_file():
            continue
        data = p.read_bytes()
        if data[:2] != b"MZ" or not pe.is_pe(data):
            continue
        s = eb.extract_bytes(data, p.name, bdir / p.name, verbose=False)
        s["sha256"] = hashlib.sha256(data).hexdigest()
        s["bytes"] = len(data)
        summaries.append(s)

    rank_of = {s["id"]: i for i, s in enumerate(h.archives)}
    by_root_sha = {s["sha256"]: s for s in summaries}
    adir = bdir / "_archived"
    for digest in sorted(h.pe_members):
        v = h.pe_members[digest]
        carriers = sorted(v["carriers"], key=lambda c: rank_of.get(c["archive"], 0))
        top = carriers[-1]
        # One extraction per DISTINCT sha256, across BOTH sources. An archived
        # image whose bytes are byte-identical to a client-root image is the
        # same image; extracting it twice would duplicate its whole strings/
        # lua/resources tree on disk and double-count it in every total. It is
        # recorded against the root binary instead, so nothing is lost.
        root = by_root_sha.get(digest)
        if root is not None:
            root.setdefault("alsoInArchives", []).extend(
                {"archive": c["archive"], "path": c["path"]} for c in carriers)
            continue
        name = top["path"].rsplit("/", 1)[-1]
        data = v["file"].read_bytes()
        # `origin` goes IN to the extraction so the per-image index.json records
        # where the bytes came from too. Patching it onto the returned summary
        # afterwards would leave the file on disk not saying it.
        origin = {"archive": top["archive"], "clientPath": top["path"],
                  "alsoIn": [{"archive": c["archive"], "path": c["path"]}
                             for c in carriers[:-1]]}
        # QUALIFIED BY ITS ARCHIVE, never by name alone. `WowError.exe` in
        # base-enUS.MPQ and `WowError.exe` in backup-enUS.MPQ are DIFFERENT
        # images, and a name-only directory silently overwrites one with the
        # other - 20 distinct images collapsing into 13 directories, with the
        # index still claiming 20.
        dest = adir / slug(top["archive"]) / eb._slug(name)
        summary = eb.extract_bytes(data, name, dest, verbose=False,
                                   origin=origin)
        summary.update(origin)
        archived.append(summary)

    # One directory per image, CHECKED rather than assumed - this is the exact
    # failure the archive-qualified path above exists to prevent. An index
    # claiming more images than there are trees on disk is a silent loss.
    dirs = {s["dir"] for s in archived}
    if len(dirs) != len(archived):
        raise SystemExit(
            f"FATAL: {len(archived)} archived PE images collapsed into "
            f"{len(dirs)} directories - one would overwrite another.")

    # Layer-wide rollups and the THRESHOLDS behind them. The rollups are sums
    # over the per-image records and could be re-derived by a reader; the
    # thresholds could not - they are decisions this layer made about what
    # counts as Lua and what counts as a string, and dropping them left the
    # counts un-interpretable. Both were lost in the collapse; both are back.
    every = summaries + archived
    index = {
        "note": "Every PE image in the client: the ones loose in the client "
                "root, and the ones stored INSIDE the MPQ archives (under "
                "_archived/), found by reading the bytes of every member.",
        "stringRule": eb.STRING_RULE, "resourceRule": eb.RESOURCE_RULE,
        "luaRule": eb.LUA_RULE,
        "minRunLength": eb.MIN_RUN,
        "luaMinScore": eb.LUA_MIN_SCORE,
        "luaFragmentMinScore": eb.LUA_FRAGMENT_MIN_SCORE,
        "clientRootBinaryCount": len(summaries),
        "archivedBinaryCount": len(archived),
        "binaryCount": len(summaries) + len(archived),
        "stringTotal": sum(s.get("strings", 0) for s in every),
        "luaChunkTotal": sum(s.get("luaSourceChunks", 0) for s in every),
        "luaFragmentTotal": sum(s.get("luaFragments", 0) for s in every),
        "resourceTotal": sum(s.get("resourceCount", 0) for s in every),
        "symbolTotal": sum(s.get("symbols", 0) for s in every),
        "binaries": summaries, "archived": archived}
    write_json(bdir / "index.json", index)
    write_bytes_lf(bdir / "README.md", f"""# Client binaries (generated)

Regenerate: `python datamine.py`.

- **{len(summaries)}** PE images loose in the client root
- **{len(archived)}** PE images stored inside the MPQ archives (`_archived/`)
- **{index['stringTotal']:,}** printable strings extracted

## How strings are selected

{eb.STRING_RULE}
""")
    layerstate.finish(bdir, {
        "layer": "binaries", "generatedBy": "python datamine.py",
        "binaryCount": index["binaryCount"],
        "clientRootBinaryCount": len(summaries),
        "archivedBinaryCount": len(archived),
        "stringTotal": index["stringTotal"]})
    return {"images": index["binaryCount"], "strings": index["stringTotal"]}


# ==========================================================================
# publish
# ==========================================================================
def publish(staging: Path, raw: Path, layers: dict) -> None:
    """Swap the staged layers over `raw/`, one layer at a time.

    Staging is what makes a failed run harmless: every layer is written
    somewhere else entirely and nothing under `raw/` is touched until the whole
    run has succeeded. A directory rename over an existing directory is not one
    operation on Windows, so each layer is moved aside and deleted after its
    replacement is in place - the window in which a layer is missing is short,
    and a layer that is missing is obviously missing, which is the failure mode
    to prefer over one that is silently half-written."""
    raw.mkdir(parents=True, exist_ok=True)
    for d in sorted(staging.iterdir()):
        if not d.is_dir():
            continue
        dest = raw / d.name
        old = raw / f".{d.name}.old"
        if old.exists():
            shutil.rmtree(old)
        if dest.exists():
            os.replace(dest, old)
        shutil.move(str(d), str(dest))
        if old.exists():
            shutil.rmtree(old)
        print(f"  published raw/{d.name}", flush=True)
    # Staged files that do NOT belong under raw/. CATALOG.md is the repo's
    # front door and lives at the root; it is staged with the layer it describes
    # so the two are published together, never one generation apart.
    #
    # There is deliberately no second copy under raw/. The repo carried one, and
    # because this mapping sends the staged file to the root the raw/ copy was
    # never rewritten: two runs later it still had the mtime of the run that
    # created it, byte-identical only by luck, and would have started lying at
    # the next client patch. A generated file with no generator is worse than no
    # file. If a raw/-local copy is ever wanted, add it HERE so it is published
    # with everything else.
    root_files = {"CATALOG.md": config.REPO_ROOT / "CATALOG.md"}
    for f in sorted(staging.iterdir()):
        if not f.is_file():
            continue
        dest = root_files.get(f.name, raw / f.name)
        dest.parent.mkdir(parents=True, exist_ok=True)
        os.replace(str(f), str(dest))
        print(f"  published {dest.relative_to(config.REPO_ROOT)}", flush=True)
    shutil.rmtree(staging, ignore_errors=True)


# ==========================================================================
# the whole emission
# ==========================================================================
def emit_all(h, manifest: dict, probe: dict, staging: Path, work: Path,
             snapshot_dir: Path, t0: float) -> dict:
    """Every layer, from what the single traversal already holds."""
    layers = {}
    overrides = override_map(manifest)

    print("\n-- raw/_inventory", flush=True)
    layers["raw/_inventory"] = emit_inventory(h, manifest, probe, staging)

    print("-- raw/tables", flush=True)
    layers["raw/tables"] = emit_tables(h, staging, t0)

    print("-- raw/content", flush=True)
    layers["raw/content"] = emit_content(snapshot_dir, staging)

    print("-- raw/interface + raw/interface_all", flush=True)
    layers["raw/interface"] = emit_interface(
        h, snapshot_dir, work, staging, overrides,
        manifest.get("installStateBoundary") or {})

    print("-- raw/cache", flush=True)
    layers["raw/cache"] = emit_cache(snapshot_dir, staging)

    print("-- raw/recovered", flush=True)
    layers["raw/recovered"] = emit_recovered(h, staging)

    print("-- raw/binaries", flush=True)
    layers["raw/binaries"] = emit_binaries(h, snapshot_dir, work, staging)

    # Everything above is done with the harvest; the catalog is pure analysis
    # over the table layer on disk. Freeing ~2 GB here is not a micro-
    # optimisation - see Harvest.release() for the corruption it prevents.
    h.release()
    gc.collect()

    print("-- raw/_catalog + CATALOG.md", flush=True)
    layers["raw/_catalog"] = emit_catalog(staging)

    emit_root_readme(staging, layers, manifest)
    return layers


def emit_catalog(staging: Path) -> dict:
    """The searchable catalog over the table layer: which column joins to which
    id space, and which columns carry text. This is what `tools/find.py` reads.

    Built LAST and from the STAGED table layer, never from the published one, so
    the catalog can never describe a previous generation of the data - the exact
    failure the old five-command procedure could produce, because its
    regeneration notes did not mention the catalog at all."""
    from tools import build_catalog
    res = build_catalog.run(verbose=True, tables_dir=staging / "tables",
                            catalog_dir=staging / "_catalog",
                            catalog_md=staging / "CATALOG.md")
    return {"columns": res["tables"]["columnCount"],
            "joinCandidates": res["joins"]["candidateCount"],
            "stringColumns": res["strings"]["columnCount"]}


def emit_root_readme(staging: Path, layers: dict, manifest: dict) -> None:
    """`raw/README.md` - the index an agent opens first. Generated from the
    layers that are actually on disk, never from a list of layers that were
    expected to be there."""
    rows = []
    for name, index_name, what in (
            ("_inventory", "README.md", "complete census of every file in the client"),
            ("tables", "index.json", "every DBC table, decoded, positional f0..fN"),
            ("content", "index.json", "loose Data\\Content: JSON payloads + .loc localization"),
            ("interface", "_manifest.json", "Interface code layer (.lua/.xml/.toc) as bytes"),
            ("interface_all", "index.json", "every Interface path: size, sha256, text/binary"),
            ("cache", "index.json", "Cache\\WDB server query caches, per realm"),
            ("binaries", "index.json", "the client's own executables: strings, Lua, PE structure"),
            ("recovered", "README.md", "archive forensics: MD5 oracle, tombstones, containers"),
            ("_catalog", "tables.json", "the searchable catalog: joins, strings, columns")):
        d = staging / name
        if not d.is_dir():
            continue
        files = sum(1 for p in d.rglob("*") if p.is_file())
        size = sum(p.stat().st_size for p in d.rglob("*") if p.is_file())
        rows.append(f"| `{name}` | {what} | `raw/{name}/{index_name}` | "
                    f"{files:,} files / {size / 1e6:,.1f} MB | "
                    f"{'complete' if layerstate.is_complete(d) else 'no sentinel'} |")

    snap_bytes = sum(f["bytes"] for f in manifest["files"].values())
    other = [d.name for d in sorted(config.RAW_DIR.iterdir())
             if d.is_dir() and not (staging / d.name).is_dir()] \
        if config.RAW_DIR.is_dir() else []
    write_bytes_lf(staging / "README.md", f"""# raw/ - the client, mechanically extracted (generated)

Every layer in the table below is written by ONE script, `datamine.py`, from a
snapshot of the client at `{config.CLIENT_DIR}`. Nothing in them is
hand-authored, hand-labelled or hand-selected: column names are positional,
types are inferred by measurement, and no wanted-list decides what is extracted.

`raw/` is not exclusively that script's output, and saying otherwise would be a
lie a reader could act on. {"`" + "`, `".join(other) + "`" if other else "No other directory"} and
`provenance.json` are built by `python -m tools.build_dataset` for the CURATED
`data/` tree - a wanted-list extraction through `tools/extract_mpq.py`, which
still reads archives with `mpyq`. They are a different pipeline with different
rules; nothing in the table below depends on them, and the "no wanted list"
guarantee is about the table below.

## Regenerating

```
python datamine.py
```

No arguments, no stages, no order to get right, no LLM. It snapshots the client,
walks each archive exactly once, and rebuilds every layer below.

## Start here

| layer | what it holds | open first | size | state |
| --- | --- | --- | --- | --- |
{chr(10).join(rows)}

## What this dataset was built from

`raw/_snapshot.json` records the sha256, size and mtime of every one of the
{len(manifest['files']):,} files ({snap_bytes / 1e9:.1f} GB) this run copied out of the client
before it read anything. That is this dataset's identity.

{SNAPSHOT_RULE_TEXT}

## The two rules that matter most when reading any of this

1. **A table has several VERSIONS, and the default pick is not always the one
   your question wants.** `Data\\<realm>\\` sits above every base and locale
   archive, so for some tables the chain winner in `raw/tables/<Table>/` is the
   realm overlay's data, not what a character on a realm without an overlay
   reads. Every distinct version is decoded to
   `raw/tables/<Table>/variants/<archive-slug>/` under the same rules, and
   `raw/tables/_variants.json` lists which chain context selects which.
2. **Columns are positional and types are measured.** `f5` means column 5. A
   type is what the bytes support, recorded with the counts behind it, not what
   a name suggests.

## Searching it

```
python -m tools.find "Tide Lash"        # a string, across tables + .loc + WDB caches + binaries
python -m tools.find --id 133           # every column an integer appears in
python -m tools.find --joins-to Spell   # every column that points at Spell.f0
```
""")


SNAPSHOT_RULE_TEXT = (
    "The snapshot being minutes or hours behind the live client is expected and "
    "harmless - the launcher patches the archives roughly hourly. What matters "
    "is that ONE client version goes in and ONE dataset comes out: without the "
    "snapshot a long run would read a mixture of versions and no layer could be "
    "said to describe any one of them.")
