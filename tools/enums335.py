"""3.3.5 enum name tables. Partial by design: unmapped ids render as
EFFECT_<n>/AURA_<n>/TARGET_<n> - the id is always authoritative, the label is sugar.

Task W4-1 (enum truth pass): re-derived against coa-sim-handoff/analysis/enum-triage.md
+ work/dbc/Spell.dbc BASE (209,125 rows). Every id below - both the 4 repo-bug fixes and
every new canonical/COA_ addition - was independently decoded from a cited golden spell
by this task, not pasted from the source doc on trust; see
.superpowers/sdd/task-w4-1-report.md for the full per-golden verification log.

Lookup order (effect_name/aura_name): canonical table -> COA_ overlay -> numeric
fallback (EFFECT_<n>/AURA_<n>). The overlay is kept separate from the canonical tables
so a custom Ascension mechanic (COA_*) is never confused with a genuine 3.3.5a name,
and so a decode failure (bare EFFECT_<n>/AURA_<n>) stays visibly distinct from both."""

DISPEL_NAMES = {
    0: "None", 1: "Magic", 2: "Curse", 3: "Disease", 4: "Poison", 5: "Stealth",
    6: "Invisibility", 7: "All", 8: "SpecialNPCOnly", 9: "Enrage", 10: "ZGTicket",
}

SCHOOL_MASK_NAMES = {
    0x01: "Physical", 0x02: "Holy", 0x04: "Fire", 0x08: "Nature",
    0x10: "Frost", 0x20: "Shadow", 0x40: "Arcane",
}

def school_names(mask):
    return [n for b, n in SCHOOL_MASK_NAMES.items() if mask & b]

POWER_TYPES = {
    -2: "Health", 0: "Mana", 1: "Rage", 2: "Focus", 3: "Energy",
    4: "Happiness", 5: "Rune", 6: "RunicPower",
}

DMG_CLASS_NAMES = {0: "None", 1: "Magic", 2: "Melee", 3: "Ranged"}
PREVENTION_NAMES = {0: "None", 1: "Silence", 2: "Pacify"}
INSTANCE_TYPES = {0: "World", 1: "Dungeon", 2: "Raid", 3: "Battleground", 4: "Arena"}
LFG_TYPES = {1: "Dungeon", 2: "Raid", 4: "Zone", 5: "Heroic", 6: "Random"}

EFFECT_NAMES = {
    0: "NONE", 1: "INSTAKILL", 2: "SCHOOL_DAMAGE", 3: "DUMMY", 5: "TELEPORT_UNITS",
    6: "APPLY_AURA", 7: "ENVIRONMENTAL_DAMAGE", 8: "POWER_DRAIN", 9: "HEALTH_LEECH",
    10: "HEAL", 16: "QUEST_COMPLETE", 17: "WEAPON_DAMAGE_NOSCHOOL", 18: "RESURRECT",
    19: "ADD_EXTRA_ATTACKS", 24: "CREATE_ITEM", 27: "PERSISTENT_AREA_AURA",
    28: "SUMMON", 29: "LEAP", 30: "ENERGIZE", 31: "WEAPON_PERCENT_DAMAGE",
    32: "TRIGGER_MISSILE", 33: "OPEN_LOCK", 35: "APPLY_AREA_AURA_PARTY",
    36: "LEARN_SPELL", 38: "DISPEL", 40: "DUAL_WIELD", 44: "SKILL_STEP",
    48: "STEALTH", 53: "ENCHANT_ITEM", 54: "ENCHANT_ITEM_TEMPORARY",
    56: "SUMMON_PET", 58: "WEAPON_DAMAGE", 62: "POWER_BURN", 63: "THREAT",
    64: "TRIGGER_SPELL", 65: "APPLY_AREA_AURA_RAID", 67: "HEAL_MAX_HEALTH",
    68: "INTERRUPT_CAST", 75: "HEAL_MECHANICAL", 77: "SCRIPT_EFFECT",
    80: "ADD_COMBO_POINTS", 91: "THREAT_ALL", 96: "CHARGE", 98: "KNOCK_BACK",
    101: "FEED_PET", 102: "DISMISS_PET",
    # [W4-1 bug fix] was "DISPEL_MECHANIC" - wrong. Golden 36936 Totemic Recall,
    # 16529 Destroy Totems (PT): both decode effect=110 on a totem-destroying slot.
    # See 108 below for the mechanic this id displaced.
    110: "DESTROY_ALL_TOTEMS",
    113: "RESURRECT_NEW", 121: "NORMALIZED_WEAPON_DMG",
    126: "STEAL_BENEFICIAL_BUFF", 135: "CALL_PET", 136: "HEAL_PCT",
    137: "ENERGIZE_PCT", 138: "LEAP_BACK",
    # [W4-1 bug fix] was "FORCE_CAST" - wrong (that's 140, added below). Golden
    # 33076/33203/33204/33205 Prayer of Mending: effect=142, bp scales 100/190/270/380
    # with rank and triggerSpell=41635 (the heal-propagation script) - "value" is the
    # accumulated heal passed to the trigger, matching TRIGGER_SPELL_WITH_VALUE, not
    # a plain forced cast.
    142: "TRIGGER_SPELL_WITH_VALUE",
    151: "TRIGGER_SPELL_2",
    # --- W4-1: verified bucket-A additions (standard 3.3.5a, repo just missing the
    # name). Each id below was independently decoded from a golden spell against
    # work/dbc/Spell.dbc BASE, not pasted from enum-triage.md on trust; see
    # .superpowers/sdd/task-w4-1-report.md for the full log. The other 35 of the 44
    # bucket-A effect ids in enum-triage.md have no individually-cited golden and are
    # left numeric (EFFECT_<n>) per this task's binding rule.
    108: "DISPEL_MECHANIC",  # golden 1604 Dazed, 8146 Tremor Totem Effect, 11641 Hex
    114: "ATTACK_ME",        # golden 355 Taunt, 6795 Growl
    128: "APPLY_AREA_AURA_FRIEND",  # golden 31634 Strength of Earth Totem
    129: "APPLY_AREA_AURA_ENEMY",   # golden 30708 Totem of Wrath (real WotLK quirk)
    140: "FORCE_CAST",              # golden 17607 Portal Effect: Ironforge
    141: "FORCE_CAST_WITH_VALUE",   # golden 41065 Bloodbolt (bp=3237, trig=41067)
    148: "TRIGGER_MISSILE_SPELL_WITH_VALUE",  # golden 43509 Orb of Fire (trig=43510)
    149: "CHARGE_DEST",             # golden 44357 Charge
    164: "REMOVE_AURA",             # golden 16193 Nature's Swiftness removal
}

