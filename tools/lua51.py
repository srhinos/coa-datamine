"""Lua 5.1 chunks, found inside binaries: precompiled ones read back to their
last byte, source ones detected by their own syntax.

WHY IT IS HERE
--------------
Ascension inlines Lua in `Extensions.dll` - script that exists in no .lua file
in the extracted Interface tree, so no amount of reading the addon layer will
ever show it. Recovering it needs two different readers, because the two forms
are nothing alike:

  * SOURCE text is just bytes in a string table. Finding it means deciding, by
    measurement, which printable runs are Lua and which are English. `score()`
    below counts how many DISTINCT Lua syntax classes a run contains; the caller
    states its threshold. The score travels with every string this repo
    extracts, so a reader can re-decide with a different threshold and never has
    to trust this module's cut-off.

  * PRECOMPILED chunks (`\\x1bLua`) have no length field anywhere. The only way
    to know where one ends - and the only way to know a magic hit is a real
    chunk rather than the four bytes of a compiler emitting the signature, which
    is exactly what Ascension.exe contains - is to WALK the whole structure and
    see whether it terminates cleanly inside the file. `undump()` is that walk,
    ported from lundump.c: header, then function prototypes recursively, each
    with its code array, constants, nested protos and debug tables.

WHAT IT DOES NOT DO
-------------------
It does not decompile and it does not name anything. A recovered chunk is
written out as the bytes that were in the file; the structure walk reports
counts, the constants it read, and a straight opcode-level disassembly of the
instruction words - all of which are re-statements of the bytes, not readings of
them.

THE HEADER IS READ, NOT ASSUMED
-------------------------------
Sizes of int, size_t, Instruction and lua_Number come out of the chunk's own
12-byte header and are used for the walk, so a chunk built by a 64-bit or
integral-number build reads correctly instead of silently mis-parsing.
"""
import re
import struct

SIGNATURE = b"\x1bLua"
VERSION_51 = 0x51
HEADER_BYTES = 12

# lopcodes.h, in opcode order. The names are the language's, not this repo's.
OPCODES = [
    ("MOVE", "iABC"), ("LOADK", "iABx"), ("LOADBOOL", "iABC"),
    ("LOADNIL", "iABC"), ("GETUPVAL", "iABC"), ("GETGLOBAL", "iABx"),
    ("GETTABLE", "iABC"), ("SETGLOBAL", "iABx"), ("SETUPVAL", "iABC"),
    ("SETTABLE", "iABC"), ("NEWTABLE", "iABC"), ("SELF", "iABC"),
    ("ADD", "iABC"), ("SUB", "iABC"), ("MUL", "iABC"), ("DIV", "iABC"),
    ("MOD", "iABC"), ("POW", "iABC"), ("UNM", "iABC"), ("NOT", "iABC"),
    ("LEN", "iABC"), ("CONCAT", "iABC"), ("JMP", "iAsBx"), ("EQ", "iABC"),
    ("LT", "iABC"), ("LE", "iABC"), ("TEST", "iABC"), ("TESTSET", "iABC"),
    ("CALL", "iABC"), ("TAILCALL", "iABC"), ("RETURN", "iABC"),
    ("FORLOOP", "iAsBx"), ("FORPREP", "iAsBx"), ("TFORLOOP", "iABC"),
    ("SETLIST", "iABC"), ("CLOSE", "iABC"), ("CLOSURE", "iABx"),
    ("VARARG", "iABC"),
]

# Caps that turn a corrupt or coincidental header into a rejection instead of a
# multi-gigabyte allocation. A real 5.1 chunk is far below all of them.
MAX_ITEMS = 1 << 22
MAX_DEPTH = 200
MAX_STRING = 1 << 24


class _Cursor:
    def __init__(self, data: bytes, pos: int, sizes: dict):
        self.d = data
        self.p = pos
        self.s = sizes

    def take(self, n: int) -> bytes:
        if n < 0 or self.p + n > len(self.d):
            raise ValueError(f"chunk runs past end of file at {self.p}")
        b = self.d[self.p:self.p + n]
        self.p += n
        return b

    def u8(self) -> int:
        return self.take(1)[0]

    def integer(self) -> int:
        n = self.s["int"]
        v = int.from_bytes(self.take(n), "little", signed=True)
        return v

    def size_t(self) -> int:
        return int.from_bytes(self.take(self.s["sizeT"]), "little")

    def number(self):
        raw = self.take(self.s["number"])
        if self.s["integral"]:
            return int.from_bytes(raw, "little", signed=True)
        if self.s["number"] == 4:
            return struct.unpack("<f", raw)[0]
        if self.s["number"] == 8:
            return struct.unpack("<d", raw)[0]
        return int.from_bytes(raw, "little")

    def string(self):
        n = self.size_t()
        if n == 0:
            return None
        if n > MAX_STRING:
            raise ValueError(f"string of {n} bytes at {self.p}")
        raw = self.take(n)
        return raw[:-1].decode("latin-1") if raw.endswith(b"\0") else \
            raw.decode("latin-1")

    def count(self) -> int:
        n = self.integer()
        if n < 0 or n > MAX_ITEMS:
            raise ValueError(f"item count {n} at {self.p}")
        return n


