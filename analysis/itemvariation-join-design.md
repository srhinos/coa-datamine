# ItemVariationData join design (task W4-11d)

Design doc only - **not implemented**. Per DATAMINE-REQUEST.md Sec 8.3: "Joining
[`ItemVariationData.json` and the aowow variant measurement] - mapping a scraped
variant id back to its base item - is squarely datamine work and nobody has done
it." This documents the mapping-rule evidence (independently re-derived against
`raw/content/ItemVariationData.json`, not copied from the source doc) and what a
future implementation would need to actually build the join.

## 1. What's already on disk

`raw/content/ItemVariationData.json` is already shipped, unchanged by this task:
10,830 records, each `{Normal, Heroic, Mythic: [40 ints], Bloodforged}` - four item
ids that are variants of the same base item at different difficulty/prestige tiers.
Re-derived directly (not from the source doc):

- 10,574 rows have a nonzero `Normal` id, 10,495 have both `Normal` and every other
  field populated (the "fully-populated" row set this analysis uses below).
- Every `Mythic` array is exactly 40 slots long, always - no row has a different
  length. Many trailing slots are `0` (unused/no keystone tier that high existed
  when this row was authored).
- **No item names or display strings anywhere in this file** - it is a pure id-to-
  id mapping table, consistent with `Item.dbc` itself carrying zero strings (Sec
  8.1's "Item.dbc is an index, not a stat source" framing extends to this file too).

## 2. The offset evidence, re-derived fresh

For every row with both `Normal` and a given variant field nonzero, this analysis
computed `variant_id - normal_id` and histogrammed the deltas (`n = 10,495`
matched rows for each pair):

| Variant | Dominant delta | Coverage | Verdict |
|---|---:|---:|---|
| `Bloodforged - Normal` | **+6,000,000** | 10,022/10,495 = **95.5%** | a real, reliable arithmetic rule |
| `Heroic - Normal` | +300,000 | 2,443/10,495 = **23.3%** | a rule for a MINORITY only |
| `Mythic[0] - Normal` | +200,000 | 2,451/10,495 = **23.4%** | a rule for a MINORITY only |

**Bloodforged is the one clean case** - it is safe to treat `base_id + 6,000,000`
as a strong prior for "this is probably the Bloodforged variant," though the
remaining 4.5% (473 rows) still need the real per-row lookup, not the formula.

**Heroic and Mythic are NOT single global-offset rules.** Beyond the dominant
+300,000/+200,000 cluster, the remaining ~77% of matched rows scatter across many
smaller, non-round clusters - e.g. Heroic-Normal also clusters at `+333,665` (80
rows), `+334,952` (57), `+341,486` (41), `+96,816` (30), `+342,200` (28), `+90,814`
(25), `+3,000,000` (24), and dozens of clusters below 20 rows. **Read this as: an
early/simple content patch used a clean `+300,000`/`+200,000` id-block convention,
and every later patch just assigned whatever id was free at authoring time** - the
messy tail is ordinary content-patch history, not a decode failure. A correct
implementation **must use `ItemVariationData.json` as a literal lookup table**,
never an arithmetic formula, for anything except a best-effort Bloodforged guess.

**Consecutive `Mythic[i+1] - Mythic[i]` deltas** (adjacent keystone-level slots)
show the same two-population shape: `+1` appears 54,876 times (padding/near-
duplicate ids, not real distinct items) while the "real" keystone-level ramp
clusters tightly around `+6,563` (24,536 occurrences) with nearby values
(`6564`/`6565`/`6613`/`6598`/`6662`/`6668`/`6664`/`6604`, each in the hundreds) -
consistent with `data/mythic/keystones/` elsewhere in this repo, where each
dungeon's Mythic+ ladder runs many levels deep and each level's variant item gets
a freshly-assigned id, not a formula-derived one.

## 3. The "+1,600,000 Prestigious" claim: NOT reproducible from this repo's own data

DATAMINE-REQUEST.md Sec 8.3 cites "variant id offsets including +1,600,000 for
'Prestigious'" as an aowow-side finding. **This analysis searched exhaustively for
it and could not find it**: every `Normal`-vs-`{Heroic, Bloodforged, every Mythic
slot}` delta across all 10,495 matched rows was checked for a value within 50 of
+1,600,000 - **zero matches**.

This is not a contradiction of the source doc, but a scope gap worth naming
explicitly: **`ItemVariationData.json` carries no item names**, so "Prestigious" is
necessarily an aowow-side label, not something this file's own columns can confirm
or deny. Either (a) "Prestigious" is a tier this file doesn't carry at all (a fifth
variant category outside `{Normal, Heroic, Mythic, Bloodforged}`), or (b) the
+1,600,000 offset is relative to something other than `Normal` (e.g. relative to a
different variant, or specific to one item family this analysis's aggregate
histogram would wash out). **Flagged as unverified-by-this-task, not disproven** -
a future implementation needs the actual aowow scrape (which has names) to check
this against, exactly as Sec 8's own framing says ("we are not asking you to own
item acquisition").

