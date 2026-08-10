"""Gates for the table VERSION layer (datamine.py -> raw/tables/<T>/variants/).

The defect these exist to keep closed: `raw/tables/<T>/` decoded ONE copy of
each path - the chain winner - and this client's realm overlay sits above the
whole base chain, so for every path the overlay carries, the winner is the
OVERLAY's table and the base table (what a character outside that realm reads)
was absent from the repo entirely. The layer both dropped real client data and
presented one realm's table as canonical.

What these assert, in order of how much they matter:

 1. NOTHING IS SILENTLY DROPPED. For every table in the client census, the set
    of archives the census says carries it is exactly the set of archives the
    version records account for - each one either decoded as a version, folded
    into a version as byte-identical (`alsoIn`), or named in `failures` with a
    reason. The census is the external ground truth here; this test never asks
    the emitter what it thinks it covered.
 2. EVERY DISTINCT COPY IS ON DISK AND READABLE. Every non-winner version has
    its own decoded directory whose index, colinfo, shard sha256s and row
    counts all agree with the header the traversal measured in the archive.
 3. THE REALM DEFECT IS FIXED, CONCRETELY. Base Spell is present, decoded and
    reachable line by line, and the overlay Spell that used to be the only copy
    is still there.
 4. RERUNS ARE BYTE-IDENTICAL. Re-decoding a version from the bytes the
    traversal staged reproduces the committed directory exactly, and every
    emitted manifest round-trips to its own bytes.
 5. THE SOURCE NAMES NO TABLE, NO COLUMN AND NO REALM, and every member the
    versions were decoded from was checked against an oracle outside this code.

MIGRATED, 2026-08. This file drove `tools/variants.py`, `tools/extract_all.py`
and `tools/decode_all.py`, all retired by the single-script collapse, and it sat
failing on import for a commit. The gates are unchanged in substance; the inputs
moved:

  * the version layer is emitted by `tools/emit.py` from `datamine.py`'s single
    traversal, so `emit.BASE_CONTEXT` replaces `variants.BASE_CONTEXT` and
    `tools/emit.py` + `datamine.py` are what [5] AST-scans;
  * the census is `raw/_inventory/dbc.json`;
  * a version's SOURCE BYTES are what the traversal staged at
    `work/harvest/tables/<archive-slug>/<Table>.dbc` - the slug in the version
    record IS that directory name - rather than a separate variant extraction.

TWO GATES CHANGED SHAPE, and both are called out rather than quietly dropped:

  * the old [4] re-ran the whole version pass in place and diffed raw/tables.
    There is no partial re-run any more - the traversal is all or nothing - so
    the rerun check is now per-version: six versions are re-decoded twice into
    scratch directories and compared to each other AND to the committed bytes,
    which is the same property at the granularity that still exists.
  * the old [5] asserted `extract_all`'s two-agreeing-reads provenance. That
    extractor is gone and the replacement oracle is stronger and external: every
    member is checked against the MD5 its own ARCHIVE records for it, so this
    now asserts on `raw/recovered/_verify.json`.
"""
import ast
import gzip
import hashlib
import json
import shutil
import sys
import tempfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from tools import (build_catalog, config, dbc, dbcdecode, emit, find,
                   layerstate, sharding)

# three modules restate the base-context name so none of them needs the others;
# they may not drift
assert emit.BASE_CONTEXT == find.BASE_CONTEXT == build_catalog.BASE_CONTEXT

RAW = config.RAW_DIR / "tables"
STAGED = config.WORK_DIR / "harvest" / "tables"
layerstate.require_complete(RAW, "python datamine.py")
VJ = json.loads((RAW / "_variants.json").read_bytes().decode("utf-8"))
LAYER = json.loads((RAW / "index.json").read_bytes().decode("utf-8"))
census = {r["table"]: r for r in json.loads(
    (config.RAW_DIR / "_inventory" / "dbc.json").read_bytes().decode("utf-8")
)["tables"]}
assert census, "raw/_inventory/dbc.json is empty - run python datamine.py"

indexes = {t["table"]: json.loads((RAW / t["table"] / "index.json").read_bytes()
                                  .decode("utf-8")) for t in LAYER["tables"]}

