"""THE LIVE-TRUTH CAPTURE - the one place the pass touches the network.

`live` is the flag that makes this dataset usable: it is what separates content
the game currently ships from content that exists in the client's tables and is
dead. It cannot be derived from the client at all - the client's own catalog
carries live and cut content alike - so it comes from an external source, the
published CoA talent builder at ascension.gg, whose page embeds the live tree's
full node array.

This module downloads that page and freezes it under `raw/talents/` with
provenance (url, capture time, sha256, byte size), exactly the way
`raw/interface/AddOns/APIDocumentation` is a verbatim capture of a live external
source rather than something this repo re-derives.

WHY IT IS CALLED FROM `datamine.py` AND HAS NO CLI
--------------------------------------------------
It used to be a second entry point - `python -m tools.fetch_coatalents` - run
occasionally, by hand, on its own schedule. That is exactly the drift the
snapshot design exists to remove, one level up: the raw layer could be minutes
old while `live` was days old, and nothing in the pass noticed or said so. The
capture is now step 0 of `datamine.py`, so the live truth and the client
snapshot are taken within seconds of each other and the distance between them is
a number the run records rather than a property of when somebody last remembered
to run a script.

It is deliberately NOT folded into the snapshot step. The snapshot is guarded -
`datamine.ClientReads` fails the run if anything reads the live client after it
is sealed - and this step reads something else entirely: a web service, over the
network, that the client has no copy of. Keeping it visibly separate, and BEFORE
the guard arms, is what keeps "the pass reads the snapshot and nothing else" a
statement about the client that is true without qualification.

DEFAULT POLICY: FETCH EVERY RUN
-------------------------------
Every run re-fetches. There is no freshness window and no reuse-if-recent
branch, because a freshness window is just a second clock with a threshold
nobody chose - the same defect in smaller print. The cost argument does not
exist: one HTTPS GET of ~11.9 MB against a pass that takes ~23 minutes.

The payload is reused in exactly two cases, and both are loud - reported in the
run summary and recorded in `raw/_snapshot.json`'s `liveCapture` block as
`status: "reused"` with the reason:

  * the fetch failed (offline, DNS, timeout, HTTP error, short read)
  * `python datamine.py --offline` was passed, an explicit skip

Reuse is never silent and never inherited. A run that reused says so in the
committed layer, so a reader can tell "the live truth was confirmed current
during this run" from "the live truth is whatever was already on disk".

NETWORK FAILURE NEVER CORRUPTS THE LAYER
----------------------------------------
The download goes to a temp file in the destination directory and is moved over
the payload with `os.replace` only after the whole body has arrived, the
server's own Content-Length (when it sends one) agrees with what was read, and
the page has been PARSED into a build record for this slug. A failure at any
point leaves the previous payload exactly as it was. If there is no previous
payload AND the fetch fails, the run stops: `live` has no offline substitute and
a silent 27k-entry "unknown" is not an acceptable degradation.

The parse check is not belt-and-braces, it is the failure that actually
happened. Measured 2026-08-12, against the 2026-08-06 payload this repo ships:
the page still returns HTTP 200, still weighs ~11.9 MB and still contains the
tree (`entriesByTab` appears in it, at the same escaping depth), but its Next.js
flight rows are BATCHED differently - 292 `self.__next_f.push` literals became
4, and the one literal that carries the tree now starts with a module row
(`I[607833,[...`) instead of being one row on its own, so the extractor's
row-per-literal assumption breaks and `raw_decode` fails. `extract_payload`
therefore finds no build record. A capture that downloads
perfectly and cannot be read is exactly as useless as one that never arrived -
and replacing the last known-good payload with it would destroy the only usable
copy. So a page that does not parse is REJECTED: the shipped payload stays, the
rejected bytes are kept under work/ (gitignored) for whoever fixes the parser,
and the run reports `status: "reused"` with the parse failure as the reason.
`status: "fetched"` therefore means fetched AND usable, never merely 200 OK.

WHAT WRITES WHAT
----------------
`raw/talents/_fetch.json` describes the PAYLOAD - where those bytes came from
and when. It is rewritten only when bytes are actually fetched.
`raw/_snapshot.json`'s `liveCapture` block describes THE RUN - whether this pass
re-fetched or reused, and how far the capture sits from the client snapshot.
"""
import datetime
import hashlib
import json
import os
import urllib.error
import urllib.request
from pathlib import Path

from tools import config

USER_AGENT = ("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
              "(KHTML, like Gecko) Chrome/120.0 Safari/537.36")

DEFAULT_SLUG = "voljin"
URL_TEMPLATE = "https://ascension.gg/en/v2/coa-builder/{slug}"

