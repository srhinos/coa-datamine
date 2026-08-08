"""Per-image PE analysis, as a pure library.

Everything here is a function of ONE PE image's bytes: its printable strings in
three encodings, the Lua it carries (source chunks, precompiled chunks and
fragments), its resource leaves, and its structural symbols. Nothing in this
module opens an archive, walks the client or decides which images to look at -
`datamine.py` found them, once, while it was reading the client anyway.

The code was MOVED here verbatim from the pipeline half of the former
`tools/extract_binaries.py`, so `raw/binaries` reproduces byte for byte.

WHAT IS EXTRACTED, AND WHY IT IS ALL OF IT
------------------------------------------
The client's executables are where `listarchive`, `SetDataPath` and the realm
hot-swap script actually live, and none of that is in any shipped data file.
Strings are taken from the WHOLE buffer - headers, sections, gaps and overlay
alike - so nothing is missed because a section table called a region
uninteresting. Resource payloads are committed when they measure as text, when
they decode to a structure, or when they are small; larger binary payloads are
recorded with size and sha256 and their bytes discarded, which is this repo's
art-and-sound rule applied by measurement rather than by type.
"""
import hashlib
import json
import re
from pathlib import Path

from tools import layerstate, lua51, pe, rawshard

# Where a summary's `dir` is expressed relative to. Set by the caller before the
# first extraction so the recorded path is `_archived/foo.exe` rather than an
# absolute path off this machine.
OUT_ROOT = None

ARCHIVED_DIR = "_archived"

# Shortest run kept, in CHARACTERS, for all three encodings. 4 is the classic
# `strings` default and is low enough that four-letter identifiers ("Lua",
# "spec", table names) survive; the count at every length is a function of this
# number alone, so it is recorded in the index rather than left in the code.
MIN_RUN = 4

# A run is Lua source if it spans at least two lines and matches at least this
# many DISTINCT syntax classes (tools/lua51.TOKEN_RULE). Measured against these
# binaries: at 3 it selects the realm-hotswap chunk in Extensions.dll and the
# two compat-library chunks in Ascension.exe and nothing else, while
# WowError.exe and discord_game_sdk.dll - which contain no Lua - select nothing.
LUA_MIN_SCORE = 3
# Single-line fragments use the same threshold. The score is on every string
# record regardless, so this only decides what the convenience list holds.
LUA_FRAGMENT_MIN_SCORE = 3

# Resource bytes are committed when they are text, when they decode to a
# structure, or when they are small. Anything larger is recorded (size +
# sha256) and its bytes discarded - the same recorded-not-committed rule this
# repo applies to art and sound, applied by MEASUREMENT rather than by type.
COMMIT_MAX_BYTES = 64 * 1024
_TEXT_SAMPLE = 8192

# Resource types the PE specification defines as images or fonts. Listed so the
# index can say WHY a payload was not committed, never to decide whether to read
# it - the size rule above does that.
ART_RESOURCE_TYPES = {1, 2, 3, 8, 12, 14, 21, 22}

# Structured resource payloads that are text in disguise and are decoded here.
RT_STRING = 6
RT_VERSION = 16

ASCII_RUN = re.compile(rb"[\x20-\x7e]{%d,}" % MIN_RUN)
UTF16_RUN = re.compile(rb"(?:[\x20-\x7e]\x00){%d,}" % MIN_RUN)
# Printable ASCII or a well-formed multi-byte UTF-8 sequence. Runs without any
# multi-byte character are dropped by the caller: they are the ASCII pass.
UTF8_RUN = re.compile(
    rb"(?:[\x20-\x7e]|[\xc2-\xdf][\x80-\xbf]|\xe0[\xa0-\xbf][\x80-\xbf]|"
    rb"[\xe1-\xec\xee\xef][\x80-\xbf]{2}|\xed[\x80-\x9f][\x80-\xbf]|"
    rb"\xf0[\x90-\xbf][\x80-\xbf]{2}|[\xf1-\xf3][\x80-\xbf]{3}|"
    rb"\xf4[\x80-\x8f][\x80-\xbf]{2}){%d,}" % MIN_RUN)

UNMAPPED = "(unmapped)"          # a file offset no section covers

