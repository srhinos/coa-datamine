"""Realm-overlay DBC extraction (task V3-2): discover Data\\<realm>\\ directories
(config.discover_realms - any dir with its own `listarchive`, excluding enUS/Content)
and extract every DBFilesClient\\*.dbc file from each realm's own archive chain into
work/realms/<realm>/dbc/.

A realm's data is a server-side OVERLAY that sits ABOVE the base client chain by
definition (per the brief: it overrides base) - this module never merges a realm's
rows with tools/extract_mpq.py's base chain; the two stay two independent layers,
one archive set apiece. Chain order WITHIN a realm is the realm's own `listarchive`
file, in line order (later line wins on a name collision) - the same later-wins
convention tools/extract_mpq.py uses for the base chain, just scoped to one realm's
own small archive set.

Every DBFilesClient\\*.dbc present is extracted, not filtered to config.WANTED_DBCS:
realm archives are small (area-52's patch-D.MPQ carries exactly 12 DBCs), so there is
no volume reason to filter, and a future realm patch adding a table is picked up here
automatically with no code change (tools/build_realms.py decides mapped-vs-colinfo
per table at build time, driven by whatever this module actually extracted).

Off-disk realm data (a realm this machine's client does not currently carry) is out
of scope by user decision - discovery only sees what's really on disk right now.

Amendment D (single-writer ownership): this module is the SOLE writer under
work/realms/ - nothing else in this repo touches that path."""
import hashlib, json, shutil, struct
from pathlib import Path

from mpyq import MPQArchive

from tools import config


def _realm_archives(realm: str) -> list:
    """listarchive line order = chain order within this realm (index 0 = weakest,
    last line = winner on a name collision). Returns archive Paths in that order."""
    realm_dir = config.CLIENT_DIR / "Data" / realm
    lines = (realm_dir / "listarchive").read_text(
        encoding="utf-8", errors="replace").splitlines()
    return [realm_dir / ln.strip() for ln in lines if ln.strip()]


def extract_realm(realm: str) -> dict:
    """Extract every DBFilesClient\\*.dbc from `realm`'s own archive chain into
    work/realms/<realm>/dbc/. Returns a provenance fragment: archives opened +
    per-file {winner archive, losing archives, sha256, header fields}."""
    out_dir = config.WORK_REALMS_DIR / realm / "dbc"
    if out_dir.exists():
        shutil.rmtree(out_dir)          # sole writer (Amendment D) - full rebuild,
    out_dir.mkdir(parents=True)         # so a table a future patch DROPS doesn't linger

    carriers = {}                 # lower dbc name -> [(rank, archive path, stored name)]
    archive_meta, skipped = [], []
    for rank, p in enumerate(_realm_archives(realm)):
        if not p.is_file():
            archive_meta.append({"archive": p.name, "present": False, "dbcCount": 0})
            continue
        try:
            a = MPQArchive(str(p), listfile=True)
            files = a.files or []
        except Exception as e:
            skipped.append({"archive": p.name, "reason": f"{type(e).__name__}: {e}"})
            archive_meta.append({"archive": p.name, "present": True, "dbcCount": 0})
            continue
        found = 0
        for f in files:
            orig = f.decode("latin-1", "replace").replace("/", "\\")
            fl = orig.lower()
            if fl.startswith("dbfilesclient\\") and fl.endswith(".dbc"):
                # key collision-detection on the lowercase name (Windows archive
                # semantics), but keep the ORIGINALLY-STORED casing for the output
                # filename - unlike extract_mpq.py's base chain (which maps back to
                # a known-cased config.WANTED_DBCS entry), this module extracts
                # every DBC present, so there is no canonical-casing table to map
                # through; the archive's own stored name is the only source of truth.
                base_name = orig.rsplit("\\", 1)[-1]
                carriers.setdefault(fl.rsplit("\\", 1)[-1], []).append((rank, p, f, base_name))
                found += 1
        archive_meta.append({"archive": p.name, "present": True, "dbcCount": found})

    by_winner = {}
    for lower_base, lst in carriers.items():
        lst.sort(key=lambda t: t[0])              # ascending listarchive line order
        rank, winner, stored, base_name = lst[-1]  # last line wins
        by_winner.setdefault(winner, []).append(
            (base_name, stored, [p.name for _, p, _, _ in lst[:-1]]))

    files_prov = {}
    for winner, entries in by_winner.items():
        a = MPQArchive(str(winner), listfile=False)
        for base_name, stored, losers in entries:
            data = a.read_file(stored)
            if not data or data[:4] != b"WDBC":
                raise SystemExit(f"FATAL: bad read of {base_name} from {winner.name} (realm {realm})")
            (out_dir / base_name).write_bytes(data)
            _, recs, fields, recsize, strsize = struct.unpack_from("<4s4I", data, 0)
            files_prov[base_name] = {
                "winner": winner.name, "losers": losers,
                "sha256": hashlib.sha256(data).hexdigest(),
                "records": recs, "fields": fields,
                "record_size": recsize, "bytes": len(data),
            }

    return {"realm": realm, "archives": archive_meta, "skipped_archives": skipped,
            "files": files_prov}


def extract_all() -> dict:
    """Extract every realm directory discovered on this machine's client (see
    config.discover_realms). Returns {realm: provenance fragment} and writes the
    same to work/realms/extract_provenance.json (ephemeral, work/ is gitignored -
    mirrors tools/extract_mpq.py's work/extract_provenance.json convention)."""
    config.WORK_REALMS_DIR.mkdir(parents=True, exist_ok=True)
    prov = {realm: extract_realm(realm) for realm in config.discover_realms()}
    (config.WORK_REALMS_DIR / "extract_provenance.json").write_text(
        json.dumps(prov, indent=1, sort_keys=True), encoding="utf-8", newline="\n")
    return prov


def main():
    prov = extract_all()
    for realm in sorted(prov):
        frag = prov[realm]
        print(f"realm {realm}: {len(frag['files'])} DBCs extracted "
              f"from {len(frag['archives'])} archive(s)")
        for base, e in sorted(frag["files"].items()):
            flag = " COLLISION:" + ",".join(e["losers"]) if e["losers"] else ""
            print(f"  {base:36s} <- {e['winner']:14s} "
                  f"records={e['records']:7d} fields={e['fields']:4d}{flag}")


if __name__ == "__main__":
    main()