CAPTURE_RULE = (
    "The live-truth capture: the ONE network read in datamine.py's pass, taken "
    "before the client snapshot is opened and outside the snapshot guard, "
    "because it reads a web service the client has no copy of. `live` - which "
    "content the game currently ships - cannot be derived from the client's own "
    "tables, so it comes from the published CoA talent builder and is frozen "
    "under raw/talents/ with the provenance below. The default is to re-fetch "
    "every run: a freshness window would be a second clock with a threshold "
    "nobody chose, which is the drift this fold removes. `status` says what "
    "THIS run did - `fetched` means the live truth was confirmed current while "
    "the snapshot was being taken; `reused` means the fetch failed or was "
    "explicitly skipped and the shipped payload was kept, with the reason in "
    "`reuseReason`. A reused capture is never silently inherited: it is stated "
    "here and in the run summary. raw/talents/_fetch.json describes the "
    "PAYLOAD's own provenance; this block describes the RUN.")

PAYLOAD_NOTE = (
    "EXTERNAL SOURCE THAT DRIFTS - Ascension's live builder reflects current "
    "game balance/content, independent of this repo's client snapshot capture "
    "date. Captured by tools/fetch_coatalents.py as step 0 of datamine.py's "
    "pass. This file describes the PAYLOAD (where these bytes came from, when); "
    "whether a given run re-fetched or reused them is in raw/_snapshot.json's "
    "liveCapture block.")

# The four fields that make a capture citable at all: where it came from, when,
# what it hashes to, and how big it was. Asserted by tests/test_live_capture.py.
REQUIRED_PROVENANCE = ("url", "capturedUtc", "sha256", "bytes")


def payload_path(slug: str = DEFAULT_SLUG, dest_dir: Path = None) -> Path:
    return (dest_dir or config.RAW_TALENTS_DIR) / f"coa-builder-{slug}.html"


def meta_path(dest_dir: Path = None) -> Path:
    return (dest_dir or config.RAW_TALENTS_DIR) / "_fetch.json"


def _utc_now() -> str:
    return (datetime.datetime.now(datetime.timezone.utc)
            .isoformat(timespec="seconds"))


def shipped(slug: str = DEFAULT_SLUG, dest_dir: Path = None) -> dict:
    """What is already on disk, measured from the bytes rather than believed
    from the sidecar.

    The sha256 returned is ALWAYS recomputed from the payload. If `_fetch.json`
    disagrees with it, that is a torn pair - a payload replaced without its
    sidecar, or the reverse - and it is reported rather than trusted, because a
    provenance record that describes different bytes than the ones on disk is
    worse than none."""
    p = payload_path(slug, dest_dir)
    if not p.is_file():
        return {}
    data = p.read_bytes()
    got = hashlib.sha256(data).hexdigest()
    mp = meta_path(dest_dir)
    meta = {}
    if mp.is_file():
        try:
            meta = json.loads(mp.read_text(encoding="utf-8"))
        except ValueError:
            meta = {}
    return {"slug": meta.get("slug", slug),
            "url": meta.get("url", URL_TEMPLATE.format(slug=slug)),
            "capturedUtc": meta.get("capturedUtc"),
            "sha256": got,
            "bytes": len(data),
            "savedAs": p.name,
            "httpStatus": meta.get("httpStatus"),
            "serverDate": meta.get("serverDate"),
            "sidecarSha256": meta.get("sha256"),
            "sidecarAgrees": meta.get("sha256") == got if meta else None}


def _download(url: str, timeout: int) -> tuple:
    """(body, httpStatus, serverDate). Raises on anything short of a complete
    response - a truncated body is a failed fetch, not a smaller capture."""
    req = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
    with urllib.request.urlopen(req, timeout=timeout) as resp:
        body = resp.read()
        status = resp.status
        server_date = resp.headers.get("Date")
        declared = resp.headers.get("Content-Length")
    if declared is not None and declared.isdigit() and int(declared) != len(body):
        raise OSError(f"short read: {len(body)} bytes of a declared {declared}")
    if not body:
        raise OSError("empty response body")
    return body, status, server_date


def _usable(body: bytes, slug: str) -> str:
    """'' if the page parses into a build record for `slug`, else why it does
    not. The check IS the payload's contract: everything downstream reads the
    page through tools/coa_live.py's extractor, so a page that extractor cannot
    read is not a capture of anything."""
    from tools import coa_live                      # local: keeps this module
    try:                                            # importable on its own
        coa_live.extract_payload(body.decode("utf-8", errors="replace"), slug)
    except Exception as e:                          # noqa: BLE001 - reported
        return f"{type(e).__name__}: {e}"
    return ""


