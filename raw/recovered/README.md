# raw/recovered - what was still opaque (generated)

Written by `python -m tools.crack`. Nothing here is hand-selected; every
count below is measured by that script on each run.

| layer | what it holds |
| --- | --- |
| `_forensics.json` | every archive's block/hash census, its data region accounted for byte by byte, orphan block entries, and every encrypted member read |
| `attributes/` | CRC32, modification time and MD5 per path, expanded from the `(attributes)` member all 77 archives carry |
| `deleted/` | every MPQ DELETE_MARKER tombstone, with the archive that deletes the path |
| `files/` | the bytes of files the previous reader could not read |
| `containers/` | nested archives and structured blobs, expanded |

## What was found

- **Deleted entries hold nothing.** 0 bytes of the client are unaccounted for by a live block entry and 0 block entries are unreferenced. The archives were compacted, so a delete-marked hash slot has no surviving data behind it. This is measured, not assumed.
- **The 6.4% unreadable figure was a reader defect, not a compression gap.** 36,139 of those files read correctly now, 4,906 were patch tombstones that never had bytes, and 0 remain unreadable.
- **`(attributes)` is a whole metadata layer.** 764,003 records, 529,029 of them carrying a modification time.
- **1 encrypted member(s)** exist in the client; 1 decrypted.
- **5 nested containers** expanded, holding 21 members.

## Regenerating

```
python -m tools.crack                  # all stages, resumable
python -m tools.crack --only resweep   # one stage
python -m tools.mpq --selftest         # the reader's own tests
```
