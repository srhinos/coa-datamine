"""TDD gate for task V3-2: realm-overlay extraction. Data\\<realm>\\ archives (e.g.
area-52's patch-D.MPQ, discovered generically via its own `listarchive` file) ->
work/realms/<realm>/dbc/ (tools/extract_realms.py) -> raw/realms/<realm>/dbc/
(mapped dump reusing base TABLE_MAPS, or dump_unmapped-style colinfo for realm-only
tables) + data/realms/<realm>/index.json overlay evidence (tools/build_realms.py).

Amendment D (single-writer ownership): tools/extract_realms.py is the sole writer
under work/realms/; tools/build_realms.py is the sole writer under raw/realms/ and
data/realms/ - nothing else in this repo touches these paths.

No new column proofs are introduced by this task - it reuses base TABLE_MAPS column
maps (with the SAME field-count layout guard) for every realm table that matches a
base map by name+field-count. Verified realm facts (2026-08-01 probe, area-52's
patch-D.MPQ via its own listarchive; brief warns these may drift slightly with the
latest client patch - this test re-verifies against whatever's on disk, not a frozen
fixture): CharacterAdvancement 7820x179(declared), CharacterAdvancementEssence
5440x9, Manastorm 1025x9, ManastormMessages 291x39, ManastormModifiers 32768x15,
ManastormPlayerGroupModifiers 15x5, SkillLineAbility 38542x14, Spell 238925x234,
SpellCharges 473x2, SpellChargesCategory 108x3, SpellRank 19601x4, Talent 2368x23.
CharacterAdvancement/SpellRank have no base TABLE_MAPS entry at all (colinfo-only,
deliberate, per the brief) - the other 10 do.

[Task W4-5 UPDATE] CharacterAdvancementEssence gained a real TABLE_MAPS column
proof (id/level/classId/abilityEssence/talentEssence, see tools/dbc.py) - it moved
from UNMAPPED_TABLES to MAPPED_TABLES below. This is the one *intended* change to
this file's expectations from that task; everything else here is unchanged.

[Task W4-10 UPDATE] SpellRank ALSO gained a real TABLE_MAPS column proof
(id/firstSpellId/spellId/rank, raw-dump-clarity naming only, NOT wired into
build_spells.py's rank-chain pipeline - see tools/dbc.py) - same move,
UNMAPPED_TABLES -> MAPPED_TABLES, and unlike CharacterAdvancementEssence's own
move, SpellRank ALSO gained a base config.WANTED_DBCS entry in the same task
(WANTED_DBCS_V5), so it now carries baseRecords/delta like every other mapped
table - CharacterAdvancement is the only table left with neither a TABLE_MAPS
entry nor a base WANTED_DBCS entry at all.

[Finding, discovered running this test] CharacterAdvancement.dbc's WDBC header
DECLARES FieldCount 179, but its record_size (692 bytes) only fits 173 int32
fields, and 692 is what reconciles exactly with the file's real total size - the
declared 179 is simply wrong. tools/dbc.py's DBCFile now derives `.fields` from
record_size (byte-accurate, and a no-op for every table that was already
self-consistent, base or realm) and exposes the header's raw claim separately as
`.declared_fields`; tools/build_realms.py surfaces a mismatch as a
`declaredFields` key in that table's index.json entry."""
import json, struct, sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from tools import config, dbc, extract_mpq, extract_realms, build_realms

REALM = "area-52"

# ---- config: generic realm-dir discovery helper ----
assert REALM in config.discover_realms(), config.discover_realms()
assert "enUS" not in config.discover_realms() and "Content" not in config.discover_realms()

# ---- extraction layer (tools/extract_realms.py) ----
extract_mpq.extract_all()          # base work/dbc must be populated (Spell.dbc etc.)
prov = extract_realms.extract_all()
assert REALM in prov, prov.keys()
frag = prov[REALM]

EXPECTED = {
    "CharacterAdvancement": (7820, 179), "CharacterAdvancementEssence": (5440, 9),
    "Manastorm": (1025, 9), "ManastormMessages": (291, 39),
    "ManastormModifiers": (32768, 15), "ManastormPlayerGroupModifiers": (15, 5),
    "SkillLineAbility": (38542, 14), "Spell": (238939, 234),
    "SpellCharges": (473, 2), "SpellChargesCategory": (108, 3),
    "SpellRank": (19601, 4), "Talent": (2368, 23),
}
assert set(frag["files"]) == {f"{t}.dbc" for t in EXPECTED}, sorted(frag["files"])
for table, (recs, fields) in EXPECTED.items():
    e = frag["files"][f"{table}.dbc"]
    assert (e["records"], e["fields"]) == (recs, fields), (table, e)
    assert len(e["sha256"]) == 64
    p = config.WORK_REALMS_DIR / REALM / "dbc" / f"{table}.dbc"
    assert p.is_file()
    magic, r2, f2, recsize, strsize = struct.unpack_from("<4s4I", p.read_bytes(), 0)
    assert magic == b"WDBC" and (r2, f2) == (recs, fields), table
    assert p.stat().st_size == 20 + r2 * recsize + strsize

saved = json.loads((config.WORK_REALMS_DIR / "extract_provenance.json").read_text(encoding="utf-8"))
assert saved[REALM]["files"]["Spell.dbc"]["records"] == 238939

