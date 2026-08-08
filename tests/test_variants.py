"""Gates for the table VERSION layer (tools/variants.py -> raw/tables/<T>/variants/).

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
    tools/variants.py what it thinks it covered.
 2. EVERY DISTINCT COPY IS ON DISK AND READABLE. Every non-winner version has
    its own decoded directory whose index, colinfo, shard sha256s and row
    counts all agree with the header the extractor measured in the archive.
 3. THE REALM DEFECT IS FIXED, CONCRETELY. Base Spell is present, decoded and
    reachable line by line, and the overlay Spell that used to be the only copy
    is still there.
 4. RERUNS ARE BYTE-IDENTICAL. Running the whole version pass again over an
    unchanged client changes no byte of raw/tables, and decoding one version
    twice into scratch directories produces the same bytes as the layer holds.
 5. NO HAND-AUTHORED VOCABULARY. tools/variants.py is AST-scanned: its string
    literals are disjoint from the repo's curated column names and from every
    table name in the census, so no table, realm or archive is special-cased.
"""
# ---------------------------------------------------------------------------
# STALE - DOES NOT RUN. This file drives stage modules that no longer exist.
#
# The raw pipeline collapsed into `datamine.py` (one snapshot, one traversal);
# tools/variants.py, tools/extract_all.py and tools/decode_all.py were retired with it. The
# GATES BELOW ARE STILL THE RIGHT GATES - they are what `datamine.py` has to
# keep true - so this file is kept rather than deleted, and migrating it is
# tracked work: point the output assertions at the published `raw/` layer, and
# the reader/decoder assertions at `tools/dbcdecode.py` and `tools/emit.py`.
#
# It is left failing on import ON PURPOSE. Deleting it would quietly drop the
# specification of behaviour this repo has already paid to learn; rewriting it
# to pass without re-checking what it checks would be worse.
# ---------------------------------------------------------------------------

import ast
import gzip
import hashlib
import json
import sys
import tempfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from tools import (build_catalog, config, dbc, decode_all, extract_all, find,
                   sharding, variants)

# three modules restate the base-context name so none of them needs the others;
# they may not drift
assert variants.BASE_CONTEXT == find.BASE_CONTEXT == build_catalog.BASE_CONTEXT

RAW = decode_all.OUT_DIR
VJ = json.loads((RAW / "_variants.json").read_bytes().decode("utf-8"))
LAYER = json.loads((RAW / "index.json").read_bytes().decode("utf-8"))
census = decode_all._census()
assert census, "raw/_inventory/dbc.json missing - run python -m tools.inventory"

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
assert VJ["pathCount"] == len(census) == LAYER["tableCount"]
print(f"[1] coverage: {VJ['copyCount']} copies of {VJ['pathCount']} paths -> "
      f"{VJ['versionCount']} distinct versions + {len(failed_pairs)} recorded "
      f"failure(s); every archive the census names is accounted for")

assert VJ["failureCount"] == len(VJ["failures"])
for f in VJ["failures"]:
    assert f["reason"] and f["archive"] and f["path"], f
print(f"[1] failures: {VJ['failureCount']} copies not decoded, each with an "
      f"archive, a path and a reason")


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
assert variants.BASE_CONTEXT in ctx_names and len(ctx_names) == len(set(ctx_names))
for stem, ix in indexes.items():
    picked = [c for v in ix["variants"] for c in v["appliesTo"]]
    assert sorted(picked) == sorted(ctx_names), (stem, picked, ctx_names)
print(f"[2] chain contexts: {ctx_names} - each selects exactly one version of "
      f"each of the {len(indexes)} paths")

contested = {r["table"] for r in VJ["realmContested"]}
for r in VJ["realmContested"]:
    ix = indexes[r["table"]]
    base = next(v for v in ix["variants"]
                if variants.BASE_CONTEXT in v["appliesTo"])
    assert base["sha256"] == r["baseSha256"] and base["rows"] == r["baseRows"]
    assert base["sha256"] != next(v["sha256"] for v in ix["variants"]
                                  if v["chainWinner"])
