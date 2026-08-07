"""Decode EVERY distinct version of every client table, not just the chain winner.

    python -m tools.variants          # step 2b of the raw table layer

THE DEFECT THIS CLOSES
----------------------
tools/extract_all.py resolves one winner per path - the last carrier in loader
order - and tools/decode_all.py decodes that one file. Everything else the
client ships for that path is named in the provenance as a "loser" and then
thrown away. That is not a rounding error: this client's realm directory sits
ABOVE the whole base chain, so for every path a realm overlay carries, the
winner is the OVERLAY's table and the base table - the one a character on a
realm with no overlay directory actually reads - is absent from the layer
entirely. The layer simultaneously dropped real client data and presented one
realm's table as canonical for all of them.

WHAT THIS MODULE DOES INSTEAD
-----------------------------
COMPLETE    Every archive carrying a path is read and its copy hashed. Copies
            that differ by sha256 are distinct VARIANTS and every one of them is
            decoded by the SAME decoder, under the same f0..fN inference, the
            same sharding rule and the same compression rule as the winner.
            Copies that are byte-identical to another are recorded as `alsoIn`
            rather than decoded twice - identical bytes are one version.
            An archive that carries a path but cannot be read is recorded in
            `failures`, never dropped.
MECHANICAL  Nothing here knows a table, a realm or an archive by name. Which
            copy a client selects is computed from CHAIN CONTEXTS built out of
            the client's own directory layout (see CONTEXT_RULE), so `appliesTo`
            is derived from the archive path and never assigned by hand.
RERUNNABLE  One command, no arguments, no agent, and byte-identical output on an
            unchanged client. The expensive pass - decompressing and hashing
            every copy - is checkpointed per archive under work/variant_hashes/
            and keyed by a content fingerprint of that archive's own hash/block
            table entries, so a crashed run resumes instead of restarting and a
            changed archive invalidates its own checkpoint.

LAYOUT
------
    raw/tables/<T>/                       unchanged: the CHAIN WINNER's decode
    raw/tables/<T>/index.json             gains a `variants` block: every
                                          version, its archive, chain rank,
                                          sha256, rows, and which is the winner
    raw/tables/<T>/variants/index.json    that same block, standalone
    raw/tables/<T>/variants/<slug>/       one directory per NON-winner version,
                                          with its own index.json, colinfo and
                                          shards - identical in shape to the
                                          winner's, so every existing reader
                                          works on it unchanged
    raw/tables/_variants.json             every table with more than one version

`<slug>` is the carrying archive's dir-qualified id, lowercased with every
non-alphanumeric run collapsed to `-`, so it names the archive and nothing else.
"""
import argparse
import collections
import hashlib
import json
import re
import time
from pathlib import Path

from tools import config, layerstate, mpq, probe_unlistable, sharding
from tools.decode_all import OUT_DIR as TABLES_DIR
from tools.decode_all import decode_table, write_readme, write_text
from tools.extract_all import OUT_DIR as WINNER_DIR
from tools.extract_all import (READ_AGREEMENT_RULE, READER_RULE, TABLE_DIR,
                               _header_facts, load_provenance, read_agreed)
from tools.inventory import archive_id, discover_archives

WORK_DIR = config.WORK_DIR / "dbc_variants"
CHECKPOINT_DIR = config.WORK_DIR / "variant_hashes"
VARIANTS_JSON = TABLES_DIR / "_variants.json"
VARIANT_SUBDIR = "variants"
BASE_CONTEXT = "baseChain"

_SLUG = re.compile(r"[^a-z0-9]+")

CONTEXT_RULE = (
    "A chain context is a set of archives a running client actually loads. It "
    "is enumerated from the client's own directory layout, not from a list: the "
    "context called `baseChain` is every archive in the base and locale "
    "directories - what a character reads when no realm overlay applies - and "
    "there is one further context per realm directory found, holding that same "
    "base set plus the archives that realm's own `listarchive` declares. A "
    "version APPLIES TO a context when its archive is the highest-ranked "
    "carrier of that path inside it; chain rank is position in "
    "tools/inventory.discover_archives(), the same loader order the census and "
    "the extractor use. A version that is the highest-ranked carrier in no "
    "context at all is still decoded - it is real client data - and is marked "
    "shadowed."
)

