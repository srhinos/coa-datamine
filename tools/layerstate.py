"""Completion sentinels for the raw layers.

WHY THIS EXISTS
---------------
Every extractor in this repo clears its output directory before it writes, so a
crash between the delete and the last write leaves the tree HALF EXTRACTED -
the exact state the directive forbids, and one that is indistinguishable from a
finished run by looking at the files. Three real crashes during the audit left
383 deleted shards, then 99 files, then 979 files, and every reader downstream
carried on as if the layer were whole.

THE RULE
--------
A layer directory is trustworthy only while it carries `_complete.json`.

    begin(dir)              removes the sentinel BEFORE anything destructive
    finish(dir, payload)    writes the sentinel LAST, after every other byte
    require_complete(dir)   a reader refuses to read a layer without one

So the window in which a layer is unreliable is exactly the window in which the
sentinel is absent, and that window opens before the first delete rather than
after it. A killed process leaves no sentinel; a finished one leaves a sentinel
whose counts describe what it wrote.

WHY A SENTINEL AND NOT A TEMP-DIR SWAP
--------------------------------------
`raw/tables` is 132 MB across 8,611 files and `raw/interface_all` re-reads 4.4
GB; staging either in a sibling directory doubles the disk cost of every run and
still leaves a non-atomic window on Windows, where a directory rename over an
existing directory is not one operation. The sentinel costs one file and makes
the half-written state DETECTABLE, which is what the readers actually need.
`atomic_write` below is used for the individual index files, where a rename IS
atomic and therefore free.

DETERMINISM
-----------
The sentinel carries no wall-clock time and no host detail - only the layer
name, the command that regenerates it, and counts the run measured. Two runs
over an unchanged client write byte-identical sentinels, so it does not break
the byte-for-byte reproduction gates.
"""
import json
import os
from pathlib import Path

SENTINEL = "_complete.json"

RULE = (
    "A raw layer is trustworthy only while it carries `_complete.json`. Every "
    "extractor removes that file BEFORE it deletes anything and writes it back "
    "LAST, after all of its output, so a layer left half-written by a crash is "
    "detectable rather than silently readable. Readers and tests refuse a layer "
    "that has no sentinel. The sentinel holds no timestamp, so it does not "
    "affect byte-for-byte reproduction.")


def sentinel_path(layer_dir) -> Path:
    return Path(layer_dir) / SENTINEL


def begin(layer_dir) -> None:
    """Invalidate the layer before touching it. Call this BEFORE the delete."""
    p = sentinel_path(layer_dir)
    p.parent.mkdir(parents=True, exist_ok=True)
    if p.is_file():
        p.unlink()


def finish(layer_dir, payload: dict) -> Path:
    """Mark the layer whole. Call this AFTER the last byte of output is written."""
    p = sentinel_path(layer_dir)
    body = dict(payload)
    body["rule"] = RULE
    p.parent.mkdir(parents=True, exist_ok=True)
    atomic_write(p, json.dumps(body, ensure_ascii=False, indent=1,
                               sort_keys=True).encode("utf-8") + b"\n")
    return p


def is_complete(layer_dir) -> bool:
    return sentinel_path(layer_dir).is_file()


def read(layer_dir) -> dict:
    return json.loads(sentinel_path(layer_dir).read_bytes().decode("utf-8"))


def require_complete(layer_dir, regenerate: str) -> dict:
    """Refuse to read a layer with no sentinel, naming the command that fixes it."""
    d = Path(layer_dir)
    if not d.is_dir():
        raise SystemExit(f"FATAL: {d} does not exist. Run `{regenerate}`.")
    if not is_complete(d):
        raise SystemExit(
            f"FATAL: {d} has no {SENTINEL}, so it is either half-written by an "
            f"interrupted run or was never finished. Refusing to read a "
            f"possibly-incomplete layer. Run `{regenerate}`.")
    return read(d)


def atomic_write(path, data: bytes) -> None:
    """Write via a temp file in the same directory + os.replace, which is atomic
    on both POSIX and Windows. A killed process leaves the previous file intact
    rather than a truncated one."""
    p = Path(path)
    p.parent.mkdir(parents=True, exist_ok=True)
    tmp = p.with_name(p.name + ".tmp")
    with open(tmp, "wb") as f:
        f.write(data)
        f.flush()
        os.fsync(f.fileno())
    os.replace(tmp, p)


def clear_dir(layer_dir, keep=()) -> int:
    """Delete a layer's contents after invalidating it. The sentinel is removed
    first by begin(), so the destructive part can never run while the layer
    still looks whole."""
    d = Path(layer_dir)
    begin(d)
    keep = {k.lower() for k in keep}
    n = 0
    if not d.is_dir():
        d.mkdir(parents=True, exist_ok=True)
        return 0
    for old in sorted(d.rglob("*"), reverse=True):
        if old.is_file():
            if old.name.lower() in keep:
                continue
            old.unlink()
            n += 1
        elif old.is_dir():
            try:
                old.rmdir()
            except OSError:
                pass          # not empty: a kept file lives under it
    return n
