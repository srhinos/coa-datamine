"""Nested containers, as a pure library.

A member of an MPQ can itself be an archive. This module answers, from BYTES
alone: is this a container, what kind, and what is inside it - one level down and
then recursively while the members are containers too.

Discovery is by MAGIC, never by name, so a nested archive with the wrong
extension is still found and a file merely named `.rar` is not mis-parsed.

Moved verbatim out of the retired `tools/crack.py`. Nothing here opens an
archive or walks the client: `datamine.py` hands it bytes it already read.

WHAT THIS DELIBERATELY DOES NOT DO
----------------------------------
It is not a RAR decompressor - RAR's own compression is patent-encumbered and
out of scope for a standard-library pipeline. It indexes every member's name,
sizes, CRC and method, and extracts the bytes of members stored uncompressed.
"We did not look" and "we looked and here is exactly what is in it" are
different answers, and only the second one is honest about what the container
holds.
"""
import collections
import hashlib
import plistlib
import re
import struct
from pathlib import Path

from tools import config, mpq

# Where expanded bytes land, and the scratch a nested archive is opened from.
# Module globals so the driver can point them at its staging tree; `OUT_DIR` is
# only used to express a written path RELATIVE to the layer.
OUT_DIR = config.RAW_DIR / "recovered" / "containers"
WORK_DIR = config.WORK_DIR / "containers"

# The recorded-not-committed rule, applied inside a container exactly as it is
# applied outside one: a member's BYTES are committed when it is small enough
# and belongs to a data class this repo commits. Art and sound inside a
# container are recorded (name, size, CRC) and their bytes left where they are,
# which is the same decision made for art and sound in the archives themselves.
#
# NOTE: `COMMIT_CLASSES` is DEFINED here. The retired tools/crack.py referenced
# it in two places and never assigned it, so its nested-MPQ expansion raised
# NameError into an exception handler and silently expanded nothing - which is
# why the committed raw/recovered/containers/ records `launcher.mpq` with no
# member list at all. Defining it is a fix, not a port.
COMMIT_MAX_BYTES = 8 * 1024 * 1024
COMMIT_CLASSES = {"dbc", "content", "interface", "other"}

_SLUG_RE = re.compile(r"[^a-z0-9]+")


def _slug(text: str) -> str:
    return _SLUG_RE.sub("-", str(text).lower()).strip("-") or "_"


CONTAINER_RULE = (
    "Anything that is itself a container of other files, expanded one level and "
    "then recursively while the members are containers too. Discovery is "
    "mechanical - a member is a container if its BYTES start with a signature "
    "this stage knows, never because of its name - so a nested archive with the "
    "wrong extension is still found and a file merely named .rar is not "
    "mis-parsed. Art and sound inside a container obey the same "
    "recorded-not-committed rule as everywhere else.")

_MAGIC = (
    (b"MPQ\x1a", "mpq"), (b"MPQ\x1b", "mpq"),
    (b"Rar!\x1a\x07\x00", "rar4"), (b"Rar!\x1a\x07\x01\x00", "rar5"),
    (b"PK\x03\x04", "zip"), (b"\x1f\x8b", "gzip"),
    (b"bplist00", "bplist"), (b"BZh", "bzip2"),
    (b"MSCF", "cab"), (b"7z\xbc\xaf\x27\x1c", "7z"),
)


def _sniff(data: bytes):
    for magic, kind in _MAGIC:
        if data.startswith(magic):
            return kind
    return None


