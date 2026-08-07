"""Search the raw client. The alternative to guessing which layer to ask.

    python -m tools.find "Tide Lash"           where a string lives
    python -m tools.find --id 133              every column an integer appears in
    python -m tools.find --joins-to Spell      every column that points at Spell.f0

WHAT GETS SCANNED
-----------------
All three raw layers that hold rows, every row of every one of them - not an
index built over a chosen subset:

    tables    raw/tables/       every DBC table, positional f0..fN
    content   raw/content/      the .loc localization store (1.6M records)
    cache     raw/cache/        the WDB query caches, base and per realm

`content` and `cache` are here because the DBC layer does not contain the text
an agent usually wants: `Quest` and `Item` have ZERO string columns on this
client - their names and objectives live in the .loc store and in the server's
own cached query responses. A search that read only raw/tables reported "not in
the client" for every quest title and item name in the game, which is exactly
the class of confidently-wrong answer this repo exists to stop. Restrict with
`--layer tables` when you want the old behaviour.

So a hit is ground truth and a miss means these layers do not contain it.

How the scan stays fast enough to be exhaustive: each shard line is tested as
TEXT first and only parsed when the text can match. For a string that is a
substring test; for an integer it is a test for the value in JSON value
position (`:133,` or `:133}`), which cannot miss an integer field and is
re-checked against the parsed record, so the shortcut costs no correctness.

Output is one line per hit: table, column, the row's key, and the value. Add
--json for machine-readable output, --table to restrict the scan, --limit to
cap hits (0 for no cap).
"""
import argparse
import gzip
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from tools import build_catalog as bc
from tools import config, layerstate

DEFAULT_LIMIT = 50
CONTEXT_ROWS = 2       # sample rows shown per hit column in --id mode

LAYERS = ("tables", "content", "cache")

# The positional first column. Not a name for anything - `f0` IS the position.
DEFAULT_KEY = "f0"

CONTENT_DIR = config.RAW_DIR / "content"
CACHE_DIR = config.RAW_DIR / "cache"


# --------------------------------------------------------------------------
# the source list: one flat namespace over three layers
# --------------------------------------------------------------------------
class Source:
    """One searchable group of shards: a DBC table, one .loc entity/locale, or
    one WDB cache file. `name` is what the user sees and what --table matches.

    `key` - which field identifies a row - is READ OUT of each layer's own
    index (`keyField`), never assumed here. No reader in this repo is allowed to
    know a column's name in advance; the module that writes the records is the
    one that gets to say what it called them. DEFAULT_KEY is the positional
    first column, which is what the table layer uses and the only name this
    module can state without asserting anything about content."""

    __slots__ = ("layer", "name", "dir", "stem", "key")

    def __init__(self, layer, name, directory=None, stem=None, key=DEFAULT_KEY):
        self.layer = layer
        self.name = name
        self.dir = directory
        self.stem = stem
        self.key = key

    def lines(self):
        if self.layer == "tables":
            ix = bc.table_index(self.stem)
            if not ix["rows"]:
                return
            for _, line in bc.iter_lines(self.stem, ix):
                yield line
            return
        for fp in sorted(self.dir.glob("*.jsonl")) + sorted(self.dir.glob("*.jsonl.gz")):
            op = gzip.open if fp.suffix == ".gz" else open
            with op(fp, "rt", encoding="utf-8") as f:
                for line in f:
                    if line.strip():
                        yield line


def _table_sources() -> list:
    layerstate.require_complete(bc.TABLES_DIR, "python -m tools.decode_all")
    return [Source("tables", t["table"], stem=t["table"])
            for t in bc.layer_index()["tables"]]


def _content_sources() -> list:
    """One source per localization <Entity>/<Field>/<locale> group, named
    `loc:Spell/Name/deDE` so --table can address it and output can name it."""
    ix_path = CONTENT_DIR / "index.json"
    if not ix_path.is_file() or not layerstate.is_complete(CONTENT_DIR):
        return []
    ix = bc.load_json(ix_path)
    out = []
    for g in ix.get("localizationGroups", []):
        d = CONTENT_DIR / "localization" / g["entity"] / g["locale"]
        if d.is_dir():
            out.append(Source("content", f"loc:{g['entity']}/{g['locale']}",
                              directory=d,
                              key=g.get("keyField", DEFAULT_KEY)))
    return out


