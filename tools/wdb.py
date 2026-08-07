"""Reader for the client-side WDB query caches under `Cache\\WDB\\<locale>\\`.

WHAT IS MEASURED AND WHAT IS INTERPRETATION - READ THIS FIRST
-------------------------------------------------------------
Two different things live in this module and they must never be confused:

  MEASURED      the LAYOUT - how many fields a record has, each field's width,
                each field's kind (uint32/int32/float32/uint8/cstring), and
                where the variable-length runs are. A layout is accepted only if
                it consumes every block of the file exactly, so a wrong width, a
                deleted field or a moved string fails immediately.

  INTERPRETATION  the NAMES - `armor`, `itemLevel`, `rank`. These come from a
                human reading TrinityCore's 3.3.5 query-response handlers. The
                exact-consumption gate CANNOT check them: any permutation of
                same-kind same-width fields consumes byte-identically, so
                swapping `requiredSkill` with `requiredSkillRank`, or any two of
                `_WQST`'s 26 leading uint32s, passes the gate unchanged.

So the decoded records this module emits are POSITIONAL - `f0..fN`, exactly like
`raw/tables` - and the names ship separately, in a sidecar labelled as the
interpretation they are. An agent reading a shard sees measurements. An agent
that wants the names has to open the file that says they are unverified. That is
the whole point: nothing in the data layer may look like a fact unless it is one.

WHY THIS LAYER EXISTS
---------------------
These files are what the SERVER told this client, cached verbatim from the
query-response opcodes. They are the only client-side source of item stats
(itemcache) and of creature type/rank/health-modifier data (creaturecache) -
the DBC `Item.dbc` is an index with no stats at all. They are also per-realm:
`Cache\\WDB\\enUS\\` holds the login/base cache and each
`Cache\\WDB\\enUS\\<realm>\\` holds what that realm actually served, so the
realm subdirectory is live-play evidence the base directory does not carry.

PROVENANCE
----------
The `WIDB` (item) field order is ported from
`coa-sim-handoff/parsers/wdb_item.py`, which took it from TrinityCore 3.3.5's
`WorldSession::HandleItemQuerySingleOpcode`. The `WMOB` (creature) reading is
ported from `coa-sim-handoff/parsers/wdb2.py`, extended past the two float
modifiers it stopped at. The rest (`WGOB`, `WNDB`, `WITX`, `WPTX`, `WNPC`,
`WQST`) follow the matching 3.3.5 query-response opcode handlers. Every one of
them is generalized here to any .wdb file carrying that magic, in any directory.

HOW A LAYOUT EARNS THE RIGHT TO BE USED
---------------------------------------
A struct layout is an assertion, and this repo does not ship assertions. So no
layout is trusted on its authority: it is applied to a file only if it consumes
EVERY block of that file EXACTLY - the block header declares each record's byte
length, and a wrong field order, a wrong width or a wrong string position lands
off that length almost immediately. On this client that check is strong rather
than nominal: `questcache.wdb` alone has 202 distinct block sizes across 257
records and every one closes to the byte. A layout that fails on any block is not
used at all for that file (never partially), and the file falls back to the
lossless block dump below with the failure recorded as evidence.

Its two limits, stated so nobody over-trusts it:

  * a same-width reinterpretation (uint32 read as float32) consumes the same
    bytes and passes;
  * a PERMUTATION of same-kind same-width fields consumes the same bytes and
    passes. This is the larger hole - essentially every uint32/int32 NAME in
    `_WQST` (26 leading scalars), `_WGOB` (data0..23) and `_WIDB` is unchecked.

Both are name-level errors, and the reason names do not reach the data.

WHAT HAPPENS TO FILES WITH NO SCHEMA
------------------------------------
Nothing is dropped. Three tiers, in order:

1. Recognized magic + layout that closes exactly  -> positional f0..fN fields.
2. Recognized WDB magic, no layout or layout fails -> per-block records of
   `{entry, size, bodyBase64}`. Lossless and rerunnable; the bytes are all there.
3. No WDB header at all -> `sniff_flat()` tries the shape Ascension's own two
   custom caches use (`itemstatcache.wdb`, `questcacheaddon.wdb`):
   `uint32 count, uint32 hash`, then `count` fixed-width records whose width is
   DERIVED, not assumed - `(fileSize - 8)` must divide by `count` exactly.
   Fields come out positional (`f0..fN`), never named, with per-column int/float
   inference measured the same way the DBC layer measures its columns. If the
   division is not exact the file is recorded as undecoded, with its bytes.
"""
import base64
import struct

