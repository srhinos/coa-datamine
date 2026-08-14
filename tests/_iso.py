"""Test isolation: give a test its own writable tree, and stop it writing the repo's.

WHY THIS EXISTS
---------------
The suite is 38 plain assert scripts run as separate processes, and 30 of them
used to REBUILD part of the repo as an import side effect: `data/`, `raw/`, and
- worst - `work/dbc`, whose bytes every later test reads. `work/dbc` had two
writers with different sources: `curate.materialize_inputs()` copies it out of
the SEALED SNAPSHOT (`work/snapshot`, taken by `datamine.py`), while
`extract_mpq.extract_all()` re-reads the LIVE client, which auto-patches and has
drifted past that snapshot (Spell 209,206 -> 209,215 and friends). Six tests
called the second one, so a test's result depended on which tests had run before
it - measured at 35P/3F solo, 34P/4F in sequence, 32P/6F on a second sequence
over the leftovers. See tests/_diagnosis.md.

WHAT `sandbox()` DOES
---------------------
1. Repoints `config.CLIENT_DIR` at the sealed snapshot, so anything that reads
   client bytes reads the same bytes `data/` and `raw/` were built from. The
   live client is then off-limits entirely - reading it is what made results
   depend on when the launcher last patched.
2. Redirects the writable roots the caller names (`data`, `raw`, `work`) into a
   scratch directory this process owns and deletes on exit, seeded from the
   committed tree so a builder that reads a sibling layer still finds it.
3. Arms an audit hook that turns any write to a NON-redirected committed root
   into an immediate, named failure. Isolation is therefore enforced rather than
   asserted: a builder that grows a new hardcoded output path cannot quietly
   start dirtying the tree again, and a test author who forgets a root gets told
   which path and which root, not a mystery diff in `git status`.

USAGE - first thing after the sys.path line, BEFORE importing any builder
(`tools/build_catalog.py` and `tools/build_items.py` freeze their output paths at
import time, so the redirect has to be in place first):

    sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
    from tests import _iso; _iso.sandbox(data=True)
    from tools import build_spells

Each root takes False (leave it pointing at the committed tree, read-only and
guarded), True (scratch, seeded with the whole committed tree), or a list of
subpaths (scratch, seeded with just those - `raw=True` copies 726 MB, so a test
that only needs `raw/content` should say `raw=["content"]`).
"""
import atexit
import os
import shutil
import sys
import tempfile
import time
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from tools import config

REPO_ROOT = config.REPO_ROOT
SNAPSHOT_DIR = config.WORK_DIR / "snapshot"
# The live client, captured BEFORE any redirect: the guard below has to know the
# path it is forbidding even after config no longer points at it.
LIVE_CLIENT = config.CLIENT_DIR

# Committed (or shared) roots a test must not write. `work/` is gitignored but is
# not free-for-all: work/dbc + work/realms + work/curation_inputs.json are the
# materialized snapshot every builder reads, single-writer-owned by datamine.py.
_PROTECTED = {
    "data": REPO_ROOT / "data",
    "raw": REPO_ROOT / "raw",
    "work": REPO_ROOT / "work",
    "catalog": REPO_ROOT / "CATALOG.md",
}

_scratch = None
_armed = False
_allowed = []          # str prefixes (lowercased) writes may land under


SCRATCH_ROOT = REPO_ROOT / "work" / "_test"
_allowed.append(str(SCRATCH_ROOT).lower())   # the one writable island inside work/


def scratch_dir() -> Path:
    """This process's scratch root, created on first use and removed at exit.

    It lives under `work/` - gitignored, and already this repo's scratch space -
    rather than in %TEMP%, because several repo-relative behaviours are load
    bearing: tools/fetch_coatalents.py records a quarantined page as a path
    relative to REPO_ROOT, and tests/test_sharding.py reports offending files the
    same way. A scratch tree on another volume silently changes what those paths
    mean; one inside the repo does not."""
    global _scratch
    if _scratch is None:
        SCRATCH_ROOT.mkdir(parents=True, exist_ok=True)
        _sweep_stale()
        _scratch = Path(tempfile.mkdtemp(
            dir=SCRATCH_ROOT, prefix=f"{Path(sys.argv[0]).stem or 'iso'}-"))
        atexit.register(_cleanup)
    return _scratch


