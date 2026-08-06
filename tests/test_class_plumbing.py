"""TDD gate for task W4-5 (class/realm plumbing): coa-sim-handoff/
DATAMINE-REQUEST.md Sec 7 (essence + ChrClassesRoles goldens), Sec 11 (specs.json
inconsistency / the ChrClasses.filename fix), Sec 3 (the realm-overlay dispute
numbers), Sec 4 trap 6, Sec 13 items 9+12 (+item 7's prep half).

(a) CharacterAdvancementEssence -> data/classes/essence.json (tools/build_essence.py,
    a new module - Amendment D keeps this OUT of build_classmeta.py, which owns
    specs.json/archetypes.json ONLY per its own docstring).
(b) ChrClasses.filename column (already a TABLE_MAPS entry, newly wired through):
    index.json chrClasses gain `filename`; the 3 null-classId CoA dirs (DemonHunter/
    Monk/SonOfArugal) resolve via a filename fallback join in both
    tools/build_classes.py and tools/build_classmeta.py; ClassRemap-style aliases
    (Runemaster/Primalist/Venomancer/"Knight of Xoroth") surface as `aliases`.
(c) ChrClassesRoles roster cross-check: this task's own re-derivation of the doc's
    Sec 7 role roster against specs.json's `roles` (already golden-proven in V2-3,
    unchanged code) - full agreement, so nothing about role derivation changed.
(d) tools/diff_realm_overlay.py: base-vs-overlay Spell.dbc diff, run against
    area-52, gated against Sec 3's own cited numbers at +/-10% tolerance.
(e) config.discover_realms() fixture-dir test (item 7 prep)."""
import json, shutil, sys, tempfile
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from tools import config, dbc, sharding
from tools import build_classes, build_classmeta, build_essence, build_realms, diff_realm_overlay

MAX_LINES = 5000


def _line_count(p):
    return sum(1 for _ in open(p, encoding="utf-8"))


# ============================= (a) essence.json =============================

ess_stats = build_essence.build()
assert ess_stats == {"count": 32, "coaCustomCount": 21}, ess_stats

edir = config.DATA_DIR / "classes"
essence_path = edir / "essence.json"
assert essence_path.is_file()
assert _line_count(essence_path) <= MAX_LINES

essence = json.loads(essence_path.read_text(encoding="utf-8"))
assert essence["levels"] == list(range(1, 81))
classes = essence["classes"]
assert len(classes) == 32
by_class_id = {c["classId"]: c for c in classes}
assert set(by_class_id) == set(range(1, 33))

# ---- goldens, RE-DERIVED directly from work/dbc/CharacterAdvancementEssence.dbc
# at test time (not trusting the curated file alone) - same discipline as
# test_gt.py's independent re-derivation of the gt* layout goldens. ----
raw = dbc.DBCFile(config.WORK_DBC_DIR / "CharacterAdvancementEssence.dbc")
assert raw.fields == 9
canonical = {}   # (classId, level) -> (ae, te), flags-(0,0,0,0) rows only
for row in raw.iter_rows():
    if row[3] == row[4] == row[5] == row[6] == 0:
        canonical[(dbc.u32(row[2]), dbc.u32(row[1]))] = (dbc.u32(row[7]), dbc.u32(row[8]))
assert len(canonical) == 2560, "expected exactly 32 classes x 80 levels canonical rows"

# classless (classId 1-9, 11) @ level 60 = (60, 51) - "the classic 51-talent-point number"
for cid in (1, 2, 3, 4, 5, 6, 7, 8, 9, 11):
    assert canonical[(cid, 60)] == (60, 51), cid
    c = by_class_id[cid]
    assert (c["abilityEssence"][59], c["talentEssence"][59]) == (60, 51), cid
    assert c["curveGroup"] == "classlessBase"

# Hero (classId 10) @ level 60 = (100, 51)
assert canonical[(10, 60)] == (100, 51)
hero = by_class_id[10]
assert (hero["abilityEssence"][59], hero["talentEssence"][59]) == (100, 51)
assert hero["curveGroup"] == "hero"

# all 21 CoA-custom classes (12-32) share ONE curve, matching the doc's cited
# breakpoints exactly: L10 (1,0) L20 (6,5) L30 (11,10) L40 (16,15) L50 (21,20)
# L60 (26,25) L70 (31,30) L80 (36,35)
DOC_COA_CURVE = {10: (1, 0), 20: (6, 5), 30: (11, 10), 40: (16, 15),
                  50: (21, 20), 60: (26, 25), 70: (31, 30), 80: (36, 35)}
