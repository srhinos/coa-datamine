"""THE entry point. Re-extracts the whole client, from nothing, with no agent
and no decision:

    python -m tools.extract_everything

Run it after any client patch. It takes no arguments, asks no questions, and
rebuilds every raw layer in dependency order. When it finishes it prints WHAT
CHANGED SINCE THE LAST RUN - per-table row deltas, tables added and removed,
tables whose winning archive moved, and every count each layer records about
itself. On an unchanged client it reports no change and rewrites the tree byte
for byte.

WHY ONE COMMAND
---------------
The regeneration procedure used to be five commands whose order was the
contract and was written down nowhere complete - `raw/README.md`'s regeneration
block did not mention the catalog at all, so the searchable layer could sit a
generation behind the data it claims to describe and nothing would say so. A
procedure that can be performed wrongly will be. This module is the procedure.

The stages stay individually runnable and are unchanged by this file; it does
not re-implement any of them.

ORDER, AND WHY IT IS THIS ORDER
-------------------------------
    1 inventory           census of every archive + path. Nothing else can run
                          first: interface_all is derived from it, and
                          extract_all takes its chain order from it.
    2 extract_all         pull every DBFilesClient body out of the winning
                          chain (into work/, not committed)
    3 decode_all          decode all of them to raw/tables/  [needs 2]
    4 extract_interface   the Interface code layer as bytes -> raw/interface/
    5 raw_layers          content/.loc + the Interface census + the WDB caches
                          [the census needs 1 and reuses 4's bytes]
    6 crack               everything the old reader could not read, the deleted
                          and encrypted members, the expanded containers, and a
                          full MD5 verification of every member against its own
                          archive  [needs 1]
    7 binaries            the client's own executables - every string, the
                          inlined Lua, the PE structure. Depends on nothing but
                          the client
    8 build_catalog       the search catalog over raw/tables/  [needs 3]

WHY IT REFUSES TO CONTINUE PAST A BAD STAGE
-------------------------------------------
Every stage writes `_complete.json` LAST and drops it BEFORE it deletes
anything (tools/layerstate.py), so an interrupted build leaves layers that read
as unfinished rather than as smaller-but-plausible. This runner checks that
sentinel after each stage and stops, because the entire value of the sentinel is
that nothing downstream builds on a half-written layer.

PARTIAL RERUNS
--------------
    --only decode_all     run exactly one stage (repeatable)
    --from decode_all     resume at a stage (the earlier layers must be complete)
    --list                print the stage list and each layer's current state

A partial run that rewrites raw/tables without rerunning `build_catalog` leaves
the catalog describing the previous generation of the data. That is the exact
failure the single command exists to prevent, so this module detects it and says
so at the end rather than exiting quietly.
"""
import argparse
import json
import sys
import time

from tools import (build_catalog, config, crack, decode_all, extract_all,
                   extract_binaries, extract_interface, extract_raw_layers,
                   inventory, layerstate)

# (name, callable, layer directories the stage must leave complete, what it
# does, the module that runs it alone). The module is here because
# tools/extract_raw_layers.py generates raw/README.md's regeneration block from
# this table - the two were maintained separately and had already drifted.
STAGES = [
    ("inventory", lambda: inventory.build(),
     [config.RAW_DIR / "_inventory"],
     "census every archive and every path in the client", "tools.inventory"),
    ("extract_all", lambda: extract_all.extract(),
     [extract_all.OUT_DIR],
     "pull every DBFilesClient body out of the winning chain",
     "tools.extract_all"),
    ("decode_all", lambda: decode_all.run(),
     [decode_all.OUT_DIR],
     "decode every table to raw/tables/, positional f0..fN",
     "tools.decode_all"),
    ("extract_interface", lambda: extract_interface.extract_all(),
     [config.RAW_INTERFACE_DIR],
     "the Interface code layer, as bytes", "tools.extract_interface"),
    ("raw_layers", lambda: extract_raw_layers.main_stages(),
     [config.RAW_CONTENT_DIR, config.RAW_DIR / "interface_all",
      config.RAW_DIR / "cache"],
     "Data\\Content + .loc, the Interface census, the WDB caches",
     "tools.extract_raw_layers"),
    ("crack", lambda: crack.run(),
     [crack.OUT_DIR, crack.ATTR_DIR, crack.FILES_DIR, crack.DELETED_DIR,
      crack.CORRECTIONS_DIR, crack.CONTAINER_DIR],
     "recover deleted/encrypted/undecodable members, expand containers, and "
     "verify every member against its archive's own MD5", "tools.crack"),
    ("binaries", lambda: extract_binaries.extract(),
     [extract_binaries.OUT_DIR],
     "the client's own executables: strings, embedded Lua, PE structure",
     "tools.extract_binaries"),
    ("build_catalog", lambda: build_catalog.run(),
     [build_catalog.CATALOG_DIR],
     "the searchable catalog over raw/tables/", "tools.build_catalog"),
]

