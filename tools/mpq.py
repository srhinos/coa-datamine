"""A complete MPQ reader, in pure Python, written because `mpyq` is not one.

WHY THIS EXISTS
---------------
Every extractor in this repo read the client through `mpyq`, and `mpyq` gets
three things wrong that together account for EVERY file this pipeline has ever
been unable to read:

1. IT MISCLASSIFIES STORED SECTORS.  An MPQ sector is compressed if and only if
   its STORED length is smaller than the length that sector is supposed to
   expand to - `min(sector_size, file_size - i * sector_size)`.  `mpyq` instead
   tests the stored length against the number of bytes left in the WHOLE FILE,
   which is a different and much larger number, so every uncompressed sector in
   a file that still has more than one sector to go is fed to the decompressor.
   Its first byte is then read as a compression mask, is not 0x02 or 0x10, and
   the read dies with "Unsupported compression type".  That single line is
   35,853 of this client's 41,053 unreadable files.  Nothing is missing from
   `mpyq` for those files; the format was simply read wrongly.

2. IT READS UNCOMPRESSED MEMBERS AS IF THEY HAD A SECTOR OFFSET TABLE.  A member
   stored with no compression has NO such table - its sectors are contiguous.
   `mpyq` reads the file's own first bytes as offsets and returns a salad of
   slices of itself.  1,271 members of this client are stored that way and
   1,266 of them come out WRONG - and silently wrong, because nothing raises and
   the result still starts with the right bytes.  Those are the client's music
   and cinematics, so `raw/_inventory` carried 1,186 confident sha256s over
   bytes that were never in the archive.  Measured, not deduced: every one of
   the 1,271 is checked against the MD5 its archive recorded, by
   `tools/crack.py --only verify`.

3. IT CANNOT DECRYPT FILE DATA AT ALL, and it stops at zlib and bzip2.

A fourth defect is real but turns out to be harmless HERE, and is recorded that
way rather than as a scare: `size // sector_size + 1` is one sector too many
when the size is an exact multiple of the sector size (675 members).  The extra
slice it reads is always empty, so 668 of those still come out byte-correct and
7 raise.  The arithmetic is wrong; the output happens not to be.

MEASURED, NOT ASSUMED
---------------------
The compression census this module's dispatcher records over the whole client
(see `tools/crack.py`) is the evidence for what the client actually uses:

    stored / 0x02 zlib / 0x10 bzip2      the only masks present, 44.9 GB
    0x01 huffman, 0x08 PKWARE implode,
    0x20 sparse, 0x40/0x80 ADPCM        ZERO occurrences

PKWARE explode and sparse are implemented here anyway, because a reader that
would fail on them is a reader that cannot honestly claim the client holds none
of them.  Huffman and ADPCM are DELIBERATELY NOT implemented: both are audio
codecs, this client contains no sector that uses either, and shipping a
from-memory DSP decoder that no byte in the client can exercise would be
asserting a correctness nobody checked.  They raise `Unsupported` naming the
mask, so a future client that does use them stops the run LOUDLY instead of
being skipped - which is the actual requirement.

SELF-TEST
---------
    python -m tools.mpq --selftest

covers the PKWARE explode tables and stream, sparse round-trip, the crypt
primitives, and keyless recovery of an encrypted file's key.  `tools/crack.py`
additionally gates the reader against `mpyq` on real archive members: 2,000
files both readers accept must come out byte-for-byte identical, which is what
makes "the corrected reader recovers 36,141 more files" a claim about this
client rather than about a mock.
"""
import argparse
import bz2
import collections
import os
import struct
import sys
import zlib
from pathlib import Path

# ---------------------------------------------------------------- block flags
MPQ_FILE_IMPLODE = 0x00000100
MPQ_FILE_COMPRESS = 0x00000200
MPQ_FILE_ENCRYPTED = 0x00010000
MPQ_FILE_FIX_KEY = 0x00020000
MPQ_FILE_PATCH_FILE = 0x00100000
MPQ_FILE_SINGLE_UNIT = 0x01000000
MPQ_FILE_DELETE_MARKER = 0x02000000
MPQ_FILE_SECTOR_CRC = 0x04000000
MPQ_FILE_EXISTS = 0x80000000

FLAG_NAMES = (
    (MPQ_FILE_IMPLODE, "IMPLODE"), (MPQ_FILE_COMPRESS, "COMPRESS"),
    (MPQ_FILE_ENCRYPTED, "ENCRYPTED"), (MPQ_FILE_FIX_KEY, "FIX_KEY"),
    (MPQ_FILE_PATCH_FILE, "PATCH_FILE"), (MPQ_FILE_SINGLE_UNIT, "SINGLE_UNIT"),
    (MPQ_FILE_DELETE_MARKER, "DELETE_MARKER"), (MPQ_FILE_SECTOR_CRC, "SECTOR_CRC"),
    (MPQ_FILE_EXISTS, "EXISTS"),
)

HASH_EMPTY = 0xFFFFFFFF
HASH_DELETED = 0xFFFFFFFE

# hash_string() kinds
HASH_TABLE_OFFSET = 0
HASH_NAME_A = 1
HASH_NAME_B = 2
HASH_FILE_KEY = 3


def flag_names(flags: int) -> list:
    """Every named bit set in `flags`, plus any bit this module has no name for -
    an unknown flag is reported as `UNKNOWN_0x...` rather than dropped."""
    out, known = [], 0
    for bit, name in FLAG_NAMES:
        known |= bit
        if flags & bit:
            out.append(name)
    rest = flags & ~known
    if rest:
        out.append(f"UNKNOWN_0x{rest:08X}")
    return out


class Unsupported(Exception):
    """A sector this reader will not guess at. Carries the mask so the caller can
    count occurrences per method instead of reporting one opaque total."""

    def __init__(self, message, mask=None):
        super().__init__(message)
        self.mask = mask


class Corrupt(Exception):
    """The archive's own numbers do not agree with each other."""


# --------------------------------------------------------------------------
# crypt primitives
# --------------------------------------------------------------------------
def _prepare_crypt_table() -> list:
    table = [0] * 0x500
    seed = 0x00100001
    for i in range(0x100):
        index = i
        for _ in range(5):
            seed = (seed * 125 + 3) % 0x2AAAAB
            temp1 = (seed & 0xFFFF) << 16
            seed = (seed * 125 + 3) % 0x2AAAAB
            temp2 = seed & 0xFFFF
            table[index] = temp1 | temp2
            index += 0x100
    return table


CRYPT_TABLE = _prepare_crypt_table()