def _cache_sources() -> list:
    """One source per decoded WDB cache file, named `wdb:<group>/<name>`."""
    ix_path = CACHE_DIR / "index.json"
    if not ix_path.is_file() or not layerstate.is_complete(CACHE_DIR):
        return []
    ix = bc.load_json(ix_path)
    out = []
    for e in ix.get("files", []):
        if not e.get("dir"):
            continue
        d = CACHE_DIR / e["dir"]
        if d.is_dir():
            out.append(Source("cache", f"wdb:{e['dir']}", directory=d,
                              key=e.get("keyField", DEFAULT_KEY)))
    return out


_SOURCES = None


def sources(only=None, layers=None) -> list:
    global _SOURCES
    if _SOURCES is None:
        _SOURCES = (_table_sources() + _content_sources() + _cache_sources())
    picked = _SOURCES
    if layers:
        want = set(layers)
        picked = [s for s in picked if s.layer in want]
    picked = sorted(picked, key=lambda s: (LAYERS.index(s.layer), s.name.lower()))
    if only:
        want = {o.lower() for o in only}
        chosen = [s for s in picked if s.name.lower() in want]
        missing = want - {s.name.lower() for s in chosen}
        if missing:
            sys.exit(f"no such table/group: {', '.join(sorted(missing))}")
        return chosen
    return picked


def key_of(rec: dict, src: Source = None):
    """The row's identity: its key column, or the raw int when it decoded as a
    string (the table layer carries that as the `i` sidecar suffix)."""
    k = src.key if src is not None else DEFAULT_KEY
    v = rec.get(k)
    if k == DEFAULT_KEY and isinstance(v, str):
        return rec.get(DEFAULT_KEY + "i")
    return v


def truncate(s: str, n: int) -> str:
    s = " ".join(str(s).split())
    return s if len(s) <= n else s[:n - 1] + "..."


# --------------------------------------------------------------------------
def find_string(query: str, only=None, ignore_case: bool = True,
                limit: int = DEFAULT_LIMIT, layers=None) -> dict:
    needle = query.lower() if ignore_case else query
    hits, counts, truncated = [], {}, False
    for src in sources(only, layers):
        for line in src.lines():
            if needle not in (line.lower() if ignore_case else line):
                continue
            rec = json.loads(line)
            for k, v in rec.items():
                if not isinstance(v, str):
                    continue
                if needle in (v.lower() if ignore_case else v):
                    counts[(src.layer, src.name, k)] = \
                        counts.get((src.layer, src.name, k), 0) + 1
                    if limit and len(hits) >= limit:
                        truncated = True
                        continue
                    hits.append({"layer": src.layer, "table": src.name,
                                 "column": k, "rowKey": key_of(rec, src),
                                 "text": v})
    return {"query": query, "hits": hits, "truncated": truncated,
            "columns": [{"layer": lay, "table": t, "column": c, "rows": n}
                        for (lay, t, c), n in sorted(counts.items())],
            "hitCount": sum(counts.values())}


def _int_in(v, value: int) -> bool:
    """A field matches when it IS the integer, or when it is a variable-length
    run (raw/cache emits those as a list in one positional slot) containing it."""
    if type(v) is int:
        return v == value
    if type(v) is list:
        return any(type(x) is int and x == value for x in v)
    return False


def _needles(value: int) -> tuple:
    """Every way the integer can appear in JSON VALUE position in a compact
    record: after a key (`:`), or as an element of a list (`[` or `,`), and
    ending at `,`, `}` or `]`. All nine combinations, because missing one is a
    silent false negative - raw/cache emits variable-length runs as lists, so
    `{"f28":[3,17]}` has the value in positions no `:N,` test would reach."""
    return tuple(f"{a}{value}{b}" for a in (":", "[", ",") for b in (",", "}", "]"))


def find_id(value: int, only=None, limit: int = DEFAULT_LIMIT, layers=None) -> dict:
    needles = _needles(value)
    found = {}
    for src in sources(only, layers):
        for line in src.lines():
            if not any(nd in line for nd in needles):
                continue
            rec = json.loads(line)
            for k, v in rec.items():
                if _int_in(v, value):
                    e = found.setdefault((src.layer, src.name, k),
                                         {"rows": 0, "samples": [], "src": src})
                    e["rows"] += 1
                    if len(e["samples"]) < CONTEXT_ROWS:
                        e["samples"].append(compact(rec, src))
    return {"integer": value, "columns": describe(found),
            "tableCount": len({t for _, t, _ in found}), "columnCount": len(found)}


def compact(rec: dict, src: Source = None, keep: int = 6) -> dict:
    """A row shrunk to something printable: its key plus its string fields,
    which are the parts a human can recognise."""
    out = {}
    k = key_of(rec, src)
    if k is not None:
        out[src.key if src else DEFAULT_KEY] = k
    for name, v in rec.items():
        if isinstance(v, str) and v and len(out) < keep:
            out[name] = truncate(v, 40)
    return out


