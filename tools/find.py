"""Search the raw client tables. The alternative to guessing which layer to ask.

    python -m tools.find "Tide Lash"        where a string lives
    python -m tools.find --id 133           every table an integer appears in

Both scan raw/tables/ directly - every row of every table, not an index built
over a chosen subset - so a hit is ground truth and a miss means the client
does not contain it. That is the whole point: this repo's worst wrong answers
came from querying a curated layer that had quietly dropped half the rows.

How the scan stays fast enough to be exhaustive: each shard line is tested as
TEXT first and only parsed when the text can match. For a string that is a
substring test; for an integer it is a test for the value in JSON value
position (`:133,` or `:133}`), which cannot miss an integer field and is
re-checked against the parsed record, so the shortcut costs no correctness.

Output is one line per hit: table, column, the row's f0, and the value. Add
--json for machine-readable output, --table to restrict the scan, --limit to
cap hits (0 for no cap).
"""
import argparse
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from tools import build_catalog as bc

DEFAULT_LIMIT = 50
CONTEXT_ROWS = 2       # sample rows shown per hit column in --id mode


def key_of(rec: dict):
    """The row's identity: f0, or its raw int when f0 decoded as a string."""
    v = rec.get("f0")
    return rec.get("f0i") if isinstance(v, str) else v


def truncate(s: str, n: int) -> str:
    s = " ".join(str(s).split())
    return s if len(s) <= n else s[:n - 1] + "..."


def stems(only=None) -> list:
    names = sorted((t["table"] for t in bc.layer_index()["tables"]), key=str.lower)
    if only:
        want = {o.lower() for o in only}
        picked = [s for s in names if s.lower() in want]
        missing = want - {s.lower() for s in picked}
        if missing:
            sys.exit(f"no such table: {', '.join(sorted(missing))}")
        return picked
    return names


# --------------------------------------------------------------------------
def find_string(query: str, only=None, ignore_case: bool = True,
                limit: int = DEFAULT_LIMIT) -> dict:
    needle = query.lower() if ignore_case else query
    hits, counts, truncated = [], {}, False
    for stem in stems(only):
        ix = bc.table_index(stem)
        if not ix["rows"]:
            continue
        for _, line in bc.iter_lines(stem, ix):
            if needle not in (line.lower() if ignore_case else line):
                continue
            rec = json.loads(line)
            for k, v in rec.items():
                if not isinstance(v, str):
                    continue
                if needle in (v.lower() if ignore_case else v):
                    counts[(stem, k)] = counts.get((stem, k), 0) + 1
                    if limit and len(hits) >= limit:
                        truncated = True
                        continue
                    hits.append({"table": stem, "column": k,
                                 "rowKey": key_of(rec), "text": v})
    return {"query": query, "hits": hits, "truncated": truncated,
            "columns": [{"table": t, "column": c, "rows": n}
                        for (t, c), n in sorted(counts.items())],
            "hitCount": sum(counts.values())}


def find_id(value: int, only=None, limit: int = DEFAULT_LIMIT) -> dict:
    needles = (f":{value},", f":{value}}}")
    found = {}
    for stem in stems(only):
        ix = bc.table_index(stem)
        if not ix["rows"]:
            continue
        for _, line in bc.iter_lines(stem, ix):
            if not any(nd in line for nd in needles):
                continue
            rec = json.loads(line)
            for k, v in rec.items():
                if type(v) is int and v == value:
                    e = found.setdefault((stem, k), {"rows": 0, "samples": []})
                    e["rows"] += 1
                    if len(e["samples"]) < CONTEXT_ROWS:
                        e["samples"].append(compact(rec))
    return {"integer": value, "columns": describe(found), "tableCount":
            len({t for t, _ in found}), "columnCount": len(found)}


def compact(rec: dict, keep: int = 6) -> dict:
    """A row shrunk to something printable: its key plus its string fields,
    which are the parts a human can recognise."""
    out = {}
    k = key_of(rec)
    if k is not None:
        out["f0"] = k
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
    for (stem, col), e in sorted(found.items()):
        t = cat["tables"].get(stem, {})
        c = cat["columns"].get((stem, col), {})
        out.append({
            "table": stem, "column": col, "rows": e["rows"],
            "isKey": col in ("f0", "f0i"),
            "inferred": c.get("inferred"),
            "columnDistinct": c.get("distinct"),
            "tableRows": t.get("rows"),
            "keyDistinct": t.get("keyDistinct"),
            "keyMin": t.get("keyMin"), "keyMax": t.get("keyMax"),
            "keyDensity": t.get("keyDensity"),
            "joinCandidates": cat["joins"].get((stem, col), []),
            "samples": e["samples"],
        })
    out.sort(key=lambda r: (not r["isKey"], r["table"].lower(), r["column"]))
    return out


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
          f'{len({c["table"] for c in res["columns"]})} tables\n')
    w = max(len(c["table"]) for c in res["columns"])
    for c in res["columns"]:
        print(f'  {c["table"]:<{w}}  {c["column"]:<6} {c["rows"]:>7} rows')
    print()
    for h in res["hits"]:
        print(f'  {h["table"]:<{w}}  {h["column"]:<6} '
              f'f0={str(h["rowKey"]):<10} {truncate(h["text"], 72)}')
    if res["truncated"]:
        print("\n  (hit list truncated; counts above are complete - "
              "raise --limit or use --json)")


def print_id(res: dict) -> None:
    cols = res["columns"]
    if not cols:
        print(f'no column contains the integer {res["integer"]}')
        return
    print(f'id {res["integer"]}: {res["columnCount"]} columns in '
          f'{res["tableCount"]} tables\n')
    for c in cols:
        head = f'  {c["table"]}.{c["column"]}  {c["rows"]} rows'
        if c["isKey"]:
            d = c["keyDensity"] or 0
            head += (f'  [KEY: {c["keyDistinct"]:,} ids over '
                     f'{c["keyMin"]}..{c["keyMax"]}, {d:.1%} dense'
                     + (" - dense, so any integer lands here]" if d > 0.5
                        else "]"))
        else:
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


def main(argv=None) -> int:
    ap = argparse.ArgumentParser(
        prog="python -m tools.find",
        description="Search every row of every decoded client table.")
    ap.add_argument("query", nargs="?", help="substring to find in decoded strings")
    ap.add_argument("--id", type=int, help="integer to find in any column")
    ap.add_argument("--table", action="append",
                    help="restrict to this table (repeatable)")
    ap.add_argument("--limit", type=int, default=DEFAULT_LIMIT,
                    help=f"max hits listed (default {DEFAULT_LIMIT}, 0 = all)")
    ap.add_argument("-s", "--case-sensitive", action="store_true")
    ap.add_argument("--json", action="store_true", help="machine-readable output")
    a = ap.parse_args(argv)

    if (a.query is None) == (a.id is None):
        ap.error("give a substring to search for, or --id N, but not both")

    if a.id is not None:
        res = find_id(a.id, a.table, a.limit)
        printer = print_id
    else:
        res = find_string(a.query, a.table, not a.case_sensitive, a.limit)
        printer = print_string

    if a.json:
        print(json.dumps(res, ensure_ascii=False, indent=1, sort_keys=True))
    else:
        printer(res)
    return 0


if __name__ == "__main__":
    sys.exit(main())