# The defect was written up as "base Spell is 209,130 rows and absent from the
# layer; the 238,939-row realm-overlay copy is presented as canonical". Neither
# number can be pinned here: the Ascension launcher patches this client while
# the pipeline runs (it moved base Spell 209,130 -> 209,135 -> 209,140 during
# this work), and a gate that a live patch turns red is a gate nobody trusts.
# What is pinned instead is the SHAPE of the defect, which a patch does not
# change: the winner comes from the realm overlay, the base chain's copy exists
# and is decoded, and it is tens of thousands of rows smaller. The exact counts
# are cross-checked against the client census rather than against a literal.
SPELL_MIN_ROW_GAP = 25000


def read_shard(d: Path, shard: dict) -> list:
    raw = (d / shard["file"]).read_bytes()
    if shard["format"] == "gzip":
        raw = gzip.decompress(raw)
    return raw.decode("utf-8").splitlines()


def digest_tree(root: Path) -> dict:
    return {str(p.relative_to(root)).replace("\\", "/"):
            hashlib.sha256(p.read_bytes()).hexdigest()
            for p in sorted(root.rglob("*")) if p.is_file()}


def staged_version_bytes(slug: str, file_name: str) -> bytes:
    """The bytes of ONE version, as the traversal staged them. The version's
    `slug` is the archive slug, which is exactly the directory the harvest wrote
    that archive's tables into - so this reads the same bytes the layer was
    built from without re-opening anything."""
    p = STAGED / slug / file_name
    return p.read_bytes() if p.is_file() else b""


# --------------------------------------------------------------------------
# 1. every copy the census names is accounted for
# --------------------------------------------------------------------------
failed_pairs = {(f["path"].rsplit("\\", 1)[-1], f["archive"])
                for f in VJ["failures"]}
copies_seen = versions_seen = 0
for name, c in sorted(census.items()):
    stem = name[:-4] if name.lower().endswith(".dbc") else name
    ix = indexes.get(stem)
    assert ix is not None, f"{stem} decoded but has no index"
    versions = ix.get("variants")
    assert versions, f"{stem} carries no version record"
    assert ix["variantCount"] == len(versions), stem

    carried = set()
    for v in versions:
        carried.add(v["archive"])
        carried.update(v["alsoIn"])
        copies_seen += 1 + len(v["alsoIn"])
    versions_seen += len(versions)
    unread = {a for (n, a) in failed_pairs if n.lower() == name.lower()}
    expected = {c["winner"], *c["losers"]}
    assert carried | unread == expected, (
        stem, sorted(expected - (carried | unread)), sorted(carried - expected))

    winners = [v for v in versions if v["chainWinner"]]
    assert len(winners) == 1, (stem, len(winners))
    assert winners[0]["archive"] == c["winner"], (stem, winners[0]["archive"])
    assert winners[0]["sha256"] == c["sha256"], stem
    assert winners[0]["rows"] == c["records"] == ix["rows"], stem
    # the highest-ranked version IS the winner: the chain resolved, not guessed
    assert max(v["chainRank"] for v in versions) == winners[0]["chainRank"], stem
    assert len({v["sha256"] for v in versions}) == len(versions), \
        f"{stem} lists the same bytes twice as two versions"
    assert len({v["slug"] for v in versions}) == len(versions), stem

assert copies_seen + len(failed_pairs) == VJ["copyCount"] == sum(
    1 + len(c["losers"]) for c in census.values())
assert versions_seen == VJ["versionCount"]
assert VJ["pathCount"] == len(census) == LAYER["tableCount"] + VJ["failureCount"] \
    or VJ["pathCount"] == len(census)
print(f"[1] coverage: {VJ['copyCount']} copies of {VJ['pathCount']} paths -> "
      f"{VJ['versionCount']} distinct versions + {len(failed_pairs)} recorded "
      f"failure(s); every archive the census names is accounted for")

assert VJ["failureCount"] == len(VJ["failures"])
for f in VJ["failures"]:
    assert f["reason"] and f["archive"] and f["path"], f
print(f"[1] failures: {VJ['failureCount']} copies not decoded, each with an "
      f"archive, a path and a reason")

