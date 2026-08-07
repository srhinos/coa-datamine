"""Build data/spells/spells.jsonl: every referenced spell, fully enriched.

Referenced = CharacterAdvancementData spells + SpellRankData chains + Talent.dbc
ranks, then closed transitively over EffectTriggerSpell (tag "trigger").

Amendment C: output is sharded data/spells/by-id/spells-<id//BUCKET_SIZE*BUCKET_SIZE>.jsonl
+ data/spells/index.json (bucket manifest); _meta.json keeps counts only, full
missing-ref id lists live in _missing_refs.json (one line per source array).

Task V2-4: records gain proven enrichment fields ONLY where data exists (no
null-noise) - tags (SpellTags/SpellTagTypes), customAttr (SpellCustomAttr),
descriptionVariables (SpellDescriptionVariables via the existing
spellDescriptionVariableID column), category (SpellCategory via the existing
category column), addon (SpellAddon), overrideData (OverrideSpellData). See
dbc.py's TABLE_MAPS comments for full golden-record proofs; _meta.json's
"enrichment" block carries per-field coverage counts, an unattached finding for
SpellAlternativePowerType (no provable per-spell link), and a "charges" block
pointing at data/spells/charges.json - SpellCharges/SpellChargesCategory are
proven internally but SpellCharges' link to live Spell.dbc rows misses the
brief's >=90% attach bar, so they ship curated STANDALONE (own file, not
per-spell fields) instead of report-only. Task W4-10 adds the same standalone-file
shape for SpellStatSuggestions -> data/spells/statSuggestions.json (proven spellId
key, unproven payload category kept raw and clearly flagged)."""
import csv, gzip, json, re, shutil
from collections import defaultdict

from tools import config, dbc, enums335, sharding

BUCKET_SIZE = 10000

# [Task W4-4] Formula-reference closure (DATAMINE-REQUEST.md Sec 1.6): CoA authors
# damage scaling in description/tooltip text, and 622/1,694 CoA damaging spells
# cross-reference ANOTHER spell id from their own formula (e.g. Crusader's Brand
# 300513's tooltip reads "${$573020m1*$<scalingbp>+...}" - it needs 573020's own m1
# value). The curation closure (cad/rank/talent/trigger, above) never followed these.
#
# Grammar, re-derived from work/dbc/Spell.dbc (not copied from the doc - binding
# rule): the doc states the base shape as "$<id><letter><n>" (e.g. $573020m1,
# $7376S1), but a direct regex on that shape undercounted the doc's own measured
# depth-1/depth-2 yield by ~1/3. Widening it to what's actually on disk closed most
# of the gap:
#   - the "letter" segment is often MULTI-character, not always one letter -
#     "$80313ppl1" / "$202137PPL1" (a cross-spell EffectRealPointsPerLevel reference,
#     the same "ppl" token used bare for a spell's own effect) are real and common.
#   - a large family has NO trailing rank/effect digit at all - "$6788d" (another
#     spell's duration), "$49188h" (another spell's proc chance) - these are
#     "$<id><letter-word>" with nothing after. Some of these have garbled trailing
#     text from what looks like a authoring/templating artifact (e.g. "$10475donds"
#     is "$10475d" + a mangled "seconds" with no separator) - the id capture is
#     still correct regardless, so these are kept, not filtered.
#   - an optional "/<n>;" tick-rate infix shows up before the letter in "per N
#     seconds" tooltip macros - "$25695/5;s1" (Restores $25695/5;s1 health).
# Deliberately NOT widened to a bare "$<id>%" or "$<id>," form (27 + a handful of
# occurrences): those collide with genuinely bare small numbers used as literal
# percentages ("$1%", "$2%" - not spell ids), and Spell.dbc's own low-id range is
# real content (id 1-3 exist), so a size-based heuristic to tell them apart would
# be exactly the "dense-id join-rate lies" trap this repo's memory warns about -
# left unfollowed rather than guessed.
#
# [Review fix] The widened no-trailing-digit shape collides with a DIFFERENT real
# authoring artifact: a same-spell "$s1"/"$m1"/etc. self-value token, TRANSPOSED
# by a tooltip typo into "$1s"/"$1m" (digit-then-letter instead of letter-then-
# digit) - e.g. Rejuvenation (28722) reads "Restores $s1 mana.\n$1s mana
# restored." twice in the same tooltip, once correctly and once transposed.
# Confirmed on 28 spells sharing this exact "$1s" template (Nature's Bounty,
# Adrenaline Rush, Healing Touch, Lesser Healing Wave, Consume Essence/Life,
# Elune's Touch, Revitalize, Infusion, Efficiency, Soul of the Dead, and every
# rank of Rejuvenation/Surging Mana) - each one misreads as "a reference to spell
# id 1" (the "UPDATE YOUR CLIENT!" placeholder row). Harmless in THIS snapshot
# only because id 1 (and the similar self-ref cases "$10d"/"$66d" - Blizzard and
# Invisibility referencing their own id instead of the bare "$d" token) were
# already closure-reachable before this task ran, by luck, not by design - a
# future client patch could easily produce the same transposition typo against
# an id that ISN'T already reachable, silently pulling in an unrelated spell.
#
# Fix: split into a STRICT form (the doc's literal cited shape - single letter,
# MANDATORY trailing digit, e.g. $573020m1, $67s1) which stays completely
# unrestricted - it cannot arise from this transposition (a transposed "$s1" has
# no trailing digit at all) and is proven safe down to 2-digit ids (Vindication
# 67, a genuine external cross-ref) - and a WIDE form (multi-letter tokens,
# no-trailing-digit tokens, the /N; infix) which additionally requires the
# candidate id to have >=3 DIGITS before it can enter the closure. Legitimate
# cross-refs actually used by this widened grammar are 3+ digit ids throughout
# this dataset (67 is the sole 2-digit case, and it is captured by the STRICT
# form regardless via its own "$67s1" trailing-digit occurrence, so nothing is
# lost); the transposition-typo class is always a 1-2 digit id (the same digit(s)
# that were meant to be the token's OWN rank/effect number, e.g. "1" in "$s1").
FORMULA_XREF_STRICT_RE = re.compile(r"\$(\d+)[A-Za-z](\d+)")
FORMULA_XREF_WIDE_RE = re.compile(r"\$(\d+)(?:/\d+;)?[A-Za-z]+(\d*)")
FORMULA_XREF_WIDE_MIN_DIGITS = 3

# "$?s<id>" per the doc; re-derivation found the same conditional-reference
# construct also spelled with other single letters ($?a<id> 258x, $?S<id> 3x,
# $?j<id> 3x) - same directive family (a conditional cross-spell value pick), so
# the letter is generalized rather than hardcoded to "s" alone.
FORMULA_QS_RE = re.compile(r"\$\?[a-zA-Z]+(\d+)")

FORMULA_IFKNOWN_RE = re.compile(r"@ifknown:(\d+)")

# NOTE: "@s:<id>" is deliberately NOT a followed form here - DATAMINE-REQUEST.md
# Sec 1.6 proved it is a spellbook cross-link, not a formula reference (following
# it changed zero coverage buckets in the source audit). Re-verified informally
# during this task: @s: targets are overwhelmingly already-closed ids (spellbook
# entries point at abilities a player already has), so it would add near-zero
# records anyway even where it does resolve - the null result is a documented
# finding, not an oversight.

FORMULA_CLOSURE_MAX_DEPTH = 2


def _formula_ref_ids(text):
    """Extract every cross-spell id referenced by the followed forms above.
    Returns a set of ints; empty for falsy/None text (never raises).

    [Review fix] FORMULA_XREF_WIDE_RE is guarded to >=3-digit ids only - see its
    definition above for why (the $1s-style transposition-typo trap). The STRICT
    form, $?<letters><id>, and @ifknown:<id> are unguarded (all proven safe, or in
    $?/@ifknown's case not implicated by the reviewed false-positive class)."""
    if not text:
        return set()
    ids = {int(m.group(1)) for m in FORMULA_XREF_STRICT_RE.finditer(text)}
    ids.update(int(m.group(1)) for m in FORMULA_XREF_WIDE_RE.finditer(text)
               if len(m.group(1)) >= FORMULA_XREF_WIDE_MIN_DIGITS)
    ids.update(int(m.group(1)) for m in FORMULA_QS_RE.finditer(text))
    ids.update(int(m.group(1)) for m in FORMULA_IFKNOWN_RE.finditer(text))
    return ids


# [Task W4-4] DATAMINE-REQUEST.md Sec 4 trap 17: dev-dead content ships in the data
# with an unmistakable authored marker. Verified by scanning every Spell.dbc
# description/tooltip for the literal phrase (not a loose "does not work" substring
# - that also matches ordinary tooltip caveats like Pyrolate's "Does not work with
# Elemental Destr[uction]", a false-positive trap found while deriving this) -
# exactly 7 rows carry it, all one rank chain (Pyromancer Flame Swell, ranks
# 502065-502071). The doc's own count ("Three such slots") is over a narrower,
# differently-shaped population (damaging EFFECT SLOTS within the level-60-reachable
# set, not spell records) - not directly comparable to a per-record flag; this task
# flags every RECORD carrying the marker, independently re-derived, not copied.
DEV_DEAD_MARKER = "DOES NOT WORK, YOU SHOULD NOT HAVE IT"


