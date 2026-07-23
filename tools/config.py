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

def ensure_dirs():
    for d in (WORK_DBC_DIR, RAW_DBC_DIR, RAW_CONTENT_DIR, DATA_DIR):
        d.mkdir(parents=True, exist_ok=True)
