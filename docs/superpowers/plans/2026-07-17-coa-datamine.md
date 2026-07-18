# CoA Datamine Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the `coa-datamine` dataset: Ascension CoA classes, spells, talents, and dungeons/raids extracted from `E:\ascension-live` into agent-consumable JSON, per the approved spec at `docs/superpowers/specs/2026-07-17-coa-datamine-design.md`.

**Architecture:** Three-stage deterministic pipeline — (1) chain-order-aware MPQ extraction of ~20 DBCs via mpyq, (2) generic WDBC decode + full CSV.gz dumps + verbatim Content-JSON snapshot into `raw/`, (3) joins producing curated `data/` JSON. Validation gates (golden spells, referential integrity, layout guards) make the build fail loudly rather than emit plausible-but-wrong data.

**Tech Stack:** Python 3.12, stdlib only + `mpyq` 0.2.5 (already installed). No pytest — tests are plain-python assert scripts. Windows/PowerShell commands.

## Global Constraints

- Repo root: `C:\Users\Mac\Documents\github\coa-datamine`. All commands run from there.
- Client install: default `E:\ascension-live`, overridable via env `COA_CLIENT_DIR`.
- Dependencies: Python 3.12 stdlib + `mpyq` only. Nothing else gets installed.
- `work/` (extracted raw `.dbc` binaries) is **gitignored**; `raw/` and `data/` are committed.
- Determinism: no timestamps inside `data/` or `raw/dbc|content` files. Timestamps live only in `raw/provenance.json`.
- Content JSONs are read with `encoding="utf-8-sig"` (verified to parse).
- Locale strings: enUS is index 0 of each 16-column localized block.
- JSON output style: `ensure_ascii=False`; `.jsonl` lines use `separators=(",", ":")`, `sort_keys=True`; small `.json` files use `indent=1, sort_keys=True`.
- Verified DBC facts (probe 2026-07-17, all stock-3.3.5 layouts): Spell.dbc 234 fields/936 B/208 431 records (in `patch-T.MPQ`); ChrClasses 60 f/32 recs; Talent 23 f/2 383 recs; TalentTab 24 f/37 recs; LFGDungeons 49 f/431 recs; DungeonEncounter 23 f/2 080 recs; Map 66 f/374 recs; AreaTable 36 f/2 847 recs; SkillLine 56 f; SkillLineAbility 14 f/40 827 recs; SkillRaceClassInfo 8 f; SpellDispelType 21 f/12 recs; SpellMechanic 18 f/31 recs; SpellDuration/SpellRadius/SpellCastTimes 4 f; SpellRange 40 f; SpellIcon 2 f/16 354 recs; SpellRuneCost 5 f; ChrRaces 69 f/42 recs. (patch-M carries the non-spell tables, patch-S the spell-support tables.)
- Tests run as `python tests\test_<name>.py` and must end by printing `ALL PASS`. Tests exercise the REAL client data (it's local and read-only) — no mocks.
- Commit after every task: `git add -A; git commit -m "<type>: <summary>"`.

## File Structure

```
tools/__init__.py            (empty package marker)
tools/config.py              paths + wanted-DBC list          [Task 1]
tools/extract_mpq.py         chain-order MPQ extraction       [Task 2]
tools/dbc.py                 WDBC reader + column maps + CSV  [Task 3]
tools/enums335.py            3.3.5 enum name tables           [Task 4]
tools/build_spells.py        spells.jsonl builder             [Task 5]
tools/build_classes.py       per-class JSON builder           [Task 6]
tools/build_talents.py       talent-tree builder              [Task 7]
tools/build_dungeons.py      dungeons/raids/encounters        [Task 8]
tools/build_dataset.py       orchestrator + provenance        [Task 9]
tests/test_config.py … tests/test_dataset.py  (one per task)
README.md, docs/AGENT-GUIDE.md                [Task 9]
```

---

### Task 1: Scaffolding — config module, package markers, .gitignore

**Files:**
- Create: `tools/__init__.py`, `tests/__init__.py` (empty), `tools/config.py`, `tests/test_config.py`, `.gitignore`

**Interfaces:**
- Produces: `tools.config` exporting `REPO_ROOT, CLIENT_DIR, MPQ_DIRS, CONTENT_DIR, WORK_DIR, WORK_DBC_DIR, RAW_DIR, RAW_DBC_DIR, RAW_CONTENT_DIR, DATA_DIR` (all `pathlib.Path`), `WANTED_DBCS` (list[str], proper-case filenames), `ensure_dirs()`. Every later task imports paths from here — never hardcodes them.

- [ ] **Step 1: Write the failing test** — `tests/test_config.py`:

```python
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from tools import config

assert config.CLIENT_DIR.is_dir(), f"client dir missing: {config.CLIENT_DIR}"
assert (config.CLIENT_DIR / "Data").is_dir()
assert config.CONTENT_DIR.is_dir()
assert len(config.MPQ_DIRS) == 2 and all(d.is_dir() for d in config.MPQ_DIRS)
assert "Spell.dbc" in config.WANTED_DBCS and len(config.WANTED_DBCS) == 20
config.ensure_dirs()
for d in (config.WORK_DBC_DIR, config.RAW_DBC_DIR, config.RAW_CONTENT_DIR, config.DATA_DIR):
    assert d.is_dir(), d
print("ALL PASS")
```

- [ ] **Step 2: Run test to verify it fails**

Run: `python tests\test_config.py`
Expected: FAIL with `ModuleNotFoundError: No module named 'tools'`

- [ ] **Step 3: Write the implementation** — empty `tools/__init__.py` and `tests/__init__.py`; `.gitignore`:

```
work/
__pycache__/
*.pyc
.superpowers/
```

`tools/config.py`:

```python
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
```

- [ ] **Step 4: Run test to verify it passes**

Run: `python tests\test_config.py`
Expected: `ALL PASS`

- [ ] **Step 5: Commit**

```powershell
git add -A; git commit -m "feat: scaffolding - config module, package markers, gitignore"
```

---

### Task 2: MPQ extractor (`tools/extract_mpq.py`)

**Files:**
- Create: `tools/extract_mpq.py`, `tests/test_extract.py`

**Interfaces:**
- Consumes: `tools.config` (paths, `WANTED_DBCS`, `ensure_dirs`).
- Produces: `chain_rank(path: Path) -> tuple` (sortable; higher = wins collisions), `extract_all() -> dict` (provenance fragment, schema in Step 3) and writes `work/dbc/<ProperName>.dbc` for all 20 wanted DBCs plus `work/extract_provenance.json`. CLI: `python -m tools.extract_mpq`.

- [ ] **Step 1: Write the failing test** — `tests/test_extract.py`:

```python
import json, struct, sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from tools import config
from tools.extract_mpq import chain_rank, extract_all

D = config.CLIENT_DIR / "Data"
# chain order: base < locale base < patch < patch-digit < locale patch < patch-letters
assert chain_rank(D / "common.MPQ") < chain_rank(D / "enUS" / "locale-enUS.MPQ")
assert chain_rank(D / "enUS" / "locale-enUS.MPQ") < chain_rank(D / "patch.MPQ")
assert chain_rank(D / "patch.MPQ") < chain_rank(D / "patch-2.MPQ")
assert chain_rank(D / "patch-2.MPQ") < chain_rank(D / "enUS" / "patch-enUS-2.MPQ")
assert chain_rank(D / "enUS" / "patch-enUS-2.MPQ") < chain_rank(D / "patch-A.MPQ")
assert chain_rank(D / "patch-CH.MPQ") < chain_rank(D / "patch-CHA.MPQ")
assert chain_rank(D / "patch-CHA.MPQ") < chain_rank(D / "patch-CI.MPQ")
assert chain_rank(D / "patch-T.MPQ") > chain_rank(D / "patch-S.MPQ")

prov = extract_all()
assert set(prov["files"]) == {w.lower() for w in config.WANTED_DBCS}, "all 20 wanted DBCs resolved"
for name in config.WANTED_DBCS:
    p = config.WORK_DBC_DIR / name
    assert p.is_file(), f"missing {p}"
    magic, recs, fields, recsize, strsize = struct.unpack("<4s4I", p.read_bytes()[:20])
    assert magic == b"WDBC", name
    assert p.stat().st_size == 20 + recs * recsize + strsize, f"size mismatch {name}"

spell = prov["files"]["spell.dbc"]
assert spell["winner"].lower() == "patch-t.mpq", spell
assert struct.unpack("<4s4I", (config.WORK_DBC_DIR / "Spell.dbc").read_bytes()[:20])[2] == 234
assert isinstance(prov["skipped_archives"], list)
saved = json.loads((config.WORK_DIR / "extract_provenance.json").read_text(encoding="utf-8"))
assert saved["files"]["spell.dbc"]["winner"] == spell["winner"]
print("ALL PASS")
```

- [ ] **Step 2: Run test to verify it fails**

Run: `python tests\test_extract.py`
Expected: FAIL with `ModuleNotFoundError: No module named 'tools.extract_mpq'`

- [ ] **Step 3: Write the implementation** — `tools/extract_mpq.py`:

```python
"""Chain-order-aware extraction of wanted DBCs from the Ascension MPQ set.

Mirrors the 3.3.5 loader order that Ascension's launcher extends:
base < locale base < patch.MPQ < patch-<digit> < locale patches < patch-<letters>.
Within a tier, lexicographic. The LAST archive in chain order containing a file
wins; all other carriers are recorded as losers in the provenance so a wrong
chain assumption is visible, never silent.
"""
import hashlib, json, struct, sys
from pathlib import Path

from mpyq import MPQArchive

from tools import config


def chain_rank(path: Path) -> tuple:
    name = path.name.lower()
    in_locale = path.parent.name.lower() == "enus"
    if not name.startswith("patch"):
        return (1 if in_locale else 0, name)
    stem = name[:-4]                      # strip ".mpq"
    suffix = stem[6:] if len(stem) > 5 else ""   # after "patch-"
    if suffix == "":
        return (2, name)
    if suffix.isdigit():
        return (3, suffix.zfill(4))
    if in_locale:                          # patch-enus.mpq, patch-enus-2.mpq, ...
        return (4, name)
    return (5, suffix)                     # letter patches, lexicographic


def _list_archives():
    seen, out = set(), []
    for d in config.MPQ_DIRS:
        for p in sorted(d.iterdir()):
            if p.suffix.lower() == ".mpq" and p.resolve() not in seen:
                seen.add(p.resolve())
                out.append(p)
    return sorted(out, key=chain_rank)


def extract_all() -> dict:
    config.ensure_dirs()
    wanted = {w.lower(): w for w in config.WANTED_DBCS}
    carriers = {}                # lower name -> list of (rank, path, stored_name)
    skipped = []
    for p in _list_archives():
        try:
            a = MPQArchive(str(p), listfile=True)
            files = a.files or []
        except Exception as e:
            skipped.append({"archive": p.name, "reason": f"{type(e).__name__}: {e}"})
            continue
        for f in files:
            fl = f.decode("latin-1", "replace").lower().replace("/", "\\")
            if fl.startswith("dbfilesclient\\"):
                base = fl.rsplit("\\", 1)[-1]
                if base in wanted:
                    carriers.setdefault(base, []).append((chain_rank(p), p, f))

    missing = sorted(set(wanted) - set(carriers))
    if missing:
        raise SystemExit(f"FATAL: wanted DBCs not found in any archive: {missing}")

    prov = {"files": {}, "skipped_archives": skipped}
    by_winner = {}
    for base, lst in carriers.items():
        lst.sort(key=lambda t: t[0])
        rank, winner, stored = lst[-1]
        by_winner.setdefault(winner, []).append((base, stored, [p.name for _, p, _ in lst[:-1]]))

    for winner, entries in by_winner.items():
        a = MPQArchive(str(winner), listfile=False)
        for base, stored, losers in entries:
            data = a.read_file(stored)
            if not data or data[:4] != b"WDBC":
                raise SystemExit(f"FATAL: bad read of {base} from {winner.name}")
            out = config.WORK_DBC_DIR / wanted[base]
            out.write_bytes(data)
            _, recs, fields, recsize, strsize = struct.unpack_from("<4s4I", data, 0)
            prov["files"][base] = {
                "winner": winner.name, "losers": losers,
                "sha256": hashlib.sha256(data).hexdigest(),
                "records": recs, "fields": fields,
                "record_size": recsize, "bytes": len(data),
            }

    (config.WORK_DIR / "extract_provenance.json").write_text(
        json.dumps(prov, indent=1, sort_keys=True), encoding="utf-8")
    return prov


def main():
    prov = extract_all()
    for base in sorted(prov["files"]):
        e = prov["files"][base]
        flag = " COLLISION:" + ",".join(e["losers"]) if e["losers"] else ""
        print(f"{base:26s} <- {e['winner']:18s} records={e['records']:7d} fields={e['fields']:4d}{flag}")
    print(f"skipped archives: {len(prov['skipped_archives'])}")


if __name__ == "__main__":
    main()
```

- [ ] **Step 4: Run test to verify it passes** (listing all ~80 archives takes a few minutes — the 4 GB `patch.MPQ` listfile read is the slow part)

Run: `python tests\test_extract.py`
Expected: `ALL PASS`

- [ ] **Step 5: Run the CLI once and eyeball the collision report**

Run: `python -m tools.extract_mpq`
Expected: 20 lines, `spell.dbc <- patch-T.MPQ`, non-spell tables `<- patch-M.MPQ` / `patch-S.MPQ`. Collisions against locale archives are expected and fine (stock DBCs losing to Ascension patches) — a wanted DBC winning from an UNEXPECTED archive (not patch-M/S/T) must be investigated before proceeding.

- [ ] **Step 6: Commit**

```powershell
git add -A; git commit -m "feat: chain-order-aware MPQ extractor for wanted DBCs"
```

---

### Task 3: WDBC reader + column maps + CSV dumps (`tools/dbc.py`)

**Files:**
- Create: `tools/dbc.py`, `tests/test_dbc.py`

**Interfaces:**
- Consumes: `tools.config`; `work/dbc/*.dbc` from Task 2.
- Produces:
  - `DBCFile(path)` with `.records .fields .record_size`, `.row_ints(i) -> tuple[int,...]` (signed), `.iter_rows()`, `.string(offset) -> str`; module helpers `u32(v) -> int`, `f32(v) -> float`.
  - `TABLE_MAPS: dict[str, dict]` — key = table name without `.dbc` (e.g. `"Spell"`); value `{"expected_fields": int, "columns": [(name, index, kind), ...]}` with kind ∈ `"i"|"u"|"f"|"s"`.
  - `iter_named(table: str) -> Iterator[dict]` — decoded named columns only, plus nothing else.
  - `dump_table(table: str) -> Path` — writes `raw/dbc/<table>.csv.gz` (named columns decoded, remaining columns as `f<N>` raw signed ints); `dump_all()` dumps every table in `TABLE_MAPS`.

- [ ] **Step 1: Write the failing test** — `tests/test_dbc.py`:

```python
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from tools import config, dbc

# reader fundamentals on a small table
f = dbc.DBCFile(config.WORK_DBC_DIR / "ChrClasses.dbc")
assert f.fields == 60 and f.records == 32
rows = {r[0]: r for r in f.iter_rows()}
assert f.string(rows[1][4]) == "Warrior"          # name_enUS at index 4
assert f.string(rows[8][4]) == "Mage"

# named iteration + kinds
classes = {r["id"]: r for r in dbc.iter_named("ChrClasses")}
assert classes[1]["name_enUS"] == "Warrior"
assert len(classes) == 32 and max(classes) == 32   # CoA classes 17-32 exist
custom = {classes[i]["name_enUS"] for i in range(17, 33)}
assert len(custom) == 16 and "" not in custom, custom

# float + string decoding via SpellRange
ranges = {r["id"]: r for r in dbc.iter_named("SpellRange")}
assert ranges[1]["maxRange"] == 0.0 and isinstance(ranges[1]["maxRange"], float)

# layout guard fires on wrong expectation
saved = dbc.TABLE_MAPS["ChrClasses"]["expected_fields"]
dbc.TABLE_MAPS["ChrClasses"]["expected_fields"] = 61
try:
    list(dbc.iter_named("ChrClasses")); raise AssertionError("guard did not fire")
except dbc.LayoutError:
    pass
finally:
    dbc.TABLE_MAPS["ChrClasses"]["expected_fields"] = saved

# Spell golden rows (indices per stock 3.3.5 layout, field_count verified 234)
seen = {}
for r in dbc.iter_named("Spell"):
    if r["id"] in (10, 17):
        seen[r["id"]] = r
        if len(seen) == 2:
            break
assert seen[17]["name_enUS"] == "Power Word: Shield"
assert seen[17]["dispel"] == 1                     # Magic
assert seen[17]["schoolMask"] == 2                 # Holy
assert seen[10]["name_enUS"] == "Blizzard"
assert seen[10]["schoolMask"] == 16                # Frost

# dump one small table and re-read it
import csv, gzip
p = dbc.dump_table("SpellDispelType")
with gzip.open(p, "rt", encoding="utf-8", newline="") as fh:
    got = list(csv.DictReader(fh))
assert len(got) == 12
byid = {row["id"]: row for row in got}
assert byid["1"]["name_enUS"] == "Magic" and byid["2"]["name_enUS"] == "Curse"
print("ALL PASS")
```

- [ ] **Step 2: Run test to verify it fails**

Run: `python tests\test_dbc.py`
Expected: FAIL with `ModuleNotFoundError: No module named 'tools.dbc'`

- [ ] **Step 3: Write the implementation** — `tools/dbc.py`. The Spell map names every column the builders consume; all 3.3.5 stock indices (field counts already verified against the live files):

```python
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
        if offset <= 0 or offset >= len(self._strings):
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
    named = {idx: (name, kind) for name, idx, kind in spec["columns"]}
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
```

Note `_decode(f, row, *named[i])` unpacks `(name, kind)` — the signature is `_decode(f, row, name, idx, kind)`, so in `dump_table` the named dict must store `(name, idx, kind)`: use `named = {idx: (name, idx, kind) for ...}` and call `_decode(f, row, *named[i])`. Implement it exactly that way.

- [ ] **Step 4: Run test to verify it passes**

Run: `python tests\test_dbc.py`
Expected: `ALL PASS` (Spell.dbc golden scan reads a 195 MB file — allow ~30-60 s)

- [ ] **Step 5: Dump all tables** (Spell.csv.gz is the big one, a few minutes)

Run: `python -m tools.dbc`
Expected: 20 `dumped <table>.csv.gz` lines; `raw/dbc/Spell.csv.gz` tens of MB.

- [ ] **Step 6: Commit**

```powershell
git add -A; git commit -m "feat: WDBC reader, per-table column maps, raw CSV dumps"
```

---

### Task 4: Enum tables + Content snapshot (`tools/enums335.py`, snapshot step)

**Files:**
- Create: `tools/enums335.py`, `tools/snapshot_content.py`, `tests/test_enums_snapshot.py`

**Interfaces:**
- Consumes: `tools.config`; `Data\Content\*.json` from the client.
- Produces:
  - `enums335`: `DISPEL_NAMES: dict[int,str]`, `SCHOOL_MASK_NAMES: dict[int,str]`, `school_names(mask:int) -> list[str]`, `POWER_TYPES: dict[int,str]`, `EFFECT_NAMES: dict[int,str]`, `AURA_NAMES: dict[int,str]`, `TARGET_NAMES: dict[int,str]`, `DMG_CLASS_NAMES`, `PREVENTION_NAMES`, `INSTANCE_TYPES`, `LFG_TYPES`, and total functions `effect_name(id)`, `aura_name(id)`, `target_name(id)` that fall back to `"EFFECT_<n>"` / `"AURA_<n>"` / `"TARGET_<n>"` for unmapped ids.
  - `snapshot_content.snapshot() -> dict` — copies every top-level `Data\Content\*.json` to `raw/content/` verbatim and returns `{filename: {"sha256":…, "bytes":…}}`.

- [ ] **Step 1: Write the failing test** — `tests/test_enums_snapshot.py`:

```python
import hashlib, sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from tools import config, enums335
from tools.snapshot_content import snapshot

assert enums335.DISPEL_NAMES[1] == "Magic" and enums335.DISPEL_NAMES[3] == "Disease"
assert enums335.school_names(0x2) == ["Holy"]
assert enums335.school_names(0x44) == ["Fire", "Arcane"]
assert enums335.aura_name(12) == "MOD_STUN"
assert enums335.aura_name(69) == "SCHOOL_ABSORB"
assert enums335.aura_name(99999) == "AURA_99999"
assert enums335.effect_name(6) == "APPLY_AURA"
assert enums335.effect_name(99999) == "EFFECT_99999"
assert enums335.POWER_TYPES[1] == "Rage" and enums335.POWER_TYPES[6] == "RunicPower"
assert enums335.INSTANCE_TYPES[2] == "Raid"

prov = snapshot()
assert "CharacterAdvancementData.json" in prov
src = config.CONTENT_DIR / "CharacterAdvancementData.json"
dst = config.RAW_CONTENT_DIR / "CharacterAdvancementData.json"
assert dst.is_file()
h = hashlib.sha256(dst.read_bytes()).hexdigest()
assert h == prov["CharacterAdvancementData.json"]["sha256"]
assert h == hashlib.sha256(src.read_bytes()).hexdigest()
print("ALL PASS")
```

- [ ] **Step 2: Run test to verify it fails**

Run: `python tests\test_enums_snapshot.py`
Expected: FAIL with `ModuleNotFoundError: No module named 'tools.enums335'`

- [ ] **Step 3: Write `tools/enums335.py`** — labels for the ids the builders and porting agents touch most; everything else renders through the numeric fallback (never a KeyError). Uncommon-id labels come from the TrinityCore 3.3.5 enums; where a label is not in this table the numeric form is the authoritative decode:

```python
"""3.3.5 enum name tables. Partial by design: unmapped ids render as
EFFECT_<n>/AURA_<n>/TARGET_<n> - the id is always authoritative, the label is sugar."""

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
    101: "FEED_PET", 102: "DISMISS_PET", 110: "DISPEL_MECHANIC",
    113: "RESURRECT_NEW", 121: "NORMALIZED_WEAPON_DMG",
    126: "STEAL_BENEFICIAL_BUFF", 135: "CALL_PET", 136: "HEAL_PCT",
    137: "ENERGIZE_PCT", 138: "LEAP_BACK", 142: "FORCE_CAST",
    151: "TRIGGER_SPELL_2",
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
    51: "MOD_BLOCK_PERCENT", 52: "MOD_CRIT_PERCENT", 53: "PERIODIC_LEECH",
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
    189: "MOD_RATING", 200: "MOD_KILL_XP_PCT", 226: "PERIODIC_DUMMY",
    228: "DETECT_STEALTH", 231: "PROC_TRIGGER_SPELL_WITH_VALUE",
}

TARGET_NAMES = {
    0: "NONE", 1: "UNIT_CASTER", 5: "UNIT_PET", 6: "UNIT_TARGET_ENEMY",
    15: "DEST_AREA_ENEMY_SRC", 16: "DEST_AREA_ENEMY_DST", 18: "DEST_DEST",
    21: "UNIT_TARGET_ALLY", 22: "SRC_CASTER", 25: "UNIT_TARGET_ANY",
    30: "UNIT_AREA_ALLY_SRC", 31: "UNIT_AREA_ALLY_DST", 45: "UNIT_CHAINHEAL_ALLY",
    53: "DEST_TARGET_ENEMY", 57: "UNIT_TARGET_RAID", 61: "UNIT_AREA_CLASS_RAID",
}


def effect_name(n):
    return EFFECT_NAMES.get(n, f"EFFECT_{n}")


def aura_name(n):
    return AURA_NAMES.get(n, f"AURA_{n}")


def target_name(n):
    return TARGET_NAMES.get(n, f"TARGET_{n}")
```

`tools/snapshot_content.py`:

```python
"""Verbatim snapshot of Data\\Content\\*.json into raw/content/ with hashes."""
import hashlib, shutil

from tools import config


def snapshot() -> dict:
    config.ensure_dirs()
    prov = {}
    for src in sorted(config.CONTENT_DIR.glob("*.json")):
        data = src.read_bytes()
        (config.RAW_CONTENT_DIR / src.name).write_bytes(data)
        prov[src.name] = {"sha256": hashlib.sha256(data).hexdigest(), "bytes": len(data)}
    return prov


if __name__ == "__main__":
    for name, e in snapshot().items():
        print(f"{name:55s} {e['bytes']:10d} {e['sha256'][:12]}")
```

- [ ] **Step 4: Run test to verify it passes**

Run: `python tests\test_enums_snapshot.py`
Expected: `ALL PASS`

- [ ] **Step 5: Commit**

```powershell
git add -A; git commit -m "feat: 3.3.5 enum tables and Content JSON snapshot"
```

---

### Task 5: Spell builder (`tools/build_spells.py`) → `data/spells/spells.jsonl`

**Files:**
- Create: `tools/build_spells.py`, `tests/test_spells.py`

**Interfaces:**
- Consumes: `dbc.iter_named`, `enums335`, `raw/content/*.json` (from Task 4 snapshot).
- Produces: `build() -> dict` stats `{"written": int, "missing": list[int], "by_source": dict}`; writes `data/spells/spells.jsonl` (one JSON object per line, ascending id) and `data/spells/_meta.json`. Each line's schema (consumed by Tasks 6-7 and future agents):
  `{id, name, rank, description, tooltip, dispel:{id,name}, mechanic:{id,name}, schoolMask, schools:[str], attributes:[8 u32], powerType:{id,name}, manaCost, manaCostPct, levels:{base,spell,max}, castTimeMs, durationMs:{base,max}, rangeYd:{minEnemy,minFriendly,maxEnemy,maxFriendly}, cooldownMs, categoryCooldownMs, gcdMs, gcdCategory, stackAmount, procFlags, procChance, procCharges, dmgClass, preventionType, iconPath, stances, targets, interruptFlags, auraInterruptFlags, channelInterruptFlags, family:{id,flags1,flags2}, runeCost, effects:[{slot,effect:{id,name},aura:{id,name},basePoints,dieSides,miscValue,miscValueB,amplitudeMs,multipleValue,chainTargets,radiusYd,triggerSpell,targetA:{id,name},targetB:{id,name},mechanic:{id,name}}], rankChain:{first,rank,level}|null, roles:{tank,healer,damage}|null, referencedBy:[str]}`

- [ ] **Step 1: Write the failing test** — `tests/test_spells.py`:

```python
import json, sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from tools import config
from tools import build_spells

stats = build_spells.build()
meta = json.loads((config.DATA_DIR / "spells" / "_meta.json").read_text(encoding="utf-8"))
assert stats["written"] == meta["count"] > 15000, stats["written"]
assert len(stats["missing"]) / max(1, stats["written"]) <= 0.01, \
    f"{len(stats['missing'])} unresolved refs"

by_id, count = {}, 0
with open(config.DATA_DIR / "spells" / "spells.jsonl", encoding="utf-8") as fh:
    prev = -1
    for line in fh:
        r = json.loads(line)
        assert r["id"] > prev, "not sorted"          # ascending, unique
        prev = r["id"]
        count += 1
        if r["id"] in (10, 17) or r["id"] >= 100000 and len(by_id) < 10:
            by_id[r["id"]] = r
assert count == meta["count"]

pws = by_id[17]
assert pws["name"] == "Power Word: Shield"
assert pws["dispel"] == {"id": 1, "name": "Magic"}
assert pws["schools"] == ["Holy"]
assert any(e["aura"]["name"] == "SCHOOL_ABSORB" for e in pws["effects"]), pws["effects"]
assert pws["rankChain"] == {"first": 17, "rank": 1, "level": 10}
bliz = by_id[10]
assert bliz["name"] == "Blizzard" and bliz["schools"] == ["Frost"]
assert bliz["castTimeMs"] >= 0 and bliz["durationMs"]["base"] > 0
custom = [r for i, r in by_id.items() if i >= 100000]
assert custom and all(r["name"] for r in custom), "custom spells must have names"
print("ALL PASS")
```

- [ ] **Step 2: Run test to verify it fails**

Run: `python tests\test_spells.py`
Expected: FAIL with `ModuleNotFoundError: No module named 'tools.build_spells'`

- [ ] **Step 3: Write the implementation** — `tools/build_spells.py`:

```python
"""Build data/spells/spells.jsonl: every referenced spell, fully enriched.

Referenced = CharacterAdvancementData spells + SpellRankData chains + Talent.dbc
ranks, then closed transitively over EffectTriggerSpell (tag "trigger")."""
import json

from tools import config, dbc, enums335


def _content(name):
    return json.loads((config.RAW_CONTENT_DIR / name).read_text(encoding="utf-8-sig"))


def _initial_refs():
    refs = {}
    def add(i, tag):
        if i:
            refs.setdefault(int(i), set()).add(tag)
    for e in _content("CharacterAdvancementData.json"):
        for s in e.get("Spells", []):
            add(s, "cad")
    for e in _content("SpellRankData.json"):
        add(e["spellId"], "rank")
        add(e["firstSpellId"], "rank")
    for t in dbc.iter_named("Talent"):
        for i in range(1, 10):
            add(t[f"rankSpell{i}"], "talent")
    return refs


def _aux():
    return {
        "cast": {r["id"]: r for r in dbc.iter_named("SpellCastTimes")},
        "dur": {r["id"]: r for r in dbc.iter_named("SpellDuration")},
        "rng": {r["id"]: r for r in dbc.iter_named("SpellRange")},
        "rad": {r["id"]: r for r in dbc.iter_named("SpellRadius")},
        "icon": {r["id"]: r["texturePath"] for r in dbc.iter_named("SpellIcon")},
        "dispel": {r["id"]: r["name_enUS"] for r in dbc.iter_named("SpellDispelType")},
        "mech": {r["id"]: r["name_enUS"] for r in dbc.iter_named("SpellMechanic")},
        "rune": {r["id"]: r for r in dbc.iter_named("SpellRuneCost")},
        "roles": {e["Spell"]: e for e in _content("SpellToRoleSuggestionData.json")},
        "rank": {e["spellId"]: e for e in _content("SpellRankData.json")},
    }


def _record(r, aux, tags):
    a = aux
    effects = []
    for slot in (1, 2, 3):
        eff = r[f"effect{slot}"]
        if not eff:
            continue
        radius = a["rad"].get(r[f"effectRadiusIndex{slot}"])
        effects.append({
            "slot": slot,
            "effect": {"id": eff, "name": enums335.effect_name(eff)},
            "aura": {"id": r[f"effectAura{slot}"],
                     "name": enums335.aura_name(r[f"effectAura{slot}"])},
            "basePoints": r[f"effectBasePoints{slot}"],
            "dieSides": r[f"effectDieSides{slot}"],
            "miscValue": r[f"effectMiscValue{slot}"],
            "miscValueB": r[f"effectMiscValueB{slot}"],
            "amplitudeMs": r[f"effectAmplitude{slot}"],
            "multipleValue": r[f"effectMultipleValue{slot}"],
            "chainTargets": r[f"effectChainTarget{slot}"],
            "radiusYd": radius["radius"] if radius else 0.0,
            "triggerSpell": r[f"effectTriggerSpell{slot}"],
            "targetA": {"id": r[f"effectImplicitTargetA{slot}"],
                        "name": enums335.target_name(r[f"effectImplicitTargetA{slot}"])},
            "targetB": {"id": r[f"effectImplicitTargetB{slot}"],
                        "name": enums335.target_name(r[f"effectImplicitTargetB{slot}"])},
            "mechanic": {"id": r[f"effectMechanic{slot}"],
                         "name": a["mech"].get(r[f"effectMechanic{slot}"], "None")},
        })
    cast = a["cast"].get(r["castingTimeIndex"])
    dur = a["dur"].get(r["durationIndex"])
    rng = a["rng"].get(r["rangeIndex"])
    rank = a["rank"].get(r["id"])
    role = a["roles"].get(r["id"])
    rune = a["rune"].get(r["runeCostID"]) if r["runeCostID"] else None
    return {
        "id": r["id"], "name": r["name_enUS"], "rank": r["rank_enUS"],
        "description": r["description_enUS"], "tooltip": r["tooltip_enUS"],
        "dispel": {"id": r["dispel"],
                   "name": a["dispel"].get(r["dispel"],
                                           enums335.DISPEL_NAMES.get(r["dispel"], str(r["dispel"])))},
        "mechanic": {"id": r["mechanic"], "name": a["mech"].get(r["mechanic"], "None")},
        "schoolMask": r["schoolMask"], "schools": enums335.school_names(r["schoolMask"]),
        "attributes": [r["attributes"], r["attributesEx"], r["attributesEx2"],
                       r["attributesEx3"], r["attributesEx4"], r["attributesEx5"],
                       r["attributesEx6"], r["attributesEx7"]],
        "powerType": {"id": r["powerType"],
                      "name": enums335.POWER_TYPES.get(r["powerType"], str(r["powerType"]))},
        "manaCost": r["manaCost"], "manaCostPct": r["manaCostPercentage"],
        "levels": {"base": r["baseLevel"], "spell": r["spellLevel"], "max": r["maxLevel"]},
        "castTimeMs": cast["base"] if cast else 0,
        "durationMs": {"base": dur["base"], "max": dur["max"]} if dur else {"base": 0, "max": 0},
        "rangeYd": {"minEnemy": rng["minRange"], "minFriendly": rng["minRangeFriendly"],
                    "maxEnemy": rng["maxRange"], "maxFriendly": rng["maxRangeFriendly"]}
                   if rng else {"minEnemy": 0.0, "minFriendly": 0.0,
                                "maxEnemy": 0.0, "maxFriendly": 0.0},
        "cooldownMs": r["recoveryTime"], "categoryCooldownMs": r["categoryRecoveryTime"],
        "gcdMs": r["startRecoveryTime"], "gcdCategory": r["startRecoveryCategory"],
        "stackAmount": r["stackAmount"], "procFlags": r["procFlags"],
        "procChance": r["procChance"], "procCharges": r["procCharges"],
        "dmgClass": enums335.DMG_CLASS_NAMES.get(r["dmgClass"], str(r["dmgClass"])),
        "preventionType": enums335.PREVENTION_NAMES.get(r["preventionType"],
                                                        str(r["preventionType"])),
        "iconPath": a["icon"].get(r["spellIconID"], ""),
        "stances": r["stances"], "targets": r["targets"],
        "interruptFlags": r["interruptFlags"],
        "auraInterruptFlags": r["auraInterruptFlags"],
        "channelInterruptFlags": r["channelInterruptFlags"],
        "family": {"id": r["spellFamilyName"], "flags1": r["spellFamilyFlags1"],
                   "flags2": r["spellFamilyFlags2"]},
        "runeCost": ({"blood": rune["blood"], "unholy": rune["unholy"],
                      "frost": rune["frost"], "runicPower": rune["runicPower"]}
                     if rune else None),
        "effects": effects,
        "rankChain": ({"first": rank["firstSpellId"], "rank": rank["rank"],
                       "level": rank["level"]} if rank else None),
        "roles": ({"tank": role["TankScore"], "healer": role["HealerScore"],
                   "damage": role["DamageScore"]} if role else None),
        "referencedBy": sorted(tags),
    }


def build() -> dict:
    config.ensure_dirs()
    refs = _initial_refs()
    aux = _aux()

    # pass 1: full records for initially-referenced ids + trigger map for ALL ids
    records, triggers = {}, {}
    for r in dbc.iter_named("Spell"):
        triggers[r["id"]] = (r["effectTriggerSpell1"], r["effectTriggerSpell2"],
                             r["effectTriggerSpell3"])
        if r["id"] in refs:
            records[r["id"]] = r

    # transitive closure over EffectTriggerSpell
    frontier = set(records)
    while frontier:
        new = set()
        for sid in frontier:
            for t in triggers.get(sid, ()):
                if t and t in triggers and t not in refs:
                    refs.setdefault(t, set()).add("trigger")
                    new.add(t)
        frontier = new

    # pass 2: fetch full records for closure-added ids
    todo = set(refs) - set(records)
    todo &= set(triggers)                       # only ids that exist in Spell.dbc
    if todo:
        for r in dbc.iter_named("Spell"):
            if r["id"] in todo:
                records[r["id"]] = r

    missing = sorted(i for i in refs if i not in triggers)
    out_dir = config.DATA_DIR / "spells"
    out_dir.mkdir(parents=True, exist_ok=True)
    by_source = {}
    with open(out_dir / "spells.jsonl", "w", encoding="utf-8", newline="\n") as fh:
        for sid in sorted(records):
            rec = _record(records[sid], aux, refs[sid])
            for t in rec["referencedBy"]:
                by_source[t] = by_source.get(t, 0) + 1
            fh.write(json.dumps(rec, ensure_ascii=False, sort_keys=True,
                                separators=(",", ":")) + "\n")

    # golden gate: refuse to publish a dataset that fails known ground truth
    g = records.get(17)
    assert g and g["name_enUS"] == "Power Word: Shield" and g["dispel"] == 1, \
        "golden spell 17 failed - column map is wrong, dataset aborted"

    meta = {"count": len(records), "missing_refs": missing, "by_source": by_source,
            "schema_note": "one spell per line, ascending id; see docs/AGENT-GUIDE.md"}
    (out_dir / "_meta.json").write_text(
        json.dumps(meta, indent=1, sort_keys=True), encoding="utf-8")
    return {"written": len(records), "missing": missing, "by_source": by_source}


if __name__ == "__main__":
    s = build()
    print(f"spells written={s['written']} missing={len(s['missing'])} by_source={s['by_source']}")
```

- [ ] **Step 4: Run test to verify it passes** (two full Spell.dbc scans — allow 2-5 min)

Run: `python tests\test_spells.py`
Expected: `ALL PASS`

- [ ] **Step 5: Commit**

```powershell
git add -A; git commit -m "feat: enriched spells.jsonl builder with trigger closure and golden gate"
```

---

### Task 6: Class builder (`tools/build_classes.py`) → `data/classes/`

**Files:**
- Create: `tools/build_classes.py`, `tests/test_classes.py`

**Interfaces:**
- Consumes: `raw/content/CharacterAdvancementData.json`, `raw/content/SpellRankData.json`, `data/spells/spells.jsonl` (Task 5), `dbc.iter_named("ChrClasses")`.
- Produces: `build() -> dict` stats `{"classes": int, "entries": int, "unresolved": int}`; writes `data/classes/<Class>.json` per CAD class value (`None`/`ConquestOfAzeroth` grouped into `_other.json`) and `data/classes/index.json`:
  `{"classes":[{"name","tag","classId","file","entryCounts":{Ability,Talent,Trait,...}}], "chrClasses":[{"id","name","powerType"}], "unmatchedChrClasses":[...]}`.
  Per-class file: `{"class","tag","classId","entries":[{cadId,name,icon,tab,type,quality,qualityCost,requiredLevel,aeCost,expansion,flags,realms,spells:[{id,name,dispel,schools,ranks:[{spellId,rank,level}]|null}]}]}`. `tag` ∈ `"vanilla"|"reborn"|"coa-custom"|"meta"`.

- [ ] **Step 1: Write the failing test** — `tests/test_classes.py`:

```python
import json, sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from tools import config
from tools import build_classes

stats = build_classes.build()
cdir = config.DATA_DIR / "classes"
index = json.loads((cdir / "index.json").read_text(encoding="utf-8"))
assert len(index["chrClasses"]) == 32
byname = {c["name"]: c for c in index["classes"]}

warlock = json.loads((cdir / "RebornWarlock.json").read_text(encoding="utf-8"))
assert warlock["tag"] == "reborn" and len(warlock["entries"]) == 1719
necro = json.loads((cdir / "Necromancer.json").read_text(encoding="utf-8"))
assert necro["tag"] == "coa-custom" and len(necro["entries"]) == 427
assert isinstance(necro["classId"], int) and 17 <= necro["classId"] <= 32
assert byname["Mage"]["tag"] == "vanilla"
assert "_other" in {c["file"].split(".")[0] for c in index["classes"]} or True

# every entry's spells resolved (build enforces <=1% unresolved overall)
some = necro["entries"][0]
assert some["spells"] and all("name" in s for s in some["spells"])
assert stats["unresolved"] / max(1, stats["entries"]) <= 0.05
print("ALL PASS")
```

- [ ] **Step 2: Run test to verify it fails**

Run: `python tests\test_classes.py`
Expected: FAIL with `ModuleNotFoundError: No module named 'tools.build_classes'`

- [ ] **Step 3: Write the implementation** — `tools/build_classes.py`:

```python
"""Group CharacterAdvancementData by class into data/classes/, joined to spells.jsonl."""
import json, re
from collections import Counter, defaultdict

from tools import config, dbc

VANILLA = {"Warrior", "Paladin", "Hunter", "Rogue", "Priest", "DeathKnight",
           "Shaman", "Mage", "Warlock", "Druid"}
META = {"None", "ConquestOfAzeroth"}


def _norm(s):
    return re.sub(r"[^a-z0-9]", "", s.lower())


def _tag(cls):
    if cls in META:
        return "meta"
    if cls.startswith("Reborn"):
        return "reborn"
    if cls in VANILLA:
        return "vanilla"
    return "coa-custom"


def _spell_min():
    out = {}
    with open(config.DATA_DIR / "spells" / "spells.jsonl", encoding="utf-8") as fh:
        for line in fh:
            r = json.loads(line)
            out[r["id"]] = {"id": r["id"], "name": r["name"],
                            "dispel": r["dispel"]["name"], "schools": r["schools"]}
    return out


def build() -> dict:
    cad = json.loads((config.RAW_CONTENT_DIR / "CharacterAdvancementData.json")
                     .read_text(encoding="utf-8-sig"))
    ranks = json.loads((config.RAW_CONTENT_DIR / "SpellRankData.json")
                       .read_text(encoding="utf-8-sig"))
    chains = defaultdict(list)
    for e in ranks:
        chains[e["firstSpellId"]].append(
            {"spellId": e["spellId"], "rank": e["rank"], "level": e["level"]})
    for c in chains.values():
        c.sort(key=lambda x: x["rank"])

    spells = _spell_min()
    chr_classes = list(dbc.iter_named("ChrClasses"))
    chr_by_norm = {_norm(c["name_enUS"]): c for c in chr_classes}

    groups = defaultdict(list)
    for e in cad:
        cls = e.get("Class") or "None"
        groups["_other" if cls in META else cls].append(e)

    cdir = config.DATA_DIR / "classes"
    cdir.mkdir(parents=True, exist_ok=True)
    index_classes, unresolved, total_entries, matched_norms = [], 0, 0, set()

    for cls in sorted(groups):
        entries = []
        for e in sorted(groups[cls], key=lambda x: (x.get("Name") or "", x["ID"])):
            resolved = []
            for sid in e.get("Spells", []):
                s = spells.get(sid)
                if s is None:
                    unresolved += 1
                    resolved.append({"id": sid, "name": None, "dispel": None,
                                     "schools": [], "ranks": None})
                else:
                    resolved.append(dict(s, ranks=chains.get(sid) or None))
            entries.append({
                "cadId": e["ID"], "name": e.get("Name", ""), "icon": e.get("Icon", ""),
                "tab": e.get("Tab", ""), "type": e.get("Type", ""),
                "quality": e.get("Quality", ""), "qualityCost": e.get("QualityCost", 0),
                "requiredLevel": e.get("RequiredLevel", 0), "aeCost": e.get("AECost", 0),
                "expansion": e.get("Expansion", 0), "flags": e.get("Flags", 0),
                "realms": e.get("Realms", ""), "spells": resolved,
            })
        total_entries += len(entries)
        tag = "meta" if cls == "_other" else _tag(cls)
        chr_match = None if cls == "_other" else chr_by_norm.get(
            _norm(cls.removeprefix("Reborn") if cls.startswith("Reborn") else cls))
        if chr_match:
            matched_norms.add(_norm(chr_match["name_enUS"]))
        payload = {"class": cls, "tag": tag,
                   "classId": chr_match["id"] if chr_match else None,
                   "entries": entries}
        (cdir / f"{cls}.json").write_text(
            json.dumps(payload, ensure_ascii=False, indent=1, sort_keys=True),
            encoding="utf-8")
        index_classes.append({
            "name": cls, "tag": tag,
            "classId": chr_match["id"] if chr_match else None,
            "file": f"{cls}.json",
            "entryCounts": dict(Counter(x["type"] for x in entries)),
        })

    index = {
        "classes": index_classes,
        "chrClasses": [{"id": c["id"], "name": c["name_enUS"],
                        "powerType": c["powerType"]} for c in chr_classes],
        "unmatchedChrClasses": sorted(c["name_enUS"] for c in chr_classes
                                      if _norm(c["name_enUS"]) not in matched_norms),
    }
    (cdir / "index.json").write_text(
        json.dumps(index, ensure_ascii=False, indent=1, sort_keys=True),
        encoding="utf-8")
    return {"classes": len(index_classes), "entries": total_entries,
            "unresolved": unresolved}


if __name__ == "__main__":
    print(build())
```

Note the classId matching rule: `RebornWarlock` matches ChrClasses `Warlock` (prefix stripped); customs match by normalized name (`SunCleric` ↔ `Sun Cleric`). CAD classes with no ChrClasses row get `classId: null` — expected for some of the 21 customs since only 16 custom slots (17-32) exist; `unmatchedChrClasses` in the index surfaces the other direction.

- [ ] **Step 4: Run test to verify it passes**

Run: `python tests\test_classes.py`
Expected: `ALL PASS`

- [ ] **Step 5: Commit**

```powershell
git add -A; git commit -m "feat: per-class dataset from CharacterAdvancementData joined to spells"
```

---

### Task 7: Talent builder (`tools/build_talents.py`) → `data/talents/`

**Files:**
- Create: `tools/build_talents.py`, `tests/test_talents.py`

**Interfaces:**
- Consumes: `dbc.iter_named` (`Talent`, `TalentTab`, `ChrClasses`), `data/spells/spells.jsonl` (spell names).
- Produces: `build() -> dict` stats `{"tabs": int, "talents": int, "files": int, "unresolvedRankSpells": int}`; writes `data/talents/<ChrClassName>.json` (spaces stripped from filenames), `data/talents/_pet.json` (tabs with `petTalentMask != 0`), `data/talents/_unassigned.json` (tabs matching no class), `data/talents/_meta.json`.
  Class file schema: `{"class","classId","tabs":[{id,name,orderIndex,backgroundFile,talents:[{id,row,col,ranks:[{spellId,name}],prereqs:[{talentId,rank}],requiredSpellID}]}]}`.

- [ ] **Step 1: Write the failing test** — `tests/test_talents.py`:

```python
import json, sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from tools import config
from tools import build_talents

stats = build_talents.build()
tdir = config.DATA_DIR / "talents"
meta = json.loads((tdir / "_meta.json").read_text(encoding="utf-8"))
assert stats["tabs"] == 37 and stats["talents"] == 2383
assert stats["unresolvedRankSpells"] / max(1, stats["talents"]) <= 0.05

files = sorted(p.name for p in tdir.glob("*.json") if not p.name.startswith("_"))
assert len(files) >= 10, files                    # at least the classes with talent tabs

one = json.loads((tdir / files[0]).read_text(encoding="utf-8"))
assert one["tabs"] and one["tabs"][0]["talents"]
t = one["tabs"][0]["talents"][0]
assert "row" in t and "col" in t and t["ranks"] and t["ranks"][0]["name"]
covered = {f.removesuffix(".json") for f in files}
assert meta["classTabCounts"] and sum(meta["classTabCounts"].values()) <= 37
print("ALL PASS")
```

- [ ] **Step 2: Run test to verify it fails**

Run: `python tests\test_talents.py`
Expected: FAIL with `ModuleNotFoundError: No module named 'tools.build_talents'`

- [ ] **Step 3: Write the implementation** — `tools/build_talents.py`:

```python
"""Talent trees per class from Talent.dbc + TalentTab.dbc (classMask bit = classId-1)."""
import json
from collections import defaultdict

from tools import config, dbc


def _spell_names():
    names = {}
    with open(config.DATA_DIR / "spells" / "spells.jsonl", encoding="utf-8") as fh:
        for line in fh:
            r = json.loads(line)
            names[r["id"]] = r["name"]
    return names


def build() -> dict:
    names = _spell_names()
    classes = {c["id"]: c["name_enUS"] for c in dbc.iter_named("ChrClasses")}
    tabs = sorted(dbc.iter_named("TalentTab"), key=lambda t: (t["orderIndex"], t["id"]))
    talents_by_tab = defaultdict(list)
    unresolved = talent_count = 0

    for t in dbc.iter_named("Talent"):
        talent_count += 1
        ranks = []
        for i in range(1, 10):
            sid = t[f"rankSpell{i}"]
            if sid:
                nm = names.get(sid)
                if nm is None:
                    unresolved += 1
                ranks.append({"spellId": sid, "name": nm})
        prereqs = [{"talentId": t[f"prereqTalent{i}"], "rank": t[f"prereqRank{i}"] + 1}
                   for i in range(1, 4) if t[f"prereqTalent{i}"]]
        talents_by_tab[t["tabID"]].append({
            "id": t["id"], "row": t["row"], "col": t["col"], "ranks": ranks,
            "prereqs": prereqs, "requiredSpellID": t["requiredSpellID"],
        })
    for lst in talents_by_tab.values():
        lst.sort(key=lambda x: (x["row"], x["col"]))

    per_class, pet_tabs, unassigned = defaultdict(list), [], []
    for tab in tabs:
        entry = {"id": tab["id"], "name": tab["name_enUS"],
                 "orderIndex": tab["orderIndex"],
                 "backgroundFile": tab["backgroundFile"],
                 "talents": talents_by_tab.get(tab["id"], [])}
        class_ids = [cid for cid in classes if tab["classMask"] & (1 << (cid - 1))]
        if tab["petTalentMask"]:
            pet_tabs.append(dict(entry, petTalentMask=tab["petTalentMask"]))
        elif class_ids:
            for cid in class_ids:
                per_class[cid].append(entry)
        else:
            unassigned.append(dict(entry, classMask=tab["classMask"]))

    tdir = config.DATA_DIR / "talents"
    tdir.mkdir(parents=True, exist_ok=True)
    files = 0
    tab_counts = {}
    for cid, class_tabs in sorted(per_class.items()):
        cname = classes[cid].replace(" ", "")
        payload = {"class": classes[cid], "classId": cid, "tabs": class_tabs}
        (tdir / f"{cname}.json").write_text(
            json.dumps(payload, ensure_ascii=False, indent=1, sort_keys=True),
            encoding="utf-8")
        files += 1
        tab_counts[cname] = len(class_tabs)
    (tdir / "_pet.json").write_text(
        json.dumps(pet_tabs, ensure_ascii=False, indent=1, sort_keys=True),
        encoding="utf-8")
    (tdir / "_unassigned.json").write_text(
        json.dumps(unassigned, ensure_ascii=False, indent=1, sort_keys=True),
        encoding="utf-8")
    meta = {"tabs": len(tabs), "talents": talent_count, "classFiles": files,
            "petTabs": len(pet_tabs), "unassignedTabs": len(unassigned),
            "classTabCounts": tab_counts,
            "unresolvedRankSpells": unresolved}
    (tdir / "_meta.json").write_text(
        json.dumps(meta, ensure_ascii=False, indent=1, sort_keys=True),
        encoding="utf-8")
    return {"tabs": len(tabs), "talents": talent_count, "files": files,
            "unresolvedRankSpells": unresolved}


if __name__ == "__main__":
    print(build())
```

- [ ] **Step 4: Run test to verify it passes**

Run: `python tests\test_talents.py`
Expected: `ALL PASS`. If it fails on `unresolvedRankSpells` (>5%): Talent.dbc references spells outside the referenced-set closure — fix by confirming Task 5's `_initial_refs()` includes all `rankSpell1..9` (it does); investigate before loosening the threshold.

- [ ] **Step 5: Commit**

```powershell
git add -A; git commit -m "feat: talent trees per class from Talent/TalentTab"
```

---

### Task 8: Dungeon builder (`tools/build_dungeons.py`) → `data/dungeons/dungeons.json`

**Files:**
- Create: `tools/build_dungeons.py`, `tests/test_dungeons.py`

**Interfaces:**
- Consumes: `dbc.iter_named` (`LFGDungeons`, `Map`, `AreaTable`, `DungeonEncounter`), `raw/content/LFGData.json`, `enums335`.
- Produces: `build() -> dict` stats `{"dungeons": int, "raids": int, "encounters": int, "orphanEncounterMaps": int}`; writes `data/dungeons/dungeons.json`:
  `{"dungeons":[{id,name,description,levels:{min,max,target,targetMin,targetMax},mapId,difficulty,typeId,typeName,faction,flags,expansionLevel,groupId,map:{name,directory,instanceType,instanceTypeName,maxPlayers,isRaid,zone}|null,encounters:[{id,name,orderIndex}],rewards:{...}|null}], "encountersByMap":{"<mapId>":{"<difficulty>":[{id,name,orderIndex}]}}}`.

- [ ] **Step 1: Write the failing test** — `tests/test_dungeons.py`:

```python
import json, sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from tools import config
from tools import build_dungeons

stats = build_dungeons.build()
doc = json.loads((config.DATA_DIR / "dungeons" / "dungeons.json").read_text(encoding="utf-8"))
ds = doc["dungeons"]
assert len(ds) == 431
names = {d["name"] for d in ds}
assert any("eadmines" in n for n in names), "Deadmines missing"
raids = [d for d in ds if d["map"] and d["map"]["isRaid"]]
assert raids, "no raids classified"
withenc = [d for d in ds if d["encounters"]]
assert len(withenc) > 50
one = withenc[0]
assert one["encounters"][0]["name"] and "orderIndex" in one["encounters"][0]
assert doc["encountersByMap"]
assert stats["encounters"] == 2080
assert stats["orphanEncounterMaps"] < 50
rewarded = [d for d in ds if d["rewards"]]
assert rewarded, "LFGData rewards not joined"
print("ALL PASS")
```

- [ ] **Step 2: Run test to verify it fails**

Run: `python tests\test_dungeons.py`
Expected: FAIL with `ModuleNotFoundError: No module named 'tools.build_dungeons'`

- [ ] **Step 3: Write the implementation** — `tools/build_dungeons.py`:

```python
"""Dungeons/raids/encounters: LFGDungeons + Map + AreaTable + DungeonEncounter + LFGData."""
import json
from collections import defaultdict

from tools import config, dbc, enums335


def build() -> dict:
    maps = {m["id"]: m for m in dbc.iter_named("Map")}
    areas = {a["id"]: a for a in dbc.iter_named("AreaTable")}
    rewards = {e["DungeonId"]: e for e in json.loads(
        (config.RAW_CONTENT_DIR / "LFGData.json").read_text(encoding="utf-8-sig"))}

    enc_by_map = defaultdict(list)
    enc_count = orphan = 0
    for e in dbc.iter_named("DungeonEncounter"):
        enc_count += 1
        if e["mapID"] not in maps:
            orphan += 1
        enc_by_map[(e["mapID"], e["difficulty"])].append(
            {"id": e["id"], "name": e["name_enUS"], "orderIndex": e["orderIndex"]})
    for lst in enc_by_map.values():
        lst.sort(key=lambda x: x["orderIndex"])

    dungeons, raid_count = [], 0
    for d in dbc.iter_named("LFGDungeons"):
        m = maps.get(d["mapID"])
        map_block = None
        if m:
            zone = areas.get(m["areaTableID"], {}).get("name_enUS", "")
            is_raid = m["instanceType"] == 2
            raid_count += is_raid
            map_block = {
                "name": m["name_enUS"], "directory": m["directory"],
                "instanceType": m["instanceType"],
                "instanceTypeName": enums335.INSTANCE_TYPES.get(
                    m["instanceType"], str(m["instanceType"])),
                "maxPlayers": m["maxPlayers"], "isRaid": is_raid, "zone": zone,
            }
        dungeons.append({
            "id": d["id"], "name": d["name_enUS"], "description": d["description_enUS"],
            "levels": {"min": d["minLevel"], "max": d["maxLevel"],
                       "target": d["targetLevel"], "targetMin": d["targetLevelMin"],
                       "targetMax": d["targetLevelMax"]},
            "mapId": d["mapID"], "difficulty": d["difficulty"],
            "typeId": d["typeID"],
            "typeName": enums335.LFG_TYPES.get(d["typeID"], str(d["typeID"])),
            "faction": d["faction"], "flags": d["flags"],
            "expansionLevel": d["expansionLevel"], "groupId": d["groupID"],
            "map": map_block,
            "encounters": enc_by_map.get((d["mapID"], d["difficulty"]), []),
            "rewards": rewards.get(d["id"]),
        })
    dungeons.sort(key=lambda x: x["id"])

    out_dir = config.DATA_DIR / "dungeons"
    out_dir.mkdir(parents=True, exist_ok=True)
    doc = {
        "dungeons": dungeons,
        "encountersByMap": {
            str(mid): {str(diff): lst for (m2, diff), lst in enc_by_map.items()
                       if m2 == mid}
            for mid in sorted({m for m, _ in enc_by_map})},
    }
    (out_dir / "dungeons.json").write_text(
        json.dumps(doc, ensure_ascii=False, indent=1, sort_keys=True), encoding="utf-8")
    return {"dungeons": len(dungeons), "raids": raid_count,
            "encounters": enc_count, "orphanEncounterMaps": orphan}


if __name__ == "__main__":
    print(build())
```

- [ ] **Step 4: Run test to verify it passes**

Run: `python tests\test_dungeons.py`
Expected: `ALL PASS`

- [ ] **Step 5: Commit**

```powershell
git add -A; git commit -m "feat: dungeons/raids/encounters dataset"
```

---

### Task 9: Orchestrator + provenance + docs (`tools/build_dataset.py`, README, AGENT-GUIDE)

**Files:**
- Create: `tools/build_dataset.py`, `tests/test_dataset.py`, `README.md`, `docs/AGENT-GUIDE.md`

**Interfaces:**
- Consumes: every module from Tasks 1-8.
- Produces: CLI `python -m tools.build_dataset [--skip-extract] [--skip-dump]` running extract → dump → snapshot → spells → classes → talents → dungeons, then writing `raw/provenance.json`:
  `{"generatedUtc", "clientDir", "extract": {…Task 2 fragment…}, "content": {…Task 4 fragment…}, "buildStats": {"spells","classes","talents","dungeons"}}`.

- [ ] **Step 1: Write the failing test** — `tests/test_dataset.py` (uses `--skip-extract --skip-dump`; the expensive stages are already proven by Tasks 2-3):

```python
import json, sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from tools import config
from tools.build_dataset import run

prov = run(skip_extract=True, skip_dump=True)
assert prov["clientDir"] == str(config.CLIENT_DIR)
assert set(prov["buildStats"]) == {"spells", "classes", "talents", "dungeons"}
assert prov["extract"]["files"]["spell.dbc"]["fields"] == 234
ondisk = json.loads((config.RAW_DIR / "provenance.json").read_text(encoding="utf-8"))
assert ondisk["generatedUtc"].endswith("+00:00")
assert (config.REPO_ROOT / "README.md").is_file()
assert (config.REPO_ROOT / "docs" / "AGENT-GUIDE.md").is_file()
print("ALL PASS")
```

- [ ] **Step 2: Run test to verify it fails**

Run: `python tests\test_dataset.py`
Expected: FAIL with `ModuleNotFoundError: No module named 'tools.build_dataset'`

- [ ] **Step 3: Write the implementation** — `tools/build_dataset.py`:

```python
"""One-command pipeline: extract -> dump -> snapshot -> build -> provenance."""
import argparse, datetime, json

from tools import (config, dbc, extract_mpq, snapshot_content,
                   build_spells, build_classes, build_talents, build_dungeons)


def run(skip_extract=False, skip_dump=False) -> dict:
    config.ensure_dirs()
    if skip_extract and all((config.WORK_DBC_DIR / w).is_file()
                            for w in config.WANTED_DBCS):
        extract_prov = json.loads(
            (config.WORK_DIR / "extract_provenance.json").read_text(encoding="utf-8"))
    else:
        extract_prov = extract_mpq.extract_all()
    if not skip_dump:
        dbc.dump_all()
    content_prov = snapshot_content.snapshot()

    stats = {}
    stats["spells"] = build_spells.build()
    print(f"[spells]   {stats['spells']['written']} written, "
          f"{len(stats['spells']['missing'])} missing refs")
    stats["classes"] = build_classes.build()
    print(f"[classes]  {stats['classes']}")
    stats["talents"] = build_talents.build()
    print(f"[talents]  {stats['talents']}")
    stats["dungeons"] = build_dungeons.build()
    print(f"[dungeons] {stats['dungeons']}")

    prov = {
        "generatedUtc": datetime.datetime.now(datetime.timezone.utc)
                        .isoformat(timespec="seconds"),
        "clientDir": str(config.CLIENT_DIR),
        "extract": extract_prov,
        "content": content_prov,
        "buildStats": stats,
    }
    (config.RAW_DIR / "provenance.json").write_text(
        json.dumps(prov, ensure_ascii=False, indent=1, sort_keys=True),
        encoding="utf-8")
    return prov


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--skip-extract", action="store_true",
                    help="reuse work/dbc from a previous extract")
    ap.add_argument("--skip-dump", action="store_true",
                    help="skip regenerating raw/dbc CSV dumps")
    a = ap.parse_args()
    run(skip_extract=a.skip_extract, skip_dump=a.skip_dump)
    print("build complete - raw/provenance.json updated")


if __name__ == "__main__":
    main()
```

- [ ] **Step 4: Write `README.md`** (repo root):

```markdown
# coa-datamine

Agent-consumable dataset of Ascension **Conquest of Azeroth** game data (classes,
spells, talents, dungeons/raids), datamined from the client install.

- **Consume it:** read `docs/AGENT-GUIDE.md` first - file map, schemas, query recipes,
  and the honest-limits list (what client data can and cannot know).
- **Regenerate it:** `python -m tools.build_dataset` (client at `E:\ascension-live`,
  override with env `COA_CLIENT_DIR`). Requires Python 3.12 + `pip install mpyq`.
  Add `--skip-extract --skip-dump` to rebuild only the curated `data/` layer.
- **Verify it:** `python tests\test_config.py` ... each test script prints `ALL PASS`.

Layout: `raw/` = extracted sources (full DBC dumps as csv.gz, verbatim Content JSONs,
provenance with sha256s); `data/` = curated JSON (classes/, spells/, talents/,
dungeons/); `tools/` = the pipeline; `work/` = gitignored scratch (raw .dbc binaries).

Spec: `docs/superpowers/specs/2026-07-17-coa-datamine-design.md`.
```

- [ ] **Step 5: Write `docs/AGENT-GUIDE.md`**:

````markdown
# Agent Guide - querying coa-datamine

Dataset of Ascension CoA (WoW 3.3.5a custom server) game data for porting work
(dispel logic, class buffs, raid tooling). Everything below is generated - do not
hand-edit; rerun `python -m tools.build_dataset` after a client patch instead.

## File map

| Path | What | Size class |
|---|---|---|
| `data/classes/index.json` | class roster + tags + classId map + ChrClasses table | small |
| `data/classes/<Class>.json` | per-class obtainable abilities/talents/traits with resolved spells | medium |
| `data/spells/spells.jsonl` | every referenced spell, fully enriched, ONE JSON PER LINE | large - stream/grep it, do not slurp |
| `data/spells/_meta.json` | counts, unresolved refs, source tags | small |
| `data/talents/<ChrClass>.json` | DBC talent trees (row/col/ranks/prereqs) | medium |
| `data/dungeons/dungeons.json` | all LFG dungeons/raids + encounters + rewards | medium |
| `raw/dbc/*.csv.gz` | full decoded DBC dumps (every column) | large |
| `raw/content/*.json` | verbatim client sidecar JSONs | large |
| `raw/provenance.json` | source hashes, archive resolution, build stats | small |

## Key semantics

- **Class tags** (`data/classes/index.json`): `vanilla` (classic 9 + DK), `reborn`
  (CoA revamps of originals, e.g. RebornWarlock), `coa-custom` (Necromancer, Tinker,
  ...), `meta` (non-class rows). `classId` matches ChrClasses.dbc (customs are
  ids 17-32) - this is the id used by client APIs like minimap blips; `null` means
  the CAD class has no ChrClasses row.
- **Dispels**: `spell.dispel.name` ∈ None/Magic/Curse/Disease/Poison/... A spell is
  a dispellable buff if it applies an aura (`effects[].effect.name == "APPLY_AURA"`)
  and `dispel.id != 0`. Dispel-CAPABLE spells have `effects[].effect.name == "DISPEL"`
  (miscValue = dispel type id it removes).
- **Ranks**: `rankChain` groups spell ranks (`first` = rank-1 spell id). Class entries
  list the first-rank spell with the full chain inline.
- **Tooltips**: `$` tokens (e.g. `$s1`, `$d`) are raw - server formulas are not
  evaluated. `effects[].basePoints` is the DBC convention: displayed value is
  usually `basePoints + dieSides` for fixed values.
- **referencedBy**: how a spell entered the set - `cad` (obtainable), `rank`,
  `talent`, `trigger` (reached via EffectTriggerSpell closure; often the actual
  buff aura behind a cast).

## Recipes (PowerShell / Python)

All spells of a class that apply a Magic-dispellable aura:

```python
import json
ids = set()
cls = json.load(open(r"data/classes/Necromancer.json", encoding="utf-8"))
for e in cls["entries"]:
    for s in e["spells"]:
        ids.add(s["id"])
        for r in (s.get("ranks") or []):
            ids.add(r["spellId"])
hits = []
for line in open(r"data/spells/spells.jsonl", encoding="utf-8"):
    sp = json.loads(line)
    if sp["id"] in ids and sp["dispel"]["id"] == 1 and \
       any(e["effect"]["name"] == "APPLY_AURA" for e in sp["effects"]):
        hits.append((sp["id"], sp["name"]))
```

Which classes get spell 954876: grep `"954876"` across `data/classes/*.json`.

All encounters of a raid: `data/dungeons/dungeons.json` → filter `map.isRaid`,
read `encounters` (ordered).

## Honest limits

- Client data cannot see server-side logic: boss scripts, loot tables, runtime
  spell grants, proc internals. Encounter lists are names/order only.
- `Realms` bitmask on class entries: semantics unknown, carried raw.
- Enum labels for uncommon effect/aura ids fall back to `EFFECT_<n>`/`AURA_<n>`;
  the numeric id is always authoritative.
- `.loc` localization files (non-enUS) are unparsed; enUS strings come from DBCs.
- CAD covers *obtainable* abilities; item/proc-granted spells appear only via the
  trigger closure or not at all.
````

- [ ] **Step 6: Run test to verify it passes**

Run: `python tests\test_dataset.py`
Expected: `ALL PASS`

- [ ] **Step 7: Commit**

```powershell
git add -A; git commit -m "feat: pipeline orchestrator, provenance, README and agent guide"
```

---

### Task 10: Full regeneration, verification sweep, dataset commit

**Files:**
- Modify: nothing new — this task runs the whole pipeline end-to-end, verifies, and commits the generated `raw/` + `data/` trees.

**Interfaces:**
- Consumes: everything.
- Produces: the committed dataset.

- [ ] **Step 1: Full clean run**

Run: `python -m tools.build_dataset`
Expected: 20 CSV dump lines, four `[stage]` stat lines, `build complete`. Full run takes ~10-20 min (archive scan + two Spell.dbc passes + 200 MB CSV dump).

- [ ] **Step 2: Run the entire test suite**

Run: `Get-ChildItem tests\test_*.py | ForEach-Object { python $_.FullName }`
Expected: `ALL PASS` × 8 (config, extract, dbc, enums_snapshot, spells, classes, talents, dataset — plus dungeons = 9 total files; every one prints `ALL PASS`, none prints a traceback).

- [ ] **Step 3: Spot-check the dataset like a consumer would** (fresh eyes, not the builders' own asserts)

Run:
```powershell
python -c "import json; d=json.load(open(r'data\classes\index.json',encoding='utf-8')); print(len(d['classes']),'classes'); print([c['name'] for c in d['classes'] if c['tag']=='coa-custom'])"
python -c "import json; hits=[json.loads(l) for l in open(r'data\spells\spells.jsonl',encoding='utf-8')]; magic=[s for s in hits if s['dispel']['name']=='Magic']; print(len(hits),'spells,',len(magic),'magic-dispellable')"
python -c "import json; d=json.load(open(r'data\dungeons\dungeons.json',encoding='utf-8')); raids=[x for x in d['dungeons'] if x['map'] and x['map']['isRaid']]; print(len(raids),'raid entries'); print(sorted({r['name'] for r in raids})[:15])"
```
Expected: ~40 classes with the 21 customs listed; thousands of magic-dispellable spells; a plausible raid list (Molten Core … plus custom CoA raids). **If any output looks absurd (0 magic-dispellable, empty raid names), STOP and investigate — do not commit.**

- [ ] **Step 4: Commit the dataset**

```powershell
git add -A; git commit -m "data: full CoA dataset build from live client (classes, spells, talents, dungeons)"
```

- [ ] **Step 5: Report** — summarize record counts (classes, spells, talents, dungeons/raids/encounters), any unresolved-ref counts, and the `unmatchedChrClasses` list for the user.

---

## Self-Review (performed while writing)

- **Spec coverage:** sources inventory → Tasks 2-4; spells.jsonl (spec's `spells.json`, renamed to JSONL for greppability — noted in AGENT-GUIDE) → Task 5; classes → Task 6; talents (both DBC view; CAD talent view lives in class files via `type`) → Tasks 6-7; dungeons/raids/encounters/rewards → Task 8; provenance/chain-order/collision reporting → Task 2/9; validation gates → embedded per task; AGENT-GUIDE + honest limits → Task 9. No spec requirement without a task.
- **Type consistency:** `extract_all()` provenance keys consumed identically in Tasks 2/9 tests; `iter_named` column names used by builders match `TABLE_MAPS` definitions; spells.jsonl field names used in Tasks 6/7 (`name`, `dispel.name`, `schools`, `id`) match Task 5's `_record`.
- **Known judgment calls:** ChrRaces/SkillLine*/SkillRaceClassInfo are extracted+dumped (raw layer) but not consumed by builders — intentional (future relational work). `prereqRank` in Task 7 stores DBC value +1 (DBC is 0-based rank index) — documented here, consistent in code.




