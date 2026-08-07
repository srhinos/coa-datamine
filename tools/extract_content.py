"""Complete extraction of the loose `Data\\Content\\` tree.

WHAT IS IN THERE
----------------
Two things, both outside the MPQ chain, both loose on disk:

  * `Data\\Content\\*.json` - Ascension's own content payloads (character
    advancement, spell/enchantment suggestion graphs, trade-skill recipes,
    LFG, world-map areas...). Copied VERBATIM: they are already JSON, already
    the client's own bytes, and re-serializing them would put this pipeline's
    formatting between an agent and the source.
  * `Data\\Content\\Localization\\<Entity>\\<Field>\\<locale>.loc` - an
    undocumented binary localization store. Decoded by `tools/loc.py`, which
    accepts a decode only if it consumes the file exactly (see that module).

COMPLETENESS
------------
This walks the WHOLE tree with rglob and records EVERY file it finds, including
files of extensions nobody anticipated and files of zero length. There is no
wanted-list, and a file this module cannot decode is written to the index with
`decoded: false` and its measured failure - never omitted. The index's
`fileCount` is the count of files on disk, so a file that stopped being handled
would show up as an undecoded row rather than as a silent absence.

The three zero-byte `Transmogrification*.json` files are a real property of this
client (the launcher blanked them), not a read failure; they are recorded at
their true size with `bytes: 0`.

WHAT THIS MODULE OWNS
---------------------
`raw/content/index.json`, `raw/content/README.md` and everything under
`raw/content/localization/`. The verbatim top-level JSON copies are written by
`tools/snapshot_content.py`, which this module calls - that module stays their
single writer so the existing snapshot gate keeps testing the thing it tests.
"""
import hashlib
import json

from tools import config, layerstate, loc, rawshard, snapshot_content
from tools.decode_all import write_text

LOCALIZATION_DIR = config.RAW_CONTENT_DIR / "localization"

# The two fields a decoded .loc record carries. They are not column names taken
# from anywhere - the format has exactly two members per record (see tools/loc.py)
# and these are this module's labels for them, published in the index so readers
# never have to hardcode them.
KEY_FIELD = "id"
TEXT_FIELD = "text"


def _rel_parts(path):
    return path.relative_to(config.CONTENT_DIR).parts


def _group_key(parts):
    """('Localization','Spell','Name','deDE.loc') -> ('Spell/Name', 'deDE')."""
    entity = "/".join(parts[1:-1])
    locale = parts[-1].rsplit(".", 1)[0]
    return entity, locale


def extract_all(verbose: bool = True) -> dict:
    config.ensure_dirs()
    if not config.CONTENT_DIR.is_dir():
        raise SystemExit(f"FATAL: {config.CONTENT_DIR} does not exist")

    # Invalidate before the first destructive write below, never after the last.
    layerstate.begin(config.RAW_CONTENT_DIR)

    # ---- pass 1: verbatim JSON snapshot (existing single writer) ----
    snap = snapshot_content.snapshot()

    # ---- pass 2: census EVERY file in the tree ----
    files = sorted(p for p in config.CONTENT_DIR.rglob("*") if p.is_file())

    # ---- pass 3: decode the .loc store ----
    if LOCALIZATION_DIR.exists():
        for old in sorted(LOCALIZATION_DIR.rglob("*"), reverse=True):
            old.unlink() if old.is_file() else old.rmdir()
    groups, entries, failures = {}, [], []

    for p in files:
        parts = _rel_parts(p)
        data = p.read_bytes()
        rec = {"path": "/".join(parts), "bytes": len(data),
               "sha256": hashlib.sha256(data).hexdigest()}
        if p.suffix.lower() == ".loc":
            entity, locale = _group_key(parts)
            try:
                rows = loc.read(data)
            except loc.LocError as e:
                rec.update({"kind": "loc", "decoded": False, "error": str(e),
                            "evidence": e.evidence})
                failures.append(rec)
                entries.append(rec)
                continue
            texts = [{KEY_FIELD: rid, TEXT_FIELD: t} for rid, t in rows]
            out = LOCALIZATION_DIR / entity.replace("/", "/") / locale
            frag = rawshard.write_group(out, texts, lambda r: r[KEY_FIELD])
            rec.update({"kind": "loc", "decoded": True, "records": len(texts),
                        "entity": entity, "locale": locale,
                        "nonEmpty": sum(1 for t in texts if t["text"]),
                        "dir": f"localization/{entity}/{locale}",
                        "shardCount": frag["shardCount"], "format": frag["format"],
                        "storedBytes": frag["storedBytes"]})
            groups[f"{entity}/{locale}"] = {
                "entity": entity, "locale": locale, "source": "/".join(parts),
                # This module WRITES the record keys, so it is the only honest
                # place to say what they are. Naming them here means a consumer
                # (tools/find.py) reads the key field out of the index instead of
                # carrying a column name of its own - no reader in this repo is
                # allowed to know a column's name a priori.
                "keyField": KEY_FIELD, "textField": TEXT_FIELD,
                "records": len(texts), "sourceBytes": len(data), **frag}
        elif p.suffix.lower() == ".json" and len(parts) == 1:
            rec.update({"kind": "json", "decoded": True,
                        "copiedTo": parts[-1],
                        "snapshotSha256": snap[parts[-1]]["sha256"]})
            if rec["sha256"] != rec["snapshotSha256"]:
                raise SystemExit(f"FATAL: verbatim copy of {parts[-1]} does not "
                                 f"hash to its source")
        else:
            # nothing is skipped: an unanticipated file is recorded as undecoded
            rec.update({"kind": "unhandled", "decoded": False,
                        "error": "no decoder for this extension/location; bytes "
                                 "are on the client and hashed here, not copied"})
            failures.append(rec)
        entries.append(rec)
        if verbose and rec.get("kind") == "loc":
            print(f"  {rec['path']:52s} {rec.get('records', 0):7d} records "
                  f"{'ok' if rec['decoded'] else 'FAILED'}")

    locs = [e for e in entries if e["kind"] == "loc"]
    index = {
        "note": "Every file under Data\\Content, decoded or not. `localization` "
                "shards live under localization/<Entity>/<Field>/<locale>/.",
        "clientDir": str(config.CLIENT_DIR),
        "fileCount": len(entries),
        "jsonCount": sum(1 for e in entries if e["kind"] == "json"),
        "locCount": len(locs),
        "unhandledCount": sum(1 for e in entries if e["kind"] == "unhandled"),
        "failureCount": len(failures),
        "locRecordTotal": sum(e.get("records", 0) for e in locs),
        "sourceBytes": sum(e["bytes"] for e in entries),
        "locFormat": loc.FORMAT,
        "locValidation": loc.VALIDATION,
        "shardRule": rawshard.SHARD_RULE,
        "compressionRule": rawshard.COMPRESSION_RULE,
        "files": entries,
        "localizationGroups": [groups[k] for k in sorted(groups)],
        "failures": failures,
    }
    write_text(config.RAW_CONTENT_DIR / "index.json",
               json.dumps(index, ensure_ascii=False, indent=1, sort_keys=True) + "\n")
    write_text(config.RAW_CONTENT_DIR / "README.md", _readme(index))
    layerstate.finish(config.RAW_CONTENT_DIR, {
        "layer": "raw/content", "generatedBy": "python -m tools.extract_content",
        "fileCount": index["fileCount"], "locCount": index["locCount"],
        "locRecordTotal": index["locRecordTotal"],
        "failureCount": index["failureCount"]})
    return index


