"""The isolation guard's own gates.

tests/_iso.py is what makes every other test's isolation claim credible, so its
blind spots are pinned here directly.

The os.rename case exists because it was a real hole: CPython raises the
`os.rename` audit event for BOTH os.rename and os.replace, with args
(src, dst, src_dir_fd, dst_dir_fd). Reading args[-1] yields an integer fd, not
the destination path, so the guard passed every rename silently - and
os.replace is exactly how tools/emit.py publishes staged layers over the
committed roots. A guard blind to it cannot see the widest writer in the repo.
"""
import os
import sys
import tempfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from tests import _iso
from tools import config

# client=False, and NO root redirected: this file writes nothing into the repo,
# so it needs the guard armed but no sandbox seeding. Staging happens in the OS
# temp dir, outside every protected root - seeding `work` here would copy the
# multi-GB client snapshot it contains.
_iso.sandbox(client=False)

REPO = Path(config.REPO_ROOT)
SCRATCH = Path(tempfile.mkdtemp(prefix="iso_guard_"))


def _fires(fn) -> bool:
    """True if the guard rejected the operation."""
    try:
        fn()
    except RuntimeError as exc:
        assert "test isolation violation" in str(exc), exc
        return True
    return False


def _cleanup(*paths):
    for p in paths:
        try:
            os.remove(p)
        except OSError:
            pass


# Every probe below targets a path that DOES NOT EXIST inside a protected root.
# That matters: if the guard regresses, the operation runs for real, so a probe
# aimed at a live file would destroy it. (Learned the hard way - an earlier
# version of this file pointed at CATALOG.md and truncated it the moment the
# guard was reverted for a RED check.) With a non-existent target the worst a
# regression can do is leave one stray probe file, which the asserts then catch.
PROBE_MD = REPO / "raw" / "_iso_probe.md"        # inside the protected raw/ root
PROBE_JSON = REPO / "data" / "_iso_probe.json"

# --- os.replace INTO a committed root: the hole this file exists for ---------
src = SCRATCH / "staged.md"
src.write_text("probe\n", encoding="utf-8")
assert _fires(lambda: os.replace(str(src), str(PROBE_MD))), (
    "os.replace into a committed root was NOT caught - the guard is reading the "
    "wrong audit-event argument again (args[-1] is dst_dir_fd, not the path)")
assert not PROBE_MD.exists(), "guard must reject BEFORE the write lands"
print("PASS os.replace into a committed root is rejected")

# --- os.rename INTO a committed root ----------------------------------------
# Target a path that does not exist: Windows os.rename refuses to clobber, and
# that error would mask whether the guard fired at all.
src2 = SCRATCH / "staged2.json"
src2.write_text("{}\n", encoding="utf-8")
assert _fires(lambda: os.rename(str(src2), str(PROBE_JSON))), (
    "os.rename into the committed data/ root was NOT caught")
assert not PROBE_JSON.exists(), "probe must not land"
print("PASS os.rename into a committed root is rejected")

# --- renaming a committed file OUT is equally destructive -------------------
# Source is non-existent on purpose: a guard regression yields FileNotFoundError
# (still a failed assert, still caught) instead of moving a real file away.
assert _fires(lambda: os.replace(str(REPO / "data" / "_iso_absent.json"),
                                 str(SCRATCH / "stolen.json"))), (
    "renaming a file OUT of a committed root was NOT caught - a rename that "
    "empties a protected path mutates it just as much as one that fills it")
print("PASS renaming a committed file out of its root is rejected")

# --- the sandboxed root stays writable (guard is not indiscriminate) --------
a, b = SCRATCH / "a.txt", SCRATCH / "b.txt"
a.write_text("ok\n", encoding="utf-8")
os.replace(str(a), str(b))
assert b.read_text(encoding="utf-8") == "ok\n"
print("PASS renames inside the sandbox are allowed")

# PROBE_MD/PROBE_JSON never land - the guard rejects before the write, and
# removing them would itself be a protected-root write.
_cleanup(src, src2, b)
import shutil
shutil.rmtree(SCRATCH, ignore_errors=True)

print("ALL PASS")