def hash_string(text, kind: int) -> int:
    """The MPQ string hash. `text` may be str or bytes; MPQ names are compared
    case-insensitively and with '/' normalised to '\\', which is done here so no
    caller has to remember to do it."""
    if isinstance(text, bytes):
        text = text.decode("latin-1")
    seed1, seed2 = 0x7FED7FED, 0xEEEEEEEE
    base = kind << 8
    for ch in text.upper().replace("/", "\\"):
        c = ord(ch)
        value = CRYPT_TABLE[base + (c & 0xFF)]
        seed1 = (value ^ (seed1 + seed2)) & 0xFFFFFFFF
        seed2 = (c + seed1 + seed2 + (seed2 << 5) + 3) & 0xFFFFFFFF
    return seed1


def decrypt_dwords(data: bytes, key: int) -> bytes:
    """Decrypt the whole-dword prefix of `data`, leaving any trailing 1-3 bytes
    verbatim. Blizzard's encryptor works in dwords and leaves the tail in the
    clear; `mpyq` DROPS that tail, which silently truncates every encrypted
    member whose length is not a multiple of 4."""
    n = len(data) // 4
    if not n:
        return data
    out = bytearray(data)
    seed1 = key & 0xFFFFFFFF
    seed2 = 0xEEEEEEEE
    for i in range(n):
        seed2 = (seed2 + CRYPT_TABLE[0x400 + (seed1 & 0xFF)]) & 0xFFFFFFFF
        value = struct.unpack_from("<I", data, i * 4)[0]
        value = (value ^ (seed1 + seed2)) & 0xFFFFFFFF
        seed1 = ((((~seed1) << 0x15) & 0xFFFFFFFF) + 0x11111111) | (seed1 >> 0x0B)
        seed1 &= 0xFFFFFFFF
        seed2 = (value + seed2 + (seed2 << 5) + 3) & 0xFFFFFFFF
        struct.pack_into("<I", out, i * 4, value)
    return bytes(out)


def encrypt_dwords(data: bytes, key: int) -> bytes:
    """The inverse of decrypt_dwords. Used only by the self-test, which needs to
    build an encrypted member in order to prove the decryptor and the keyless
    key-recovery both work."""
    n = len(data) // 4
    if not n:
        return data
    out = bytearray(data)
    seed1 = key & 0xFFFFFFFF
    seed2 = 0xEEEEEEEE
    for i in range(n):
        seed2 = (seed2 + CRYPT_TABLE[0x400 + (seed1 & 0xFF)]) & 0xFFFFFFFF
        plain = struct.unpack_from("<I", data, i * 4)[0]
        cipher = (plain ^ (seed1 + seed2)) & 0xFFFFFFFF
        seed1 = ((((~seed1) << 0x15) & 0xFFFFFFFF) + 0x11111111) | (seed1 >> 0x0B)
        seed1 &= 0xFFFFFFFF
        seed2 = (plain + seed2 + (seed2 << 5) + 3) & 0xFFFFFFFF
        struct.pack_into("<I", out, i * 4, cipher)
    return bytes(out)


def base_name(path: str) -> str:
    """The part of an archive path a per-file key is derived from: MPQ keys the
    file on its BASENAME, not on the full path."""
    p = path.replace("/", "\\")
    return p.rsplit("\\", 1)[-1]


def file_key(name: str, flags: int = 0, block_offset: int = 0, file_size: int = 0) -> int:
    """The per-file encryption key. MPQ_FILE_FIX_KEY mixes in the file's position
    and length, which is why the same name in two archives can need two keys."""
    key = hash_string(base_name(name), HASH_FILE_KEY)
    if flags & MPQ_FILE_FIX_KEY:
        key = ((key + block_offset) ^ file_size) & 0xFFFFFFFF
    return key


def detect_file_key(encrypted_table: bytes, expected_first: int):
    """Recover an encrypted file's key from its sector offset table alone, with
    no filename - the classic StormLib seed detection.

    The first entry of a sector offset table is always the table's own byte
    length, so one known plaintext dword plus one structural constraint on the
    second (the offset of sector 1, small for any sane sector) is enough to pin
    the key. This is what makes an encrypted member with an unknown or unlisted
    name still recoverable.

    Returns the FILE key - the sector table itself is encrypted with key-1, and
    that -1 is undone here so the caller always holds the same key it would have
    derived from a filename. Returns None when nothing fits.

    The 16-bit constraint on the second dword is a disambiguator, not a
    requirement: a file with more than ~16k sectors has a sector offset table
    longer than 0xFFFF and legitimately fails it, so a self-consistent candidate
    that is the ONLY one is accepted without it rather than thrown away."""
    if len(encrypted_table) < 8:
        return None
    e0, e1 = struct.unpack_from("<2I", encrypted_table, 0)
    temp = ((e0 ^ expected_first) - 0xEEEEEEEE) & 0xFFFFFFFF
    candidates = []
    for i in range(0x100):
        seed1 = (temp - CRYPT_TABLE[0x400 + i]) & 0xFFFFFFFF
        seed2 = (0xEEEEEEEE + CRYPT_TABLE[0x400 + (seed1 & 0xFF)]) & 0xFFFFFFFF
        value = (e0 ^ (seed1 + seed2)) & 0xFFFFFFFF
        if value != expected_first:
            continue
        found = (seed1 + 1) & 0xFFFFFFFF     # table key + 1 == the file key
        seed1 = ((((~seed1) << 0x15) & 0xFFFFFFFF) + 0x11111111) | (seed1 >> 0x0B)
        seed1 &= 0xFFFFFFFF
        seed2 = (value + seed2 + (seed2 << 5) + 3) & 0xFFFFFFFF
        seed2 = (seed2 + CRYPT_TABLE[0x400 + (seed1 & 0xFF)]) & 0xFFFFFFFF
        second = (e1 ^ (seed1 + seed2)) & 0xFFFFFFFF
        if (second & 0xFFFF0000) == 0:
            return found
        candidates.append(found)
    return candidates[0] if len(candidates) == 1 else None


# --------------------------------------------------------------------------
# PKWARE Data Compression Library - "explode"  (compression mask 0x08)
# --------------------------------------------------------------------------
# The three canonical Huffman code sets, in PKWARE's compact run-length form:
# each byte is (repeat_count - 1) << 4 | code_bit_length.
_LITLEN = bytes((
    11, 124, 8, 7, 28, 7, 188, 13, 76, 4, 10, 8, 12, 10, 12, 10, 8, 23, 8,
    9, 7, 6, 7, 8, 7, 6, 55, 8, 23, 24, 12, 11, 7, 9, 11, 12, 6, 7, 22, 5,
    7, 24, 6, 11, 9, 6, 7, 22, 7, 11, 38, 7, 9, 8, 25, 11, 8, 11, 9, 12,
    8, 12, 5, 38, 5, 38, 5, 11, 7, 5, 6, 21, 6, 10, 53, 8, 7, 24, 10, 27,
    44, 253, 253, 253, 252, 252, 252, 13, 12, 45, 12, 45, 12, 61, 12, 45,
    44, 173))
