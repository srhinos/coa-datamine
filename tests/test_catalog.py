"""Gate for the generated search catalog (CATALOG.md + raw/_catalog/*).

What this proves, in order of how much it would hurt to get wrong:

[1] The catalog is COMPLETE. It describes every table and every column the
    decode produced - 368/368 and 6,662/6,662, cross-checked against
    raw/tables/index.json rather than against itself. A catalog that quietly
    covers a subset is exactly the failure the raw layer exists to end.
[2] Nothing is hand-authored. Both modules are AST-scanned: their string
    literals must be disjoint from every column name the curated layer ever
    asserted (tools/dbc.TABLE_MAPS) and from every table name, so no table is
    special-cased and no column is given a meaning.
[3] The join arithmetic is EARNED, not asserted. Candidates are re-derived here
    from the shards by an independent implementation and must agree to the
    digit - containment, matched, inSpan and lift.
[4] The samples trap is closed: `samples` may ride only on columns the decode
    called a string, because a string-hypothesis decode of an int column is
    bytes, not content, and reading it as content is how this repo produced
    confidently wrong answers before.
[5] find.py is exhaustive and correct: goldens in a huge table and in a tiny
    one, so a scan that silently skipped either would fail.
[6] Determinism + line caps + LF bytes: the catalog regenerates byte-identically
    and no generated file exceeds the 5,000-line rule.
"""
import ast
import hashlib
import json
import re
import sys
import tempfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from tools import build_catalog as bc
from tools import dbc, find

REPO = Path(__file__).resolve().parent.parent
GENERATED = {
    "CATALOG.md": bc.CATALOG_MD,
    "tables.json": bc.CATALOG_DIR / "tables.json",
    "joins.json": bc.CATALOG_DIR / "joins.json",
    "strings.json": bc.CATALOG_DIR / "strings.json",
}
SHARD_MAX_LINES = 5000

for label, path in GENERATED.items():
    assert path.exists(), f"{label} has not been generated: run tools.build_catalog"

layer = bc.layer_index()
tables = bc.load_json(GENERATED["tables.json"])
joins = bc.load_json(GENERATED["joins.json"])
strings = bc.load_json(GENERATED["strings.json"])
catalog_md = GENERATED["CATALOG.md"].read_bytes().decode("utf-8")


# ==========================================================================
# [1] complete coverage, checked against the layer and not against itself
# ==========================================================================
layer_tables = {t["table"] for t in layer["tables"]}
cat_tables = {t["table"] for t in tables["tables"]}
assert cat_tables == layer_tables, sorted(cat_tables ^ layer_tables)
assert tables["tableCount"] == layer["tableCount"] == len(layer_tables)

total_columns = 0
for t in tables["tables"]:
    ci = bc.colinfo(t["table"])
    detail = t["columnDetail"]
    assert len(detail) == ci["columnCount"] == t["columns"], t["table"]
    assert [c["name"] for c in detail] == [c["name"] for c in ci["columns"]], t["table"]
    assert [c["inferred"] for c in detail] == [c["inferred"] for c in ci["columns"]]
    total_columns += len(detail)
assert total_columns == tables["columnCount"]
assert total_columns == sum(sum(t["inferredCounts"].values()) for t in tables["tables"])

# every table is either a join target or explicitly listed as having no int key
assert joins["targetTables"] + len(tables["tablesWithoutIntegerKey"]) == len(layer_tables)

# every table in the layer is a row of the markdown, and the markdown invites
# no edits
assert "never hand-edit" in catalog_md.lower()
md_rows = set(re.findall(r"^\| \*\*(.+?)\*\* \|", catalog_md, re.M))
assert md_rows == layer_tables, sorted(md_rows ^ layer_tables)
print(f"[1] coverage: {len(cat_tables)} tables, {total_columns:,} columns, "
      f"{len(md_rows)} markdown rows - equal to the layer")


# ==========================================================================
# [2] no hand-authored vocabulary, no table special-cased
# ==========================================================================
curated_names = set()
for spec in dbc.TABLE_MAPS.values():
    curated_names.update(name for name, _idx, _kind in spec["columns"])
assert len(curated_names) > 100, len(curated_names)

table_words = set()
for name in layer_tables:
    table_words.add(name.lower())
    table_words.add((name + ".dbc").lower())

MODULES = [REPO / "tools" / "build_catalog.py", REPO / "tools" / "find.py"]
literals, names_used = set(), set()
for path in MODULES:
    tree = ast.parse(path.read_bytes().decode("utf-8"))
    for node in ast.walk(tree):
        if isinstance(node, ast.Constant) and isinstance(node.value, str):
            literals.add(node.value)
        elif isinstance(node, ast.Name):
            names_used.add(node.id)
        elif isinstance(node, ast.Attribute):
            names_used.add(node.attr)