def iter_all():
    """Yield every spell record across all id-bucket shards, via index.json - the
    reader path for build_classes._spell_min / build_talents._spell_names."""
    out_dir = config.DATA_DIR / "spells"
    index = json.loads((out_dir / "index.json").read_text(encoding="utf-8"))
    for b in index["buckets"]:
        with open(out_dir / b["file"], encoding="utf-8") as fh:
            for line in fh:
                yield json.loads(line)


def _write_missing_refs(path, missing_by_source):
    """Amendment C: each source's array on ONE line, not json.dumps(indent=...)'d
    (which would put one id per line and blow past the 5,000-line gate)."""
    keys = sorted(missing_by_source)
    lines = ["{"]
    for i, k in enumerate(keys):
        arr = json.dumps(missing_by_source[k], separators=(",", ":"))
        comma = "," if i < len(keys) - 1 else ""
        lines.append(f' "{k}": {arr}{comma}')
    lines.append("}")
    path.write_text("\n".join(lines) + "\n", encoding="utf-8", newline="\n")


def _content(name):
    return json.loads((config.RAW_CONTENT_DIR / name).read_text(encoding="utf-8-sig"))


def _initial_refs(cad):
    refs = {}
    def add(i, tag):
        if i:
            refs.setdefault(int(i), set()).add(tag)
    for e in cad:
        for s in e.get("Spells", []):
            add(s, "cad")
    for e in _content("SpellRankData.json"):
        add(e["spellId"], "rank")
        add(e["firstSpellId"], "rank")
    for t in dbc.iter_named("Talent"):
        for i in range(1, 10):
            add(t[f"rankSpell{i}"], "talent")
    return refs


def _cad_realm_split(cad):
    """Amendment A: CharacterAdvancementData.json is account-wide across four realms;
    Reborn*-class entries belong to "Bronzebeard - Warcraft Reborn", whose spell data
    isn't materialized in this client's Spell.dbc snapshot. Split CAD-referenced ids
    into "referenced by >=1 non-Reborn entry" vs "referenced only by Reborn entries"."""
    other, reborn = set(), set()
    for e in cad:
        bucket = reborn if str(e.get("Class", "")).startswith("Reborn") else other
        for s in e.get("Spells", []):
            if s:
                bucket.add(int(s))
    reborn -= other
    return other, reborn


def _bucket(tags, cad_other_ids, cad_reborn_ids, sid):
    if sid in cad_other_ids:
        return "cad_other"
    if sid in cad_reborn_ids:
        return "cad_reborn"
    if "talent" in tags:
        return "talent"
    return "rank"


def _rank_at_60_map():
    """[Task W4-4] Per rank chain (grouped by SpellRankData's firstSpellId), the top
    rank whose CAD level (SpellRankData.json's own "level" field) is <= 60 -
    DATAMINE-REQUEST.md Sec 1.7: a consumer taking ranks[-1] (global top) gets an
    ability the player cannot have at the level-60 cap on 92.2% of multi-rank CoA
    chains (re-derived here over ALL rank chains incl. stock: 1,445/2,130 = 67.8%
    have a different top-at-60 pick - narrower than the doc's CoA-only figure, same
    "our closure is a superset" pattern seen throughout this task).

    Gating field is [INFERRED]-CAD per the doc: CAD ranks[].level and DBC spellLevel
    agree on only 32.0% of rows and pick a different level-60 rank on 512/920 CoA
    chains - UNRESOLVED, needs an in-game /dump to confirm which field the Ascension
    server actually gates on. This function follows CAD level (the doc's own
    reasoning: CAD is what grants the rank on Ascension), NOT DBC spellLevel - see
    AGENT-GUIDE.md for the caveat, repeated here since it is load-bearing for every
    consumer of this field.

    Returns {firstSpellId: {"spellId", "rank", "cadLevel"}}. A chain where even rank
    1 requires CAD level > 60 (47 of 2,130 in this snapshot - stock 61-80 content
    with no level-60-reachable rank at all) gets no entry - per this repo's no-null-
    noise convention, the caller omits the key entirely rather than emitting a
    misleading rankAt60 for an ability the character can never have any rank of."""
    chains = defaultdict(list)
    for e in _content("SpellRankData.json"):
        chains[e["firstSpellId"]].append(
            {"spellId": e["spellId"], "rank": e["rank"], "cadLevel": e["level"]})
    out = {}
    for first_id, ranks in chains.items():
        ranks.sort(key=lambda x: x["rank"])
        eligible = [r for r in ranks if r["cadLevel"] <= 60]
        if eligible:
            out[first_id] = eligible[-1]              # highest rank among those <=60
    return out


def _scalingbp_constant():
    """[Task W4-4] DATAMINE-REQUEST.md Sec 1.8: CoA's one global base-point level
    curve, SpellDescriptionVariables.dbc row id 182, referenced by 550 spells via the
    literal token "$<scalingbp>" in their formula text (both figures re-derived
    fresh against work/dbc, not copied - see task report). Coefficients are parsed
    out of the live SDV row text (not hardcoded) so a client patch that changes them
    fails loudly (assert) instead of silently going stale.

    Framing (binding rule): this is a LEVEL NORMALISER, not a stat coefficient - it
    crosses 1.0 at PL ~= 60.46 and sits at 0.9874 at CoA's level-60 cap, independent
    confirmation the content is authored at a 60 cap. A consumer applies it as a
    multiplier on basePoints for spells whose formula references it; it is not
    itself a source of gear/stat scaling."""
    sdv = {r["id"]: r["text_enUS"] for r in dbc.iter_named("SpellDescriptionVariables")}
    text = sdv.get(182, "")
    m = re.search(
        r"\$scalingbp\s*=\s*\$\{\(([-\d.]+)\+([-\d.]+)\*\$PL\+([-\d.]+)\*\$PL\*\$PL\)\}",
        text)
    assert m, f"$scalingbp SDV row 182 shape changed - re-derive: {text!r}"
    c0, c1, c2 = (float(m.group(i)) for i in (1, 2, 3))

    def value_at(pl):
        return c0 + c1 * pl + c2 * pl * pl

    ref_count = sum(
        1 for r in dbc.iter_named("Spell")
        if re.search(r"\$<\s*scalingbp\s*>", (r["description_enUS"] or "")
                     + (r["tooltip_enUS"] or ""), re.IGNORECASE))
    return {
        "sdvId": 182,
        "rawText": text,
        "formula": f"{c0} + {c1} * $PL + {c2} * $PL * $PL",
        "referencedBySpellCount": ref_count,
        "framing": ("Level normaliser, NOT a stat coefficient: crosses 1.0 at "
                    "PL ~= 60.46 and sits at 0.9874 at CoA's level-60 cap - "
                    "independent confirmation CoA content is authored at a 60 cap. "
                    "Consumers multiply a spell's basePoints by this value when the "
                    "spell's formula text references \"$<scalingbp>\"; it carries no "
                    "gear/stat scaling of its own."),
        "valueTable": {str(pl): round(value_at(pl), 4) for pl in range(1, 81)},
        "citedBreakpoints": {str(pl): round(value_at(pl), 4)
                              for pl in (1, 20, 40, 55, 60, 61, 70, 80)},
    }


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
        "rankAt60": _rank_at_60_map(),
    }


def _spell_tags(ref_ids):
    """Task V2-4: SpellTags.dbc has 488,661 rows - stream raw ints directly (no
    per-row dict via dbc.iter_named) and keep only rows whose proven spellId (f1)
    is in the referenced-spell set, per the brief's memory-streaming note. tagTypeId
    (f2) resolves through SpellTagTypes.name_enUS (f27, proven - see dbc.py).

    Intentional dedup: `out[sid]` is a set, so two different tagTypeIds that happen
    to decode to the same display name (e.g. spell 17 carries BOTH a "Class: Priest"
    tag and a "Specialization: Priest" tag - two distinct SpellTagTypes rows, same
    name_enUS) collapse into a single "Priest" entry in the output `tags` list. This
    is deliberate: `tags` is a display-name list, not a tagTypeId list, and the brief
    asks for `tags: [tagNames]` - a repeated identical string would be redundant
    noise for a consumer, not signal. Pinned by a golden in tests/test_spells_v2.py
    (spell 17's tags contains "Priest" exactly once)."""
    tagtype_name = {r["id"]: r["name_enUS"] for r in dbc.iter_named("SpellTagTypes")}
    f = dbc.DBCFile(config.WORK_DBC_DIR / "SpellTags.dbc")
    out = defaultdict(set)
    for row in f.iter_rows():
        sid = dbc.u32(row[1])
        if sid in ref_ids:
            name = tagtype_name.get(dbc.u32(row[2]))
            if name:
                out[sid].add(name)
    return {sid: sorted(names) for sid, names in out.items()}


def _spell_custom_attr():
    """SpellCustomAttr: proven spellId is f1 (not f0, the brief's hypothesis - see
    dbc.py). Remaining 10 columns [f0, f2..f10] carried as a raw customAttr array."""
    f = dbc.DBCFile(config.WORK_DBC_DIR / "SpellCustomAttr.dbc")
    out = {}
    for row in f.iter_rows():
        sid = dbc.u32(row[1])
        out[sid] = [dbc.u32(row[0])] + [dbc.u32(row[i]) for i in range(2, 11)]
    return out


