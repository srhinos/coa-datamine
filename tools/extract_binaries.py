"""The client's own executables, opened.

    python -m tools.extract_binaries              # every PE in the client root
    python -m tools.extract_binaries --only Extensions.dll
    python -m tools.extract_binaries --force      # ignore the resume checkpoints

WHY THIS LAYER EXISTS
---------------------
Every other layer in this repo reads DATA the client ships. This one reads the
client. `Extensions.dll` is Ascension's engine extension and it is the only file
in the install that carries `listarchive`, `SetDataPath`, `realmdata` and an
inlined Lua chunk that builds `AscensionRealmHotSwapOverlay` - script that
exists in no .lua file anywhere in the extracted Interface tree, so no amount of
reading the addon layer will ever show it. Until now nothing had been extracted
from any of these files at all.

WHAT COMES OUT, AND THE RULE BEHIND EACH
----------------------------------------
    strings/    Every printable run in the file, in three encodings - ASCII,
                UTF-16LE and UTF-8 (the last only where a run actually contains
                a multi-byte character, so it is never a second copy of the
                ASCII pass). Minimum run length is MIN_RUN characters and is
                recorded in the index. Runs are deduplicated by (encoding,
                text); EVERY file offset each one occurs at is kept, along with
                the PE section that offset falls in - a string in `.rdata` and
                the same string in `.text` are different facts.

    lua/        Two readers, because Lua appears here in two unrelated forms.
                Multi-line SOURCE runs that score at least LUA_MIN_SCORE on
                tools/lua51.py's syntax-class measure are written out verbatim
                as .lua files. Precompiled chunks are found by their `\\x1bLua`
                magic and then WALKED to their last byte (tools/lua51.undump);
                a magic hit that does not walk cleanly is recorded as a
                rejection with the reason, because "the signature is here and it
                is not a chunk" is the answer for Ascension.exe, whose Lua
                compiler writes those four bytes at run time. Single-line
                fragments - the concatenation pieces the DLL assembles scripts
                from - are listed separately at LUA_FRAGMENT_MIN_SCORE.

    pe.json     Sections, imports (including delay-load), exports, the resource
                tree, the debug directory, the certificate table, the Rich
                header and the overlay. tools/pe.py reads it; nothing here
                interprets it.

    resources/  Every resource leaf. RT_VERSION and RT_STRING are decoded to
                JSON because they ARE structured text; everything else is
                written as bytes under the same recorded-not-committed rule the
                rest of this repo uses (see COMMIT_MAX_BYTES).

    symbols/    One JSONL record per import, export, section, resource and
                debug entry, so `tools.find` can answer "which binary imports
                this" the same way it answers everything else.

NO INTERPRETATION
-----------------
Nothing here says what a string MEANS. Names are the PE specification's or the
Lua language's; every threshold is stated in the index next to the counts it
produced; the Lua score travels with every string so a reader can re-cut it.

CRASH SAFETY
------------
This host aborts processes at random. Each binary is finished independently and
its completion is checkpointed in work/binaries/ under the INPUT's sha256, so a
killed run resumes at the next binary instead of restarting, and the layer
carries tools/layerstate's sentinel so a half-written tree can never be read as
a whole one.
"""
import argparse
import hashlib
import json
import re
import sys
import time
from pathlib import Path

from tools import config, layerstate, lua51, pe, rawshard
from tools.decode_all import write_text

OUT_DIR = config.RAW_DIR / "binaries"
WORK_DIR = config.WORK_DIR / "binaries"

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
    "Every file in the client root whose bytes parse as a PE image, found by "
    "reading the bytes - no name list and no extension test decides it. The "
    "whole client tree is swept for further .exe/.dll/.ocx/.sys files and the "
    "result is recorded in `outsideRoot`, so 'these are all of them' is a "
    "measurement rather than an assumption.")