hits = sorted(l for l in literals if l in curated_names)
assert not hits, f"curated column names appear as literals: {hits}"
table_hits = sorted(l for l in literals if l.lower() in table_words)
assert not table_hits, f"a table is named in the source: {table_hits}"
banned = {"TABLE_MAPS", "iter_named", "dump_table", "dump_unmapped", "enums335",
          "WANTED_DBCS", "_spell_columns", "CUSTOM_RAW_DUMP_TABLES"}
assert not (names_used & banned), f"curated machinery referenced: {names_used & banned}"

# every emitted column name is positional
for t in tables["tables"]:
    for c in t["columnDetail"]:
        assert re.fullmatch(r"f\d+", c["name"]), (t["table"], c["name"])
for r in joins["columns"] + strings["columns"]:
    assert re.fullmatch(r"f\d+", r["column"]), r
print(f"[2] source scan: {len(literals)} literals vs {len(curated_names)} curated "
      f"column names and {len(layer_tables)} table names - disjoint")


# ==========================================================================
# [3] the join arithmetic is re-derived from the shards, independently
# ==========================================================================
def column_values(stem: str, col: str) -> set:
    """Distinct non-zero values of one column, read straight off the shards."""
    return {v for _, rec in bc.iter_records(stem)
            if (v := rec.get(col)) and type(v) is int}


def key_values(stem: str) -> set:
    out = set()
    for _, rec in bc.iter_records(stem):
        v = rec.get("f0")
        v = rec.get("f0i") if isinstance(v, str) else v
        if type(v) is int:
            out.add(v)
    return out


small = {t["table"] for t in layer["tables"] if t["rows"] < 20000}
sample = [r for r in joins["columns"] if r["table"] in small][:6]
assert len(sample) == 6, "not enough small tables to re-verify joins"

checked = 0
for r in sample:
    src = column_values(r["table"], r["column"])
    assert len(src) == r["sourceDistinct"], (r["table"], r["column"])
    ordered = sorted(src)
    for cand in r["candidates"]:
        if cand["table"] not in small:
            continue
        tgt = key_values(cand["table"])
        assert len(tgt) == cand["targetDistinct"], cand
        tmin, tmax = min(tgt), max(tgt)
        assert (tmin, tmax) == (cand["targetMin"], cand["targetMax"]), cand
        density = round(len(tgt) / (tmax - tmin + 1), 6)
        assert density == cand["targetDensity"], (cand, density)

        matched = len(src & tgt)
        in_span = sum(1 for v in ordered if tmin <= v <= tmax)
        assert matched == cand["matched"], cand
        assert in_span == cand["inSpan"], cand
        assert round(matched / len(src), 6) == cand["containment"], cand
        expected = in_span * density
        want = round(matched / expected, 4) if expected > 0 else None
        assert want == cand["lift"], (cand, want)
        assert cand["weakEvidence"] == (matched < bc.MIN_MATCHED_EVIDENCE), cand
        assert cand["containment"] >= bc.MIN_CONTAINMENT, cand
        checked += 1

assert checked >= 6, checked
# and the file never states a relation, only a rate
assert "NOTHING HERE IS A FOREIGN KEY" in joins["rule"]
for r in joins["columns"]:
    assert len(r["candidates"]) <= bc.TOP_K
    assert r["candidatesFound"] >= len(r["candidates"])
    assert r["sourceDistinct"] >= bc.MIN_SOURCE_DISTINCT
print(f"[3] join arithmetic: {checked} candidates re-derived from the shards - "
      f"containment, matched, inSpan and lift all agree")


# ==========================================================================
# [4] samples ride only on string columns; string samples are real values
# ==========================================================================
for t in tables["tables"]:
    for c in t["columnDetail"]:
        if c["inferred"] == "string":
            assert "samples" in c, (t["table"], c["name"])
        else:
            assert "samples" not in c, (
                f"{t['table']}.{c['name']} is {c['inferred']} but carries "
                "samples - a string-hypothesis decode of a non-string column "
                "is bytes, not content")

str_cols = {(r["table"], r["column"]) for r in strings["columns"]}
layer_str = {(t["table"], c["name"]) for t in tables["tables"]
             for c in t["columnDetail"] if c["inferred"] == "string"}
assert str_cols == layer_str, sorted(str_cols ^ layer_str)

