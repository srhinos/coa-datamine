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
RAW_INTERFACE_DIR = RAW_DIR / "interface"
DATA_DIR = REPO_ROOT / "data"

# v3 (task V3-2): realm-overlay layer. work/realms owned by tools/extract_realms.py;
# raw/realms + data/realms owned by tools/build_realms.py (Amendment D single-writer).
WORK_REALMS_DIR = WORK_DIR / "realms"
RAW_REALMS_DIR = RAW_DIR / "realms"
DATA_REALMS_DIR = DATA_DIR / "realms"
_REALM_DIR_EXCLUDE = {"enus", "content"}  # the base client's own locale/content dirs

WANTED_DBCS = [
    "Spell.dbc", "ChrClasses.dbc", "ChrRaces.dbc", "Talent.dbc", "TalentTab.dbc",
    "LFGDungeons.dbc", "DungeonEncounter.dbc", "Map.dbc", "AreaTable.dbc",
    "SkillLine.dbc", "SkillLineAbility.dbc", "SkillRaceClassInfo.dbc",
    "SpellDispelType.dbc", "SpellMechanic.dbc", "SpellDuration.dbc",
    "SpellRange.dbc", "SpellRadius.dbc", "SpellCastTimes.dbc",
    "SpellIcon.dbc", "SpellRuneCost.dbc",
]

# v2: 53 tables from docs/superpowers/specs/2026-07-23-coa-datamine-v2-design.md
# "Verified header facts" (patch-M then patch-S, spec transcription order).
WANTED_DBCS_V2 = [
    # patch-M (41): bosses/quests/trainers (6)
    "Creature.dbc", "DungeonEncounterExtra.dbc", "Quest.dbc", "QuestInfo.dbc",
    "QuestSort.dbc", "NPCTrainer.dbc",
    # patch-M: class metadata (16). NOTE: the spec's "Verified header facts"
    # prose drops the repeated CharacterCreation*/CharacterAdvancement*
    # prefix after the first mention of each family (shorthand in a comma
    # list); the real on-disk names carry the full prefix, confirmed by a
    # live archive listfile scan 2026-07-23 - use the real names here.
    "ChrSpecs.dbc", "ChrClassesRoles.dbc", "CharacterCreationArchetypes.dbc",
    "CharacterCreationArchetypeCategories.dbc", "CharacterCreationArchetypeDetails.dbc",
    "CharacterCreationArchetypeRoles.dbc", "CharacterCreationClassDetails.dbc",
    "CharacterCreationClassGuideRoles.dbc", "CharacterCreationClassGuideSubroleClasses.dbc",
    "CharacterCreationClassGuideSubroles.dbc", "CharacterCreationPetDetails.dbc",
    "CharacterCreationShapeshiftDetails.dbc",
    "CharacterAdvancementCategories.dbc", "CharacterAdvancementClassTypes.dbc",
    "CharacterAdvancementEssence.dbc", "CharacterAdvancementTabTypes.dbc",
    # patch-M: mythic+/challenges (19; ChallengeSpells lives in patch-S below)
    "MythicAffixes.dbc", "MythicKeystones.dbc", "MythicPlusScaling.dbc",
    "TimedDungeons.dbc", "MapDifficulty.dbc", "Challenge.dbc",
    "ChallengeConditionTypes.dbc", "ChallengeConditions.dbc", "ChallengeFeatured.dbc",
    "ChallengeGroupRewards.dbc", "ChallengeGroups.dbc", "ChallengeLevels.dbc",
    "ChallengeModifierTypes.dbc", "ChallengeModifiers.dbc",
    "ChallengeRequirementTypes.dbc", "ChallengeRequirements.dbc",
    "ChallengeRewards.dbc", "ChallengeRuleTypes.dbc", "ChallengeRules.dbc",
    # patch-S (12): spell metadata (11) + ChallengeSpells (1)
    "SpellCharges.dbc", "SpellChargesCategory.dbc", "SpellCustomAttr.dbc",
    "SpellTags.dbc", "SpellTagTypes.dbc", "SpellAlternativeCost.dbc",
    "SpellAlternativePowerType.dbc", "OverrideSpellData.dbc",
    "SpellDescriptionVariables.dbc", "SpellAddon.dbc", "SpellCategory.dbc",
    "ChallengeSpells.dbc",
]
WANTED_DBCS += WANTED_DBCS_V2

# v3 (task V3-1): Manastorm seasonal-modifier system (patch-M, verified headers
# 2026-08-01 per .superpowers/sdd/task-v3-1-brief.md - Manastorm 1017x9,
# ManastormMessages 291x39, ManastormModifiers 32768x15, ManastormPlayerGroupModifiers 15x5).
WANTED_DBCS_V3 = [
    "Manastorm.dbc", "ManastormMessages.dbc", "ManastormModifiers.dbc",
    "ManastormPlayerGroupModifiers.dbc",
]
WANTED_DBCS += WANTED_DBCS_V3

def ensure_dirs():
    for d in (WORK_DBC_DIR, RAW_DBC_DIR, RAW_CONTENT_DIR, DATA_DIR):
        d.mkdir(parents=True, exist_ok=True)


def discover_realms() -> list:
    """Realm-overlay directories = subdirs of Data\\ carrying their own `listarchive`
    file, excluding the base client's own enUS locale dir and Content dir. Generic
    by design (task V3-2): any future realm directory following this shape is picked
    up automatically with no code change; only realms actually present on THIS
    machine's client are returned - off-disk realm data is out of scope by user
    decision. Sorted for determinism."""
    root = CLIENT_DIR / "Data"
    if not root.is_dir():
        return []
    out = []
    for p in sorted(root.iterdir()):
        if (p.is_dir() and p.name.lower() not in _REALM_DIR_EXCLUDE
                and (p / "listarchive").is_file()):
            out.append(p.name)
    return out