def _spell_addon():
    """SpellAddon: proven spellId is f1 (not f0, the brief's hypothesis - see dbc.py).
    Remaining 22 columns [f0, f2..f22] carried as a raw addon.raw array."""
    f = dbc.DBCFile(config.WORK_DBC_DIR / "SpellAddon.dbc")
    out = {}
    for row in f.iter_rows():
        sid = dbc.u32(row[1])
        out[sid] = [dbc.u32(row[0])] + [dbc.u32(row[i]) for i in range(2, 23)]
    return out


def _override_spell_data():
    """OverrideSpellData: f0 = base/trigger spellId, f1-f10 = up to 10 override spell
    ids (nonzero slots only), f11 = unproven raw flag/count. Rows with no override
    spells AND a zero flag carry no data and are skipped."""
    f = dbc.DBCFile(config.WORK_DBC_DIR / "OverrideSpellData.dbc")
    out = {}
    for row in f.iter_rows():
        base = dbc.u32(row[0])
        overrides = [dbc.u32(row[i]) for i in range(1, 11) if dbc.u32(row[i])]
        flag = dbc.u32(row[11])
        if overrides or flag:
            out[base] = {"spells": overrides, "raw": flag}
    return out


def _v2_aux(ref_ids):
    """Task V2-4 enrichment lookups, built once per build() call. SpellCharges/
    SpellChargesCategory and SpellAlternativePowerType are proven internally (see
    dbc.py) but attach nothing to spell records - documented in _meta.enrichment
    instead (see build())."""
    return {
        "tags": _spell_tags(ref_ids),
        "customAttr": _spell_custom_attr(),
        "addon": _spell_addon(),
        "override": _override_spell_data(),
        "descvars": {r["id"]: r["text_enUS"] for r in dbc.iter_named("SpellDescriptionVariables")},
        "categoryIds": {r["id"] for r in dbc.iter_named("SpellCategory")},
    }


def _record(r, aux, tags, v2):
    a = aux
    effects = []
    for slot in (1, 2, 3):
        eff = r[f"effect{slot}"]
        if not eff:
            continue
        radius = a["rad"].get(r[f"effectRadiusIndex{slot}"])
        e = {
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
        }
        # [Task W4-3] 5 new per-effect columns (DATAMINE-REQUEST.md Sec 1.2/1.4),
        # all omitted from this slot's dict when their raw DBC value is the
        # literal zero word - consistent with the v2 enrichment convention
        # (_enrich_v2 below: "no null-noise", absent key not null) rather than
        # the older always-present convention basePoints/dieSides/etc. use above.
        # This matters most for damageMultiplier/bonusMultiplierStock, whose
        # in-DBC "no data here" sentinel really is a literal 0 float bit pattern
        # (0x00000000), distinct from their in-game default of 1.0 (0x3F800000,
        # which - when actually authored - is kept and emitted, not treated as
        # absent). See tools/dbc.py's TABLE_MAPS comments for the golden proofs.
        rppl = r[f"effectRealPointsPerLevel{slot}"]
        if rppl:
            e["realPointsPerLevel"] = rppl
        ppc = r[f"effectPointsPerComboPoint{slot}"]
        if ppc:
            e["pointsPerComboPoint"] = ppc
        mask = [r[f"effectSpellClassMaskA{slot}"], r[f"effectSpellClassMaskB{slot}"],
                r[f"effectSpellClassMaskC{slot}"]]
        if any(mask):
            e["spellClassMask"] = mask
        dmul = r[f"effectDamageMultiplier{slot}"]
        if dmul:
            e["damageMultiplier"] = dmul
        # bonusMultiplierStock: correct for stock/Reborn content, CONTRADICTS
        # CoA's own tooltip-authored coefficient on the same slot far more often
        # than it agrees (Sec 2: stock 0/37, CoA re-derived below) - deliberately
        # named to flag the caveat rather than implying it's a trustworthy CoA
        # coefficient. Never unioned with the tooltip/description text.
        bmul = r[f"effectBonusMultiplier{slot}"]
        if bmul:
            e["bonusMultiplierStock"] = bmul
        effects.append(e)
    cast = a["cast"].get(r["castingTimeIndex"])
    dur = a["dur"].get(r["durationIndex"])
    rng = a["rng"].get(r["rangeIndex"])
    rank = a["rank"].get(r["id"])
    role = a["roles"].get(r["id"])
    rune = a["rune"].get(r["runeCostID"]) if r["runeCostID"] else None
    sid = r["id"]
    rec = {
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
                   "flags2": r["spellFamilyFlags2"], "flags3": r["spellFamilyFlags3"]},
        "runeCost": ({"blood": rune["blood"], "unholy": rune["unholy"],
                      "frost": rune["frost"], "runicPower": rune["runicPower"]}
                     if rune else None),
        # [Task W4-3] spell-level columns from DATAMINE-REQUEST.md Sec 1.3 (8
        # already-mapped-but-dropped columns - zero new column proofs, re-
        # verified fill rates against work/dbc anyway) + Sec 1.4 (equipped-item
        # sub-masks + spellMissileID). Always present, matching this record's
        # existing top-level convention (manaCost/procChance/etc. are never
        # omitted even when 0) - unlike the per-effect fields above, these are
        # single scalars per spell, not 3x-duplicated per slot, so there's no
        # null-noise concern from keeping them unconditional.
        "speed": r["speed"],
        "equippedItem": {"itemClass": r["equippedItemClass"],
                          "subClassMask": r["equippedItemSubClassMask"],
                          "inventoryTypeMask": r["equippedItemInventoryTypeMask"]},
        "maxAffectedTargets": r["maxAffectedTargets"],
        "casterAuraSpell": r["casterAuraSpell"], "targetAuraSpell": r["targetAuraSpell"],
        "manaPerSecond": r["manaPerSecond"],
        "targetCreatureType": r["targetCreatureType"],
        "casterAuraState": r["casterAuraState"], "targetAuraState": r["targetAuraState"],
        "stancesNot": r["stancesNot"],
        "missileId": r["spellMissileID"],
        "effects": effects,
        "rankChain": ({"first": rank["firstSpellId"], "rank": rank["rank"],
                       "level": rank["level"]} if rank else None),
        "roles": ({"tank": role["TankScore"], "healer": role["HealerScore"],
                   "damage": role["DamageScore"]} if role else None),
        "referencedBy": sorted(tags),
    }
    # [Task W4-4] rankAt60 (Sec 1.7): emitted only on the chain's OWN first-rank
    # record (rankChain.first == this record's id, i.e. sid == rank["firstSpellId"])
    # - a per-chain convenience field belongs on one record, not duplicated across
    # every rank. Omitted (no null-noise) when the chain has no rank <= CAD level 60
    # at all (see _rank_at_60_map).
    if rank and sid == rank["firstSpellId"]:
        r60 = a["rankAt60"].get(sid)
        if r60:
            rec["rankAt60"] = r60
    # [Task W4-4] devDead (Sec 4 trap 17): literal marker text, re-verified by scan
    # (see DEV_DEAD_MARKER's docstring) - not a loose "does not work" substring,
    # which false-positives on ordinary tooltip caveats.
    dead_text = (r["description_enUS"] or "") + (r["tooltip_enUS"] or "")
    if DEV_DEAD_MARKER in dead_text.upper():
        rec["devDead"] = True
    _enrich_v2(rec, r, sid, v2)
    return rec


def _enrich_v2(rec, r, sid, v2):
    """Task V2-4: add enrichment keys ONLY where proven data exists for this spell -
    no null-noise (binding rule: absent keys are omitted entirely, never null)."""
    spell_tags = v2["tags"].get(sid)
    if spell_tags:
        rec["tags"] = spell_tags
    custom_attr = v2["customAttr"].get(sid)
    if custom_attr is not None:
        rec["customAttr"] = custom_attr
    if r["spellDescriptionVariableID"]:
        text = v2["descvars"].get(r["spellDescriptionVariableID"])
        if text:
            rec["descriptionVariables"] = text
    if r["category"] and r["category"] in v2["categoryIds"]:
        rec["category"] = r["category"]
    addon = v2["addon"].get(sid)
    if addon is not None:
        rec["addon"] = {"raw": addon}
    override = v2["override"].get(sid)
    if override is not None:
        rec["overrideData"] = override