def _sweep_stale(max_age_s: int = 12 * 3600) -> None:
    """Drop scratch trees a crashed run left behind. Age-gated so a suite running
    beside this one is never touched."""
    now = time.time()
    for p in SCRATCH_ROOT.iterdir():
        try:
            if p.is_dir() and now - p.stat().st_mtime > max_age_s:
                shutil.rmtree(p, ignore_errors=True)
        except OSError:
            pass


def _cleanup():
    """Never raises: this runs from atexit, after the test has already decided
    whether it passed, and a transient lock on one scratch file must not turn a
    green test red. A tree that survives all three attempts is swept by the next
    run's _sweep_stale()."""
    for _ in range(3):
        if _scratch is None or not _scratch.is_dir():
            return
        shutil.rmtree(_scratch, ignore_errors=True)


def _seed(src: Path, dst: Path, what) -> None:
    """Copy the committed tree (or the named subpaths of it) into the scratch root."""
    dst.mkdir(parents=True, exist_ok=True)
    if what is True:
        if src.is_dir():
            shutil.copytree(src, dst, dirs_exist_ok=True)
        return
    for name in what:
        s = src / name
        if not s.exists():
            continue
        d = dst / name
        d.parent.mkdir(parents=True, exist_ok=True)
        if s.is_dir():
            shutil.copytree(s, d, dirs_exist_ok=True)
        else:
            shutil.copyfile(s, d)


def _redirect(root: str, what) -> Path:
    """Point config's paths for `root` at scratch, seeded per `what`."""
    dst = scratch_dir() / root
    _seed(_PROTECTED[root], dst, what)
    if root == "data":
        config.DATA_DIR = dst
        config.DATA_REALMS_DIR = dst / "realms"
    elif root == "raw":
        config.RAW_DIR = dst
        config.RAW_DBC_DIR = dst / "dbc"
        config.RAW_CONTENT_DIR = dst / "content"
        config.RAW_INTERFACE_DIR = dst / "interface"
        config.RAW_TALENTS_DIR = dst / "talents"
        config.RAW_REALMS_DIR = dst / "realms"
    elif root == "work":
        config.WORK_DIR = dst
        config.WORK_DBC_DIR = dst / "dbc"
        config.WORK_REALMS_DIR = dst / "realms"
    _allowed.append(str(dst).lower())
    return dst


def own_dir(name: str) -> Path:
    """A scratch directory the test owns outright, for a builder that takes an
    output path. Nothing else in the process writes here."""
    d = scratch_dir() / name
    d.mkdir(parents=True, exist_ok=True)
    _allowed.append(str(d).lower())
    return d


def use_snapshot_client() -> Path:
    """Read client bytes from the sealed snapshot, never from the live client.

    `work/snapshot` is what `datamine.py` copied out of the client and then built
    everything from; extracting from it reproduces `work/curation_inputs.json`
    byte for byte (all 111 base tables), which is exactly what the pinned record
    counts in this suite were measured against."""
    if not (SNAPSHOT_DIR / "Data").is_dir():
        raise SystemExit(
            f"FATAL: no sealed client snapshot at {SNAPSHOT_DIR} - run "
            "`python datamine.py` once. Tests read the snapshot, never the live "
            "client: the client auto-patches, and a test whose expected record "
            "counts move when the launcher runs is not a test.")
    config.CLIENT_DIR = SNAPSHOT_DIR
    config.MPQ_DIRS = [SNAPSHOT_DIR / "Data", SNAPSHOT_DIR / "Data" / "enUS"]
    config.CONTENT_DIR = SNAPSHOT_DIR / "Data" / "Content"
    return SNAPSHOT_DIR