coa_curve_shapes = set()
for cid in range(12, 33):
    c = by_class_id[cid]
    assert c["curveGroup"] == "coaCustom"
    coa_curve_shapes.add((tuple(c["abilityEssence"]), tuple(c["talentEssence"])))
    for lvl, (ae, te) in DOC_COA_CURVE.items():
        assert canonical[(cid, lvl)] == (ae, te), (cid, lvl)
        assert (c["abilityEssence"][lvl - 1], c["talentEssence"][lvl - 1]) == (ae, te), (cid, lvl)
assert len(coa_curve_shapes) == 1, "all 21 CoA-custom classes must share one identical curve"

# className resolved via ChrClasses, including the 3 filename-only matches
assert by_class_id[14]["className"] == "Felsworn"     # DemonHunter dir's real class
assert by_class_id[19]["className"] == "Templar"       # Monk dir
assert by_class_id[20]["className"] == "Bloodmage"     # SonOfArugal dir


# ==================== (b) ChrClasses.filename + classId fix ====================

chr_rows = {r["id"]: r for r in dbc.iter_named("ChrClasses")}
assert len(chr_rows) == 32

# golden: the 3 display-name/filename divergences DATAMINE-REQUEST.md Sec 11 cites,
# re-derived directly against work/dbc/ChrClasses.dbc (not copied from the doc)
assert chr_rows[14]["name_enUS"] == "Felsworn" and chr_rows[14]["filename"] == "DEMONHUNTER"
assert chr_rows[19]["name_enUS"] == "Templar" and chr_rows[19]["filename"] == "MONK"
assert chr_rows[20]["name_enUS"] == "Bloodmage" and chr_rows[20]["filename"] == "SONOFARUGAL"

# cross-check against the client's own ClassRemap Lua table (independent evidence,
# not the DBC) - every one of the 4 non-trivial custom-class remaps
CLASS_REMAP_ALIASES = {
    "Runemaster": "SPIRITMAGE", "Primalist": "WILDWALKER",
    "Venomancer": "PROPHET", "KnightOfXoroth": "FLESHWARDEN",
}
remap_lua = (config.RAW_INTERFACE_DIR / "FrameXML" / "Data" / "CharacterAdvancement.lua").read_text(encoding="utf-8")
for cad_name, token in CLASS_REMAP_ALIASES.items():
    assert f'["{cad_name}"]' in remap_lua and f'= "{token}"' in remap_lua, cad_name

build_stats = build_classes.build()
cidx = json.loads((edir / "index.json").read_text(encoding="utf-8"))

# gate: index.json chrClasses entries carry filename
by_chr_id = {c["id"]: c for c in cidx["chrClasses"]}
assert by_chr_id[14]["filename"] == "DEMONHUNTER"
assert by_chr_id[19]["filename"] == "MONK"
assert by_chr_id[20]["filename"] == "SONOFARUGAL"
assert all("filename" in c for c in cidx["chrClasses"])

# gate: 21/21 coa-custom class dirs have a non-null classId
coa_classes = [c for c in cidx["classes"] if c["tag"] == "coa-custom"]
assert len(coa_classes) == 21, len(coa_classes)
assert all(c["classId"] is not None for c in coa_classes), \
    [c["name"] for c in coa_classes if c["classId"] is None]
by_name = {c["name"]: c for c in cidx["classes"]}
assert by_name["DemonHunter"]["classId"] == 14
assert by_name["Monk"]["classId"] == 19
assert by_name["SonOfArugal"]["classId"] == 20

# gate: only Hero remains unmatched (no CAD class named "Hero" exists at all)
assert cidx["unmatchedChrClasses"] == ["Hero"], cidx["unmatchedChrClasses"]

# gate: ClassRemap aliases surfaced exactly where they apply, nowhere else
for cad_name, token in CLASS_REMAP_ALIASES.items():
    assert by_name[cad_name]["aliases"] == [token], (cad_name, by_name[cad_name]["aliases"])
for name in ("DemonHunter", "Monk", "SonOfArugal"):
    assert by_name[name]["aliases"] == [], (name, by_name[name]["aliases"])   # filename == own name
assert by_name["Necromancer"]["aliases"] == []
no_alias_count = sum(1 for c in cidx["classes"] if c["tag"] == "coa-custom" and not c["aliases"])
assert no_alias_count == 21 - len(CLASS_REMAP_ALIASES)

# per-class index.json carries the same aliases/classId (not just the top-level manifest)
knight_meta = json.loads((edir / by_name["KnightOfXoroth"]["index"]).read_text(encoding="utf-8"))
assert knight_meta["classId"] == 17 and knight_meta["aliases"] == ["FLESHWARDEN"]
demon_meta = json.loads((edir / by_name["DemonHunter"]["index"]).read_text(encoding="utf-8"))
assert demon_meta["classId"] == 14 and demon_meta["aliases"] == []


