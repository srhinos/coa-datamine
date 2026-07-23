# Agent Guide - querying coa-datamine

Dataset of Ascension CoA (WoW 3.3.5a custom server) game data for porting work
(dispel logic, class buffs, raid tooling). Everything below is generated - do not
hand-edit; rerun `python -m tools.build_dataset` after a client patch instead.

## File map

**Amendment C (sharding).** No committed `data/` file is an arbitrary 10k+-line
monolith: every dataset with enough records to matter is split by a stable semantic
key (per-dungeon file, per-class-per-tab file) or a fixed id range (`id // N * N`
bucket - never count-based chunking, since that reshuffles every file's contents on
insertion and destroys diff locality). Every sharded dataset has an `index.json`
manifest that fully enumerates its shard files; `index.json` files themselves use a
compact one-record-per-line format (not the content files' `indent=1`) so a
several-hundred-record manifest stays small and still diffs one line per record. A
repo-wide test (`tests/test_sharding.py`) asserts every `data/**/*.json(l)` file is
<=5,000 lines except an explicit, commented allowlist (currently empty - nothing in
this repo needs an exemption).

| Path | What | Size class |
|---|---|---|
| `data/classes/index.json` | class roster + tags + classId map + `dir`/`index` pointers into each class's subdirectory + `chrClasses` (ChrClasses.dbc table, 32 rows, ids 1-32) + `unmatchedChrClasses` (ChrClasses rows with no CAD data: Bloodmage, Felsworn, Hero, Templar) | small |
| `data/classes/<Class>/index.json` | that class's `tag`/`classId`/`realmHint`/`entryCount`/`unresolvedCount` + `files: [{file, tab, type, cadIdRange, count}]` enumerating every shard file for the class | small |
| `data/classes/<Class>/<Tab>.json` | one spec tab's obtainable abilities/talents/traits with resolved spells (`{class, tab, type: null, entries}`) | small-medium |
| `data/classes/<Class>/<Tab>.<Type>.json` / `<Tab>.<Type>-<cadId-bucket>.json` | only present when a single tab's entries exceed 5,000 lines as one file (Reborn* classes' biggest tabs) - see "Class tab sharding" below | small |
| `data/classes/<Class>/_general.json` | entries with no `Tab` (none exist in the current snapshot; the file only appears if some do) | small |
| `data/spells/index.json` | bucket manifest: `bucketSize` (10000), total `count`, `buckets: [{bucket, file, count, minId, maxId}]` | small |
| `data/spells/by-id/spells-<id//10000*10000>.jsonl` | every referenced spell in that id bucket, fully enriched, ONE JSON PER LINE, ascending id within the bucket; empty buckets are omitted | small-medium per file - stream/grep it, do not slurp |
| `data/spells/_meta.json` | counts only: `count`, `missing_ref_counts_by_source`, `ref_counts`, `dataNotes`, `by_source`, `missingRefsFile` pointer | small |
| `data/spells/_missing_refs.json` | full missing-ref id lists by source (`cad_other`/`cad_reborn`/`talent`/`rank`), each source's array on ONE line | small (line count, not byte count) |
| `data/talents/<ChrClass>.json` | DBC talent trees (row/col/ranks/prereqs) - only exists for the 12 classes that have DBC talent tabs; largest is ~3.6k lines, under the gate as-is, not sharded | medium |
| `data/talents/_pet.json` | pet talent tabs (`petTalentMask` set) - not tied to a single player class | small |
| `data/talents/_unassigned.json` | talent tabs matching no classMask/petTalentMask | small |
| `data/talents/_meta.json` | tab/talent counts, per-class tab counts, unresolved rank-spell count | small |
| `data/dungeons/index.json` | one compact record per dungeon: `{id, name, file, mapId, isRaid, levels}` | small |
| `data/dungeons/<id>-<slug>.json` | one dungeon incl. its encounters (ordered) + reward brackets; `<slug>` = lowercase name, non-alnum runs -> `-`, collapsed, max 40 chars | small |
| `raw/dbc/*.csv.gz` | full decoded DBC dumps (every column) | large |
| `raw/content/*.json` | verbatim client sidecar JSONs | large |
| `raw/provenance.json` | source hashes, archive resolution, build stats | small |

### Class tab sharding (why three levels, not one)