AURA_NAMES = {
    0: "NONE", 3: "PERIODIC_DAMAGE", 4: "DUMMY", 5: "MOD_CONFUSE", 6: "MOD_CHARM",
    7: "MOD_FEAR", 8: "PERIODIC_HEAL", 9: "MOD_ATTACKSPEED", 10: "MOD_THREAT",
    11: "MOD_TAUNT", 12: "MOD_STUN", 13: "MOD_DAMAGE_DONE", 14: "MOD_DAMAGE_TAKEN",
    15: "DAMAGE_SHIELD", 16: "MOD_STEALTH", 18: "MOD_INVISIBILITY",
    20: "OBS_MOD_HEALTH", 21: "OBS_MOD_POWER", 22: "MOD_RESISTANCE",
    23: "PERIODIC_TRIGGER_SPELL", 24: "PERIODIC_ENERGIZE", 25: "MOD_PACIFY",
    26: "MOD_ROOT", 27: "MOD_SILENCE", 28: "REFLECT_SPELLS", 29: "MOD_STAT",
    30: "MOD_SKILL", 31: "MOD_INCREASE_SPEED", 33: "MOD_DECREASE_SPEED",
    34: "MOD_INCREASE_HEALTH", 35: "MOD_INCREASE_ENERGY", 36: "MOD_SHAPESHIFT",
    37: "EFFECT_IMMUNITY", 38: "STATE_IMMUNITY", 39: "SCHOOL_IMMUNITY",
    40: "DAMAGE_IMMUNITY", 41: "DISPEL_IMMUNITY", 42: "PROC_TRIGGER_SPELL",
    43: "PROC_TRIGGER_DAMAGE", 47: "MOD_PARRY_PERCENT", 49: "MOD_DODGE_PERCENT",
    51: "MOD_BLOCK_PERCENT",
    52: "MOD_WEAPON_CRIT_PERCENT",  # [W4-1 bug fix] was "MOD_CRIT_PERCENT" - cosmetic
    53: "PERIODIC_LEECH",
    54: "MOD_HIT_CHANCE", 55: "MOD_SPELL_HIT_CHANCE", 56: "TRANSFORM",
    57: "MOD_SPELL_CRIT_CHANCE", 60: "MOD_PACIFY_SILENCE", 61: "MOD_SCALE",
    64: "PERIODIC_MANA_LEECH", 65: "MOD_CASTING_SPEED_NOT_STACK",
    66: "FEIGN_DEATH", 67: "MOD_DISARM", 69: "SCHOOL_ABSORB",
    72: "MOD_POWER_COST_SCHOOL_PCT", 73: "MOD_POWER_COST_SCHOOL",
    74: "REFLECT_SPELLS_SCHOOL", 77: "MECHANIC_IMMUNITY", 78: "MOUNTED",
    79: "MOD_DAMAGE_PERCENT_DONE", 80: "MOD_PERCENT_STAT", 81: "SPLIT_DAMAGE_PCT",
    82: "WATER_BREATHING", 84: "MOD_REGEN", 85: "MOD_POWER_REGEN",
    87: "MOD_DAMAGE_PERCENT_TAKEN", 89: "PERIODIC_DAMAGE_PERCENT",
    94: "INTERRUPT_REGEN", 95: "GHOST", 97: "MANA_SHIELD",
    99: "MOD_ATTACK_POWER", 101: "MOD_RESISTANCE_PCT", 103: "MOD_TOTAL_THREAT",
    104: "WATER_WALK", 105: "FEATHER_FALL", 106: "HOVER",
    107: "ADD_FLAT_MODIFIER", 108: "ADD_PCT_MODIFIER", 109: "ADD_TARGET_TRIGGER",
    110: "MOD_POWER_REGEN_PERCENT", 123: "MOD_TARGET_RESISTANCE",
    124: "MOD_RANGED_ATTACK_POWER", 132: "MOD_INCREASE_ENERGY_PERCENT",
    133: "MOD_INCREASE_HEALTH_PERCENT", 134: "MOD_MANA_REGEN_INTERRUPT",
    135: "MOD_HEALING_DONE", 136: "MOD_HEALING_DONE_PERCENT",
    137: "MOD_TOTAL_STAT_PERCENTAGE", 138: "MOD_MELEE_HASTE",
    140: "MOD_RANGED_HASTE", 142: "MOD_BASE_RESISTANCE_PCT",
    143: "MOD_RESISTANCE_EXCLUSIVE", 144: "SAFE_FALL", 154: "MOD_STEALTH_LEVEL",
    189: "MOD_RATING",
    200: "MOD_XP_PCT",  # [W4-1 bug fix] was "MOD_KILL_XP_PCT" - cosmetic
    226: "PERIODIC_DUMMY",
    228: "DETECT_STEALTH", 231: "PROC_TRIGGER_SPELL_WITH_VALUE",
    # --- W4-1: verified bucket-A additions (standard 3.3.5a, repo just missing the
    # name). Each id below was independently decoded from a golden spell against
    # work/dbc/Spell.dbc BASE; see .superpowers/sdd/task-w4-1-report.md. The other
    # 106 of the 129 bucket-A aura ids in enum-triage.md have no individually-cited
    # golden and are left numeric (AURA_<n>) per this task's binding rule.
    # [W4-1 review fix] found hiding in enum-triage.md's bucket-B prose (the EFF190
    # discussion), not its own table - golden 300240 Curse of the Lich slot2/3,
    # aura=71 misc=16=Frost, tooltip "increases the Frost critical strike chance of
    # you and your summons".
    71: "MOD_SPELL_CRIT_CHANCE_SCHOOL",
    112: "OVERRIDE_CLASS_SCRIPTS",       # golden 11170 Shatter, misc=913
    118: "MOD_HEALING_PCT",              # golden 12294 Mortal Strike slot1, val -50%
    149: "REDUCE_PUSHBACK",              # golden 11083 Burning Soul, val=35 (exact)
    163: "MOD_CRIT_DAMAGE_BONUS",        # golden 10041 QA Test +100% Crit Damage
    166: "MOD_ATTACK_POWER_PCT",         # golden 9199 "Attack Power %"
    174: "MOD_SPELL_DAMAGE_OF_STAT_PERCENT",   # golden 14901-15031 Spiritual Guidance
    175: "MOD_SPELL_HEALING_OF_STAT_PERCENT",  # golden 14901-15031 Spiritual Guidance
    192: "MOD_MELEE_RANGED_HASTE",       # golden 2825 Bloodlust slot3, val=30% (exact)
    212: "MOD_RANGED_ATTACK_POWER_OF_STAT_PERCENT",  # golden 34501 Expose Weakness
    216: "HASTE_SPELLS",                 # golden 1714 Curse of Tongues
    220: "MOD_RATING_FROM_STAT",         # golden 21853 Tier 2 Priest 5pc set
    227: "PERIODIC_TRIGGER_SPELL_WITH_VALUE",  # golden 15407 Mind Flay slot3
    232: "MECHANIC_DURATION_MOD",        # golden 12300 Iron Will, 9453 Unyielding Faith
    240: "MOD_EXPERTISE",                # golden 10024 QA Test 100% Expertise
    268: "MOD_ATTACK_POWER_OF_STAT_PERCENT",  # golden 34501 Expose Weakness
    271: "MOD_DAMAGE_FROM_CASTER",       # golden 17364 Stormstrike, val=20 misc=8
    280: "MOD_ARMOR_PENETRATION_PCT",    # golden 2457 Battle Stance, 12308 Puncture
    285: "MOD_ATTACK_POWER_OF_ARMOR",    # golden 48978 Bladed Armor
    286: "ABILITY_PERIODIC_CRIT",        # golden 58435 Pandemic, 63503 Primal Gore
    290: "MOD_CRIT_PCT",                 # golden 14138/14139/14140 Malice r1-3
    303: "MOD_DAMAGE_DONE_VERSUS_AURASTATE",  # golden 16858 Feral Aggression misc=23
    308: "MOD_CRIT_CHANCE_FOR_CASTER",   # golden 23552 Lightning Shield slot2
}