NAMES = [s[0] for s in STAGES]

# The stage that publishes the catalog, and the stages that invalidate it by
# rewriting the table layer underneath it.
CATALOG_STAGE = "build_catalog"
CATALOG_INPUT_STAGES = {"extract_all", "decode_all"}

# How many changed tables to list before summarising the rest. A patch that
# touches everything should not bury its own headline under 368 lines.
MAX_LISTED = 50


# --------------------------------------------------------------------------
# what the tree looks like right now
# --------------------------------------------------------------------------
def _flatten_numbers(obj, prefix="") -> dict:
    """Every number anywhere in a sentinel payload, keyed by its dotted path.

    Generic on purpose: the runner does not know, and must not encode, which
    counts a given layer happens to record. Whatever a stage measures about
    itself is what gets diffed - a new count added to any sentinel tomorrow is
    picked up here with no change to this file."""
    out = {}
    if isinstance(obj, dict):
        for k, v in obj.items():
            out.update(_flatten_numbers(v, f"{prefix}{k}."))
    elif isinstance(obj, bool):
        pass                      # `partial: false` is a state, not a count
    elif isinstance(obj, (int, float)):
        out[prefix[:-1]] = obj
    return out


def layer_dirs() -> list:
    """Every layer directory any stage claims, in stage order, deduplicated."""
    seen, out = set(), []
    for _name, _fn, dirs, _what, _mod in STAGES:
        for d in dirs:
            if d not in seen:
                seen.add(d)
                out.append(d)
    return out


def snapshot() -> dict:
    """The state a diff is taken against: each layer's own counts, plus every
    table's row/column count and winning archive out of the catalog.

    Read from the tree itself, not from a state file this runner maintains. A
    state file would be a second copy of facts that already exist in the layers
    and could disagree with them; the layers are the record."""
    layers = {}
    for d in layer_dirs():
        rel = str(d).replace(str(config.REPO_ROOT) + "\\", "").replace("\\", "/")
        if layerstate.is_complete(d):
            payload = dict(layerstate.read(d))
            payload.pop("rule", None)
            layers[rel] = _flatten_numbers(payload)

    tables = {}
    cat = build_catalog.CATALOG_DIR / "tables.json"
    if layerstate.is_complete(build_catalog.CATALOG_DIR) and cat.is_file():
        doc = json.loads(cat.read_text(encoding="utf-8"))
        for t in doc.get("tables", []):
            tables[t["table"]] = {"rows": t.get("rows", 0),
                                  "columns": t.get("columns", 0),
                                  "winner": t.get("winner", "")}
    return {"layers": layers, "tables": tables}


# --------------------------------------------------------------------------
# what changed
# --------------------------------------------------------------------------
def _fmt_delta(n) -> str:
    return f"+{n:,}" if n > 0 else f"{n:,}"


def _print_capped(rows) -> None:
    for line in rows[:MAX_LISTED]:
        print(line)
    if len(rows) > MAX_LISTED:
        print(f"    ... and {len(rows) - MAX_LISTED:,} more")


