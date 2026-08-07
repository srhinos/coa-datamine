# raw/recovered - what was still opaque (generated)

Written by `python -m tools.crack`. Nothing here is hand-selected; every
count below is measured by that script on each run.

| layer | what it holds |
| --- | --- |
| `_forensics.json` | every archive's block/hash census, its data region accounted for byte by byte, orphan block entries, and every encrypted member read |
| `attributes/` | CRC32, modification time and MD5 per path, expanded from the `(attributes)` member all 77 archives carry |
| `deleted/` | every MPQ DELETE_MARKER tombstone in the client, with the archive that deletes the path - read from the block tables, so a tombstone a higher archive shadows is still here |
| `empty/` | every block entry an archive records as zero bytes without deleting the path: a member that exists and holds nothing |
| `files/` | the bytes of files the previous reader could not read |
| `containers/` | nested archives and structured blobs, expanded |

## What was found

- **Deleted entries hold nothing.** 0 bytes of the client are unaccounted for by a live block entry and 0 block entries are unreferenced. The archives were compacted, so a delete-marked hash slot has no surviving data behind it. This is measured, not assumed.
- **The 6.4% unreadable figure was a reader defect, not a compression gap.** 0 of those files read correctly now, 4,906 were patch tombstones that never had bytes, 0 are members the archive records as zero bytes, and 0 remain unreadable.
- **The client holds more of both than the census can see.** 4,911 DELETE_MARKER tombstones and 13 zero-length members exist across the archives; the census only ever sees the winning copy of a path, so these layers are built from the block tables instead.
- **`(attributes)` is a whole metadata layer.** 764,003 records, 529,029 of them carrying a modification time.
- **1 encrypted member(s)** exist in the client; 1 decrypted.
- **5 nested containers** expanded, holding 21 members.

## Regenerating

```
python -m tools.crack                  # all stages, resumable
python -m tools.crack --only resweep   # one stage
python -m tools.mpq --selftest         # the reader's own tests
```
