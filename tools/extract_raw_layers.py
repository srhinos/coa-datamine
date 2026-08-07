"""One entry point for the non-DBC raw layers: content, interface, cache.

    python -m tools.extract_raw_layers            # all three, then raw/README.md
    python -m tools.extract_raw_layers --only cache

Plain script, no agent, no manual step, deterministic: rerunning it on an
unchanged client rewrites byte-identical output. It reads the client and the
committed inventory; it never reads the curated `data/` tree, so it cannot
inherit a curation decision from it.

ORDER AND DEPENDENCIES
----------------------
`interface` is derived from `raw/_inventory/files/` and cross-checks every
sha256 it re-reads against it, so `python -m tools.inventory` must have run at
least once (it is committed, so normally it has). `content` and `cache` read the
client directly and depend on nothing else. The stages do not depend on each
other and can be run in any order or alone.

The DBC layer is NOT run from here - it has its own entry points
(`tools.extract_all` + `tools.decode_all`) and takes far longer. The final
`raw/README.md` this writes indexes every raw layer present, including those.
"""
import argparse
import json
import time
from pathlib import Path

from tools import config, extract_cache, extract_content, extract_interface_all
from tools.decode_all import write_text

STAGES = {
    "content": (extract_content.extract_all,
                "Data\\Content JSON + the .loc localization store"),
    "interface": (extract_interface_all.extract_all,
                  "every path under Interface\\ in the MPQ chain"),
    "cache": (extract_cache.extract_all,
              "Cache\\WDB query caches, base and per realm"),
}

# Every raw layer this repo can hold, with the file an agent should open first.
# Layers absent from disk are simply not listed in the generated README - the
# catalog describes what IS there, never what was expected to be there.
LAYERS = [
    ("_inventory", "README.md", "complete census of every file in the client"),
    ("tables", "index.json", "every DBC table, decoded, positional f0..fN"),
    ("dbc", None, "raw DBC bodies as extracted from the MPQ chain"),
    ("content", "index.json", "loose Data\\Content: JSON payloads + .loc localization"),
    ("interface", "_manifest.json", "Interface code layer (.lua/.xml/.toc) as bytes"),
    ("interface_all", "index.json", "every Interface path: size, sha256, text/binary"),
    ("cache", "index.json", "Cache\\WDB server query caches, per realm"),
    ("realms", None, "realm-overlay diff artifacts"),
    ("talents", None, "frozen capture of the external CoA talent builder"),
]


def _headline(d: Path, index_name) -> str:
    """A one-line size/count summary read OUT of the layer's own index, never
    hardcoded here - so this catalog cannot drift from the layers it indexes."""
    files = sum(1 for p in d.rglob("*") if p.is_file())
    size = sum(p.stat().st_size for p in d.rglob("*") if p.is_file())
    bits = [f"{files:,} files", f"{size/1e6:,.1f} MB"]
    if index_name and (d / index_name).is_file() and index_name.endswith(".json"):
        try:
            ix = json.loads((d / index_name).read_text(encoding="utf-8"))
        except Exception:
            return " / ".join(bits)
        for k in ("pathCount", "fileCount", "recordTotal", "locRecordTotal",
                  "count", "rows"):
            if isinstance(ix.get(k), int):
                bits.append(f"{k} {ix[k]:,}")
    return " / ".join(bits)


def write_root_readme() -> str:
    rows = []
    for name, index_name, what in LAYERS:
        d = config.RAW_DIR / name
        if not d.is_dir():
            continue
        entry = f"`raw/{name}/{index_name}`" if index_name else f"`raw/{name}/`"
        rows.append(f"| `{name}` | {what} | {entry} | {_headline(d, index_name)} |")
    text = f"""# raw/ - the client, mechanically extracted (generated)

Everything under `raw/` is written by a script in `tools/` from the client at
`{config.CLIENT_DIR}`. Nothing in it is hand-authored, hand-labelled or
hand-selected: column names are positional, types are inferred by measurement,
and no wanted-list decides what is extracted. Rerunning the scripts on an
unchanged client reproduces it byte for byte.

## Start here

| layer | what it holds | open first | size |
| --- | --- | --- | --- |
{chr(10).join(rows)}

## Regenerating

```
python -m tools.inventory            # census of every file in the client (~25 min)
python -m tools.extract_all          # pull DBC bodies out of the MPQ chain
python -m tools.decode_all           # decode every table to raw/tables/
python -m tools.extract_interface    # Interface code layer -> raw/interface/
python -m tools.extract_raw_layers   # content + interface census + WDB caches
```

Each stage is independent and each writes its own `index.json`/`README.md`
describing its own rules. No stage requires an LLM, an argument or a decision.

## The two rules that matter most when reading any of this

1. **The realm overlay outranks the whole base chain.** `Data\\<realm>\\` sits
   above every base and locale archive. Twelve tables - `Spell.dbc` among them -
   are won there, and the realm copy carries 14% more spells than the base one.
   The same is true of `Cache\\WDB\\<locale>\\<realm>\\` against its parent.
   Reading only the base layer silently loses live content.
2. **Columns are positional and types are measured.** `f5` means column 5. A
   type is what the bytes support, recorded with the counts behind it, not what
   a name suggests. Where a field layout IS named (the WDB caches), it was
   applied only because it consumed every record exactly, and its source is
   recorded next to it.
"""
    write_text(config.RAW_DIR / "README.md", text)
    return text


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--only", choices=sorted(STAGES), action="append",
                    help="run just this stage (repeatable)")
    ap.add_argument("--quiet", action="store_true")
    args = ap.parse_args()

    names = args.only or list(STAGES)
    out = {}
    for name in names:
        fn, what = STAGES[name]
        t = time.time()
        print(f"== {name}: {what}")
        ix = fn(verbose=not args.quiet)
        out[name] = ix
        print(f"== {name}: done in {time.time() - t:.1f}s")
    write_root_readme()

    print("\n---- summary ----")
    if "content" in out:
        c = out["content"]
        print(f"content   files={c['fileCount']} json={c['jsonCount']} "
              f"loc={c['locCount']} locRecords={c['locRecordTotal']:,} "
              f"failures={c['failureCount']}")
    if "interface" in out:
        i = out["interface"]
        print(f"interface paths={i['pathCount']:,} text={i['textCount']:,} "
              f"binary={i['binaryCount']:,} unreadable={i['unreadableCount']} "
              f"sha256Mismatches={i['sha256MismatchCount']}")
    if "cache" in out:
        k = out["cache"]
        print(f"cache     files={k['fileCount']} records={k['recordTotal']:,} "
              f"tiers={k['tierCounts']}")
    return out


if __name__ == "__main__":
    main()
