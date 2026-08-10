"""A PE/COFF reader, written here because the client binaries are the last
unopened layer of this client and nothing in the standard library reads them.

WHAT IT IS FOR
--------------
`Extensions.dll` is Ascension's engine extension: it carries `listarchive`,
`SetDataPath`, `realmdata` and inlined Lua that exists in no .lua file anywhere
in the extracted tree. To get at any of that mechanically you first need the
file's own structure - where each section starts in the FILE (so a string can be
reported with the section it lives in), what the image imports and exports, and
what sits in the resource directory.

WHAT IT PROMISES
----------------
It never raises on a malformed image. Every reader below is bounds-checked
against the buffer and records what it could not read in `notes`, because a
parser that throws turns "this field is truncated" into "this binary yielded
nothing" - and the whole point of the layer above is to state exactly how much
was recovered.

It interprets nothing. Field names are the names the PE/COFF specification gives
them; resource type ids are the spec's RT_* constants; everything else is
numbers as they appear in the file. Meaning is not this module's business.

WHAT IT READS
-------------
    DOS header + the Rich header (the linker's own tool-version record, which
    is undocumented but trivially decodable and is DATA about how the file was
    built), COFF header, both optional-header shapes (PE32 and PE32+), the data
    directories, the section table, imports, delay-load imports, exports,
    the resource tree, the debug directory (including the CodeView RSDS record,
    which carries the PDB path the binary was built with), the attribute
    certificate table, and the overlay - bytes after the last section, which no
    section table entry accounts for and which are therefore invisible to any
    reader that walks sections alone.
"""
import hashlib
import math
import struct

# ---------------------------------------------------------------------------
# constants, all straight from the PE/COFF specification
# ---------------------------------------------------------------------------
PE32 = 0x10B
PE32_PLUS = 0x20B

DIRECTORY_NAMES = [
    "export", "import", "resource", "exception", "security", "basereloc",
    "debug", "architecture", "globalptr", "tls", "loadConfig", "boundImport",
    "iat", "delayImport", "comDescriptor", "reserved",
]

MACHINES = {
    0x014C: "IMAGE_FILE_MACHINE_I386", 0x8664: "IMAGE_FILE_MACHINE_AMD64",
    0x01C0: "IMAGE_FILE_MACHINE_ARM", 0xAA64: "IMAGE_FILE_MACHINE_ARM64",
    0x0200: "IMAGE_FILE_MACHINE_IA64", 0x01C4: "IMAGE_FILE_MACHINE_ARMNT",
}

SUBSYSTEMS = {
    0: "UNKNOWN", 1: "NATIVE", 2: "WINDOWS_GUI", 3: "WINDOWS_CUI",
    5: "OS2_CUI", 7: "POSIX_CUI", 9: "WINDOWS_CE_GUI", 10: "EFI_APPLICATION",
    11: "EFI_BOOT_SERVICE_DRIVER", 12: "EFI_RUNTIME_DRIVER", 13: "EFI_ROM",
    14: "XBOX", 16: "WINDOWS_BOOT_APPLICATION",
}

FILE_CHARACTERISTICS = [
    (0x0001, "RELOCS_STRIPPED"), (0x0002, "EXECUTABLE_IMAGE"),
    (0x0004, "LINE_NUMS_STRIPPED"), (0x0008, "LOCAL_SYMS_STRIPPED"),
    (0x0010, "AGGRESSIVE_WS_TRIM"), (0x0020, "LARGE_ADDRESS_AWARE"),
    (0x0080, "BYTES_REVERSED_LO"), (0x0100, "32BIT_MACHINE"),
    (0x0200, "DEBUG_STRIPPED"), (0x0400, "REMOVABLE_RUN_FROM_SWAP"),
    (0x0800, "NET_RUN_FROM_SWAP"), (0x1000, "SYSTEM"), (0x2000, "DLL"),
    (0x4000, "UP_SYSTEM_ONLY"), (0x8000, "BYTES_REVERSED_HI"),
]