_WRITE_EVENTS = {"os.remove", "os.rmdir", "os.rename", "os.replace",
                 "os.truncate", "shutil.rmtree", "shutil.copyfile",
                 "shutil.copymode", "shutil.copystat"}
_WRITE_FLAGS = os.O_WRONLY | os.O_RDWR | os.O_APPEND | os.O_CREAT | os.O_TRUNC


def _under(path: str, root: str) -> bool:
    return path == root or path.startswith(root + os.sep)


def _violation(path) -> str:
    try:
        p = os.fsdecode(path)
    except (TypeError, ValueError):                       # pragma: no cover
        return ""
    if not p:
        return ""
    low = os.path.abspath(p).lower()
    if any(_under(low, ok) for ok in _allowed):
        return ""
    for name, root in _PROTECTED.items():
        if _under(low, str(root).lower()):
            return name
    return ""


def _hook(event, args):
    if event == "open":
        path, mode, flags = args
        if isinstance(mode, str):
            if not any(c in mode for c in "wax+"):
                return
        elif not (flags & _WRITE_FLAGS):
            return
    elif event == "os.mkdir":
        path = args[0]
        # mkdir(exist_ok=True) on a directory that is already there is not a
        # write; every builder's ensure_dirs() does it on every run.
        if os.path.isdir(path):
            return
    elif event in _WRITE_EVENTS:
        path = args[-1] if event in ("os.rename", "os.replace") else args[0]
    else:
        return
    root = _violation(path)
    if root:
        raise RuntimeError(
            f"test isolation violation: this test wrote {path} - inside the "
            f"committed `{root}` root it did not sandbox. Pass {root}=True (or a "
            f"list of subpaths to seed) to _iso.sandbox(), or point the builder "
            f"at a directory the test owns. Tests must leave the tree byte-clean; "
            f"see tests/_iso.py and tests/_diagnosis.md.")


def _arm():
    global _armed
    if _armed:
        return
    _armed = True
    live = str(LIVE_CLIENT).lower()

    def guard(event, args):
        # The live client is off-limits to the whole suite, read or write: it
        # auto-patches, so any byte read from it makes a result depend on the
        # launcher's clock rather than on the code under test.
        if event == "open" and args[0]:
            p = str(args[0]).lower()
            if p.startswith(live + os.sep):
                raise RuntimeError(
                    f"test isolation violation: this test read the LIVE client "
                    f"({args[0]}). The client auto-patches; tests read the sealed "
                    f"snapshot at {SNAPSHOT_DIR}. _iso.sandbox() already repoints "
                    f"config.CLIENT_DIR - this path was hardcoded.")
        _hook(event, args)

    sys.addaudithook(guard)


def sandbox(*, data=False, raw=False, work=False, work_dbc=False,
            work_realms=False, client=True) -> Path:
    """Isolate this test. Returns the scratch root (also `_iso.scratch_dir()`).

    data/raw/work: False = stay on the committed root, guarded read-only;
    True = scratch seeded with the whole tree; list = scratch seeded with those
    subpaths only.

    work_dbc/work_realms redirect just that one materialized-input directory,
    leaving the rest of `work/` where it is - what an extractor test needs, since
    it writes one of them while still reading the other.
    """
    if client:
        use_snapshot_client()
    for root, what in (("data", data), ("raw", raw), ("work", work)):
        if what is not False:
            _redirect(root, what)
    if work_dbc is not False:
        config.WORK_DBC_DIR = own_dir("work_dbc")
        if work_dbc is True:
            _seed(_PROTECTED["work"] / "dbc", config.WORK_DBC_DIR, True)
    if work_realms is not False:
        config.WORK_REALMS_DIR = own_dir("work_realms")
        if work_realms is True:
            _seed(_PROTECTED["work"] / "realms", config.WORK_REALMS_DIR, True)
    _arm()
    return scratch_dir()