def print_diff(before: dict, after: dict) -> bool:
    """Print the since-last-run diff. Returns True if anything moved."""
    print(f"\n{'=' * 72}\n== what changed since the last run\n{'=' * 72}")

    b_t, a_t = before["tables"], after["tables"]
    if not b_t and not a_t:
        print("  no catalog on either side of this run - nothing to compare.")
    elif not b_t:
        rows = sum(t["rows"] for t in a_t.values())
        print(f"  first run with a catalog: {len(a_t):,} tables, {rows:,} rows. "
              f"No previous generation to diff against.")
        return True

    changed = False
    added = sorted(set(a_t) - set(b_t))
    removed = sorted(set(b_t) - set(a_t))
    common = sorted(set(a_t) & set(b_t))

    if added:
        changed = True
        print(f"\n  tables ADDED ({len(added):,}):")
        _print_capped([f"    + {n:<40} {a_t[n]['rows']:>10,} rows, "
                       f"{a_t[n]['columns']} cols" for n in added])
    if removed:
        changed = True
        print(f"\n  tables REMOVED ({len(removed):,}):")
        _print_capped([f"    - {n:<40} {b_t[n]['rows']:>10,} rows (was)"
                       for n in removed])

    row_moves = [(n, a_t[n]["rows"] - b_t[n]["rows"]) for n in common
                 if a_t[n]["rows"] != b_t[n]["rows"]]
    if row_moves:
        changed = True
        row_moves.sort(key=lambda x: (-abs(x[1]), x[0]))
        total = sum(d for _n, d in row_moves)
        print(f"\n  row-count deltas ({len(row_moves):,} tables, "
              f"net {_fmt_delta(total)} rows):")
        _print_capped([f"    {n:<40} {b_t[n]['rows']:>10,} -> "
                       f"{a_t[n]['rows']:>10,}  {_fmt_delta(d)}"
                       for n, d in row_moves])

    col_moves = [n for n in common if a_t[n]["columns"] != b_t[n]["columns"]]
    if col_moves:
        changed = True
        print(f"\n  COLUMN-COUNT changes ({len(col_moves):,}) - a table whose "
              f"width moved has re-numbered fields, so every fN reference to it "
              f"must be re-derived:")
        _print_capped([f"    {n:<40} {b_t[n]['columns']:>4} -> "
                       f"{a_t[n]['columns']:>4} columns" for n in col_moves])

    win_moves = [n for n in common if a_t[n]["winner"] != b_t[n]["winner"]]
    if win_moves:
        changed = True
        print(f"\n  winning archive moved ({len(win_moves):,}) - the table is "
              f"now resolved from a different point in the chain:")
        _print_capped([f"    {n:<40} {b_t[n]['winner']} -> {a_t[n]['winner']}"
                       for n in win_moves])

    lines = []
    for layer in sorted(set(before["layers"]) | set(after["layers"])):
        b_l = before["layers"].get(layer)
        a_l = after["layers"].get(layer)
        if b_l is None:
            lines.append(f"    {layer:<24} NEW")
            continue
        if a_l is None:
            lines.append(f"    {layer:<24} GONE (no sentinel now)")
            continue
        for k in sorted(set(b_l) | set(a_l)):
            bv, av = b_l.get(k), a_l.get(k)
            if bv != av:
                lines.append(f"    {layer:<24} {k:<22} {bv} -> {av}")
    if lines:
        changed = True
        print(f"\n  layer counts ({len(lines):,} changed):")
        _print_capped(lines)

    if not changed and (b_t or a_t):
        rows = sum(t["rows"] for t in a_t.values())
        print(f"  NO CHANGE. {len(a_t):,} tables, {rows:,} rows, every layer "
              f"count identical to the previous run.")
    return changed


# --------------------------------------------------------------------------
# reporting
# --------------------------------------------------------------------------
def state(directory) -> str:
    if not directory.is_dir():
        return "absent"
    return "complete" if layerstate.is_complete(directory) else "INCOMPLETE"


def rel(directory) -> str:
    return str(directory).replace(str(config.REPO_ROOT) + "\\", "")


