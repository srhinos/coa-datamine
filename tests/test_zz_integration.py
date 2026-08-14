"""THE integration test: the one place in the suite that rebuilds anything.

Every other test in this suite reads what `datamine.py` already materialized and
asserts against it. Exactly one has to prove that the materialized layers are
what the code actually produces, end to end, or the other 37 are asserting
against a fixture nobody re-derives. That is this file, and it is deliberately
singular: five tests used to trigger their own extraction and a sixth ran all 16
curation stages, each writing into the same committed directories, which is what
made the suite's result depend on what had run before it (tests/_diagnosis.md).

It is named `test_zz_` so it sorts last, but nothing depends on that: it builds
into a scratch tree it owns and deletes, over the SEALED SNAPSHOT rather than the
live client, so it is order-independent like everything else here.

Three gates, in order:

  1. Base extraction from the snapshot reproduces `work/dbc` exactly - all 111
     tables, sha256 for sha256. This is what makes every snapshot-relative pin in
     the rest of the suite trustworthy, and it is why those pins must NOT be
     re-pinned to the live client: the client auto-patches, the snapshot does not,
     and `data/` + `raw/` are a function of the snapshot.
  2. Realm extraction reproduces `work/realms/<realm>` the same way.
  3. Curation over those inputs reproduces the committed dataset: the same
     buildStats, the same curationInputs, and - the strongest form of "the
     curated layer is a pure function of the raw layer" this repo can state - a
     byte-identical `data/` tree and `raw/dbc` dump.
"""
import hashlib, json, sys, time
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from tests import _iso

# Read the pass's own record of what it materialized BEFORE work/ is redirected.
COMMITTED = _iso.REPO_ROOT
recorded = json.loads((COMMITTED / "work" / "curation_inputs.json")
                      .read_text(encoding="utf-8"))
committed_prov = json.loads((COMMITTED / "raw" / "provenance.json")
                            .read_text(encoding="utf-8"))

# data/ is seeded because curation legitimately reads the previous pass's tree in
# places (build_spells reads data/classes, which a later stage rebuilds), exactly
# as a real `python datamine.py` run does.
_iso.sandbox(data=True, raw=True, work=[])

from tools import config, curate, extract_mpq, extract_realms


def tree(root: Path) -> dict:
    return {str(p.relative_to(root)).replace("\\", "/"):
            hashlib.sha256(p.read_bytes()).hexdigest()
            for p in sorted(root.rglob("*")) if p.is_file()}


def diff(a: dict, b: dict, label: str) -> None:
    only_a = sorted(set(a) - set(b))
    only_b = sorted(set(b) - set(a))
    changed = sorted(k for k in set(a) & set(b) if a[k] != b[k])
    assert not (only_a or only_b or changed), (
        f"{label}: the rebuild does not reproduce the committed tree - "
        f"missing={only_a[:5]} extra={only_b[:5]} differing={changed[:5]} "
        f"({len(only_a)}/{len(only_b)}/{len(changed)} of {len(b)})")


# ---- 1. base extraction reproduces work/dbc, table for table ----------------
t0 = time.time()
prov = extract_mpq.extract_all()
print(f"  extract_mpq  {len(prov['files'])} tables  [{time.time() - t0:6.1f}s]", flush=True)

assert set(prov["files"]) == {w.lower() for w in config.WANTED_DBCS}
assert isinstance(prov["skipped_archives"], list)
for name, rec in sorted(recorded["base"].items()):
    got = prov["files"][name.lower()]
    assert got["sha256"] == rec["sha256"], (
        f"{name}: extracting from the sealed snapshot no longer reproduces the "
        f"bytes datamine.py curated from ({got['records']} records vs "
        f"{rec['records']}). Either work/ was rebuilt from a different client "
        f"than the one raw/+data/ were built from, or the chain rules changed.")
    assert got["records"] == rec["records"] and got["winner"] == rec["archive"].rsplit("/", 1)[-1]
    p = config.WORK_DBC_DIR / name
    assert p.is_file() and hashlib.sha256(p.read_bytes()).hexdigest() == rec["sha256"]

saved = json.loads((config.WORK_DIR / "extract_provenance.json").read_text(encoding="utf-8"))
assert saved["files"]["spell.dbc"]["winner"] == prov["files"]["spell.dbc"]["winner"]
assert prov["census"]["extractedCount"] == len(config.WANTED_DBCS)

# ---- 2. realm extraction reproduces work/realms ----------------------------
t0 = time.time()
rprov = extract_realms.extract_all()
print(f"  extract_realms  {sorted(rprov)}  [{time.time() - t0:6.1f}s]", flush=True)

assert set(rprov) == set(recorded["realms"]), (set(rprov), set(recorded["realms"]))
for realm, frag in sorted(rprov.items()):
    want = recorded["realms"][realm]["files"]
    assert set(frag["files"]) == set(want), (realm, sorted(frag["files"]))
    for name, rec in sorted(want.items()):
        assert frag["files"][name]["sha256"] == rec["sha256"], (realm, name)
        assert frag["files"][name]["records"] == rec["records"], (realm, name)

# ---- 3. curation over those inputs reproduces the committed dataset --------
t0 = time.time()
fresh = curate.run(recorded)
print(f"  curate.run  {len(fresh['buildStats'])} stages  [{time.time() - t0:6.1f}s]", flush=True)

assert fresh["clientDir"] == str(config.CLIENT_DIR)
# Through JSON first: the committed side has been serialized, so its int dict keys
# (generationSpanHistogram) are strings. Comparing the in-memory dict against it
# would fail on that alone, which says nothing about the data.
fresh = json.loads(json.dumps(fresh))
assert set(fresh["buildStats"]) == set(committed_prov["buildStats"])
for stage in sorted(fresh["buildStats"]):
    assert fresh["buildStats"][stage] == committed_prov["buildStats"][stage], (
        f"stage {stage} no longer reproduces the committed provenance:\n"
        f"  rebuilt   {fresh['buildStats'][stage]}\n"
        f"  committed {committed_prov['buildStats'][stage]}")
assert fresh["curationInputs"] == committed_prov["curationInputs"]
assert fresh["headerMismatches"] == committed_prov["headerMismatches"]

diff(tree(config.DATA_DIR), tree(COMMITTED / "data"), "data/")
diff(tree(config.RAW_DBC_DIR), tree(COMMITTED / "raw" / "dbc"), "raw/dbc/")

print("ALL PASS")