STRING_RULE = (
    f"Every printable run of at least {MIN_RUN} characters in the whole file - "
    f"headers, sections, gaps and overlay alike - in three encodings: ASCII "
    f"(bytes 0x20-0x7E), UTF-16LE (printable-ASCII code units) and UTF-8 (kept "
    f"only when the run contains a multi-byte character, so it never duplicates "
    f"the ASCII pass). Runs are deduplicated by (encoding, text) and every "
    f"offset each occurs at is kept, with the PE section that offset lands in "
    f"or '{UNMAPPED}' when no section covers it. Note what the UTF-8 pass is: "
    f"machine code contains byte pairs that are well-formed UTF-8 by chance, so "
    f"most `utf8` runs are not text - they are kept because dropping them would "
    f"mean dropping every genuinely non-ASCII string with them, and `enc` "
    f"separates them from the ASCII and UTF-16 passes for anyone who wants "
    f"only text.")

RESOURCE_RULE = (
    f"Every resource leaf is read. Its bytes are committed when the payload "
    f"measures as text, when it decodes to a structure (RT_VERSION, RT_STRING), "
    f"or when it is at most {COMMIT_MAX_BYTES} bytes; larger binary payloads are "
    f"recorded with size and sha256 and their bytes discarded, which is this "
    f"repo's art-and-sound rule applied by measurement. Nothing is skipped "
    f"because of its type.")

PATH_RULE = (
    "Every `file` path an index records is relative to THAT index's own "
    "directory, so `chunks/0x00b59c00.lua` in lua/index.json is "
    "<binary>/lua/chunks/0x00b59c00.lua on disk.")

SELECTION_RULE = (
    "Every PE image in the client, wherever it sits: the ones loose in the "
    "client root AND the ones stored inside the MPQ archives. Both are found by "
    "reading bytes - no name list and no extension test decides it - and the "
    "archive sweep reads the first sector of every one of the client's ~769,000 "
    "members and keeps the ones that parse as a PE (see ARCHIVE_SCAN_RULE). The "
    "whole client tree is also swept for further .exe/.dll/.ocx/.sys files "
    "outside the root and the result is recorded in `outsideRoot`, so 'these "
    "are all of them' is a measurement rather than an assumption.")

ARCHIVE_SCAN_RULE = (
    "Every member named by every archive's listfile has its FIRST SECTOR "
    "decoded and is kept if those bytes parse as a PE image; a member starting "
    "`MZ` whose PE header lies past the first sector is re-read in full rather "
    "than judged on the short read. The sweep costs one sector per member, and "
    "it is checkpointed per archive under work/binaries/archive_scan/ keyed by "
    "the archive's own sha256 AND this rule, so changing what counts as a hit "
    "invalidates the cache instead of being masked by it.\n\n"
    "Driving this off the listfiles is complete rather than convenient, and "
    "that is a MEASUREMENT, not an assumption: the client's 77 archives hold "
    "768,998 block entries, 4,911 of them DELETE_MARKER tombstones that carry "
    "no bytes, and every one of the 764,087 remaining live entries resolves to "
    "a name - 0 live members are unnamed. Seven archives ship no readable "
    "listfile (patch-4, -5, -C, -CZZ, -W, -WB, -WC), and they are stubs: two "
    "block entries each, which are their own `(listfile)` and `(attributes)` "
    "members and nothing else, so there is no unnamed payload hiding behind "
    "them. tools/crack.py's forensics stage records the same decomposition from "
    "the other direction (orphanBlockEntriesTotal 0, unaccountedBytesTotal 0).")

ARCHIVE_VERSION_RULE = (
    "One extraction per DISTINCT sha256, not one per carrying archive - the "
    "same rule tools/variants.py applies to tables. Byte-identical copies are "
    "ONE version, extracted under the HIGHEST-ranked archive that carries those "
    "bytes with the others listed in `alsoIn`. A version whose bytes are "
    "already extracted as a loose client-root binary is not extracted twice "
    "either; it is recorded against that binary in `alsoInArchives`. Chain rank "
    "is position in tools/inventory.discover_archives(), the same loader order "
    "every other layer here uses.")