VARIANT_RULE = (
    "One version per DISTINCT sha256 among the copies of a path, not one per "
    "carrying archive: byte-identical copies in several archives are ONE "
    "version, listed once under the highest-ranked archive that carries those "
    "bytes with the rest recorded in `alsoIn`. The chain winner - the copy "
    "tools/decode_all.py already decoded - keeps its place at "
    "raw/tables/<T>/ and is listed here with `chainWinner` true; every other "
    "version is decoded into raw/tables/<T>/variants/<slug>/ by the same "
    "decoder, so the two are comparable byte for byte. `rowDelta` is this "
    "version's record count minus the chain winner's."
)

FINGERPRINT_RULE = (
    "Decompressing and hashing every copy of every table is the only pass here "
    "long enough that finishing it in one process is an assumption rather than "
    "a formality, so it is checkpointed per archive under work/variant_hashes/. "
    "The checkpoint key is a sha256 over the archive's file size plus the "
    "offset, stored size, decompressed size and flags of every table entry in "
    "its block table - all read from the archive's own tables without "
    "decompressing anything. A changed archive therefore invalidates its own "
    "checkpoint, and the output is the same with an empty cache or a full one."
)


class VariantError(RuntimeError):
    pass


def slug(aid: str) -> str:
    """An archive's directory-qualified id as a filename: lowercased, every run
    of non-alphanumerics collapsed to '-'. Archive ids are unique, so slugs are
    too - which is asserted rather than assumed, because a collision would
    silently merge two archives' versions into one directory."""
    return _SLUG.sub("-", aid.lower()).strip("-")


def stem_of(stored: str) -> str:
    name = stored.rsplit("\\", 1)[-1]
    return name[:-4] if name.lower().endswith(".dbc") else name


# --------------------------------------------------------------------------
# stage 1 - every carrier of every path, not just the winner
# --------------------------------------------------------------------------
def resolve_copies(verbose: bool = True):
    """Walk the chain and keep EVERY carrier of every path under the table
    directory. This is tools/extract_all.resolve_chain()'s walk with the
    discard removed: that function keeps the winner and reduces the rest to a
    list of archive names, which is exactly the information loss this module
    exists to undo."""
    archives = discover_archives()
    meta, carriers, unlistable = {}, {}, []
    t0 = time.time()
    for i, rec in enumerate(archives):
        p = rec["path"]
        aid = archive_id(p)
        meta[aid] = {"archive": aid, "chainRank": i, "layer": rec["layer"],
                     "realm": rec["realm"], "declared": rec["declared"],
                     "path": p}
        files, reason = probe_unlistable.try_list(p)
        if files is None:
            unlistable.append({"archive": aid, "chainRank": i, "reason": reason})
            continue
        found = 0
        for raw in files:
            stored = raw.decode("latin-1", "replace").replace("/", "\\")
            low = stored.lower()
            if not low.startswith(TABLE_DIR):
                continue
            found += 1
            c = carriers.setdefault(low, {"path": low, "stored": stored,
                                          "copies": []})
            # Archives disagree about the CASE of a stored path. The chain
            # walk runs weakest-first, so overwriting here leaves the winner's
            # spelling - the same one tools/extract_all.py names the extracted
            # file with, and therefore the same directory the decode wrote.
            c["stored"] = stored
            c["copies"].append({"archive": aid, "chainRank": i, "readable": True})
        if verbose and found:
            print(f"  [{i+1:2d}/{len(archives)}] {aid:34s} copies={found:4d} "
                  f"paths={len(carriers):4d}  [{time.time()-t0:5.1f}s]", flush=True)

    # An archive with no readable listfile can still CARRY a path; its hash
    # table answers that question without enumeration. A hit there is a copy
    # this module cannot read, which is a recorded failure, not an absence.
    names = sorted(carriers)
    probes = {}
    for u in unlistable:
        try:
            hits = probe_unlistable.probe_paths(meta[u["archive"]]["path"], names)
        except Exception as e:                       # noqa: BLE001 - recorded
            probes[u["archive"]] = {"error": f"{type(e).__name__}: {e}",
                                    "probedCount": len(names), "hits": []}
            continue
        hit = sorted(k for k, v in hits.items() if v)
        probes[u["archive"]] = {"probedCount": len(names), "hits": hit,
                                "reason": u["reason"]}
        for low in hit:
            carriers[low]["copies"].append(
                {"archive": u["archive"], "chainRank": u["chainRank"],
                 "readable": False})
    for c in carriers.values():
        c["copies"].sort(key=lambda x: x["chainRank"])
    return carriers, archives, meta, unlistable, probes


