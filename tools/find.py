"""Search the raw client. The alternative to guessing which layer to ask.

    python -m tools.find "Tide Lash"           where a string lives
    python -m tools.find --id 133              every column an integer appears in
    python -m tools.find --joins-to Spell      every column that points at Spell.f0

WHAT GETS SCANNED
-----------------
All four raw layers that hold rows, every row of every one of them - not an
index built over a chosen subset:

    tables    raw/tables/       every DBC table, positional f0..fN
    content   raw/content/      the .loc localization store (1.6M records)
    cache     raw/cache/        the WDB query caches, base and per realm
    binaries  raw/binaries/     every printable run, Lua chunk and PE symbol
                                in the client's own executables

`content` and `cache` are here because the DBC layer does not contain the text
an agent usually wants: `Quest` and `Item` have ZERO string columns on this
client - their names and objectives live in the .loc store and in the server's
own cached query responses. A search that read only raw/tables reported "not in
the client" for every quest title and item name in the game, which is exactly
the class of confidently-wrong answer this repo exists to stop. Restrict with
`--layer tables` when you want the old behaviour.

`binaries` is here for the same reason one layer up: some of what the client
does exists only in `Extensions.dll` and `Ascension.exe` - `listarchive`,
`SetDataPath`, `realmdata`, the inlined Lua that builds the realm hot-swap
overlay - and is in no shipped data file at all, so a search of the data layers
alone answers "not in the client" about strings the client demonstrably has.

So a hit is ground truth and a miss means these layers do not contain it.

How the scan stays fast enough to be exhaustive: each shard line is tested as
TEXT first and only parsed when the text can match. For a string that is a
substring test; for an integer it is a test for the value in JSON value
position (`:133,` or `:133}`), which cannot miss an integer field and is
re-checked against the parsed record, so the shortcut costs no correctness.

WHICH VERSION OF A TABLE
------------------------
A DBC path is carried by several archives and the chain picks one. Those copies
are not history - this client's realm overlay sits above the whole base chain,
so for a path the overlay carries, the chain winner is the OVERLAY's table and a
character outside that realm reads different bytes. Every hit therefore reports
the version it came from, and `--variant` chooses which versions are scanned:

    (default)               the chain winner, as the client resolves it
    --variant baseChain     what the base chain alone selects, no realm overlay
    --variant realm:<dir>   what that realm's overlay selects
    --variant overlay       what any realm overlay selects
    --variant all           every distinct version in the client
    --variant <slug>        only versions carried by that archive

The context names and slugs come out of `raw/tables/_variants.json`; an
unknown one lists what is available.

Output is one line per hit: table, version, column, the row's key, and the
value. Add --json for machine-readable output, --table to restrict the scan,
--limit to cap hits (0 for no cap).
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

LAYERS = ("tables", "content", "cache", "binaries")

# --variant selectors that are not an archive slug. `winner` is the default and
# is what every previous version of this tool scanned.
VARIANT_WINNER = "winner"
VARIANT_OVERLAY = "overlay"
VARIANT_ALL = "all"
VARIANT_KEYWORDS = (VARIANT_WINNER, VARIANT_OVERLAY, VARIANT_ALL)

# The chain context tools/variants.py records for "base chain, no realm
# overlay". Restated rather than imported so this module keeps working with no
# client attached; tests/test_variants.py pins the two together. Any OTHER
# --variant value is matched against the contexts and archive slugs the layer
# itself recorded, so no realm and no archive is named in this module.
BASE_CONTEXT = "baseChain"

# The positional first column. Not a name for anything - `f0` IS the position.
DEFAULT_KEY = "f0"

CONTENT_DIR = config.RAW_DIR / "content"
CACHE_DIR = config.RAW_DIR / "cache"
BINARIES_DIR = config.RAW_DIR / "binaries"

# The record groups every extracted binary carries. Named here rather than
# discovered by listing directories so a group that failed to write is a missing
# source (and shows up as one) instead of silently reducing the search.
BINARY_GROUPS = ("strings", "lua", "symbols")


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

    __slots__ = ("layer", "name", "dir", "stem", "key", "variant", "archive",
                 "applies")

    def __init__(self, layer, name, directory=None, stem=None, key=DEFAULT_KEY,
                 variant=None, archive=None, applies=()):
        self.layer = layer
        self.name = name
        self.dir = directory
        self.stem = stem
        self.key = key
        # Which version of the table this source reads, straight out of
        # raw/tables/_variants.json. None for the layers that have only one.
        self.variant = variant
        self.archive = archive
        self.applies = list(applies)

    def label(self) -> str:
        """The version, named the way a reader can act on it: the chain
        contexts that select it when there are any, else the archive."""
        if self.variant is None:
            return ""
        return ",".join(self.applies) if self.applies else f"({self.archive})"

    def lines(self):
        if self.layer == "tables":
            d = self.dir or (bc.TABLES_DIR / self.stem)
            ix = bc.load_json(d / "index.json")
            if not ix["rows"]:
                return
            for s in ix["shards"]:
                with bc.open_shard(d / s["file"]) as f:
                    for line in f:
                        if line.strip():
                            yield line
            return
        for fp in sorted(self.dir.glob("*.jsonl")) + sorted(self.dir.glob("*.jsonl.gz")):
            op = gzip.open if fp.suffix == ".gz" else open
            with op(fp, "rt", encoding="utf-8") as f:
                for line in f:
                    if line.strip():
                        yield line


def _table_sources(variant: str = VARIANT_WINNER) -> list:
    """One source per table, or several when `variant` asks for more than the
    chain winner. Which versions exist and which chain context selects each is
    READ OUT of every table's own index (`variants`), never derived here - the
    module that decoded them is the one that gets to say what they are."""
    layerstate.require_complete(bc.TABLES_DIR, "python datamine.py")
    out = []
    for t in bc.layer_index()["tables"]:
        stem = t["table"]
        ix = bc.table_index(stem)
        versions = ix.get("variants")
        if not versions:
            # a layer decoded before versions were recorded: winner only
            out.append(Source("tables", stem, stem=stem))
            continue
        for v in versions:
            if not _wanted(v, variant):
                continue
            d = (bc.TABLES_DIR / stem) if v["chainWinner"] else \
                (bc.TABLES_DIR / stem / "variants" / v["slug"])
            if not (d / "index.json").is_file():
                continue
            out.append(Source("tables", stem, directory=d, stem=stem,
                              variant=v["slug"], archive=v["archive"],
                              applies=v["appliesTo"]))
    if not out and variant not in VARIANT_KEYWORDS:
        vp = bc.TABLES_DIR / "_variants.json"
        vj = bc.load_json(vp) if vp.is_file() else {}
        ctx = sorted(c["context"] for c in vj.get("contexts", []))
        slugs = sorted({v["slug"] for t in vj.get("tables", [])
                        for v in t["variants"]})
        sys.exit(f"no table version named {variant!r}. Use one of "
                 f"{', '.join(VARIANT_KEYWORDS)}, a chain context "
                 f"({', '.join(ctx) or 'none recorded'}), or an archive slug "
                 f"({', '.join(slugs) or 'none recorded'}).")
    return out


def _wanted(v: dict, variant: str) -> bool:
    if variant == VARIANT_ALL:
        return True
    if variant == VARIANT_WINNER:
        return bool(v["chainWinner"])
    if variant == VARIANT_OVERLAY:
        return any(c != BASE_CONTEXT for c in v["appliesTo"])
    # a chain context recorded by the layer, or an archive slug
    return variant in v["appliesTo"] or v["slug"] == variant


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


def _binary_sources() -> list:
    """One source per record group of every extracted client binary, named
    `bin:Extensions.dll/strings` so --table can address one binary's strings and
    output can name where a hit came from."""
    ix_path = BINARIES_DIR / "index.json"
    if not ix_path.is_file() or not layerstate.is_complete(BINARIES_DIR):
        return []
    ix = bc.load_json(ix_path)
    out = []
    for b in ix.get("binaries", []):
        for group in BINARY_GROUPS:
            d = BINARIES_DIR / b["name"] / group
            if not d.is_dir():
                continue
            label = group
            gix = d / "index.json"
            key = (bc.load_json(gix).get("keyField", DEFAULT_KEY)
                   if gix.is_file() else DEFAULT_KEY)
            out.append(Source("binaries", f'bin:{b["name"]}/{label}',
                              directory=d, key=key))
    return out


_SOURCES = {}


def sources(only=None, layers=None, variant: str = VARIANT_WINNER) -> list:
    if variant not in _SOURCES:
        _SOURCES[variant] = (_table_sources(variant) + _content_sources()
                             + _cache_sources() + _binary_sources())
    picked = _SOURCES[variant]
    if layers:
        want = set(layers)
        picked = [s for s in picked if s.layer in want]
    picked = sorted(picked, key=lambda s: (LAYERS.index(s.layer), s.name.lower(),
                                           s.variant or ""))
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
                limit: int = DEFAULT_LIMIT, layers=None,
                variant: str = VARIANT_WINNER) -> dict:
    needle = query.lower() if ignore_case else query
    hits, counts, truncated = [], {}, False
    for src in sources(only, layers, variant):
        for line in src.lines():
            if needle not in (line.lower() if ignore_case else line):
                continue
            rec = json.loads(line)
            for k, v in rec.items():
                if not isinstance(v, str):
                    continue
                if needle in (v.lower() if ignore_case else v):
                    key = (src.layer, src.name, src.variant or "", k)
                    e = counts.setdefault(key, {"rows": 0, "src": src})
                    e["rows"] += 1
                    if limit and len(hits) >= limit:
                        truncated = True
                        continue
                    hits.append({"layer": src.layer, "table": src.name,
                                 "variant": src.variant,
                                 "variantArchive": src.archive,
                                 "appliesTo": src.applies,
                                 "column": k, "rowKey": key_of(rec, src),
                                 "text": v})
    return {"query": query, "variant": variant, "hits": hits,
            "truncated": truncated,
            "columns": [{"layer": lay, "table": t, "variant": vr or None,
                         "variantArchive": e["src"].archive,
                         "appliesTo": e["src"].applies,
                         "column": c, "rows": e["rows"]}
                        for (lay, t, vr, c), e in sorted(
                            counts.items(), key=lambda kv: kv[0])],
            "hitCount": sum(e["rows"] for e in counts.values())}


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


def find_id(value: int, only=None, limit: int = DEFAULT_LIMIT, layers=None,
            variant: str = VARIANT_WINNER) -> dict:
    needles = _needles(value)
    found = {}
    for src in sources(only, layers, variant):
        for line in src.lines():
            if not any(nd in line for nd in needles):
                continue
            rec = json.loads(line)
            for k, v in rec.items():
                if _int_in(v, value):
                    e = found.setdefault((src.layer, src.name, src.variant or "", k),
                                         {"rows": 0, "samples": [], "src": src})
                    e["rows"] += 1
                    if len(e["samples"]) < CONTEXT_ROWS:
                        e["samples"].append(compact(rec, src))
    return {"integer": value, "variant": variant, "columns": describe(found),
            "tableCount": len({t for _, t, _, _ in found}),
            "columnCount": len(found)}


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
    for (layer, stem, var, col), e in sorted(found.items()):
        t = cat["tables"].get(stem, {})
        c = cat["columns"].get((stem, col), {})
        out.append({
            "layer": layer, "table": stem, "column": col, "rows": e["rows"],
            "variant": var or None, "variantArchive": e["src"].archive,
            "appliesTo": e["src"].applies,
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
                            r["table"].lower(), r["variant"] or "", r["column"]))
    return out


# --------------------------------------------------------------------------
def find_joins_to(target: str) -> dict:
    """Every column the catalog measured as pointing at `target`.f0.

    Reads `byTarget` out of the generated joins.json rather than re-deriving it,
    so this command and the catalog can never disagree about a rate."""
    p = bc.CATALOG_DIR / "joins.json"
    if not p.exists():
        sys.exit("raw/_catalog/joins.json is missing - run "
                 "`python datamine.py`")
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
def _version(rec: dict) -> str:
    """How a hit names the version it came from: the chain contexts that select
    it, or the archive when no context does (a shadowed version)."""
    if not rec.get("variant"):
        return ""
    a = rec.get("appliesTo") or []
    return ",".join(a) if a else f'({rec.get("variantArchive")})'


def print_string(res: dict) -> None:
    if not res["columns"]:
        print(f'no row contains "{res["query"]}" '
              f'(version scanned: {res["variant"]})')
        return
    print(f'"{res["query"]}": {res["hitCount"]} rows in '
          f'{len(res["columns"])} columns of '
          f'{len({c["table"] for c in res["columns"]})} tables/groups '
          f'[--variant {res["variant"]}]\n')
    w = max(len(c["table"]) for c in res["columns"])
    v = max([len(_version(c)) for c in res["columns"]] + [7])
    for c in res["columns"]:
        print(f'  {c["layer"]:<7} {c["table"]:<{w}}  {_version(c):<{v}}  '
              f'{c["column"]:<6} {c["rows"]:>7} rows')
    print()
    for h in res["hits"]:
        print(f'  {h["layer"]:<7} {h["table"]:<{w}}  {_version(h):<{v}}  '
              f'{h["column"]:<6} key={str(h["rowKey"]):<10} '
              f'{truncate(h["text"], 62)}')
    if res["truncated"]:
        print("\n  (hit list truncated; counts above are complete - "
              "raise --limit or use --json)")


def print_id(res: dict) -> None:
    cols = res["columns"]
    if not cols:
        print(f'no column contains the integer {res["integer"]} '
              f'(version scanned: {res["variant"]})')
        return
    print(f'id {res["integer"]}: {res["columnCount"]} columns in '
          f'{res["tableCount"]} tables/groups [--variant {res["variant"]}]\n')
    for c in cols:
        ver = _version(c)
        head = (f'  [{c["layer"]}] {c["table"]}'
                + (f' [{ver}]' if ver else "")
                + f'.{c["column"]}  {c["rows"]} rows')
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
    ap.add_argument("--variant", default=VARIANT_WINNER, metavar="WHICH",
                    help="which version of each table to scan: "
                         f"{', '.join(VARIANT_KEYWORDS)}, a chain context or "
                         f"an archive slug from raw/tables/_variants.json "
                         f"(default {VARIANT_WINNER}: what the chain resolves)")
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
        res = find_id(a.id, a.table, a.limit, a.layer, a.variant)
        printer = print_id
    else:
        res = find_string(a.query, a.table, not a.case_sensitive, a.limit,
                          a.layer, a.variant)
        printer = print_string

    if a.json:
        print(json.dumps(res, ensure_ascii=False, indent=1, sort_keys=True,
                         default=str))
    else:
        printer(res)
    return 0


if __name__ == "__main__":
    sys.exit(main())
