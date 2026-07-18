"""Generic WDBC (3.3.5) reader, named column maps, and raw CSV dumps."""
import csv, gzip, struct
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
        # NOTE: unlike the "canonical" WDBC convention of reserving offset 0 as
        # the empty-string sentinel, this build's exported string blocks place
        # real content directly at offset 0 (verified across ChrClasses,
        # ChrRaces, SpellDispelType, SpellMechanic, SpellRange, TalentTab: none
        # have a leading NUL byte). Empty-string references instead land on a
        # NUL byte elsewhere in the blob (e.g. SpellDispelType offset 5, between
        # "None" and "Magic"), which the index(b"\x00", offset) lookup below
        # already resolves to "" correctly. So only offset < 0 is invalid here;
        # treating offset == 0 as empty would silently drop real strings (e.g.
        # ChrClasses id=1 "Warrior" sits at true offset 0).
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
    with gzip.open(out, "wt", encoding="utf-8", newline="") as fh:
        w = csv.writer(fh)
        w.writerow(header)
        for row in f.iter_rows():
            w.writerow([
                _decode(f, row, *named[i]) if i in named else row[i]
                for i in range(f.fields)
            ])
    return out


def dump_all():
    config.ensure_dirs()
    for table in sorted(TABLE_MAPS):
        p = dump_table(table)
        print(f"dumped {p.name}")


if __name__ == "__main__":
    dump_all()