def describe(found: dict) -> list:
    """Attach each hit column's measured context: what the column is, and - the
    part that matters - whether the table it hit has a dense id space, because
    a dense space is hit by any integer and proves nothing."""
    cat = load_catalog()
    out = []
    for (layer, stem, col), e in sorted(found.items()):
        t = cat["tables"].get(stem, {})
        c = cat["columns"].get((stem, col), {})
        out.append({
            "layer": layer, "table": stem, "column": col, "rows": e["rows"],
            "isKey": col == e["src"].key,
            "inferred": c.get("inferred"),
            "columnDistinct": c.get("distinct"),
            "tableRows": t.get("rows"),
            "keyDistinct": t.get("keyDistinct"),
            "keyMin": t.get("keyMin"), "keyMax": t.get("keyMax"),
            "keyDensity": t.get("keyDensity"),
            "joinCandidates": cat["joins"].get((stem, col), []),
            "samples": e["samples"],
        })
    out.sort(key=lambda r: (LAYERS.index(r["layer"]), not r["isKey"],
                            r["table"].lower(), r["column"]))
    return out


# --------------------------------------------------------------------------
def find_joins_to(target: str) -> dict:
    """Every column the catalog measured as pointing at `target`.f0.

    Reads `byTarget` out of the generated joins.json rather than re-deriving it,
    so this command and the catalog can never disagree about a rate."""
    p = bc.CATALOG_DIR / "joins.json"
    if not p.exists():
        sys.exit("raw/_catalog/joins.json is missing - run "
                 "`python -m tools.build_catalog`")
    jj = bc.load_json(p)
    index = {b["target"].lower(): b for b in jj["byTarget"]}
    b = index.get(target.lower())
    if b is None:
        known = sorted(x["target"] for x in jj["byTarget"])
        sys.exit(f"no column joins to {target}.f0 (or no such table). "
                 f"{len(known)} tables have inbound candidates.")
    return {"target": b["target"], "targetColumn": DEFAULT_KEY,
            "inboundColumns": b["inboundColumns"],
            "inboundTables": b["inboundTables"],
            "aboveChance": b["aboveChance"],
            "aboveChanceStrong": b["aboveChanceStrong"],
            "aboveChanceStrongTables": b["aboveChanceStrongTables"],
            "weakEvidence": b["weakEvidence"],
            "chanceLift": jj["caps"]["chanceLift"],
            "minMatchedEvidence": jj["caps"]["minMatchedEvidence"],
            "rule": jj["byTargetRule"], "columns": b["columns"]}


_CATALOG = None


def load_catalog() -> dict:
    """The generated catalog, if it has been built. Optional on purpose - find
    must still work on a fresh clone that has only run the decode."""
    global _CATALOG
    if _CATALOG is None:
        tables, columns, joins = {}, {}, {}
        p = bc.CATALOG_DIR / "tables.json"
        if p.exists():
            for t in bc.load_json(p)["tables"]:
                tables[t["table"]] = t
                for c in t["columnDetail"]:
                    columns[(t["table"], c["name"])] = c
        p = bc.CATALOG_DIR / "joins.json"
        if p.exists():
            for r in bc.load_json(p)["columns"]:
                joins[(r["table"], r["column"])] = [
                    {"table": c["table"], "containment": c["containment"],
                     "lift": c["lift"], "targetDensity": c["targetDensity"]}
                    for c in r["candidates"][:3]]
        _CATALOG = {"tables": tables, "columns": columns, "joins": joins}
    return _CATALOG


# --------------------------------------------------------------------------
def print_string(res: dict) -> None:
    if not res["columns"]:
        print(f'no row contains "{res["query"]}"')
        return
    print(f'"{res["query"]}": {res["hitCount"]} rows in '
          f'{len(res["columns"])} columns of '
          f'{len({c["table"] for c in res["columns"]})} tables/groups\n')
    w = max(len(c["table"]) for c in res["columns"])
    for c in res["columns"]:
        print(f'  {c["layer"]:<7} {c["table"]:<{w}}  {c["column"]:<6} '
              f'{c["rows"]:>7} rows')
    print()
    for h in res["hits"]:
        print(f'  {h["layer"]:<7} {h["table"]:<{w}}  {h["column"]:<6} '
              f'key={str(h["rowKey"]):<10} {truncate(h["text"], 62)}')
    if res["truncated"]:
        print("\n  (hit list truncated; counts above are complete - "
              "raise --limit or use --json)")