def build_contexts(meta: dict) -> list:
    """CONTEXT_RULE, as code. Reads only each archive's layer and realm, both of
    which discover_archives() derives from where the file sits on disk."""
    base = {aid for aid, m in meta.items() if m["layer"] != "realm"}
    realms = sorted({m["realm"] for m in meta.values()
                     if m["layer"] == "realm" and m["realm"]})
    out = [{"context": BASE_CONTEXT, "archives": base}]
    for r in realms:
        out.append({"context": f"realm:{r}",
                    "archives": base | {aid for aid, m in meta.items()
                                        if m["realm"] == r}})
    return out


# --------------------------------------------------------------------------
# stage 2 - hash every copy (checkpointed per archive)
# --------------------------------------------------------------------------
def archive_fingerprint(a, aid: str, size: int, stored: list) -> str:
    """Content-derived checkpoint key, read from the archive's own hash and
    block tables - no file content is decompressed to compute it."""
    parts = [aid, str(size)]
    for s in stored:
        bi = a.block_index_of(s)
        b = a.block_table[bi] if bi is not None and bi < len(a.block_table) \
            else None
        parts.append("|".join(str(x) for x in (
            s.lower(), *((-1, -1, -1, -1) if b is None else b))))
    return hashlib.sha256("\n".join(parts).encode("utf-8")).hexdigest()


def hash_archive(aid: str, apath: Path, stored: list, verbose: bool = True):
    """Every copy this archive carries, hashed. Returns (payload, from_cache)."""
    ck = CHECKPOINT_DIR / (slug(aid) + ".json")
    a = mpq.Archive(apath)
    fp = archive_fingerprint(a, aid, apath.stat().st_size, stored)
    if ck.is_file():
        try:
            old = json.loads(ck.read_bytes().decode("utf-8"))
        except ValueError:
            old = {}
        # The rule text is part of the key on purpose: a checkpoint written
        # before the two-agreeing-reads rule existed was produced by a weaker
        # measurement and must not be trusted just because the archive matches.
        # READER_RULE is in the key for the same reason - a checkpoint written
        # by the previous reader must not survive the move onto this one.
        if old.get("fingerprint") == fp \
                and old.get("readAgreementRule") == READ_AGREEMENT_RULE \
                and old.get("readerRule") == READER_RULE \
                and old.get("fileCount", -1) + len(old.get("failures", [])) == len(stored):
            a.close()
            return old, True

    files, failures = {}, []
    for s in stored:
        # No pre-check on the block entry's size here. A zero-byte entry can be
        # a DELETE_MARKER tombstone or a genuinely empty member, and those are
        # different client facts; testing `size == 0` reports the first as the
        # second. The reader already classifies it, so the classification is
        # read off the member's status rather than re-derived (wrongly) here.
        try:
            data, sha, reason, status = read_agreed(a, s)
        except Exception as ex:                      # noqa: BLE001 - recorded
            data, sha, reason, status = None, None, f"{type(ex).__name__}: {ex}", "error"
        if data is None:
            failures.append({"path": s, "archive": aid, "stage": "read",
                             "status": status, "reason": reason})
            continue
        files[s.lower()] = {"sha256": sha, **_header_facts(data)}
        del data
    a.close()
    payload = {"archive": aid, "fingerprint": fp, "fingerprintRule": FINGERPRINT_RULE,
               "readAgreementRule": READ_AGREEMENT_RULE, "readerRule": READER_RULE,
               "fileCount": len(files), "failures": failures, "files": files}
    layerstate.atomic_write(ck, json.dumps(payload, ensure_ascii=False, indent=1,
                                           sort_keys=True).encode("utf-8") + b"\n")
    return payload, False


