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


# --- os.replace INTO a committed root: the hole this file exists for ---------
src = SCRATCH / "staged.md"
src.write_text("probe\n", encoding="utf-8")
dst = REPO / "CATALOG.md"          # protected, and emit.py publishes it this way
assert _fires(lambda: os.replace(str(src), str(dst))), (
    "os.replace into a committed root was NOT caught - the guard is reading the "
    "wrong audit-event argument again (args[-1] is dst_dir_fd, not the path)")
assert dst.is_file(), "guard must reject BEFORE the write lands"
print("PASS os.replace into a committed root is rejected")

# --- os.rename INTO a committed root ----------------------------------------
# Target a path that does not exist: Windows os.rename refuses to clobber, and
# that error would mask whether the guard fired at all.
src2 = SCRATCH / "staged2.json"
src2.write_text("{}\n", encoding="utf-8")
assert _fires(lambda: os.rename(str(src2), str(REPO / "data" / "_iso_probe.json"))), (
    "os.rename into the committed data/ root was NOT caught")
assert not (REPO / "data" / "_iso_probe.json").exists(), "probe must not land"
print("PASS os.rename into a committed root is rejected")

# --- renaming a committed file OUT is equally destructive -------------------
assert _fires(lambda: os.replace(str(REPO / "CATALOG.md"),
                                 str(SCRATCH / "stolen.md"))), (
    "renaming a committed file OUT of its root was NOT caught - a rename that "
    "empties a protected path mutates it just as much as one that fills it")
assert (REPO / "CATALOG.md").is_file(), "CATALOG.md must survive the probe"
print("PASS renaming a committed file out of its root is rejected")

# --- the sandboxed root stays writable (guard is not indiscriminate) --------
a, b = SCRATCH / "a.txt", SCRATCH / "b.txt"
a.write_text("ok\n", encoding="utf-8")
os.replace(str(a), str(b))
assert b.read_text(encoding="utf-8") == "ok\n"
print("PASS renames inside the sandbox are allowed")

_cleanup(src, src2, b)
import shutil
shutil.rmtree(SCRATCH, ignore_errors=True)

print("ALL PASS")