# =============== (b continued) specs.json perClass classId fix ===============

meta_stats = build_classmeta.build()
specs_doc = json.loads((edir / "specs.json").read_text(encoding="utf-8"))
specs = specs_doc["specs"]
by_spec_id = {s["id"]: s for s in specs}

# gate: 32/32 ChrClasses now covered (was 25/32 before the filename fallback)
matched_class_ids = {s["classId"] for s in specs if s["classId"] is not None}
assert matched_class_ids == set(range(1, 33)), sorted(set(range(1, 33)) - matched_class_ids)
assert meta_stats["specs"]["classesCovered"] == 32
assert meta_stats["specs"]["coverage"] == 1.0

# golden: DEMONHUNTER-token spec (id 7, "Infernal") now resolves - was null/null
assert by_spec_id[7]["classId"] == 14 and by_spec_id[7]["className"] == "Felsworn"
assert by_spec_id[7]["classToken"] == "DEMONHUNTER" and by_spec_id[7]["tabToken"] == "FELBLOOD"

# content sanity check (per the task's binding rule: does the DemonHunter/Monk/
# SonOfArugal dir's content actually make sense as Felsworn/Templar/Bloodmage's?):
# each filename-token's ChrSpecs tabTokens must match that CAD dir's own tab names.
demon_tabs = {f["tab"] for f in demon_meta["files"] if f["tab"]}
demon_spec_tabs = {s["tabToken"] for s in specs if s["classToken"] == "DEMONHUNTER"}
assert demon_spec_tabs <= {t.upper() for t in demon_tabs}, (demon_spec_tabs, demon_tabs)
monk_meta = json.loads((edir / by_name["Monk"]["index"]).read_text(encoding="utf-8"))
monk_tabs = {f["tab"] for f in monk_meta["files"] if f["tab"]}
monk_spec_tabs = {s["tabToken"] for s in specs if s["classToken"] == "MONK"}
assert monk_spec_tabs <= {t.upper() for t in monk_tabs}, (monk_spec_tabs, monk_tabs)


# ================ (c) ChrClassesRoles roster cross-check (Sec 7) ================
# Re-derivation of the doc's own published roster against specs.json["roles"]
# (unchanged V2-3 code - ChrClassesRoles.roleMask decoded directly). This is a
# VERIFICATION pass, not a fix: per the task's binding rule, change nothing if
# they agree - they do, so build_classmeta.py's role logic is untouched by this task.

DOC_ROLE_ROSTER = {
    "Pure DPS": (["Barbarian", "Hunter", "Mage", "Necromancer", "Ranger", "Rogue",
                  "Runemaster", "Stormbringer"], {"DPS"}),
    "Tank+DPS": (["Death Knight", "Felsworn", "Guardian", "Knight of Xoroth", "Primalist",
                  "Reaper", "Templar", "Bloodmage", "Warlock", "Warrior", "Witch Hunter"],
                 {"Tank", "DPS"}),
    "Healer+DPS": (["Chronomancer", "Priest", "Pyromancer", "Shaman", "Tinker", "Witch Doctor"],
                   {"Healer", "DPS"}),
    "Tank+Healer+DPS": (["Cultist", "Druid", "Paladin", "Starcaller", "Sun Cleric", "Venomancer"],
                        {"Tank", "Healer", "DPS"}),
}
roles = specs_doc["roles"]
assert len(roles) == 32
covered, mismatches = set(), []
for group, (names, expected) in DOC_ROLE_ROSTER.items():
    for name in names:
        covered.add(name)
        if set(roles.get(name, [])) != expected:
            mismatches.append((name, group, expected, roles.get(name)))
assert not mismatches, mismatches
assert len(covered) == 31, "doc's Sec 7 roster covers 31 of the 32 ChrClasses"
# the sole gap is Hero (unreleased/unmatched to any CAD class, see
# unmatchedChrClasses above) - the doc's own roster simply never lists it, not a
# disagreement between the two sources
assert set(roles) - covered == {"Hero"}


# =========================== (d) diff_realm_overlay ===========================

REALM = "area-52"
build_realms.build(skip_extract=True)   # ensure work/realms is populated + index.json fresh
result = diff_realm_overlay.build(REALM)

odir = config.DATA_REALMS_DIR / REALM
overlay_path = odir / "overlay_diff.json"
assert overlay_path.is_file()
assert _line_count(overlay_path) <= MAX_LINES
on_disk = json.loads(overlay_path.read_text(encoding="utf-8"))
assert on_disk == result, "overlay_diff.json on disk must match the returned report dict"