def hash_all(carriers: dict, meta: dict, verbose: bool = True):
    """{(path, archive): facts} over every readable copy in the client."""
    by_archive = {}
    for low, c in carriers.items():
        for cp in c["copies"]:
            if cp["readable"]:
                by_archive.setdefault(cp["archive"], []).append(c["stored"])
    hashes, failures = {}, []
    t0 = time.time()
    for aid in sorted(by_archive, key=lambda x: meta[x]["chainRank"]):
        stored = sorted(by_archive[aid])
        payload, cached = hash_archive(aid, meta[aid]["path"], stored, verbose)
        for low, rec in payload["files"].items():
            hashes[(low, aid)] = rec
        failures.extend(payload["failures"])
        if verbose:
            print(f"  {aid:34s} copies={len(stored):4d} hashed={payload['fileCount']:4d}"
                  f"{'  (cached)' if cached else ''}  [{time.time()-t0:6.1f}s]",
                  flush=True)
    return hashes, failures


# --------------------------------------------------------------------------
# stage 3 - group copies into distinct versions
# --------------------------------------------------------------------------
def group_versions(carriers: dict, hashes: dict, meta: dict, contexts: list,
                   provenance: dict, already: set = ()) -> list:
    """One record per path: its distinct versions, which archives carry each,
    and which chain contexts select it. Nothing here is decoded yet.

    `already` is the (path, archive) set the hash pass already recorded a
    failure for, so a copy that could not be read is reported once."""
    prov = {t["path"].replace("/", "\\").lower(): t
            for t in provenance.get("tables", [])}
    already = set(already)
    out, failures = [], []
    for low in sorted(carriers):
        c = carriers[low]
        stem = stem_of(c["stored"])
        readable = [cp for cp in c["copies"] if cp["readable"]
                    and (low, cp["archive"]) in hashes]
        for cp in c["copies"]:
            if (c["stored"], cp["archive"]) in already:
                continue
            if not cp["readable"]:
                failures.append({
                    "path": c["stored"], "archive": cp["archive"],
                    "stage": "carrier", "reason":
                        "archive carries this path but has no readable listfile "
                        "and its content could not be read"})
            elif (low, cp["archive"]) not in hashes:
                failures.append({"path": c["stored"], "archive": cp["archive"],
                                 "stage": "hash", "reason": "copy could not be read"})
        if not readable:
            continue

        winner = readable[-1]
        wsha = hashes[(low, winner["archive"])]["sha256"]
        # Independent cross-check: the extractor resolved this same winner by
        # its own walk. A disagreement means one of the two readers is looking
        # at bytes the client does not use, which is structural, not cosmetic.
        p = prov.get(low)
        if p and (p["winner"] != winner["archive"] or p["sha256"] != wsha):
            raise VariantError(
                f"winner disagreement for {c['stored']}: the extraction in "
                f"work/dbc_all says {p['winner']}/{p['sha256'][:12]}, a fresh "
                f"read of the chain says {winner['archive']}/{wsha[:12]}. Two "
                f"independent reads of the client disagree, so raw/tables holds "
                f"bytes the client does not. Re-run `python -m "
                f"tools.extract_all` (its reads must now agree twice before it "
                f"writes) and then `python -m tools.decode_all --resume`.")

        by_sha = {}
        for cp in readable:
            by_sha.setdefault(hashes[(low, cp["archive"])]["sha256"], []).append(cp)

        selected = {}
        for ctx in contexts:
            inside = [cp for cp in readable if cp["archive"] in ctx["archives"]]
            if inside:
                selected.setdefault(
                    hashes[(low, inside[-1]["archive"])]["sha256"], []
                ).append(ctx["context"])

        versions = []
        for sha, copies in by_sha.items():
            rep = copies[-1]                      # highest-ranked carrier
            facts = hashes[(low, rep["archive"])]
            m = meta[rep["archive"]]
            ctxs = sorted(selected.get(sha, []))
            versions.append({
                "slug": slug(rep["archive"]),
                "archive": rep["archive"],
                "chainRank": rep["chainRank"],
                "layer": m["layer"],
                "realm": m["realm"],
                "sha256": sha,
                "rows": facts.get("records", 0),
                "columns": facts.get("actualFields", 0)
                           + facts.get("trailingBytesPerRecord", 0),
                "recordSize": facts.get("recordSize"),
                "stringBlockSize": facts.get("stringBlockSize"),
                "sourceBytes": facts.get("bytes", 0),
                "chainWinner": sha == wsha,
                "appliesTo": ctxs,
                "appliesToNote": _applies_note(ctxs, rep["archive"]),
                "alsoIn": [x["archive"] for x in copies[:-1]],
            })
        versions.sort(key=lambda v: (-v["chainRank"], v["sha256"]))
        wrows = next(v["rows"] for v in versions if v["chainWinner"])
        for v in versions:
            v["rowDelta"] = v["rows"] - wrows
            v["path"] = (f"raw/tables/{stem}/" if v["chainWinner"]
                         else f"raw/tables/{stem}/{VARIANT_SUBDIR}/{v['slug']}/")
        out.append({
            "table": stem, "file": c["stored"].rsplit("\\", 1)[-1],
            "clientPath": c["stored"].replace("\\", "/"),
            "copyCount": len(c["copies"]), "readableCopyCount": len(readable),
            "versionCount": len(versions),
            "carriedBy": [cp["archive"] for cp in c["copies"]],
            "versions": versions,
        })
    return out, failures


