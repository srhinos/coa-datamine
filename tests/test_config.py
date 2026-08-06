import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from tools import config

assert config.CLIENT_DIR.is_dir(), f"client dir missing: {config.CLIENT_DIR}"
assert (config.CLIENT_DIR / "Data").is_dir()
assert config.CONTENT_DIR.is_dir()
assert len(config.MPQ_DIRS) == 2 and all(d.is_dir() for d in config.MPQ_DIRS)
assert "Spell.dbc" in config.WANTED_DBCS and len(config.WANTED_DBCS) == (
    20 + len(config.WANTED_DBCS_V2) + len(config.WANTED_DBCS_V3) + len(config.WANTED_DBCS_V4)
    + len(config.WANTED_DBCS_V5) + len(config.WANTED_DBCS_V6))
assert len(config.WANTED_DBCS_V2) == 53
assert len(config.WANTED_DBCS_V3) == 4
assert len(config.WANTED_DBCS_V4) == 11
assert len(config.WANTED_DBCS_V5) == 12
assert len(set(n.lower() for n in config.WANTED_DBCS_V5)) == 12, "no duplicate names"
assert set(config.WANTED_DBCS_V5) <= set(config.WANTED_DBCS)
# task W4-11: item support tables (coa-sim-handoff/DATAMINE-REQUEST.md Sec 8)
assert len(config.WANTED_DBCS_V6) == 9
assert set(config.WANTED_DBCS_V6) <= set(config.WANTED_DBCS)
config.ensure_dirs()
for d in (config.WORK_DBC_DIR, config.RAW_DBC_DIR, config.RAW_CONTENT_DIR, config.DATA_DIR):
    assert d.is_dir(), d
print("ALL PASS")
