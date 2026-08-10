# Client binaries (generated)

Regenerate: `python datamine.py`.

- **7** PE images loose in the client root
- **20** PE images stored inside the MPQ archives (`_archived/`)
- **566,861** printable strings extracted

## How strings are selected

Every printable run of at least 4 characters in the whole file - headers, sections, gaps and overlay alike - in three encodings: ASCII (bytes 0x20-0x7E), UTF-16LE (printable-ASCII code units) and UTF-8 (kept only when the run contains a multi-byte character, so it never duplicates the ASCII pass). Runs are deduplicated by (encoding, text) and every offset each occurs at is kept, with the PE section that offset lands in or '(unmapped)' when no section covers it. Note what the UTF-8 pass is: machine code contains byte pairs that are well-formed UTF-8 by chance, so most `utf8` runs are not text - they are kept because dropping them would mean dropping every genuinely non-ASCII string with them, and `enc` separates them from the ASCII and UTF-16 passes for anyone who wants only text.
