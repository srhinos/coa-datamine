"""The CURATED data/ layer - derived from the raw layer, in the same pass.

`datamine.py` drives this; there is no __main__ here, in any builder this drives,
or in the four retired client-reading extractors, and no other caller - so the
single-entry-point property is enforced by the code rather than observed by
convention (see ENTRY_POINT_RULE). It lives in its own file for a reason that is
load-bearing rather than tidy: the raw pipeline's central claim is that NO WANTED
LIST decides what it extracts, and tests/test_raw_tables.py + test_variants.py
enforce that by scanning datamine.py, emit.py and dbcdecode.py for any table name
or curated-machinery reference at all. Curation legitimately HAS a wanted list -
a curated view has to choose what it curates - so putting it in datamine.py would
have made that gate unenforceable on the file it exists to protect. The two
concerns are separated in the source exactly as they are separated in the claim.

WHY IT EXISTS AT ALL
--------------------
Curation used to be a SECOND pipeline: `tools/build_dataset.py` re-opened the live
client for itself (extract_mpq / extract_realms / extract_interface /
snapshot_content), then ran ~15 per-domain builders against whatever that second
read produced. Two consequences, both measured on this repo:

  * the two halves could describe different clients, because the launcher patches
    archives between them;
  * the curated layer was seeded from the CAD catalog, a STALE content
    generation, so of the 3,932 spell ids the LIVE talent trees reference only
    1,963 (49.9%) had an enriched record - while 1,966 of the 1,969 missing ones
    sat in raw/tables/Spell the whole time.

Both are the same defect wearing two hats: curation was not a function of the raw
layer. It is now. `materialize_inputs()` writes the builders' .dbc inputs out of
the bytes datamine's traversal already staged, `run()` drives the per-domain
builders over them, and the whole thing happens with datamine's `ClientReads`
guard still armed - so "the curated layer never touches the client" is enforced
by the same mechanism that enforces it for the raw layer, not by prose.
"""
import datetime
import json
import shutil
import time
from pathlib import Path

from tools import coa_live, config


def _write_json(path: Path, payload) -> None:
    """UTF-8, LF, sorted, no wall-clock in the bytes - datamine.write_json's
    contract, restated here so this module imports nothing from its caller."""
    path.parent.mkdir(parents=True, exist_ok=True)
    text = json.dumps(payload, indent=1, sort_keys=True, ensure_ascii=False)
    path.write_bytes((text + "\n").encode("utf-8"))


CURATION_INPUTS_JSON = "curation_inputs.json"

CURATION_RULE = (
    "The curated data/ layer is a pure function of the raw layer produced by the "
    "same run of the same script, from the same snapshot. Its .dbc inputs are "
    "written out of the bytes this run's single traversal already staged "
    "(tools/curate.py materialize_inputs), never by reopening an archive "
    "and never by reading the live client - which is enforced, not asserted: "
    "ClientReads stays armed through curation and fails the run on any read of "
    "the client after the snapshot was sealed.")

BASE_VARIANT_RULE = (
    "Curated CoA views derive from the BASE variant of every table: the "
    "highest-ranked carrier among the base and locale archives - the file a "
    "character reads when no realm overlay applies - NOT the chain winner. On "
    "this client the chain winner for Spell.dbc is area-52's realm overlay, "
    "which is missing live CoA content: all 3,932 live talent-node spell ids "
    "resolve in the base variant and only 3,928 in the overlay, so curating off "
    "the winner would silently drop live abilities. Realm overlays are not "
    "discarded - they are curated separately, from each realm's own chain, into "
    "raw/realms + data/realms.")

LIVE_SEED_RULE = (
    "The spell closure is seeded from LIVE truth, not from the CAD catalog: "
    "every spell id a live talent-tree node carries, plus - through the ability "
    "identity layer (data/abilities) - every trainer-taught id, rank-ladder id "
    "and catalog id that belongs to the same ability as a live node. The "
    "catalog is still read, as one generation among several and never as the "
    "seed of truth; ids that reach the closure only through it are kept and "
    "marked live:false rather than deleted.")