def print_list() -> None:
    print(f"client: {config.CLIENT_DIR}\n")
    w = max(len(n) for n in NAMES)
    for name, _fn, dirs, what, _mod in STAGES:
        for d in dirs:
            print(f"  {name:<{w}}  {state(d):<10}  {rel(d):<24}  {what}")


def print_stage_summary(ran: list) -> None:
    print(f"\n{'=' * 72}\n== stages\n{'=' * 72}")
    w = max(len(n) for n, _s in ran) if ran else 1
    for name, secs in ran:
        dirs = next(s[2] for s in STAGES if s[0] == name)
        counts = []
        for d in dirs:
            payload = dict(layerstate.read(d)) if layerstate.is_complete(d) else {}
            payload.pop("rule", None)
            payload.pop("layer", None)
            payload.pop("generatedBy", None)
            flat = _flatten_numbers(payload)
            counts.append(f"{rel(d)}: " +
                          ", ".join(f"{k}={v:,}" if isinstance(v, int) else
                                    f"{k}={v}" for k, v in sorted(flat.items())))
        print(f"  {name:<{w}}  {secs:7.1f}s  {counts[0] if counts else ''}")
        for extra in counts[1:]:
            print(f"  {'':<{w}}  {'':>7}   {extra}")


def main(argv=None) -> int:
    ap = argparse.ArgumentParser(
        prog="python -m tools.extract_everything",
        description="Re-extract the entire client. No arguments needed.")
    ap.add_argument("--from", dest="start", choices=NAMES,
                    help="resume at this stage")
    ap.add_argument("--only", action="append", choices=NAMES,
                    help="run exactly this stage (repeatable)")
    ap.add_argument("--list", action="store_true",
                    help="show the stages and each layer's current state")
    a = ap.parse_args(argv)

    if a.list:
        print_list()
        return 0

    picked = STAGES
    if a.only:
        picked = [s for s in STAGES if s[0] in set(a.only)]
    elif a.start:
        picked = STAGES[NAMES.index(a.start):]
    picked_names = {s[0] for s in picked}

    print(f"client: {config.CLIENT_DIR}")
    print(f"repo:   {config.REPO_ROOT}")
    print(f"stages: {', '.join(s[0] for s in picked)}")

    before = snapshot()

    t0 = time.time()
    ran = []
    for name, fn, dirs, what, _mod in picked:
        print(f"\n{'=' * 72}\n== {name}: {what}\n{'=' * 72}", flush=True)
        t = time.time()
        fn()
        for d in dirs:
            if not layerstate.is_complete(d):
                raise SystemExit(
                    f"FATAL: stage {name} returned but {d} carries no "
                    f"{layerstate.SENTINEL}. Refusing to run later stages over "
                    f"a layer that did not finish.")
        secs = time.time() - t
        ran.append((name, secs))
        print(f"== {name}: complete in {secs:.1f}s", flush=True)

    # raw/README.md indexes the layers that exist ON DISK, and the stage that
    # writes it (raw_layers) is not the last one to build a layer. Rewriting it
    # here, after every stage this run touched, is what stops a fresh full
    # extraction from publishing a catalogue of the tree as it looked in the
    # middle of that same run.
    extract_raw_layers.write_root_readme()

    print_stage_summary(ran)
    print(f"\ntotal {time.time() - t0:.1f}s")
    print_diff(before, snapshot())

    print(f"\n{'=' * 72}\n== layers\n{'=' * 72}")
    print_list()

    stale = picked_names & CATALOG_INPUT_STAGES
    if stale and CATALOG_STAGE not in picked_names:
        print(f"\nWARNING: {', '.join(sorted(stale))} rewrote the table layer but "
              f"{CATALOG_STAGE} did not run, so raw/_catalog and CATALOG.md now "
              f"describe the PREVIOUS generation of the data, and the diff above "
              f"compared the catalog against itself. Run "
              f"`python -m tools.extract_everything --only {CATALOG_STAGE}`.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