def _charges_realm_check(non_joining_refs: set) -> dict:
    """[Task W4-11f] DATAMINE-REQUEST.md Sec 11's own open question about the
    SpellCharges join gap: "a path to closing the join would be valuable" - are the
    base-non-joining refs realm-overlay ids, or dead? For each realm whose own
    Spell.dbc dump is already committed (raw/realms/<realm>/dbc/Spell.csv.gz -
    written by a prior tools/build_realms.py run; this reads that static sibling
    artifact directly, no live re-extraction and no dependency on build_realms
    running first in THIS session/pipeline order), checks how many of the
    non-joining refs exist as a real id there. Returns {} if no realm dump is on
    disk at all (e.g. a checkout with raw/realms/ absent)."""
    if not non_joining_refs or not config.RAW_REALMS_DIR.is_dir():
        return {}
    out = {}
    for realm_dir in sorted(config.RAW_REALMS_DIR.iterdir()):
        p = realm_dir / "dbc" / "Spell.csv.gz"
        if not p.is_file():
            continue
        realm_ids = set()
        with gzip.open(p, "rt", encoding="utf-8", newline="") as fh:
            for row in csv.DictReader(fh):
                realm_ids.add(int(row["id"]))
        hits = sorted(r for r in non_joining_refs if r in realm_ids)
        out[realm_dir.name] = {"realmSpellCount": len(realm_ids),
                               "resolvedRefs": hits}
    return out


def _build_charges(out_dir):
    """SpellCharges/SpellChargesCategory (Task V2-4 review fix): the brief's fallback
    for a sub-90%-proven link is to ship the tables curated STANDALONE, not just
    report join statistics - writes data/spells/charges.json (build_spells owns
    data/spells/, single-writer rule unaffected) and returns the _meta.json
    enrichment.charges block. SpellCharges.f0 is unnamed in TABLE_MAPS per the
    empirical mapping rule (88.5% join vs live Spell.dbc ids, short of the brief's
    explicit >=90% bar for this pair); exposed here as "ref" - a deliberately
    noncommittal name, not "spellId" - with resolvedSpellName null where it doesn't
    resolve. categoryId (f1) is proven at 100% against SpellChargesCategory.id.
    Full evidence (incl. the tooltip-text semantic corroboration among
    resolved rows) is in dbc.py's TABLE_MAPS comment.

    [Task W4-11f] Characterizes the non-joining refs against realm-overlay Spell
    data (see _charges_realm_check above) and only flips "attached"/re-derives the
    join rate if PROVEN-dead refs (resolving in NEITHER the base client NOR any
    committed realm overlay) can be excluded to legitimately clear the 0.90 bar -
    re-derived fresh each build, not a one-time hardcoded verdict, so this stays
    correct across future client patches."""
    spell_names = {r["id"]: r["name_enUS"] for r in dbc.iter_named("Spell")}

    categories = {}
    for row in dbc.DBCFile(config.WORK_DBC_DIR / "SpellChargesCategory.dbc").iter_rows():
        cid = dbc.u32(row[0])
        categories[str(cid)] = {"id": cid, "raw": [dbc.u32(row[1]), dbc.u32(row[2])]}
    cat_ids = {c["id"] for c in categories.values()}

    rows = []
    for row in dbc.DBCFile(config.WORK_DBC_DIR / "SpellCharges.dbc").iter_rows():
        ref = dbc.u32(row[0])
        rows.append({"ref": ref, "categoryId": dbc.u32(row[1]),
                     "resolvedSpellName": spell_names.get(ref)})
    rows.sort(key=lambda c: c["ref"])                    # deterministic ordering

    spell_ids = set(spell_names)
    spell_hits = sum(1 for c in rows if c["ref"] in spell_ids)
    cat_hits = sum(1 for c in rows if c["categoryId"] in cat_ids)
    spell_rate = round(spell_hits / len(rows), 4) if rows else 0.0
    cat_rate = round(cat_hits / len(rows), 4) if rows else 0.0

    non_joining = {c["ref"] for c in rows if c["resolvedSpellName"] is None}
    realm_check = _charges_realm_check(non_joining)
    realm_resolved = set()
    for info in realm_check.values():
        realm_resolved.update(info["resolvedRefs"])
    proven_dead = sorted(non_joining - realm_resolved)
    n_denom = len(rows) - len(proven_dead)
    adjusted_rate = round(spell_hits / n_denom, 4) if n_denom else spell_rate
    # NOTE: "attach" is a reporting-only verdict (would the join clear the 0.90 bar
    # after proven-dead exclusions) - it does NOT itself merge a `charges` field
    # onto any spells.jsonl record. Flipping this True is necessary but not
    # sufficient for real attachment; a future task would still need to add the
    # actual merge path in _record()/the per-spell write loop below, keyed by ref.
    attach = len(proven_dead) > 0 and adjusted_rate >= 0.90

    for c in rows:
        if c["ref"] in non_joining:
            c["realmResolvedIn"] = sorted(
                realm for realm, info in realm_check.items()
                if c["ref"] in info["resolvedRefs"])

    realm_gap_finding = {
        "nonJoiningCount": len(non_joining),
        "byRealm": {realm: {"realmSpellCount": info["realmSpellCount"],
                            "resolvedCount": len(info["resolvedRefs"])}
                   for realm, info in realm_check.items()},
        "resolvedByAnyRealm": len(realm_resolved),
        "provenDeadCount": len(proven_dead),
        "provenDeadRefs": proven_dead,
        "adjustedJoinRate": adjusted_rate,
        "verdict": (
            f"{len(realm_resolved)}/{len(non_joining)} of the base-non-joining refs "
            "resolve as real, live ids in a committed realm-overlay Spell.dbc "
            f"({sorted(realm_check)}) - realm-overlay content, not dead ids. "
            f"{len(proven_dead)} are proven dead (resolve nowhere). Since a "
            "realm-overlay id is real content in a DIFFERENT id space by design "
            "(the four-realm/account-wide-CAD split, see AGENT-GUIDE.md), resolving "
            "in a realm does NOT count as a legitimate exclusion for the base "
            "spells.jsonl attach bar - only proven-dead refs would. "
            + (f"With {len(proven_dead)} proven-dead ref(s) excluded, the adjusted "
               f"join rate is {adjusted_rate:.2%}."
               if proven_dead else
               "No refs are proven dead, so the join rate cannot legitimately be "
               "raised above the base measurement through exclusion.")
        ) if non_joining else "no non-joining refs to characterize",
    }

    doc = {
        "_note": (f"SpellCharges 'ref' resolves to a Spell.dbc id for {spell_rate:.2%} "
                  "of rows in this snapshot (below the 90% attach bar); carried "
                  "standalone, not attached to spell records. See "
                  "'realmGapFinding' below (task W4-11f) for the full "
                  "characterization of the non-joining refs. NOTE: '_meta.json's "
                  "enrichment.charges.attached' is a reporting-only verdict on "
                  "whether the join clears 0.90 after proven-dead exclusions - it "
                  "does not itself merge a 'charges' field onto any spells.jsonl "
                  "record; that would need a separate build_spells.py merge path."),
        "categories": categories,
        "charges": rows,
        "realmGapFinding": realm_gap_finding,
    }
    (out_dir / "charges.json").write_text(
        json.dumps(doc, ensure_ascii=False, indent=1, sort_keys=True), encoding="utf-8", newline="\n")

    return {
        "attached": attach,
        "file": "charges.json",
        "reason": ("SpellCharges.ref join-rate vs live Spell.dbc ids is below the "
                   "brief's 0.90 bar for attaching a 'charges' field to spells.jsonl "
                   "records, despite the categoryId link to SpellChargesCategory "
                   "being proven at 100% and 95.45% of the ref hits mentioning "
                   "'charge' in their tooltip/description text - shipped standalone "
                   "in data/spells/charges.json instead of report-only; see dbc.py "
                   "TABLE_MAPS comment for the full writeup. Task W4-11f "
                   "investigated the gap: the non-joining refs are realm-overlay "
                   "content (not dead), which doesn't legitimately raise the base "
                   "attach rate - see charges.json's realmGapFinding."),
        "recordCount": len(rows), "categoryRecordCount": len(cat_ids),
        "spellIdJoinRate": spell_rate, "categoryLinkJoinRate": cat_rate,
        "realmGapFinding": {
            "nonJoiningCount": realm_gap_finding["nonJoiningCount"],
            "resolvedByAnyRealm": realm_gap_finding["resolvedByAnyRealm"],
            "provenDeadCount": realm_gap_finding["provenDeadCount"],
            "adjustedJoinRate": realm_gap_finding["adjustedJoinRate"],
        },
    }


