"""THE entry point. Rebuilds every raw layer from the client, in dependency
order, with no agent and no decision:

    python -m tools.build_raw

The spec asks for one command that regenerates everything. There were five, in
an order documented nowhere complete (`raw/README.md`'s regeneration block did
not even mention the catalog), which meant the searchable layer could silently
be a generation behind the data it describes. This module is that one command;
the stages remain individually runnable and unchanged.

ORDER, AND WHY IT IS THIS ORDER
-------------------------------
    1 inventory           census of every archive + path. Nothing else can run
                          first: interface_all is derived from it, and
                          extract_all takes its chain order from it.
    2 extract_all         pull every DBFilesClient body out of the winning chain
                          (into work/, not committed)
    3 decode_all          decode all of them to raw/tables/  [needs 2]
    4 extract_interface   the Interface code layer as bytes -> raw/interface/
    5 extract_raw_layers  content/.loc + the Interface census + the WDB caches
                          [the census needs 1 and reuses 4's bytes]
    6 build_catalog       the search catalog over raw/tables/  [needs 3]

Every stage writes `_complete.json` LAST (tools/layerstate.py) and drops it
BEFORE it deletes anything, so an interrupted build leaves layers that read as
unfinished rather than as smaller-but-plausible. This runner refuses to continue
past a stage whose layer did not come back complete, because the whole point of
the sentinel is that nothing downstream builds on a half-written layer.

    --from decode_all     resume at a stage (the earlier layers must be complete)
    --only interface      run exactly one stage
    --list                print the stage list and each layer's current state
"""
import argparse
import sys
import time

from tools import (build_catalog, config, decode_all, extract_all,
                   extract_interface, extract_raw_layers, inventory,
                   layerstate)

# (name, callable, layer directories the stage must leave complete, what it does)
STAGES = [
    ("inventory", lambda: inventory.build(),
     [config.RAW_DIR / "_inventory"],
     "census every archive and every path in the client"),
    ("extract_all", lambda: extract_all.extract(),
     [extract_all.OUT_DIR],
     "pull every DBFilesClient body out of the winning chain"),
    ("decode_all", lambda: decode_all.run(),
     [decode_all.OUT_DIR],
     "decode every table to raw/tables/, positional f0..fN"),
    ("extract_interface", lambda: extract_interface.extract_all(),
     [config.RAW_INTERFACE_DIR],
     "the Interface code layer, as bytes"),
    ("raw_layers", lambda: extract_raw_layers.main_stages(),
     [config.RAW_CONTENT_DIR, config.RAW_DIR / "interface_all",
      config.RAW_DIR / "cache"],
     "Data\\Content + .loc, the Interface census, the WDB caches"),
    ("build_catalog", lambda: build_catalog.run(),
     [build_catalog.CATALOG_DIR],
     "the searchable catalog over raw/tables/"),
]

NAMES = [s[0] for s in STAGES]


def state(directory) -> str:
    if not directory.is_dir():
        return "absent"
    return "complete" if layerstate.is_complete(directory) else "INCOMPLETE"


def print_list() -> None:
    print(f"client: {config.CLIENT_DIR}\n")
    w = max(len(n) for n in NAMES)
    for name, _fn, dirs, what in STAGES:
        for d in dirs:
            rel = str(d).replace(str(config.REPO_ROOT) + "\\", "")
            print(f"  {name:<{w}}  {state(d):<10}  {rel:<24}  {what}")


def main(argv=None) -> int:
    ap = argparse.ArgumentParser(prog="python -m tools.build_raw",
                                 description=__doc__.splitlines()[0])
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

    t0 = time.time()
    for name, fn, dirs, what in picked:
        print(f"\n{'=' * 72}\n== {name}: {what}\n{'=' * 72}", flush=True)
        t = time.time()
        fn()
        for d in dirs:
            if not layerstate.is_complete(d):
                raise SystemExit(
                    f"FATAL: stage {name} returned but {d} carries no "
                    f"{layerstate.SENTINEL}. Refusing to run later stages over "
                    f"a layer that did not finish.")
        print(f"== {name}: complete in {time.time() - t:.1f}s", flush=True)

    print(f"\nall stages complete in {time.time() - t0:.1f}s")
    print_list()
    return 0


if __name__ == "__main__":
    sys.exit(main())