Most class tabs fit in one file: `data/classes/<Class>/<Tab>.json`. A handful of
Reborn* classes' biggest tabs (e.g. RebornWarlock/Destruction, 728 entries) don't -
even though Tab is the natural semantic key, one file would run 15k-18k lines. The
writer (`tools/build_classes.py:_shard_tab`) cascades three levels, each only used
if the previous one still overflows 5,000 lines:

1. **Whole tab** - `<Tab>.json`. Used for the large majority of tabs.
2. **Split by entry `Type`** - `<Tab>.<Type>.json` (`Talent`/`TalentAbility`/`Trait`/...).
   Insufficient by itself for the worst offenders: `Type == "Trait"` alone is ~95%
   of the oversized tabs' entries, so splitting Talent/TalentAbility off barely
   moves the needle on the dominant Trait bucket.
3. **Fixed `cadId` range within the Type** - `<Tab>.<Type>-<cadId//2000*2000>.json`.
   The remaining fallback, used only for the handful of `Trait` files still over
   5,000 lines after step 2. A `requiredLevel` band was also measured and rejected:
   ~40% of a typical oversized Trait bucket shares the exact same `RequiredLevel`
   (mostly 1), so no level-band width shrinks that cluster - it isn't a workable
   semantic key here. Fixed id ranges are the amendment's own sanctioned fallback
   for exactly this case (no smaller semantic key available), so this isn't a new
   mechanism, just the same `id // N * N` rule spells use, applied to `cadId`.

Every shard file, regardless of level, is self-describing (`{class, tab, type,
entries}`) and listed in `data/classes/<Class>/index.json`'s `files` array with its
`tab`/`type`/`cadIdRange`/`count`, so you can always find every piece of a class or
tab without guessing the split level.

## Key semantics

- **Four realms, one account-wide CAD file.** This client serves four realms:
  "Area 52 - Free-Pick" (classless), "Bronzebeard - Warcraft Reborn" (the Reborn*
  classes), "Rexxar - Conquest of Azeroth", and "Vol'jin - Conquest of Azeroth".
  `CharacterAdvancementData.json` - the source of everything in `data/classes/` - is
  **account-wide across all four realms**, not scoped to one. Each realm ships its
  own DBC overrides separately (e.g. `Data\area-52\patch-D.MPQ` for Area 52), and
  **Bronzebeard/Reborn's spell data is not part of this client snapshot's
  `Spell.dbc`**. Consequence: Reborn-class spell references resolve as `null` in
  class files far more often than other classes (~51% of Reborn* refs) - this is a
  data-availability fact of the snapshot, not a pipeline bug. Every class file and
  `data/classes/index.json` entry carries `realmHint`
  (`"Bronzebeard - Warcraft Reborn"` / `"Area 52 - Free-Pick /shared"` /
  `"Rexxar/Vol'jin - Conquest of Azeroth"` / `null` for meta rows) and
  `unresolvedCount` so you can tell at a glance whether a class's gaps are expected
  (reborn) or worth investigating (anything else).
- **Class tags** (`data/classes/index.json`): `vanilla` (classic 9 + DK), `reborn`
  (CoA revamps of originals, e.g. RebornWarlock), `coa-custom` (Necromancer, Tinker,
  ...), `meta` (non-class rows). `classId` matches ChrClasses.dbc (customs are
  ids 17-32) - this is the id used by client APIs like minimap blips; `null` means
  the CAD class has no ChrClasses row.
- **Dispels**: `spell.dispel.name` in None/Magic/Curse/Disease/Poison/... A spell is
  a dispellable buff if it applies an aura (`effects[].effect.name == "APPLY_AURA"`)
  and `dispel.id != 0`. Dispel-CAPABLE spells have `effects[].effect.name == "DISPEL"`
  (miscValue = dispel type id it removes). Schema differs by file: in
  `data/spells/by-id/*.jsonl` `dispel` is the `{id, name}` object described above; in
  `data/classes/<Class>/<Tab>.json`, each entry's `spells[].dispel` is a plain string
  (or `null` when unresolved) - the summary view drops the numeric id.
- **Ranks**: `rankChain` groups spell ranks (`first` = rank-1 spell id). Class entries
  list the first-rank spell with the full chain inline.