verified = 0
for r in strings["columns"][:40]:
    if not r["samples"]:
        continue
    seen = {rec.get(r["column"]) for _, rec in bc.iter_records(r["table"])}
    missing = [s for s in r["samples"] if s not in seen]
    assert not missing, (r["table"], r["column"], missing[:3])
    if r["exhaustive"]:
        assert set(r["samples"]) == {v for v in seen if isinstance(v, str)}, r
    verified += 1
assert verified > 20, verified
print(f"[4] samples: {len(layer_str)} string columns catalogued, {verified} "
      f"re-read from the shards - every sample is a real value")


# ==========================================================================
# [5] find.py is exhaustive and correct
# ==========================================================================
TABLES = ["tables"]
res = find.find_string("Tide Lash", layers=TABLES)
cols = {(c["table"], c["column"]): c["rows"] for c in res["columns"]}
assert cols == {("Spell", "f136"): 5}, cols
assert {h["text"] for h in res["hits"]} == {"Tide Lash"}
spell_ids = sorted(h["rowKey"] for h in res["hits"])
assert len(spell_ids) == 5 and len(set(spell_ids)) == 5, spell_ids

# a tiny table: a scan that skipped small shards would miss this
res = find.find_string("POWER_TYPE_PYRITE", layers=TABLES)
assert ("PowerDisplay", "f2") in {(c["table"], c["column"]) for c in res["columns"]}

# case folding, and its opt-out
assert find.find_string("tide lash", layers=TABLES)["hitCount"] == 5
assert find.find_string("tide lash", ignore_case=False, layers=TABLES)["hitCount"] == 0

# the id path: the spell id resolves in Spell, and the same integer lands in
# unrelated dense id spaces - which is the whole warning
res = find.find_id(spell_ids[0], layers=TABLES)
hit = {(c["table"], c["column"]): c for c in res["columns"]}
assert ("Spell", "f0") in hit, sorted(hit)
assert hit[("Spell", "f0")]["isKey"] and hit[("Spell", "f0")]["rows"] == 1
assert hit[("Spell", "f0")]["samples"][0]["f136"] == "Tide Lash"
dense = [c for c in res["columns"] if c["isKey"] and (c["keyDensity"] or 0) > 0.5]
assert dense, "expected this id to also land in a dense, unrelated id space"

# --table restricts without changing what is found there
one = find.find_string("Tide Lash", only=["Spell"])
assert one["hitCount"] == 5
print(f"[5] find: 'Tide Lash' -> Spell.f136 x5 (ids {spell_ids}); id "
      f"{spell_ids[0]} -> {res['columnCount']} columns in {res['tableCount']} "
      f"tables, {len(dense)} of them dense keys")


# ==========================================================================
# [5b] find reaches the layers where quest and item TEXT actually lives
# ==========================================================================
# Quest and Item have ZERO string columns on this client, so a search that read
# only raw/tables answered "not in the client" for every quest title and item
# name in the game. These assertions are the regression gate on that.
quest_cols = {c for t in tables["tables"] if t["table"] in ("Quest", "Item")
              for c in t["columnDetail"] if c["inferred"] == "string"}
assert not quest_cols, "premise changed: Quest/Item now have string columns"

# The two layers carry different things, and the split is worth stating: the
# WDB caches hold what the server sent THIS client in its own locale (English
# here), while the .loc store holds the TRANSLATIONS. Neither is in the DBC.
q = find.find_string("A New Threat", layers=["content", "cache"], limit=0)
assert {c["layer"] for c in q["columns"]} == {"cache"}, q["columns"][:4]
assert all(c["table"].startswith("wdb:") for c in q["columns"]), q["columns"][:4]
assert any("questcache" in c["table"] for c in q["columns"]), q["columns"][:4]

it = find.find_string("Beaststalker's Belt", layers=["cache"], limit=0)
groups = {c["table"] for c in it["columns"]}
assert groups and all(g.startswith("wdb:") for g in groups), groups

# the .loc side: a translated spell name, which lives only in raw/content
de = find.find_string("Machtwort: Schild", layers=["content", "cache"], limit=0)
assert {c["layer"] for c in de["columns"]} == {"content"}, de["columns"][:4]
assert any(c["table"].startswith("loc:") for c in de["columns"]), de["columns"][:4]

# and the DBC layer cannot answer either question - not because the scan misses
# it, but because the row that would carry the text does not exist there
for text in ("A New Threat", "Beaststalker's Belt"):
    t = find.find_string(text, layers=TABLES, limit=0)
    assert not [c for c in t["columns"] if c["table"] in ("Quest", "Item")], \
        (text, t["columns"][:4])