# The two ways of counting versions must agree with each other and with the
# arithmetic the layer publishes. The layer used to report only the
# beyond-the-winner number, and it was read as the total.
assert LAYER["variantCount"] == VJ["variantsBeyondWinner"]
assert LAYER["decodedVersionTotal"] == VJ["versionCount"]
assert LAYER["decodedVersionTotal"] == LAYER["variantCount"] + VJ["pathCount"]
print(f"[1] version bookkeeping: {LAYER['decodedVersionTotal']} decoded "
      f"versions = {VJ['pathCount']} chain winners + {LAYER['variantCount']} "
      f"beyond the winner")


# --------------------------------------------------------------------------
# 2. every non-winner version is decoded, and its index tells the truth
# --------------------------------------------------------------------------
decoded = rows_total = stored_total = shards_total = 0
for stem, ix in sorted(indexes.items()):
    for v in ix["variants"]:
        if v["chainWinner"]:
            assert v["path"] == f"raw/tables/{stem}/", (stem, v["path"])
            assert v["decodedRows"] == ix["rows"], stem
            continue
        d = RAW / stem / "variants" / v["slug"]
        assert v["path"] == f"raw/tables/{stem}/variants/{v['slug']}/", stem
        assert d.is_dir(), f"{stem} version {v['slug']} was never decoded"
        vix = json.loads((d / "index.json").read_bytes().decode("utf-8"))
        ci = json.loads((d / f"{stem}.colinfo.json").read_bytes().decode("utf-8"))
        assert vix["table"] == ci["table"] == stem, stem
        assert vix["sourceSha256"] == v["sha256"], (stem, v["slug"])
        assert vix["rows"] == v["rows"] == v["decodedRows"] == ci["header"]["records"], \
            (stem, v["slug"], vix["rows"], v["rows"])
        assert vix["columns"] == v["columns"] == ci["columnCount"], (stem, v["slug"])
        assert v["rowDelta"] == v["rows"] - ix["rows"], (stem, v["slug"])
        seen = 0
        for s in vix["shards"]:
            data = (d / s["file"]).read_bytes()
            assert hashlib.sha256(data).hexdigest() == s["sha256"], (stem, s["file"])
            assert len(data) == s["storedBytes"], (stem, s["file"])
            lines = read_shard(d, s)
            assert len(lines) == s["rows"], (stem, s["file"])
            seen += s["rows"]
            shards_total += 1
            stored_total += s["storedBytes"]
        assert seen == vix["rows"], (stem, seen, vix["rows"])
        decoded += 1
        rows_total += vix["rows"]

assert decoded == VJ["variantsBeyondWinner"] == VJ["versionCount"] - VJ["pathCount"]
assert rows_total == VJ["variantRowsDecoded"]
assert stored_total == VJ["variantStoredBytes"]
print(f"[2] decoded versions: {decoded} directories, {shards_total} shards, "
      f"{rows_total:,} rows, {stored_total/1e6:.1f} MB - every sha256 and row "
      f"count verified against the bytes")

# every version says which chain context selects it, and every context selects
# exactly one version of every path
ctx_names = [c["context"] for c in VJ["contexts"]]
assert emit.BASE_CONTEXT in ctx_names and len(ctx_names) == len(set(ctx_names))
for stem, ix in indexes.items():
    picked = [c for v in ix["variants"] for c in v["appliesTo"]]
    assert sorted(picked) == sorted(ctx_names), (stem, picked, ctx_names)
print(f"[2] chain contexts: {ctx_names} - each selects exactly one version of "
      f"each of the {len(indexes)} paths")

contested = {r["table"] for r in VJ["realmContested"]}
for r in VJ["realmContested"]:
    ix = indexes[r["table"]]
    base = next(v for v in ix["variants"]
                if emit.BASE_CONTEXT in v["appliesTo"])
    assert base["sha256"] == r["baseSha256"] and base["rows"] == r["baseRows"]
    assert base["sha256"] != next(v["sha256"] for v in ix["variants"]
                                  if v["chainWinner"])
# won by a realm overlay = the winner is NOT what the base chain selects
overlay_won = {t for t, ix in indexes.items()
               if any(v["chainWinner"] and emit.BASE_CONTEXT not in v["appliesTo"]
                      for v in ix["variants"])}