def _applies_note(contexts: list, archive: str) -> str:
    if not contexts:
        return (f"shadowed: {archive} carries these bytes but is outranked in "
                f"every chain context, so no client selects them")
    return f"selected by chain context(s): {', '.join(contexts)}"


# --------------------------------------------------------------------------
# stage 4 - decode every version the winner decode does not already cover
# --------------------------------------------------------------------------
def decode_versions(records: list, meta: dict, out_dir: Path, resume: bool = True,
                    verbose: bool = True) -> list:
    """Extract and decode every non-winner version. Grouped by archive so each
    one is opened once, and the bytes are re-hashed on the way out, so a byte
    stream that does not reproduce the hash the checkpoint recorded is caught
    here rather than committed. That check is kept as cheap insurance against
    one unexplained corruption incident on this host, NOT because a hardware
    fault is established - see HOST_FAULT_SCOPE in tools/crack.py."""
    todo = {}
    for r in records:
        for v in r["versions"]:
            if not v["chainWinner"]:
                todo.setdefault(v["archive"], []).append((r, v))
    failures, decoded, skipped = [], 0, 0
    total = sum(len(v) for v in todo.values())
    t0 = time.time()
    for aid in sorted(todo, key=lambda x: meta[x]["chainRank"]):
        jobs = sorted(todo[aid], key=lambda j: j[0]["table"].lower())
        pending = []
        for r, v in jobs:
            dest = out_dir / r["table"] / VARIANT_SUBDIR / v["slug"]
            ix = dest / "index.json"
            if resume and ix.is_file():
                old = json.loads(ix.read_bytes().decode("utf-8"))
                if old.get("sourceSha256") == v["sha256"] and all(
                        (dest / s["file"]).is_file() for s in old["shards"]):
                    skipped += 1
                    continue
            pending.append((r, v, dest))
        if not pending:
            continue
        a = mpq.Archive(meta[aid]["path"])
        for r, v, dest in pending:
            stored = r["clientPath"].replace("/", "\\")
            try:
                data, got, reason, status = read_agreed(a, stored)
            except Exception as e:                   # noqa: BLE001 - recorded
                data, got, reason, status = None, None, f"{type(e).__name__}: {e}", "error"
            if data is None:
                failures.append({"table": r["file"], "archive": aid,
                                 "stage": "extract", "status": status,
                                 "reason": reason})
                continue
            if got != v["sha256"]:
                raise VariantError(
                    f"{r['file']} in {aid} hashed {got[:12]} on extract but "
                    f"{v['sha256'][:12]} when the checkpoint was written - the "
                    f"bytes are not stable, refusing to write the layer")
            src = WORK_DIR / v["slug"]
            src.mkdir(parents=True, exist_ok=True)
            (src / r["file"]).write_bytes(data)
            del data
            source = {"winner": aid, "losers": v["alsoIn"],
                      "sha256": v["sha256"], "bytes": v["sourceBytes"]}
            try:
                decode_table(r["file"], source, out_dir, src_dir=src, dest=dest)
            except Exception as e:                   # noqa: BLE001 - recorded
                failures.append({"table": r["file"], "archive": aid,
                                 "stage": "decode",
                                 "reason": f"{type(e).__name__}: {e}"})
                continue
            decoded += 1
            if verbose and (decoded % 25 == 0 or decoded + skipped == total):
                print(f"  decoded {decoded}/{total - skipped} versions "
                      f"[{time.time()-t0:6.1f}s]", flush=True)
        a.close()
    if verbose:
        print(f"  versions decoded={decoded} reused={skipped} "
              f"failed={len(failures)}", flush=True)
    return failures


