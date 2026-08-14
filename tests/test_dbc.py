import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

# Read-only test: sandbox() reads client bytes from the sealed snapshot and
# arms the guard that fails this test if it writes a committed root.
from tests import _iso; _iso.sandbox()

from tools import config, dbc

# reader fundamentals on a small table
f = dbc.DBCFile(config.WORK_DBC_DIR / "ChrClasses.dbc")
assert f.fields == 60 and f.records == 32
rows = {r[0]: r for r in f.iter_rows()}
assert f.string(rows[1][4]) == "Warrior"          # name_enUS at index 4
assert f.string(rows[8][4]) == "Mage"

# named iteration + kinds
classes = {r["id"]: r for r in dbc.iter_named("ChrClasses")}
assert classes[1]["name_enUS"] == "Warrior"
assert len(classes) == 32 and max(classes) == 32   # CoA classes 17-32 exist
custom = {classes[i]["name_enUS"] for i in range(17, 33)}
assert len(custom) == 16 and "" not in custom, custom

# float + string decoding via SpellRange
ranges = {r["id"]: r for r in dbc.iter_named("SpellRange")}
assert ranges[1]["maxRange"] == 0.0 and isinstance(ranges[1]["maxRange"], float)

# layout guard fires on wrong expectation
saved = dbc.TABLE_MAPS["ChrClasses"]["expected_fields"]
dbc.TABLE_MAPS["ChrClasses"]["expected_fields"] = 61
try:
    list(dbc.iter_named("ChrClasses")); raise AssertionError("guard did not fire")
except dbc.LayoutError:
    pass
finally:
    dbc.TABLE_MAPS["ChrClasses"]["expected_fields"] = saved

# Spell golden rows (indices per stock 3.3.5 layout, field_count verified 234)
seen = {}
for r in dbc.iter_named("Spell"):
    if r["id"] in (10, 17):
        seen[r["id"]] = r
        if len(seen) == 2:
            break
assert seen[17]["name_enUS"] == "Power Word: Shield"
assert seen[17]["dispel"] == 1                     # Magic
assert seen[17]["schoolMask"] == 2                 # Holy
assert seen[10]["name_enUS"] == "Blizzard"
assert seen[10]["schoolMask"] == 16                # Frost

# dump one small table and re-read it - into a directory this test owns, not
# over the committed raw/dbc/SpellDispelType.csv.gz (dump_table already takes
# out_dir; this file was simply not passing it, so a "read-only" reader test
# rewrote a committed dump on every run)
import csv, gzip
p = dbc.dump_table("SpellDispelType", out_dir=_iso.own_dir("dumps"))
with gzip.open(p, "rt", encoding="utf-8", newline="") as fh:
    got = list(csv.DictReader(fh))
assert len(got) == 12
byid = {row["id"]: row for row in got}
assert byid["1"]["name_enUS"] == "Magic" and byid["2"]["name_enUS"] == "Curse"

# string-offset-0 semantics on this build: real content lives at offset 0
# (ChrClasses "Warrior"), and Spell.dbc has a placeholder there that the
# all-zero row id=1 references - faithful decode reports it as-is.
f2 = dbc.DBCFile(config.WORK_DBC_DIR / "ChrClasses.dbc")
warrior = next(r for r in f2.iter_rows() if r[0] == 1)
assert warrior[4] == 0 and f2.string(0) == "Warrior"
for r in dbc.iter_named("Spell"):
    assert r["id"] == 1 and r["name_enUS"] == "UPDATE YOUR CLIENT!"
    break

print("ALL PASS")