# --- W4-1: Ascension-custom overlay (id >= 165 for effects / >= 317 for auras cannot
# be canonical 3.3.5a - TOTAL_SPELL_EFFECTS=165, TOTAL_AURAS=317). Kept SEPARATE from
# EFFECT_NAMES/AURA_NAMES so a custom mechanic is never mistaken for a genuine 3.3.5a
# one, and so effect_name()/aura_name() can report a decode failure (EFFECT_<n>/
# AURA_<n>) as visibly distinct from both a canonical and a COA_ name. Every entry
# below was independently decoded from a cited golden spell against work/dbc/Spell.dbc
# BASE by this task; see .superpowers/sdd/task-w4-1-report.md.
COA_EFFECT_NAMES = {
    165: "COA_MODIFY_COOLDOWN",       # misc=spellId, value=deltaMs; golden 270151
                                       # "Blink CDR" misc=1953=Blink val=-10000 (exact)
    169: "COA_SPREAD_AURA",           # trig=aura to copy; golden 281493 "Pestilence
                                       # Prolif" trig=172=Corruption
    170: "COA_SPREAD_AURA",           # misc-variant pairing with 169; golden 283989
                                       # "Bloodletting Rend Spread" trig=772=Rend (0
                                       # occurrences in the current referenced closure -
                                       # verified directly against BASE, not reachable
                                       # from any CAD/rank/talent/trigger chain today)
    173: "COA_REFRESH_AURA",          # misc=spellId; golden 47422 Everlasting
                                       # Affliction misc=172=Corruption
    175: "COA_MODIFY_AURA_STACKS",    # trig=aura, misc=delta; golden 300177 "Lose 5
                                       # Insanity" misc=-5 trig=500706 (exact)
    176: "COA_MODIFY_AURA_STACKS_2",  # misc=aura spellId, bp=delta; golden 92763
                                       # "Spirit Frost Consume 2 Stacks" bp=-2 misc=92753
    177: "COA_MODIFY_AURA_DURATION",  # misc=spellId, value=deltaMs; golden 271752
                                       # "Locust Cascade" val=2000 misc=5570=Insect Swarm
    183: "COA_TRIGGER_SPELL_DELAYED", # delay=bp+1, trig=spell; golden 92709 Summon
                                       # Arcane Orbs - 3 slots, 2001/4001/6001ms (exact)
    184: "COA_TRIGGER_RANDOM_SPELL",  # golden 278095 "Fire Arsenal randomizer"
    187: "COA_RESTORE_SPELL_CHARGES", # misc=SpellChargesCategory id; client-wide
                                       # 110/118=93.2% of miscValues resolve against
                                       # data/spells/charges.json categories (exact
                                       # match to the source doc's cited rate); golden
                                       # 283146 "Everliving adds 1 Charge" misc=62
    190: "COA_APPLY_AURA_TO_SUMMONS", # golden 300240 Curse of the Lich (aura=71
                                       # misc=16=Frost), 300748 Hulking Hordes (aura=133)
    195: "COA_RESET_COOLDOWN",        # misc=spellId; golden 290199 "Precision Impact
                                       # Meteor CDR", 300368 Moment of Triumph
    # 168 deliberately absent - see EFFECT_168_NOTE below. Do not add a name here
    # without a real golden: SpellTags.dbc cross-reference was tried and rejected
    # (0/1,228 rows resolve to the carrying spell - the dense-id false-positive class
    # this repo has been burned by before).
}
EFFECT_168_NOTE = (
    "EFFECT_168: left intentionally numeric. miscValue is an opaque 852-distinct "
    "token clustered 110k-129k, shared across unrelated spells (Raise: Ghoul / "
    "Abomination / Colossus / Graveyard all misc=117151). SpellTags.dbc cross-"
    "reference tested and rejected (0/1,228 rows resolve to the carrying spell - the "
    "dense-id false-positive class documented elsewhere in this repo). Do not guess."
)