HEADER = struct.Struct("<4sI4sIII")     # magic, build, locale, recordSize, version, cacheId
HEADER_SIZE = HEADER.size               # 24
_BLOCK = struct.Struct("<II")

# Mirrors tools/decode_all.py's float plausibility window, so a column called a
# float here means the same measured thing it means in raw/tables.
FLOAT_ABS_MIN = 1e-20
FLOAT_ABS_MAX = 1e20

VALIDATION_RULE = (
    "A field LAYOUT is applied to a WDB file only if it consumes every block of "
    "that file exactly: each block declares its own byte length in its header, "
    "and the decode must land on that length for all blocks, with no block "
    "skipped. One mismatch anywhere disqualifies the layout for the whole file "
    "(never per-block), and the file falls back to a lossless base64 block dump "
    "with the mismatch recorded. WHAT THIS DOES NOT CATCH, stated so it is not "
    "over-trusted: (1) reading a uint32 as a float32 consumes the same bytes and "
    "passes; (2) PERMUTING any two same-kind same-width fields consumes the same "
    "bytes and passes. Both were measured - removing a field, or moving a string "
    "by one position, fail on the first block; a width-preserving swap does not. "
    "Because (2) is unfalsifiable from the bytes alone, THIS LAYER SHIPS NO FIELD "
    "NAMES: every decoded record is positional (f0..fN), exactly like "
    "raw/tables. The TrinityCore-derived names are published separately in "
    "raw/cache/_interpretation.json, labelled as the unverified interpretation "
    "they are. A reader can therefore never mistake a name for a measurement.")

INTERPRETATION_RULE = (
    "The field names below are an INTERPRETATION, not a measurement. They were "
    "read off TrinityCore 3.3.5's query-response handlers by a human and mapped "
    "onto the positions this layer measured. The measurement is the layout - "
    "field count, widths, kinds, and the variable-length runs - which is proven "
    "by exact block consumption. The names are not proven by anything: any two "
    "same-kind same-width fields can be swapped without changing a single byte "
    "of consumption, so `f21` being called `flags` is a claim about what the "
    "server meant, verifiable only against an external source. Use the positions "
    "for data and treat every name here as a hypothesis to check.")

FLAT_RULE = (
    "A file with no WDB header is tried as Ascension's own flat cache shape: "
    "uint32 count, uint32 hash, then `count` fixed-width records. The width is "
    "derived - (fileSize - 8) must be divisible by count and by 4 - not assumed. "
    "Columns stay positional (f0..fN); a column is called float only if every "
    "non-zero value in it is a finite binary32 of magnitude in "
    f"[{FLOAT_ABS_MIN}, {FLOAT_ABS_MAX}], otherwise it is an int.")


class WdbError(RuntimeError):
    pass


# --------------------------------------------------------------------------
# header + block layer
# --------------------------------------------------------------------------

def sniff(data: bytes) -> dict:
    """Measured header. `magic` is the 4 bytes reversed, which is how these
    files spell themselves ('BOMW' on disk is WMOB). Returns None-ish shape with
    `hasWdbHeader` False when the bytes cannot be a WDB header."""
    if len(data) < HEADER_SIZE:
        return {"hasWdbHeader": False, "reason": f"file is {len(data)} bytes, "
                f"shorter than a {HEADER_SIZE}-byte WDB header"}
    magic_raw, build, locale, record_size, version, cache_id = HEADER.unpack_from(data, 0)
    magic = magic_raw[::-1].decode("latin-1")
    printable = all(0x20 <= c < 0x7F for c in magic_raw)
    locale_ok = all(0x20 <= c < 0x7F for c in locale)
    if not (printable and locale_ok):
        return {"hasWdbHeader": False,
                "reason": "magic or locale field is not printable ASCII",
                "magicBytes": magic_raw.hex(), "localeBytes": locale.hex()}
    return {"hasWdbHeader": True, "magic": magic,
            "locale": locale[::-1].decode("latin-1"), "build": build,
            "declaredRecordSize": record_size, "version": version,
            "cacheId": f"{cache_id:08x}"}