def _build_stat_suggestions(out_dir):
    """[Task W4-10] SpellStatSuggestions.dbc (coa-sim-handoff/DATAMINE-REQUEST.md
    Sec 5.2's "cheap win"): 1121 rows, f1 golden-proven spellId (99.91% join vs live
    Spell.dbc ids; row id=1 decodes to (1, 10, 3, 1), an exact match to the doc's own
    cited sample "spell 10 is Blizzard"). Shipped standalone at
    data/spells/statSuggestions.json - same "proven key, curate standalone" shape as
    _build_charges above - keyed by the proven spellId, NOT attached to spells.jsonl
    records (this table's own value proposition, a per-spell stat weight, is exactly
    the part that ISN'T proven).

    f2/f3 are carried raw, deliberately NOT asserted as fact: f3 is a constant 1 on
    every row (zero information). f2 takes only 4 values (0/1/3/4) and CORRELATES
    (73.5% agreement on the SpellToStatSuggestionData.json overlap, best-fit
    permutation 0=STR/1=AGI/3=INT/4=SPI - see dbc.py's TABLE_MAPS comment for the
    full cross-validation) with a primary-stat category, but that agreement rate is
    well short of this repo's naming bar - so it ships as "statCategoryRaw", not
    "statCategory", with the caveat inline in _note rather than in a name a consumer
    might trust at face value."""
    spell_names = {r["id"]: r["name_enUS"] for r in dbc.iter_named("Spell")}
    spell_ids = set(spell_names)

    rows = []
    for row in dbc.DBCFile(config.WORK_DBC_DIR / "SpellStatSuggestions.dbc").iter_rows():
        sid = dbc.u32(row[1])
        rows.append({
            "spellId": sid, "resolvedSpellName": spell_names.get(sid),
            "statCategoryRaw": dbc.u32(row[2]), "f3": dbc.u32(row[3]),
        })
    rows.sort(key=lambda r: r["spellId"])

    hits = sum(1 for r in rows if r["spellId"] in spell_ids)
    join_rate = round(hits / len(rows), 4) if rows else 0.0

    doc = {
        "_note": (f"SpellStatSuggestions.dbc's spellId (f1) joins live Spell.dbc ids "
                  f"at {join_rate:.2%} (golden: id 1 -> spell 10 'Blizzard', matching "
                  "DATAMINE-REQUEST.md Sec 5.2's own cited sample). 'statCategoryRaw' "
                  "(f2) is UNPROVEN: it takes exactly 4 values (0/1/3/4) that correlate "
                  "73.5% with a primary-stat category (0=Strength/1=Agility/3=Intellect/"
                  "4=Spirit) when cross-validated against raw/content/"
                  "SpellToStatSuggestionData.json's per-spell dominant stat score over "
                  "their 1,078-spell overlap - well above the 25% random-4-way baseline "
                  "but short of a naming-grade bar, so the raw value ships without an "
                  "asserted meaning. 'f3' is always 1 across all rows - no information, "
                  "carried for completeness only. See tools/dbc.py's SpellStatSuggestions "
                  "TABLE_MAPS comment for the full re-derivation."),
        "spellIdJoinRate": join_rate,
        "suggestions": rows,
    }
    # sharding.dump_manifest, not indent=1: 1121 records at indent=1 runs ~6,700
    # lines (one field per line), over Amendment C's 5,000-line gate; one-compact-
    # record-per-line keeps this file small AND still diffable per row.
    (out_dir / "statSuggestions.json").write_text(
        sharding.dump_manifest(doc), encoding="utf-8", newline="\n")

    return {"file": "statSuggestions.json", "recordCount": len(rows),
            "spellIdJoinRate": join_rate}


def _coa_class_spell_ids():
    """[Task W4-3] The "CoA class set" DATAMINE-REQUEST.md's per-column fill-rate
    figures are measured against: every spell id (incl. every rank-chain id)
    referenced by any of the 21 coa-custom-tagged classes in data/classes/,
    intersected with live Spell.dbc ids. Re-derivation reproduces the doc's own
    counts EXACTLY (6,436 total ids / 6,038 resolved in base Spell.dbc, matching
    Sec 3's "base resolves 6,038/6,436" verbatim) - see
    .superpowers/sdd/task-w4-3-report.md for the full per-column re-verification
    log. Used by tests/test_spells_columns.py to re-verify every new column's
    fill rate against the doc's cited figures; NOT used by build() itself, since
    data/classes/ must already exist on disk (build_dataset.py's stage order
    runs spells before classes) - this can only run after build_classes has
    populated data/classes/ at least once.

    SCOPE, now stated instead of incidental: rank-chain ids are taken only from
    spells that HAVE a base Spell.dbc row (`spell.name is None` is build_classes'
    marker for "no row"). That is the doc's set, exactly - it is what reproduces
    6,436/6,038 on the nose, and both numbers move together if it is widened.
    data/classes/ itself no longer agrees with that scope: a CAD spell with no
    Spell.dbc row still HAS a SpellRankData chain (the table is keyed on the id,
    not on the row), and build_classes used to drop it - a bug that cost the
    live/dead join a real acquisition path and is now fixed. Widening this
    function to match would add 354 ids (17 of them base-resolvable) and silently
    retire the only exact external calibration this repo has against
    DATAMINE-REQUEST.md Sec 3, so the two scopes are kept deliberately distinct
    and this one stays pinned to the doc."""
    classes_dir = config.DATA_DIR / "classes"
    idx = json.loads((classes_dir / "index.json").read_text(encoding="utf-8"))
    ids = set()
    for c in idx["classes"]:
        if c.get("tag") != "coa-custom":
            continue
        cidx = json.loads((classes_dir / c["index"]).read_text(encoding="utf-8"))
        for fentry in cidx["files"]:
            tab = json.loads((classes_dir / c["dir"] / fentry["file"]).read_text(encoding="utf-8"))
            for e in tab.get("entries", []):
                for s in e.get("spells", []) or []:
                    if s.get("id"):
                        ids.add(s["id"])
                    if s.get("name") is None:
                        continue          # no base Spell.dbc row - see the scope note
                    for rk in s.get("ranks") or []:
                        if rk.get("spellId"):
                            ids.add(rk["spellId"])
    return ids


# [Task W4-3] Per-column {mapped, emitted, where} classification for
# data/spells/_coverage.json (DATAMINE-REQUEST.md item 4's coverage-manifest ask).
# "mapped" is implicitly True for every key here (all come from TABLE_MAPS["Spell"]);
# "emitted" False means the column IS named/decoded but its value never reaches any
# spells.jsonl record - either because it's on the doc's Sec 1.4 zero-fill skip list
# (re-verified 0/6038 on the CoA class set, see _coa_class_spell_ids) or because no
# consumer has claimed it yet. A KeyError here on a future TABLE_MAPS["Spell"]
# addition is intentional - _build_coverage fails loudly rather than silently
# reporting a stale manifest.
_SPELL_COLUMN_COVERAGE = {
    "id": (True, "id"),
    "category": (True, "category (present only if value resolves against SpellCategory ids)"),
    "dispel": (True, "dispel.id / dispel.name"),
    "mechanic": (True, "mechanic.id / mechanic.name"),
    "attributes": (True, "attributes[0]"),
    "attributesEx": (True, "attributes[1]"),
    "attributesEx2": (True, "attributes[2]"),
    "attributesEx3": (True, "attributes[3]"),
    "attributesEx4": (True, "attributes[4]"),
    "attributesEx5": (True, "attributes[5]"),
    "attributesEx6": (True, "attributes[6]"),
    "attributesEx7": (True, "attributes[7]"),
    "stances": (True, "stances"),
    "stancesNot": (True, "stancesNot"),
    "targets": (True, "targets"),
    "targetCreatureType": (True, "targetCreatureType"),
    "casterAuraState": (True, "casterAuraState"),
    "targetAuraState": (True, "targetAuraState"),
    "casterAuraSpell": (True, "casterAuraSpell"),
    "targetAuraSpell": (True, "targetAuraSpell"),
    "castingTimeIndex": (True, "castTimeMs (resolved via SpellCastTimes.base; raw index not carried)"),
    "recoveryTime": (True, "cooldownMs"),
    "categoryRecoveryTime": (True, "categoryCooldownMs"),
    "interruptFlags": (True, "interruptFlags"),
    "auraInterruptFlags": (True, "auraInterruptFlags"),
    "channelInterruptFlags": (True, "channelInterruptFlags"),
    "procFlags": (True, "procFlags"),
    "procChance": (True, "procChance (sentinel 101 = unset, not a percentage - see AGENT-GUIDE.md)"),
    "procCharges": (True, "procCharges"),
    "maxLevel": (True, "levels.max"),
    "baseLevel": (True, "levels.base"),
    "spellLevel": (True, "levels.spell"),
    "durationIndex": (True, "durationMs.base / durationMs.max (resolved via SpellDuration; raw index not carried)"),
    "powerType": (True, "powerType.id / powerType.name"),
    "manaCost": (True, "manaCost"),
    "manaCostPerLevel": (False, "confirmed zero-fill on the CoA class set (skip list, "
                                 "DATAMINE-REQUEST.md Sec 1.4) - re-verified 0/6038 nonzero, not emitted"),
    "manaPerSecond": (True, "manaPerSecond"),
    "rangeIndex": (True, "rangeYd.* (resolved via SpellRange; raw index not carried)"),
    "speed": (True, "speed"),
    "stackAmount": (True, "stackAmount"),
    "equippedItemClass": (True, "equippedItem.itemClass"),
    "equippedItemSubClassMask": (True, "equippedItem.subClassMask"),
    "equippedItemInventoryTypeMask": (True, "equippedItem.inventoryTypeMask"),
    "spellIconID": (True, "iconPath (resolved via SpellIcon; raw id not carried)"),
    "activeIconID": (False, "no consumer yet - not part of this task's requested set, "
                            "candidate for a future task"),
    "name_enUS": (True, "name"),
    "rank_enUS": (True, "rank"),
    "description_enUS": (True, "description"),
    "tooltip_enUS": (True, "tooltip"),
    "manaCostPercentage": (True, "manaCostPct"),
    "startRecoveryCategory": (True, "gcdCategory"),
    "startRecoveryTime": (True, "gcdMs"),
    "maxTargetLevel": (False, "confirmed zero-fill on the CoA class set (skip list, "
                              "DATAMINE-REQUEST.md Sec 1.4) - re-verified 0/6038 nonzero, not emitted"),
    "spellFamilyName": (True, "family.id"),
    "spellFamilyFlags1": (True, "family.flags1"),
    "spellFamilyFlags2": (True, "family.flags2"),
    "spellFamilyFlags3": (True, "family.flags3"),
    "maxAffectedTargets": (True, "maxAffectedTargets"),
    "dmgClass": (True, "dmgClass"),
    "preventionType": (True, "preventionType"),
    "schoolMask": (True, "schoolMask / schools"),
    "runeCostID": (True, "runeCost.* (resolved via SpellRuneCost; raw id not carried, null when no rune cost)"),
    "spellMissileID": (True, "missileId"),
    "spellDescriptionVariableID": (True, "descriptionVariables (present only if resolves via SpellDescriptionVariables)"),
    "spellDifficultyID": (False, "confirmed zero-fill on the CoA class set (skip list, "
                                 "DATAMINE-REQUEST.md Sec 1.4) - re-verified 0/6038 nonzero, not emitted"),
}