## 4. Cross-reference against this task's own `Item.dbc`/`ItemStat` additions

Task W4-11a/b added `Item.dbc` (raw index, 563,335 ids) and `ItemStat.dbc` (stat
coverage for 20,267 items) to this pipeline for the first time. Re-derived join
rates of `ItemVariationData.json`'s own ids against them:

| Field | vs `Item.dbc` | vs `ItemStat` coverage (`data/items/statsByItem/`) |
|---|---:|---:|
| `Normal` | 10,569/10,574 = **100.0%** | 1,405/10,574 = 13.3% |
| `Heroic` | 10,283/10,495 = **98.0%** | (not separately measured) |
| `Bloodforged` | 10,619/10,699 = **99.3%** | (not separately measured) |
| `Mythic[0]` | 9,190/10,749 = **85.5%** | (not separately measured) |
| `Mythic` (all 40 slots) | 173,930/422,027 = 41.2% (padding drags this down) | (not separately measured) |

**This matters for the design**: `Normal`/`Heroic`/`Bloodforged`/`Mythic[0]` are
near-universally real, live `Item.dbc` ids in THIS repo's own snapshot - a future
join does not need to trust the external aowow scrape's id space at all for
existence-checking, only for names/display strings. But `ItemStat` coverage of even
the `Normal` (base) id is only 13.3% - consistent with Sec 8.2's own "not a primary
CoA source" verdict - so resolving a variant id back to its base item id will very
often NOT come with a stat row in this pipeline today. The aowow scrape stays the
sim's primary stat source per Sec 8's framing; this pipeline's role is
existence/identity validation, not stat curation.

## 5. What a future implementation needs

1. **A reverse-lookup table, not a formula**: for every one of the 10,495 fully-
   populated rows, index `Heroic -> Normal`, `Bloodforged -> Normal`, and each
   `Mythic[i] -> (Normal, i)` (keystone level `i`). That is up to
   `10,495 * (1 + 1 + 40) = 440,790` reverse entries (most `Mythic` slots are `0`
   and get skipped, so the real count is smaller - see the 422,027 nonzero-slot
   figure above). **This would need Amendment C sharding if ever curated into
   `data/`** (id-range bucketed, same convention as `data/items/statsByItem/`) -
   it is far larger than the 5,000-line gate as one file.
2. **The aowow scrape itself**, which this pipeline does not own (Sec 8's explicit
   framing) - needed for: item names/display strings (this file has none), and to
   actually test the "+1,600,000 Prestigious" claim from Sec 3 above.
3. **A collision policy**: the source doc's own aowow-side measurement found
   "~1.32x variant inflation" (1,000 scraped rows collapse to 760 distinct
   name+displayid groups) - meaning aowow's own listing already has multiple scraped
   rows that are the SAME real item at different tiers. A join implementation needs
   to decide whether to de-duplicate on the `Normal` (base) id before or after
   attaching aowow's per-tier stat/name data, and how to handle a scraped id that
   matches more than one `ItemVariationData.json` row (not observed as a real risk
   in this analysis - every reverse-lookup key checked above was a plain dict build
   with no collision handling needed, but a future implementation should assert this
   rather than assume it, the same "golden gate, refuse to publish if it breaks"
   discipline this repo uses elsewhere, e.g. `build_creatures.py`).
4. **Given the join surfaces this analysis found (Sec 4's table)**, the most useful
   FIRST deliverable is probably not a full aowow join at all, but a standalone
   `data/items/variantsByNormalId/` (or similar) curation of
   `raw/content/ItemVariationData.json` ALONE against this repo's own `Item.dbc` -
   i.e. "which of my 20,267 `ItemStat`-covered items have known Heroic/Mythic/
   Bloodforged variant ids, and do those variant ids themselves have `ItemStat`
   coverage" - entirely re-derivable from already-committed data, no external
   scrape dependency, and a natural stepping stone before attempting the harder
   aowow-name join.
