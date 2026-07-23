"""Generic WDBC (3.3.5) reader, named column maps, and raw CSV dumps."""
import csv, gzip, io, json, struct
from pathlib import Path

from tools import config


class LayoutError(RuntimeError):
    pass


def u32(v: int) -> int:
    return v & 0xFFFFFFFF


def f32(v: int) -> float:
    return struct.unpack("<f", struct.pack("<i", v))[0]


class DBCFile:
    def __init__(self, path):
        self.path = Path(path)
        data = self.path.read_bytes()
        magic, self.records, self.fields, self.record_size, strsize = \
            struct.unpack_from("<4s4I", data, 0)
        if magic != b"WDBC":
            raise LayoutError(f"{self.path.name}: bad magic {magic!r}")
        if self.record_size != self.fields * 4:
            raise LayoutError(f"{self.path.name}: record_size {self.record_size} != 4*{self.fields}")
        body_end = 20 + self.records * self.record_size
        if body_end + strsize != len(data):
            raise LayoutError(f"{self.path.name}: size mismatch")
        self._body = data[20:body_end]
        self._strings = data[body_end:]
        self._fmt = f"<{self.fields}i"

    def row_ints(self, i):
        return struct.unpack_from(self._fmt, self._body, i * self.record_size)

    def iter_rows(self):
        for i in range(self.records):
            yield self.row_ints(i)

    def string(self, offset):
        # This build's exporters store real content at string-block offset 0 in
        # every table probed (ChrClasses, ChrRaces, SpellDispelType, SpellMechanic,
        # SpellRange, TalentTab), so 0 is a valid offset, not an empty sentinel.
        # Known anomaly: Spell.dbc places "UPDATE YOUR CLIENT!" at offset 0 and its
        # all-zero placeholder row id=1 references it; faithful decode keeps it.
        if offset < 0 or offset >= len(self._strings):
            return ""
        end = self._strings.index(b"\x00", offset)
        return self._strings[offset:end].decode("utf-8", "replace")


def _spell_columns():
    cols = [
        ("id", 0, "u"), ("category", 1, "u"), ("dispel", 2, "u"), ("mechanic", 3, "u"),
        ("attributes", 4, "u"), ("attributesEx", 5, "u"), ("attributesEx2", 6, "u"),
        ("attributesEx3", 7, "u"), ("attributesEx4", 8, "u"), ("attributesEx5", 9, "u"),
        ("attributesEx6", 10, "u"), ("attributesEx7", 11, "u"),
        ("stances", 12, "u"), ("stancesNot", 14, "u"), ("targets", 16, "u"),
        ("targetCreatureType", 17, "u"), ("casterAuraState", 20, "u"),
        ("targetAuraState", 21, "u"), ("casterAuraSpell", 24, "u"), ("targetAuraSpell", 25, "u"),
        ("castingTimeIndex", 28, "u"), ("recoveryTime", 29, "u"),
        ("categoryRecoveryTime", 30, "u"), ("interruptFlags", 31, "u"),
        ("auraInterruptFlags", 32, "u"), ("channelInterruptFlags", 33, "u"),
        ("procFlags", 34, "u"), ("procChance", 35, "u"), ("procCharges", 36, "u"),
        ("maxLevel", 37, "u"), ("baseLevel", 38, "u"), ("spellLevel", 39, "u"),
        ("durationIndex", 40, "u"), ("powerType", 41, "i"), ("manaCost", 42, "u"),
        ("manaCostPerLevel", 43, "u"), ("manaPerSecond", 44, "u"),
        ("rangeIndex", 46, "u"), ("speed", 47, "f"), ("stackAmount", 49, "u"),
        ("equippedItemClass", 68, "i"),
    ]
    for slot in range(3):
        cols += [
            (f"effect{slot+1}", 71 + slot, "u"),
            (f"effectDieSides{slot+1}", 74 + slot, "i"),
            (f"effectBasePoints{slot+1}", 80 + slot, "i"),
            (f"effectMechanic{slot+1}", 83 + slot, "u"),
            (f"effectImplicitTargetA{slot+1}", 86 + slot, "u"),
            (f"effectImplicitTargetB{slot+1}", 89 + slot, "u"),
            (f"effectRadiusIndex{slot+1}", 92 + slot, "u"),
            (f"effectAura{slot+1}", 95 + slot, "u"),
            (f"effectAmplitude{slot+1}", 98 + slot, "u"),
            (f"effectMultipleValue{slot+1}", 101 + slot, "f"),
            (f"effectChainTarget{slot+1}", 104 + slot, "u"),
            (f"effectMiscValue{slot+1}", 110 + slot, "i"),
            (f"effectMiscValueB{slot+1}", 113 + slot, "i"),
            (f"effectTriggerSpell{slot+1}", 116 + slot, "u"),
        ]
    cols += [
        ("spellIconID", 133, "u"), ("activeIconID", 134, "u"),
        ("name_enUS", 136, "s"), ("rank_enUS", 153, "s"),
        ("description_enUS", 170, "s"), ("tooltip_enUS", 187, "s"),
        ("manaCostPercentage", 204, "u"), ("startRecoveryCategory", 205, "u"),
        ("startRecoveryTime", 206, "u"), ("maxTargetLevel", 207, "u"),
        ("spellFamilyName", 208, "u"), ("spellFamilyFlags1", 209, "u"),
        ("spellFamilyFlags2", 210, "u"), ("maxAffectedTargets", 212, "u"),
        ("dmgClass", 213, "u"), ("preventionType", 214, "u"),
        ("schoolMask", 225, "u"), ("runeCostID", 226, "u"),
        ("spellDescriptionVariableID", 232, "u"), ("spellDifficultyID", 233, "u"),
    ]
    return cols