def print_id(res: dict) -> None:
    cols = res["columns"]
    if not cols:
        print(f'no column contains the integer {res["integer"]}')
        return
    print(f'id {res["integer"]}: {res["columnCount"]} columns in '
          f'{res["tableCount"]} tables/groups\n')
    for c in cols:
        head = f'  [{c["layer"]}] {c["table"]}.{c["column"]}  {c["rows"]} rows'
        if c["isKey"] and c["keyDistinct"]:
            d = c["keyDensity"] or 0
            head += (f'  [KEY: {c["keyDistinct"]:,} ids over '
                     f'{c["keyMin"]}..{c["keyMax"]}, {d:.1%} dense'
                     + (" - dense, so any integer lands here]" if d > 0.5
                        else "]"))
        elif c["isKey"]:
            head += "  [KEY]"
        elif c["inferred"]:
            head += f'  [{c["inferred"]}, {c["columnDistinct"]:,} distinct]'
        print(head)
        for j in c["joinCandidates"]:
            print(f'      joins -> {j["table"]}.f0  containment '
                  f'{j["containment"]}  lift {j["lift"]}  '
                  f'targetDensity {j["targetDensity"]}')
        for s in c["samples"]:
            print(f'      {json.dumps(s, ensure_ascii=False)}')
    print("\n  A hit in a dense id space is not evidence of identity: CoA "
          "reuses ids across generations.\n  Check lift on any join above "
          "before treating two rows as the same thing.")


def print_joins_to(res: dict) -> None:
    print(f'{res["inboundColumns"]} columns in {res["inboundTables"]} tables '
          f'join to {res["target"]}.{res["targetColumn"]}\n'
          f'  {res["aboveChance"]} beat lift {res["chanceLift"]}; '
          f'{res["aboveChanceStrong"]} of those in '
          f'{res["aboveChanceStrongTables"]} tables also have at least '
          f'{res["minMatchedEvidence"]} matched values ({res["weakEvidence"]} '
          f'rest on fewer)\n')
    w = max((len(c["table"]) for c in res["columns"]), default=8)
    for c in res["columns"]:
        flag = " WEAK" if c["weakEvidence"] else ""
        chance = "" if (c["lift"] or 0) >= res["chanceLift"] else "  <- chance level"
        print(f'  {c["table"]:<{w}} {c["column"]:<6} containment '
              f'{c["containment"]:<8} matched {c["matched"]:<7} lift '
              f'{str(c["lift"]):<10}{flag}{chance}')
    print("\n  Containment is overlap, not identity. `matched` is the sample "
          "size behind `lift`;\n  a spectacular lift on two matched values is "
          "chance. Read both.")


def main(argv=None) -> int:
    ap = argparse.ArgumentParser(
        prog="python -m tools.find",
        description="Search every row of raw/tables, raw/content and raw/cache.")
    ap.add_argument("query", nargs="?", help="substring to find in decoded strings")
    ap.add_argument("--id", type=int, help="integer to find in any column")
    ap.add_argument("--joins-to", metavar="TABLE",
                    help="list every column measured to point at TABLE.f0")
    ap.add_argument("--table", action="append",
                    help="restrict to this table/group (repeatable)")
    ap.add_argument("--layer", action="append", choices=LAYERS,
                    help=f"restrict to this layer (repeatable; default all of "
                         f"{', '.join(LAYERS)})")
    ap.add_argument("--limit", type=int, default=DEFAULT_LIMIT,
                    help=f"max hits listed (default {DEFAULT_LIMIT}, 0 = all)")
    ap.add_argument("-s", "--case-sensitive", action="store_true")
    ap.add_argument("--json", action="store_true", help="machine-readable output")
    a = ap.parse_args(argv)

    given = [x is not None for x in (a.query, a.id, a.joins_to)]
    if sum(given) != 1:
        ap.error("give exactly one of: a substring, --id N, or --joins-to TABLE")

    if a.joins_to is not None:
        res = find_joins_to(a.joins_to)
        printer = print_joins_to
    elif a.id is not None:
        res = find_id(a.id, a.table, a.limit, a.layer)
        printer = print_id
    else:
        res = find_string(a.query, a.table, not a.case_sensitive, a.limit, a.layer)
        printer = print_string

    if a.json:
        print(json.dumps(res, ensure_ascii=False, indent=1, sort_keys=True,
                         default=str))
    else:
        printer(res)
    return 0


if __name__ == "__main__":
    sys.exit(main())
