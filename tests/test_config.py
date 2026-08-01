import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from tools import config

assert config.CLIENT_DIR.is_dir(), f"client dir missing: {config.CLIENT_DIR}"
assert (config.CLIENT_DIR / "Data").is_dir()
assert config.CONTENT_DIR.is_dir()
assert len(config.MPQ_DIRS) == 2 and all(d.is_dir() for d in config.MPQ_DIRS)
assert "Spell.dbc" in config.WANTED_DBCS and len(config.WANTED_DBCS) == (
    20 + len(config.WANTED_DBCS_V2) + len(config.WANTED_DBCS_V3))
assert len(config.WANTED_DBCS_V2) == 53
assert len(config.WANTED_DBCS_V3) == 4
config.ensure_dirs()
for d in (config.WORK_DBC_DIR, config.RAW_DBC_DIR, config.RAW_CONTENT_DIR, config.DATA_DIR):
    assert d.is_dir(), d
print("ALL PASS")