TABLE_MAPS = {
    "Spell": {"expected_fields": 234, "columns": _spell_columns()},
    "ChrClasses": {"expected_fields": 60, "columns": [
        ("id", 0, "u"), ("powerType", 2, "u"), ("petNameToken", 3, "s"),
        ("name_enUS", 4, "s"), ("filename", 55, "s"), ("spellClassSet", 56, "u"),
        ("flags", 57, "u"),
    ]},
    "ChrRaces": {"expected_fields": 69, "columns": [
        ("id", 0, "u"), ("flags", 1, "u"), ("factionID", 2, "u"),
        ("clientPrefix", 6, "s"), ("clientFileString", 11, "s"),
        ("name_enUS", 14, "s"),
    ]},
    "Talent": {"expected_fields": 23, "columns":
        [("id", 0, "u"), ("tabID", 1, "u"), ("row", 2, "u"), ("col", 3, "u")]
        + [(f"rankSpell{i+1}", 4 + i, "u") for i in range(9)]
        + [(f"prereqTalent{i+1}", 13 + i, "u") for i in range(3)]
        + [(f"prereqRank{i+1}", 16 + i, "u") for i in range(3)]
        + [("flags", 19, "u"), ("requiredSpellID", 20, "u")],
    },
    "TalentTab": {"expected_fields": 24, "columns": [
        ("id", 0, "u"), ("name_enUS", 1, "s"), ("spellIconID", 18, "u"),
        ("raceMask", 19, "u"), ("classMask", 20, "u"), ("petTalentMask", 21, "u"),
        ("orderIndex", 22, "u"), ("backgroundFile", 23, "s"),
    ]},
    "LFGDungeons": {"expected_fields": 49, "columns": [
        ("id", 0, "u"), ("name_enUS", 1, "s"), ("minLevel", 18, "u"),
        ("maxLevel", 19, "u"), ("targetLevel", 20, "u"), ("targetLevelMin", 21, "u"),
        ("targetLevelMax", 22, "u"), ("mapID", 23, "i"), ("difficulty", 24, "u"),
        ("flags", 25, "u"), ("typeID", 26, "u"), ("faction", 27, "i"),
        ("textureFilename", 28, "s"), ("expansionLevel", 29, "u"),
        ("orderIndex", 30, "u"), ("groupID", 31, "u"), ("description_enUS", 32, "s"),
    ]},
    "DungeonEncounter": {"expected_fields": 23, "columns": [
        ("id", 0, "u"), ("mapID", 1, "i"), ("difficulty", 2, "u"),
        ("orderIndex", 3, "u"), ("encounterBit", 4, "u"), ("name_enUS", 5, "s"),
        ("spellIconID", 22, "u"),
    ]},
    "Map": {"expected_fields": 66, "columns": [
        ("id", 0, "u"), ("directory", 1, "s"), ("instanceType", 2, "u"),
        ("flags", 3, "u"), ("name_enUS", 5, "s"), ("areaTableID", 22, "u"),
        ("loadingScreenID", 57, "u"), ("corpseMapID", 59, "i"),
        ("expansionID", 63, "u"), ("maxPlayers", 65, "u"),
    ]},
    "AreaTable": {"expected_fields": 36, "columns": [
        ("id", 0, "u"), ("mapID", 1, "u"), ("parentAreaID", 2, "u"),
        ("flags", 4, "u"), ("explorationLevel", 10, "i"), ("name_enUS", 11, "s"),
        ("factionGroupMask", 28, "u"),
    ]},
    "SkillLine": {"expected_fields": 56, "columns": [
        ("id", 0, "u"), ("categoryID", 1, "i"), ("name_enUS", 3, "s"),
        ("description_enUS", 20, "s"), ("spellIconID", 37, "u"), ("canLink", 55, "u"),
    ]},
    "SkillLineAbility": {"expected_fields": 14, "columns": [
        ("id", 0, "u"), ("skillLine", 1, "u"), ("spell", 2, "u"),
        ("raceMask", 3, "u"), ("classMask", 4, "u"), ("excludeRaceMask", 5, "u"),
        ("excludeClassMask", 6, "u"), ("requiredSkillValue", 7, "u"),
        ("supercededBySpell", 8, "u"), ("acquireMethod", 9, "u"),
        ("trivialSkillLineRankHigh", 10, "u"), ("trivialSkillLineRankLow", 11, "u"),
    ]},
    "SkillRaceClassInfo": {"expected_fields": 8, "columns": [
        ("id", 0, "u"), ("skillID", 1, "u"), ("raceMask", 2, "u"),
        ("classMask", 3, "u"), ("flags", 4, "u"), ("minLevel", 5, "u"),
    ]},
    "SpellDispelType": {"expected_fields": 21, "columns": [
        ("id", 0, "u"), ("name_enUS", 1, "s"), ("mask", 18, "u"),
        ("immunityPossible", 19, "u"), ("internalName", 20, "s"),
    ]},
    "SpellMechanic": {"expected_fields": 18, "columns": [
        ("id", 0, "u"), ("name_enUS", 1, "s"),
    ]},
    "SpellDuration": {"expected_fields": 4, "columns": [
        ("id", 0, "u"), ("base", 1, "i"), ("perLevel", 2, "i"), ("max", 3, "i"),
    ]},
    "SpellRange": {"expected_fields": 40, "columns": [
        ("id", 0, "u"), ("minRange", 1, "f"), ("minRangeFriendly", 2, "f"),
        ("maxRange", 3, "f"), ("maxRangeFriendly", 4, "f"), ("flags", 5, "u"),
        ("name_enUS", 6, "s"),
    ]},
    "SpellRadius": {"expected_fields": 4, "columns": [
        ("id", 0, "u"), ("radius", 1, "f"), ("radiusPerLevel", 2, "f"),
        ("radiusMax", 3, "f"),
    ]},
    "SpellCastTimes": {"expected_fields": 4, "columns": [
        ("id", 0, "u"), ("base", 1, "i"), ("perLevel", 2, "i"), ("min", 3, "i"),
    ]},
    "SpellIcon": {"expected_fields": 2, "columns": [
        ("id", 0, "u"), ("texturePath", 1, "s"),
    ]},
    "SpellRuneCost": {"expected_fields": 5, "columns": [
        ("id", 0, "u"), ("blood", 1, "u"), ("unholy", 2, "u"), ("frost", 3, "u"),
        ("runicPower", 4, "u"),
    ]},
    # v2 (task V2-2): proven via golden-record probes (see .superpowers/sdd/task-v2-2-report.md).
    # Creature: f0 proven ascending-unique 1..127175 (id); f2 proven via golden decode
    # (id 437/60041/92992 -> "Hogger", id 8034 etc -> "Ragnaros"). f20/f21/f22 (the next-
    # highest string_likelihood columns per V2-1 colinfo) were probed as subname
    # candidates and DISPROVEN: on both goldens' rows the raw value is 0 (no data), and
    # across the table the ~4-5% of rows where they decode to non-empty text resolve to
    # unrelated fragments/other creatures' names at a rate matching pure background
    # coincidence (measured ~3.45% on a random-offset control) against a huge (2.5MB)
    # shared string block - not a real subname column. Left unmapped; not carried.
    "Creature": {"expected_fields": 23, "columns": [
        ("id", 0, "u"), ("name_enUS", 2, "s"),
    ]},
    # Quest: NO string block (confirmed, string_block_size=0) - f0 proven unique id
    # (18561 distinct == records). No other column clears the brief's join-rate bars
    # (QuestSort >=80%, QuestInfo join) against QuestSort.dbc/QuestInfo.dbc ids - best
    # real candidate (f20) tops out at ~58.6%/58.2%. Remaining 28 columns stay f<N>,
    # carried raw by tools/build_creatures.py (Quest.dbc has no TABLE_MAPS entry for them).
    "Quest": {"expected_fields": 29, "columns": [
        ("id", 0, "u"),
    ]},
    # QuestSort/QuestInfo: f0 = own id (unique, matches record count), f1 = name_enUS
    # (proven: distinct count equals record count for both - a clean bijective name
    # column, e.g. QuestSort samples "Epic"/"Seasonal"/... and QuestInfo samples
    # "Group"/"Life"/"PvP"/...). Used only as lookup tables (no Quest.dbc column joins
    # them with enough confidence to link - see Quest above).
    "QuestSort": {"expected_fields": 18, "columns": [
        ("id", 0, "u"), ("name_enUS", 1, "s"),
    ]},
    "QuestInfo": {"expected_fields": 18, "columns": [
        ("id", 0, "u"), ("name_enUS", 1, "s"),
    ]},
    # NPCTrainer: f0 proven ascending-unique 1..13001 (id). f1 proven spellId (98.9%
    # join vs Spell.dbc ids; kept signed "i" not "u" - ~1% of rows carry small negative
    # sentinel values, e.g. -210021, that are clearly unused/placeholder entries, and
    # u32-wrapping them would manufacture a misleading huge fake-looking id instead of
    # leaving the sentinel visibly non-positive). f2 proven skillLine (99.9% join vs
    # SkillLine.dbc ids AND semantic golden: values resolve to real profession/talent-
    # tree names - Blacksmithing, Leatherworking, Tailoring, Arcane, Holy, Feral Combat,
    # ...). f3 (the brief's hypothesized "trainer-id low-cardinality column") does NOT
    # prove out as a trainer/NPC identity - see report; left unmapped, carried as raw f3.
    "NPCTrainer": {"expected_fields": 4, "columns": [
        ("id", 0, "u"), ("spellId", 1, "i"), ("skillLine", 2, "u"),
    ]},
    # DungeonEncounterExtra: f0 proven dungeonEncounterId (98.5% join vs DungeonEncounter
    # ids AND semantic golden: resolves to real encounter names - "Panzor the
    # Invincible", "Lord Valthalak", ...). f1 (creature-id hypothesis) clears the naive
    # 90% numeric join-rate vs Creature ids (92.4%) but is DISPROVEN by golden
    # verification: famous boss encounters (Ragnaros, Onyxia, Kel'Thuzad, Illidan, ...)
    # all resolve to random unrelated NPCs (fuzzy name-overlap 1.3%, barely above a
    # random-pairing control's 0.45%). This is a false positive of naive join-rate
    # testing caused by Creature.dbc's fully-dense id space (every integer 1..127175 is
    # a valid creature id, so ANY bounded column passes membership near-trivially) - see
    # report. f2/f3 fail even the naive join-rate bar (~51-55%) against either table.
    # No creature link is provable; tools/build_dungeons.py ships "creature": null.
    "DungeonEncounterExtra": {"expected_fields": 4, "columns": [
        ("dungeonEncounterId", 0, "u"),
    ]},
    # v2 (task V2-3): proven via golden-record probes (see .superpowers/sdd/task-v2-3-report.md).
    # ChrSpecs (101x65): f0 ascending unique 1..101 (id). f1 is NOT a raw classId int -
    # it is a STRING class-name token ("WARRIOR", "WITCHDOCTOR", "DEMONHUNTER", ...),
    # proven by joining its normalized text against ChrClasses.name_enUS: 77/101 rows
    # match one of the 32 ChrClasses rows (25 distinct classes, 78% >= the brief's 60%
    # coverage gate). Rows 1-3 (raw f1=0) decode to "BARBARIAN" - offset 0 in this
    # table's string block is real content (per this build's documented offset-0
    # semantics, see DBCFile.string), not "no data"; they correctly match Barbarian
    # (classId 12). The remaining 24 unmatched rows carry real tokens for classes
    # absent from the 32-row ChrClasses ground truth (DEMONHUNTER, MONK, FLESHWARDEN,
    # SONOFARUGAL, PROPHET, WILDWALKER, SPIRITMAGE) - classId/className resolution
    # happens in build_classmeta.py, not here (this column is intentionally left as
    # the raw token). f2 golden-proven as the CAD "Tab" link key: its uppercased value equals
    # (case-insensitively) the "Tab" field CharacterAdvancementData entries carry for
    # the matched class (verified: Chronomancer's rows decode DISPLACEMENT/DUALITY/TIME,
    # matching data/classes/Chronomancer's Displacement/Duality/Time tab files exactly).
    # f4-f7 are 4 mutually-exclusive-per-class boolean flags proven to be armor-type
    # proficiency (Cloth/Leather/Mail/Plate): every matched class's specs agree on
    # exactly one flag, and the flag matches real WoW class armor proficiency for all
    # 24 matched classes (Warrior/Paladin/DeathKnight->Plate, Hunter/Shaman->Mail,
    # Druid/Rogue->Leather, Priest/Mage/Warlock->Cloth); build_classmeta.py combines
    # them into one "armorType" string (null when 0 or >1 flags are set, e.g. the
    # unreleased "Hero" class has all 4 set and Witch Doctor has 2). f8/f9 golden-
    # verified as primary/secondary stat text ("Agility"/"Intellect"/.../"None"),
    # consistent with each spec's real-WoW stat profile. f17 golden-verified as a
    # difficulty rating ("Medium"/"Normal"/"Hard", 3 distinct). f18/f19 golden-verified
    # as primary/secondary power type ("MANA"/"ENERGY"/"RAGE"/"RUNES"/"RUNIC_POWER"/...),
    # matching each class's real resource (e.g. DeathKnight->RUNES, Rogue->ENERGY).
    # f29 golden-proven as the spec DISPLAY name (distinct=101, bijective with records):
    # Mage rows decode exactly "Arcane"/"Fire"/"Frost", Priest "Discipline"/"Holy"/
    # "Shadow", Warlock "Affliction"/.../.., matching the brief's candidate goldens
    # verbatim. f46 golden-verified as a long descriptive sentence (spec flavor text).
    # f63 (3 distinct: 1/2/3) was the brief's "role" hypothesis (low cardinality <=4) -
    # DISPROVEN as Tank/Healer/DPS role: Discipline Priest(1) and Holy Priest(2) - both
    # healers - get different codes; Protection Warrior(3) vs Protection Paladin(2) -
    # both tanks - disagree; table-wide distribution is a near-even 32/35/34 split,
    # inconsistent with real WoW's DPS-heavy skew. Also tested as "ordinal spec
    # position by ascending id within class" - holds for all 10 vanilla classes
    # (coincidence: their rows were inserted in that order) but fails on 20 of 31
    # class-token groups once customs are included (e.g. WitchDoctor's 3 specs decode
    # 3,1,2, not 1,2,3). No semantic identity provable; shipped raw as f63 (satisfies
    # the brief's `role|f<N>` union via the f<N> branch), read directly off the row
    # (not in this columns list - iter_named only exposes named columns; see
    # build_classmeta.py, same pattern as build_creatures.py's NPCTrainer f3 read).
    "ChrSpecs": {"expected_fields": 65, "columns": [
        ("id", 0, "u"), ("classToken", 1, "s"), ("tabToken", 2, "s"),
        ("armorCloth", 4, "u"), ("armorLeather", 5, "u"),
        ("armorMail", 6, "u"), ("armorPlate", 7, "u"),
        ("primaryStat", 8, "s"), ("secondaryStat", 9, "s"),
        ("difficulty", 17, "s"), ("powerType", 18, "s"), ("secondaryPowerType", 19, "s"),
        ("name_enUS", 29, "s"), ("description_enUS", 46, "s"),
    ]},
    # ChrClassesRoles (32x11): f0 verified classId 1..32 (ascending unique, matches
    # ChrClasses ids exactly). f1 golden-proven as a role bitmask: bit2=canTank,
    # bit4=canHeal, bit8=canDPS (always set) - verified against 12+ classes' real-WoW
    # role capabilities (Warrior/DeathKnight=10=DPS+Tank no heal; Priest/Shaman=12=
    # DPS+Heal no tank; Paladin/Druid=14=all three; Hunter/Rogue/Mage/most pure-DPS
    # customs=8=DPS only). f4 golden-proven as a specialAbilitySpellId: only 3 of 32
    # classes carry a non-zero value (Shaman 1182001, Bloodmage 681078, Primalist
    # 92150), and all 3 resolve to real, thematically-plausible Spell.dbc entries
    # ("Earthen Guardian", "Pooled Vitality", "Grove Training"). f2/f3 correlate with
    # f4's presence (only non-zero on the same 3 rows) but have no independently
    # provable meaning of their own - left raw. f5-f10 are always 0 - left raw.
    "ChrClassesRoles": {"expected_fields": 11, "columns": [
        ("id", 0, "u"), ("roleMask", 1, "u"), ("specialAbilitySpellId", 4, "u"),
    ]},
    # CharacterCreationArchetypes (56x157, "Choose your Archetype"-style character-
    # creation flavor presets, class-agnostic - no classId column exists in this
    # table; see report). f0 ascending unique (id), 100% FK target of
    # ArchetypeDetails.f1 (see below). f19 golden-proven bijective display name
    # (distinct=56): samples "Naturalist"/"Dawnkeeper"/"Eternal Caretaker" (all
    # healer-flavor names), cross-validated by f155 (distinct=56, "Interface\
    # Cinematics\Naturalist.avi" etc - literal filename match to f19's value). f36/f53
    # golden-verified as tagline/long-description text (both distinct=56, coherent
    # flavor prose). f8 golden-verified primary stat token ("STAT_STRENGTH" etc). f9-
    # f11/f12-f14 golden-verified as up to 3 preferred weapon/armor subclass tokens
    # each (ITEM_SUBCLASS_WEAPON_*/ITEM_SUBCLASS_ARMOR_*); "MAX_ITEM_SUBCLASS_*"
    # sentinel values (an enum terminator, not a real type) are filtered out in
    # build_classmeta.py. f15 golden-verified spell-icon token. f70/f87/f104/f121/f138
    # golden-verified as up to 5 "ability preview" tooltip texts ("Unlocks at level N
    # ... <effect text>"), sparsely populated (f138 only 16/56). f1 (distinct=9,
    # bounded 1-12) looks like a categoryId FK into CharacterCreationArchetypeCategories
    # - out of this task's curation scope per the brief, not decoded, left raw.
    "CharacterCreationArchetypes": {"expected_fields": 157, "columns": [
        ("id", 0, "u"), ("primaryStat", 8, "s"),
        ("weaponType1", 9, "s"), ("weaponType2", 10, "s"), ("weaponType3", 11, "s"),
        ("armorType1", 12, "s"), ("armorType2", 13, "s"), ("armorType3", 14, "s"),
        ("iconToken", 15, "s"), ("name_enUS", 19, "s"), ("tagline_enUS", 36, "s"),
        ("description_enUS", 53, "s"),
        ("abilityPreview1_enUS", 70, "s"), ("abilityPreview2_enUS", 87, "s"),
        ("abilityPreview3_enUS", 104, "s"), ("abilityPreview4_enUS", 121, "s"),
        ("abilityPreview5_enUS", 138, "s"), ("cinematicPath", 155, "s"),
    ]},
    # CharacterCreationArchetypeDetails (1120x28, no strings): f0 ascending unique
    # (id). f1 golden-proven archetypeId: 100% (1120/1120) join-rate against
    # CharacterCreationArchetypes.f0 (a genuinely sparse id space, 56 values within
    # 1-144). f2 golden-proven raceId: distinct values are exactly {1,2,3,4,5,6,7,8,
    # 10,11} (skipping 9=Goblin, not playable in WotLK), 1:1 name match via
    # ChrRaces.dbc for every value, and exactly 112 rows per race (1120/10). Remaining
    # 25 columns are mostly float-looking/near-constant with no provable semantics -
    # left raw.
    "CharacterCreationArchetypeDetails": {"expected_fields": 28, "columns": [
        ("id", 0, "u"), ("archetypeId", 1, "u"), ("raceId", 2, "u"),
    ]},
    # CharacterCreationClassDetails (464x28, no strings): f0 ascending unique (id).
    # f1 golden-proven classId: its 21 distinct values are EXACTLY the range 12-32
    # (every custom ChrClasses id, zero vanilla/Hero ids 1-11) - a structural/semantic
    # match to the real custom-vs-vanilla class boundary, not a naive bounded-range
    # coincidence. f2 golden-proven raceId: same {1..8,10,11} skip-9 pattern as
    # ArchetypeDetails, verified per-class (e.g. Barbarian's 64 rows group into 11
    # raceId buckets - all 11, including Goblin). Remaining 25 columns (float-looking
    # stat scalars) have no provable semantics - left raw.
    "CharacterCreationClassDetails": {"expected_fields": 28, "columns": [
        ("id", 0, "u"), ("classId", 1, "u"), ("raceId", 2, "u"),
    ]},
    # CharacterCreationPetDetails (170x12, no strings): f0 ascending-ish unique (id,
    # sparse 11-190). f2 golden-proven raceId (same skip-9 pattern, verified: 17
    # distinct f1-groups each cycle exactly the 10 playable raceIds). f1 (brief
    # hypothesis: petId or spellId) DISPROVEN as a Spell.dbc join: only 76.5% naive
    # join-rate (below the 90% bar) AND the resolved "spell name" for the most common
    # value is a garbage colorized tooltip fragment ("Bile\n|cFF1EFF0CTier 1|r"), not
    # a real spell name - a join-rate false positive from Spell.dbc's large id space,
    # same class of finding as V2-2's DungeonEncounterExtra creature link. Left raw.
    "CharacterCreationPetDetails": {"expected_fields": 12, "columns": [
        ("id", 0, "u"), ("raceId", 2, "u"),
    ]},
    # CharacterCreationShapeshiftDetails (100x21, no strings): f0 ascending-ish unique
    # (id, sparse 9-108). f2 golden-proven raceId (same skip-9 pattern, verified: 10
    # distinct f1-groups each cycle exactly the 10 playable raceIds). f1 (brief
    # hypothesis: shapeshift-form spellId) DISPROVEN as a Spell.dbc join: only 70.0%
    # naive join-rate (below the 90% bar) and the most common value (1816) does not
    # resolve to any Spell.dbc row at all. Left raw.
    "CharacterCreationShapeshiftDetails": {"expected_fields": 21, "columns": [
        ("id", 0, "u"), ("raceId", 2, "u"),
    ]},
    # v2 (task V2-4): proven via golden-record probes (see .superpowers/sdd/task-v2-4-report.md).
    # SpellDescriptionVariables (31x2, trivial per the brief - a plain (id, text)
    # string table): f0 golden-proven as the id Spell.dbc's own spellDescriptionVariableID
    # column (already extracted, previously unused in output) points at - the two id
    # sets are IDENTICAL (both exactly 31 values, 100% overlap), and a concrete golden
    # resolves: spell 10 (Blizzard) carries spellDescriptionVariableID 167, which
    # decodes here to a real tooltip-math script starting "$arctic1=...".
    "SpellDescriptionVariables": {"expected_fields": 2, "columns": [
        ("id", 0, "u"), ("text_enUS", 1, "s"),
    ]},
    # SpellCategory (5024x2): f0 golden-proven as the id Spell.dbc's own "category"
    # column (already extracted as TABLE_MAPS "category", index 1 - previously decoded
    # but never surfaced in build_spells.py's output) references: 1112/1119 (99.37%)
    # of the distinct nonzero Spell.category values used across the whole Spell.dbc
    # resolve as SpellCategory.f0 ids, and the golden spell 17 (Power Word: Shield)
    # carries category=1269, which is present in this table. f1 (distinct 4, range
    # 0-4, 99.88% zero) matches the real WotLK SpellCategory.dbc's 2-column (ID, Flags)
    # shape by prior-art range alone, but has no in-dataset golden proof (only 6/5024
    # rows nonzero; cross-checking it against Spell.dbc's own procCharges field found
    # no correlation) - left unmapped/raw, not carried into any output.
    "SpellCategory": {"expected_fields": 2, "columns": [
        ("id", 0, "u"),
    ]},
    # SpellTags (488661x3): f0 (distinct==records, sparse range up to 567460) is the
    # table's own per-row PK - not itself useful, kept named for raw-dump clarity only.
    # f1 golden-proven spellId: range tops out at 13977917, 3 below the live Spell.dbc's
    # actual max id (13977920) - overwhelming corroboration alongside the golden check
    # (spell 17 Power Word: Shield resolves tags "Priest"/"Discipline"/"Holy"/"Healer"/
    # "Absorb"/"Magic"/"Instant Cast"/"Mana Cost" - exactly the real spell's class/
    # spec/school/role; spell 10 Blizzard resolves "Mage"/"Frost"/"AoE"/"DPS"; spell
    # 133 Fireball resolves "Mage"/"Fire"/"DPS"). The raw row-level join rate against
    # Spell.dbc ids is 86.26% (421510/488661) - short of a naive 95% bar, but the
    # misses cluster in small adjacent id runs (4916; 16308-16309; 19258-19259; ...),
    # the signature of legitimate historical-spell churn (same class as this codebase's
    # documented cad_reborn/rank orphan findings), not a wrong column: the golden
    # semantic match is unambiguous and the value range corroboration is a near-exact
    # ceiling match, so f1 is named despite the raw percentage. f2 golden-proven
    # tagTypeId: 100% (488661/488661) of values are members of SpellTagTypes.f0.
    "SpellTags": {"expected_fields": 3, "columns": [
        ("id", 0, "u"), ("spellId", 1, "u"), ("tagTypeId", 2, "u"),
    ]},
    # SpellTagTypes (200x61): f0 ascending-ish unique (id, matches SpellTags.f2 range
    # exactly). f27 golden-proven as the tag display name (distinct 175/200, samples
    # "Core Damage"/"Mobility"/"Raid Buffs" per V2-1's colinfo evidence; confirmed by
    # the SpellTags goldens above, e.g. id 63->"Priest", 93->"Discipline", 10->"Absorb").
    # f44 is a "<category>: <name>" composite label (e.g. "Ability Type: Magic",
    # "Class: Priest", "Priest: Discipline") - useful grouping evidence but not needed
    # by the brief's `tags: [tagNames]` output shape, left unmapped. Every other
    # string-likely column (per V2-1 colinfo: f3-f25,f28-f60ish) is either an all-zero
    # placeholder (offset-0 filler, this build's documented non-empty-offset-0
    # anomaly) or a constant-offset locale-padding artifact (all rows point at the
    # same string, e.g. f28-f42/f45-f59 always decode to the empty string at offset 65)
    # - not real per-row data, left unmapped.
    "SpellTagTypes": {"expected_fields": 61, "columns": [
        ("id", 0, "u"), ("name_enUS", 27, "s"),
    ]},
    # SpellCustomAttr (58127x11): the brief hypothesized f0=spellId, DISPROVEN - f0 is
    # ascending unique EXACTLY 1..58127 (matches record count precisely, the classic
    # local auto-increment PK shape), and its raw join rate against Spell.dbc ids is
    # only 73.86%. The real spellId is f1: distinct==records (bijective, no dupes),
    # range tops out at 13977855 (essentially the same near-max-id ceiling evidence as
    # SpellTags.f1 above), and its raw join rate is 99.98% (58116/58127) - comfortably
    # proven. Remaining 9 columns (f2-f10, all-numeric flag/bitmask-looking data, no
    # strings, no further semantics provable) plus f0 (now known to be the row's own
    # id, not spellId) are carried as a 10-element raw `customAttr` array in column
    # order [f0, f2, f3, f4, f5, f6, f7, f8, f9, f10] per the brief's literal
    # `customAttr: [u32 x10]` shape.
    "SpellCustomAttr": {"expected_fields": 11, "columns": [
        ("id", 0, "u"), ("spellId", 1, "u"),
    ]},
    # SpellAddon (5598x23, no strings): the brief hypothesized f0=spellId, DISPROVEN
    # the same way as SpellCustomAttr - f0's raw join rate is only 41.18% (and f0's
    # value range, up to 1591271, doesn't reach anywhere near Spell.dbc's real ~14M
    # max id). f1 is the real spellId: raw join rate 99.98% (5597/5598), range tops
    # out at 2514021 - well inside the live custom-spell id space. Remaining 22
    # columns (f0, f2-f22) were probed for further semantics: f20/f21/f22 clear a
    # naive 100% join-rate vs Spell.dbc ids, but this is the same false-positive class
    # documented elsewhere in this file (Creature/DungeonEncounterExtra) - a golden
    # check shows f20's "resolved spell" for 5 unrelated SpellAddon rows (Moonfury,
    # Blades of Blood, Volatile Discharge, Nightmare Mauling, ...) all repeats the SAME
    # unrelated id (42, "Extravagant Black Pearl"), i.e. coincidental small-number
    # membership, not a real per-row link - disproven. No other column showed string
    # evidence (string_block_size=0) or a corroborating lookup table. Carried as a
    # 22-element raw `addon.raw` array in column order [f0, f2, f3, ..., f22].
    "SpellAddon": {"expected_fields": 23, "columns": [
        ("id", 0, "u"), ("spellId", 1, "u"),
    ]},
    # OverrideSpellData (49x12, no strings): f0 golden-proven as a base/trigger spellId
    # (raw join rate 97.96%, 48/49) whose f1-f10 slots hold up to 10 alternate spell
    # ids that visually/functionally replace it (a real WotLK action-bar-swap
    # mechanic) - proven both by range (values up to 3.3M, well inside the live spell
    # id space, not a small-number coincidence) and by strong thematic goldens: base
    # 271 "Call of the Void" overrides to Rip/Claw/Rake (Druid Cat Form abilities);
    # base 221 "Endangered" overrides to Fire Nova/Fireball/Flame Patch/Explode (all
    # fire-themed); base 331/332 "Healing Wave" override to Flow of Life/Rejuvenation
    # and Lesser Healing Wave/Chain Heal (all heals). f11 (distinct 4, range 0-5) has
    # no provable semantics (no lookup table, no cross-validation found) - carried raw
    # as `overrideData.raw`, not named.
    "OverrideSpellData": {"expected_fields": 12, "columns":
        [("id", 0, "u")] + [(f"override{i}", i, "u") for i in range(1, 11)]
    },
    # SpellAlternativePowerType (4x19): f0=id, f1 golden-proven display name (only
    # string-likely column, samples "Shadow Orbs (3)"/"Shadow Orbs (5)"/"Holy Power
    # (3)"/"Holy Power (5)" - trivially proven, a plain lookup table). NO per-spell
    # link is provable: the brief's natural hypothesis (Spell.dbc's signed "powerType"
    # column going negative indexes this table) is DISPROVEN - the only negative
    # powerType value that occurs anywhere in Spell.dbc is -2 (518 spells: Health
    # Funnel, Life Tap, Bloodrage, Dark Offering, Sacrifice, ...), which is already the
    # pre-existing, unrelated "Health" sentinel this codebase's own enums335.POWER_TYPES
    # decodes (a real WoW power-type enum value, nothing to do with alternate power
    # bars). No other Spell.dbc column was found to reference ids 1-4. Kept as a named
    # lookup table (id/name) for raw-dump clarity; zero coverage on spells.jsonl,
    # documented in _meta.enrichment.alternativePowerType.
    "SpellAlternativePowerType": {"expected_fields": 19, "columns": [
        ("id", 0, "u"), ("name_enUS", 1, "s"),
    ]},
    # SpellCharges (401x2) + SpellChargesCategory (105x3): linkage direction PROVEN -
    # SpellCharges.f1 -> SpellChargesCategory.f0 joins at 100% (401/401), matching
    # value range (SpellCharges.f1 max 661 == SpellChargesCategory.f0's own max) - so
    # SpellCharges is (spellId, categoryId) and SpellChargesCategory's f0 is its own
    # id. SpellCharges.f0 is golden-corroborated as a spellId: of the 352/401 (87.78%)
    # rows that resolve against live Spell.dbc ids, 95.45% (336/352) mention "charge"
    # in their tooltip/description text (e.g. id 52 "Overcharged: Manaforge Coruu") -
    # strong semantic confirmation. BUT the brief sets an explicit >=90% bar
    # specifically for this pair's link to Spell.dbc rows, and 87.78% falls short of
    # it - per the brief's documented fallback, this is named here (linkage is proven)
    # but attaches NOTHING to spells.jsonl records (see build_spells.py); coverage +
    # both join rates are recorded in _meta.enrichment.charges instead.
    # SpellChargesCategory.f1 (maxCharges?, 1-10) and f2 (rechargeMs?, 4000-120000)
    # look domain-plausible by range alone but failed the one cross-validation
    # attempted (Spell.dbc's own procCharges field vs f1: 1.7% match, no correlation)
    # - left unmapped/raw, not named.
    "SpellCharges": {"expected_fields": 2, "columns": [
        ("spellId", 0, "u"), ("categoryId", 1, "u"),
    ]},
    "SpellChargesCategory": {"expected_fields": 3, "columns": [
        ("id", 0, "u"),
    ]},
}