COA_AURA_NAMES = {
    317: "COA_MOD_ABSORB_AND_HEAL_RECEIVED_PCT",  # golden 705128 Impenetrable Wards,
                                                   # 60448 Shadow Embrace (negative)
    319: "COA_MOD_HEALING_RECEIVED_PCT",          # golden 74410 Dampening
    327: "COA_MOD_STAT_FROM_STAT",                # golden 92132 Moon Guard, misc=3
                                                   # (Strength) exact match
    328: "COA_MOD_MAX_MANA_FROM_STAT",            # golden 300351 Ancient Rites
    330: "COA_MOD_CRIT_CHANCE_AGAINST_TARGET",    # golden 16454 Searing Blast,
                                                   # 503298 Bane
    333: "COA_MOD_HIT_CHANCE_ALL_PCT",            # golden 12814 Sword Specialization,
                                                   # val=4 (exact)
    336: "COA_BLOCK_TARGETING_IN_AREA",           # golden 805756 Smoke Grenade,
                                                   # val=0 (exact, matches "all 0")
    338: "COA_MOD_IGNORE_ARMOR_PCT",              # golden 15280 Cleave Armor
    344: "COA_MOD_ATTACK_POWER_FLAT",             # golden 1160 Demoralizing Shout,
                                                   # val=-35 (exact)
    345: "COA_MOD_SPELL_POWER_FLAT",              # golden 1459-1461 Arcane Intellect
                                                   # slot2, val=2/7/15 (exact)
    347: "COA_NEXT_CAST_ATTACH_TRIGGER",          # golden 805306 Rejuvenating Gadget
                                                   # trig=706255
    354: "COA_SCRIPTED_PASSIVE_WITH_VALUE",       # golden 300557 Dread val=25 (exact)
                                                   # trig=300558, 500283 Harvester val=15
                                                   # (exact) trig=504565
    360: "COA_MOD_HEALING_DONE_VERSUS_AURASTATE", # golden 300343 Savior, misc=2
                                                   # (exact match)
}