def _readme(ix: dict) -> str:
    failed = [f for f in ix["failures"] if f.get("kind") == "loc"]
    closure = (f"All {ix['locCount']} files decode to exact closure, so no `.loc` "
               f"bytes are shipped undecoded."
               if not failed else
               f"{ix['locCount'] - len(failed)} of {ix['locCount']} files decode to "
               f"exact closure. The {len(failed)} that do not are listed under "
               f"`failures` in index.json with the offset they reached - their bytes "
               f"are still on the client and hashed here, and NOTHING partial was "
               f"shipped for them.")
    by_entity = {}
    for g in ix["localizationGroups"]:
        e = by_entity.setdefault(g["entity"], {"locales": 0, "records": 0, "bytes": 0})
        e["locales"] += 1
        e["records"] += g["records"]
        e["bytes"] += g["storedBytes"]
    rows = "\n".join(
        f"| `{k}` | {v['locales']} | {v['records']:,} | {v['bytes']/1e6:.2f} |"
        for k, v in sorted(by_entity.items()))
    return f"""# Loose client content (generated)

Regenerate: `python -m tools.extract_content`. Written by `tools/extract_content.py`
from `{ix['clientDir']}\\Data\\Content`. Nothing in this directory is hand-authored
and nothing in that tree is filtered out of it.

## Totals

- **{ix['fileCount']} files** in the client tree ({ix['sourceBytes']/1e6:.1f} MB on disk)
- **{ix['jsonCount']} JSON payloads**, copied verbatim (byte-identical, sha256 checked against source)
- **{ix['locCount']} `.loc` localization files**, {ix['locRecordTotal']:,} records decoded
- **{ix['failureCount']} failures** (`index.json` -> `failures`)

## Layout

```
raw/content/index.json         every file: bytes, sha256, decode status
raw/content/README.md          this file
raw/content/<Name>.json        verbatim copy of Data\\Content\\<Name>.json
raw/content/localization/<Entity>/<Field>/<locale>/<lo>-<hi>.jsonl[.gz]
                               one record per line: {{"id":..,"text":".."}}
```

## The `.loc` format

Undocumented in the client and nowhere else. Decoded, not guessed:

```
{ix['locFormat']}
```

{ix['locValidation']}

{closure} `id` is the id of the entity the directory names - `Spell/Name/deDE.loc`
record id 17 is spell 17 - which was established by reading the ids out and
matching them against known spell and item ids, not by assuming it.

| entity/field | locales | records | MB stored |
| --- | ---: | ---: | ---: |
{rows}

## Sharding and compression

{ix['shardRule']}

{ix['compressionRule']}
"""


def main():
    ix = extract_all()
    print(f"content files: {ix['fileCount']} "
          f"(json={ix['jsonCount']}, loc={ix['locCount']}, "
          f"unhandled={ix['unhandledCount']}, failures={ix['failureCount']})")
    print(f"loc records: {ix['locRecordTotal']}")


if __name__ == "__main__":
    main()