def _open_checked(table: str) -> tuple[DBCFile, dict]:
    spec = TABLE_MAPS[table]
    f = DBCFile(config.WORK_DBC_DIR / f"{table}.dbc")
    if f.fields != spec["expected_fields"]:
        raise LayoutError(
            f"{table}: field_count {f.fields} != expected {spec['expected_fields']} "
            f"- column map must be re-verified before trusting any output")
    return f, spec


def _decode(f: DBCFile, row: tuple, name: str, idx: int, kind: str):
    v = row[idx]
    if kind == "u":
        return u32(v)
    if kind == "f":
        return round(f32(v), 6)
    if kind == "s":
        return f.string(v)
    return v


def iter_named(table: str):
    f, spec = _open_checked(table)
    cols = spec["columns"]
    for row in f.iter_rows():
        yield {name: _decode(f, row, name, idx, kind) for name, idx, kind in cols}


def dump_table(table: str) -> Path:
    f, spec = _open_checked(table)
    named = {idx: (name, idx, kind) for name, idx, kind in spec["columns"]}
    header = [named[i][0] if i in named else f"f{i}" for i in range(f.fields)]
    out = config.RAW_DBC_DIR / f"{table}.csv.gz"
    # gzip.open("wt") embeds the current mtime in the gzip header, so identical
    # CSV content re-dumped later produces byte-different .gz files - violates
    # the "raw/ diff shows exactly what a game patch changed" constraint.
    # Pin mtime=0 so output is a pure function of the DBC content.
    with open(out, "wb") as fb, \
         gzip.GzipFile(fileobj=fb, mode="wb", mtime=0) as gz, \
         io.TextIOWrapper(gz, encoding="utf-8", newline="") as fh:
        w = csv.writer(fh)
        w.writerow(header)
        for row in f.iter_rows():
            w.writerow([
                _decode(f, row, *named[i]) if i in named else row[i]
                for i in range(f.fields)
            ])
    return out