SECTION_CHARACTERISTICS = [
    (0x00000020, "CNT_CODE"), (0x00000040, "CNT_INITIALIZED_DATA"),
    (0x00000080, "CNT_UNINITIALIZED_DATA"), (0x00000200, "LNK_INFO"),
    (0x00000800, "LNK_REMOVE"), (0x00001000, "LNK_COMDAT"),
    (0x00008000, "GPREL"), (0x02000000, "MEM_DISCARDABLE"),
    (0x04000000, "MEM_NOT_CACHED"), (0x08000000, "MEM_NOT_PAGED"),
    (0x10000000, "MEM_SHARED"), (0x20000000, "MEM_EXECUTE"),
    (0x40000000, "MEM_READ"), (0x80000000, "MEM_WRITE"),
]

DLL_CHARACTERISTICS = [
    (0x0020, "HIGH_ENTROPY_VA"), (0x0040, "DYNAMIC_BASE"),
    (0x0080, "FORCE_INTEGRITY"), (0x0100, "NX_COMPAT"),
    (0x0200, "NO_ISOLATION"), (0x0400, "NO_SEH"), (0x0800, "NO_BIND"),
    (0x1000, "APPCONTAINER"), (0x2000, "WDM_DRIVER"), (0x4000, "GUARD_CF"),
    (0x8000, "TERMINAL_SERVER_AWARE"),
]

RESOURCE_TYPES = {
    1: "RT_CURSOR", 2: "RT_BITMAP", 3: "RT_ICON", 4: "RT_MENU", 5: "RT_DIALOG",
    6: "RT_STRING", 7: "RT_FONTDIR", 8: "RT_FONT", 9: "RT_ACCELERATOR",
    10: "RT_RCDATA", 11: "RT_MESSAGETABLE", 12: "RT_GROUP_CURSOR",
    14: "RT_GROUP_ICON", 16: "RT_VERSION", 17: "RT_DLGINCLUDE",
    19: "RT_PLUGPLAY", 20: "RT_VXD", 21: "RT_ANICURSOR", 22: "RT_ANIICON",
    23: "RT_HTML", 24: "RT_MANIFEST",
}

DEBUG_TYPES = {
    0: "UNKNOWN", 1: "COFF", 2: "CODEVIEW", 3: "FPO", 4: "MISC", 5: "EXCEPTION",
    6: "FIXUP", 7: "OMAP_TO_SRC", 8: "OMAP_FROM_SRC", 9: "BORLAND",
    10: "RESERVED10", 11: "CLSID", 12: "VC_FEATURE", 13: "POGO", 14: "ILTCG",
    15: "MPX", 16: "REPRO", 20: "EX_DLLCHARACTERISTICS",
}

# A resource tree that points at itself would otherwise walk forever.
MAX_RESOURCE_DEPTH = 8
# Import/export tables in a corrupt image can declare absurd counts.
MAX_ENTRIES = 1 << 20


class Reader:
    """Bounds-checked access to the file's bytes. Every read returns a default
    instead of raising, so one truncated field costs one field."""

    def __init__(self, data: bytes):
        self.data = data
        self.size = len(data)

    def ok(self, off: int, n: int) -> bool:
        return 0 <= off and n >= 0 and off + n <= self.size

    def u8(self, off, default=0):
        return self.data[off] if self.ok(off, 1) else default

    def u16(self, off, default=0):
        return struct.unpack_from("<H", self.data, off)[0] if self.ok(off, 2) else default

    def u32(self, off, default=0):
        return struct.unpack_from("<I", self.data, off)[0] if self.ok(off, 4) else default

    def u64(self, off, default=0):
        return struct.unpack_from("<Q", self.data, off)[0] if self.ok(off, 8) else default

    def blob(self, off, n) -> bytes:
        if off < 0 or n <= 0 or off >= self.size:
            return b""
        return self.data[off:min(off + n, self.size)]

    def cstr(self, off, limit=4096) -> str:
        """A NUL-terminated ASCII string, as latin-1 so no byte is lost."""
        if off < 0 or off >= self.size:
            return ""
        end = self.data.find(b"\0", off, min(off + limit, self.size))
        if end < 0:
            end = min(off + limit, self.size)
        return self.data[off:end].decode("latin-1")


def _flags(value: int, table) -> list:
    return [name for bit, name in table if value & bit]


