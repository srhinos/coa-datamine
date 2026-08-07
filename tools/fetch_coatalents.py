"""Fetch step for task W4-9 (CoA talent tree geometry, coa-sim-handoff/
DATAMINE-REQUEST.md Sec 6.1): downloads the published ascension.gg CoA
talent-builder page and freezes it under raw/talents/, exactly like
raw/interface/AddOns/APIDocumentation is a verbatim capture of a live external
source rather than something this repo re-derives.

This is a DELIBERATE, occasional, manually-triggered step - NOT part of the
offline tools/build_dataset.py pipeline. The page is ~11.9 MB of server-rendered
HTML/JS (a Next.js "flight" payload embedding the live talent-tree JSON) fetched
from a service outside this repo's control; per the task brief, it is an
EXTERNAL SOURCE THAT DRIFTS (Ascension patches its live game balance/content on
its own schedule, independent of this repo's client snapshot - see the
"contentDrift" finding in data/talents/coa/_meta.json). Freezing one capture with
recorded provenance (url, UTC timestamp, byte size, sha256) is what makes
tools/build_coatalents.py's output reproducible from the committed repo state
without a live network call, and what lets a future task detect drift by
re-running this fetch and diffing raw/talents/_fetch.json's sha256.

Run: python -m tools.fetch_coatalents [--slug voljin]"""
import argparse, datetime, hashlib, json, urllib.request

from tools import config

USER_AGENT = ("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
              "(KHTML, like Gecko) Chrome/120.0 Safari/537.36")


def fetch(slug: str = "voljin", timeout: int = 120) -> dict:
    url = f"https://ascension.gg/en/v2/coa-builder/{slug}"
    req = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
    with urllib.request.urlopen(req, timeout=timeout) as resp:
        body = resp.read()
        status = resp.status
        server_date = resp.headers.get("Date")

    config.RAW_TALENTS_DIR.mkdir(parents=True, exist_ok=True)
    html_path = config.RAW_TALENTS_DIR / f"coa-builder-{slug}.html"
    html_path.write_bytes(body)

    prov = {
        "url": url,
        "slug": slug,
        "capturedUtc": datetime.datetime.now(datetime.timezone.utc)
                       .isoformat(timespec="seconds"),
        "serverDate": server_date,
        "httpStatus": status,
        "bytes": len(body),
        "sha256": hashlib.sha256(body).hexdigest(),
        "savedAs": html_path.name,
        "note": ("EXTERNAL SOURCE THAT DRIFTS - Ascension's live builder reflects "
                 "current game balance/content, independent of this repo's client "
                 "snapshot capture date. Re-run this fetch and diff sha256 to check "
                 "for drift; do not assume this capture stays current."),
    }
    (config.RAW_TALENTS_DIR / "_fetch.json").write_text(
        json.dumps(prov, ensure_ascii=False, indent=1, sort_keys=True),
        encoding="utf-8", newline="\n")
    return prov


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--slug", default="voljin",
                    help="builder realm slug, e.g. 'voljin' or 'voljin-alpha'")
    a = ap.parse_args()
    prov = fetch(a.slug)
    print(prov)


if __name__ == "__main__":
    main()