def dump_unmapped(table: str) -> Path:
    """Dump a table with no TABLE_MAPS entry as raw signed ints (f0..fN) plus
    a colinfo.json evidence sidecar: per-column distinct/min/max/pct_zero and
    a string-likelihood score (fraction of rows whose value is a plausible
    string-block offset), with up to 3 decoded samples for string-likely
    columns. This is the mapping-evidence trail for later empirical curation.
    """
    f = DBCFile(config.WORK_DBC_DIR / f"{table}.dbc")
    n = f.fields
    strblock_size = len(f._strings)
    records = f.records

    distinct = [set() for _ in range(n)]
    mins = [None] * n
    maxs = [None] * n
    zeros = [0] * n
    strlike = [0] * n
    samples = [[] for _ in range(n)]

    out = config.RAW_DBC_DIR / f"{table}.csv.gz"
    with open(out, "wb") as fb, \
         gzip.GzipFile(fileobj=fb, mode="wb", mtime=0) as gz, \
         io.TextIOWrapper(gz, encoding="utf-8", newline="") as fh:
        w = csv.writer(fh)
        w.writerow([f"f{i}" for i in range(n)])
        for row in f.iter_rows():
            w.writerow(row)
            for i in range(n):
                v = row[i]
                distinct[i].add(v)
                if mins[i] is None or v < mins[i]:
                    mins[i] = v
                if maxs[i] is None or v > maxs[i]:
                    maxs[i] = v
                if v == 0:
                    zeros[i] += 1
                is_strlike = strblock_size > 0 and (
                    v == 0 or (0 < v < strblock_size and f._strings[v - 1] == 0))
                if is_strlike:
                    strlike[i] += 1
                    if len(samples[i]) < 3:
                        s = f.string(v)
                        if s and s not in samples[i]:
                            samples[i].append(s)

    columns = []
    for i in range(n):
        likelihood = round(strlike[i] / records, 4) if records else 0.0
        columns.append({
            "index": i,
            "distinct": len(distinct[i]),
            "min": mins[i],
            "max": maxs[i],
            "pct_zero": round(zeros[i] / records, 4) if records else 0.0,
            "string_likelihood": likelihood,
            "samples": samples[i][:3] if likelihood >= 0.9 else [],
        })

    colinfo = {
        "table": table, "records": records, "fields": n,
        "string_block_size": strblock_size, "columns": columns,
    }
    (config.RAW_DBC_DIR / f"{table}.colinfo.json").write_text(
        json.dumps(colinfo, indent=1, sort_keys=True, ensure_ascii=False), encoding="utf-8")
    return out


def dump_all():
    config.ensure_dirs()
    for table in sorted(TABLE_MAPS):
        p = dump_table(table)
        print(f"dumped {p.name}")
    for name in sorted(config.WANTED_DBCS):
        table = Path(name).stem
        if table in TABLE_MAPS:
            continue
        p = dump_unmapped(table)
        print(f"dumped {p.name} (unmapped)")


if __name__ == "__main__":
    dump_all()