def parse_header(data: bytes, off: int) -> dict:
    """The 12-byte chunk header, as fields plus a verdict."""
    if off + HEADER_BYTES > len(data):
        return {"ok": False, "reason": "truncated header"}
    h = data[off:off + HEADER_BYTES]
    if h[:4] != SIGNATURE:
        return {"ok": False, "reason": "no signature"}
    out = {"version": h[4], "format": h[5], "endianness": h[6],
           "sizeInt": h[7], "sizeSizeT": h[8], "sizeInstruction": h[9],
           "sizeNumber": h[10], "integral": h[11]}
    if out["version"] != VERSION_51:
        return dict(out, ok=False,
                    reason=f"version {out['version']:#x} is not Lua 5.1")
    if out["format"] != 0:
        return dict(out, ok=False, reason=f"format {out['format']} is not the "
                                          f"official one")
    if out["endianness"] != 1:
        return dict(out, ok=False, reason="big-endian chunk")
    if out["sizeInt"] not in (4, 8) or out["sizeSizeT"] not in (4, 8):
        return dict(out, ok=False, reason="unsupported int/size_t width")
    if out["sizeInstruction"] != 4:
        return dict(out, ok=False, reason="instruction width is not 4")
    if out["sizeNumber"] not in (4, 8):
        return dict(out, ok=False, reason="unsupported lua_Number width")
    return dict(out, ok=True, reason="")


def disassemble(code: list) -> list:
    """Instruction words as opcode + operands. A restatement of the bits."""
    out = []
    for i, w in enumerate(code):
        op = w & 0x3F
        name, mode = OPCODES[op] if op < len(OPCODES) else (f"OP{op}", "iABC")
        a = (w >> 6) & 0xFF
        rec = {"pc": i, "op": name, "a": a}
        if mode == "iABC":
            rec["b"] = (w >> 23) & 0x1FF
            rec["c"] = (w >> 14) & 0x1FF
        elif mode == "iABx":
            rec["bx"] = (w >> 14) & 0x3FFFF
        else:
            rec["sbx"] = ((w >> 14) & 0x3FFFF) - 131071
        out.append(rec)
    return out


def _function(c: _Cursor, depth: int) -> dict:
    if depth > MAX_DEPTH:
        raise ValueError("prototype nesting too deep")
    f = {"source": c.string(), "lineDefined": c.integer(),
         "lastLineDefined": c.integer(), "upvalues": c.u8(),
         "numParams": c.u8(), "isVararg": c.u8(), "maxStackSize": c.u8()}
    n = c.count()
    code = list(struct.unpack(f"<{n}I", c.take(n * 4))) if n else []
    f["instructionCount"] = n

    consts = []
    for _ in range(c.count()):
        t = c.u8()
        if t == 0:
            consts.append({"type": "nil", "value": None})
        elif t == 1:
            consts.append({"type": "boolean", "value": bool(c.u8())})
        elif t == 3:
            consts.append({"type": "number", "value": c.number()})
        elif t == 4:
            consts.append({"type": "string", "value": c.string()})
        else:
            raise ValueError(f"constant type {t} is not a Lua 5.1 type")
    f["constants"] = consts

    f["protos"] = [_function(c, depth + 1) for _ in range(c.count())]

    n = c.count()
    f["lineInfo"] = list(struct.unpack(f"<{n}i", c.take(n * 4))) if n else []
    f["localVars"] = [{"name": c.string(), "startPc": c.integer(),
                       "endPc": c.integer()} for _ in range(c.count())]
    f["upvalueNames"] = [c.string() for _ in range(c.count())]
    f["disassembly"] = disassemble(code)
    return f