# --------------------------------------------------------------------------
# helpers
# --------------------------------------------------------------------------
def _sha(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


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
# discovery
# --------------------------------------------------------------------------
def client_binaries(root: Path = None) -> list:
    """Every PE image sitting directly in the client root, by reading bytes."""
    root = root or config.CLIENT_DIR
    out = []
    if not root.is_dir():
        return out
    for p in sorted(root.iterdir()):
        if not p.is_file():
            continue
        try:
            with open(p, "rb") as f:
                head = f.read(0x1000)
                # e_lfanew is a file offset and nothing caps it: a DOS stub
                # longer than the window would make a real PE look like it is
                # not one. Read the file rather than answer from a short read.
                if (head[:2] == b"MZ" and len(head) >= 0x40
                        and not pe.is_pe(head)):
                    f.seek(0)
                    head = f.read()
        except OSError:
            continue
        if pe.is_pe(head):
            out.append(p)
    return out


def _outside_root(root: Path = None) -> list:
    """Binary-shaped files anywhere else in the client. Recorded so the claim
    that the root holds all of them is measured, not assumed."""
    root = root or config.CLIENT_DIR
    hits = []
    if not root.is_dir():
        return hits
    for p in root.rglob("*"):
        if p.parent == root or not p.is_file():
            continue
        if p.suffix.lower() in (".exe", ".dll", ".ocx", ".sys"):
            hits.append(str(p.relative_to(root)).replace("\\", "/"))
    return sorted(hits)


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


# --------------------------------------------------------------------------
# one binary
# --------------------------------------------------------------------------
def extract_one(path: Path, out_root: Path = None, verbose: bool = True) -> dict:
    out_root = out_root or OUT_DIR
    data = path.read_bytes()
    digest = _sha(data)
    out_dir = out_root / path.name
    layerstate.clear_dir(out_dir)

    parsed = pe.parse(data)
    sections = parsed.get("sections", [])
    if verbose:
        print(f"  {path.name}: {len(data):,} bytes, "
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
        "name": path.name, "bytes": len(data), "sha256": digest,
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
    _json(out_dir / "index.json", summary)
    layerstate.finish(out_dir, {"layer": f"binaries/{path.name}",
                                "generatedBy": "python -m tools.extract_binaries",
                                "sourceSha256": digest,
                                "strings": len(strings),
                                "symbols": len(symbols),
                                "luaRecords": len(lua["records"])})
    return summary


# --------------------------------------------------------------------------
# the layer
# --------------------------------------------------------------------------
def _checkpoint(name: str, digest: str) -> Path:
    return WORK_DIR / f"{_slug(name)}.{digest[:16]}.json"


def extract(only=None, force: bool = False, verbose: bool = True) -> dict:
    """Every client-root PE, resumable per binary.

    `--only` and `--force` decide what is RE-extracted, never what the layer
    contains: a binary that is not selected is loaded from its own committed
    index if it has one and extracted if it does not, so a partial rerun can
    never publish a layer index that has lost the binaries it did not touch."""
    binaries = client_binaries()
    if not binaries:
        raise SystemExit(f"no PE image in {config.CLIENT_DIR}")
    want = {o.lower() for o in only} if only else None
    if want and not any(p.name.lower() in want for p in binaries):
        raise SystemExit(f"no client-root PE named {', '.join(sorted(only))}")

    WORK_DIR.mkdir(parents=True, exist_ok=True)
    layerstate.begin(OUT_DIR)
    OUT_DIR.mkdir(parents=True, exist_ok=True)

    summaries, skipped = [], 0
    for p in binaries:
        selected = want is None or p.name.lower() in want
        digest = _sha(p.read_bytes())
        cp = _checkpoint(p.name, digest)
        done = OUT_DIR / p.name / "index.json"
        fresh = (cp.is_file() and done.is_file()
                 and layerstate.is_complete(OUT_DIR / p.name))
        if fresh and not (force and selected):
            summaries.append(json.loads(done.read_text(encoding="utf-8")))
            skipped += 1
            if verbose:
                print(f"  {p.name}: unchanged, resumed from checkpoint",
                      flush=True)
            continue
        t = time.time()
        s = extract_one(p, OUT_DIR, verbose)
        summaries.append(s)
        layerstate.atomic_write(cp, json.dumps(
            {"name": p.name, "sha256": digest, "strings": s["strings"]},
            indent=1, sort_keys=True).encode("utf-8") + b"\n")
        if verbose:
            print(f"    {s['strings']:,} strings, {s['symbols']:,} symbols, "
                  f"{s['luaSourceChunks']} lua chunks, "
                  f"{s['luaFragments']} fragments  [{time.time() - t:.1f}s]",
                  flush=True)

    # directories for binaries that are no longer in the client
    keep = {p.name for p in binaries}
    for d in sorted(OUT_DIR.iterdir()):
        if d.is_dir() and d.name not in keep:
            layerstate.clear_dir(d)
            d.rmdir()

    payload = write_layer_index(summaries)
    write_readme(summaries)
    layerstate.finish(OUT_DIR, {
        "layer": "binaries", "generatedBy": "python -m tools.extract_binaries",
        "binaryCount": len(summaries),
        "stringTotal": sum(s["strings"] for s in summaries),
        "luaChunkTotal": sum(s["luaSourceChunks"] + s["luaPrecompiled"]
                             for s in summaries),
        "luaFragmentTotal": sum(s["luaFragments"] for s in summaries),
        "symbolTotal": sum(s["symbols"] for s in summaries),
        "resourceTotal": sum(s["resourceCount"] for s in summaries)})
    if verbose:
        print(f"  {len(summaries)} binaries ({skipped} resumed), "
              f"{sum(s['strings'] for s in summaries):,} strings", flush=True)
    return payload


def write_layer_index(summaries: list) -> dict:
    payload = {
        "generatedBy": "python -m tools.extract_binaries",
        "clientDir": str(config.CLIENT_DIR),
        "selectionRule": SELECTION_RULE,
        "stringRule": STRING_RULE,
        "luaRule": lua51.TOKEN_RULE,
        "resourceRule": RESOURCE_RULE,
        "interpretationRule":
            "Nothing here says what a string means. Field names are the "
            "PE/COFF specification's and the Lua language's; every threshold is "
            "recorded next to the counts it produced.",
        "minRunLength": MIN_RUN,
        "luaMinScore": LUA_MIN_SCORE,
        "luaFragmentMinScore": LUA_FRAGMENT_MIN_SCORE,
        "binaryCount": len(summaries),
        "stringTotal": sum(s["strings"] for s in summaries),
        "symbolTotal": sum(s["symbols"] for s in summaries),
        "resourceTotal": sum(s["resourceCount"] for s in summaries),
        "luaChunkTotal": sum(s["luaSourceChunks"] + s["luaPrecompiled"]
                             for s in summaries),
        "luaFragmentTotal": sum(s["luaFragments"] for s in summaries),
        "outsideRoot": _outside_root(),
        "binaries": sorted(summaries, key=lambda s: s["name"].lower()),
    }
    _json(OUT_DIR / "index.json", payload)
    return payload


def write_readme(summaries: list) -> None:
    rows = []
    for s in sorted(summaries, key=lambda x: x["name"].lower()):
        rows.append(
            f"| `{s['name']}` | {s['bytes']:,} | {s['machine'] or '-'} | "
            f"{s['strings']:,} | {s['luaSourceChunks'] + s['luaPrecompiled']} | "
            f"{s['luaFragments']} | {s['importedFunctions']} | "
            f"{s['exportedFunctions']} | {s['resourceCount']} |")
    body = f"""# raw/binaries - the client's own executables (generated)

Written by `python -m tools.extract_binaries` from the PE images in
`{config.CLIENT_DIR}`. Every other layer in this repo reads data the client
ships; this one reads the client.

| binary | bytes | machine | strings | lua chunks | lua fragments | imports | exports | resources |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
{chr(10).join(rows)}

## What is under each binary

```
<name>/index.json          counts and the PE headline for this image
<name>/pe.json             sections, imports, exports, resources, debug,
                           certificates, the Rich header, the overlay
<name>/strings/            every printable run, sharded JSONL, with offsets
<name>/lua/                one record per chunk and per single-line fragment
<name>/lua/chunks/         recovered Lua, verbatim (.lua source, .luac compiled)
<name>/resources/          resource payloads, decoded where they are structures
<name>/symbols/            imports/exports/sections/resources/debug as records
```

## The rules, stated

* **Which files.** {SELECTION_RULE}
* **Strings.** {STRING_RULE}
* **Lua.** {lua51.TOKEN_RULE} A run is written out as a source chunk when it
  spans at least two lines and scores at least {LUA_MIN_SCORE}; single-line
  fragments are listed at {LUA_FRAGMENT_MIN_SCORE}. Precompiled chunks are found
  by their `\\x1bLua` magic and then walked to their last byte, so a magic hit
  that is not a chunk is recorded as a rejection with its reason instead of
  being reported as recovered script.
* **Resources.** {RESOURCE_RULE}
* **No interpretation.** Nothing here says what a string means.

## Searching it

```
python -m tools.find "listarchive" --layer binaries
python -m tools.find "SetDataPath"
```

## Half-written layers cannot happen silently

{layerstate.RULE}
"""
    write_text(OUT_DIR / "README.md", body)


# --------------------------------------------------------------------------
def main(argv=None) -> int:
    ap = argparse.ArgumentParser(
        prog="python -m tools.extract_binaries",
        description="Extract strings, embedded Lua and PE structure from the "
                    "client's own executables.")
    ap.add_argument("--only", action="append", metavar="NAME",
                    help="just this binary (repeatable)")
    ap.add_argument("--force", action="store_true",
                    help="re-extract even when the checkpoint says unchanged")
    ap.add_argument("--quiet", action="store_true")
    a = ap.parse_args(argv)
    t = time.time()
    payload = extract(a.only, a.force, not a.quiet)
    if not a.quiet:
        print(f"\nraw/binaries: {payload['binaryCount']} binaries, "
              f"{payload['stringTotal']:,} strings, "
              f"{payload['luaChunkTotal']} lua chunks, "
              f"{payload['luaFragmentTotal']} fragments, "
              f"{payload['symbolTotal']:,} symbols  "
              f"[{time.time() - t:.1f}s]")
    return 0


if __name__ == "__main__":
    sys.exit(main())
