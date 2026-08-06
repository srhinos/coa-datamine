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

# v4 (task W4-9): frozen capture of the external ascension.gg CoA talent-builder
# payload (raw/talents/coa-builder-<slug>.html) + its fetch-provenance sidecar
# (raw/talents/_fetch.json). Owned by tools/fetch_coatalents.py (network step,
# run manually/occasionally - NOT part of the offline build_dataset pipeline);
# tools/build_coatalents.py only ever reads the already-committed capture.
RAW_TALENTS_DIR = RAW_DIR / "talents"

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

# v4 (task W4-2): gt* combat-rating/regen tables (coa-sim-handoff/DATAMINE-REQUEST.md
# Sec 1.1 + Sec 13 item 1). All confirmed extracting there 2026-08-05; re-extracted
# fresh by this task since the client patches independently of that snapshot. The 10
# Sec 1.1 tables plus gtNPCManaCostScaler (attached "in case it helps" per Sec 1.1's
# own note - extracted for completeness, not curated by this task's build_gt.py; see
# .superpowers/sdd/task-w4-2-report.md).
WANTED_DBCS_V4 = [
    "gtCombatRatings.dbc", "gtChanceToMeleeCrit.dbc", "gtChanceToMeleeCritBase.dbc",
    "gtChanceToSpellCrit.dbc", "gtChanceToSpellCritBase.dbc",
    "gtOCTClassCombatRatingScalar.dbc", "gtRegenMPPerSpt.dbc", "gtOCTRegenMP.dbc",
    "gtRegenHPPerSpt.dbc", "gtOCTRegenHP.dbc", "gtNPCManaCostScaler.dbc",
]
WANTED_DBCS += WANTED_DBCS_V4

# v5 (task W4-10): simulation-adjacent spell support tables (coa-sim-handoff/
# DATAMINE-REQUEST.md Sec 9 + Sec 13 items 13/17). All 12 confirmed present in
# the MPQ chain by extract_mpq.extract_all() itself - it raises SystemExit on
# any wanted name missing from every archive, which is this task's "verify
# each actually exists" gate; see .superpowers/sdd/task-w4-10-report.md.
WANTED_DBCS_V5 = [
    "SpellAffect.dbc", "SpellDifficulty.dbc", "SummonProperties.dbc",
    "SpellMissile.dbc", "SpellShapeshiftForm.dbc", "SpellFocusObject.dbc",
    "SpellRank.dbc", "CreatureSpellData.dbc", "GlyphProperties.dbc",
    "GlyphSlot.dbc", "SpellStatSuggestions.dbc", "SpellItemEnchantmentCondition.dbc",
]
WANTED_DBCS += WANTED_DBCS_V5

# v6 (task W4-11): item support tables (coa-sim-handoff/DATAMINE-REQUEST.md Sec 8.1 +
# Sec 13 item 14). Item.dbc is an INDEX not a stat source (id/class/subclass/
# soundOverrideSubclass/material/displayid/inventoryType/sheath, zero stats/ilvl/
# quality) - the sim's primary item source stays an external aowow scrape per Sec 8;
# this pipeline extracts these for completeness, no curation this task beyond
# raw+colinfo (see tools/build_items.py). ItemStat.dbc/ItemSpells.dbc are
# DELIBERATELY excluded from this list - both need bespoke handling (ItemStat's
# 236MB raw body cannot land in raw/dbc/ as one file; see WANTED_DBCS_V7 below and
# dbc.CUSTOM_RAW_DUMP_TABLES).
WANTED_DBCS_V6 = [
    "Item.dbc", "ItemSet.dbc", "SpellItemEnchantment.dbc", "GemProperties.dbc",
    "ScalingStatDistribution.dbc", "ScalingStatValues.dbc", "RandPropPoints.dbc",
    "ItemRandomSuffix.dbc", "ItemRandomProperties.dbc",
]
WANTED_DBCS += WANTED_DBCS_V6

# v7 (task W4-11b): ItemStat.dbc - 1,513,931 rows, 236MB body, hostile as a single
# raw/dbc/ file (see tools/build_items.py's sharded raw/dbc/itemstat/ dumper and
# dbc.CUSTOM_RAW_DUMP_TABLES). Kept in its own wave, separate from WANTED_DBCS_V6,
# because it needs a real keying investigation (DATAMINE-REQUEST.md Sec 8.2 + Sec 4
# trap 8) before any column gets named - unlike V6's index-only tables. Verdict:
# f1=itemId/f2=ownItemLevel PROVEN (item-100248 golden vs itemcache.wdb, see
# tools/dbc.py's ItemStat TABLE_MAPS comment) - both are now named.
WANTED_DBCS_V7 = ["ItemStat.dbc"]
WANTED_DBCS += WANTED_DBCS_V7

# v8 (task W4-11c): ItemSpells.dbc - 131,722 rows x 37 fields. Sec 4 trap 9: f1 is
# NOT the item link (unique per row, only 55% resolves against Item.dbc); only
# f2->spellId is well-supported (99.81% against Spell.dbc's 1.50%-dense id space).
# No item-link column exists in this table at all - same "no grouping identity"
# shape as NPCTrainer (see tools/build_creatures.py's trainerIdFinding).
WANTED_DBCS_V8 = ["ItemSpells.dbc"]
WANTED_DBCS += WANTED_DBCS_V8

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