# per-effect-slot columns (3 slots each, suffix 1/2/3 stripped before lookup)
_EFFECT_SLOT_COLUMN_COVERAGE = {
    "effect": "effects[].effect.id / effects[].effect.name",
    "effectDieSides": "effects[].dieSides",
    "effectRealPointsPerLevel": "effects[].realPointsPerLevel (omitted when raw==0)",
    "effectBasePoints": "effects[].basePoints",
    "effectMechanic": "effects[].mechanic.id / effects[].mechanic.name",
    "effectImplicitTargetA": "effects[].targetA.id / effects[].targetA.name",
    "effectImplicitTargetB": "effects[].targetB.id / effects[].targetB.name",
    "effectRadiusIndex": "effects[].radiusYd (resolved via SpellRadius; raw index not carried)",
    "effectAura": "effects[].aura.id / effects[].aura.name",
    "effectAmplitude": "effects[].amplitudeMs",
    "effectMultipleValue": "effects[].multipleValue",
    "effectChainTarget": "effects[].chainTargets",
    "effectMiscValue": "effects[].miscValue",
    "effectMiscValueB": "effects[].miscValueB",
    "effectTriggerSpell": "effects[].triggerSpell",
    "effectPointsPerComboPoint": "effects[].pointsPerComboPoint (omitted when raw==0)",
    "effectDamageMultiplier": "effects[].damageMultiplier (omitted when raw==0)",
    "effectBonusMultiplier": ("effects[].bonusMultiplierStock (omitted when raw==0; "
                               "stock/Reborn-valid, CoA-contradicted - see AGENT-GUIDE.md)"),
}
_CLASS_MASK_WHERE = "effects[].spellClassMask: [a,b,c] (omitted when all-zero)"


def _classify_spell_column(name):
    if name in _SPELL_COLUMN_COVERAGE:
        return _SPELL_COLUMN_COVERAGE[name]
    if name.startswith("effectSpellClassMask"):
        return True, _CLASS_MASK_WHERE
    if name[-1] in "123" and name[:-1] in _EFFECT_SLOT_COLUMN_COVERAGE:
        return True, _EFFECT_SLOT_COLUMN_COVERAGE[name[:-1]]
    raise KeyError(f"_classify_spell_column: no coverage classification for {name!r} - "
                   "a TABLE_MAPS['Spell'] column was added without updating this map")


def _build_coverage(out_dir):
    """Writes data/spells/_coverage.json (task W4-3 item 4: single-writer rule -
    build_spells owns data/spells/). Per DATAMINE-REQUEST.md's ask: for every
    TABLE_MAPS["Spell"] column, {mapped: true, emitted, where}, plus the
    unmapped-column count against the table's full 234-field width."""
    spec = dbc.TABLE_MAPS["Spell"]
    total_fields = spec["expected_fields"]
    columns = {}
    for name, idx, kind in spec["columns"]:
        emitted, where = _classify_spell_column(name)
        columns[name] = {"index": idx, "kind": kind, "mapped": True,
                          "emitted": emitted, "where": where}
    mapped = len(columns)
    emitted_count = sum(1 for c in columns.values() if c["emitted"])
    doc = {
        "totalFields": total_fields,
        "mappedColumns": mapped,
        "unmappedColumns": total_fields - mapped,
        "emittedColumns": emitted_count,
        "mappedNotEmittedColumns": mapped - emitted_count,
        "columns": columns,
        "_note": (
            f"{mapped} of {total_fields} Spell.dbc fields are named in "
            f"tools.dbc.TABLE_MAPS['Spell']; {total_fields - mapped} remain raw f<N> "
            "(never investigated or investigated and disproven - see raw/dbc/Spell.csv.gz "
            f"for the full byte-accurate dump). Of the {mapped} mapped, {emitted_count} "
            f"reach a spells.jsonl record in some form (direct passthrough or a resolved "
            f"join) and {mapped - emitted_count} are named but not emitted: "
            "manaCostPerLevel/maxTargetLevel/spellDifficultyID are the doc's confirmed "
            "zero-fill skip list (Sec 1.4 - re-verified 0/6038 on the CoA class set before "
            "skipping, per this task's binding rule), activeIconID has no consumer yet. "
            "Task W4-3 (coa-sim-handoff/DATAMINE-REQUEST.md Sec 1.2-1.4) added the 25 "
            "columns needed for damage-scaling modeling: effectRealPointsPerLevel "
            "(f77-79), effectPointsPerComboPoint (f119-121), effectSpellClassMask "
            "(f122-130, 3x flag96), spellFamilyFlags3 (f211), equippedItemSubClassMask/"
            "equippedItemInventoryTypeMask (f69-70), effectDamageMultiplier (f216-218), "
            "spellMissileID (f227), effectBonusMultiplier (f229-231, emitted as "
            "bonusMultiplierStock - correct for stock/Reborn only, contradicts CoA's own "
            "tooltip formula, see AGENT-GUIDE.md); plus re-verified emission of the 8 "
            "already-mapped-but-dropped columns from Sec 1.3 (speed, equippedItemClass, "
            "maxAffectedTargets, casterAuraSpell/targetAuraSpell, manaPerSecond, "
            "targetCreatureType, casterAuraState/targetAuraState, stancesNot)."
        ),
    }
    (out_dir / "_coverage.json").write_text(
        json.dumps(doc, ensure_ascii=False, indent=1, sort_keys=True), encoding="utf-8", newline="\n")
    return {"totalFields": total_fields, "mappedColumns": mapped,
            "unmappedColumns": total_fields - mapped, "emittedColumns": emitted_count,
            "mappedNotEmittedColumns": mapped - emitted_count}


AURA_APPLYING_EFFECTS = {6, 27, 35, 65, 119, 128, 129, 143}


def _enum_evidence_occurrences(records):
    """Task W4-1: per-(namespace, id) occurrence counts over THIS build's
    CoA-referenced closure (`records`), disciplined by the two counting traps from
    coa-sim-handoff/DATAMINE-REQUEST.md Sec 1.5:

    trap 1 - effectAura is only meaningful when that slot's effect is aura-applying
    (6/27/35/65/119/128/129/143); dead slots carry stale aura bytes left over from
    template reuse (e.g. stock Meditation 14777 slot2 has effect=0, aura=87, bp=8 -
    counting that aura would be noise). Aura occurrences below are gated on this.

    trap 2 - Ascension appends INERT template slots to stock spells: basePoints=-1,
    dieSides=1 AND EffectRealPointsPerLevel=0 together mean the slot always
    evaluates to value 0, a no-op stamped onto hundreds of stock spells (aura 271 on
    Corruption/Hand of Protection/Serpent Sting is the worst offender - see the
    source doc). f77-79 (rppl) are NOT in tools/dbc.py's TABLE_MAPS - mapping them
    is a separate task (item 1.2 in the source doc), out of scope here - so they're
    read directly off the raw DBC row by position, not through dbc.iter_named.
    Per trap 3 (same doc), f77-79 are IEEE-754 float bit patterns, but testing
    equality to integer 0 is valid without decoding: a float 0.0 bit pattern is the
    all-zero word, same as int 0.

    Returns (effect_occ, aura_occ), each {id: {"raw": n, "filtered": m}} - "raw" is
    every slot carrying that id, "filtered" is trap-2-disciplined (inert slots
    excluded). Both are reported so a consumer can see the inert-slot noise rather
    than have it silently subtracted."""
    raw_rows = {}
    f = dbc.DBCFile(config.WORK_DBC_DIR / "Spell.dbc")
    for row in f.iter_rows():
        raw_rows[dbc.u32(row[0])] = row

    effect_occ, aura_occ = {}, {}

    def bump(d, key, inert):
        e = d.setdefault(key, {"raw": 0, "filtered": 0})
        e["raw"] += 1
        if not inert:
            e["filtered"] += 1

    for sid, r in records.items():
        row = raw_rows.get(sid)
        if row is None:
            continue
        for slot in (1, 2, 3):
            eff = r[f"effect{slot}"]
            aura = r[f"effectAura{slot}"]
            bp = r[f"effectBasePoints{slot}"]
            ds = r[f"effectDieSides{slot}"]
            rppl_raw = row[76 + slot]           # f77/f78/f79 for slot 1/2/3
            inert = (bp == -1 and ds == 1 and rppl_raw == 0)
            if eff:
                bump(effect_occ, eff, inert)
            if aura and eff in AURA_APPLYING_EFFECTS:   # trap 1
                bump(aura_occ, aura, inert)
    return effect_occ, aura_occ