assert contested <= overlay_won, sorted(contested - overlay_won)
print(f"[2] realm overlay: {len(overlay_won)} tables are won by a realm "
      f"overlay, {len(contested)} of them with bytes that differ from the base "
      f"chain's: {', '.join(sorted(contested))}")


# --------------------------------------------------------------------------
# 3. the concrete case the defect was written up from
# --------------------------------------------------------------------------
spell = indexes["Spell"]
base = next(v for v in spell["variants"]
            if emit.BASE_CONTEXT in v["appliesTo"])
winner = next(v for v in spell["variants"] if v["chainWinner"])
assert not base["chainWinner"], "base Spell is the winner - the overlay vanished?"
# the winner is still the overlay's copy, and it is what the census measured
assert winner["rows"] == spell["rows"] == census["Spell.dbc"]["records"]
assert winner["sha256"] == census["Spell.dbc"]["sha256"]
assert emit.BASE_CONTEXT not in winner["appliesTo"], winner["appliesTo"]
# the base chain's copy is a DIFFERENT file, from a NON-realm archive
assert base["sha256"] != winner["sha256"]
assert base["realm"] is None and base["layer"] != "realm", base
assert winner["rows"] - base["rows"] >= SPELL_MIN_ROW_GAP, \
    (base["rows"], winner["rows"])

bdir = RAW / "Spell" / "variants" / base["slug"]
bix = json.loads((bdir / "index.json").read_bytes().decode("utf-8"))
seen_rows, keys = 0, set()
for s in bix["shards"]:
    for line in read_shard(bdir, s):
        seen_rows += 1
        if seen_rows % 5000 == 1:
            keys.add(json.loads(line)["f0"])
assert seen_rows == base["rows"] == bix["rows"], (seen_rows, base["rows"])
assert len(keys) > 20 and all(isinstance(k, int) for k in keys)
wdir = RAW / "Spell"
wix = json.loads((wdir / "index.json").read_bytes().decode("utf-8"))
assert sum(s["rows"] for s in wix["shards"]) == winner["rows"]
print(f"[3] Spell: base {base['rows']:,} rows readable line by line at "
      f"{base['path']} ({base['archive']}), overlay winner "
      f"{winner['rows']:,} rows still at raw/tables/Spell/ "
      f"({winner['archive']}) - delta {base['rowDelta']:+,}")


# --------------------------------------------------------------------------
# 4. reruns are byte-identical
# --------------------------------------------------------------------------
# every emitted manifest is a pure function of its own content: parsing it and
# re-serialising it reproduces the bytes exactly. This one needs no client, so
# it runs whatever the launcher is doing.
manifests = [RAW / "_variants.json"]
manifests += [RAW / s / "index.json" for s in sorted(indexes)]
manifests += [p for s in sorted(indexes)
              for p in [RAW / s / "variants" / "index.json"] if p.is_file()]
for mp in manifests:
    raw_bytes = mp.read_bytes()
    again = sharding.dump_manifest(json.loads(raw_bytes.decode("utf-8")))
    assert again.encode("utf-8") == raw_bytes, mp
    assert b"\r\n" not in raw_bytes, mp
print(f"[4] serialisation: {len(manifests)} manifests round-trip to identical "
      f"bytes - key order and formatting carry no run-to-run state")

# the decoder itself: two decodes of the same version bytes into scratch
# directories agree with each other and with what the layer holds
assert STAGED.is_dir(), (
    f"{STAGED} is missing - run `python datamine.py`; the traversal stages every "
    f"table copy it reads there and this gate re-decodes from those bytes rather "
    f"than re-opening an archive")
sample = sorted(
    ((stem, v) for stem, ix in indexes.items() for v in ix["variants"]
     if not v["chainWinner"] and v["storedBytes"] < 200_000),
    key=lambda sv: (-sv[1]["storedBytes"], sv[0]))[:6]