ENTRY_POINT_RULE = (
    "datamine.py is the only entry point, and that is now a property of the "
    "code rather than a convention: no builder under tools/ has a __main__ any "
    "more, so `python -m tools.build_spells` cannot rewrite part of data/ from "
    "whatever happens to be on disk, and neither can the four retired "
    "client-reading extractors (extract_mpq, extract_realms, extract_interface, "
    "snapshot_content) - the STAGES were retired from the pipeline last pass, "
    "the MODULES kept their CLIs, and that was the surviving surface for exactly "
    "the two-pipeline drift this change set out to kill. They remain importable, "
    "because the test suite rebuilds individual layers on purpose. "
    "tests/test_dataset.py enforces the absence rather than trusting it.")


def materialize_inputs(h, prog) -> dict:
    """Write the .dbc bytes the curated layer reads, out of this run's harvest.

    Two selections, and they are different on purpose (see BASE_VARIANT_RULE):

      work/dbc/<Table>.dbc          the BASE-context winner - highest chain rank
                                    among archives whose layer is not "realm".
      work/realms/<r>/dbc/<T>.dbc   the winner within realm r's OWN archives,
                                    which is what an overlay IS: the realm's
                                    files, kept apart from the base chain rather
                                    than merged into it.

    Nothing is re-read: `h.table_bytes` already points at the staged bytes of
    every copy of every table path, keyed by (path, archive)."""
    rank_of = {s["id"]: i for i, s in enumerate(h.archives)}
    base_ids = {s["id"] for s in h.archives if s["layer"] != "realm"}
    realm_ids = {}
    for s in h.archives:
        if s["layer"] == "realm" and s["realm"]:
            realm_ids.setdefault(s["realm"], set()).add(s["id"])

    def pick(low, allowed):
        have = [(rank_of[aid], aid) for aid in allowed
                if (low, aid) in h.table_bytes]
        return max(have) if have else None

    def place(low, aid, dest_dir, name):
        facts = h.table_bytes[(low, aid)]
        dest_dir.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(facts["file"], dest_dir / name)
        return {"archive": aid, "sha256": facts["sha256"],
                "records": facts.get("records"),
                "declaredFields": facts.get("declaredFields"),
                "actualFields": facts.get("actualFields"),
                "bytes": facts.get("bytes")}

    # ---- base context ----------------------------------------------------
    wanted = {w.lower(): w for w in config.WANTED_DBCS}
    if config.WORK_DBC_DIR.exists():
        shutil.rmtree(config.WORK_DBC_DIR)
    config.WORK_DBC_DIR.mkdir(parents=True)
    base, mismatches = {}, []
    for low in sorted(h.copies):
        stored = h.copies[low]["stored"].rsplit("\\", 1)[-1]
        name = wanted.get(stored.lower())
        if name is None:
            continue
        got = pick(low, base_ids)
        if got is None:
            continue
        rec = place(low, got[1], config.WORK_DBC_DIR, name)
        rec["chainRank"] = got[0]
        base[name] = rec
        if rec["declaredFields"] != rec["actualFields"]:
            mismatches.append({"table": name.lower(),
                               "declaredFields": rec["declaredFields"],
                               "actualFields": rec["actualFields"]})
    missing = sorted(set(config.WANTED_DBCS) - set(base))
    if missing:
        raise SystemExit(
            f"FATAL: {len(missing)} wanted table(s) have no readable copy in "
            f"the base chain of this snapshot: {missing}")

    # ---- realm contexts --------------------------------------------------
    if config.WORK_REALMS_DIR.exists():
        shutil.rmtree(config.WORK_REALMS_DIR)
    realms = {}
    for realm in sorted(realm_ids):
        out = config.WORK_REALMS_DIR / realm / "dbc"
        files = {}
        for low in sorted(h.copies):
            stored = h.copies[low]["stored"].rsplit("\\", 1)[-1]
            if not stored.lower().endswith(".dbc"):
                continue
            got = pick(low, realm_ids[realm])
            if got is None:
                continue
            files[stored] = place(low, got[1], out, stored)
        realms[realm] = {"archives": sorted(realm_ids[realm]), "files": files}

    inputs = {
        "note": "What the curated data/ layer was derived from. Written by "
                "datamine.py's traversal, read by its curate() stage; work/ is "
                "gitignored, the committed copy of these facts is "
                "raw/provenance.json's `curationInputs`.",
        "curationRule": CURATION_RULE,
        "baseVariantRule": BASE_VARIANT_RULE,
        "baseArchives": sorted(base_ids),
        "base": base,
        "headerMismatches": sorted(mismatches, key=lambda m: m["table"]),
        "realms": realms,
    }
    _write_json(config.WORK_DIR / CURATION_INPUTS_JSON, inputs)
    prog.note(f"curation inputs: {len(base)} base tables, "
              f"{len(realms)} realm overlay(s) "
              f"({sum(len(r['files']) for r in realms.values())} tables), "
              f"{len(mismatches)} header mismatch(es)")
    return inputs