def blocks(data: bytes):
    """Yield (entry, size, body) for every record block, stopping at the 0/0
    terminator. Raises WdbError on a block that runs past EOF, because a
    truncated cache read as if it were whole is exactly the silent-loss shape
    this repo exists to remove."""
    off, n = HEADER_SIZE, len(data)
    while off + _BLOCK.size <= n:
        entry, size = _BLOCK.unpack_from(data, off)
        if entry == 0 and size == 0:
            return
        off += _BLOCK.size
        if off + size > n:
            raise WdbError(f"block for entry {entry} declares {size} bytes but "
                           f"only {n - off} remain before EOF")
        yield entry, size, data[off:off + size]
        off += size


# --------------------------------------------------------------------------
# layouts
# --------------------------------------------------------------------------
# A layout is a flat list of (name, kind). `kind` is one of
#   u  uint32      i  int32      f  float32      b  uint8      s  cstring (UTF-8)
# or a variable-length run written "*<kinds>", whose repeat count is the value of
# the IMMEDIATELY PRECEDING field (itself a real field in the record). A run
# decodes to a flat list in one positional slot, so every field after it keeps a
# stable index no matter how long the run is in a given record.
#
# The `name` half is carried only to build raw/cache/_interpretation.json. It
# never reaches a decoded record - see INTERPRETATION_RULE. Nothing here is
# applied without the exact-consumption check in decode_blocks().

def _rep(fmt, kind, n, start=0):
    return [(fmt.format(i), kind) for i in range(start, start + n)]


_WMOB = ([(f"name{i}", "s") for i in range(4)] +
         [("subname", "s"), ("iconName", "s"), ("typeFlags", "u"), ("type", "u"),
          ("family", "u"), ("rank", "u"), ("killCredit0", "u"), ("killCredit1", "u")] +
         _rep("modelId{}", "u", 4) +
         [("healthModifier", "f"), ("manaModifier", "f"), ("racialLeader", "b")] +
         _rep("questItem{}", "u", 6) + [("movementId", "u")])

_WGOB = ([("type", "u"), ("displayId", "u")] + _rep("name{}", "s", 4) +
         [("iconName", "s"), ("castBarCaption", "s"), ("unk1", "s")] +
         _rep("data{}", "i", 24) + [("size", "f")] + _rep("questItem{}", "u", 6))

_WNDB = [("name", "s"), ("inventoryType", "u")]
_WITX = [("text", "s")]
_WPTX = [("text", "s"), ("nextPageId", "u")]
_WRDN = []                        # never carries a block on this client

_WNPC = []
for _i in range(8):
    _WNPC += [(f"probability{_i}", "f"), (f"text0_{_i}", "s"), (f"text1_{_i}", "s"),
              (f"language{_i}", "u")]
    for _j in range(3):
        _WNPC += [(f"emoteDelay{_i}_{_j}", "u"), (f"emote{_i}_{_j}", "u")]

_WQST = ([("questId", "u"), ("method", "u"), ("level", "i"), ("minLevel", "u"),
          ("zoneOrSort", "i"), ("type", "u"), ("suggestedPlayers", "u"),
          ("repObjectiveFaction", "u"), ("repObjectiveValue", "u"),
          ("repObjectiveFaction2", "u"), ("repObjectiveValue2", "u"),
          ("nextQuestInChain", "u"), ("rewXPId", "u"), ("rewOrReqMoney", "i"),
          ("rewMoneyMaxLevel", "u"), ("rewSpell", "u"), ("rewSpellCast", "i"),
          ("rewHonorAddition", "u"), ("rewHonorMultiplier", "f"), ("srcItemId", "u"),
          ("flags", "u"), ("charTitleId", "u"), ("playersSlain", "u"),
          ("bonusTalents", "u"), ("rewArenaPoints", "u"), ("unk0", "u")] +
         [p for i in range(4) for p in ((f"rewItemId{i}", "u"), (f"rewItemCount{i}", "u"))] +
         [p for i in range(6) for p in ((f"rewChoiceItemId{i}", "u"),
                                        (f"rewChoiceItemCount{i}", "u"))] +
         _rep("rewFactionId{}", "u", 5) + _rep("rewFactionValueId{}", "i", 5) +
         _rep("rewFactionValueIdOverride{}", "i", 5) +
         [("pointMapId", "u"), ("pointX", "f"), ("pointY", "f"), ("pointOpt", "u"),
          ("title", "s"), ("objectives", "s"), ("details", "s"), ("endText", "s"),
          ("completedText", "s")] +
         [p for i in range(4) for p in ((f"reqNpcOrGo{i}", "i"),
                                        (f"reqNpcOrGoCount{i}", "u"),
                                        (f"reqSourceId{i}", "u"),
                                        (f"reqSourceCount{i}", "u"))] +
         [p for i in range(6) for p in ((f"reqItemId{i}", "u"), (f"reqItemCount{i}", "u"))] +
         _rep("objectiveText{}", "s", 4))

