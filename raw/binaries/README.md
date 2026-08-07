# raw/binaries - the client's own executables (generated)

Written by `python -m tools.extract_binaries` from the PE images in
`E:\ascension-live`. Every other layer in this repo reads data the client
ships; this one reads the client.

| binary | bytes | machine | strings | lua chunks | lua fragments | imports | exports | resources |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `Ascension.exe` | 7,694,848 | IMAGE_FILE_MACHINE_I386 | 36,931 | 2 | 39 | 470 | 1 | 27 |
| `discord_game_sdk.dll` | 3,154,744 | IMAGE_FILE_MACHINE_I386 | 14,493 | 0 | 0 | 120 | 3 | 0 |
| `DivxDecoder.dll` | 413,696 | IMAGE_FILE_MACHINE_I386 | 1,849 | 0 | 0 | 60 | 4 | 0 |
| `DivxTac.dll` | 98,816 | IMAGE_FILE_MACHINE_I386 | 1,118 | 0 | 0 | 82 | 0 | 1 |
| `Extensions.dll` | 12,659,256 | IMAGE_FILE_MACHINE_I386 | 131,428 | 1 | 1 | 384 | 1 | 1 |
| `MMgr64.exe` | 364,032 | IMAGE_FILE_MACHINE_AMD64 | 2,168 | 0 | 0 | 182 | 0 | 1 |
| `WowError.exe` | 205,824 | IMAGE_FILE_MACHINE_I386 | 1,861 | 0 | 0 | 152 | 0 | 11 |

## The executables stored INSIDE the archives

The client ships more PE images than the ones loose in its root: these are
members of the MPQ archives, found by reading the bytes of every member the
archives name and extracted through the same pass as the ones above. They live
under `_archived/<archive>/<name>/`.

| binary | archive | bytes | machine | strings | lua chunks | lua fragments | resources |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `BackgroundDownloader.exe` | `Data/enUS/backup-enUS.MPQ` | 2,639,424 | IMAGE_FILE_MACHINE_I386 | 27,043 | 0 | 0 | 41 |
| `BackgroundDownloader.exe` | `Data/enUS/base-enUS.MPQ` | 1,077,904 | IMAGE_FILE_MACHINE_I386 | 11,111 | 0 | 0 | 31 |
| `Battle.net.dll` | `Data/enUS/backup-enUS.MPQ` | 15,588,224 | IMAGE_FILE_MACHINE_I386 | 124,947 | 0 | 0 | 3 |
| `Battle.net.dll` | `Data/enUS/base-enUS.MPQ` | 225,936 | IMAGE_FILE_MACHINE_I386 | 1,400 | 0 | 0 | 2 |
| `dbghelp.dll` | `Data/enUS/base-enUS.MPQ` (+1) | 1,039,728 | IMAGE_FILE_MACHINE_I386 | 4,930 | 0 | 0 | 1 |
| `ijl15.dll` | `Data/enUS/base-enUS.MPQ` (+1) | 372,736 | IMAGE_FILE_MACHINE_I386 | 1,441 | 0 | 0 | 1 |
| `Launcher.exe` | `Data/enUS/backup-enUS.MPQ` | 4,895,616 | IMAGE_FILE_MACHINE_I386 | 61,589 | 0 | 0 | 76 |
| `Launcher.exe` | `Data/enUS/base-enUS.MPQ` | 2,421,392 | IMAGE_FILE_MACHINE_I386 | 36,433 | 0 | 0 | 199 |
| `msvcr71.dll` | `Data/enUS/base-enUS.MPQ` (+1) | 348,160 | IMAGE_FILE_MACHINE_I386 | 3,666 | 0 | 0 | 1 |
| `msvcr80.dll` | `Data/enUS/backup-enUS.MPQ` | 632,656 | IMAGE_FILE_MACHINE_I386 | 5,223 | 0 | 0 | 1 |
| `msvcr80.dll` | `Data/enUS/base-enUS.MPQ` | 626,688 | IMAGE_FILE_MACHINE_I386 | 5,138 | 0 | 0 | 1 |
| `Repair.exe` | `Data/enUS/backup-enUS.MPQ` | 975,512 | IMAGE_FILE_MACHINE_I386 | 9,143 | 0 | 0 | 22 |
| `Repair.exe` | `Data/enUS/base-enUS.MPQ` | 889,488 | IMAGE_FILE_MACHINE_I386 | 8,502 | 0 | 0 | 22 |
| `Scan.dll` | `Data/enUS/base-enUS.MPQ` (+1) | 42,244 | IMAGE_FILE_MACHINE_I386 | 771 | 0 | 0 | 2 |
| `unicows.dll` | `Data/enUS/base-enUS.MPQ` (+1) | 245,408 | IMAGE_FILE_MACHINE_I386 | 2,404 | 0 | 0 | 1 |
| `Uninstall.exe` | `Data/enUS/base-enUS.MPQ` (+1) | 397,312 | IMAGE_FILE_MACHINE_I386 | 3,179 | 0 | 0 | 8 |
| `Wow.exe` | `Data/enUS/backup-enUS.MPQ` | 7,704,216 | IMAGE_FILE_MACHINE_I386 | 36,982 | 2 | 39 | 29 |
| `Wow.exe` | `Data/enUS/base-enUS.MPQ` | 9,506,960 | IMAGE_FILE_MACHINE_I386 | 29,162 | 2 | 35 | 16 |
| `WowError.exe` | `Data/enUS/backup-enUS.MPQ` | 350,360 | IMAGE_FILE_MACHINE_I386 | 2,260 | 0 | 0 | 10 |
| `WowError.exe` | `Data/enUS/base-enUS.MPQ` | 220,816 | IMAGE_FILE_MACHINE_I386 | 1,689 | 0 | 0 | 10 |

