"""Gate on the live-truth capture being a step of the pass, with provenance.

`live` is the flag that makes this dataset usable and it does not come from the
client - it comes from a web capture. That capture used to be a separate entry
point run by hand, so the raw layer could be minutes old while `live` was days
old and nothing in the pass said so. This pins the three properties that fix:

  (a) the capture carries citable provenance - url, capturedUtc, sha256, bytes -
      in the payload sidecar AND in the run's own record;
  (b) a reused payload is LOUD: status/reuseReason, never silently inherited;
  (c) a failed fetch leaves the previous payload byte-for-byte intact, and a
      failed fetch with NO payload stops the run instead of guessing `live`.

None of it touches the network: the reuse paths are exercised with `offline` and
with a stubbed downloader, against a scratch directory rather than raw/talents/.
"""
import hashlib, json, shutil, sys, tempfile
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

import datamine
from tools import config, fetch_coatalents

REQUIRED = fetch_coatalents.REQUIRED_PROVENANCE
assert set(REQUIRED) == {"url", "capturedUtc", "sha256", "bytes"}, REQUIRED


def _fake_payload(dest: Path, body: bytes = b"<html>live truth</html>") -> dict:
    """A payload + sidecar pair on disk, written the way a real capture leaves
    them, so the reuse and failure paths run against a real directory."""
    dest.mkdir(parents=True, exist_ok=True)
    (dest / "coa-builder-voljin.html").write_bytes(body)
    prov = {"url": fetch_coatalents.URL_TEMPLATE.format(slug="voljin"),
            "slug": "voljin", "capturedUtc": "2026-01-01T00:00:00+00:00",
            "sha256": hashlib.sha256(body).hexdigest(), "bytes": len(body),
            "savedAs": "coa-builder-voljin.html", "status": "fetched"}
    (dest / "_fetch.json").write_text(json.dumps(prov, indent=1, sort_keys=True),
                                      encoding="utf-8", newline="\n")
    return prov


# ---------------------------------------------------------------------------
# (a) the shipped payload's provenance, on disk
# ---------------------------------------------------------------------------
def test_payload_sidecar_carries_the_four_fields():
    meta = json.loads(fetch_coatalents.meta_path().read_text(encoding="utf-8"))
    missing = [k for k in REQUIRED if not meta.get(k)]
    assert not missing, f"raw/talents/_fetch.json is missing {missing}"
    assert meta["url"].startswith("https://"), meta["url"]
    assert meta["capturedUtc"].endswith("+00:00"), meta["capturedUtc"]
    assert len(meta["sha256"]) == 64 and meta["bytes"] > 1_000_000, meta


def test_the_sidecar_describes_the_bytes_that_are_actually_there():
    """A provenance record that describes different bytes than the ones on disk
    is worse than none - shipped() recomputes rather than believing."""
    have = fetch_coatalents.shipped()
    assert have, "no live-truth payload under raw/talents/"
    assert have["sidecarAgrees"] is True, (
        f"torn pair: _fetch.json says {have['sidecarSha256']}, the payload "
        f"hashes to {have['sha256']}")


# ---------------------------------------------------------------------------
# (b) the run's own record of the capture
# ---------------------------------------------------------------------------
def test_run_block_carries_provenance_and_the_two_clocks():
    """The block datamine.py writes into raw/_snapshot.json, built by the same
    code path over this repo's real manifest and real payload."""
    manifest = json.loads(
        (config.RAW_DIR / datamine.SNAPSHOT_JSON).read_text(encoding="utf-8"))
    prov = fetch_coatalents.capture(offline=True)      # no network
    block = datamine.live_capture_block(prov, manifest)
    missing = [k for k in REQUIRED if not block.get(k)]
    assert not missing, f"liveCapture block is missing {missing}"
    assert block["status"] == "reused" and block["reuseReason"], block
    assert "offline" in block["reuseReason"]
    assert block["rule"] and "ONE network read" in block["rule"]
    assert block["clientSnapshotNewestArchiveUtc"], block
    assert isinstance(block["captureMinusSnapshotDays"], float), block
    # sign convention, stated in the block and matched here: positive means the
    # capture is NEWER than the client files it is being joined onto
    newer = block["capturedUtc"] > block["clientSnapshotNewestArchiveUtc"]
    assert (block["captureMinusSnapshotDays"] > 0) == newer, block