def _expand_rar(data: bytes) -> dict:
    """Index a RAR4 volume: every member's name, sizes, CRC and method, and the
    bytes of any member stored uncompressed.

    Deliberately not a RAR decompressor - RAR's own compression is patent-
    encumbered and out of scope for a stdlib pipeline - but 'we did not look' and
    'we looked and here is exactly what is in it' are different answers, and only
    the second one is honest about what the container holds."""
    METHODS = {0x30: "stored", 0x31: "fastest", 0x32: "fast", 0x33: "normal",
               0x34: "good", 0x35: "best"}
    members, extracted, blobs = [], 0, {}
    pos = 7 if data.startswith(b"Rar!\x1a\x07\x00") else 0
    while pos + 7 <= len(data):
        _crc, htype, flags, hsize = struct.unpack_from("<HBHH", data, pos)
        if hsize < 7 or pos + hsize > len(data):
            break
        # A block declares a data body after its header with ADD_SIZE, the first
        # dword past the 7-byte base header. For a file block that same dword IS
        # the packed size, so one rule advances past every block type.
        add = 0
        if flags & 0x8000 and pos + 11 <= len(data):
            (add,) = struct.unpack_from("<I", data, pos + 7)
        if htype == 0x74 and pos + 32 <= len(data):
            packed, unpacked, _host, fcrc, _time, _ver, method, namelen, attr = \
                struct.unpack_from("<IIBIIBBHI", data, pos + 7)
            cursor = pos + 32
            if flags & 0x100 and cursor + 8 <= len(data):     # 64-bit sizes
                high_packed, high_unpacked = struct.unpack_from("<II", data, cursor)
                packed |= high_packed << 32
                unpacked |= high_unpacked << 32
                cursor += 8
            name = data[cursor:cursor + namelen].split(b"\0")[0].decode(
                "latin-1", "replace")
            body = pos + hsize
            row = {"name": name.replace("\\", "/"), "packedBytes": packed,
                   "bytes": unpacked, "crc32": f"{fcrc:08x}",
                   "method": f"0x{method:02x}",
                   "methodName": METHODS.get(method, f"unknown(0x{method:02x})"),
                   "directory": bool(attr & 0x10),
                   "encrypted": bool(flags & 0x04)}
            if (method == 0x30 and packed and not flags & 0x04
                    and body + packed <= len(data)):
                blob = data[body:body + packed]
                row["sha256"] = sha256(blob)
                row["extracted"] = True
                blobs[row["name"]] = blob
                extracted += 1
            members.append(row)
            add = packed
        pos += hsize + add
    return ({"format": "rar4", "members": members, "memberCount": len(members),
             "storedMembersExtracted": extracted,
             "note": ("RAR's own compression methods are not implemented - they are "
                      "outside a stdlib pipeline. Members stored uncompressed "
                      "(method 0x30) ARE extracted and hashed; every other member "
                      "is indexed with the name, sizes, CRC32 and method the "
                      "archive itself declares, so what the container holds is "
                      "recorded even where the bytes are not decodable here.")},
            blobs)


def _vint(data: bytes, pos: int):
    """RAR5's variable-length integer: 7 bits per byte, little-endian, high bit
    means 'another byte follows'."""
    value = shift = 0
    while pos < len(data):
        byte = data[pos]
        pos += 1
        value |= (byte & 0x7F) << shift
        if not byte & 0x80:
            return value, pos
        shift += 7
        if shift > 63:
            break
    raise ValueError("RAR5: truncated variable-length integer")