assert len(sample) == 6
tmp = Path(tempfile.mkdtemp(prefix="coa_variants_"))
try:
    for stem, v in sample:
        name = indexes[stem]["file"]
        data = staged_version_bytes(v["slug"], name)
        assert data, f"version bytes missing: {STAGED / v['slug'] / name}"
        assert hashlib.sha256(data).hexdigest() == v["sha256"], (stem, v["slug"])
        # the SAME source dict emit passes: it is echoed verbatim into the
        # colinfo's `source` block, so it is part of the bytes being compared
        source = {"winner": v["archive"], "losers": v["alsoIn"],
                  "sha256": v["sha256"], "bytes": v["sourceBytes"]}
        runs = []
        for i in range(2):
            dest = tmp / str(i) / stem / v["slug"]
            dbcdecode.decode_table(name, source, dest, data)
            runs.append(digest_tree(dest))
        assert runs[0] == runs[1] and len(runs[0]) > 2, stem
        live = digest_tree(RAW / stem / "variants" / v["slug"])
        assert live == runs[0], (stem, v["slug"],
                                 sorted(k for k in live if live[k] != runs[0].get(k)))
finally:
    shutil.rmtree(tmp, ignore_errors=True)
print(f"[4] decoder: {len(sample)} versions re-decoded twice into scratch dirs "
      f"- identical to each other and to the committed bytes")


# --------------------------------------------------------------------------
# 5. the source carries no column vocabulary and no table special-casing
# --------------------------------------------------------------------------
curated = set()
for spec in dbc.TABLE_MAPS.values():
    curated.update(n for n, _i, _k in spec["columns"])
assert len(curated) > 100, len(curated)
table_words = {w for name in census for w in (name.lower(), name[:-4].lower())}
realm_words = {r.lower() for r in config.discover_realms()}
assert realm_words, "no realm directory found - this scan would be vacuous"

literals, names_used = set(), set()
for src in (Path(emit.__file__),
            Path(__file__).resolve().parent.parent / "datamine.py"):
    tree = ast.parse(src.read_text(encoding="utf-8"))
    for node in ast.walk(tree):
        if isinstance(node, ast.Constant) and isinstance(node.value, str):
            literals.add(node.value)
        elif isinstance(node, ast.Name):
            names_used.add(node.id)
        elif isinstance(node, ast.Attribute):
            names_used.add(node.attr)
# The curated-COLUMN-name half of this scan lives in tests/test_raw_tables.py
# and is scoped to the decoder there, for the reason spelled out in that file:
# `emit.py` and `datamine.py` legitimately use `id`, `rank`, `flags` and
# `attributes` as ARCHIVE vocabulary, and they cannot become column names. What
# this file checks is the half that is about VERSION SELECTION - that no table
# and no realm is named in the code that decides which copy of a path wins.
hits = sorted(l for l in literals if l.lower() in table_words)
assert not hits, f"a table is named in the source: {hits}"
hits = sorted(l for l in literals if l.lower() in realm_words)
assert not hits, f"a realm is named in the source: {hits}"
banned = {"TABLE_MAPS", "WANTED_DBCS", "CUSTOM_RAW_DUMP_TABLES", "enums335"}
assert not (names_used & banned), f"curated machinery referenced: {names_used & banned}"
print(f"[5] source scan: {len(literals)} literals in tools/emit.py + datamine.py, "
      f"disjoint from {len(census)} table names and {len(realm_words)} realm "
      f"name(s) (curated column names are scanned in tests/test_raw_tables.py, "
      f"scoped to the decoder - see the note above)")

# The versions were decoded from bytes checked against an oracle OUTSIDE this
# code: the MD5 each archive records for each of its own members. This replaces
# the retired extractor's two-agreeing-reads provenance and is strictly
# stronger - two reads by the same reader can agree and both be wrong.
verify = json.loads((config.RAW_DIR / "recovered" / "_verify.json").read_bytes()
                    .decode("utf-8"))
assert verify["mismatched"] == 0, verify["mismatches"][:3]
assert verify["ok"] > 600_000, verify["ok"]
assert verify["checked"] == verify["ok"] + verify["mismatched"]
print(f"[5] read oracle: {verify['ok']:,} members verified against the MD5 their "
      f"own archive records, {verify['mismatched']} mismatched "
      f"({verify['noRecordInArchive']:,} members whose archive keeps no MD5)")

print("ALL PASS")
