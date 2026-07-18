# Agent Guide - querying coa-datamine

Dataset of Ascension CoA (WoW 3.3.5a custom server) game data for porting work
(dispel logic, class buffs, raid tooling). Everything below is generated - do not
hand-edit; rerun `python -m tools.build_dataset` after a client patch instead.

## File map

| Path | What | Size class |
|---|---|---|
| `data/classes/index.json` | class roster + tags + classId map + `chrClasses` (ChrClasses.dbc table, 32 rows, ids 1-32) + `unmatchedChrClasses` (ChrClasses rows with no CAD data: Bloodmage, Felsworn, Hero, Templar) | small |
| `data/classes/<Class>.json` | per-class obtainable abilities/talents/traits with resolved spells, plus `tag`/`classId`/`realmHint` | medium |
| `data/spells/spells.jsonl` | every referenced spell, fully enriched, ONE JSON PER LINE | large - stream/grep it, do not slurp |
| `data/spells/_meta.json` | counts, `missing_refs_by_source`, `ref_counts`, `dataNotes`, source tags | small |
| `data/talents/<ChrClass>.json` | DBC talent trees (row/col/ranks/prereqs) - only exists for the 12 classes that have DBC talent tabs | medium |
| `data/talents/_pet.json` | pet talent tabs (`petTalentMask` set) - not tied to a single player class | small |
| `data/talents/_unassigned.json` | talent tabs matching no classMask/petTalentMask | small |
| `data/talents/_meta.json` | tab/talent counts, per-class tab counts, unresolved rank-spell count | small |
| `data/dungeons/dungeons.json` | all LFG dungeons/raids + encounters + reward brackets | medium |
| `raw/dbc/*.csv.gz` | full decoded DBC dumps (every column) | large |
| `raw/content/*.json` | verbatim client sidecar JSONs | large |
| `raw/provenance.json` | source hashes, archive resolution, build stats | small |

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
  (miscValue = dispel type id it removes).
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
  talents through `CharacterAdvancementData` entries instead - in
  `data/classes/<Class>.json`, look for entries with `type == "Talent"` or
  `"TalentAbility"`. If you're asked "what talents does class X have" and X isn't
  one of the 12, `data/talents/` will have no file for it - that's expected; the
  answer lives in the class file's CAD entries, not the DBC talent tree.

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

All encounters of a raid: `data/dungeons/dungeons.json` -> filter `map.isRaid`,
read `encounters` (ordered).

A dungeon's reward for a given character level: `data/dungeons/dungeons.json` ->
`dungeons[i]["rewards"]` is a **list** of level-bracket objects sorted by
`MaxLevel` ascending (most dungeons have one bracket or none - 4 dungeons have
several, e.g. dungeon id 258 has 17); pick the first bracket whose `MaxLevel` is
>= the character's level, and treat an empty list as "no reward data", not an error.

## Honest limits

- Client data cannot see server-side logic: boss scripts, loot tables, runtime
  spell grants, proc internals. Encounter lists are names/order only.
- `CharacterAdvancementData.json` is account-wide across the four realms this
  client serves (see Key semantics above); Reborn*-class spell refs are expected
  to resolve `null` far more often than other classes in this snapshot - that's a
  data-availability fact of the capture, not a pipeline bug.
  `data/spells/_meta.json` records this precisely: `missing_refs_by_source`
  buckets every missing id into `cad_other` / `cad_reborn` / `talent` / `rank`, and
  `ref_counts` gives the denominator for each bucket. The build only hard-gates
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
  (`type == "Talent"`/`"TalentAbility"` in `data/classes/<Class>.json`) - absence
  from `data/talents/` does not mean the class has no talents.