def undump(data: bytes, off: int) -> dict:
    """Read one precompiled chunk at `off`. Returns its byte length and full
    structure, or a rejection with the reason the walk failed."""
    head = parse_header(data, off)
    if not head["ok"]:
        return {"ok": False, "offset": off, "header": head,
                "reason": head["reason"]}
    sizes = {"int": head["sizeInt"], "sizeT": head["sizeSizeT"],
             "number": head["sizeNumber"], "integral": head["integral"]}
    c = _Cursor(data, off + HEADER_BYTES, sizes)
    try:
        top = _function(c, 0)
    except (ValueError, struct.error) as exc:
        return {"ok": False, "offset": off, "header": head, "reason": str(exc)}
    return {"ok": True, "offset": off, "header": head, "bytes": c.p - off,
            "chunk": top}


def find_chunks(data: bytes) -> list:
    """Every `\\x1bLua` in the file, each either walked to its end or rejected
    with the reason. Rejections are kept: "the magic is here and it is NOT a
    chunk" is a finding, and it is what a compiler that writes the signature at
    run time looks like."""
    out = []
    at = data.find(SIGNATURE)
    while at >= 0:
        out.append(undump(data, at))
        at = data.find(SIGNATURE, at + 1)
    return out


# ---------------------------------------------------------------------------
# source text
# ---------------------------------------------------------------------------
# Distinct SYNTAX classes, not a word list: each pattern is something that is
# Lua and is not ordinary prose. `score()` counts how many of them a run
# matches, so one repeated keyword cannot carry a string over any threshold.
TOKEN_CLASSES = [
    ("function", re.compile(r"\bfunction\b")),
    ("local", re.compile(r"\blocal\s+[A-Za-z_]")),
    ("end", re.compile(r"(?:^|[\s;)}])end\b")),
    ("then", re.compile(r"\bthen\b")),
    ("elseif", re.compile(r"\belseif\b")),
    ("nil", re.compile(r"\bnil\b")),
    ("methodCall", re.compile(r"[\w\"')\]]\s*:\s*[A-Za-z_]\w*\s*\(")),
    ("concat", re.compile(r"\.\.")),
    ("comment", re.compile(r"--\[\[|(?:^|\s)--\s*\w")),
    ("return", re.compile(r"\breturn\b")),
    ("notOperator", re.compile(r"\bnot\s+[A-Za-z_]")),
    ("tableConstructor", re.compile(r"=\s*\{")),
    ("forIn", re.compile(r"\bfor\b[^\n]{0,60}?\b(?:in|do)\b")),
    ("stdlibCall", re.compile(
        r"\b(?:pairs|ipairs|tostring|tonumber|pcall|xpcall|setmetatable|"
        r"getmetatable|rawget|rawset|select|unpack|tinsert|tremove|"
        r"string\.\w+|table\.\w+|math\.\w+)\s*\(")),
    ("selfRef", re.compile(r"\bself[.:]")),
    ("longString", re.compile(r"\[\[")),
    ("doEnd", re.compile(r"\bdo\b")),
    ("colonDef", re.compile(r"function\s+[\w.]+[:.]\w+\s*\(")),
]

TOKEN_RULE = (
    "A run's Lua score is the number of DISTINCT syntax classes in "
    "tools/lua51.py TOKEN_CLASSES that match it - keywords, method-call and "
    "concatenation syntax, comment openers, table constructors and standard "
    "library calls. Counting distinct classes rather than occurrences stops one "
    "repeated word from carrying English prose over a threshold. The score is "
    "recorded on every extracted string, so any reader can re-cut it.")


def score(text: str) -> int:
    return sum(1 for _name, pat in TOKEN_CLASSES if pat.search(text))


def classes(text: str) -> list:
    return [name for name, pat in TOKEN_CLASSES if pat.search(text)]


# A printable run for source purposes INCLUDES the line breaks, which is what
# separates a multi-line chunk from the single-line fragments around it.
SOURCE_RUN = re.compile(rb"[\x20-\x7e\t\r\n]{40,}")


def find_source_blobs(data: bytes, min_score: int, min_lines: int = 2) -> list:
    """Maximal printable-with-newlines runs that score at or above `min_score`
    and span at least `min_lines` lines. Verbatim - the run is reported at its
    own offset with its own bytes, not cleaned up."""
    out = []
    for m in SOURCE_RUN.finditer(data):
        raw = m.group()
        if raw.count(b"\n") + 1 < min_lines:
            continue
        text = raw.decode("latin-1")
        s = score(text)
        if s < min_score:
            continue
        out.append({"offset": m.start(), "bytes": len(raw), "score": s,
                    "classes": classes(text), "lines": raw.count(b"\n") + 1,
                    "text": text})
    return out