_LENLEN = bytes((2, 35, 36, 53, 38, 23))
_DISTLEN = bytes((2, 20, 53, 230, 247, 151, 248))
_LEN_BASE = (3, 2, 4, 5, 6, 7, 8, 9, 10, 12, 16, 24, 40, 72, 136, 264)
_LEN_EXTRA = (0, 0, 0, 0, 0, 0, 0, 0, 1, 2, 3, 4, 5, 6, 7, 8)
_MAX_CODE_BITS = 15


def _construct(rep: bytes):
    """Expand a compact length list into a canonical Huffman (counts, symbols)."""
    lengths = []
    for byte in rep:
        lengths.extend([byte & 0x0F] * ((byte >> 4) + 1))
    counts = [0] * (_MAX_CODE_BITS + 1)
    for length in lengths:
        counts[length] += 1
    offsets = [0] * (_MAX_CODE_BITS + 2)
    for length in range(1, _MAX_CODE_BITS + 1):
        offsets[length + 1] = offsets[length] + counts[length]
    symbols = [0] * len(lengths)
    cursor = list(offsets)
    for symbol, length in enumerate(lengths):
        if length:
            symbols[cursor[length]] = symbol
            cursor[length] += 1
    return counts, symbols, len(lengths)


_LIT_CODE = _construct(_LITLEN)
_LEN_CODE = _construct(_LENLEN)
_DIST_CODE = _construct(_DISTLEN)


class _BitReader:
    """LSB-first bit reader over a bytes object, as PKWARE's format wants."""

    __slots__ = ("data", "pos", "buf", "cnt")

    def __init__(self, data: bytes):
        self.data = data
        self.pos = 0
        self.buf = 0
        self.cnt = 0

    def bits(self, need: int) -> int:
        while self.cnt < need:
            if self.pos >= len(self.data):
                raise Unsupported("PKWARE explode: input ended mid-stream", 0x08)
            self.buf |= self.data[self.pos] << self.cnt
            self.pos += 1
            self.cnt += 8
        value = self.buf & ((1 << need) - 1)
        self.buf >>= need
        self.cnt -= need
        return value

    def decode(self, code) -> int:
        """Decode one symbol. PKWARE stores its Huffman codes bit-INVERTED, which
        is the only thing separating this from a textbook canonical decoder."""
        counts, symbols, _n = code
        value = first = index = 0
        for length in range(1, _MAX_CODE_BITS + 1):
            value |= self.bits(1) ^ 1
            count = counts[length]
            if value < first + count:
                return symbols[index + (value - first)]
            index += count
            first = (first + count) << 1
            value <<= 1
        raise Unsupported("PKWARE explode: ran out of codes", 0x08)


def explode(data: bytes, expected: int = -1) -> bytes:
    """PKWARE DCL decompression (compression mask 0x08, and the whole payload of
    a block carrying the old MPQ_FILE_IMPLODE flag)."""
    if len(data) < 4:
        raise Unsupported("PKWARE explode: stream too short for a header", 0x08)
    reader = _BitReader(data)
    literal_mode = reader.bits(8)
    if literal_mode > 1:
        raise Corrupt(f"PKWARE explode: bad literal mode {literal_mode}")
    dict_bits = reader.bits(8)
    if not 4 <= dict_bits <= 6:
        raise Corrupt(f"PKWARE explode: bad dictionary size {dict_bits}")
    out = bytearray()
    while True:
        if reader.bits(1):
            symbol = reader.decode(_LEN_CODE)
            length = _LEN_BASE[symbol] + reader.bits(_LEN_EXTRA[symbol])
            if length == 519:
                break                       # end-of-stream code
            shift = 2 if length == 2 else dict_bits
            distance = (reader.decode(_DIST_CODE) << shift) + reader.bits(shift) + 1
            if distance > len(out):
                raise Corrupt("PKWARE explode: distance before start of output")
            start = len(out) - distance
            for i in range(length):         # may overlap; must copy byte by byte
                out.append(out[start + i])
        else:
            out.append(reader.bits(8) if not literal_mode
                       else reader.decode(_LIT_CODE))
        if expected >= 0 and len(out) > expected:
            break
    return bytes(out)


# --------------------------------------------------------------------------
# sparse  (compression mask 0x20)
# --------------------------------------------------------------------------
def sparse_decompress(data: bytes) -> bytes:
    """Blizzard's run-of-zeroes codec: a big-endian output length, then control
    bytes - high bit set means (n & 0x7F) + 1 literal bytes follow, clear means
    (n & 0x7F) + 3 zero bytes."""
    if len(data) < 4:
        raise Corrupt("sparse: stream too short")
    (expected,) = struct.unpack_from(">I", data, 0)
    out = bytearray()
    pos = 4
    while pos < len(data) and len(out) < expected:
        control = data[pos]
        pos += 1
        if control & 0x80:
            n = (control & 0x7F) + 1
            out += data[pos:pos + n]
            pos += n
        else:
            out += b"\0" * ((control & 0x7F) + 3)
    return bytes(out[:expected])


def sparse_compress(data: bytes) -> bytes:
    """Only the self-test needs this - it is how the sparse decoder is proven on
    a stream this module did not also decode."""
    out = bytearray(struct.pack(">I", len(data)))
    pos = 0
    while pos < len(data):
        run = 0
        while run < 0x82 and pos + run < len(data) and data[pos + run] == 0:
            run += 1
        if run >= 3:
            out.append(run - 3)
            pos += run
            continue
        lit = 0
        while lit < 0x80 and pos + lit < len(data):
            if data[pos + lit] == 0:
                zeros = 0
                while zeros < 3 and pos + lit + zeros < len(data) \
                        and data[pos + lit + zeros] == 0:
                    zeros += 1
                if zeros >= 3:
                    break
            lit += 1
        out.append(0x80 | (lit - 1))
        out += data[pos:pos + lit]
        pos += lit
    return bytes(out)