# --------------------------------------------------------------------------
# stage 5 - write the records into the layer
# --------------------------------------------------------------------------
def _version_record(v: dict, ix: dict = None) -> dict:
    rec = {k: v[k] for k in ("slug", "archive", "chainRank", "layer", "realm",
                             "sha256", "rows", "columns", "sourceBytes",
                             "chainWinner", "appliesTo", "appliesToNote",
                             "alsoIn", "rowDelta", "path")}
    if ix is not None:
        rec["decodedRows"] = ix["rows"]
        rec["shards"] = ix["shardCount"]
        rec["storedBytes"] = ix["storedBytes"]
        rec["format"] = ix["format"]
    return rec


def write_records(records: list, out_dir: Path, contexts: list, meta: dict,
                  failures: list, verbose: bool = True) -> dict:
    """Write the `variants` block into every table index, the per-table variant
    index, and the layer-wide _variants.json."""
    contested, multi = [], []
    added_stored = added_rows = 0
    for r in records:
        tdir = out_dir / r["table"]
        ipath = tdir / "index.json"
        if not ipath.is_file():
            continue                       # table the decode recorded as failed
        index = json.loads(ipath.read_bytes().decode("utf-8"))
        vdir = tdir / VARIANT_SUBDIR
        rows = []
        for v in r["versions"]:
            if v["chainWinner"]:
                ix = index          # the winner's decode IS this index
            else:
                ix = None
                vp = vdir / v["slug"] / "index.json"
                if vp.is_file():
                    ix = json.loads(vp.read_bytes().decode("utf-8"))
                    added_stored += ix["storedBytes"]
                    added_rows += ix["rows"]
            rows.append(_version_record(v, ix))

        index["variantCount"] = len(rows)
        index["variantRule"] = VARIANT_RULE
        index["contextRule"] = CONTEXT_RULE
        index["variants"] = rows
        write_text(ipath, sharding.dump_manifest(index))

        if len(rows) > 1:
            payload = {
                "note": "Every distinct version of this table in the client. "
                        "The chain winner is decoded one directory up; every "
                        "other version is decoded in the subdirectory named by "
                        "its `slug`, by the same decoder under the same rules.",
                "table": r["table"], "file": r["file"],
                "variantRule": VARIANT_RULE, "contextRule": CONTEXT_RULE,
                "copyCount": r["copyCount"], "versionCount": r["versionCount"],
                "carriedBy": r["carriedBy"], "variants": rows,
            }
            vdir.mkdir(parents=True, exist_ok=True)
            write_text(vdir / "index.json", sharding.dump_manifest(payload))
            multi.append(r)

        sel = {}
        for v in r["versions"]:
            for ctx in v["appliesTo"]:
                sel[ctx] = v
        base = sel.get(BASE_CONTEXT)
        others = {k: v for k, v in sel.items() if k != BASE_CONTEXT}
        if base and any(v["sha256"] != base["sha256"] for v in others.values()):
            contested.append({
                "table": r["table"],
                "baseContext": BASE_CONTEXT,
                "baseArchive": base["archive"], "baseSha256": base["sha256"],
                "baseRows": base["rows"], "basePath": base["path"],
                "overlayContexts": sorted(others),
                "overlayArchive": sorted({v["archive"] for v in others.values()}),
                "overlayRows": sorted({v["rows"] for v in others.values()}),
                "chainWinnerArchive": next(v["archive"] for v in r["versions"]
                                           if v["chainWinner"]),
                "chainWinnerRows": next(v["rows"] for v in r["versions"]
                                        if v["chainWinner"]),
                "rowDeltaBaseMinusWinner": base["rows"] - next(
                    v["rows"] for v in r["versions"] if v["chainWinner"]),
            })

    # tables that lost their variants block (a table that vanished, or one whose
    # directory the decode rebuilt) must not keep a stale variants directory
    known = {r["table"] for r in records}
    for d in sorted(out_dir.iterdir()):
        if not d.is_dir() or d.name.startswith("_"):
            continue
        vdir = d / VARIANT_SUBDIR
        if not vdir.is_dir():
            continue
        keep = {v["slug"] for r in records if r["table"] == d.name
                for v in r["versions"] if not v["chainWinner"]}
        if d.name not in known:
            keep = set()
        for sub in sorted(vdir.iterdir()):
            if sub.is_dir() and sub.name not in keep:
                for f in sorted(sub.rglob("*")):
                    if f.is_file():
                        f.unlink()
                sub.rmdir()

    total_versions = sum(r["versionCount"] for r in records)
    payload = {
        "note": "Every table the client ships in more than one version, and "
                "which chain context selects each. Tables absent from this list "
                "have exactly one version, already decoded at raw/tables/<T>/. "
                "Read `contextRule` before reading `appliesTo`: a version is not "
                "'the' table, it is the table SOME client configuration reads.",
        "generatedBy": "python -m tools.variants",
        "variantRule": VARIANT_RULE,
        "contextRule": CONTEXT_RULE,
        "fingerprintRule": FINGERPRINT_RULE,
        "readerRule": READER_RULE,
        "failureStatusRule": (
            "`status` is tools/mpq.py's classification of the member, so a copy "
            "that is NOT a table is reported as what the archive says it is. "
            "`deleted` is an MPQ DELETE_MARKER tombstone - the patch REMOVES "
            "the path, which is archive semantics and not a read failure, and "
            "every one of them is enumerated in raw/recovered/deleted/. "
            "`empty` is a real entry holding zero bytes, enumerated in "
            "raw/recovered/empty/. Only `error` and `unstable` are reads that "
            "actually failed."),
        "failuresByStatus": dict(sorted(collections.Counter(
            f.get("status", "error") for f in failures).items())),
        "clientDir": str(config.CLIENT_DIR),
        "tableDir": TABLE_DIR.replace("\\", "/"),
        "contexts": [{"context": c["context"],
                      "archives": sorted(c["archives"],
                                         key=lambda a: meta[a]["chainRank"])}
                     for c in contexts],
        "carrierArchives": sorted(
            {a for r in records for a in r["carriedBy"]},
            key=lambda a: meta[a]["chainRank"]),
        "pathCount": len(records),
        "copyCount": sum(r["copyCount"] for r in records),
        "versionCount": total_versions,
        "tablesWithOneVersion": len(records) - len(multi),
        "tablesWithVariants": len(multi),
        "variantsBeyondWinner": total_versions - len(records),
        "variantRowsDecoded": added_rows,
        "variantStoredBytes": added_stored,
        "realmContestedCount": len(contested),
        "realmContested": sorted(contested, key=lambda r: r["table"].lower()),
        "failureCount": len(failures),
        "failures": sorted(failures, key=lambda f: (f.get("path", ""),
                                                    f.get("table", ""),
                                                    f.get("archive", ""))),
        "tables": [{
            "table": r["table"], "file": r["file"],
            "copyCount": r["copyCount"], "versionCount": r["versionCount"],
            "carriedBy": r["carriedBy"],
            "variants": [_version_record(v) for v in r["versions"]],
        } for r in sorted(multi, key=lambda r: r["table"].lower())],
    }
    write_text(VARIANTS_JSON, sharding.dump_manifest(payload))
    # The layer index describes the winners; without this it does not say that
    # there ARE other versions, and a consumer reading only that file would
    # never learn it is holding one of several.
    lpath = out_dir / "index.json"
    if lpath.is_file():
        layer = json.loads(lpath.read_bytes().decode("utf-8"))
        layer.update({
            "variantIndex": VARIANTS_JSON.name,
            "variantRule": VARIANT_RULE,
            "tablesWithVariants": payload["tablesWithVariants"],
            "variantCount": payload["variantsBeyondWinner"],
            "variantRows": payload["variantRowsDecoded"],
            "variantStoredBytes": payload["variantStoredBytes"],
            "realmContestedTables": [r["table"] for r in payload["realmContested"]],
        })
        write_text(lpath, sharding.dump_manifest(layer))
    # raw/tables/README.md stays owned by tools/decode_all.py - it is simply
    # regenerated now that _variants.json exists, so the layer's own
    # documentation describes the layer that is actually on disk.
    write_readme(out_dir)
    return payload