# --------------------------------------------------------------------------
# helpers
# --------------------------------------------------------------------------
def _sha(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def _sha_file(path: Path) -> str:
    """An archive's sha256, streamed. Used to key the archive PE scan, and
    MEASURED rather than read out of the census for the same reason
    tools/crack.py measures it: a stale census would silently validate a stale
    checkpoint on a client the launcher live-patches between runs."""
    digest = hashlib.sha256()
    with open(path, "rb") as handle:
        for chunk in iter(lambda: handle.read(8 * 1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def _json(path: Path, obj) -> dict:
    body = json.dumps(obj, ensure_ascii=False, indent=1, sort_keys=True,
                      default=str).encode("utf-8") + b"\n"
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(body)
    return {"file": path.name, "bytes": len(body), "sha256": _sha(body)}


def _is_text(data: bytes) -> bool:
    """Text is a sample with no NUL and almost all printable bytes - the same
    measurement tools/crack.py uses, so the two layers agree on what text is."""
    sample = data[:_TEXT_SAMPLE]
    if not sample or b"\0" in sample:
        return False
    printable = sum(1 for b in sample if 32 <= b < 127 or b in (9, 10, 13))
    return printable / len(sample) >= 0.95


def _slug(text: str) -> str:
    """A file-name-safe form of a resource name. Reversible enough to be read
    back: every character outside [A-Za-z0-9._-] becomes an underscore."""
    return re.sub(r"[^A-Za-z0-9._-]", "_", text)[:80] or "_"


# --------------------------------------------------------------------------
# strings
# --------------------------------------------------------------------------
def extract_strings(data: bytes, sections: list) -> list:
    """Every printable run in the file, deduplicated, with all of its offsets.

    One pass per encoding over the WHOLE buffer, so nothing is missed because a
    section table said a region was uninteresting."""
    found = {}
    order = {}

    def add(enc, text, off):
        key = (enc, text)
        rec = found.get(key)
        if rec is None:
            rec = found[key] = {"enc": enc, "text": text, "off": [], "sec": []}
            order[key] = off
        rec["off"].append(off)
        name = pe.section_of_offset(sections, off) or UNMAPPED
        if name not in rec["sec"]:
            rec["sec"].append(name)

    for m in ASCII_RUN.finditer(data):
        add("ascii", m.group().decode("ascii"), m.start())
    for m in UTF16_RUN.finditer(data):
        add("utf16le", m.group().decode("utf-16-le"), m.start())
    for m in UTF8_RUN.finditer(data):
        raw = m.group()
        if not any(b >= 0x80 for b in raw):
            continue                       # pure ASCII: the first pass has it
        add("utf8", raw.decode("utf-8"), m.start())

    rows = []
    for i, key in enumerate(sorted(found, key=lambda k: (order[k], k[0], k[1]))):
        rec = found[key]
        rows.append({"id": i, "enc": rec["enc"], "text": rec["text"],
                     "len": len(rec["text"]), "n": len(rec["off"]),
                     "off": rec["off"], "sec": sorted(rec["sec"]),
                     "lua": lua51.score(rec["text"])})
    return rows


# --------------------------------------------------------------------------
# lua
# --------------------------------------------------------------------------
def extract_lua(data: bytes, strings: list, out_dir: Path) -> dict:
    """Source chunks and precompiled chunks as files, plus the fragment list."""
    chunk_dir = out_dir / "chunks"
    records, files = [], []

    for blob in lua51.find_source_blobs(data, LUA_MIN_SCORE):
        name = f"{blob['offset']:#010x}.lua"
        chunk_dir.mkdir(parents=True, exist_ok=True)
        raw = data[blob["offset"]:blob["offset"] + blob["bytes"]]
        (chunk_dir / name).write_bytes(raw)
        files.append({"file": f"chunks/{name}", "bytes": len(raw),
                      "sha256": _sha(raw)})
        records.append({"kind": "sourceChunk", "off": blob["offset"],
                        "bytes": blob["bytes"], "lines": blob["lines"],
                        "score": blob["score"], "classes": blob["classes"],
                        "file": f"chunks/{name}", "sha256": _sha(raw),
                        "text": blob["text"]})

    for cand in lua51.find_chunks(data):
        if not cand["ok"]:
            records.append({"kind": "precompiledRejected", "off": cand["offset"],
                            "reason": cand["reason"], "header": cand["header"],
                            "text": ""})
            continue
        name = f"{cand['offset']:#010x}.luac"
        chunk_dir.mkdir(parents=True, exist_ok=True)
        raw = data[cand["offset"]:cand["offset"] + cand["bytes"]]
        (chunk_dir / name).write_bytes(raw)
        _json(chunk_dir / f"{cand['offset']:#010x}.structure.json", cand["chunk"])
        files.append({"file": f"chunks/{name}", "bytes": len(raw),
                      "sha256": _sha(raw)})
        top = cand["chunk"]
        records.append({"kind": "precompiled", "off": cand["offset"],
                        "bytes": cand["bytes"], "source": top.get("source"),
                        "instructions": top.get("instructionCount"),
                        "constants": len(top.get("constants", [])),
                        "protos": len(top.get("protos", [])),
                        "file": f"chunks/{name}", "sha256": _sha(raw),
                        "text": ""})

    for s in strings:
        if s["lua"] >= LUA_FRAGMENT_MIN_SCORE and "\n" not in s["text"]:
            records.append({"kind": "fragment", "off": s["off"][0],
                            "stringId": s["id"], "score": s["lua"],
                            "classes": lua51.classes(s["text"]),
                            "bytes": len(s["text"]), "text": s["text"]})

    records.sort(key=lambda r: (r["off"], r["kind"]))
    for i, r in enumerate(records):
        r["id"] = i
    return {"records": records, "files": files,
            "sourceChunks": sum(1 for r in records if r["kind"] == "sourceChunk"),
            "precompiled": sum(1 for r in records if r["kind"] == "precompiled"),
            "precompiledRejected": sum(1 for r in records
                                       if r["kind"] == "precompiledRejected"),
            "fragments": sum(1 for r in records if r["kind"] == "fragment")}


# --------------------------------------------------------------------------
# resources
# --------------------------------------------------------------------------
def extract_resources(data: bytes, parsed: dict, out_dir: Path) -> dict:
    """Every resource leaf, decoded where it is a structure, dumped where the
    size rule allows, recorded in every case."""
    rows, used = [], set()
    for i, r in enumerate(parsed.get("resources", [])):
        off, size = r.get("offset"), r.get("size", 0)
        rec = {"index": i, "typeId": r.get("typeId"),
               "typeName": r.get("typeName"),
               "nameId": r.get("nameId"), "nameString": r.get("nameString"),
               "languageId": r.get("languageId"), "rva": r.get("rva"),
               "offset": off, "bytes": size, "codePage": r.get("codePage")}
        if off is None or size <= 0:
            rec.update({"read": False,
                        "reason": r.get("note") or "empty resource"})
            rows.append(rec)
            continue
        body = data[off:off + size]
        rec.update({"read": True, "bytesRead": len(body), "sha256": _sha(body)})

        type_slug = _slug(r.get("typeName") or f"type{r.get('typeId')}")
        name_slug = _slug(r.get("nameString") or f"id{r.get('nameId')}")
        stem = f"{type_slug}/{name_slug}-lang{r.get('languageId')}"
        # A name long enough to be truncated by _slug, or a malformed tree with
        # two leaves at the same coordinates, must not silently overwrite an
        # earlier payload: the leaf's own index disambiguates it.
        if stem in used:
            stem = f"{stem}-{i}"
        used.add(stem)

        decoded = None
        if r.get("typeId") == RT_VERSION:
            decoded = pe.parse_version_info(body)
        elif r.get("typeId") == RT_STRING:
            block = r.get("nameId") or 0
            decoded = [{"stringId": (block - 1) * 16 + e["index"],
                        "text": e["text"]}
                       for e in pe.parse_string_table(body) if e["text"]]
        if decoded is not None:
            path = out_dir / f"{stem}.json"
            _json(path, decoded)
            rec["decodedFile"] = f"{stem}.json"

        text = _is_text(body)
        rec["isText"] = text
        if text or len(body) <= COMMIT_MAX_BYTES:
            rel = f"{stem}.txt" if text else f"{stem}.bin"
            path = out_dir / rel
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes(body)
            rec["file"] = rel
            rec["bytesCommitted"] = True
        else:
            rec["bytesCommitted"] = False
            rec["notCommitted"] = (
                f"{len(body)} bytes of binary payload exceeds the "
                f"{COMMIT_MAX_BYTES}-byte commit rule"
                + (" (an image or font resource type)"
                   if r.get("typeId") in ART_RESOURCE_TYPES else ""))
        rows.append(rec)
    return {"resources": rows,
            "committed": sum(1 for r in rows if r.get("bytesCommitted")),
            "decoded": sum(1 for r in rows if r.get("decodedFile"))}


# --------------------------------------------------------------------------
# symbols
# --------------------------------------------------------------------------
def symbol_records(parsed: dict) -> list:
    """Sections, imports, exports, resources, debug entries and certificates as
    one flat searchable record stream."""
    rows = []
    for s in parsed.get("sections", []):
        rows.append({"kind": "section", "name": s["name"],
                     "rva": s["virtualAddress"], "off": s["pointerToRawData"],
                     "bytes": s["sizeOfRawData"],
                     "detail": ",".join(s["characteristicsFlags"]),
                     "sha256": s.get("sha256")})
    for imp in parsed.get("imports", []):
        for f in imp["functions"]:
            rows.append({"kind": imp["kind"], "dll": imp["dll"],
                         "name": f.get("name"), "ordinal": f.get("ordinal"),
                         "hint": f.get("hint"),
                         "detail": f"{imp['dll']}!"
                                   f"{f.get('name') or ('#' + str(f.get('ordinal')))}"})
    ex = parsed.get("exports", {})
    for f in ex.get("functions", []):
        rows.append({"kind": "export", "dll": ex.get("name"),
                     "name": f.get("name"), "ordinal": f.get("ordinal"),
                     "rva": f.get("rva"), "forwarder": f.get("forwarder"),
                     "detail": f.get("forwarder") or ""})
    for r in parsed.get("resources", []):
        rows.append({"kind": "resource",
                     "name": r.get("nameString") or str(r.get("nameId")),
                     "type": r.get("typeName") or str(r.get("typeId")),
                     "language": r.get("languageId"), "off": r.get("offset"),
                     "bytes": r.get("size"),
                     "detail": f"{r.get('typeName') or r.get('typeId')}/"
                               f"{r.get('nameString') or r.get('nameId')}"})
    for d in parsed.get("debug", []):
        cv = d.get("codeView") or {}
        rows.append({"kind": "debug", "name": d.get("typeName"),
                     "off": d.get("pointerToRawData"),
                     "bytes": d.get("sizeOfData"),
                     "pdb": cv.get("pdb"), "guid": cv.get("guid"),
                     "detail": cv.get("pdb") or d.get("typeName")})
    for c in parsed.get("certificates", []):
        rows.append({"kind": "certificate", "off": c["offset"],
                     "bytes": c["bytes"], "sha256": c["sha256"],
                     "detail": f"revision {c['revision']} type "
                               f"{c['certificateType']}"})
    rich = parsed.get("rich") or {}
    for e in rich.get("entries", []):
        rows.append({"kind": "richHeaderEntry", "off": rich.get("offset"),
                     "productId": e["productId"],
                     "buildNumber": e["buildNumber"], "count": e["count"],
                     "detail": f"productId {e['productId']} build "
                               f"{e['buildNumber']} x{e['count']}"})
    for i, r in enumerate(rows):
        r["id"] = i
    return rows

def extract_bytes(data: bytes, name: str, out_dir: Path,
                  verbose: bool = True, origin: dict = None) -> dict:
    """One PE image, from its bytes, into `out_dir`.

    Split out from extract_one so a PE stored INSIDE an archive goes through
    exactly the same strings/Lua/resource/PE pass as a loose one - the alternative
    was a second, thinner code path for archived images, which is how two layers
    that are supposed to be comparable stop being comparable. `origin` is
    recorded verbatim in the summary and says where the bytes came from; it is
    None for a client-root binary."""
    digest = _sha(data)
    layerstate.clear_dir(out_dir)

    parsed = pe.parse(data)
    sections = parsed.get("sections", [])
    if verbose:
        print(f"  {name}: {len(data):,} bytes, "
              f"{len(sections)} sections", flush=True)

    strings = extract_strings(data, sections)
    string_ix = rawshard.write_group(out_dir / "strings", strings,
                                     lambda r: r["id"], stem="s")
    by_enc = {}
    for s in strings:
        by_enc[s["enc"]] = by_enc.get(s["enc"], 0) + 1
    string_ix.update({"keyField": "id", "minRunLength": MIN_RUN,
                      "rule": STRING_RULE, "byEncoding": by_enc,
                      "occurrences": sum(s["n"] for s in strings),
                      "luaScored": sum(1 for s in strings if s["lua"] > 0),
                      "tokenRule": lua51.TOKEN_RULE})
    _json(out_dir / "strings" / "index.json", string_ix)

    lua = extract_lua(data, strings, out_dir / "lua")
    lua_ix = rawshard.write_group(out_dir / "lua", lua["records"],
                                  lambda r: r["id"], stem="l")
    lua_ix.update({"keyField": "id", "pathRule": PATH_RULE,
                   "minScore": LUA_MIN_SCORE,
                   "fragmentMinScore": LUA_FRAGMENT_MIN_SCORE,
                   "tokenRule": lua51.TOKEN_RULE,
                   "sourceChunks": lua["sourceChunks"],
                   "precompiled": lua["precompiled"],
                   "precompiledRejected": lua["precompiledRejected"],
                   "fragments": lua["fragments"], "chunkFiles": lua["files"]})
    _json(out_dir / "lua" / "index.json", lua_ix)

    res = extract_resources(data, parsed, out_dir / "resources")
    _json(out_dir / "resources" / "index.json",
          {"rule": RESOURCE_RULE, "pathRule": PATH_RULE,
           "count": len(res["resources"]),
           "committed": res["committed"], "decoded": res["decoded"],
           "commitMaxBytes": COMMIT_MAX_BYTES,
           "resources": res["resources"]})

    # Bytes after the last section: no section table entry accounts for them, so
    # a reader that walks sections alone never sees them. Committed under the
    # same size rule as the resources.
    overlay = dict(parsed.get("overlay") or {})
    if overlay.get("bytes"):
        body = data[overlay["offset"]:overlay["offset"] + overlay["bytes"]]
        if len(body) <= COMMIT_MAX_BYTES:
            (out_dir / "overlay.bin").write_bytes(body)
            overlay["file"] = "overlay.bin"
            overlay["bytesCommitted"] = True
        else:
            overlay["bytesCommitted"] = False
            overlay["notCommitted"] = (f"{len(body)} bytes exceeds the "
                                       f"{COMMIT_MAX_BYTES}-byte commit rule")

    symbols = symbol_records(parsed)
    sym_ix = rawshard.write_group(out_dir / "symbols", symbols,
                                  lambda r: r["id"], stem="y")
    sym_ix["keyField"] = "id"
    sym_ix["byKind"] = {}
    for r in symbols:
        sym_ix["byKind"][r["kind"]] = sym_ix["byKind"].get(r["kind"], 0) + 1
    _json(out_dir / "symbols" / "index.json", sym_ix)

    _json(out_dir / "pe.json", parsed)

    summary = {
        "name": name, "bytes": len(data), "sha256": digest,
        "isPE": parsed.get("isPE", False),
        "machine": parsed.get("coff", {}).get("machineName"),
        "magic": parsed.get("optional", {}).get("magicName"),
        "subsystem": parsed.get("optional", {}).get("subsystemName"),
        "timeDateStamp": parsed.get("coff", {}).get("timeDateStamp"),
        "sectionNames": [s["name"] for s in sections],
        "sectionCount": len(sections),
        "importedDlls": len(parsed.get("imports", [])),
        "importedFunctions": sum(len(i["functions"])
                                 for i in parsed.get("imports", [])),
        "exportedFunctions": len(parsed.get("exports", {}).get("functions", [])),
        "resourceCount": len(parsed.get("resources", [])),
        "resourcesCommitted": res["committed"],
        "pdbPaths": sorted({d["codeView"]["pdb"] for d in parsed.get("debug", [])
                            if d.get("codeView", {}).get("pdb")}),
        "overlay": overlay,
        "overlayBytes": overlay.get("bytes", 0),
        "certificates": len(parsed.get("certificates", [])),
        "strings": len(strings), "stringsByEncoding": by_enc,
        "stringOccurrences": sum(s["n"] for s in strings),
        "stringStoredBytes": string_ix["storedBytes"],
        "luaSourceChunks": lua["sourceChunks"],
        "luaPrecompiled": lua["precompiled"],
        "luaPrecompiledRejected": lua["precompiledRejected"],
        "luaFragments": lua["fragments"],
        "luaChunkFiles": [f["file"] for f in lua["files"]],
        "symbols": len(symbols),
        "parseNotes": parsed.get("notes", []),
    }
    if origin:
        summary["origin"] = origin
    root = OUT_ROOT
    rel = out_dir.relative_to(root).as_posix() \
        if root is not None and out_dir.is_relative_to(root) \
        else out_dir.name
    summary["dir"] = rel
    _json(out_dir / "index.json", summary)
    layerstate.finish(out_dir, {"layer": f"binaries/{rel}",
                                "generatedBy": "python datamine.py",
                                "sourceSha256": digest,
                                "strings": len(strings),
                                "symbols": len(symbols),
                                "luaRecords": len(lua["records"])})
    return summary