- **Tooltips**: `$` tokens (e.g. `$s1`, `$d`) are raw - server formulas are not
  evaluated. `effects[].basePoints` is the DBC convention: displayed value is
  usually `basePoints + dieSides` for fixed values.
- **referencedBy**: how a spell entered the set - `cad` (obtainable), `rank`,
  `talent`, `trigger` (reached via EffectTriggerSpell closure; often the actual
  buff aura behind a cast).
- **Blank name vs. null name.** A spell can be present with `name: ""` (blank but
  non-null) - this is a WIP-content signature straight from the client (e.g. 222
  Talent-rank spells ship with an empty `name_enUS` in this snapshot). That is
  different from `name: null`, which means the id was referenced somewhere but has
  no row at all in this snapshot's `Spell.dbc` (see the four-realm note above).
  Don't treat `""` as missing data - it's a real, if unfinished, spell row.
- **Talent coverage has two views - check both.** Only 12 classes have DBC
  `Talent.dbc` talent tabs (`data/talents/<ChrClass>.json`): the 10 vanilla classes
  plus Barbarian and WitchDoctor. Every other CoA custom/reborn class drives its
  talents through `CharacterAdvancementData` entries instead - iterate every file
  listed in `data/classes/<Class>/index.json`'s `files` array and look for entries
  with `type == "Talent"` or `"TalentAbility"` (or use the index's `entryCounts`
  to see the type breakdown without opening every shard). If you're asked "what
  talents does class X have" and X isn't one of the 12, `data/talents/` will have
  no file for it - that's expected; the answer lives in the class's CAD entry
  shards, not the DBC talent tree.

## Recipes (PowerShell / Python)

All spells across the whole dataset (helper for the recipes below):

```python
import json

def iter_all_spells():
    idx = json.load(open(r"data/spells/index.json", encoding="utf-8"))
    for b in idx["buckets"]:
        for line in open(rf"data/spells/{b['file']}", encoding="utf-8"):
            yield json.loads(line)

def iter_class_entries(cls):
    idx = json.load(open(rf"data/classes/{cls}/index.json", encoding="utf-8"))
    for f in idx["files"]:
        doc = json.load(open(rf"data/classes/{cls}/{f['file']}", encoding="utf-8"))
        yield from doc["entries"]
```

All spells of a class that apply a Magic-dispellable aura:

```python
ids = set()
for e in iter_class_entries("Necromancer"):
    for s in e["spells"]:
        ids.add(s["id"])
        for r in (s.get("ranks") or []):
            ids.add(r["spellId"])
hits = [(sp["id"], sp["name"]) for sp in iter_all_spells()
        if sp["id"] in ids and sp["dispel"]["id"] == 1
        and any(e["effect"]["name"] == "APPLY_AURA" for e in sp["effects"])]
```

Which classes get spell 954876: grep `"954876"` recursively across
`data/classes/*/*.json` (every shard is self-describing, so a hit's `class`/`tab`
fields tell you where it came from without cross-referencing the index).

All encounters of a raid: read `data/dungeons/index.json`, filter `isRaid`, open
each hit's `file` and read `encounters` (already ordered).

A dungeon's reward for a given character level: open its `data/dungeons/<id>-<slug>.json`
(id looked up via `index.json`) -> `rewards` is a **list** of level-bracket objects
sorted by `MaxLevel` ascending (most dungeons have one bracket or none - 4 dungeons
have several, e.g. dungeon id 258 has 17); pick the first bracket whose `MaxLevel`
is >= the character's level, and treat an empty list as "no reward data", not an
error. The old `encountersByMap` duplicate view is gone - if you need encounters
grouped by map instead of by dungeon, derive it by reading every dungeon file and
grouping on `(mapId, difficulty)`.

## Honest limits

- Client data cannot see server-side logic: boss scripts, loot tables, runtime
  spell grants, proc internals. Encounter lists are names/order only.
