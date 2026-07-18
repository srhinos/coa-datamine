"""Central paths + the wanted-DBC list for the coa-datamine pipeline."""
import os
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
CLIENT_DIR = Path(os.environ.get("COA_CLIENT_DIR", r"E:\ascension-live"))
MPQ_DIRS = [CLIENT_DIR / "Data", CLIENT_DIR / "Data" / "enUS"]
CONTENT_DIR = CLIENT_DIR / "Data" / "Content"

WORK_DIR = REPO_ROOT / "work"
WORK_DBC_DIR = WORK_DIR / "dbc"
RAW_DIR = REPO_ROOT / "raw"
RAW_DBC_DIR = RAW_DIR / "dbc"
RAW_CONTENT_DIR = RAW_DIR / "content"
DATA_DIR = REPO_ROOT / "data"

WANTED_DBCS = [
    "Spell.dbc", "ChrClasses.dbc", "ChrRaces.dbc", "Talent.dbc", "TalentTab.dbc",
    "LFGDungeons.dbc", "DungeonEncounter.dbc", "Map.dbc", "AreaTable.dbc",
    "SkillLine.dbc", "SkillLineAbility.dbc", "SkillRaceClassInfo.dbc",
    "SpellDispelType.dbc", "SpellMechanic.dbc", "SpellDuration.dbc",
    "SpellRange.dbc", "SpellRadius.dbc", "SpellCastTimes.dbc",
    "SpellIcon.dbc", "SpellRuneCost.dbc",
]

def ensure_dirs():
    for d in (WORK_DBC_DIR, RAW_DBC_DIR, RAW_CONTENT_DIR, DATA_DIR):
        d.mkdir(parents=True, exist_ok=True)