`(+n)` marks a version that n further archive(s) carry byte for byte; they are
listed in that binary's `origin.alsoIn`. A version identical to a client-root
binary is not extracted twice - it is recorded on that binary as
`alsoInArchives`.

## What is under each binary

```
<name>/index.json          counts and the PE headline for this image
<name>/pe.json             sections, imports, exports, resources, debug,
                           certificates, the Rich header, the overlay
<name>/strings/            every printable run, sharded JSONL, with offsets
<name>/lua/                one record per chunk and per single-line fragment
<name>/lua/chunks/         recovered Lua, verbatim (.lua source, .luac compiled)
<name>/resources/          resource payloads, decoded where they are structures
<name>/symbols/            imports/exports/sections/resources/debug as records

_archived/<archive>/<name>/   the same tree, for a PE stored in an archive
```

## The rules, stated

* **Which files.** Every PE image in the client, wherever it sits: the ones loose in the client root AND the ones stored inside the MPQ archives. Both are found by reading bytes - no name list and no extension test decides it - and the archive sweep reads the first sector of every one of the client's ~769,000 members and keeps the ones that parse as a PE (see ARCHIVE_SCAN_RULE). The whole client tree is also swept for further .exe/.dll/.ocx/.sys files outside the root and the result is recorded in `outsideRoot`, so 'these are all of them' is a measurement rather than an assumption.
* **Archive sweep.** Every member named by every archive's listfile has its FIRST SECTOR decoded and is kept if those bytes parse as a PE image; a member starting `MZ` whose PE header lies past the first sector is re-read in full rather than judged on the short read. The sweep costs one sector per member, and it is checkpointed per archive under work/binaries/archive_scan/ keyed by the archive's own sha256 AND this rule, so changing what counts as a hit invalidates the cache instead of being masked by it.

Driving this off the listfiles is complete rather than convenient, and that is a MEASUREMENT, not an assumption: the client's 77 archives hold 768,998 block entries, 4,911 of them DELETE_MARKER tombstones that carry no bytes, and every one of the 764,087 remaining live entries resolves to a name - 0 live members are unnamed. Seven archives ship no readable listfile (patch-4, -5, -C, -CZZ, -W, -WB, -WC), and they are stubs: two block entries each, which are their own `(listfile)` and `(attributes)` members and nothing else, so there is no unnamed payload hiding behind them. tools/crack.py's forensics stage records the same decomposition from the other direction (orphanBlockEntriesTotal 0, unaccountedBytesTotal 0).
* **One extraction per version.** One extraction per DISTINCT sha256, not one per carrying archive - the same rule tools/variants.py applies to tables. Byte-identical copies are ONE version, extracted under the HIGHEST-ranked archive that carries those bytes with the others listed in `alsoIn`. A version whose bytes are already extracted as a loose client-root binary is not extracted twice either; it is recorded against that binary in `alsoInArchives`. Chain rank is position in tools/inventory.discover_archives(), the same loader order every other layer here uses.
* **Strings.** Every printable run of at least 4 characters in the whole file - headers, sections, gaps and overlay alike - in three encodings: ASCII (bytes 0x20-0x7E), UTF-16LE (printable-ASCII code units) and UTF-8 (kept only when the run contains a multi-byte character, so it never duplicates the ASCII pass). Runs are deduplicated by (encoding, text) and every offset each occurs at is kept, with the PE section that offset lands in or '(unmapped)' when no section covers it. Note what the UTF-8 pass is: machine code contains byte pairs that are well-formed UTF-8 by chance, so most `utf8` runs are not text - they are kept because dropping them would mean dropping every genuinely non-ASCII string with them, and `enc` separates them from the ASCII and UTF-16 passes for anyone who wants only text.
* **Lua.** A run's Lua score is the number of DISTINCT syntax classes in tools/lua51.py TOKEN_CLASSES that match it - keywords, method-call and concatenation syntax, comment openers, table constructors and standard library calls. Counting distinct classes rather than occurrences stops one repeated word from carrying English prose over a threshold. The score is recorded on every extracted string, so any reader can re-cut it. A run is written out as a source chunk when it
  spans at least two lines and scores at least 3; single-line
  fragments are listed at 3. Precompiled chunks are found
  by their `\x1bLua` magic and then walked to their last byte, so a magic hit
  that is not a chunk is recorded as a rejection with its reason instead of
  being reported as recovered script.
* **Resources.** Every resource leaf is read. Its bytes are committed when the payload measures as text, when it decodes to a structure (RT_VERSION, RT_STRING), or when it is at most 65536 bytes; larger binary payloads are recorded with size and sha256 and their bytes discarded, which is this repo's art-and-sound rule applied by measurement. Nothing is skipped because of its type.
* **No interpretation.** Nothing here says what a string means.

## Searching it

```
python -m tools.find "listarchive" --layer binaries
python -m tools.find "SetDataPath"
```

## Half-written layers cannot happen silently

A raw layer is trustworthy only while it carries `_complete.json`. Every extractor removes that file BEFORE it deletes anything and writes it back LAST, after all of its output, so a layer left half-written by a crash is detectable rather than silently readable. Readers and tests refuse a layer that has no sentinel. The sentinel holds no timestamp, so it does not affect byte-for-byte reproduction.