# ---------------------------------------------------------------------------
def _build_test_chunk() -> bytes:
    """A hand-assembled Lua 5.1 chunk: one main function with a string constant,
    a number constant, one nested prototype and full debug tables. Built by hand
    on purpose - the point is to test the reader against the FORMAT, not against
    another copy of this code."""
    def i32(v):
        return struct.pack("<i", v)

    def size(v):
        return struct.pack("<I", v)

    def s(text):
        return size(len(text) + 1) + text.encode() + b"\0"

    def func(source, code, consts, protos):
        b = s(source) if source else size(0)
        b += i32(1) + i32(9)                      # line defined / last
        b += bytes([0, 0, 2, 2])                  # nups, params, vararg, stack
        b += i32(len(code)) + b"".join(struct.pack("<I", w) for w in code)
        b += i32(len(consts))
        for c in consts:
            if isinstance(c, str):
                b += b"\x04" + s(c)
            elif isinstance(c, bool):
                b += b"\x01" + bytes([1 if c else 0])
            elif c is None:
                b += b"\x00"
            else:
                b += b"\x03" + struct.pack("<d", c)
        b += i32(len(protos)) + b"".join(protos)
        b += i32(len(code)) + b"".join(i32(7) for _ in code)   # lineinfo
        b += i32(1) + s("x") + i32(0) + i32(len(code))         # one local
        b += i32(0)                                            # no upvalues
        return b

    header = SIGNATURE + bytes([0x51, 0, 1, 4, 4, 4, 8, 0])
    inner = func("@inner.lua", [0x0000001E], [], [])            # RETURN
    # GETGLOBAL 0 0 ; LOADK 1 1 ; CALL 0 2 1 ; RETURN 0 1
    main = func("@test.lua", [0x00000005, 0x00004041, 0x0100405C, 0x0080001E],
                ["print", 3.5], [inner])
    return header + main


def selftest() -> int:
    bad = 0
    blob = _build_test_chunk()
    r = undump(blob, 0)
    if not r["ok"]:
        print(f"  FAIL undump rejected a valid chunk: {r['reason']}")
        return 1
    if r["bytes"] != len(blob):
        print(f"  FAIL chunk length {r['bytes']} != {len(blob)}"); bad += 1
    ch = r["chunk"]
    if ch["source"] != "@test.lua":
        print("  FAIL source name"); bad += 1
    if [c["value"] for c in ch["constants"]] != ["print", 3.5]:
        print(f"  FAIL constants {ch['constants']}"); bad += 1
    if len(ch["protos"]) != 1 or ch["protos"][0]["source"] != "@inner.lua":
        print("  FAIL nested prototype"); bad += 1
    ops = [d["op"] for d in ch["disassembly"]]
    if ops != ["GETGLOBAL", "LOADK", "CALL", "RETURN"]:
        print(f"  FAIL disassembly {ops}"); bad += 1
    if ch["localVars"][0]["name"] != "x":
        print("  FAIL debug local"); bad += 1

    # a chunk embedded in a larger buffer must be found and measured
    wrapped = b"\xcc" * 17 + blob + b"\xcc" * 9
    found = [f for f in find_chunks(wrapped) if f["ok"]]
    if len(found) != 1 or found[0]["offset"] != 17 or found[0]["bytes"] != len(blob):
        print(f"  FAIL find_chunks in a buffer: {[(f['offset'], f['bytes']) for f in found]}")
        bad += 1

    # the magic alone must be REJECTED, which is the whole point of walking it
    if undump(SIGNATURE + b"\x51\x00\x01\x04\x04\x04\x08\x00", 0)["ok"]:
        print("  FAIL a bare header must not read as a chunk"); bad += 1
    if undump(SIGNATURE + b"\x53" + b"\0" * 7, 0)["ok"]:
        print("  FAIL a 5.3 header must be rejected"); bad += 1

    # truncation must be a rejection, never an exception
    if undump(blob[:len(blob) - 4], 0)["ok"]:
        print("  FAIL a truncated chunk must be rejected"); bad += 1

    if score("if UIParent and not AscensionRealmHotSwapOverlay then\n"
             "local f = CreateFrame(\"Frame\")\nend") < 4:
        print("  FAIL real Lua must score"); bad += 1
    if score("Number Of Processors: %d Physical Memory: %d KB Available") >= 3:
        print("  FAIL prose must not score"); bad += 1
    return bad


if __name__ == "__main__":
    raise SystemExit(selftest())
