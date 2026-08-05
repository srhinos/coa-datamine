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
        magic, self.records, declared_fields, self.record_size, strsize = \
            struct.unpack_from("<4s4I", data, 0)
        if magic != b"WDBC":
            raise LayoutError(f"{self.path.name}: bad magic {magic!r}")
        if self.record_size % 4 != 0:
            raise LayoutError(
                f"{self.path.name}: record_size {self.record_size} not a multiple of 4")
        # [Task V3-2 finding] The header's declared FieldCount is occasionally wrong -
        # observed on a realm-overlay table, area-52's CharacterAdvancement.dbc:
        # declared 179 vs the byte-accurate 173 (record_size 692 / 4), off by exactly
        # 6 fields. record_size is what actually determines row layout AND it
        # reconciles exactly with the file's total size (20 + records*record_size +
        # string_block_size == len(data), verified), so it is authoritative for
        # parsing; the declared count is kept only as a diagnostic
        # (self.declared_fields), never trusted for the row struct format. This is a
        # no-op for every table where the two already agree (every base-client table
        # probed so far, and 11 of area-52's 12 tables).
        self.fields = self.record_size // 4
        self.declared_fields = declared_fields
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
    # [V3-0 CORRECTION 2026-08-01, see .superpowers/sdd/task-v3-0-report.md] V2-2 named f0
    # as "id" (ascending-unique 1..127178, the classic local auto-increment PK shape) -
    # this is WRONG: f0 is a POSITIONAL row index, not a stable entry id. The 2026-08-01
    # client rebuild proved this directly - a patch inserted 3 rows and every downstream
    # Ragnaros-variant id shifted by exactly +3 (107744->107747 etc), the same "row-
    # position, not content key" churn already documented elsewhere in this file
    # (SpellCustomAttr, SpellAddon, SpellCharges ref). f1 is the real, stable creature
    # TEMPLATE ENTRY id: proven unique across all 127178 rows (distinct(f1) == records,
    # zero duplicates) and golden-verified against 4 canonical WotLK 3.3.5 entry ids -
    # Hogger 448, Edwin VanCleef 639, Onyxia 10184, Ragnaros 11502 - matching the server's
    # real template ids (f0 resolves those same numbers to unrelated NPCs, e.g.
    # 448->"Demisette Cloyce", proving the two columns are genuinely different things,
    # not a coincidental relabeling). f2 stays proven "name" (unchanged from V2-2,
    # string_likelihood=1.0, pct_zero=0.0). f0 is dropped entirely from curated output
    # (positional noise, not carried, not even raw). f20/f21/f22 subname hypothesis is
    # unaffected by this correction - still DISPROVEN per V2-2's report (both goldens
    # carry raw 0, table-wide non-zero rate matches a random-offset control's coincidence
    # rate) - left unmapped.
    "Creature": {"expected_fields": 23, "columns": [
        ("id", 1, "u"), ("name_enUS", 2, "s"),
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
    # NPCTrainer: f0 proven ascending-unique 1..13111 (id). f1 proven spellId (98.9%
    # join vs Spell.dbc ids; kept signed "i" not "u" - ~1% of rows carry small negative
    # sentinel values, e.g. -210021, that are clearly unused/placeholder entries, and
    # u32-wrapping them would manufacture a misleading huge fake-looking id instead of
    # leaving the sentinel visibly non-positive). f2 proven skillLine (99.9% join vs
    # SkillLine.dbc ids AND semantic golden: values resolve to real profession/talent-
    # tree names - Blacksmithing, Leatherworking, Tailoring, Arcane, Holy, Feral Combat,
    # ...). f3 (the brief's hypothesized "trainer-id low-cardinality column") does NOT
    # prove out as a trainer/NPC identity - see report; left unmapped, carried as raw f3.
    # [V3-0 re-check 2026-08-01, see .superpowers/sdd/task-v3-0-report.md] Every column
    # retested against Creature.dbc's now-corrected f1 entry-id space (sparse,
    # 1..11001007, unlike the old dense-f0 space that made false positives easy): f0 (own
    # row id) 67.3% naive join, f1 (proven spellId) 13.2%, f2 (proven skillLine) 49.0%,
    # f3 (unproven) 48.7% - none clears the 90% bar, all comfortably below it now that a
    # bounded column can't coast on Creature's id density. No remap: this table still has
    # no per-row trainer-NPC identity column anywhere; f0 stays the table's own
    # positional row id, unrenamed.
    "NPCTrainer": {"expected_fields": 4, "columns": [
        ("id", 0, "u"), ("spellId", 1, "i"), ("skillLine", 2, "u"),
    ]},
    # DungeonEncounterExtra: f0 proven dungeonEncounterId (98.5% join vs DungeonEncounter
    # ids AND semantic golden: resolves to real encounter names - "Panzor the
    # Invincible", "Lord Valthalak", ...).
    # [V3-0 CORRECTION 2026-08-01, see .superpowers/sdd/task-v3-0-report.md] f1
    # creatureId: V2-2 DISPROVED this same column joining against Creature.dbc's old f0
    # (a fully-dense 1..127178 id space where any bounded column passes membership near-
    # trivially - every famous-boss golden resolved to an unrelated random NPC, fuzzy
    # name-overlap only 1.3% vs a 0.45% random control). Once Creature's real entry id
    # was identified as f1 (a genuinely sparse space, 127178 ids spread across
    # 1..11001007 - see the Creature entry above), the SAME DungeonEncounterExtra column
    # f1 was retested against it and PROVEN: row-level join-rate 98.57% (2006/2035 rows
    # whose encounter resolves a name), and every famous-boss golden now resolves
    # correctly (Ragnaros->11502 "Ragnaros", Onyxia->10184 "Onyxia",
    # Kel'Thuzad->15990 "Kel'Thuzad", Illidan Stormrage->22917 "Illidan Stormrage",
    # Vaelastrasz the Corrupt->13020, Broodlord Lashlayer->12017, Chromaggus->14020,
    # Nefarian->11583, C'thun->15727 "C'Thun" [case-only difference]) - fuzzy word-
    # overlap across the whole table is 94.7% (1900/2006) vs a random-pairing control's
    # 0.55%, not a coincidence. A minority of dungeonEncounterId values (20 of ~2048
    # distinct) repeat across multiple DungeonEncounterExtra rows (extra per-difficulty
    # metadata rows); every repeat verified to agree on f1 (same creature), so first-row-
    # wins is safe. dungeonEncounterId==0 is a placeholder/sentinel (14 rows, disagreeing
    # f1 values, and 0 is not a real DungeonEncounter id) - naturally excluded, no real
    # encounter has id 0. f2/f3 still fail even the naive join-rate bar (~51-55%) against
    # either table - left raw, unmapped. tools/build_dungeons.py now wires
    # "creature": {id, name} | null onto every encounter.
    "DungeonEncounterExtra": {"expected_fields": 4, "columns": [
        ("dungeonEncounterId", 0, "u"), ("creatureId", 1, "u"),
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
    # SpellCharges (400x2) + SpellChargesCategory (105x3): linkage direction PROVEN -
    # SpellCharges.f1 -> SpellChargesCategory.f0 joins at 100% (400/400), matching
    # value range (SpellCharges.f1 max 661 == SpellChargesCategory.f0's own max) - so
    # f1 is named "categoryId" here (the category-link column is 100% proven).
    # SpellCharges.f0 is golden-corroborated as a spellId: of the 354/400 (88.5%)
    # rows that resolve against live Spell.dbc ids, a large majority mention "charge"
    # in their tooltip/description text (e.g. id 52 "Overcharged: Manaforge Coruu") -
    # strong semantic confirmation. BUT the brief sets an explicit >=90% bar
    # specifically for this pair's link to Spell.dbc rows, and 88.5% falls short of
    # it - per the empirical mapping rule (name only with proof clearing the stated
    # bar), f0 stays UNNAMED here (not "spellId") and is dumped as plain "f0" by
    # dump_table. build_spells.py's standalone data/spells/charges.json (single-writer:
    # build_spells owns data/spells/) refers to this same column as "ref" - a
    # deliberately noncommittal name that documents the sub-90% finding inline via its
    # own "_note" field rather than asserting a proven identity in TABLE_MAPS. Nothing
    # from this table attaches to individual spells.jsonl records; see build_spells.py.
    # SpellChargesCategory.f1 (maxCharges?, 1-10) and f2 (rechargeMs?, 4000-120000)
    # look domain-plausible by range alone but failed the one cross-validation
    # attempted (Spell.dbc's own procCharges field vs f1: 1.7% match, no correlation)
    # - left unmapped/raw, not named; carried into charges.json's "categories" as raw.
    "SpellCharges": {"expected_fields": 2, "columns": [
        ("categoryId", 1, "u"),
    ]},
    "SpellChargesCategory": {"expected_fields": 3, "columns": [
        ("id", 0, "u"),
    ]},
    # v2 (task V2-5): proven via golden-record probes (see .superpowers/sdd/task-v2-5-report.md).
    # Challenge (297x53, the hub table): f0 golden-proven id (distinct==records==297, sparse
    # 5-622, not contiguous - a real custom id space, not row order). f7 golden-proven
    # name_enUS (distinct 291/297: id5="Partner Up!", id7="Nudist", ...). f24 golden-proven
    # description_enUS (distinct 210/297, 1:1 with f7 per row). Golden: Challenge 7 "Nudist"
    # decodes description "You are unable to equip or wear armor of any kind." - this cross-
    # validates against ChallengeRuleTypes id5 (CHALLENGE_RULES_TYPE_NO_EQUIP_ARMOR / "No
    # Equipping Armor" / "You may not equip any armor.") and ChallengeRules' own per-challenge
    # row for challenge 7 (ruleTypeToken == that exact same token) - the brief's requested
    # cross-table corroboration, verified end-to-end. f42 iconToken (distinct 203/297, icon
    # path tokens). f43 difficultyToken (5 distinct: CHALLENGE_DIFFICULTY_EASY/HARD/
    # IMPOSSIBLE/NORMAL/VERY_HARD). f52 modeToken (8 distinct: default/ironman/hardcore/
    # Hardcore/nightmare/resolute/Resolute/adventure). f1-f2,f8-f23,f25-f41,f44-f51 are
    # either the 16-locale-offset+mask LangString filler block this build always carries
    # around each real string column (see DBCFile.string's offset-0 note) or unproven
    # boolean/flag columns - left f<N>.
    "Challenge": {"expected_fields": 53, "columns": [
        ("id", 0, "u"), ("name_enUS", 7, "s"), ("description_enUS", 24, "s"),
        ("iconToken", 42, "s"), ("difficultyToken", 43, "s"), ("modeToken", 52, "s"),
    ]},
    # ChallengeModifierTypes (8x37, lookup table): f0=id(1-8). f1=token
    # (CHALLENGE_MODIFIERS_TYPE_*). f2=name_enUS (short display, e.g. "Physical Damage
    # Done"). f19=descriptionFormat_enUS (templated tooltip w/ {1} placeholder, e.g. "{1}%
    # Physical Damage Done"). f36=iconToken. All golden-verified by direct row decode (8
    # rows, trivial to eyeball in full - see report).
    "ChallengeModifierTypes": {"expected_fields": 37, "columns": [
        ("id", 0, "u"), ("token", 1, "s"), ("name_enUS", 2, "s"),
        ("descriptionFormat_enUS", 19, "s"), ("iconToken", 36, "s"),
    ]},
    # ChallengeRuleTypes (127x36, lookup table): f0=id(1-127). f1=token. f2=name_enUS
    # (short, e.g. "No Equipping Armor"). f19=description_enUS (full sentence, e.g. "You
    # may not equip any armor.") - id5's row is the Challenge-7 "Nudist" golden's
    # cross-validation target, see Challenge's comment above.
    "ChallengeRuleTypes": {"expected_fields": 36, "columns": [
        ("id", 0, "u"), ("token", 1, "s"), ("name_enUS", 2, "s"), ("description_enUS", 19, "s"),
    ]},
    # ChallengeConditionTypes (18x73, lookup table): f0=id(1-18). f1=token. f2=name_enUS.
    # f19=description_enUS. f36=negatedName_enUS ("<Name> (Inverted)"). f53=
    # negatedDescription_enUS. (No ChallengeConditions.dbc row carries a provable numeric
    # or token link back to this table - see ChallengeConditions below; this lookup table
    # itself decodes cleanly and is shipped for completeness/evidence.)
    "ChallengeConditionTypes": {"expected_fields": 73, "columns": [
        ("id", 0, "u"), ("token", 1, "s"), ("name_enUS", 2, "s"), ("description_enUS", 19, "s"),
        ("negatedName_enUS", 36, "s"), ("negatedDescription_enUS", 53, "s"),
    ]},
    # ChallengeRequirementTypes (22x41, lookup table): f0=id(1-22). f1=token. f2=name_enUS.
    # f19=description_enUS (templated, e.g. "You must complete the quest: ... before
    # reaching level ..."). ChallengeRequirements.requirementTypeToken (below) is a proven
    # 100% string-match link to this table's f1.
    "ChallengeRequirementTypes": {"expected_fields": 41, "columns": [
        ("id", 0, "u"), ("token", 1, "s"), ("name_enUS", 2, "s"), ("description_enUS", 19, "s"),
    ]},
    # ChallengeGroups (1203x3): f0=id (own row id, unique, sparse 1-5531). f1=challengeId,
    # golden-proven 100% row-level join vs Challenge.dbc ids (1203/1203). f2 (distinct 76,
    # range 1-221) has no provable semantics (no lookup table clears any bar) - left raw.
    "ChallengeGroups": {"expected_fields": 3, "columns": [
        ("id", 0, "u"), ("challengeId", 1, "u"),
    ]},
    # ChallengeLevels (1334x5): f0=id (own row id, unique, sparse 1-5022). f1=challengeId,
    # proven 84.9% raw row-level join vs Challenge.dbc ids (1133/1334; the brief's own
    # >=80% link-table gate) - the closest-to-threshold of all 8 link tables but still a
    # clean pass, and the remaining 199 rows are the value 0 ("unassigned") sentinel this
    # codebase already documents for other FK columns, not noise (99.8% join once 0 is
    # excluded: 1133/1135). f2 (distinct 63, 0-300), f3 (distinct 100, 1-100 - the SAME
    # distinct-100/range-1-100 shape recurs identically across Rules/Conditions/
    # Requirements/Rewards/Spells/MythicPlusScaling, never independently provable as
    # anything more specific than "a generic small parameter"), f4 (distinct 9, 0-2763)
    # have no provable semantics - left raw.
    "ChallengeLevels": {"expected_fields": 5, "columns": [
        ("id", 0, "u"), ("challengeId", 1, "u"),
    ]},
    # ChallengeRules (3646x5): f0=id. f1=challengeId, proven 93.5% raw (99.9% once the
    # value-0 sentinel is excluded: 3408/3410). f4=ruleTypeToken, proven 100% (3646/3646)
    # by STRING match against ChallengeRuleTypes.token - not a numeric FK: the brief's
    # natural "small numeric id" hypothesis (f2, distinct 12, 0-300) was tried and
    # DISPROVEN (only 6.3% raw / 97.5% on its own mostly-zero-sentinel nonzero subset,
    # much weaker and redundant with f4's clean 100% string proof) - f2 stays raw. f3 is
    # the same distinct-100/1-100 recurring column noted under ChallengeLevels - raw.
    "ChallengeRules": {"expected_fields": 5, "columns": [
        ("id", 0, "u"), ("challengeId", 1, "u"), ("ruleTypeToken", 4, "s"),
    ]},
    # ChallengeModifiers (2x8, tiny - only 2 challenges currently use a modifier).
    # f0=modifierTypeId, proven 100% (2/2) vs ChallengeModifierTypes ids. f1=challengeId,
    # proven 100% (2/2) vs Challenge.dbc ids. f2-f7 (mostly 0/constant/one float-looking
    # value) have no provable semantics on a 2-row sample - left raw.
    "ChallengeModifiers": {"expected_fields": 8, "columns": [
        ("modifierTypeId", 0, "u"), ("challengeId", 1, "u"),
    ]},
    # ChallengeConditions (354x10): f0=id. f1=challengeId, proven 91.2% raw (100% once the
    # value-0 sentinel is excluded: 323/323). NO conditionTypeId link is provable: every
    # remaining column (f2,f5,f6 and the always-zero f4/f7/f8/f9) was tested against
    # ChallengeConditionTypes ids and none clears any real bar (best real candidate f5's
    # nonzero subset: 0/144 - a hard disproof, its populated values cluster on 72/35/...,
    # nothing to do with the 18-row type table). Unlike Rules/Requirements, this table's
    # OWN string block is only 167 bytes (vs Rules' 4976 / Requirements' 3985) - too small
    # to carry a per-row denormalized type token, so there is no string-match escape hatch
    # either. Conditions ship with challengeId only; f2-f9 all raw, no type name resolved.
    "ChallengeConditions": {"expected_fields": 10, "columns": [
        ("id", 0, "u"), ("challengeId", 1, "u"),
    ]},
    # ChallengeRequirements (2047x9): f0=id. f1=challengeId, proven 99.9% raw (100% once
    # the value-0 sentinel is excluded: 2044/2044). f4=requirementTypeToken, proven 100%
    # (2033/2047 populated rows - the other 14 are 0/unset - all of which string-match
    # ChallengeRequirementTypes.token) - same string-match pattern as ChallengeRules.f4,
    # not a numeric FK (no numeric column clears any bar: best is f3 at 96.2% but f3 is
    # the ubiquitous distinct-100/1-100 generic parameter column, not a type id - its
    # values densely fill 1-100 while RequirementTypes only has 22 rows). f2,f3,f5,f6,f7,f8
    # (float-bit-pattern-looking large numbers and small counts, likely template
    # parameters for f4's description text) have no independently provable semantics -
    # left raw.
    "ChallengeRequirements": {"expected_fields": 9, "columns": [
        ("id", 0, "u"), ("challengeId", 1, "u"), ("requirementTypeToken", 4, "s"),
    ]},
    # ChallengeRewards (21677x11): f0=id. f1=challengeId, proven 97.1% raw (100% once the
    # value-0 sentinel is excluded: 21048/21048). Per the brief, "item-ish reward columns
    # stay f<N>" - f2-f10 (itemId/quantity/currency-looking numeric columns, one boolean)
    # carried raw, not decoded further.
    "ChallengeRewards": {"expected_fields": 11, "columns": [
        ("id", 0, "u"), ("challengeId", 1, "u"),
    ]},
    # ChallengeFeatured (54x5): f0=id. f2=challengeId, proven 100% (54/54) vs Challenge.dbc
    # ids. f1 (distinct 54, 0-53, near-bijective with row order - a UI ordering/season
    # index) and f3 (distinct 9, 0-402) have no independently provable semantics - raw.
    "ChallengeFeatured": {"expected_fields": 5, "columns": [
        ("id", 0, "u"), ("challengeId", 2, "u"),
    ]},
    # ChallengeSpells (7702x10): f0=id. f1=challengeId, proven 100% (7702/7702) vs
    # Challenge.dbc ids. f5=spellId, proven 100% on its populated subset (802/802 nonzero
    # rows join Spell.dbc) AND semantically corroborated: 72.7% of the resolved spell
    # names literally embed the OWNING challenge's own name plus a colorized "Tier N"
    # suffix (e.g. challenge 25 "Fleeting" -> spell 207 "Fleeting\n|cFF1EFF0CTier 1|r") -
    # not the colorized-tooltip-garbage false positive documented elsewhere in this
    # codebase (SpellAddon, CharacterCreationPetDetails), because the text is legibly
    # on-theme rather than unrelated fragments. f4 (distinct 7526, populated on ALL 7702
    # rows but only 19.4% join Spell.dbc ids, and its resolved names are the same
    # Tier-N pattern for the subset that DOES join) looks like a stale/legacy duplicate of
    # f5 - left raw, not named, since it clears no join-rate bar. f2 (always 0), f3 (the
    # recurring distinct-100/1-100 column), f6-f9 (near-constant/boolean) - raw.
    "ChallengeSpells": {"expected_fields": 10, "columns": [
        ("id", 0, "u"), ("challengeId", 1, "u"), ("spellId", 5, "u"),
    ]},
    # ChallengeGroupRewards (144x10): f0 is NOT its own independent PK - golden-proven to
    # reuse ChallengeGroups' OWN id space (this table keys directly by challengeGroupId,
    # awarding a reward for completing that group). Two candidate id spaces were tested
    # (both pass a naive "is this a valid id" check near-100%, since both tables' id
    # spaces are ~72-77% dense over 1-653): chaining through ChallengeGroups.challengeId
    # resolves 135/144=93.75% of rows to a real Challenge (and every row whose f0 is a
    # valid ChallengeGroups id ALSO resolves via that group's already-100%-proven
    # challengeId - a fully coherent chain), whereas chaining through
    # ChallengeLevels.challengeId only resolves 72/144=50% (weaker, and the naive 100%
    # id-membership figure was mostly the ~72% background density of small integers being
    # valid Levels ids too - the same false-positive class as this codebase's other dense-
    # id-space findings). f0 is therefore named groupId, not levelId. f4=expansionToken,
    # proven (distinct 3: EXPANSION_CLASSIC/THE_BURNING_CRUSADE/WRATH_OF_THE_LICH_KING - a
    # plain string lookup, trivially decoded). f1(distinct 6, 1-54), f2(always 1),
    # f3(distinct 8, 1-8), f5(always 18), f6(distinct 48, itemId-ish per the brief's
    # "item-ish reward columns stay f<N>"), f7(always 1), f8(always 0), f9(always
    # 1000000, a gold-amount-looking sentinel) - all raw, not decoded further.
    "ChallengeGroupRewards": {"expected_fields": 10, "columns": [
        ("groupId", 0, "u"), ("expansionToken", 4, "s"),
    ]},
    # MythicKeystones (6801x3): f0=id (own row id, sparse, no further semantics needed).
    # f1=dungeonId, proven 98.5% row-level join vs LFGDungeons.dbc ids (6700/6801 - the
    # remainder are non-dungeon/test map ids, same class of residual noise documented
    # throughout this codebase). f2=level (0-100, matches the real WotLK-era Mythic+
    # keystone-level concept; corroborated by MythicPlusScaling.level using the identical
    # 1-100 range).
    "MythicKeystones": {"expected_fields": 3, "columns": [
        ("id", 0, "u"), ("dungeonId", 1, "u"), ("level", 2, "u"),
    ]},
    # MythicAffixes (13409x16): f0=id. The brief's own hypothesis ("affix name source =
    # ChallengeModifierTypes if join proves it") was tested and DISPROVEN - no column
    # clears any join-rate bar against ChallengeModifierTypes' 8 rows. Instead
    # grantSpellId(f3)/effectSpellId1-3(f11-f13) all prove out 100% against Spell.dbc on
    # their populated subsets, with clean on-theme resolved names ("Pack Tactics",
    # "Fast", "Resistant", "Life Stealing", "True Sight", "Avenger", "Horde", "Tiny") -
    # these ARE the de-facto affix names/effects, used instead of the disproven
    # ChallengeModifierTypes route. f1 (distinct 53, 0-52, exactly 253 rows per value -
    # a real structural dimension, likely an affix-slot index) and f2 (distinct 253,
    # 2-254) have no independently provable NAME/semantic (no lookup table of the right
    # size exists) - left raw despite the clean structural regularity, per the empirical
    # rule (structural regularity alone is not a golden). f4-f10,f14 (always 0), f15
    # (always the float bit-pattern for 1.0) - raw.
    "MythicAffixes": {"expected_fields": 16, "columns": [
        ("id", 0, "u"), ("grantSpellId", 3, "u"),
        ("effectSpellId1", 11, "u"), ("effectSpellId2", 12, "u"), ("effectSpellId3", 13, "u"),
    ]},
    # MythicPlusScaling (200x8): f0=id (own row id, 0-199, ascending). f1=level, proven by
    # direct row inspection (ascending 1,2,3,...,100 repeated twice across the 200 rows,
    # i.e. 2 scaling categories x 100 levels) and corroborated by the identical 1-100
    # range MythicKeystones.level uses. f2(always 0), f3/f5 (identical increasing-curve
    # values, distinct 100, likely a health/damage scalar), f4(always 0), f6(distinct 100,
    # a second increasing curve), f7(distinct 3, 0-14) have no independently provable
    # semantics - left raw.
    "MythicPlusScaling": {"expected_fields": 8, "columns": [
        ("id", 0, "u"), ("level", 1, "u"),
    ]},
    # TimedDungeons (82x6): f0=dungeonId, golden-proven - raw row-level join vs
    # LFGDungeons.dbc ids is 84.1% (69/82); the 13 misses all sit in the same anomalous
    # dev/test id block 2001-2028, and none resolves against LFGDungeons.dbc or Map.dbc.
    # 12 of the 13 share the IDENTICAL placeholder payload [36,20,20,7800000,1.0] (one,
    # 2001, even resolves against Map.dbc to the literal name "This is a REAL map" / a row
    # named "MyInternalTest4"); the 13th (id 2002) has a different payload
    # [283,8,2,3480000,1.0] but is still in the same 2001-2028 block and still resolves to
    # no dungeon - excluding these 13 documented non-dungeon rows, the join is 69/69 =
    # 100%, and every one resolves to a real classic/TBC dungeon name (Lower Scholomance,
    # Auchenai Crypts, Mana-Tombs, ...); the raw 84.1% join rate alone already clears the
    # brief's gate without relying on this exclusion. f4=timeLimitMs, corroborated
    # semantically: values range 1.6M-7.8M ms (26.7-130 min) and line up with real
    # per-dungeon run-time expectations (e.g. dungeonId 53 "Lower Scholomance" carries
    # 1896000ms = 31.6 min). f1(distinct 50, 0-1000), f2(distinct 9, 1-20), f3(distinct 4,
    # 0-20), f5(always the float bit-pattern for 1.0) - raw.
    "TimedDungeons": {"expected_fields": 6, "columns": [
        ("dungeonId", 0, "u"), ("timeLimitMs", 4, "u"),
    ]},
    # MapDifficulty (685x23): not named in the brief's V2-5 output schema, but included in
    # this task's mapping-evidence file list and cleanly provable, so curated too. f0=id.
    # f1=mapId, proven 97.5% row-level join vs Map.dbc ids (668/685). f2=difficultyIndex
    # (0-3, matches WotLK's per-map difficulty-tier concept). f3=lockoutMessage_enUS
    # (distinct 35, e.g. "Mythic Difficulty requires you to be level 70." - the literal
    # string that first suggested this table was in-scope for the Mythic+ pack).
    # f22=difficultyToken (distinct 8: DUNGEON_DIFFICULTY_5PLAYER[_HEROIC/_EPIC],
    # RAID_DIFFICULTY_10PLAYER_HEROIC/25PLAYER[_HEROIC]/40PLAYER). f4-f18 (LangString
    # filler block for f3), f19-f21 (a color-looking constant, a lockout-duration-looking
    # value, a small count) have no independently provable semantics - raw.
    "MapDifficulty": {"expected_fields": 23, "columns": [
        ("id", 0, "u"), ("mapId", 1, "u"), ("difficultyIndex", 2, "u"),
        ("lockoutMessage_enUS", 3, "s"), ("difficultyToken", 22, "s"),
    ]},
    # v3 (task V3-1): proven via golden-record probes (see .superpowers/sdd/task-v3-1-report.md).
    # Manastorm (1017x9, no strings): f0 ascending-unique 1-1212 (id). f1 golden-proven
    # mapId: 100% (73/73) of its distinct values are valid Map.dbc ids AND every single
    # one resolves to a real classic/TBC/WotLK dungeon or raid zone name (Shadowfang Keep,
    # Deadmines, Molten Core, Blackwing Lair, Naxxramas, Hellfire Citadel wings, ...) - not
    # a density coincidence (Map.dbc is only 374/4000 = 9.4% dense over f1's own 33-1806
    # range, so 73/73 random hits would be astronomically unlikely). f3 golden-proven
    # dungeonEncounterId: 99.5% (1012/1017) resolve against DungeonEncounter.dbc ids, and
    # of those, 100% (1012/1012) have the resolved encounter's OWN mapID column equal to
    # this row's f1 (a full two-hop chain validation, not just membership) - e.g. Manastorm
    # rows with mapId=33 (Shadowfang Keep) resolve f3 to exactly SFK's 7 real bosses
    # (Rethilgore, Baron Silverlaine, Commander Springvale, Odo the Blindwatcher, Fenrus the
    # Devourer, Wolf Master Nandos, Archmage Arugal). The 5 unresolved rows all carry
    # f3=0 - the same "0 = unassigned sentinel" pattern this codebase documents elsewhere
    # (DungeonEncounterExtra, ChallengeGroups/Levels/Rules/...). f2 golden-proven difficulty:
    # 0 mismatches across all 1012 resolved rows against the resolved DungeonEncounter row's
    # OWN "difficulty" column (values are the identical {0,2} set) - e.g. encounter 464
    # "Rethilgore" has difficulty=0 and its paired variant 2464 (same name, same mapID) has
    # difficulty=2, matching Manastorm's own f2 for the rows referencing each. f4-f8 are
    # IEEE-754 floats (empirically obvious: sequential rows show canonical values like 1.0/
    # 0.125/10.0; f7 is a 200-distinct "weight"-looking value 0.125-1.95, plausibly a random-
    # selection weight) but have NO provable per-row semantic identity or lookup-table target -
    # left raw (carried as signed ints, not float-decoded, per the empirical rule - "unproven"
    # covers both meaning AND wire-type interpretation).
    "Manastorm": {"expected_fields": 9, "columns": [
        ("id", 0, "u"), ("mapId", 1, "u"), ("difficulty", 2, "u"), ("dungeonEncounterId", 3, "u"),
    ]},
    # ManastormMessages (291x39): f0 ascending-unique 1-1206 (id). f4 golden-proven iconToken
    # (string_likelihood 1.0, samples are real texture-path tokens like
    # "inv_misc_stormdragonpale"). f5 golden-proven a short notification title (string_
    # likelihood 1.0, e.g. "Unlocked Iskarr Village!"). f22 golden-proven the full message
    # text (string_likelihood 1.0, e.g. "You have unlocked Iskarr Village in your next
    # Manastorm!" - literally contains "Manastorm", the brief's requested seasonal-flavor
    # golden). f6-f21 and f23-f38 (32 columns total, exactly two 16-column blocks) are the
    # LangString locale-filler pattern already documented elsewhere in this file (Challenge.
    # dbc etc.) - every row carries the SAME constant value (50, decoding to the empty
    # string) across all 32 columns, i.e. zero information (this build only populates
    # enUS); dropped from output entirely, not even carried raw. f1 (2 distinct: {0,2}) is
    # the SAME value domain as Manastorm.difficulty and behaves identically here (id 1 and
    # its exact content-duplicate id 12 differ ONLY in f1, 0 vs 2) - strong circumstantial
    # match to the same seasonal-tier concept, but NOT independently provable within this
    # table alone (no DungeonEncounter-style cross-table anchor exists for messages) - left
    # raw, not named. f2 (187 distinct, 5-102550) was hypothesized as a spellId - DISPROVEN:
    # 90.4% raw join rate against Spell.dbc but the resolved "spells" are unrelated ancient
    # low-id test/base spells ("Heal Self (TEST)", "Blizzard", "Stun") with zero thematic
    # connection to the message text - a textbook Spell.dbc low-id density false positive
    # (same class as this codebase's other disproven joins). f3 (19 distinct, 0-730) was
    # hypothesized as an areaId - DISPROVEN the same way: 92.2% of the 153 nonzero rows
    # (48.5% of all 291 rows - ~47% carry the 0 sentinel) join against AreaTable.dbc,
    # but resolved area names (e.g. "Silverpine Forest", "Coldridge Valley")
    # bear no relation to the grouped messages' actual content (Zul'Gurub bosses, Molten
    # Core bosses) - a density false positive, not a real link (AreaTable's low-id range is
    # densely populated by classic zones). f3's nonzero values DO cleanly group messages by
    # real content pack (130=Zul'Gurub, 132=Molten Core, 134=Blackwing Lair, 135=AQ20,
    # 137=AQ40, 139=Naxxramas) - a genuine internal grouping structure, but no WANTED_DBCS
    # lookup table exists to independently prove what f3's own id space names, so it stays
    # raw. f2's large outlier values for endgame unlocks (102550 "Heroic Sunwell Plateau
    # Items", 102400 "Sunwell Plateau Items") are consistent with an unlock-point-threshold
    # hypothesis but this is not provable via any join - left raw.
    "ManastormMessages": {"expected_fields": 39, "columns": [
        ("id", 0, "u"), ("iconToken", 4, "s"), ("title_enUS", 5, "s"), ("text_enUS", 22, "s"),
    ]},
    # ManastormModifiers (32768x15, no strings): f0 ascending-unique 1-32768 (id) - the
    # brief's only required proof for this table besides a spellId check. No spellId
    # column exists: every other column is either a tiny-range int (f1 in {0,2}, f2 a
    # 1-16384 "level" index, f7/f9 always 0, f14 a 0/1 flag) or an IEEE-754 float in a
    # small numeric range (f3-f6,f8,f10-f13, empirically obvious from smooth sequential
    # progressions like 5.0/5.075/5.15/... and clean values like -20.0/10.0/1.0) - none
    # remotely resembles Spell.dbc's id space (which runs into the millions). Structural
    # observation (not a proof, no lookup table exists to verify against): rows come in
    # id-adjacent pairs sharing the same f2 "level" value with f1 alternating 0/2 (the
    # same value domain as Manastorm.difficulty) - looks like a precomputed two-tier
    # (Normal/Heroic-style) scaling-curve table keyed by an internal level/stack index,
    # not by any external entity id. All non-id columns left raw (signed, not float-
    # decoded - see Manastorm's f4-f8 comment for the same "unproven covers wire-type too"
    # rationale).
    "ManastormModifiers": {"expected_fields": 15, "columns": [
        ("id", 0, "u"),
    ]},
    # ManastormPlayerGroupModifiers (15x5, no strings): f0 ascending-unique 1-15 (id).
    # f1 is bit-for-bit IDENTICAL to f0 on every row (no distinguishing evidence that it
    # carries independent information - could be "group size" given the table's name, but
    # that is a naming guess, not a provable identity distinct from f0) - left raw, not
    # renamed. f2 always 0. f3/f4 are IDENTICAL to each other per row, a float curve
    # climbing 1.0->1.4 over ids 1-5 then plateauing at 1.4 for ids 6-15 - the same class
    # of finding as MythicPlusScaling's f3/f5 ("likely a health/damage scalar... left
    # raw"). No lookup table exists to independently verify any of f1-f4 - all left raw.
    "ManastormPlayerGroupModifiers": {"expected_fields": 5, "columns": [
        ("id", 0, "u"),
    ]},
}


def _open_checked(table: str, dbc_dir: Path = None) -> tuple[DBCFile, dict]:
    """dbc_dir defaults to config.WORK_DBC_DIR (base client). Task V3-2 passes an
    explicit realm dbc dir (work/realms/<realm>/dbc) so the SAME base TABLE_MAPS
    column map + layout guard apply to a realm-overlay DBC of the same name."""
    spec = TABLE_MAPS[table]
    d = dbc_dir if dbc_dir is not None else config.WORK_DBC_DIR
    f = DBCFile(d / f"{table}.dbc")
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


def iter_named(table: str, dbc_dir: Path = None):
    f, spec = _open_checked(table, dbc_dir)
    cols = spec["columns"]
    for row in f.iter_rows():
        yield {name: _decode(f, row, name, idx, kind) for name, idx, kind in cols}


def dump_table(table: str, dbc_dir: Path = None, out_dir: Path = None) -> Path:
    """dbc_dir/out_dir default to config.WORK_DBC_DIR/config.RAW_DBC_DIR (base
    client's dump_all() behavior). Task V3-2 passes explicit realm paths so a
    mapped realm-overlay table dumps to raw/realms/<realm>/dbc/ instead."""
    f, spec = _open_checked(table, dbc_dir)
    named = {idx: (name, idx, kind) for name, idx, kind in spec["columns"]}
    header = [named[i][0] if i in named else f"f{i}" for i in range(f.fields)]
    d = out_dir if out_dir is not None else config.RAW_DBC_DIR
    d.mkdir(parents=True, exist_ok=True)
    out = d / f"{table}.csv.gz"
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


def dump_unmapped(table: str, out_dir: Path = None, dbc_dir: Path = None) -> Path:
    """Dump a table with no TABLE_MAPS entry as raw signed ints (f0..fN) plus
    a colinfo.json evidence sidecar: per-column distinct/min/max/pct_zero and
    a string-likelihood score (fraction of rows whose value is a plausible
    string-block offset), with up to 3 decoded samples for string-likely
    columns. This is the mapping-evidence trail for later empirical curation.

    out_dir defaults to config.RAW_DBC_DIR (dump_all()'s behavior). Callers
    that just want to inspect/verify a dump (e.g. tests) should pass a
    scratch dir instead, so they don't clobber committed raw/ artifacts -
    especially for tables that HAVE since become mapped, where this
    unmapped f0..fN shape would corrupt the committed named-header dump.

    dbc_dir defaults to config.WORK_DBC_DIR (base client). Task V3-2 passes an
    explicit realm dbc dir to colinfo-dump a realm-only table (no base
    TABLE_MAPS entry, e.g. CharacterAdvancement/SpellRank).
    """
    if out_dir is None:
        out_dir = config.RAW_DBC_DIR
    out_dir.mkdir(parents=True, exist_ok=True)
    d = dbc_dir if dbc_dir is not None else config.WORK_DBC_DIR
    f = DBCFile(d / f"{table}.dbc")
    n = f.fields
    strblock_size = len(f._strings)
    records = f.records

    distinct = [set() for _ in range(n)]
    mins = [None] * n
    maxs = [None] * n
    zeros = [0] * n
    strlike = [0] * n
    samples = [[] for _ in range(n)]

    out = out_dir / f"{table}.csv.gz"
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
    (out_dir / f"{table}.colinfo.json").write_text(
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