# byte-true field count per table (record_size/4) - what dbc.DBCFile.fields actually
# reports; disagrees with the header's DECLARED field count for CharacterAdvancement
# only (see module docstring finding)
TRUE_FIELDS = {t: frag["files"][f"{t}.dbc"]["record_size"] // 4 for t in EXPECTED}
assert TRUE_FIELDS["CharacterAdvancement"] == 173, TRUE_FIELDS
assert all(TRUE_FIELDS[t] == EXPECTED[t][1] for t in EXPECTED if t != "CharacterAdvancement")

# ---- build layer: mapped/colinfo dump + curated overlay index ----
results = build_realms.build()
assert REALM in results
idx = results[REALM]

MAPPED_TABLES = {"Spell", "SkillLineAbility", "Talent", "SpellCharges",
                  "SpellChargesCategory", "Manastorm", "ManastormMessages",
                  "ManastormModifiers", "ManastormPlayerGroupModifiers",
                  "CharacterAdvancementEssence", "SpellRank"}
UNMAPPED_TABLES = {"CharacterAdvancement"}
assert set(idx["tables"]) == MAPPED_TABLES | UNMAPPED_TABLES, set(idx["tables"])

raw_dir = config.RAW_REALMS_DIR / REALM / "dbc"
for table in MAPPED_TABLES:
    info = idx["tables"][table]
    assert info["mapped"] is True, (table, info)
    assert info["records"] == EXPECTED[table][0] and info["fields"] == TRUE_FIELDS[table]
    assert "declaredFields" not in info, (table, info)     # all 11 mapped tables self-consistent
    assert (raw_dir / f"{table}.csv.gz").is_file()
    assert not (raw_dir / f"{table}.colinfo.json").exists()
    # baseRecords/delta populated: every mapped table here also has a base
    # config.WANTED_DBCS entry of the same name
    assert isinstance(info["baseRecords"], int), (table, info)
    assert info["delta"] == info["records"] - info["baseRecords"], (table, info)
for table in UNMAPPED_TABLES:
    info = idx["tables"][table]
    assert info["mapped"] is False, (table, info)
    assert info["records"] == EXPECTED[table][0] and info["fields"] == TRUE_FIELDS[table]
    assert (raw_dir / f"{table}.csv.gz").is_file()
    assert (raw_dir / f"{table}.colinfo.json").is_file()

# "mapped" (has a base TABLE_MAPS column proof) and "has a base WANTED_DBCS entry to
# diff against" are independent axes - CharacterAdvancement has no base DBC of this
# name AT ALL (realm-only table), so both are null/null for real, not just unmapped.
# [Task W4-5] Before that task, CharacterAdvancementEssence.dbc was the
# axis-independence example (base entry present, mapped false) - it moved to
# MAPPED_TABLES above once tools/dbc.py gained its column proof. [Task W4-10]
# SpellRank made the SAME move AND gained a base WANTED_DBCS entry in the same
# task (WANTED_DBCS_V5) - it now carries real baseRecords/delta like the other 10
# originally-mapped tables, leaving CharacterAdvancement as the sole table on
# neither axis.
assert "CharacterAdvancementEssence.dbc" in config.WANTED_DBCS
assert "SpellRank.dbc" in config.WANTED_DBCS
for table in ("CharacterAdvancement",):
    info = idx["tables"][table]
    assert info["baseRecords"] is None and info["delta"] is None, (table, info)
    assert f"{table}.dbc" not in config.WANTED_DBCS

# CharacterAdvancement's declared/true field-count mismatch must be surfaced, not
# silently swallowed
assert idx["tables"]["CharacterAdvancement"]["declaredFields"] == 179
for table in ("CharacterAdvancementEssence", "SpellRank"):
    assert "declaredFields" not in idx["tables"][table], idx["tables"][table]

# a mapped colinfo.json must never exist (would corrupt raw/dbc-style expectations)
for table in MAPPED_TABLES:
    assert not (raw_dir / f"{table}.colinfo.json").is_file()

# golden gate: base spell id 17 decodes via the base TABLE_MAPS column map read
# straight off the REALM's OWN Spell.dbc - proves layout compatibility, not just a
# matching field count
spell_rows = {r["id"]: r for r in dbc.iter_named("Spell", dbc_dir=config.WORK_REALMS_DIR / REALM / "dbc")}
assert spell_rows[17]["name_enUS"] == "Power Word: Shield", spell_rows[17]
assert len(spell_rows) == 238939

# overlay evidence: newSpellCount / spellIdRange
assert idx["newSpellCount"] > 10000, idx["newSpellCount"]      # brief's loose pin, ~+30k expected
lo, hi = idx["spellIdRange"]
assert lo <= 17 <= hi
assert lo == min(spell_rows) and hi == max(spell_rows)

# overlay evidence: missingRefResolution, per base data/spells/_missing_refs.json bucket
missing = json.loads((config.DATA_DIR / "spells" / "_missing_refs.json").read_text(encoding="utf-8"))
assert set(idx["missingRefResolution"]) == set(missing), idx["missingRefResolution"]
for source, ids in missing.items():
    mr = idx["missingRefResolution"][source]
    assert mr["missingCount"] == len(ids), (source, mr)
    assert 0 <= mr["resolvedInRealm"] <= mr["missingCount"], (source, mr)
    # membership check must be real, not a stub: recompute independently
    real_resolved = sum(1 for i in ids if i in spell_rows)
    assert mr["resolvedInRealm"] == real_resolved, (source, mr, real_resolved)

# ---- curated files on disk match the returned dict exactly ----
data_dir = config.DATA_REALMS_DIR / REALM
on_disk_index = json.loads((data_dir / "index.json").read_text(encoding="utf-8"))
assert on_disk_index == idx
meta = json.loads((data_dir / "_meta.json").read_text(encoding="utf-8"))
assert meta["realm"] == REALM
assert set(meta["mappedTables"]) == MAPPED_TABLES
assert set(meta["unmappedTables"]) == UNMAPPED_TABLES
assert "futureMilestone" in meta and "curation" in meta["futureMilestone"].lower()

print("ALL PASS")