assert result["realm"] == REALM
assert result["sharedCount"] > 0
assert result["differingSharedCount"] <= result["sharedCount"]
assert result["nameChangeCount"] == len(result["nameChanges"])
assert all(0 <= c["diffCount"] <= result["sharedCount"] for c in result["columnDiffs"])
assert result["columnDiffs"] == sorted(
    result["columnDiffs"], key=lambda r: (-r["diffCount"], r["field"]))
# independently recompute overlay-only/base-only spell-id counts directly from
# work/dbc + work/realms/<realm>/dbc, not trusting the module's own arithmetic
base_ids = {r["id"] for r in dbc.iter_named("Spell")}
overlay_ids = {r["id"] for r in dbc.iter_named("Spell", dbc_dir=config.WORK_REALMS_DIR / REALM / "dbc")}
assert result["totalBaseSpellCount"] == len(base_ids)
assert result["totalOverlaySpellCount"] == len(overlay_ids)
assert result["overlayOnlySpellCount"] == len(overlay_ids - base_ids)
assert result["baseOnlySpellCount"] == len(base_ids - overlay_ids)

# gate: reproduces Sec 3's cited area-52 numbers within +/-10% (the brief's own
# tolerance) - report exact, don't force an exact match (patch drift expected)
for label, cmp in result["docComparison"].items():
    assert cmp["withinTolerance"], (label, cmp)

# golden: the doc's own literal example (spell 92093 renamed Deadeye -> Houndmaster)
by_id_change = {c["id"]: c for c in result["nameChanges"]}
assert by_id_change[92093] == {"id": 92093, "baseName": "Deadeye", "overlayName": "Houndmaster"}

# golden: effectBasePoints1 (f80) is the doc's own "damage numbers" column
bp1 = next(c for c in result["columnDiffs"] if c["field"] == "effectBasePoints1")
assert bp1["index"] == 80
assert result["damageNumberDisagreementCount"] == bp1["diffCount"]

# description_enUS (f170) must be the single highest-diff-count column, matching
# the doc's own "top differing columns" ranking
assert result["columnDiffs"][0]["field"] == "description_enUS"
assert result["columnDiffs"][0]["index"] == 170

# ---- Amendment D boundary: overlay_diff.json must survive a build_realms rerun
# (the bug this task found and fixed in tools/build_realms.py - it used to
# shutil.rmtree() the whole data/realms/<realm>/ dir before rewriting) ----
build_realms.build(skip_extract=True)
assert overlay_path.is_file(), "overlay_diff.json destroyed by a build_realms rerun"
overlay_after = json.loads(overlay_path.read_text(encoding="utf-8"))
assert overlay_after == result, "overlay_diff.json content changed by an unrelated build_realms rerun"
# index.json/_meta.json are still build_realms' own job - real content, not stubs
idx_after = json.loads((odir / "index.json").read_text(encoding="utf-8"))
assert idx_after["realm"] == REALM and "tables" in idx_after


# ======================= (e) discover_realms fixture-dir test =======================
# Item 7 prep: verify discover_realms() picks up a hypothetical new realm dir,
# via a temp fixture (not the real client install) so this is a true unit test.

tmp_root = Path(tempfile.mkdtemp(prefix="coa_discover_realms_"))
try:
    data_dir = tmp_root / "Data"
    (data_dir / "rexxar").mkdir(parents=True)
    (data_dir / "rexxar" / "listarchive").write_text("patch-D.MPQ\n", encoding="utf-8")
    (data_dir / "voljin").mkdir(parents=True)
    (data_dir / "voljin" / "listarchive").write_text("patch-D.MPQ\n", encoding="utf-8")
    (data_dir / "enUS").mkdir(parents=True)                    # excluded base locale dir
    (data_dir / "enUS" / "listarchive").write_text("x\n", encoding="utf-8")  # even if it had one
    (data_dir / "Content").mkdir(parents=True)                 # excluded base content dir
    (data_dir / "norealm").mkdir(parents=True)                 # no listarchive -> not a realm

    saved_client_dir = config.CLIENT_DIR
    config.CLIENT_DIR = tmp_root
    try:
        found = config.discover_realms()
    finally:
        config.CLIENT_DIR = saved_client_dir

    assert found == ["rexxar", "voljin"], found     # sorted, both real fixture realms
    assert "enUS" not in found and "Content" not in found and "norealm" not in found
finally:
    shutil.rmtree(tmp_root, ignore_errors=True)

# sanity: the real client install still resolves correctly after the monkeypatch
# is restored (config.CLIENT_DIR round-tripped cleanly)
assert REALM in config.discover_realms()

print("ALL PASS")