- `CharacterAdvancementData.json` is account-wide across the four realms this
  client serves (see Key semantics above); Reborn*-class spell refs are expected
  to resolve `null` far more often than other classes in this snapshot - that's a
  data-availability fact of the capture, not a pipeline bug.
  `data/spells/_meta.json` records the shape precisely: `missing_ref_counts_by_source`
  gives the count per bucket (`cad_other` / `cad_reborn` / `talent` / `rank`) and
  `ref_counts` gives the denominator for each; the full id lists themselves live in
  `data/spells/_missing_refs.json` (kept out of `_meta.json` so it stays small - each
  source's array is on one line there). The build only hard-gates
  `cad_other` and `talent` (each must resolve to <=5% missing - measured churn
  baseline was `cad_other` 211/7162 = 2.95% on 2026-07-17, i.e. real named
  custom-class abilities absent from this snapshot's `Spell.dbc`, recorded in
  `dataNotes`). `cad_reborn` misses and `rank` orphans (stale `SpellRankData`
  chains with no filterable realm/class field) are report-only, not gated -
  expect both to be nonzero on every build.
- `Realms` bitmask on class entries: semantics unknown, carried raw.
- Enum labels for uncommon effect/aura ids fall back to `EFFECT_<n>`/`AURA_<n>`;
  the numeric id is always authoritative.
- `.loc` localization files (non-enUS) are unparsed; enUS strings come from DBCs.
- CAD covers *obtainable* abilities; item/proc-granted spells appear only via the
  trigger closure or not at all.
- Dungeon `rewards` is a **list** of level-bracket objects sorted by `MaxLevel`
  ascending, never a single object - `LFGData.json` carries multiple reward rows
  for 4 dungeons (id 258: 17 brackets; 259/417/465: 2 each). An empty list means
  no LFGData reward entry exists for that dungeon at all; always iterate it, never
  assume exactly one row.
- Only 12 classes have DBC `Talent.dbc` talent tabs (10 vanilla + Barbarian +
  WitchDoctor); every other class's talents live only in CAD entries
  (`type == "Talent"`/`"TalentAbility"` across that class's `data/classes/<Class>/*.json`
  shards) - absence from `data/talents/` does not mean the class has no talents.

## Regenerating after a client patch

The test suite mixes two different kinds of check, and they fail for different
reasons. STRUCTURAL checks verify the pipeline itself still works: WDBC layout
guards (`dbc.LayoutError`), golden spell rows (id 17 Power Word: Shield, id 10
Blizzard - name/dispel/school/duration fixed points), the `cad_other`/`talent`
missing-ref ratio gates (<=5%), and general schema asserts (field counts,
sort order, required keys). SNAPSHOT PINS, by contrast, are exact counts
calibrated to this repo's 2026-07-17 capture and will legitimately drift
whenever CoA ships new content:

- `tests/test_classes.py`: RebornWarlock 1719 entries / Necromancer 427 entries
  (summed across each class's shard files, per `data/classes/<Class>/index.json`)
- `tests/test_talents.py`: 37 tabs / 2383 talents
- `tests/test_dungeons.py`: 431 dungeons / 2080 encounters / dungeon-258 has 17
  reward brackets
- `tests/test_extract.py`: `spell.dbc` resolves from `patch-T.MPQ`
- `tests/test_sharding.py`: pins the pre-shard record-count baseline (spells 27441,
  per-class entry counts, dungeons 431) so sharding can't silently drop/duplicate
  records; also the repo-wide <=5,000-line gate (empty allowlist today - re-add an
  entry here and in the allowlist if content growth ever forces one)

Note: the spells count above (27441) already reflects one round of exactly this kind
of drift - discovered mid-task when a controlled re-run of the pre-sharding writer
against the current `work/dbc`/`raw/content` snapshot produced 27441 records, not the
27432 that had been committed in `data/spells/`. Re-running both the old and new
writer against identical source data confirmed the delta was pre-existing upstream
content drift (unrelated to the sharding rewrite itself), not a regression - the same
class of churn documented in past task reports (e.g. Task 9's spell 61685 rename,
Task V2-1's raw/ Spell.csv.gz +292 rows).

After regenerating against a patched client, treat the two failure modes
differently. A snapshot-pin failure with a small delta (record counts moved by
tens, not orders of magnitude; a different archive won the same DBC by one
letter) means content changed upstream - eyeball the new numbers for
sanity, then re-pin the constants to match. A structural-check failure (layout
guard fires, a golden spell's fixed fields changed, a ratio gate blows past
5%, a huge/negative count swing) means the pipeline itself broke - investigate
the extractor/builder, don't just paper over it by re-pinning.
