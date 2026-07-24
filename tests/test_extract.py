import json, struct, sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from tools import config
from tools.extract_mpq import chain_rank, extract_all

D = config.CLIENT_DIR / "Data"
# chain order: base < locale base < patch < patch-digit < locale patch < patch-letters
assert chain_rank(D / "common.MPQ") < chain_rank(D / "enUS" / "locale-enUS.MPQ")
assert chain_rank(D / "enUS" / "locale-enUS.MPQ") < chain_rank(D / "patch.MPQ")
assert chain_rank(D / "patch.MPQ") < chain_rank(D / "patch-2.MPQ")
assert chain_rank(D / "patch-2.MPQ") < chain_rank(D / "enUS" / "patch-enUS-2.MPQ")
assert chain_rank(D / "enUS" / "patch-enUS.MPQ") < chain_rank(D / "enUS" / "patch-enUS-2.MPQ")
assert chain_rank(D / "enUS" / "patch-enUS-2.MPQ") < chain_rank(D / "enUS" / "patch-enUS-10.MPQ")
assert chain_rank(D / "enUS" / "patch-enUS-2.MPQ") < chain_rank(D / "patch-A.MPQ")
assert chain_rank(D / "patch-CH.MPQ") < chain_rank(D / "patch-CHA.MPQ")
assert chain_rank(D / "patch-CHA.MPQ") < chain_rank(D / "patch-CI.MPQ")
assert chain_rank(D / "patch-T.MPQ") > chain_rank(D / "patch-S.MPQ")

prov = extract_all()
assert set(prov["files"]) == {w.lower() for w in config.WANTED_DBCS}, "all wanted DBCs resolved"
for name in config.WANTED_DBCS:
    p = config.WORK_DBC_DIR / name
    assert p.is_file(), f"missing {p}"
    magic, recs, fields, recsize, strsize = struct.unpack("<4s4I", p.read_bytes()[:20])
    assert magic == b"WDBC", name
    assert p.stat().st_size == 20 + recs * recsize + strsize, f"size mismatch {name}"

spell = prov["files"]["spell.dbc"]
assert spell["winner"].lower() == "patch-t.mpq", spell
assert struct.unpack("<4s4I", (config.WORK_DBC_DIR / "Spell.dbc").read_bytes()[:20])[2] == 234
assert isinstance(prov["skipped_archives"], list)
saved = json.loads((config.WORK_DIR / "extract_provenance.json").read_text(encoding="utf-8"))
assert saved["files"]["spell.dbc"]["winner"] == spell["winner"]
print("ALL PASS")