def _expand_rar5(data: bytes) -> tuple:
    """Index a RAR5 volume. Same policy as RAR4: no RAR decompressor, but every
    member's name, sizes, CRC, method and timestamp are read out of the headers,
    and members stored uncompressed are extracted."""
    METHODS = {0: "stored", 1: "fastest", 2: "fast", 3: "normal", 4: "good",
               5: "best"}
    members, extracted, blobs = [], 0, {}
    pos = 8
    while pos + 8 < len(data):
        try:
            start = pos + 4                     # past the header CRC32
            header_size, cursor = _vint(data, start)
            header_start = cursor
            htype, cursor = _vint(data, cursor)
            hflags, cursor = _vint(data, cursor)
            extra_size = data_size = 0
            if hflags & 0x0001:
                extra_size, cursor = _vint(data, cursor)
            if hflags & 0x0002:
                data_size, cursor = _vint(data, cursor)
            if htype in (2, 3):                 # file header / service header
                file_flags, cursor = _vint(data, cursor)
                unpacked, cursor = _vint(data, cursor)
                _attrs, cursor = _vint(data, cursor)
                mtime = None
                if file_flags & 0x0002:
                    (mtime,) = struct.unpack_from("<I", data, cursor)
                    cursor += 4
                crc = None
                if file_flags & 0x0004:
                    (crc,) = struct.unpack_from("<I", data, cursor)
                    cursor += 4
                comp_info, cursor = _vint(data, cursor)
                _host_os, cursor = _vint(data, cursor)
                name_len, cursor = _vint(data, cursor)
                name = data[cursor:cursor + name_len].decode("utf-8", "replace")
                method = (comp_info >> 7) & 0x07
                body = header_start + header_size
                row = {"name": name.replace("\\", "/"), "packedBytes": data_size,
                       "bytes": unpacked if not file_flags & 0x0008 else None,
                       "crc32": f"{crc:08x}" if crc is not None else None,
                       "method": method,
                       "methodName": METHODS.get(method, f"unknown({method})"),
                       "directory": bool(file_flags & 0x0001),
                       "encryptedHeaderExtra": bool(extra_size),
                       "kind": "service" if htype == 3 else "file"}
                if mtime:
                    import datetime
                    row["mtime"] = datetime.datetime.fromtimestamp(
                        mtime, datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
                if (method == 0 and data_size and htype == 2
                        and body + data_size <= len(data)):
                    blob = data[body:body + data_size]
                    row["sha256"] = sha256(blob)
                    row["extracted"] = True
                    blobs[row["name"]] = blob
                    extracted += 1
                members.append(row)
            pos = header_start + header_size + data_size
            if header_size <= 0:
                break
        except Exception:                        # noqa: BLE001 - stop at the end
            break
    return ({"format": "rar5", "members": members,
             "memberCount": sum(1 for m in members if m["kind"] == "file"),
             "serviceRecords": sum(1 for m in members if m["kind"] == "service"),
             "storedMembersExtracted": extracted,
             "note": ("RAR5's own compression is not implemented - it is outside a "
                      "stdlib pipeline. Members stored uncompressed ARE extracted "
                      "and hashed; every other member is indexed with the name, "
                      "sizes, CRC32, method and timestamp the archive declares.")},
            blobs)


def _expand_bplist(data: bytes) -> dict:
    obj = plistlib.loads(data)

    def clean(value):
        if isinstance(value, dict):
            return {str(k): clean(v) for k, v in value.items()}
        if isinstance(value, (list, tuple)):
            return [clean(v) for v in value]
        if isinstance(value, (bytes, bytearray)):
            return {"__bytes_sha256__": sha256(bytes(value)), "__len__": len(value)}
        if isinstance(value, (str, int, float, bool)) or value is None:
            return value
        return str(value)
    return {"format": "bplist", "plist": clean(obj)}


def _expand_nested_mpq(data: bytes, name: str, out_dir: Path) -> dict:
    tmp = WORK_DIR / "nested" / (_slug(name) + ".mpq")
    tmp.parent.mkdir(parents=True, exist_ok=True)
    tmp.write_bytes(data)
    members, written = [], 0
    with mpq.Archive(tmp) as archive:
        names = archive.list_names()
        seen = collections.Counter()
        targets = names if names is not None else []
        for member_name in sorted(targets):
            member = archive.read(member_name, seen=seen)
            # imported here, not at module scope: tools/emit.py reaches for this
            # module lazily too, and a top-level pair would be a cycle
            from tools.emit import path_class
            row = {"path": member_name.replace("\\", "/"), "status": member.status,
                   "bytes": member.size,
                   "class": path_class(member_name.replace("/", "\\").lower(),
                                       "mpq")}
            if member.ok and member.data is not None:
                row["sha256"] = sha256(member.data)
                if row["class"] in COMMIT_CLASSES and len(member.data) <= COMMIT_MAX_BYTES:
                    target = out_dir / member_name.replace("\\", "/")
                    target.parent.mkdir(parents=True, exist_ok=True)
                    target.write_bytes(member.data)
                    row["committedAt"] = str(
                        target.relative_to(OUT_DIR)).replace("\\", "/")
                    written += 1
            elif member.detail:
                row["detail"] = member.detail
            members.append(row)
        attrs = archive.attributes()
        header = dict(archive.header)
        header.pop("magic", None)
    return {"format": "mpq", "members": members, "memberCount": len(members),
            "membersCommitted": written,
            "listfileNames": None if names is None else len(names),
            "attributeEntries": attrs.get("entries", 0),
            "blockEntries": header["block_table_entries"],
            "compression": dict(seen)}



def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def sniff(data: bytes):
    """Public name for the magic test - see CONTAINER_RULE."""
    return _sniff(data)