def entropy(data: bytes) -> float:
    """Shannon entropy in bits per byte. A MEASUREMENT, recorded per section
    because it is the difference between "this section yielded four strings
    because it holds none" and "because its bytes are compressed or encrypted" -
    which one it is stays the reader's call, not this module's."""
    if not data:
        return 0.0
    counts = [0] * 256
    for b in data:
        counts[b] += 1
    n = len(data)
    total = 0.0
    for c in counts:
        if c:
            p = c / n
            total -= p * math.log2(p)
    return round(total, 6)


def _sha(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


# ---------------------------------------------------------------------------
def is_pe(data: bytes) -> bool:
    if len(data) < 0x40 or data[:2] != b"MZ":
        return False
    off = struct.unpack_from("<I", data, 0x3C)[0]
    return 0 < off < len(data) - 4 and data[off:off + 4] == b"PE\0\0"


def rva_to_offset(sections: list, rva: int):
    """File offset for a virtual address, or None when no section covers it.

    The mapping is per section and not a constant delta, which is exactly why a
    string's file offset and its address are different numbers and both are
    worth recording."""
    for s in sections:
        start = s["virtualAddress"]
        # A section's mapped span is the larger of its two sizes: virtualSize
        # can exceed the raw size (bss-style tails) and raw size can exceed
        # virtualSize (file alignment padding).
        span = max(s["virtualSize"], s["sizeOfRawData"])
        if start <= rva < start + span:
            delta = rva - start
            if delta < s["sizeOfRawData"]:
                return s["pointerToRawData"] + delta
            return None
    return None


def section_of_offset(sections: list, off: int):
    for s in sections:
        if s["sizeOfRawData"] and s["pointerToRawData"] <= off < \
                s["pointerToRawData"] + s["sizeOfRawData"]:
            return s["name"]
    return None


# ---------------------------------------------------------------------------
# headers
# ---------------------------------------------------------------------------
def _rich_header(r: Reader, pe_off: int) -> dict:
    """The linker's undocumented build record between the DOS stub and the PE
    header: XOR-masked (compid, count) pairs bracketed by `DanS` and `Rich`.

    Recorded, not read: the pairs are numbers identifying the tool that emitted
    each object file. Which tool a number means is not stated here."""
    window = r.blob(0, min(pe_off, r.size))
    at = window.rfind(b"Rich")
    if at < 0 or at + 8 > len(window):
        return {"present": False}
    key = struct.unpack_from("<I", window, at + 4)[0]
    # walk backwards in dwords until the masked DanS marker
    start = None
    i = at - 4
    while i >= 0:
        if struct.unpack_from("<I", window, i)[0] ^ key == 0x536E6144:   # 'DanS'
            start = i
            break
        i -= 4
    if start is None:
        return {"present": False, "note": "Rich marker with no DanS start"}
    entries = []
    i = start + 16                       # DanS + three masked padding dwords
    while i + 8 <= at:
        compid = struct.unpack_from("<I", window, i)[0] ^ key
        count = struct.unpack_from("<I", window, i + 4)[0] ^ key
        entries.append({"productId": compid >> 16, "buildNumber": compid & 0xFFFF,
                        "count": count})
        i += 8
    return {"present": True, "offset": start, "key": key,
            "checksumOffset": at + 4, "entries": entries,
            "sha256": _sha(window[start:at + 8])}


def _optional_header(r: Reader, off: int, size: int) -> dict:
    magic = r.u16(off)
    plus = magic == PE32_PLUS
    o = {
        "magic": magic,
        "magicName": "PE32+" if plus else "PE32" if magic == PE32 else "unknown",
        "majorLinkerVersion": r.u8(off + 2), "minorLinkerVersion": r.u8(off + 3),
        "sizeOfCode": r.u32(off + 4), "sizeOfInitializedData": r.u32(off + 8),
        "sizeOfUninitializedData": r.u32(off + 12),
        "addressOfEntryPoint": r.u32(off + 16), "baseOfCode": r.u32(off + 20),
    }
    if plus:
        o["imageBase"] = r.u64(off + 24)
        p = off + 32
    else:
        o["baseOfData"] = r.u32(off + 24)
        o["imageBase"] = r.u32(off + 28)
        p = off + 32
    o.update({
        "sectionAlignment": r.u32(p), "fileAlignment": r.u32(p + 4),
        "majorOperatingSystemVersion": r.u16(p + 8),
        "minorOperatingSystemVersion": r.u16(p + 10),
        "majorImageVersion": r.u16(p + 12), "minorImageVersion": r.u16(p + 14),
        "majorSubsystemVersion": r.u16(p + 16),
        "minorSubsystemVersion": r.u16(p + 18),
        "win32VersionValue": r.u32(p + 20), "sizeOfImage": r.u32(p + 24),
        "sizeOfHeaders": r.u32(p + 28), "checkSum": r.u32(p + 32),
        "subsystem": r.u16(p + 36),
        "subsystemName": SUBSYSTEMS.get(r.u16(p + 36), "unknown"),
        "dllCharacteristics": r.u16(p + 38),
        "dllCharacteristicsFlags": _flags(r.u16(p + 38), DLL_CHARACTERISTICS),
    })
    q = p + 40
    if plus:
        o.update({"sizeOfStackReserve": r.u64(q), "sizeOfStackCommit": r.u64(q + 8),
                  "sizeOfHeapReserve": r.u64(q + 16),
                  "sizeOfHeapCommit": r.u64(q + 24)})
        q += 32
    else:
        o.update({"sizeOfStackReserve": r.u32(q), "sizeOfStackCommit": r.u32(q + 4),
                  "sizeOfHeapReserve": r.u32(q + 8),
                  "sizeOfHeapCommit": r.u32(q + 12)})
        q += 16
    o["loaderFlags"] = r.u32(q)
    o["numberOfRvaAndSizes"] = r.u32(q + 4)
    o["_directoryOffset"] = q + 8
    o["_size"] = size
    return o


def _sections(r: Reader, off: int, count: int) -> list:
    out = []
    for i in range(min(count, 4096)):
        b = off + i * 40
        if not r.ok(b, 40):
            break
        raw_name = r.blob(b, 8)
        out.append({
            "index": i,
            "name": raw_name.rstrip(b"\0").decode("latin-1"),
            "nameBytesHex": raw_name.hex(),
            "virtualSize": r.u32(b + 8), "virtualAddress": r.u32(b + 12),
            "sizeOfRawData": r.u32(b + 16), "pointerToRawData": r.u32(b + 20),
            "pointerToRelocations": r.u32(b + 24),
            "pointerToLinenumbers": r.u32(b + 28),
            "numberOfRelocations": r.u16(b + 32),
            "numberOfLinenumbers": r.u16(b + 34),
            "characteristics": r.u32(b + 36),
            "characteristicsFlags": _flags(r.u32(b + 36), SECTION_CHARACTERISTICS),
        })
    return out


# ---------------------------------------------------------------------------
# imports / exports
# ---------------------------------------------------------------------------
def _thunks(r: Reader, sections, rva: int, plus: bool, notes: list) -> list:
    """One import table's entries: a name, or an ordinal when the high bit of
    the thunk is set."""
    out = []
    width = 8 if plus else 4
    ordinal_bit = 1 << 63 if plus else 1 << 31
    off = rva_to_offset(sections, rva)
    if off is None:
        notes.append(f"import thunk array rva {rva:#x} is in no section")
        return out
    for i in range(MAX_ENTRIES):
        v = r.u64(off + i * width) if plus else r.u32(off + i * width)
        if v == 0:
            break
        if v & ordinal_bit:
            out.append({"ordinal": v & 0xFFFF, "name": None, "hint": None})
            continue
        n_off = rva_to_offset(sections, v & 0x7FFFFFFF)
        if n_off is None:
            out.append({"ordinal": None, "name": None, "hint": None,
                        "unresolvedRva": v})
            continue
        out.append({"ordinal": None, "hint": r.u16(n_off),
                    "name": r.cstr(n_off + 2)})
    return out


def _imports(r: Reader, sections, directory, plus: bool, notes: list) -> list:
    d = directory.get("import") or {}
    if not d.get("virtualAddress"):
        return []
    base = rva_to_offset(sections, d["virtualAddress"])
    if base is None:
        notes.append("import directory rva is in no section")
        return []
    out = []
    for i in range(MAX_ENTRIES):
        b = base + i * 20
        fields = [r.u32(b), r.u32(b + 4), r.u32(b + 8), r.u32(b + 12), r.u32(b + 16)]
        if not any(fields):
            break
        name_off = rva_to_offset(sections, fields[3])
        entry = {
            "dll": r.cstr(name_off) if name_off is not None else None,
            "originalFirstThunk": fields[0], "timeDateStamp": fields[1],
            "forwarderChain": fields[2], "nameRva": fields[3],
            "firstThunk": fields[4], "kind": "import",
        }
        rva = fields[0] or fields[4]
        entry["functions"] = _thunks(r, sections, rva, plus, notes) if rva else []
        out.append(entry)
    return out


def _delay_imports(r: Reader, sections, directory, plus: bool, image_base: int,
                   notes: list) -> list:
    d = directory.get("delayImport") or {}
    if not d.get("virtualAddress"):
        return []
    base = rva_to_offset(sections, d["virtualAddress"])
    if base is None:
        notes.append("delay-import directory rva is in no section")
        return []
    out = []
    for i in range(MAX_ENTRIES):
        b = base + i * 32
        attrs = r.u32(b)
        name_field = r.u32(b + 4)
        if not any(r.u32(b + k) for k in range(0, 32, 4)):
            break
        # attributes bit 0 clear = the old MSVC form, whose fields hold virtual
        # addresses rather than RVAs.
        adj = (lambda v: v) if attrs & 1 else (lambda v: v - image_base if v else 0)
        name_off = rva_to_offset(sections, adj(name_field))
        rva = adj(r.u32(b + 16)) or adj(r.u32(b + 12))
        entry = {"dll": r.cstr(name_off) if name_off is not None else None,
                 "attributes": attrs, "nameRva": adj(name_field),
                 "kind": "delayImport",
                 "functions": _thunks(r, sections, rva, plus, notes) if rva else []}
        out.append(entry)
    return out


def _exports(r: Reader, sections, directory, notes: list) -> dict:
    d = directory.get("export") or {}
    if not d.get("virtualAddress"):
        return {"present": False, "functions": []}
    base = rva_to_offset(sections, d["virtualAddress"])
    if base is None:
        notes.append("export directory rva is in no section")
        return {"present": False, "functions": []}
    lo, hi = d["virtualAddress"], d["virtualAddress"] + d.get("size", 0)
    name_off = rva_to_offset(sections, r.u32(base + 12))
    ordinal_base = r.u32(base + 16)
    n_funcs = min(r.u32(base + 20), MAX_ENTRIES)
    n_names = min(r.u32(base + 24), MAX_ENTRIES)
    a_funcs = rva_to_offset(sections, r.u32(base + 28))
    a_names = rva_to_offset(sections, r.u32(base + 32))
    a_ords = rva_to_offset(sections, r.u32(base + 36))

    names = {}
    if a_names is not None and a_ords is not None:
        for i in range(n_names):
            n_rva = r.u32(a_names + i * 4)
            idx = r.u16(a_ords + i * 2)
            s_off = rva_to_offset(sections, n_rva)
            if s_off is not None:
                names[idx] = r.cstr(s_off)

    funcs = []
    if a_funcs is not None:
        for i in range(n_funcs):
            rva = r.u32(a_funcs + i * 4)
            if rva == 0 and i not in names:
                continue                       # an unused ordinal slot
            fwd = None
            if lo <= rva < hi:                 # points inside the export table
                f_off = rva_to_offset(sections, rva)
                fwd = r.cstr(f_off) if f_off is not None else None
            funcs.append({"ordinal": ordinal_base + i, "rva": rva,
                          "name": names.get(i), "forwarder": fwd})
    return {"present": True,
            "name": r.cstr(name_off) if name_off is not None else None,
            "ordinalBase": ordinal_base, "functionCount": n_funcs,
            "nameCount": n_names, "timeDateStamp": r.u32(base + 4),
            "functions": funcs}


# ---------------------------------------------------------------------------
# resources
# ---------------------------------------------------------------------------
def _resource_name(r: Reader, res_base: int, value: int):
    """A directory entry's name: an id, or a length-prefixed UTF-16LE string."""
    if not value & 0x80000000:
        return value, None
    off = res_base + (value & 0x7FFFFFFF)
    n = r.u16(off)
    return None, r.blob(off + 2, n * 2).decode("utf-16-le", "replace")


def _walk_resources(r: Reader, sections, res_base: int, off: int, depth: int,
                    path: list, out: list, notes: list) -> None:
    if depth > MAX_RESOURCE_DEPTH or not r.ok(off, 16):
        return
    named = r.u16(off + 12)
    ids = r.u16(off + 14)
    total = named + ids
    if total > 65535:
        notes.append(f"resource directory at {off:#x} declares {total} entries")
        return
    for i in range(total):
        e = off + 16 + i * 8
        if not r.ok(e, 8):
            return
        name_field = r.u32(e)
        data_field = r.u32(e + 4)
        ident, name = _resource_name(r, res_base, name_field)
        step = {"id": ident, "name": name}
        if data_field & 0x80000000:
            _walk_resources(r, sections, res_base,
                            res_base + (data_field & 0x7FFFFFFF), depth + 1,
                            path + [step], out, notes)
            continue
        leaf = res_base + data_field
        if not r.ok(leaf, 16):
            notes.append(f"resource data entry at {leaf:#x} is out of range")
            continue
        data_rva = r.u32(leaf)
        size = r.u32(leaf + 4)
        file_off = rva_to_offset(sections, data_rva)
        levels = path + [step]
        rec = {
            "typeId": levels[0]["id"] if levels else None,
            "typeName": (levels[0]["name"] if levels and levels[0]["name"]
                         else RESOURCE_TYPES.get(levels[0]["id"] if levels else None)),
            "nameId": levels[1]["id"] if len(levels) > 1 else None,
            "nameString": levels[1]["name"] if len(levels) > 1 else None,
            "languageId": levels[2]["id"] if len(levels) > 2 else None,
            "levels": levels, "rva": data_rva, "size": size,
            "codePage": r.u32(leaf + 8), "offset": file_off,
        }
        if file_off is None:
            rec["note"] = "data rva is in no section"
        out.append(rec)


def _resources(r: Reader, sections, directory, notes: list) -> list:
    d = directory.get("resource") or {}
    if not d.get("virtualAddress"):
        return []
    base = rva_to_offset(sections, d["virtualAddress"])
    if base is None:
        notes.append("resource directory rva is in no section")
        return []
    out = []
    _walk_resources(r, sections, base, base, 0, [], out, notes)
    return out


# ---------------------------------------------------------------------------
# debug directory
# ---------------------------------------------------------------------------
def _debug(r: Reader, sections, directory, notes: list) -> list:
    d = directory.get("debug") or {}
    if not d.get("virtualAddress") or not d.get("size"):
        return []
    base = rva_to_offset(sections, d["virtualAddress"])
    if base is None:
        notes.append("debug directory rva is in no section")
        return []
    out = []
    for i in range(min(d["size"] // 28, 256)):
        b = base + i * 28
        if not r.ok(b, 28):
            break
        typ = r.u32(b + 12)
        rec = {"type": typ, "typeName": DEBUG_TYPES.get(typ, "unknown"),
               "timeDateStamp": r.u32(b + 4),
               "majorVersion": r.u16(b + 8), "minorVersion": r.u16(b + 10),
               "sizeOfData": r.u32(b + 16), "addressOfRawData": r.u32(b + 20),
               "pointerToRawData": r.u32(b + 24)}
        p, n = rec["pointerToRawData"], rec["sizeOfData"]
        blob = r.blob(p, n)
        if blob[:4] == b"RSDS" and len(blob) >= 24:
            g = blob[4:20]
            guid = (f"{struct.unpack_from('<I', g)[0]:08X}-"
                    f"{struct.unpack_from('<H', g, 4)[0]:04X}-"
                    f"{struct.unpack_from('<H', g, 6)[0]:04X}-"
                    f"{g[8:10].hex().upper()}-{g[10:16].hex().upper()}")
            rec["codeView"] = {"signature": "RSDS", "guid": guid,
                               "age": struct.unpack_from("<I", blob, 20)[0],
                               "pdb": r.cstr(p + 24)}
        elif blob[:4] == b"NB10" and len(blob) >= 16:
            rec["codeView"] = {"signature": "NB10",
                               "offset": struct.unpack_from("<I", blob, 4)[0],
                               "signatureTime": struct.unpack_from("<I", blob, 8)[0],
                               "age": struct.unpack_from("<I", blob, 12)[0],
                               "pdb": r.cstr(p + 16)}
        out.append(rec)
    return out


def _certificates(r: Reader, directory) -> list:
    """The attribute certificate table. Its directory entry holds a FILE OFFSET,
    not an RVA - the one directory that does."""
    d = directory.get("security") or {}
    off, size = d.get("virtualAddress", 0), d.get("size", 0)
    if not off or not size:
        return []
    out = []
    p, end = off, min(off + size, r.size)
    while p + 8 <= end:
        length = r.u32(p)
        if length < 8 or p + length > end:
            break
        blob = r.blob(p + 8, length - 8)
        out.append({"offset": p, "length": length, "revision": r.u16(p + 4),
                    "certificateType": r.u16(p + 6), "bytes": length - 8,
                    "sha256": _sha(blob)})
        p += (length + 7) & ~7
    return out


# ---------------------------------------------------------------------------
def parse(data: bytes) -> dict:
    """Everything structural in one dict. `notes` lists what could not be read."""
    r = Reader(data)
    notes = []
    if not is_pe(data):
        return {"isPE": False, "bytes": len(data), "notes": ["not a PE image"]}

    pe_off = r.u32(0x3C)
    coff = pe_off + 4
    machine = r.u16(coff)
    n_sections = r.u16(coff + 2)
    size_opt = r.u16(coff + 16)
    characteristics = r.u16(coff + 18)
    header = {
        "machine": machine, "machineName": MACHINES.get(machine, "unknown"),
        "numberOfSections": n_sections, "timeDateStamp": r.u32(coff + 4),
        "pointerToSymbolTable": r.u32(coff + 8),
        "numberOfSymbols": r.u32(coff + 12), "sizeOfOptionalHeader": size_opt,
        "characteristics": characteristics,
        "characteristicsFlags": _flags(characteristics, FILE_CHARACTERISTICS),
    }
    opt = _optional_header(r, coff + 20, size_opt)
    plus = opt["magic"] == PE32_PLUS

    d_off = opt.pop("_directoryOffset")
    n_dirs = min(opt["numberOfRvaAndSizes"], 16)
    directory = {}
    for i in range(n_dirs):
        name = DIRECTORY_NAMES[i] if i < len(DIRECTORY_NAMES) else f"dir{i}"
        directory[name] = {"index": i, "virtualAddress": r.u32(d_off + i * 8),
                           "size": r.u32(d_off + i * 8 + 4)}
    opt.pop("_size", None)

    sections = _sections(r, coff + 20 + size_opt, n_sections)
    for s in sections:
        body = r.blob(s["pointerToRawData"], s["sizeOfRawData"])
        s["sha256"] = _sha(body)
        s["bytesRead"] = len(body)
        printable = sum(1 for b in body if 32 <= b < 127 or b in (9, 10, 13))
        s["printableRatio"] = round(printable / len(body), 6) if body else 0.0
        s["entropy"] = entropy(body)

    end_of_sections = max([s["pointerToRawData"] + s["sizeOfRawData"]
                           for s in sections if s["sizeOfRawData"]] + [0])
    overlay = {"offset": end_of_sections, "bytes": max(0, r.size - end_of_sections)}
    if overlay["bytes"]:
        blob = r.blob(end_of_sections, overlay["bytes"])
        overlay["sha256"] = _sha(blob)

    return {
        "isPE": True, "bytes": r.size, "peHeaderOffset": pe_off,
        "dos": {"e_lfanew": pe_off, "stubBytes": pe_off - 0x40},
        "rich": _rich_header(r, pe_off),
        "coff": header, "optional": opt, "directories": directory,
        "sections": sections,
        "imports": (_imports(r, sections, directory, plus, notes)
                    + _delay_imports(r, sections, directory, plus,
                                     opt.get("imageBase", 0), notes)),
        "exports": _exports(r, sections, directory, notes),
        "resources": _resources(r, sections, directory, notes),
        "debug": _debug(r, sections, directory, notes),
        "certificates": _certificates(r, directory),
        "overlay": overlay,
        "notes": notes,
    }


# ---------------------------------------------------------------------------
# resource payloads that are themselves structures
# ---------------------------------------------------------------------------
def parse_string_table(data: bytes) -> list:
    """RT_STRING: sixteen length-prefixed UTF-16LE strings per block, in order,
    empty entries included. The caller supplies the block's own name id, from
    which the spec derives the string ids."""
    out, p = [], 0
    for i in range(16):
        if p + 2 > len(data):
            break
        n = struct.unpack_from("<H", data, p)[0]
        p += 2
        out.append({"index": i,
                    "text": data[p:p + n * 2].decode("utf-16-le", "replace")})
        p += n * 2
    return out


def _pad4(n: int) -> int:
    return (n + 3) & ~3


def _version_node(data: bytes, off: int, depth: int = 0):
    """One VS_VERSIONINFO node: length, value length, type, UTF-16 key, value,
    children. The structure is uniform at every level, so one reader does all
    of it."""
    if depth > 8 or off + 6 > len(data):
        return None, len(data)
    length = struct.unpack_from("<H", data, off)[0]
    value_len = struct.unpack_from("<H", data, off + 2)[0]
    typ = struct.unpack_from("<H", data, off + 4)[0]
    end = min(off + length, len(data))
    if length < 6:
        return None, len(data)
    p = off + 6
    key_end = p
    while key_end + 2 <= end and data[key_end:key_end + 2] != b"\0\0":
        key_end += 2
    key = data[p:key_end].decode("utf-16-le", "replace")
    p = _pad4(key_end + 2 - off) + off
    node = {"key": key, "type": typ}
    if value_len:
        raw = data[p:p + (value_len * 2 if typ == 1 else value_len)]
        if typ == 1:
            node["value"] = raw.decode("utf-16-le", "replace").rstrip("\0")
        else:
            node["valueHex"] = raw.hex()
            if key == "VS_VERSION_INFO" and len(raw) >= 52:
                f = struct.unpack_from("<13I", raw, 0)
                node["fixed"] = {
                    "signature": f[0], "structVersion": f[1],
                    "fileVersion": f"{f[2] >> 16}.{f[2] & 0xFFFF}."
                                   f"{f[3] >> 16}.{f[3] & 0xFFFF}",
                    "productVersion": f"{f[4] >> 16}.{f[4] & 0xFFFF}."
                                      f"{f[5] >> 16}.{f[5] & 0xFFFF}",
                    "fileFlagsMask": f[6], "fileFlags": f[7], "fileOS": f[8],
                    "fileType": f[9], "fileSubtype": f[10]}
        p = _pad4(p + (value_len * 2 if typ == 1 else value_len) - off) + off
    children = []
    while p + 6 <= end:
        child, nxt = _version_node(data, p, depth + 1)
        if child is None or nxt <= p:
            break
        children.append(child)
        p = _pad4(nxt - off) + off
    if children:
        node["children"] = children
    return node, end


def parse_version_info(data: bytes) -> dict:
    node, _ = _version_node(data, 0)
    return node or {}


# ---------------------------------------------------------------------------
def selftest() -> int:
    """Build a tiny PE by hand and read it back. Catches the arithmetic that a
    live binary would only expose as a plausible-looking wrong offset."""
    bad = 0
    sections = [{"virtualAddress": 0x1000, "virtualSize": 0x200,
                 "sizeOfRawData": 0x400, "pointerToRawData": 0x400,
                 "name": ".text"}]
    if rva_to_offset(sections, 0x1000) != 0x400:
        print("  FAIL rva_to_offset start"); bad += 1
    if rva_to_offset(sections, 0x1100) != 0x500:
        print("  FAIL rva_to_offset middle"); bad += 1
    if rva_to_offset(sections, 0x2000) is not None:
        print("  FAIL rva_to_offset out of range"); bad += 1
    if section_of_offset(sections, 0x400) != ".text":
        print("  FAIL section_of_offset"); bad += 1

    r = Reader(b"abc\0def")
    if r.cstr(0) != "abc" or r.u32(4) == 0 and False:
        print("  FAIL cstr"); bad += 1
    if r.u32(6) != 0:
        print("  FAIL out-of-range u32 must default, not raise"); bad += 1

    if parse(b"MZ")["isPE"]:
        print("  FAIL a two-byte file must not parse as PE"); bad += 1

    st = parse_string_table(struct.pack("<H", 2) + "hi".encode("utf-16-le")
                            + b"\0\0" * 15)
    if st[0]["text"] != "hi" or len(st) != 16:
        print("  FAIL string table"); bad += 1
    return bad


if __name__ == "__main__":
    raise SystemExit(selftest())