# WIDB is the one layout with a run-time-sized member: `statsCount` stat pairs.
# It is expressed as the "*u,i" variable run rather than as special-case code, so
# it goes through the same decoder and the same exact-consumption gate as every
# other layout. Field order ported from coa-sim-handoff/parsers/wdb_item.py
# (TrinityCore 3.3.5 item query response).
_WIDB_HEAD = ([("class", "u"), ("subclass", "u"), ("soundOverrideSubclass", "i")] +
              _rep("name{}", "s", 4) +
              [("displayId", "u"), ("quality", "u"), ("flags", "u"), ("flags2", "u"),
               ("buyPrice", "u"), ("sellPrice", "u"), ("inventoryType", "u"),
               ("allowableClass", "i"), ("allowableRace", "i"), ("itemLevel", "u"),
               ("requiredLevel", "u"), ("requiredSkill", "u"),
               ("requiredSkillRank", "u"), ("requiredSpell", "u"),
               ("requiredHonorRank", "u"), ("requiredCityRank", "u"),
               ("requiredRepFaction", "u"), ("requiredRepRank", "u"),
               ("maxCount", "i"), ("stackable", "i"), ("containerSlots", "u")])

_WIDB_TAIL = ([("scalingStatDistribution", "u"), ("scalingStatValue", "u")] +
              [p for i in range(2) for p in ((f"damageMin{i}", "f"),
                                             (f"damageMax{i}", "f"),
                                             (f"damageType{i}", "u"))] +
              [("armor", "u")] + _rep("resistance{}", "u", 6) +
              [("delay", "u"), ("ammoType", "u"), ("rangedModRange", "f")] +
              [p for i in range(5) for p in ((f"spellId{i}", "i"),
                                             (f"spellTrigger{i}", "u"),
                                             (f"spellCharges{i}", "i"),
                                             (f"spellCooldown{i}", "i"),
                                             (f"spellCategory{i}", "u"),
                                             (f"spellCategoryCooldown{i}", "i"))] +
              [("bonding", "u"), ("description", "s"), ("pageText", "u"),
               ("languageId", "u"), ("pageMaterial", "u"), ("startQuest", "u"),
               ("lockId", "u"), ("material", "i"), ("sheath", "u"),
               ("randomProperty", "u"), ("randomSuffix", "u"), ("block", "u"),
               ("itemSet", "u"), ("maxDurability", "u"), ("area", "u"),
               ("map", "i"), ("bagFamily", "u"), ("totemCategory", "u")] +
              [p for i in range(3) for p in ((f"socketColor{i}", "u"),
                                             (f"socketContent{i}", "u"))] +
              [("socketBonus", "u"), ("gemProperties", "u"),
               ("requiredDisenchantSkill", "i"), ("armorDamageModifier", "f"),
               ("duration", "u"), ("itemLimitCategory", "u"), ("holidayId", "u")])

_WIDB = _WIDB_HEAD + [("statsCount", "u"), ("stats", "*u,i")] + _WIDB_TAIL

SCHEMAS = {"WMOB": _WMOB, "WGOB": _WGOB, "WNDB": _WNDB, "WITX": _WITX,
           "WPTX": _WPTX, "WNPC": _WNPC, "WQST": _WQST, "WRDN": _WRDN,
           "WIDB": _WIDB}