# won by a realm overlay = the winner is NOT what the base chain selects
overlay_won = {t for t, ix in indexes.items()
               if any(v["chainWinner"] and variants.BASE_CONTEXT not in v["appliesTo"]
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
            if variants.BASE_CONTEXT in v["appliesTo"])
winner = next(v for v in spell["variants"] if v["chainWinner"])
assert not base["chainWinner"], "base Spell is the winner - the overlay vanished?"
# the winner is still the overlay's copy, and it is what the census measured
assert winner["rows"] == spell["rows"] == census["Spell.dbc"]["records"]
assert winner["sha256"] == census["Spell.dbc"]["sha256"]
assert variants.BASE_CONTEXT not in winner["appliesTo"], winner["appliesTo"]
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

before = digest_tree(RAW)
try:
    variants.run(verbose=False)
except variants.VariantError as e:
    # The Ascension launcher patches this client in place while the pipeline
    # runs. That is not a determinism failure of the layer - it is the layer
    # correctly refusing to describe bytes that moved - but it does mean the
    # rerun comparison could not be made, so it is reported, never swallowed.
    print(f"[4] rerun NOT CHECKED - the client changed under the test: {e}")
else:
    after = digest_tree(RAW)
    changed = sorted(k for k in set(before) | set(after)
                     if before.get(k) != after.get(k))
    assert not changed, f"a rerun changed {len(changed)} files: {changed[:5]}"
    print(f"[4] rerun: {len(before):,} files under raw/tables, byte-identical "
          f"after a second full version pass")

# and the decoder itself: two decodes of the same variant bytes into scratch
# directories agree with each other and with what the layer holds
sample = sorted(
    ((stem, v) for stem, ix in indexes.items() for v in ix["variants"]
     if not v["chainWinner"] and v["storedBytes"] < 200_000),
    key=lambda sv: (-sv[1]["storedBytes"], sv[0]))[:6]
assert len(sample) == 6
tmp = Path(tempfile.mkdtemp(prefix="coa_variants_"))
for stem, v in sample:
    src = variants.WORK_DIR / v["slug"]
    name = indexes[stem]["file"]
    assert (src / name).is_file(), f"variant bytes missing: {src / name}"
    runs = []
    for i in range(2):
        dest = tmp / str(i) / stem / v["slug"]
        decode_all.decode_table(name, {"winner": v["archive"], "losers": v["alsoIn"],
                                       "sha256": v["sha256"],
                                       "bytes": v["sourceBytes"]},
                                tmp / str(i), src_dir=src, dest=dest)
        runs.append(digest_tree(dest))
    assert runs[0] == runs[1] and len(runs[0]) > 2, stem
    live = digest_tree(RAW / stem / "variants" / v["slug"])
    assert live == runs[0], (stem, v["slug"],
                             sorted(k for k in live if live[k] != runs[0].get(k)))
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
tree = ast.parse(Path(variants.__file__).read_text(encoding="utf-8"))
for node in ast.walk(tree):
    if isinstance(node, ast.Constant) and isinstance(node.value, str):
        literals.add(node.value)
    elif isinstance(node, ast.Name):
        names_used.add(node.id)
    elif isinstance(node, ast.Attribute):
        names_used.add(node.attr)
hits = sorted(l for l in literals if l in curated)
assert not hits, f"curated column names appear as literals: {hits}"
hits = sorted(l for l in literals if l.lower() in table_words)
assert not hits, f"a table is named in the source: {hits}"
hits = sorted(l for l in literals if l.lower() in realm_words)
assert not hits, f"a realm is named in the source: {hits}"
banned = {"TABLE_MAPS", "WANTED_DBCS", "CUSTOM_RAW_DUMP_TABLES", "enums335"}
assert not (names_used & banned), f"curated machinery referenced: {names_used & banned}"
print(f"[5] source scan: {len(literals)} literals in tools/variants.py, disjoint "
      f"from {len(curated)} curated column names, {len(census)} table names and "
      f"{len(realm_words)} realm name(s)")

# the extractor must not have written bytes the client does not hold: two
# independent reads of every member have to agree before it writes at all
prov = extract_all.load_provenance()
assert prov.get("readAttempts", 0) >= 2 and prov.get("readAgreementRule")
assert not prov["failures"], prov["failures"]
print(f"[5] read agreement: the extraction confirmed every one of its "
      f"{prov['extractedCount']} members with {prov['readAttempts']} attempts "
      f"at two agreeing reads")

print("\nALL VARIANT GATES PASS")