# --------------------------------------------------------------------------
# the compression dispatcher
# --------------------------------------------------------------------------
COMP_HUFFMAN = 0x01
COMP_ZLIB = 0x02
COMP_PKWARE = 0x08
COMP_BZIP2 = 0x10
COMP_SPARSE = 0x20
COMP_ADPCM_MONO = 0x40
COMP_ADPCM_STEREO = 0x80

COMP_NAMES = {
    COMP_HUFFMAN: "huffman", COMP_ZLIB: "zlib", COMP_PKWARE: "pkware",
    COMP_BZIP2: "bzip2", COMP_SPARSE: "sparse",
    COMP_ADPCM_MONO: "adpcm_mono", COMP_ADPCM_STEREO: "adpcm_stereo",
}

# Bit order for a multi-method mask, undoing the compressor's order.
_DISPATCH_ORDER = (COMP_BZIP2, COMP_PKWARE, COMP_ZLIB, COMP_SPARSE,
                   COMP_HUFFMAN, COMP_ADPCM_STEREO, COMP_ADPCM_MONO)

_NOT_IMPLEMENTED = {
    COMP_HUFFMAN: ("Blizzard adaptive huffman - an audio codec. Not implemented "
                   "on purpose: this client contains zero sectors that use it, "
                   "so an implementation could not be checked against a single "
                   "real byte, and audio is outside the committed data set."),
    COMP_ADPCM_MONO: ("IMA ADPCM mono - an audio codec, zero occurrences in this "
                      "client, unverifiable here. See huffman."),
    COMP_ADPCM_STEREO: ("IMA ADPCM stereo - an audio codec, zero occurrences in "
                        "this client, unverifiable here. See huffman."),
}


def decompress(data: bytes, expected: int, seen=None) -> bytes:
    """Decompress one MPQ sector whose first byte is the compression mask.

    `expected` is how long the sector must come out; `seen` is an optional
    collections.Counter the dispatcher records each method it applies into, which
    is how the run reports WHICH compressions the client actually uses instead of
    assuming."""
    if not data:
        return b""
    mask = data[0]
    body = data[1:]
    if mask == 0:
        if seen is not None:
            seen["stored(mask 0x00)"] += 1
        return body
    unknown = mask & ~sum(_DISPATCH_ORDER)
    if unknown:
        raise Unsupported(f"unknown compression bits 0x{unknown:02X} "
                          f"(full mask 0x{mask:02X})", mask)
    for bit in _DISPATCH_ORDER:
        if not mask & bit:
            continue
        if seen is not None:
            seen[COMP_NAMES[bit]] += 1
        if bit in _NOT_IMPLEMENTED:
            raise Unsupported(f"compression 0x{bit:02X} ({COMP_NAMES[bit]}) is "
                              f"not implemented: {_NOT_IMPLEMENTED[bit]}", mask)
        if bit == COMP_BZIP2:
            body = bz2.decompress(body)
        elif bit == COMP_PKWARE:
            body = explode(body, expected)
        elif bit == COMP_ZLIB:
            body = zlib.decompress(body)
        elif bit == COMP_SPARSE:
            body = sparse_decompress(body)
    return body


# --------------------------------------------------------------------------
# the archive
# --------------------------------------------------------------------------
class Member:
    """One read of one member. `status` is the whole result, so a caller never
    has to tell "no bytes" apart from "not read" by inspecting `data`.

        ok        `data` holds exactly `size` bytes
        deleted   a patch tombstone: this path is REMOVED at this layer. Real
                  MPQ semantics, not a failure - it carries no bytes by design.
        empty     a genuine zero-length member
        missing   no hash entry, or the entry does not point at a live block
        error     `detail` says what stopped it
    """

    __slots__ = ("name", "status", "data", "detail", "block", "flags", "size",
                 "stored_size", "offset", "masks")

    def __init__(self, name, status, data=None, detail=None, block=None,
                 flags=0, size=0, stored_size=0, offset=0, masks=None):
        self.name = name
        self.status = status
        self.data = data
        self.detail = detail
        self.block = block
        self.flags = flags
        self.size = size
        self.stored_size = stored_size
        self.offset = offset
        self.masks = masks or []

    @property
    def ok(self) -> bool:
        return self.status == "ok"

    def __repr__(self):
        return (f"<Member {self.name!r} {self.status} size={self.size} "
                f"flags={'|'.join(flag_names(self.flags))}>")


# Every archive this process actually opened, keyed by resolved path, counted
# HERE - at the one line that opens the file - and nowhere else.
#
# It exists because the caller's own version of this check was vacuous: it
# incremented a counter once per element of a list whose keys were already
# proven unique two functions earlier, so it counted LOOP ITERATIONS and could
# never fire. A second open through any other code path was invisible to it. A
# ledger at the constructor cannot be fooled that way: an archive opened twice
# is two increments regardless of who opened it or why, and the key is the
# resolved path so two spellings of one file are one entry.
OPEN_LEDGER = collections.Counter()


def open_ledger_snapshot() -> dict:
    """The ledger as a plain dict, path -> times opened."""
    return dict(OPEN_LEDGER)