def _build_enum_evidence(out_dir, records):
    """Writes data/spells/_enum_evidence.json (task W4-1: single-writer rule -
    build_spells owns data/spells/). Bucket/name/goldenSpells/confidence per id is
    fixed research knowledge (enums335.ENUM_EVIDENCE) re-derived against
    work/dbc/Spell.dbc BASE by this task - see
    .superpowers/sdd/task-w4-1-report.md for the full per-golden verification log.
    Occurrence counts are computed fresh here, live, over THIS build's referenced-
    spell closure (see _enum_evidence_occurrences for the trap-1/trap-2 discipline).

    'name' is non-null only where this task's own re-derivation (confidence
    "verified") or an individually-cited golden already transcribed from
    enum-triage.md survived independent decode; those ids are the ones wired into
    enums335.EFFECT_NAMES/AURA_NAMES/COA_EFFECT_NAMES/COA_AURA_NAMES. Every other
    bucket-A/B id here is classified (which bucket it belongs to) but left
    name=null and stays numeric (EFFECT_<n>/AURA_<n>) in enums335.py - no golden
    survived re-derivation for it, so it is not asserted as decoded."""
    effect_occ, aura_occ = _enum_evidence_occurrences(records)
    doc = {"effects": {}, "auras": {}}
    for eid, ev in enums335.ENUM_EVIDENCE["effects"].items():
        occ = effect_occ.get(eid, {"raw": 0, "filtered": 0})
        doc["effects"][str(eid)] = {**ev, "occurrences": occ}
    for aid, ev in enums335.ENUM_EVIDENCE["auras"].items():
        occ = aura_occ.get(aid, {"raw": 0, "filtered": 0})
        doc["auras"][str(aid)] = {**ev, "occurrences": occ}

    # [W4-1 review fix] "classified" (this sidecar has a bucket/occurrence entry for
    # the id) and "wired" (the id actually resolves via effect_name()/aura_name(),
    # i.e. sits in one of enums335.py's 4 lookup tables) are DIFFERENT counts and
    # were previously conflated under one ambiguous "namedIds" field - e.g. EFFECT_168
    # and the 20 unlisted bucket-B ids are classified (bucket B) but never wired, and
    # 2 bucket-C [INFERRED] auras (214, 312) carry a documentation-only "name" in the
    # sidecar without being wired into any enums335.py table. Both are now explicit.
    classified = len(doc["effects"]) + len(doc["auras"])
    wired_effect_ids = set(enums335.EFFECT_NAMES) | set(enums335.COA_EFFECT_NAMES)
    wired_aura_ids = set(enums335.AURA_NAMES) | set(enums335.COA_AURA_NAMES)
    wired = sum(1 for eid in enums335.ENUM_EVIDENCE["effects"] if eid in wired_effect_ids) + \
            sum(1 for aid in enums335.ENUM_EVIDENCE["auras"] if aid in wired_aura_ids)
    sidecar_named = sum(1 for e in doc["effects"].values() if e["name"]) + \
                     sum(1 for a in doc["auras"].values() if a["name"])
    numeric = classified - wired
    summary = {
        "effectIds": len(doc["effects"]), "auraIds": len(doc["auras"]),
        "classifiedIds": classified,      # every id this sidecar has a bucket/occurrence entry for
        "wiredIds": wired,                # of those, ids resolvable via effect_name()/aura_name()
                                           # (present in EFFECT_NAMES/AURA_NAMES/COA_EFFECT_NAMES/
                                           # COA_AURA_NAMES)
        "sidecarNamedIds": sidecar_named, # sidecar entries carrying a non-null "name" - equals
                                           # wiredIds plus a few bucket-C [INFERRED] reads kept for
                                           # documentation only, deliberately NOT wired into any
                                           # enums335.py table (see byBucket.C below)
        "numericFallbackIds": numeric,    # classifiedIds - wiredIds: still fall through to
                                           # EFFECT_<n>/AURA_<n> in enums335.py
        "byBucket": {
            b: sum(1 for e in list(doc["effects"].values()) + list(doc["auras"].values())
                   if e["bucket"] == b)
            for b in ("A", "B", "C", "unknown")
        },
    }
    doc["_note"] = (
        f"{wired} of {classified} unnamed-at-repo-start effect/aura ids (4 W4-1 bug "
        f"fixes not counted here) carry a golden-verified name wired into "
        f"enums335.py; the remaining {numeric} are bucket-classified per "
        "enum-triage.md's aggregate analysis but have no individually-cited golden "
        "that survived independent re-derivation, so they stay numeric "
        "(EFFECT_<n>/AURA_<n>) rather than being asserted. 'sidecarNamedIds' "
        f"({sidecar_named}) is slightly higher than 'wiredIds' ({wired}): a few "
        "bucket-C [INFERRED] auras carry a documentation-only name here without "
        "being wired into enums335.py, since bucket C is explicitly uncertain. "
        "'occurrences.raw' counts every slot carrying that id across this build's "
        "CoA-referenced closure; 'occurrences.filtered' additionally excludes inert "
        "template slots (basePoints=-1, dieSides=1, EffectRealPointsPerLevel=0) per "
        "trap 2, and aura occurrences are gated on the carrying effect being "
        "aura-applying per trap 1 - see coa-sim-handoff/DATAMINE-REQUEST.md Sec 1.5."
    )
    doc["summary"] = summary
    (out_dir / "_enum_evidence.json").write_text(
        json.dumps(doc, ensure_ascii=False, indent=1, sort_keys=True), encoding="utf-8", newline="\n")
    return summary


def _alt_power_type_findings():
    """SpellAlternativePowerType (Task V2-4): the table itself is trivially proven
    (id/name) but no per-spell link is provable - see dbc.py TABLE_MAPS comment."""
    rows = list(dbc.iter_named("SpellAlternativePowerType"))
    return {
        "attached": False,
        "reason": ("Hypothesized link (Spell.dbc's signed powerType going negative "
                   "indexes this table) is disproven: the only negative powerType "
                   "value anywhere in Spell.dbc is -2, already decoded by "
                   "enums335.POWER_TYPES as the pre-existing 'Health' resource-cost "
                   "sentinel (518 spells: Life Tap, Health Funnel, Bloodrage, ...), "
                   "unrelated to alternate power bars. No other Spell.dbc column "
                   "was found to reference this table's ids."),
        "recordCount": len(rows), "names": [r["name_enUS"] for r in rows],
    }