# --- W4-1: full bucket classification for the _enum_evidence.json sidecar
# (data/spells/_enum_evidence.json, written by tools/build_spells.py). Every
# entry's bucket/name/goldenSpells is fixed research knowledge from this task;
# build_spells.py combines it with LIVE occurrence counts (trap-1 aura-slot-
# gating + trap-2 inert-slot-filtering) computed fresh at build time. Entries
# with confidence 'verified' were independently golden-decoded by this task;
# 'undocumented' entries are bucket-classified per enum-triage.md's aggregate
# analysis only (no individually-cited golden survived re-derivation) and are
# NOT wired into EFFECT_NAMES/AURA_NAMES/COA_*_NAMES - name stays null.
ENUM_EVIDENCE = {
    "effects": {
        22: {"bucket": "A", "name": None, "goldenSpells": [], "confidence": "undocumented"},
        23: {"bucket": "A", "name": None, "goldenSpells": [], "confidence": "undocumented"},
        25: {"bucket": "A", "name": None, "goldenSpells": [], "confidence": "undocumented"},
        26: {"bucket": "A", "name": None, "goldenSpells": [], "confidence": "undocumented"},
        42: {"bucket": "A", "name": None, "goldenSpells": [], "confidence": "undocumented"},
        43: {"bucket": "A", "name": None, "goldenSpells": [], "confidence": "undocumented"},
        47: {"bucket": "A", "name": None, "goldenSpells": [], "confidence": "undocumented"},
        50: {"bucket": "A", "name": None, "goldenSpells": [], "confidence": "undocumented"},
        55: {"bucket": "A", "name": None, "goldenSpells": [], "confidence": "undocumented"},
        59: {"bucket": "A", "name": None, "goldenSpells": [], "confidence": "undocumented"},
        60: {"bucket": "A", "name": None, "goldenSpells": [], "confidence": "undocumented"},
        69: {"bucket": "A", "name": None, "goldenSpells": [], "confidence": "undocumented"},
        71: {"bucket": "A", "name": None, "goldenSpells": [], "confidence": "undocumented"},
        72: {"bucket": "A", "name": None, "goldenSpells": [], "confidence": "undocumented"},
        79: {"bucket": "A", "name": None, "goldenSpells": [], "confidence": "undocumented"},
        85: {"bucket": "A", "name": None, "goldenSpells": [], "confidence": "undocumented"},
        90: {"bucket": "A", "name": None, "goldenSpells": [], "confidence": "undocumented"},
        93: {"bucket": "A", "name": None, "goldenSpells": [], "confidence": "undocumented"},
        94: {"bucket": "A", "name": None, "goldenSpells": [], "confidence": "undocumented"},
        97: {"bucket": "A", "name": None, "goldenSpells": [], "confidence": "undocumented"},
        104: {"bucket": "A", "name": None, "goldenSpells": [], "confidence": "undocumented"},
        105: {"bucket": "A", "name": None, "goldenSpells": [], "confidence": "undocumented"},
        106: {"bucket": "A", "name": None, "goldenSpells": [], "confidence": "undocumented"},
        108: {"bucket": "A", "name": 'DISPEL_MECHANIC', "goldenSpells": [1604, 8146, 11641], "confidence": "verified"},
        109: {"bucket": "A", "name": None, "goldenSpells": [], "confidence": "undocumented"},
        114: {"bucket": "A", "name": 'ATTACK_ME', "goldenSpells": [355, 6795], "confidence": "verified"},
        118: {"bucket": "A", "name": None, "goldenSpells": [], "confidence": "undocumented"},
        119: {"bucket": "A", "name": None, "goldenSpells": [], "confidence": "undocumented"},
        124: {"bucket": "A", "name": None, "goldenSpells": [], "confidence": "undocumented"},
        125: {"bucket": "A", "name": None, "goldenSpells": [], "confidence": "undocumented"},
        128: {"bucket": "A", "name": 'APPLY_AREA_AURA_FRIEND', "goldenSpells": [31634], "confidence": "verified"},
        129: {"bucket": "A", "name": 'APPLY_AREA_AURA_ENEMY', "goldenSpells": [30708], "confidence": "verified"},
        130: {"bucket": "A", "name": None, "goldenSpells": [], "confidence": "undocumented"},
        131: {"bucket": "A", "name": None, "goldenSpells": [], "confidence": "undocumented"},
        140: {"bucket": "A", "name": 'FORCE_CAST', "goldenSpells": [17607, 7853], "confidence": "verified"},
        141: {"bucket": "A", "name": 'FORCE_CAST_WITH_VALUE', "goldenSpells": [41065], "confidence": "verified"},
        143: {"bucket": "A", "name": None, "goldenSpells": [], "confidence": "undocumented"},
        144: {"bucket": "A", "name": None, "goldenSpells": [], "confidence": "undocumented"},
        145: {"bucket": "A", "name": None, "goldenSpells": [], "confidence": "undocumented"},
        146: {"bucket": "A", "name": None, "goldenSpells": [], "confidence": "undocumented"},
        148: {"bucket": "A", "name": 'TRIGGER_MISSILE_SPELL_WITH_VALUE', "goldenSpells": [43509], "confidence": "verified"},
        149: {"bucket": "A", "name": 'CHARGE_DEST', "goldenSpells": [44357], "confidence": "verified"},
        155: {"bucket": "A", "name": None, "goldenSpells": [], "confidence": "undocumented"},
        164: {"bucket": "A", "name": 'REMOVE_AURA', "goldenSpells": [16193], "confidence": "verified"},
        165: {"bucket": "B", "name": 'COA_MODIFY_COOLDOWN', "goldenSpells": [270151], "confidence": "verified"},
        166: {"bucket": "B", "name": None, "goldenSpells": [], "confidence": "undocumented"},
        168: {"bucket": "B", "name": None, "goldenSpells": [], "confidence": "unresolved"},
        169: {"bucket": "B", "name": 'COA_SPREAD_AURA', "goldenSpells": [281493], "confidence": "verified"},
        170: {"bucket": "B", "name": 'COA_SPREAD_AURA', "goldenSpells": [283989], "confidence": "verified"},
        171: {"bucket": "B", "name": None, "goldenSpells": [], "confidence": "undocumented"},
        173: {"bucket": "B", "name": 'COA_REFRESH_AURA', "goldenSpells": [47422], "confidence": "verified"},
        174: {"bucket": "B", "name": None, "goldenSpells": [], "confidence": "undocumented"},
        175: {"bucket": "B", "name": 'COA_MODIFY_AURA_STACKS', "goldenSpells": [300177, 300900], "confidence": "verified"},
        176: {"bucket": "B", "name": 'COA_MODIFY_AURA_STACKS_2', "goldenSpells": [92763], "confidence": "verified"},
        177: {"bucket": "B", "name": 'COA_MODIFY_AURA_DURATION', "goldenSpells": [271752], "confidence": "verified"},
        178: {"bucket": "B", "name": None, "goldenSpells": [], "confidence": "undocumented"},
        181: {"bucket": "B", "name": None, "goldenSpells": [], "confidence": "undocumented"},
        183: {"bucket": "B", "name": 'COA_TRIGGER_SPELL_DELAYED', "goldenSpells": [92709], "confidence": "verified"},
        184: {"bucket": "B", "name": 'COA_TRIGGER_RANDOM_SPELL', "goldenSpells": [278095], "confidence": "verified"},
        187: {"bucket": "B", "name": 'COA_RESTORE_SPELL_CHARGES', "goldenSpells": [283146, 284871], "confidence": "verified"},
        190: {"bucket": "B", "name": 'COA_APPLY_AURA_TO_SUMMONS', "goldenSpells": [300240, 300748], "confidence": "verified"},
        192: {"bucket": "B", "name": None, "goldenSpells": [], "confidence": "undocumented"},
        193: {"bucket": "B", "name": None, "goldenSpells": [], "confidence": "undocumented"},
        195: {"bucket": "B", "name": 'COA_RESET_COOLDOWN', "goldenSpells": [290199, 300368], "confidence": "verified"},
        197: {"bucket": "B", "name": None, "goldenSpells": [], "confidence": "undocumented"},
        198: {"bucket": "B", "name": None, "goldenSpells": [], "confidence": "undocumented"},
    },
    "auras": {
        1: {"bucket": "A", "name": None, "goldenSpells": [], "confidence": "undocumented"},
        2: {"bucket": "A", "name": None, "goldenSpells": [], "confidence": "undocumented"},
        17: {"bucket": "A", "name": None, "goldenSpells": [], "confidence": "undocumented"},
        19: {"bucket": "A", "name": None, "goldenSpells": [], "confidence": "undocumented"},
        32: {"bucket": "A", "name": None, "goldenSpells": [], "confidence": "undocumented"},
        44: {"bucket": "A", "name": None, "goldenSpells": [], "confidence": "undocumented"},
        45: {"bucket": "A", "name": None, "goldenSpells": [], "confidence": "undocumented"},
        50: {"bucket": "A", "name": None, "goldenSpells": [], "confidence": "undocumented"},
        58: {"bucket": "A", "name": None, "goldenSpells": [], "confidence": "undocumented"},
        59: {"bucket": "A", "name": None, "goldenSpells": [], "confidence": "undocumented"},
        68: {"bucket": "A", "name": None, "goldenSpells": [], "confidence": "undocumented"},
        71: {"bucket": "A", "name": "MOD_SPELL_CRIT_CHANCE_SCHOOL", "goldenSpells": [300240], "confidence": "verified"},
        75: {"bucket": "A", "name": None, "goldenSpells": [], "confidence": "undocumented"},
        83: {"bucket": "A", "name": None, "goldenSpells": [], "confidence": "undocumented"},
        86: {"bucket": "A", "name": None, "goldenSpells": [], "confidence": "undocumented"},
        88: {"bucket": "A", "name": None, "goldenSpells": [], "confidence": "undocumented"},
        91: {"bucket": "A", "name": None, "goldenSpells": [], "confidence": "undocumented"},
        92: {"bucket": "A", "name": None, "goldenSpells": [], "confidence": "undocumented"},
        93: {"bucket": "A", "name": None, "goldenSpells": [], "confidence": "undocumented"},
        98: {"bucket": "A", "name": None, "goldenSpells": [], "confidence": "undocumented"},
        102: {"bucket": "A", "name": None, "goldenSpells": [], "confidence": "undocumented"},
        111: {"bucket": "A", "name": None, "goldenSpells": [], "confidence": "undocumented"},
        112: {"bucket": "A", "name": 'OVERRIDE_CLASS_SCRIPTS', "goldenSpells": [11170], "confidence": "verified"},
        114: {"bucket": "A", "name": None, "goldenSpells": [], "confidence": "undocumented"},
        115: {"bucket": "A", "name": None, "goldenSpells": [], "confidence": "undocumented"},
        117: {"bucket": "A", "name": None, "goldenSpells": [], "confidence": "undocumented"},
        118: {"bucket": "A", "name": 'MOD_HEALING_PCT', "goldenSpells": [12294], "confidence": "verified"},
        120: {"bucket": "A", "name": None, "goldenSpells": [], "confidence": "undocumented"},
        122: {"bucket": "A", "name": None, "goldenSpells": [], "confidence": "undocumented"},
        127: {"bucket": "A", "name": None, "goldenSpells": [], "confidence": "undocumented"},
        128: {"bucket": "A", "name": None, "goldenSpells": [], "confidence": "undocumented"},
        145: {"bucket": "A", "name": None, "goldenSpells": [], "confidence": "undocumented"},
        146: {"bucket": "A", "name": None, "goldenSpells": [], "confidence": "undocumented"},
        147: {"bucket": "A", "name": None, "goldenSpells": [], "confidence": "undocumented"},
        148: {"bucket": "A", "name": None, "goldenSpells": [], "confidence": "undocumented"},
        149: {"bucket": "A", "name": 'REDUCE_PUSHBACK', "goldenSpells": [11083], "confidence": "verified"},
        150: {"bucket": "A", "name": None, "goldenSpells": [], "confidence": "undocumented"},
        151: {"bucket": "A", "name": None, "goldenSpells": [], "confidence": "undocumented"},
        152: {"bucket": "A", "name": None, "goldenSpells": [], "confidence": "undocumented"},
        156: {"bucket": "A", "name": None, "goldenSpells": [], "confidence": "undocumented"},
        158: {"bucket": "A", "name": None, "goldenSpells": [], "confidence": "undocumented"},
        163: {"bucket": "A", "name": 'MOD_CRIT_DAMAGE_BONUS', "goldenSpells": [10041], "confidence": "verified"},
        164: {"bucket": "unknown", "name": None, "goldenSpells": [803451], "confidence": "unclassified"},
        166: {"bucket": "A", "name": 'MOD_ATTACK_POWER_PCT', "goldenSpells": [9199], "confidence": "verified"},
        167: {"bucket": "A", "name": None, "goldenSpells": [], "confidence": "undocumented"},
        168: {"bucket": "A", "name": None, "goldenSpells": [], "confidence": "undocumented"},
        169: {"bucket": "A", "name": None, "goldenSpells": [], "confidence": "undocumented"},
        171: {"bucket": "A", "name": None, "goldenSpells": [], "confidence": "undocumented"},
        172: {"bucket": "A", "name": None, "goldenSpells": [], "confidence": "undocumented"},
        174: {"bucket": "A", "name": 'MOD_SPELL_DAMAGE_OF_STAT_PERCENT', "goldenSpells": [14901, 15031], "confidence": "verified"},
        175: {"bucket": "A", "name": 'MOD_SPELL_HEALING_OF_STAT_PERCENT', "goldenSpells": [14901, 15031], "confidence": "verified"},
        178: {"bucket": "A", "name": None, "goldenSpells": [], "confidence": "undocumented"},
        179: {"bucket": "A", "name": None, "goldenSpells": [], "confidence": "undocumented"},
        182: {"bucket": "A", "name": None, "goldenSpells": [], "confidence": "undocumented"},
        184: {"bucket": "A", "name": None, "goldenSpells": [], "confidence": "undocumented"},
        185: {"bucket": "A", "name": None, "goldenSpells": [], "confidence": "undocumented"},
        186: {"bucket": "A", "name": None, "goldenSpells": [], "confidence": "undocumented"},
        187: {"bucket": "A", "name": None, "goldenSpells": [], "confidence": "undocumented"},
        188: {"bucket": "A", "name": None, "goldenSpells": [], "confidence": "undocumented"},
        191: {"bucket": "A", "name": None, "goldenSpells": [], "confidence": "undocumented"},
        192: {"bucket": "A", "name": 'MOD_MELEE_RANGED_HASTE', "goldenSpells": [2825], "confidence": "verified"},
        193: {"bucket": "A", "name": None, "goldenSpells": [], "confidence": "undocumented"},
        195: {"bucket": "A", "name": None, "goldenSpells": [], "confidence": "undocumented"},
        197: {"bucket": "A", "name": None, "goldenSpells": [], "confidence": "undocumented"},
        199: {"bucket": "A", "name": None, "goldenSpells": [], "confidence": "undocumented"},
        201: {"bucket": "A", "name": None, "goldenSpells": [], "confidence": "undocumented"},
        202: {"bucket": "A", "name": None, "goldenSpells": [], "confidence": "undocumented"},
        206: {"bucket": "A", "name": None, "goldenSpells": [], "confidence": "undocumented"},
        207: {"bucket": "A", "name": None, "goldenSpells": [], "confidence": "undocumented"},
        208: {"bucket": "A", "name": None, "goldenSpells": [], "confidence": "undocumented"},
        209: {"bucket": "A", "name": None, "goldenSpells": [], "confidence": "undocumented"},
        210: {"bucket": "A", "name": None, "goldenSpells": [], "confidence": "undocumented"},
        211: {"bucket": "A", "name": None, "goldenSpells": [], "confidence": "undocumented"},
        212: {"bucket": "A", "name": 'MOD_RANGED_ATTACK_POWER_OF_STAT_PERCENT', "goldenSpells": [34501], "confidence": "verified"},
        213: {"bucket": "A", "name": None, "goldenSpells": [], "confidence": "undocumented"},
        214: {"bucket": "C", "name": 'MOD_PERIODIC_DAMAGE_TAKEN_PCT [INFERRED]', "goldenSpells": [27900, 806386], "confidence": "inferred"},
        216: {"bucket": "A", "name": 'HASTE_SPELLS', "goldenSpells": [1714], "confidence": "verified"},
        218: {"bucket": "A", "name": None, "goldenSpells": [], "confidence": "undocumented"},
        219: {"bucket": "A", "name": None, "goldenSpells": [], "confidence": "undocumented"},
        220: {"bucket": "A", "name": 'MOD_RATING_FROM_STAT', "goldenSpells": [21853], "confidence": "verified"},
        222: {"bucket": "C", "name": None, "goldenSpells": [44586], "confidence": "uncertain"},
        225: {"bucket": "A", "name": None, "goldenSpells": [], "confidence": "undocumented"},
        227: {"bucket": "A", "name": 'PERIODIC_TRIGGER_SPELL_WITH_VALUE', "goldenSpells": [15407], "confidence": "verified"},
        229: {"bucket": "A", "name": None, "goldenSpells": [], "confidence": "undocumented"},
        230: {"bucket": "A", "name": None, "goldenSpells": [], "confidence": "undocumented"},
        232: {"bucket": "A", "name": 'MECHANIC_DURATION_MOD', "goldenSpells": [12300, 9453], "confidence": "verified"},
        234: {"bucket": "A", "name": None, "goldenSpells": [], "confidence": "undocumented"},
        235: {"bucket": "A", "name": None, "goldenSpells": [], "confidence": "undocumented"},
        236: {"bucket": "A", "name": None, "goldenSpells": [], "confidence": "undocumented"},
        237: {"bucket": "A", "name": None, "goldenSpells": [], "confidence": "undocumented"},
        238: {"bucket": "A", "name": None, "goldenSpells": [], "confidence": "undocumented"},
        239: {"bucket": "A", "name": None, "goldenSpells": [], "confidence": "undocumented"},
        240: {"bucket": "A", "name": 'MOD_EXPERTISE', "goldenSpells": [10024], "confidence": "verified"},
        241: {"bucket": "A", "name": None, "goldenSpells": [], "confidence": "undocumented"},
        243: {"bucket": "A", "name": None, "goldenSpells": [], "confidence": "undocumented"},
        245: {"bucket": "A", "name": None, "goldenSpells": [], "confidence": "undocumented"},
        246: {"bucket": "A", "name": None, "goldenSpells": [], "confidence": "undocumented"},
        248: {"bucket": "A", "name": None, "goldenSpells": [], "confidence": "undocumented"},
        249: {"bucket": "A", "name": None, "goldenSpells": [], "confidence": "undocumented"},
        253: {"bucket": "A", "name": None, "goldenSpells": [], "confidence": "undocumented"},
        254: {"bucket": "A", "name": None, "goldenSpells": [], "confidence": "undocumented"},
        255: {"bucket": "A", "name": None, "goldenSpells": [], "confidence": "undocumented"},
        256: {"bucket": "A", "name": None, "goldenSpells": [], "confidence": "undocumented"},
        259: {"bucket": "A", "name": None, "goldenSpells": [], "confidence": "undocumented"},
        261: {"bucket": "A", "name": None, "goldenSpells": [], "confidence": "undocumented"},
        262: {"bucket": "A", "name": None, "goldenSpells": [], "confidence": "undocumented"},
        263: {"bucket": "A", "name": None, "goldenSpells": [], "confidence": "undocumented"},
        267: {"bucket": "A", "name": None, "goldenSpells": [], "confidence": "undocumented"},
        268: {"bucket": "A", "name": 'MOD_ATTACK_POWER_OF_STAT_PERCENT', "goldenSpells": [34501], "confidence": "verified"},
        271: {"bucket": "A", "name": 'MOD_DAMAGE_FROM_CASTER', "goldenSpells": [17364], "confidence": "verified"},
        272: {"bucket": "A", "name": None, "goldenSpells": [], "confidence": "undocumented"},
        274: {"bucket": "A", "name": None, "goldenSpells": [], "confidence": "undocumented"},
        275: {"bucket": "A", "name": None, "goldenSpells": [], "confidence": "undocumented"},
        276: {"bucket": "A", "name": None, "goldenSpells": [], "confidence": "undocumented"},
        277: {"bucket": "A", "name": None, "goldenSpells": [], "confidence": "undocumented"},
        278: {"bucket": "A", "name": None, "goldenSpells": [], "confidence": "undocumented"},
        279: {"bucket": "A", "name": None, "goldenSpells": [], "confidence": "undocumented"},
        280: {"bucket": "A", "name": 'MOD_ARMOR_PENETRATION_PCT', "goldenSpells": [2457, 12308], "confidence": "verified"},
        281: {"bucket": "A", "name": None, "goldenSpells": [], "confidence": "undocumented"},
        283: {"bucket": "A", "name": None, "goldenSpells": [], "confidence": "undocumented"},
        284: {"bucket": "A", "name": None, "goldenSpells": [], "confidence": "undocumented"},
        285: {"bucket": "A", "name": 'MOD_ATTACK_POWER_OF_ARMOR', "goldenSpells": [48978], "confidence": "verified"},
        286: {"bucket": "A", "name": 'ABILITY_PERIODIC_CRIT', "goldenSpells": [58435, 63503], "confidence": "verified"},
        287: {"bucket": "A", "name": None, "goldenSpells": [], "confidence": "undocumented"},
        290: {"bucket": "A", "name": 'MOD_CRIT_PCT', "goldenSpells": [14138, 14139, 14140], "confidence": "verified"},
        292: {"bucket": "A", "name": None, "goldenSpells": [], "confidence": "undocumented"},
        294: {"bucket": "A", "name": None, "goldenSpells": [], "confidence": "undocumented"},
        301: {"bucket": "A", "name": None, "goldenSpells": [], "confidence": "undocumented"},
        303: {"bucket": "A", "name": 'MOD_DAMAGE_DONE_VERSUS_AURASTATE', "goldenSpells": [16858], "confidence": "verified"},
        305: {"bucket": "A", "name": None, "goldenSpells": [], "confidence": "undocumented"},
        308: {"bucket": "A", "name": 'MOD_CRIT_CHANCE_FOR_CASTER', "goldenSpells": [23552], "confidence": "verified"},
        312: {"bucket": "C", "name": 'IGNORE_MIN_RANGE [INFERRED]', "goldenSpells": [92116, 804749], "confidence": "inferred"},
        313: {"bucket": "C", "name": None, "goldenSpells": [], "confidence": "uncertain"},
        316: {"bucket": "A", "name": None, "goldenSpells": [], "confidence": "undocumented"},
        317: {"bucket": "B", "name": 'COA_MOD_ABSORB_AND_HEAL_RECEIVED_PCT', "goldenSpells": [705128, 60448], "confidence": "verified"},
        318: {"bucket": "B", "name": None, "goldenSpells": [], "confidence": "undocumented"},
        319: {"bucket": "B", "name": 'COA_MOD_HEALING_RECEIVED_PCT', "goldenSpells": [74410], "confidence": "verified"},
        320: {"bucket": "B", "name": None, "goldenSpells": [], "confidence": "undocumented"},
        327: {"bucket": "B", "name": 'COA_MOD_STAT_FROM_STAT', "goldenSpells": [92132], "confidence": "verified"},
        328: {"bucket": "B", "name": 'COA_MOD_MAX_MANA_FROM_STAT', "goldenSpells": [300351], "confidence": "verified"},
        330: {"bucket": "B", "name": 'COA_MOD_CRIT_CHANCE_AGAINST_TARGET', "goldenSpells": [16454, 503298], "confidence": "verified"},
        333: {"bucket": "B", "name": 'COA_MOD_HIT_CHANCE_ALL_PCT', "goldenSpells": [12814, 11237], "confidence": "verified"},
        336: {"bucket": "B", "name": 'COA_BLOCK_TARGETING_IN_AREA', "goldenSpells": [805756], "confidence": "verified"},
        337: {"bucket": "B", "name": None, "goldenSpells": [], "confidence": "undocumented"},
        338: {"bucket": "B", "name": 'COA_MOD_IGNORE_ARMOR_PCT', "goldenSpells": [15280], "confidence": "verified"},
        340: {"bucket": "B", "name": None, "goldenSpells": [], "confidence": "undocumented"},
        341: {"bucket": "B", "name": None, "goldenSpells": [], "confidence": "undocumented"},
        344: {"bucket": "B", "name": 'COA_MOD_ATTACK_POWER_FLAT', "goldenSpells": [1160], "confidence": "verified"},
        345: {"bucket": "B", "name": 'COA_MOD_SPELL_POWER_FLAT', "goldenSpells": [1459, 1460, 1461], "confidence": "verified"},
        347: {"bucket": "B", "name": 'COA_NEXT_CAST_ATTACH_TRIGGER', "goldenSpells": [805306], "confidence": "verified"},
        348: {"bucket": "B", "name": None, "goldenSpells": [], "confidence": "undocumented"},
        350: {"bucket": "B", "name": None, "goldenSpells": [], "confidence": "undocumented"},
        351: {"bucket": "B", "name": None, "goldenSpells": [], "confidence": "undocumented"},
        353: {"bucket": "B", "name": None, "goldenSpells": [], "confidence": "undocumented"},
        354: {"bucket": "B", "name": 'COA_SCRIPTED_PASSIVE_WITH_VALUE', "goldenSpells": [300557, 500283], "confidence": "verified"},
        357: {"bucket": "B", "name": None, "goldenSpells": [], "confidence": "undocumented"},
        360: {"bucket": "B", "name": 'COA_MOD_HEALING_DONE_VERSUS_AURASTATE', "goldenSpells": [300343], "confidence": "verified"},
        365: {"bucket": "B", "name": None, "goldenSpells": [], "confidence": "undocumented"},
    },
}