# the variable-length run in raw/cache is a list in one positional slot; an
# integer inside it has to be findable, or the prefilter is silently lossy
runs = find.find_id(3, layers=["cache"], limit=0)
assert runs["columnCount"] > 0, "no cache column contains the integer 3"
print(f"[5b] find over content+cache: quest title in {len(q['columns'])} WDB "
      f"columns, item name in {len(it['columns'])}, translated spell name in "
      f"{len(de['columns'])} .loc groups - none of it reachable from raw/tables")


# ==========================================================================
# [5c] the reverse-join index answers "what joins to X"
# ==========================================================================
# This question needed a hand-written traversal of joins.json before byTarget.
by_target = {b["target"]: b for b in joins["byTarget"]}
flat = [(r["table"], r["column"], c["table"], c["containment"], c["lift"])
        for r in joins["columns"] for c in r["candidates"]]
assert sum(b["inboundColumns"] for b in joins["byTarget"]) == len(flat), \
    "byTarget must hold exactly the candidates in `columns` - no more, no fewer"
for b in joins["byTarget"]:
    want = [f for f in flat if f[2] == b["target"]]
    assert b["inboundColumns"] == len(want), b["target"]
    assert b["inboundTables"] == len({f[0] for f in want}), b["target"]
    assert b["aboveChance"] == sum(1 for f in want
                                   if f[4] is not None and f[4] >= bc.CHANCE_LIFT), \
        b["target"]
    assert b["aboveChanceStrong"] <= b["aboveChance"], b["target"]
    assert b["aboveChanceStrong"] + b["weakEvidence"] >= b["aboveChance"], b["target"]
    # ordering is by containment desc, strong evidence first
    conts = [c["containment"] for c in b["columns"]]
    assert conts == sorted(conts, reverse=True), b["target"]

spell = find.find_joins_to("Spell")
assert spell["target"] == "Spell"
assert spell["inboundColumns"] == by_target["Spell"]["inboundColumns"]
assert spell["inboundColumns"] > 0
# case-insensitive, and it reads the generated file rather than re-deriving
assert find.find_joins_to("spell")["inboundColumns"] == spell["inboundColumns"]
assert "byTargetRule" in joins and "no new measurement" in joins["byTargetRule"]
# the number an independent audit derived by hand from joins.json, which is what
# this index exists to make a one-command answer
assert (spell["inboundColumns"], spell["inboundTables"]) == (157, 80), spell
assert (spell["aboveChanceStrong"], spell["aboveChanceStrongTables"]) == (140, 71), spell
print(f"[5c] byTarget: {len(joins['byTarget'])} target tables index "
      f"{len(flat)} candidates; Spell.f0 has {spell['inboundColumns']} inbound "
      f"columns in {spell['inboundTables']} tables, "
      f"{spell['aboveChanceStrong']} of them in "
      f"{spell['aboveChanceStrongTables']} tables above chance on real evidence")


# ==========================================================================
# [6] line caps, LF bytes, determinism
# ==========================================================================
for label, path in GENERATED.items():
    raw = path.read_bytes()
    assert b"\r" not in raw, f"{label} carries CR - autocrlf would break rebuilds"
    lines = raw.count(b"\n")
    assert lines <= SHARD_MAX_LINES, f"{label} has {lines} lines"

attrs = (REPO / ".gitattributes").read_bytes().decode("utf-8")
for pattern in ("raw/_catalog/** -text", "CATALOG.md -text"):
    assert pattern in attrs, f".gitattributes must pin {pattern}"

before = {k: hashlib.sha256(p.read_bytes()).hexdigest() for k, p in GENERATED.items()}
tmp = Path(tempfile.mkdtemp())
old_dir, old_md = bc.CATALOG_DIR, bc.CATALOG_MD
try:
    bc.CATALOG_DIR, bc.CATALOG_MD = tmp / "_catalog", tmp / "CATALOG.md"
    bc.run(verbose=False)
    after = {
        "CATALOG.md": hashlib.sha256(bc.CATALOG_MD.read_bytes()).hexdigest(),
        "tables.json": hashlib.sha256((bc.CATALOG_DIR / "tables.json").read_bytes()).hexdigest(),
        "joins.json": hashlib.sha256((bc.CATALOG_DIR / "joins.json").read_bytes()).hexdigest(),
        "strings.json": hashlib.sha256((bc.CATALOG_DIR / "strings.json").read_bytes()).hexdigest(),
    }
finally:
    bc.CATALOG_DIR, bc.CATALOG_MD = old_dir, old_md
assert after == before, [k for k in before if before[k] != after[k]]
print(f"[6] {len(GENERATED)} generated files: LF only, under the "
      f"{SHARD_MAX_LINES}-line cap, and byte-identical on regeneration")

print("\nALL CATALOG CHECKS PASS")
