"""Reader for the client's undocumented `Data\\Content\\Localization\\**\\*.loc` files.

WHAT THESE ARE
--------------
Ascension ships its own localization store outside the MPQ chain, as a loose tree
under `Data\\Content\\Localization\\<Entity>\\<Field>\\<locale>.loc` - e.g.
`Spell\\Name\\deDE.loc`, `Item\\Description\\zhCN.loc`. The format is not
documented anywhere. Nothing in this module was told what the layout is; the
layout below is what the bytes measurably are, and `read()` refuses to return a
result it could not prove.

THE FORMAT, AND HOW IT WAS ESTABLISHED
--------------------------------------
    uint32  recordCount
    recordCount x:
        uint32  id
        uint32  byteLength
        byteLength bytes, UTF-8

Established mechanically, not guessed:

* The first record of `Spell\\Name\\deDE.loc` is id=5 / len=12 /
  "Verstuemmeln" and the next are id=7 "Selbstmord", id=10 "Blizzard",
  id=15 "Heiliges Feuer", id=17 "Machtwort: Schild" - the German names of
  spell ids 5, 7, 10, 15 and 17. The id field is therefore the entity id of the
  directory it sits in, not a row ordinal (the ids are sparse and ascending).
* `Item\\Name\\deDE.loc` opens with id=17 "Martinsfuror" - item 17 is Martin's
  Fury. Same shape, different entity space.
* The decisive check is not the sample, it is CLOSURE: reading exactly
  `recordCount` records must land EXACTLY on EOF, every length must fit inside
  the file, and every string must decode as STRICT UTF-8. A wrong field order or
  a wrong header size fails that on the first file. All 64 .loc files in the
  client pass it with zero bytes left over.

WHAT THIS MODULE WILL NOT DO
----------------------------
It will not fall back to a partial read. `read()` either returns a decode whose
consumed length equals the file length, or raises `LocError` carrying the
measurement that failed (offset reached, bytes expected, records recovered) so
the caller can record the failure as evidence instead of shipping a half-parse.
"""
import struct

_HDR = struct.Struct("<I")
_REC = struct.Struct("<II")

# Format constants, stated once so the docs and the code cannot drift apart.
FORMAT = ("uint32 recordCount, then recordCount x (uint32 id, uint32 byteLength, "
          "byteLength bytes of UTF-8). No trailing bytes.")
VALIDATION = ("A decode is accepted only if it consumes the file EXACTLY: the "
              "declared record count is read in full, no length runs past EOF, "
              "every string decodes as strict UTF-8, and the final offset equals "
              "the file size. Any shortfall or overrun is a LocError carrying the "
              "offset reached and the record index that failed - never a partial "
              "result.")


class LocError(RuntimeError):
    """A .loc file that did not decode to exact closure. Carries `.evidence`."""

    def __init__(self, message: str, evidence: dict):
        super().__init__(message)
        self.evidence = evidence


def read(data: bytes) -> list:
    """Decode one .loc payload to [(id, text), ...] in file order.

    Raises LocError with measured evidence if the file does not close exactly."""
    n = len(data)
    if n < _HDR.size:
        raise LocError("file shorter than the 4-byte header",
                       {"size": n, "recordsRecovered": 0, "offsetReached": 0})
    count = _HDR.unpack_from(data, 0)[0]
    out = []
    off = _HDR.size
    for i in range(count):
        if off + _REC.size > n:
            raise LocError(f"record {i} header runs past EOF",
                           {"size": n, "declaredCount": count, "recordsRecovered": i,
                            "offsetReached": off})
        rid, length = _REC.unpack_from(data, off)
        off += _REC.size
        if off + length > n:
            raise LocError(f"record {i} (id {rid}) string of {length} bytes runs past EOF",
                           {"size": n, "declaredCount": count, "recordsRecovered": i,
                            "offsetReached": off, "declaredLength": length})
        try:
            text = data[off:off + length].decode("utf-8")
        except UnicodeDecodeError as e:
            raise LocError(f"record {i} (id {rid}) is not strict UTF-8: {e}",
                           {"size": n, "declaredCount": count, "recordsRecovered": i,
                            "offsetReached": off, "declaredLength": length}) from None
        off += length
        out.append((rid, text))
    if off != n:
        raise LocError(f"decode consumed {off} of {n} bytes ({n - off:+d} left over)",
                       {"size": n, "declaredCount": count,
                        "recordsRecovered": len(out), "offsetReached": off})
    return out


def read_file(path) -> list:
    with open(path, "rb") as f:
        return read(f.read())