# --------------------------------------------------------------------------
# driver
# --------------------------------------------------------------------------
def run(out_dir: Path = None, resume: bool = True, verbose: bool = True) -> dict:
    out_dir = out_dir or TABLES_DIR
    t0 = time.time()
    prov = load_provenance()
    if not prov or not layerstate.is_complete(WINNER_DIR):
        raise SystemExit(
            "FATAL: no complete extraction at work/dbc_all - run "
            "`python -m tools.decode_all` first; this module extends that "
            "layer, it does not replace it.")
    if not layerstate.is_complete(out_dir):
        raise SystemExit(
            f"FATAL: {out_dir} has no completion sentinel - run "
            "`python -m tools.decode_all` first.")

    CHECKPOINT_DIR.mkdir(parents=True, exist_ok=True)
    WORK_DIR.mkdir(parents=True, exist_ok=True)

    if verbose:
        print(f"client: {config.CLIENT_DIR}", flush=True)
    carriers, archives, meta, unlistable, probes = resolve_copies(verbose)
    if not carriers:
        raise SystemExit(f"FATAL: no paths under {TABLE_DIR!r} in any archive.")

    slugs = {}
    for aid in meta:
        s = slug(aid)
        if s in slugs:
            raise VariantError(f"archive slug collision: {aid} and {slugs[s]}")
        slugs[s] = aid

    contexts = build_contexts(meta)
    if verbose:
        print(f"  {len(carriers)} paths, "
              f"{sum(len(c['copies']) for c in carriers.values())} copies, "
              f"{len(contexts)} chain contexts", flush=True)

    hashes, hash_failures = hash_all(carriers, meta, verbose)
    records, group_failures = group_versions(
        carriers, hashes, meta, contexts, prov,
        already={(f["path"], f["archive"]) for f in hash_failures})
    failures = hash_failures + group_failures

    # The sentinel goes down BEFORE the first byte of the layer changes and is
    # written back only once every version is on disk and every index patched.
    prior = layerstate.read(out_dir)
    layerstate.begin(out_dir)
    failures += decode_versions(records, meta, out_dir, resume, verbose)
    payload = write_records(records, out_dir, contexts, meta, failures, verbose)
    prior.pop("rule", None)
    prior.update({
        "variantTableCount": payload["tablesWithVariants"],
        "variantCount": payload["variantsBeyondWinner"],
        "variantRowCount": payload["variantRowsDecoded"],
        "variantFailureCount": payload["failureCount"],
    })
    layerstate.finish(out_dir, prior)
    payload["elapsed"] = round(time.time() - t0, 1)
    payload["unlistableArchives"] = sorted(u["archive"] for u in unlistable)
    payload["unlistableProbe"] = probes
    return payload


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--no-resume", action="store_true",
                    help="re-decode every variant even if its bytes are unchanged")
    ap.add_argument("--out", type=Path, help="write somewhere else than raw/tables")
    ap.add_argument("-q", "--quiet", action="store_true")
    a = ap.parse_args()
    p = run(out_dir=a.out, resume=not a.no_resume, verbose=not a.quiet)
    print("\n=== VARIANTS ===")
    print(f"paths            {p['pathCount']}  ({p['copyCount']} copies in the chain)")
    print(f"versions         {p['versionCount']}  "
          f"({p['variantsBeyondWinner']} beyond the chain winners)")
    print(f"tables affected  {p['tablesWithVariants']} of {p['pathCount']}")
    print(f"realm-contested  {p['realmContestedCount']}")
    print(f"added            {p['variantRowsDecoded']:,} rows, "
          f"{p['variantStoredBytes']/1e6:.1f} MB stored")
    print(f"failures         {p['failureCount']}")
    print(f"elapsed          {p['elapsed']}s")


if __name__ == "__main__":
    main()
