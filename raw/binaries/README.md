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
```

## The rules, stated

* **Which files.** Every file in the client root whose bytes parse as a PE image, found by reading the bytes - no name list and no extension test decides it. The whole client tree is swept for further .exe/.dll/.ocx/.sys files and the result is recorded in `outsideRoot`, so 'these are all of them' is a measurement rather than an assumption.
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