def test_the_published_snapshot_records_the_capture_once_a_pass_has_run():
    """raw/_snapshot.json is written by the pass, so this asserts against the
    LAST run's output. A tree published before the capture was folded in has no
    block yet - say which, rather than passing vacuously either way."""
    snap = json.loads(
        (config.RAW_DIR / datamine.SNAPSHOT_JSON).read_text(encoding="utf-8"))
    block = snap.get("liveCapture")
    if block is None:
        print("  (raw/_snapshot.json predates the fold - no liveCapture block; "
              "the next full pass writes one)")
        return
    missing = [k for k in REQUIRED if not block.get(k)]
    assert not missing, f"published liveCapture block is missing {missing}"
    assert block["status"] in ("fetched", "reused"), block
    assert block["status"] == "fetched" or block["reuseReason"], (
        "a reused capture must say why, in the layer")


# ---------------------------------------------------------------------------
# (c) failure never corrupts, and never guesses
# ---------------------------------------------------------------------------
def test_a_failed_fetch_reuses_the_payload_byte_for_byte():
    tmp = Path(tempfile.mkdtemp(prefix="coa-capture-"))
    try:
        original = _fake_payload(tmp)
        before = (tmp / "coa-builder-voljin.html").read_bytes()
        real = fetch_coatalents._download
        fetch_coatalents._download = lambda url, timeout: (_ for _ in ()).throw(
            OSError("simulated network failure"))
        try:
            prov = fetch_coatalents.capture(dest_dir=tmp)
        finally:
            fetch_coatalents._download = real
        assert prov["status"] == "reused", prov
        assert "simulated network failure" in prov["reuseReason"], prov
        assert not [k for k in REQUIRED if not prov.get(k)], prov
        assert (tmp / "coa-builder-voljin.html").read_bytes() == before
        assert json.loads((tmp / "_fetch.json").read_text(
            encoding="utf-8")) == original, "_fetch.json was rewritten on reuse"
        assert not list(tmp.glob("*.part")), "a partial download was left behind"
    finally:
        shutil.rmtree(tmp, ignore_errors=True)


def test_a_page_that_does_not_parse_is_rejected_not_installed():
    """The failure that actually happened on 2026-08-12: HTTP 200, ~11.9 MB, and
    the extractor cannot find a build record in it. Installing that over the last
    known-good payload would destroy the only usable copy of the live truth."""
    tmp = Path(tempfile.mkdtemp(prefix="coa-capture-"))
    junk = b"<html>200 OK, and not a builder page</html>"
    try:
        original = _fake_payload(tmp)
        real = fetch_coatalents._download
        fetch_coatalents._download = lambda url, timeout: (junk, 200, "today")
        try:
            prov = fetch_coatalents.capture(dest_dir=tmp)
        finally:
            fetch_coatalents._download = real
        assert prov["status"] == "reused", prov
        assert prov["sha256"] == original["sha256"], "the junk page was installed"
        rej = prov["rejectedCapture"]
        assert rej["sha256"] == hashlib.sha256(junk).hexdigest()
        assert "entriesByTab" in rej["reason"], rej
        assert not Path(rej["keptAt"]).is_absolute(), rej["keptAt"]
        kept = config.REPO_ROOT / rej["keptAt"]
        assert kept.read_bytes() == junk, "the rejected bytes were not kept"
        kept.unlink()
        assert (tmp / "coa-builder-voljin.html").read_bytes() \
            == b"<html>live truth</html>"
    finally:
        shutil.rmtree(tmp, ignore_errors=True)


def test_a_failed_fetch_with_no_payload_stops_the_run():
    tmp = Path(tempfile.mkdtemp(prefix="coa-capture-"))
    try:
        real = fetch_coatalents._download
        fetch_coatalents._download = lambda url, timeout: (_ for _ in ()).throw(
            OSError("simulated network failure"))
        try:
            fetch_coatalents.capture(dest_dir=tmp)
        except SystemExit as e:
            assert "no live-truth payload" in str(e), e
        else:
            raise AssertionError(
                "a missing payload and a dead network produced a capture - "
                "`live` has no offline substitute and must fail loudly")
        finally:
            fetch_coatalents._download = real
    finally:
        shutil.rmtree(tmp, ignore_errors=True)


def test_the_capture_is_not_a_second_entry_point():
    src = (config.REPO_ROOT / "tools" / "fetch_coatalents.py").read_text(
        encoding="utf-8")
    assert "if __name__" not in src, (
        "tools/fetch_coatalents.py carries a __main__ again - the capture is a "
        "step of datamine.py's pass, not a thing run on its own schedule")
    assert "argparse" not in src


if __name__ == "__main__":
    for name, fn in sorted(globals().items()):
        if name.startswith("test_") and callable(fn):
            fn()
            print(f"  {name}: PASS")
    print("test_live_capture: ALL PASS")