def _quarantine(body: bytes, slug: str, digest: str) -> str:
    """Keep the rejected bytes where a parser fix can look at them, OUTSIDE the
    committed tree - a page that does not parse is evidence, not a layer.
    Returns a REPO-RELATIVE path: the reason string it lands in is committed,
    and an absolute path from one machine is install state."""
    out = config.WORK_DIR / "rejected-captures"
    out.mkdir(parents=True, exist_ok=True)
    p = out / f"coa-builder-{slug}-{digest[:16]}.html"
    p.write_bytes(body)
    try:
        return p.relative_to(config.REPO_ROOT).as_posix()
    except ValueError:
        return p.name


def capture(slug: str = DEFAULT_SLUG, dest_dir: Path = None, timeout: int = 120,
            offline: bool = False) -> dict:
    """Fetch the live-truth payload, freeze it, and return this run's capture
    provenance. Never raises on a network failure when a payload already
    exists - it reuses it and says so.

    `dest_dir` exists so a verification run can capture somewhere other than
    raw/talents/ without touching the committed payload. It is not a pipeline
    knob; datamine.py never passes it."""
    dest = dest_dir or config.RAW_TALENTS_DIR
    have = shipped(slug, dest)
    url = URL_TEMPLATE.format(slug=slug)

    reuse_reason = None
    if offline:
        reuse_reason = ("--offline was passed: this run explicitly skipped the "
                        "network step")
    else:
        try:
            body, status, server_date = _download(url, timeout)
        except (urllib.error.URLError, OSError, ValueError) as e:
            reuse_reason = (f"the fetch failed ({type(e).__name__}: {e}) - the "
                            f"shipped payload was kept, unmodified")
        else:
            digest = hashlib.sha256(body).hexdigest()
            unusable = _usable(body, slug)
            if unusable:
                kept = _quarantine(body, slug, digest)
                reuse_reason = (
                    f"the page downloaded ({len(body):,} bytes, sha256 "
                    f"{digest[:16]}) but did not parse into a build record for "
                    f"slug={slug!r} ({unusable}) - the shipped payload was kept "
                    f"rather than replaced with bytes nothing can read; the "
                    f"rejected page is at {kept} and tools/coa_live.py's "
                    f"extractor needs re-investigation")
                rejected = {"sha256": digest, "bytes": len(body),
                            "reason": unusable, "keptAt": kept}
                if have:
                    return {**have, "status": "reused",
                            "reuseReason": reuse_reason,
                            "changedFromPrevious": False,
                            "previousSha256": have.get("sha256"),
                            "rejectedCapture": rejected,
                            "note": PAYLOAD_NOTE, "rule": CAPTURE_RULE}
                raise SystemExit(
                    f"FATAL: no live-truth payload at "
                    f"{payload_path(slug, dest)} and {reuse_reason}. `live` has "
                    f"no offline substitute, so the run stops here.")
            dest.mkdir(parents=True, exist_ok=True)
            captured = _utc_now()
            final = payload_path(slug, dest)
            tmp = final.with_name(final.name + ".part")
            # temp file in the DESTINATION directory: os.replace is only atomic
            # within a volume, and a payload half-written over the previous one
            # is the failure this whole step is supposed to be immune to
            tmp.write_bytes(body)
            os.replace(tmp, final)
            prov = {
                "url": url, "slug": slug, "capturedUtc": captured,
                "serverDate": server_date, "httpStatus": status,
                "bytes": len(body), "sha256": digest, "savedAs": final.name,
                "status": "fetched",
                "previousSha256": have.get("sha256"),
                "changedFromPrevious": (None if not have
                                        else digest != have.get("sha256")),
                "note": PAYLOAD_NOTE,
            }
            mtmp = meta_path(dest).with_name("_fetch.json.part")
            mtmp.write_text(json.dumps(prov, ensure_ascii=False, indent=1,
                                       sort_keys=True),
                            encoding="utf-8", newline="\n")
            os.replace(mtmp, meta_path(dest))
            return {**prov, "reuseReason": None, "rule": CAPTURE_RULE}

    if not have:
        raise SystemExit(
            f"FATAL: no live-truth payload at {payload_path(slug, dest)} and "
            f"{reuse_reason}. `live` has no offline substitute - the client's "
            f"own catalog cannot tell live content from cut content, which is "
            f"the entire reason this capture exists - so the run stops here "
            f"rather than shipping 27k entries whose live flag is a guess.")
    return {**have, "status": "reused", "reuseReason": reuse_reason,
            "changedFromPrevious": False, "previousSha256": have.get("sha256"),
            "note": PAYLOAD_NOTE, "rule": CAPTURE_RULE}