class Archive:
    """One MPQ file, read correctly.

    Opens read-only, keeps the file handle, and builds the (hash_a, hash_b)
    index once - `mpyq` linear-scans the whole hash table on every single lookup,
    which is quadratic and is most of why a full client pass took ~25 minutes."""

    HEADER = struct.Struct("<4s2I2H4I")
    HEADER_EXT = struct.Struct("<qhh")

    def __init__(self, path):
        self.path = Path(path)
        self.file = open(self.path, "rb")
        # counted the instant the handle exists, BEFORE the header is parsed: an
        # archive whose bytes are corrupt was still opened, and a caller that
        # retries it has still opened it twice. Counting after a successful
        # parse would hide exactly that.
        OPEN_LEDGER[str(self.path.resolve()).lower()] += 1
        self.header = self._read_header()
        self.base = self.header["offset"]
        self.sector_size = 512 << self.header["sector_size_shift"]
        self.hash_table = self._read_table("hash")
        self.block_table = self._read_table("block")
        self._index = None

    # -- lifecycle ---------------------------------------------------------
    def close(self):
        if self.file and not self.file.closed:
            self.file.close()

    def __enter__(self):
        return self

    def __exit__(self, *exc):
        self.close()

    # -- structure ---------------------------------------------------------
    def _read_header(self) -> dict:
        self.file.seek(0)
        magic = self.file.read(4)
        self.file.seek(0)
        offset = 0
        if magic == b"MPQ\x1b":
            shim = struct.unpack("<4s3I", self.file.read(16))
            offset = shim[2]
            self.file.seek(offset)
            magic = self.file.read(4)
            self.file.seek(offset)
        if magic != b"MPQ\x1a":
            raise Corrupt(f"{self.path.name}: not an MPQ (magic {magic!r})")
        fields = self.HEADER.unpack(self.file.read(self.HEADER.size))
        header = dict(zip(("magic", "header_size", "archive_size",
                           "format_version", "sector_size_shift",
                           "hash_table_offset", "block_table_offset",
                           "hash_table_entries", "block_table_entries"), fields))
        if header["format_version"] >= 1 and header["header_size"] >= 44:
            ext = self.HEADER_EXT.unpack(self.file.read(self.HEADER_EXT.size))
            header["extended_block_table_offset"] = ext[0]
            header["hash_table_offset_high"] = ext[1]
            header["block_table_offset_high"] = ext[2]
        header["offset"] = offset
        return header

    def _read_table(self, kind: str) -> list:
        count = self.header[f"{kind}_table_entries"]
        self.file.seek(self.base + self.header[f"{kind}_table_offset"])
        raw = decrypt_dwords(self.file.read(count * 16),
                             hash_string(f"({kind} table)", HASH_FILE_KEY))
        if len(raw) < count * 16:
            raise Corrupt(f"{self.path.name}: {kind} table truncated "
                          f"({len(raw)} of {count * 16} bytes)")
        fmt = "<2I2HI" if kind == "hash" else "<4I"
        unpack = struct.Struct(fmt).unpack_from
        return [unpack(raw, i * 16) for i in range(count)]

    @property
    def index(self) -> dict:
        """(hash_a, hash_b) -> block index, first live slot wins."""
        if self._index is None:
            built = {}
            for entry in self.hash_table:
                if entry[4] < HASH_DELETED:
                    built.setdefault((entry[0], entry[1]), entry[4])
            self._index = built
        return self._index

    def block_index_of(self, name: str):
        return self.index.get((hash_string(name, HASH_NAME_A),
                               hash_string(name, HASH_NAME_B)))

    def has(self, name: str) -> bool:
        return self.block_index_of(name) is not None

    def list_names(self):
        """The archive's own (listfile), as a list of stored names. Returns None
        when the archive has no readable listfile - which is a fact about the
        archive, never an exception."""
        member = self.read("(listfile)")
        if not member.ok or not member.data:
            return None
        text = member.data.decode("latin-1")
        return [line.strip().replace("/", "\\")
                for line in text.replace("\r\n", "\n").replace("\r", "\n").split("\n")
                if line.strip()]

    # -- reading -----------------------------------------------------------
    def read(self, name: str, seen=None) -> Member:
        block_index = self.block_index_of(name)
        if block_index is None or block_index >= len(self.block_table):
            return Member(name, "missing", detail="no live hash entry")
        return self.read_block(block_index, name, seen=seen)

    def read_block(self, block_index: int, name: str = None, seen=None) -> Member:
        """Read by BLOCK INDEX. Separate from read() because recovery work needs
        to reach block entries whose name is unknown or whose hash slot is gone."""
        offset, stored_size, size, flags = self.block_table[block_index]
        make = lambda status, data=None, detail=None, masks=None: Member(  # noqa: E731
            name, status, data, detail, block_index, flags, size, stored_size,
            offset, masks)

        if not flags & MPQ_FILE_EXISTS:
            return make("missing", detail="block entry has no EXISTS flag")
        if flags & MPQ_FILE_DELETE_MARKER:
            return make("deleted", detail="patch tombstone: this layer DELETES "
                                          "the path; it carries no bytes")
        if stored_size == 0 or size == 0:
            return make("empty", data=b"")

        start = self.base + offset
        if start + stored_size > self.path.stat().st_size:
            return make("error", detail=f"block runs past end of archive "
                                        f"({start}+{stored_size})")
        key = None
        if flags & MPQ_FILE_ENCRYPTED:
            if name is None:
                key = None                  # recovered below from the sector table
            else:
                key = file_key(name, flags, offset, size)

        masks = []
        try:
            if flags & MPQ_FILE_SINGLE_UNIT:
                data = self._read_single_unit(start, stored_size, size, flags,
                                              key, masks, seen)
            else:
                data = self._read_sectors(start, stored_size, size, flags,
                                          key, masks, seen)
        except Unsupported as exc:
            return make("error", detail=f"Unsupported: {exc}", masks=masks)
        except Exception as exc:            # noqa: BLE001 - recorded, never raised
            return make("error", detail=f"{type(exc).__name__}: {exc}", masks=masks)

        if len(data) != size:
            return make("error", masks=masks,
                        detail=f"decoded {len(data)} bytes, block table says {size}")
        return make("ok", data=data, masks=masks)

    def _read_single_unit(self, start, stored_size, size, flags, key, masks, seen):
        self.file.seek(start)
        blob = self.file.read(stored_size)
        if flags & MPQ_FILE_ENCRYPTED:
            if key is None:
                raise Unsupported("encrypted single-unit member with no name to "
                                  "derive a key from and no sector table to "
                                  "recover one")
            blob = decrypt_dwords(blob, key)
        if stored_size < size:
            if flags & MPQ_FILE_COMPRESS:
                masks.append(blob[0])
                return decompress(blob, size, seen)
            if flags & MPQ_FILE_IMPLODE:
                masks.append(COMP_PKWARE)
                if seen is not None:
                    seen["pkware(IMPLODE flag)"] += 1
                return explode(blob, size)
        return blob[:size]

    # Candidate sector sizes, tried in order after the header's own. See
    # _sector_layout: one archive in this client states a sector shift its
    # members do not use, and the sector offset table says so out loud.
    _SECTOR_CANDIDATES = tuple(512 << s for s in range(0, 9))

    def _sector_layouts(self, first_dword, size, flags):
        """Every (sector_size, position_count, sector_count) the member's own
        sector offset table could describe, best guess first.

        The first entry of a sector offset table IS the table's byte length, so
        the member states how many positions it has, and only one sector size can
        make that number of positions describe a file of this length. Two things
        in this client need that:

        * writers disagree about whether a trailing checksum slot is counted, and
          they do NOT reliably set MPQ_FILE_SECTOR_CRC when they add one - three
          members of this client carry the extra slot with the flag clear - so
          both table shapes are tried whatever the flag says;
        * `Data/enUS/backup-enUS.MPQ` declares sector shift 5 (16 KB) in its
          header while many of its members are laid out at 4 KB or 2 KB. Trusting
          the header there produces short, wrong files; trusting each member's
          own table produces files whose length AND MD5 both check out.

        The table length does NOT always pin one answer: a 4,363-byte member of
        this client has a 16-byte table, which is both "2 KB sectors, no checksum
        slot" and "4 KB sectors, one checksum slot". So this returns CANDIDATES
        and the caller decides by decoding - the layout that yields exactly the
        declared number of bytes with every sector decoding is the right one, and
        that is a property of the data rather than of the search order. Choosing
        by order alone silently produced a 4,344-byte file for that member.

        The header's value is tried FIRST, so nothing changes for the 76 archives
        whose header and members agree."""
        out, unique = [], set()
        for sector_size in (self.sector_size,) + self._SECTOR_CANDIDATES:
            n_sectors = (size + sector_size - 1) // sector_size
            for extra in (1 if flags & MPQ_FILE_SECTOR_CRC else 0, 1, 0):
                n_positions = n_sectors + 1 + extra
                if first_dword != 4 * n_positions:
                    continue
                shape = (sector_size, n_positions)
                if shape not in unique:
                    unique.add(shape)
                    out.append((sector_size, n_positions, n_sectors))
        return out

    def _read_sectors(self, start, stored_size, size, flags, key, masks, seen):
        # An UNCOMPRESSED member has no sector offset table at all: its sectors
        # are contiguous. mpyq reads the file's own first bytes as a table here
        # and returns a slice-salad of the wrong length - silently, because it
        # never raises. 1,271 members of this client are in that state.
        if not flags & (MPQ_FILE_COMPRESS | MPQ_FILE_IMPLODE):
            self.file.seek(start)
            blob = self.file.read(min(stored_size, size))
            if flags & MPQ_FILE_ENCRYPTED:
                out = bytearray()
                for i in range(0, len(blob), self.sector_size):
                    out += decrypt_dwords(blob[i:i + self.sector_size],
                                          (key + i // self.sector_size) & 0xFFFFFFFF)
                blob = bytes(out)
            if seen is not None:
                seen["stored(no sector table)"] += 1
            return blob[:size]

        self.file.seek(start)
        head = self.file.read(4)
        if len(head) < 4:
            raise Corrupt("sector offset table truncated")
        (first,) = struct.unpack("<I", head)

        if flags & MPQ_FILE_ENCRYPTED:
            # The table is encrypted, so its first dword cannot be read to learn
            # the layout; fall back to the header's sector size, which is what
            # the key recovery also assumes.
            n_sectors = (size + self.sector_size - 1) // self.sector_size
            n_positions = n_sectors + 1 + (1 if flags & MPQ_FILE_SECTOR_CRC else 0)
            sector_size = self.sector_size
            self.file.seek(start)
            table_raw = self.file.read(4 * n_positions)
            if key is None:
                key = detect_file_key(table_raw, 4 * n_positions)
                if key is None:
                    key = detect_file_key(table_raw, 4 * (n_sectors + 1))
                    if key is not None:
                        n_positions = n_sectors + 1
                        table_raw = table_raw[:4 * n_positions]
                if key is None:
                    raise Unsupported("encrypted member: could not recover the "
                                      "file key from its sector offset table")
            table_raw = decrypt_dwords(table_raw, (key - 1) & 0xFFFFFFFF)
            layouts = [(self.sector_size, n_positions, n_sectors)]
        else:
            layouts = self._sector_layouts(first, size, flags)
            if not layouts:
                raise Corrupt(
                    f"sector offset table starts at {first}, which is not the "
                    f"length of any table that could describe {size} bytes at "
                    f"any power-of-two sector size")
            table_raw = None

        self.file.seek(start)
        blob = self.file.read(stored_size)
        last_error = None
        for sector_size, n_positions, n_sectors in layouts:
            raw = table_raw if table_raw is not None else blob[:4 * n_positions]
            if len(raw) < 4 * n_positions:
                last_error = Corrupt("sector offset table truncated")
                continue
            positions = struct.unpack(f"<{n_positions}I", raw)
            # Trials count into their OWN tallies: a rejected layout must not
            # leave its guesses in the client-wide compression census.
            trial_masks, trial_seen = list(masks), collections.Counter()
            try:
                out = self._decode_sectors(blob, positions, n_sectors, sector_size,
                                           size, stored_size, flags, key,
                                           trial_masks, trial_seen)
            except Exception as exc:         # noqa: BLE001 - try the next layout
                last_error = exc
                continue
            # A layout is only accepted when it reproduces the declared length,
            # which is what makes picking between two candidates a measurement.
            if len(out) != size:
                last_error = Corrupt(
                    f"layout with {sector_size}-byte sectors decoded "
                    f"{len(out)} bytes, block table says {size}")
                continue
            masks[:] = trial_masks
            if seen is not None:
                seen.update(trial_seen)
                if sector_size != self.sector_size:
                    seen[f"sectorSize {sector_size} "
                         f"(header says {self.sector_size})"] += 1
            return bytes(out)
        raise last_error or Corrupt("no usable sector layout")

    def _decode_sectors(self, blob, positions, n_sectors, sector_size, size,
                        stored_size, flags, key, masks, seen):
        out = bytearray()
        for i in range(n_sectors):
            lo, hi = positions[i], positions[i + 1]
            if not 0 <= lo <= hi <= stored_size:
                raise Corrupt(f"sector {i} range {lo}..{hi} outside the "
                              f"{stored_size}-byte block")
            sector = blob[lo:hi]
            if flags & MPQ_FILE_ENCRYPTED:
                sector = decrypt_dwords(sector, (key + i) & 0xFFFFFFFF)
            # THE RULE mpyq GETS WRONG: a sector is compressed iff it is stored
            # shorter than the length THIS sector must expand to.
            want = min(sector_size, size - len(out))
            if len(sector) < want:
                if flags & MPQ_FILE_COMPRESS:
                    masks.append(sector[0] if sector else 0)
                    sector = decompress(sector, want, seen)
                elif flags & MPQ_FILE_IMPLODE:
                    masks.append(COMP_PKWARE)
                    if seen is not None:
                        seen["pkware(IMPLODE flag)"] += 1
                    sector = explode(sector, want)
            elif seen is not None:
                seen["stored(sector not compressed)"] += 1
            out += sector
        return out

    def read_prefix(self, name: str, want: int = 64):
        """The first `want` bytes of a member, decoding only the sectors needed.

        Content sniffing over a whole client must not mean decompressing a whole
        client: a signature lives in the first few bytes, and an MPQ sector is
        independently compressed, so one sector is enough. Returns b"" when the
        member cannot be read - a sniffer wants an answer, not an exception."""
        block_index = self.block_index_of(name)
        if block_index is None or block_index >= len(self.block_table):
            return b""
        offset, stored, size, flags = self.block_table[block_index]
        if (not flags & MPQ_FILE_EXISTS or flags & MPQ_FILE_DELETE_MARKER
                or not stored or not size):
            return b""
        if flags & (MPQ_FILE_ENCRYPTED | MPQ_FILE_SINGLE_UNIT):
            member = self.read_block(block_index, name)   # rare; just read it all
            return (member.data or b"")[:want] if member.ok else b""
        try:
            start = self.base + offset
            if not flags & (MPQ_FILE_COMPRESS | MPQ_FILE_IMPLODE):
                self.file.seek(start)                     # no sector table
                return self.file.read(min(want, size))
            self.file.seek(start)
            head = self.file.read(4)
            if len(head) < 4:
                return b""
            layouts = self._sector_layouts(struct.unpack("<I", head)[0], size, flags)
            if not layouts:
                return b""
            sector_size, n_positions, n_sectors = layouts[0]
            self.file.seek(start)
            positions = struct.unpack(f"<{n_positions}I",
                                      self.file.read(4 * n_positions))
            out = bytearray()
            for i in range(n_sectors):
                if len(out) >= want:
                    break
                lo, hi = positions[i], positions[i + 1]
                if not 0 <= lo <= hi <= stored:
                    return b""
                self.file.seek(start + lo)
                sector = self.file.read(hi - lo)
                expect = min(sector_size, size - len(out))
                if len(sector) < expect and flags & MPQ_FILE_COMPRESS:
                    sector = decompress(sector, expect)
                elif len(sector) < expect and flags & MPQ_FILE_IMPLODE:
                    sector = explode(sector, expect)
                out += sector
            return bytes(out[:want])
        except Exception:                    # noqa: BLE001 - a sniff never raises
            return b""

    # -- (attributes) ------------------------------------------------------
    ATTR_CRC32 = 0x01
    ATTR_FILETIME = 0x02
    ATTR_MD5 = 0x04

    def attributes(self) -> dict:
        """Expand the archive's `(attributes)` member.

        It is an array PARALLEL TO THE BLOCK TABLE holding, per block entry, a
        CRC32, a Windows FILETIME and an MD5 - a complete second integrity record
        for every file in the archive that nothing in this repo had ever read.
        Returns {} when the archive has none."""
        member = self.read("(attributes)")
        if not member.ok or not member.data or len(member.data) < 8:
            return {"present": member.status == "ok",
                    "error": member.detail or "absent or too short"}
        data = member.data
        version, flags = struct.unpack_from("<2I", data, 0)
        per = ((4 if flags & self.ATTR_CRC32 else 0)
               + (8 if flags & self.ATTR_FILETIME else 0)
               + (16 if flags & self.ATTR_MD5 else 0))
        if not per:
            return {"present": True, "version": version, "flags": flags,
                    "entries": 0, "error": "no attribute kinds set"}
        count = (len(data) - 8) // per
        pos = 8
        crcs = times = None
        md5s = None
        if flags & self.ATTR_CRC32:
            crcs = struct.unpack_from(f"<{count}I", data, pos)
            pos += 4 * count
        if flags & self.ATTR_FILETIME:
            times = struct.unpack_from(f"<{count}Q", data, pos)
            pos += 8 * count
        if flags & self.ATTR_MD5:
            md5s = [data[pos + i * 16: pos + 16 + i * 16] for i in range(count)]
        return {"present": True, "version": version, "flags": flags,
                "bytes": len(data), "entries": count,
                "matchesBlockTable": count == len(self.block_table),
                "crc32": crcs, "filetime": times, "md5": md5s}


# Windows FILETIME -> ISO 8601. 100-ns ticks since 1601-01-01.
_FILETIME_EPOCH_DELTA = 11644473600


def filetime_to_iso(ticks: int):
    if not ticks:
        return None
    seconds = ticks // 10_000_000 - _FILETIME_EPOCH_DELTA
    if not -12219292800 < seconds < 4102444800:
        return None                          # outside 1601..2100: not a real time
    import datetime
    return datetime.datetime.fromtimestamp(
        seconds, datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


# --------------------------------------------------------------------------
# self-test
# --------------------------------------------------------------------------
def selftest() -> int:
    failures = []

    def check(name, condition, detail=""):
        print(f"  {'PASS' if condition else 'FAIL'}  {name}"
              + (f"   {detail}" if detail and not condition else ""))
        if not condition:
            failures.append(name)

    print("crypt primitives")
    # Known MPQ constants: the table/hash keys every archive in the world uses.
    check("hash('(hash table)', FILE_KEY) == 0xC3AF3770",
          hash_string("(hash table)", HASH_FILE_KEY) == 0xC3AF3770,
          hex(hash_string("(hash table)", HASH_FILE_KEY)))
    check("hash('(block table)', FILE_KEY) == 0xEC83B3A3",
          hash_string("(block table)", HASH_FILE_KEY) == 0xEC83B3A3,
          hex(hash_string("(block table)", HASH_FILE_KEY)))
    check("hash is case-insensitive and separator-insensitive",
          hash_string("Foo/Bar.DBC", HASH_NAME_A)
          == hash_string("foo\\bar.dbc", HASH_NAME_A))
    payload = bytes(range(256)) * 3
    for key in (0x12345678, 0xC3AF3770, 1):
        check(f"encrypt/decrypt round trip key=0x{key:08X}",
              decrypt_dwords(encrypt_dwords(payload, key), key) == payload)
    tail = payload + b"\xAA\xBB\xCC"
    check("decrypt leaves the sub-dword tail verbatim",
          decrypt_dwords(encrypt_dwords(tail, 7), 7) == tail)

    print("keyless key recovery (detect_file_key)")
    for name in ("(listfile)", "war3map.j", "Spell.dbc", "Interface\\Foo\\bar.blp"):
        key = file_key(name)
        table = struct.pack("<3I", 12, 0x40, 0x120)
        found = detect_file_key(encrypt_dwords(table, (key - 1) & 0xFFFFFFFF), 12)
        check(f"recovered the key of {name} from its sector table alone",
              found == key, f"got {found}, wanted {key}")
    check("detect_file_key returns None on a table it cannot fit",
          detect_file_key(b"\x00" * 8, 0xDEADBEEF) is None)

    print("PKWARE explode")
    check("literal code set expands to 256 symbols", _LIT_CODE[2] == 256,
          str(_LIT_CODE[2]))
    check("length code set expands to 16 symbols", _LEN_CODE[2] == 16,
          str(_LEN_CODE[2]))
    check("distance code set expands to 64 symbols", _DIST_CODE[2] == 64,
          str(_DIST_CODE[2]))
    # Hand-built DCL streams. There is no PKWARE compressor here to round-trip
    # against, so the streams are written bit by bit against the format and the
    # expected output is worked out by hand - which is the only way this proves
    # the DECODER rather than proving an encoder and a decoder agree with each
    # other. Between them they exercise: raw literals, Huffman-coded literals,
    # three different length codes including one with extra bits, the distance
    # decoder, an OVERLAPPING copy (length longer than the distance), and the
    # 519 end-of-stream code.
    class _W:
        def __init__(self):
            self.bits = []

        def put(self, value, n):
            for i in range(n):
                self.bits.append((value >> i) & 1)

        def put_code(self, code, symbol):
            counts, symbols, _n = code
            first = index = 0
            for length in range(1, _MAX_CODE_BITS + 1):
                count = counts[length]
                if symbol in symbols[index:index + count]:
                    value = first + symbols[index:index + count].index(symbol)
                    for i in range(length - 1, -1, -1):
                        self.bits.append(((value >> i) & 1) ^ 1)
                    return
                index += count
                first = (first + count) << 1
            raise AssertionError("symbol not in code set")

        def done(self):
            while len(self.bits) % 8:
                self.bits.append(0)
            return bytes(sum(b << i for i, b in enumerate(self.bits[j:j + 8]))
                         for j in range(0, len(self.bits), 8))

    def _end(writer):
        # symbol 15 is base 264 with 8 extra bits; 264 + 255 == 519 == end code
        writer.put(1, 1); writer.put_code(_LEN_CODE, 15); writer.put(255, 8)
        return writer.done()

    def _literal(writer, mode, ch):
        writer.put(0, 1)
        if mode:
            writer.put_code(_LIT_CODE, ord(ch))
        else:
            writer.put(ord(ch), 8)

    def _match(writer, length_symbol, extra, distance, dict_bits):
        writer.put(1, 1)
        writer.put_code(_LEN_CODE, length_symbol)
        if _LEN_EXTRA[length_symbol]:
            writer.put(extra, _LEN_EXTRA[length_symbol])
        length = _LEN_BASE[length_symbol] + extra
        shift = 2 if length == 2 else dict_bits
        writer.put_code(_DIST_CODE, (distance - 1) >> shift)
        writer.put((distance - 1) & ((1 << shift) - 1), shift)

    def _head(mode, dict_bits):
        writer = _W()
        writer.put(mode, 8)
        writer.put(dict_bits, 8)
        return writer

    # binary literals, 1024-byte dictionary
    w = _head(0, 4)
    for ch in "abc":
        _literal(w, 0, ch)
    _match(w, 0, 0, 3, 4)        # length 3, distance 3  -> "abc" again
    _match(w, 6, 0, 6, 4)        # length 8, distance 6  -> OVERLAPPING copy
    got = explode(_end(w))
    check("explodes literals + a plain copy + an overlapping copy",
          got == b"abcabcabcabcab", repr(got))

    # ASCII mode: literals come out of the 256-symbol Huffman table instead
    w = _head(1, 6)
    for ch in "Hello, world! ":
        _literal(w, 1, ch)
    _match(w, 8, 1, 14, 6)       # symbol 8 is base 10 + 1 extra bit -> length 11
    got = explode(_end(w))
    check("explodes Huffman-coded literals and an extra-bits length code",
          got == b"Hello, world! Hello, worl", repr(got))

    w = _head(0, 4)
    _match(w, 0, 0, 8, 4)        # a copy from before the start of the output
    check("explode refuses a back-reference that points before the output",
          _raises(lambda: explode(_end(w)), Corrupt))
    check("explode rejects a bad literal mode",
          _raises(lambda: explode(b"\x05\x04\x00\x00"), Corrupt))
    check("explode rejects a bad dictionary size",
          _raises(lambda: explode(b"\x00\x09\x00\x00"), Corrupt))

    print("sparse")
    for sample in (b"", b"\0" * 4096, b"x" * 300,
                   b"abc" + b"\0" * 700 + b"def" + b"\0" * 3 + b"g",
                   bytes(range(256)) * 7):
        check(f"sparse round trip ({len(sample)} bytes)",
              sparse_decompress(sparse_compress(sample)) == sample)

    print("dispatcher")
    body = b"hello world" * 40
    check("mask 0x02 -> zlib", decompress(b"\x02" + zlib.compress(body),
                                          len(body)) == body)
    check("mask 0x10 -> bzip2", decompress(b"\x10" + bz2.compress(body),
                                           len(body)) == body)
    check("mask 0x20 -> sparse",
          decompress(b"\x20" + sparse_compress(body), len(body)) == body)
    check("mask 0x00 -> stored", decompress(b"\x00" + body, len(body)) == body)
    check("mask 0x22 -> sparse then zlib",
          decompress(b"\x22" + zlib.compress(sparse_compress(body)),
                     len(body)) == body)
    for mask in (COMP_HUFFMAN, COMP_ADPCM_MONO, COMP_ADPCM_STEREO):
        check(f"mask 0x{mask:02X} raises Unsupported naming the method",
              _raises(lambda m=mask: decompress(bytes([m]) + b"junk", 10),
                      Unsupported))
    check("an unknown compression bit raises rather than being ignored",
          _raises(lambda: decompress(b"\x04junk", 10), Unsupported))

    print(f"\n{'ALL PASS' if not failures else str(len(failures)) + ' FAILURES: '
                                                + ', '.join(failures)}")
    return 1 if failures else 0


def _raises(fn, kind) -> bool:
    try:
        fn()
    except kind:
        return True
    except Exception:                        # noqa: BLE001
        return False
    return False


def main(argv=None) -> int:
    ap = argparse.ArgumentParser(prog="python -m tools.mpq",
                                 description=__doc__.split("\n")[0])
    ap.add_argument("--selftest", action="store_true",
                    help="run the decompressor and crypt self-test")
    ap.add_argument("archive", nargs="?", help="an .MPQ to describe")
    args = ap.parse_args(argv)
    if args.selftest or not args.archive:
        return selftest()
    with Archive(args.archive) as archive:
        print(f"{archive.path}")
        for k, v in sorted(archive.header.items()):
            print(f"  {k:28} {v!r}")
        names = archive.list_names()
        print(f"  listfile names               "
              f"{'none' if names is None else len(names)}")
        attrs = archive.attributes()
        print(f"  attributes                   {attrs.get('entries', 0)} entries "
              f"of {len(archive.block_table)} block entries")
    return 0


if __name__ == "__main__":
    sys.exit(main())
