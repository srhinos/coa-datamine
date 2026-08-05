import csv, gzip, json, struct, sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from tools import config, dbc, extract_mpq

assert len(config.WANTED_DBCS_V2) == 53, len(config.WANTED_DBCS_V2)
assert len(set(n.lower() for n in config.WANTED_DBCS_V2)) == 53, "no duplicate names"
assert all(n.endswith(".dbc") for n in config.WANTED_DBCS_V2)
assert set(config.WANTED_DBCS_V2) <= set(config.WANTED_DBCS)

prov = extract_mpq.extract_all()

# spec's exact (records, fields) for at least these tables (2026-07-23 verified header facts)
expected = {
    "Creature.dbc": (127178, 23),
    "Quest.dbc": (18561, 29),
    "NPCTrainer.dbc": (13111, 4),
    "ChrSpecs.dbc": (101, 65),
    "SpellTags.dbc": (488662, 3),
    "Challenge.dbc": (297, 53),
    "SpellAlternativeCost.dbc": (0, 3),
}

for name in config.WANTED_DBCS_V2:
    p = config.WORK_DBC_DIR / name
    assert p.is_file(), f"missing {p}"
    data = p.read_bytes()
    magic, recs, fields, recsize, strsize = struct.unpack_from("<4s4I", data, 0)
    assert magic == b"WDBC", name
    assert len(data) == 20 + recs * recsize + strsize, f"size mismatch {name}"
    if name in expected:
        assert (recs, fields) == expected[name], f"{name}: got ({recs},{fields}) want {expected[name]}"

# Creature.dbc colinfo evidence: a proven-string-likely column with non-empty samples.
# Creature has been a MAPPED table since V2-2 (named header in raw/dbc/Creature.csv.gz) -
# dump into a scratch dir, NOT config.RAW_DBC_DIR, so this verification step doesn't
# clobber the committed mapped dump with the unmapped f0..fN shape.
scratch_dir = config.WORK_DIR / "test_dumps"
p = dbc.dump_unmapped("Creature", out_dir=scratch_dir)
colinfo = json.loads((scratch_dir / "Creature.colinfo.json").read_text(encoding="utf-8"))
assert colinfo["table"] == "Creature"
assert colinfo["records"] == 127178
string_cols = [c for c in colinfo["columns"] if c["string_likelihood"] >= 0.9]
assert len(string_cols) >= 1, colinfo["columns"]
assert all(s for s in string_cols[0]["samples"]), string_cols[0]
assert len(string_cols[0]["samples"]) >= 1

with gzip.open(p, "rt", encoding="utf-8", newline="") as fh:
    rows = list(csv.reader(fh))
assert len(rows) - 1 == 127178, len(rows) - 1   # header + data rows

# SpellAlternativeCost: empty table must not divide by zero. Dump into the same
# scratch dir as Creature above, not config.RAW_DBC_DIR, so this verification step
# doesn't write to (or clobber) committed raw/dbc/ artifacts.
p2 = dbc.dump_unmapped("SpellAlternativeCost", out_dir=scratch_dir)
colinfo2 = json.loads((scratch_dir / "SpellAlternativeCost.colinfo.json").read_text(encoding="utf-8"))
assert colinfo2["records"] == 0
for c in colinfo2["columns"]:
    assert c["string_likelihood"] == 0.0
    assert c["distinct"] == 0
with gzip.open(p2, "rt", encoding="utf-8", newline="") as fh:
    rows2 = list(csv.reader(fh))
assert len(rows2) == 1   # header only, no data rows

print("ALL PASS")