SCHEMA_SOURCE = {
    "WIDB": "coa-sim-handoff/parsers/wdb_item.py (TrinityCore 3.3.5 item query response)",
    "WMOB": "coa-sim-handoff/parsers/wdb2.py, extended past its two float modifiers",
    "WGOB": "3.3.5 gameobject query response",
    "WNDB": "3.3.5 item-name query response",
    "WITX": "3.3.5 item-text query response",
    "WPTX": "3.3.5 page-text query response",
    "WNPC": "3.3.5 npc-text query response",
    "WQST": "3.3.5 quest query response",
    "WRDN": "3.3.5 name query cache (carries no block on this client)",
}

_UNPACK = {"u": struct.Struct("<I"), "i": struct.Struct("<i"), "f": struct.Struct("<f")}


class _Cursor:
    __slots__ = ("b", "o")

    def __init__(self, b):
        self.b = b
        self.o = 0

    def take(self, kind):
        if kind == "s":
            e = self.b.index(b"\0", self.o)
            v = self.b[self.o:e].decode("utf-8", "replace")
            self.o = e + 1
            return v
        if kind == "b":
            v = self.b[self.o]
            self.o += 1
            return v
        s = _UNPACK[kind]
        v = s.unpack_from(self.b, self.o)[0]
        self.o += s.size
        return v


_FIXED_WIDTH = {"u": 4, "i": 4, "f": 4, "b": 1}


def _decode_layout(body: bytes, layout) -> tuple:
    """Decode one block positionally. Returns ({f0: v, ...}, bytes consumed)."""
    c = _Cursor(body)
    rec = {}
    prev = None
    for pos, (_name, kind) in enumerate(layout):
        if kind[0] == "*":
            kinds = kind[1:].split(",")
            if not isinstance(prev, int) or prev < 0:
                raise WdbError(f"variable run at f{pos} needs a non-negative "
                               f"count in the preceding field, got {prev!r}")
            # MEASURED bound, not a semantic one: the run cannot be longer than
            # the bytes the block itself declares are left. A count that would
            # overrun is a wrong layout, and saying so here is what stops a bad
            # count from allocating against a number the file made up.
            need = prev * sum(_FIXED_WIDTH[k] for k in kinds)
            left = len(body) - c.o
            if need > left:
                raise WdbError(f"variable run at f{pos} declares {prev} "
                               f"repeats ({need} bytes) but only {left} bytes "
                               f"remain in the block")
            run = []
            for _ in range(prev):
                for k in kinds:
                    run.append(c.take(k))
            rec[f"f{pos}"] = run
            prev = run
            continue
        v = c.take(kind)
        rec[f"f{pos}"] = v
        prev = v
    return rec, c.o


def decode_blocks(data: bytes, magic: str) -> dict:
    """Decode every block of a WDB payload under `magic`'s layout.

    Records are POSITIONAL (`f0..fN` plus `_entry`, the block header's own entry
    id). Names live in raw/cache/_interpretation.json - see INTERPRETATION_RULE.

    Returns {"decoded": bool, "records": [...], "fields": [...], "failure": {...}}.
    `decoded` is True only when every block consumed exactly its declared size."""
    if magic not in SCHEMAS:
        return {"decoded": False, "records": [], "fields": [],
                "failure": {"reason": "no layout for this magic", "magic": magic}}
    layout = SCHEMAS[magic]
    out = []
    for entry, size, body in blocks(data):
        try:
            rec, used = _decode_layout(body, layout)
        except Exception as e:
            return {"decoded": False, "records": [], "fields": [],
                    "failure": {"reason": f"{type(e).__name__}: {e}",
                                "entry": entry, "blockSize": size,
                                "blocksDecodedBefore": len(out)}}
        if used != size:
            return {"decoded": False, "records": [], "fields": [],
                    "failure": {"reason": "layout did not consume the block exactly",
                                "entry": entry, "blockSize": size, "consumed": used,
                                "delta": used - size, "blocksDecodedBefore": len(out)}}
        rec["_entry"] = entry
        out.append(rec)
    return {"decoded": True, "records": out, "fields": positional_fields(magic),
            "failure": None}


def positional_fields(magic: str) -> list:
    """The measured shape of a decoded record: one entry per positional slot."""
    return ["_entry"] + [f"f{i}" for i in range(len(SCHEMAS[magic]))]