PROVENANCE_MAX_LINES = 5000
PROVENANCE_LIST_LIMIT = 50


def _compact(value):
    """Provenance carries COUNTS, not payloads.

    The stage stats a builder returns include its own id lists - 7,119 missing
    Reborn refs, 2,810 stale rank-chain ids, and so on - and `indent=1` puts every
    one of them on its own line. The committed raw/provenance.json was 12,356
    lines because of it, in a repo whose own rule is that no generated file goes
    past 5,000. Those lists are not lost: each already lives, in full, in the
    layer that owns it (data/spells/_missing_refs.json and friends), which is
    where a reader can grep it. Here they become a count.

    The rule is mechanical - any list of more than PROVENANCE_LIST_LIMIT scalars,
    anywhere in the tree - so it needs no per-key maintenance and cannot rot into
    a hand-kept list of exceptions."""
    if isinstance(value, dict):
        return {k: _compact(v) for k, v in value.items()}
    if isinstance(value, list):
        if (len(value) > PROVENANCE_LIST_LIMIT
                and all(not isinstance(v, (dict, list)) for v in value)):
            return {"count": len(value),
                    "elided": ("the full list lives in the layer that owns it; "
                               "provenance carries counts")}
        return [_compact(v) for v in value]
    return value


def run(inputs: dict = None) -> dict:
    """Drive every per-domain builder over the materialized inputs, in
    dependency order, and write raw/provenance.json.

    This is what `tools/build_dataset.py` used to be, minus its four
    client-reading stages, which the raw layer already produced from the
    snapshot and which are therefore gone rather than repeated:

        extract_mpq        -> materialize_inputs (base context)
        extract_realms     -> materialize_inputs (realm contexts)
        snapshot_content   -> emit.emit_content   (raw/content)
        extract_interface  -> emit.emit_interface (raw/interface)

    `inputs` defaults to the sidecar the traversal wrote, so a test can re-run
    curation alone against the inputs of the last full pass. There is
    deliberately no __main__ in this module - nor in any builder it drives, nor
    in the four retired extractors: see ENTRY_POINT_RULE."""
    from tools import (dbc, build_spells, build_classes, build_talents,
                       build_dungeons, build_creatures, build_classmeta,
                       build_essence, build_mythic, build_manastorm,
                       build_realms, build_coatalents, build_items, build_gt,
                       build_abilities, coverage_live, diff_realm_overlay)

    if inputs is None:
        inputs = json.loads((config.WORK_DIR / CURATION_INPUTS_JSON)
                            .read_text(encoding="utf-8"))
    config.ensure_dirs()
    dbc.dump_all()
    stats = {}

    def stage(name, fn, fmt=str):
        t = time.time()
        stats[name] = fn()
        print(f"  {name:11s} {fmt(stats[name])}  [{time.time() - t:6.1f}s]",
              flush=True)

    # The ability-identity layer FIRST, and that ordering is the whole repair.
    # It reads raw/ only - the live builder capture, the base Spell variant, the
    # trainer rows, the rank chains, the catalog - and joins CoA's several spell
    # id generations into one ability per (class, name). Every stage below that
    # needs to know what is LIVE asks it, instead of asking the catalog.
    stage("abilities", build_abilities.build,
          lambda s: f"{s['abilities']} abilities, {s['abilitiesLive']} live, "
                    f"{s['abilitiesMultiGeneration']} multi-generation")
    stage("spells", build_spells.build,
          lambda s: f"{s['written']} written, live {s['liveCoverage']['covered']}/"
                    f"{s['liveCoverage']['liveNodeIds']}, "
                    f"missing_by_source={ {k: len(v) for k, v in s['missing_by_source'].items()} }")
    stage("classes", build_classes.build)
    # coatalents joins the frozen builder capture against data/classes + data/spells
    # (classId join + resolve-rate cross-validation), so it follows both; classmeta
    # reads its _meta.json, so it precedes classmeta.
    stage("coatalents", build_coatalents.build)
    stage("talents", build_talents.build)
    stage("dungeons", build_dungeons.build)
    stage("creatures", build_creatures.build)
    # classmeta writes INTO data/classes/, which build_classes owns and rebuilds
    # wholesale - it must come after it or its specs.json/archetypes.json are wiped.
    stage("classmeta", build_classmeta.build)
    stage("essence", build_essence.build)
    stage("gt", build_gt.build, lambda s: str(s["counts"]))
    stage("mythic", build_mythic.build)
    stage("items", build_items.build)
    stage("manastorm", build_manastorm.build)
    # realms reads data/spells/_missing_refs.json (the spells stage, above) and the
    # per-realm dbc dirs materialize_inputs wrote - the realm list comes
    # from the SNAPSHOT's archive layout, never from a fresh scan of the client.
    stage("realms", lambda: build_realms.build(realms=sorted(inputs["realms"])),
          lambda s: str(sorted(s)))
    # Both of the following write committed files under data/ off the tree the
    # stages above just curated, so they must run INSIDE the pass. They were
    # once hand-run CLIs, which is a drift class rather than a convenience: a
    # rebuild refreshed everything around them while their own outputs kept the
    # previous run's numbers, and no test noticed because each file's internal
    # gates are checked against figures stored in that same file.
    # overlay_diff follows realms because build_realms owns the rest of
    # data/realms/<realm>/ and rewrites that directory.
    stage("overlayDiff", lambda: diff_realm_overlay.build(sorted(inputs["realms"])),
          lambda s: ", ".join(f"{r}: {v['differing']}/{v['shared']} differ"
                              for r, v in sorted(s.items())))
    # coverage_live reads data/spells + data/classes, so it follows both.
    stage("coverageLive", coverage_live.build,
          lambda s: f"{s['modelable']}/{s['slots']} live slots modelable "
                    f"({s['modelablePct']:.1f}%), {s['holeDistinctSpellSlotPairs']} "
                    f"hole pairs, goldens {'pass' if s['goldenChecksPass'] else 'FAIL'}")

    prov = {
        "generatedUtc": datetime.datetime.now(datetime.timezone.utc)
                        .isoformat(timespec="seconds"),
        "clientDir": str(config.CLIENT_DIR),
        "curationRule": CURATION_RULE,
        "baseVariantRule": BASE_VARIANT_RULE,
        "liveSeedRule": LIVE_SEED_RULE,
        "entryPointRule": ENTRY_POINT_RULE,
        # The residual drift class, measured rather than implied: curation is a
        # pure function of raw/, but raw/talents/coa-builder-*.html is a network
        # capture on its own clock, taken outside this guarded pass. Everything
        # `live` says is only as current as that fetch.
        "liveSeedDrift": coa_live.seed_drift(),
        "curationInputs": {
            "baseArchives": inputs["baseArchives"],
            "base": {k: {"archive": v["archive"], "sha256": v["sha256"],
                         "records": v["records"], "fields": v["declaredFields"],
                         "actualFields": v["actualFields"]}
                     for k, v in sorted(inputs["base"].items())},
            "realms": {r: {"archives": v["archives"],
                           "files": {n: {"archive": f["archive"],
                                         "sha256": f["sha256"],
                                         "records": f["records"]}
                                     for n, f in sorted(v["files"].items())}}
                       for r, v in sorted(inputs["realms"].items())},
        },
        "buildStats": _compact(stats),
        # Every base table whose WDBC header's declared FieldCount disagrees with
        # its byte-accurate record_size//4. tests/test_dataset.py gates this
        # against an explicit allowlist, so a NEW base mismatch fails loudly.
        "headerMismatches": inputs["headerMismatches"],
    }
    path = config.RAW_DIR / "provenance.json"
    _write_json(path, prov)
    lines = path.read_bytes().count(b"\n")
    if lines > PROVENANCE_MAX_LINES:
        raise SystemExit(
            f"FATAL: raw/provenance.json is {lines} lines, past the {PROVENANCE_MAX_LINES}-line "
            "rule every generated file in this repo is held to. A stage is "
            "returning a payload where it should return a count - extend "
            "_compact rather than raising the limit.")
    return prov