def build() -> dict:
    config.ensure_dirs()
    cad = _content("CharacterAdvancementData.json")               # load CAD once
    refs = _initial_refs(cad)
    cad_other_ids, cad_reborn_ids = _cad_realm_split(cad)
    initial_ids = set(refs)                                       # pre-closure snapshot
    aux = _aux()

    # pass 1: full records for initially-referenced ids + trigger map for ALL ids +
    # [Task W4-4] formula_text: description+tooltip text for EVERY Spell.dbc id (not
    # just referenced ones), so the formula closure below can look up a candidate's
    # text without a second full-table scan per depth.
    records, triggers, formula_text = {}, {}, {}
    for r in dbc.iter_named("Spell"):
        triggers[r["id"]] = (r["effectTriggerSpell1"], r["effectTriggerSpell2"],
                             r["effectTriggerSpell3"])
        formula_text[r["id"]] = (r["description_enUS"] or "") + "\n" + (r["tooltip_enUS"] or "")
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

    # [Task W4-4] formula-reference closure (DATAMINE-REQUEST.md Sec 1.6), capped at
    # depth 2 per the doc's own cost/benefit measurement (depth 3's marginal yield is
    # negligible - re-derived below, not copied). Frontier starts as EVERY id
    # referenced so far (initial cad/rank/talent + trigger closure); each depth scans
    # only the ids newly added at the previous depth, matching the doc's own
    # depth-1/depth-2/depth-3 framing. Only ids that resolve to a live Spell.dbc row
    # (`rid in triggers`) get added to refs/records - unresolved ones are tracked in
    # formula_seen_ids/formula's missing_by_source bucket below, report-only, exactly
    # so they can't leak into the cad_other/talent hard-gate ratios above.
    formula_seen_ids = set()
    formula_depth_new_counts = []
    frontier = set(refs)
    for _depth in range(1, FORMULA_CLOSURE_MAX_DEPTH + 1):
        new_resolved = set()
        for sid in frontier:
            for rid in _formula_ref_ids(formula_text.get(sid, "")):
                formula_seen_ids.add(rid)
                if rid in refs:
                    continue
                if rid in triggers:
                    refs.setdefault(rid, set()).add("formula")
                    new_resolved.add(rid)
        formula_depth_new_counts.append(len(new_resolved))
        frontier = new_resolved
        if not frontier:
            break
    formula_missing_ids = sorted(i for i in formula_seen_ids if i not in triggers)

    # pass 2: fetch full records for closure-added ids (trigger + formula)
    todo = set(refs) - set(records)
    todo &= set(triggers)                       # only ids that exist in Spell.dbc
    if todo:
        for r in dbc.iter_named("Spell"):
            if r["id"] in todo:
                records[r["id"]] = r

    # Amendment A: bucket every pre-closure referenced id (cad_other > cad_reborn >
    # talent > rank) and report per-bucket miss ratios instead of one flat ratio -
    # CAD is account-wide across four realms and Reborn's spells aren't on disk here.
    ref_counts = {"cad_other": 0, "cad_reborn": 0, "talent": 0, "rank": 0, "formula": 0}
    missing_by_source = {"cad_other": [], "cad_reborn": [], "talent": [], "rank": [],
                          "formula": []}
    for sid in initial_ids:
        b = _bucket(refs[sid], cad_other_ids, cad_reborn_ids, sid)
        ref_counts[b] += 1
        if sid not in triggers:
            missing_by_source[b].append(sid)
    missing_by_source = {k: sorted(v) for k, v in missing_by_source.items()}
    # [Task W4-4] formula bucket is populated separately from the initial_ids loop
    # above (formula refs are discovered DURING closure, not part of the pre-closure
    # snapshot) - deliberately kept out of that loop/the cad_other/talent hard gates
    # so an unresolved formula reference can never distort them. Report-only.
    ref_counts["formula"] = len(formula_seen_ids)
    missing_by_source["formula"] = formula_missing_ids

    out_dir = config.DATA_DIR / "spells"
    if out_dir.exists():
        shutil.rmtree(out_dir)                    # drop any prior monolith/shards
    by_id_dir = out_dir / "by-id"
    by_id_dir.mkdir(parents=True)

    charges_finding = _build_charges(out_dir)
    stat_suggestions_finding = _build_stat_suggestions(out_dir)
    enum_evidence_summary = _build_enum_evidence(out_dir, records)
    coverage_summary = _build_coverage(out_dir)
    v2 = _v2_aux(set(records))

    by_source = {}
    enrichment_counts = {"tags": 0, "customAttr": 0, "descriptionVariables": 0,
                          "category": 0, "addon": 0, "overrideData": 0}
    bucketed = defaultdict(list)
    rank_at_60_count = 0
    dev_dead_ids = []
    for sid in sorted(records):
        rec = _record(records[sid], aux, refs[sid], v2)
        for t in rec["referencedBy"]:
            by_source[t] = by_source.get(t, 0) + 1
        for k in enrichment_counts:
            if k in rec:
                enrichment_counts[k] += 1
        if "rankAt60" in rec:
            rank_at_60_count += 1
        if rec.get("devDead"):
            dev_dead_ids.append(sid)
        bucketed[sharding.bucket_id(sid, BUCKET_SIZE)].append(rec)

    bucket_index = []
    for bkt in sorted(bucketed):
        recs = bucketed[bkt]
        fname = f"by-id/spells-{bkt}.jsonl"
        with open(out_dir / fname, "w", encoding="utf-8", newline="\n") as fh:
            for rec in recs:
                fh.write(json.dumps(rec, ensure_ascii=False, sort_keys=True,
                                    separators=(",", ":")) + "\n")
        bucket_index.append({"bucket": bkt, "file": fname, "count": len(recs),
                              "minId": recs[0]["id"], "maxId": recs[-1]["id"]})

    # golden gate: refuse to publish a dataset that fails known ground truth
    g = records.get(17)
    assert g and g["name_enUS"] == "Power Word: Shield" and g["dispel"] == 1, \
        "golden spell 17 failed - column map is wrong, dataset aborted"

    # hard gates: cad_other and talent must resolve near-completely (this client's own
    # realms); cad_reborn and rank are report-only (Reborn realm + stale rank chains)
    co_ratio = len(missing_by_source["cad_other"]) / max(1, ref_counts["cad_other"])
    assert co_ratio <= 0.05, \
        f"cad_other missing ratio {co_ratio:.3f} > 0.05 - non-Reborn CAD refs must resolve"
    tal_ratio = len(missing_by_source["talent"]) / max(1, ref_counts["talent"])
    assert tal_ratio <= 0.05, \
        f"talent missing ratio {tal_ratio:.3f} > 0.05 - Talent.dbc ranks must resolve"

    index = {"bucketSize": BUCKET_SIZE, "count": len(records), "buckets": bucket_index}
    (out_dir / "index.json").write_text(sharding.dump_manifest(index), encoding="utf-8", newline="\n")
    _write_missing_refs(out_dir / "_missing_refs.json", missing_by_source)

    meta = {
        "schemaVersion": 2,
        "count": len(records),
        "missing_ref_counts_by_source": {k: len(v) for k, v in missing_by_source.items()},
        "missingRefsFile": "_missing_refs.json",
        "ref_counts": ref_counts, "by_source": by_source,
        "enrichment": {
            **enrichment_counts,
            "charges": charges_finding,
            "statSuggestions": stat_suggestions_finding,
            "alternativePowerType": _alt_power_type_findings(),
        },
        "enumEvidence": {
            "file": "_enum_evidence.json",
            **enum_evidence_summary,
        },
        "columnCoverage": {
            "file": "_coverage.json",
            **coverage_summary,
        },
        # [Task W4-4] DATAMINE-REQUEST.md Sec 1.6: depth-capped BFS over description/
        # tooltip cross-spell references. "totalNewRecords" is this build's own
        # re-derivation of the doc's "+1,843" (doc's own depth1/2/3 = 1753/87/3,
        # capped at depth 2) - re-derived, not copied, and expected to differ
        # somewhat since this closure runs over the FULL current dataset (stock +
        # CoA + rank + talent + trigger), a superset of the doc's own measurement
        # population; see AGENT-GUIDE.md for the full writeup and the ±20% gate.
        "formulaClosure": {
            "maxDepth": FORMULA_CLOSURE_MAX_DEPTH,
            "depthNewRecordCounts": formula_depth_new_counts,
            "totalNewRecords": sum(formula_depth_new_counts),
            "distinctIdsSeen": len(formula_seen_ids),
            "resolvedIds": len(formula_seen_ids) - len(formula_missing_ids),
            "unresolvedIds": len(formula_missing_ids),
        },
        # [Task W4-4] DATAMINE-REQUEST.md Sec 1.7: per rank chain, the top rank at
        # CAD level <= 60 - see rankAt60 field + _rank_at_60_map's docstring for the
        # [INFERRED]-CAD gating-field caveat (needs an in-game /dump to confirm).
        "rankAt60": {"chainsWithRankAt60": rank_at_60_count},
        # [Task W4-4] DATAMINE-REQUEST.md Sec 1.8: $scalingbp named constant.
        "scalingConstants": {"scalingbp": _scalingbp_constant()},
        # [Task W4-4] DATAMINE-REQUEST.md Sec 4 trap 17: dev-dead content flag.
        "devDead": {
            "marker": DEV_DEAD_MARKER,
            "count": len(dev_dead_ids),
            "ids": sorted(dev_dead_ids),
        },
        "dataNotes": (
            "CharacterAdvancementData.json is account-wide across four realms served by "
            "this client (Area 52 - Free-Pick, Bronzebeard - Warcraft Reborn, Rexxar - "
            "Conquest of Azeroth, Vol'jin - Conquest of Azeroth). Reborn*-class entries "
            "belong to the Warcraft Reborn realm, whose spell data is not materialized in "
            "this client's Spell.dbc snapshot, so cad_reborn misses are expected and "
            "report-only. SpellRankData.json also carries stale orphan rank chains "
            "(bucket 'rank') with no filterable realm/class field; also report-only. "
            "Measured churn baseline: cad_other 211/7162 = 2.95% on 2026-07-17 (real "
            "named custom-class abilities absent from this snapshot's Spell.dbc)."
        ),
        "schema_note": ("sharded by id//" + str(BUCKET_SIZE) + "*" + str(BUCKET_SIZE) +
                        " into by-id/spells-<bucket>.jsonl (one spell per line, ascending "
                        "id within a bucket); see index.json and AGENT-GUIDE.md"),
    }
    (out_dir / "_meta.json").write_text(
        json.dumps(meta, indent=1, sort_keys=True), encoding="utf-8", newline="\n")
    return {"written": len(records), "missing_by_source": missing_by_source,
            "ref_counts": ref_counts, "by_source": by_source,
            "enum_evidence": enum_evidence_summary,
            "column_coverage": coverage_summary,
            "formula_closure": {
                "depthNewRecordCounts": formula_depth_new_counts,
                "totalNewRecords": sum(formula_depth_new_counts),
                "distinctIdsSeen": len(formula_seen_ids),
                "unresolvedIds": len(formula_missing_ids),
            },
            "rank_at_60_count": rank_at_60_count,
            "dev_dead_ids": sorted(dev_dead_ids)}


if __name__ == "__main__":
    s = build()
    print(f"spells written={s['written']} "
          f"missing_by_source={ {k: len(v) for k, v in s['missing_by_source'].items()} } "
          f"ref_counts={s['ref_counts']} by_source={s['by_source']}")