def interpretation(magic: str) -> list:
    """Position -> the TrinityCore-derived NAME and kind for that slot. This is
    the unverified half; see INTERPRETATION_RULE before using any of it."""
    out = []
    for i, (name, kind) in enumerate(SCHEMAS[magic]):
        rec = {"field": f"f{i}", "name": name}
        if kind[0] == "*":
            rec.update({"kind": "variableRun",
                        "repeatKinds": kind[1:].split(","),
                        "repeatCountFrom": f"f{i-1}",
                        "note": "flat list; length = repeatCount x len(repeatKinds)"})
        else:
            rec["kind"] = {"u": "uint32", "i": "int32", "f": "float32",
                           "b": "uint8", "s": "cstring"}[kind]
        out.append(rec)
    return out


def dump_blocks(data: bytes) -> list:
    """Lossless fallback: one record per block, body as base64. Used when no
    schema closes the file, so the bytes survive to the raw layer regardless."""
    return [{"_entry": entry, "_size": size,
             "_bodyBase64": base64.b64encode(body).decode("ascii")}
            for entry, size, body in blocks(data)]


# --------------------------------------------------------------------------
# headerless (Ascension custom) caches
# --------------------------------------------------------------------------

def _plausible_float(bits: int) -> bool:
    v = struct.unpack("<f", struct.pack("<I", bits & 0xFFFFFFFF))[0]
    if v != v or v in (float("inf"), float("-inf")):
        return False
    a = abs(v)
    return a == 0.0 or (FLOAT_ABS_MIN <= a <= FLOAT_ABS_MAX)


def sniff_flat(data: bytes) -> dict:
    """Try the flat `uint32 count, uint32 hash, count x fixed-width record` shape.

    The record width is DERIVED by exact division, never assumed. Returns
    {"decoded": bool, ...}; on success carries `records` (positional f0..fN),
    `recordSize`, `columnTypes` and the measurement behind each type."""
    n = len(data)
    if n < 8:
        return {"decoded": False, "reason": f"only {n} bytes; no room for a count+hash header"}
    count, hash_word = struct.unpack_from("<II", data, 0)
    body = n - 8
    if count == 0:
        return {"decoded": False, "reason": "declared count is 0", "declaredCount": 0}
    if body % count:
        return {"decoded": False, "declaredCount": count, "bodyBytes": body,
                "reason": f"{body} body bytes do not divide by {count} records"}
    rs = body // count
    if rs == 0 or rs % 4:
        return {"decoded": False, "declaredCount": count, "bodyBytes": body,
                "recordSize": rs,
                "reason": f"derived record size {rs} is not a positive multiple of 4"}
    width = rs // 4
    raw = struct.unpack_from(f"<{count * width}I", data, 8)
    cols = [raw[c::width] for c in range(width)]
    types, evidence = [], []
    for c, col in enumerate(cols):
        nonzero = [v for v in col if v]
        floaty = all(_plausible_float(v) for v in nonzero) if nonzero else False
        types.append("float" if floaty else "int")
        evidence.append({"column": f"f{c}", "rows": len(col),
                         "nonZero": len(nonzero),
                         "allNonZeroPlausibleFloat": floaty})
    records = []
    for r in range(count):
        rec = {}
        for c in range(width):
            v = cols[c][r]
            if types[c] == "float":
                rec[f"f{c}"] = struct.unpack("<f", struct.pack("<I", v))[0]
            else:
                rec[f"f{c}"] = v - (1 << 32) if v >= (1 << 31) else v
        records.append(rec)
    return {"decoded": True, "declaredCount": count,
            "headerWord2": f"{hash_word:08x}", "recordSize": rs, "columns": width,
            "columnTypes": types, "columnEvidence": evidence, "records": records}


def interpretation_index() -> dict:
    """The whole interpretation sidecar payload: every magic this module has a
    layout for, its source, and its position->name map."""
    return {
        "note": "The unverified NAME half of the WDB layouts. raw/cache shards "
                "are positional (f0..fN); this file is the only place a name "
                "appears, and it is a hypothesis, not a measurement.",
        "rule": INTERPRETATION_RULE,
        "validationRule": VALIDATION_RULE,
        "generatedBy": "python -m tools.extract_cache",
        "magics": {m: {"source": SCHEMA_SOURCE.get(m),
                       "fieldCount": len(SCHEMAS[m]),
                       "fields": interpretation(m)}
                   for m in sorted(SCHEMAS)},
    }