TARGET_NAMES = {
    0: "NONE", 1: "UNIT_CASTER", 5: "UNIT_PET", 6: "UNIT_TARGET_ENEMY",
    15: "DEST_AREA_ENEMY_SRC", 16: "DEST_AREA_ENEMY_DST", 18: "DEST_DEST",
    21: "UNIT_TARGET_ALLY", 22: "SRC_CASTER", 25: "UNIT_TARGET_ANY",
    30: "UNIT_AREA_ALLY_SRC", 31: "UNIT_AREA_ALLY_DST", 45: "UNIT_CHAINHEAL_ALLY",
    53: "DEST_TARGET_ENEMY", 57: "UNIT_TARGET_RAID", 61: "UNIT_AREA_CLASS_RAID",
}


def effect_name(n):
    """Canonical name -> COA_ overlay -> numeric fallback (task W4-1)."""
    if n in EFFECT_NAMES:
        return EFFECT_NAMES[n]
    if n in COA_EFFECT_NAMES:
        return COA_EFFECT_NAMES[n]
    return f"EFFECT_{n}"


def aura_name(n):
    """Canonical name -> COA_ overlay -> numeric fallback (task W4-1)."""
    if n in AURA_NAMES:
        return AURA_NAMES[n]
    if n in COA_AURA_NAMES:
        return COA_AURA_NAMES[n]
    return f"AURA_{n}"


def target_name(n):
    return TARGET_NAMES.get(n, f"TARGET_{n}")
