# Complete Interface census (generated)

Regenerate: `python datamine.py`.

## Totals

- **93,437 Interface paths** (4.449 GB uncompressed in the client)
- **1,461 measured text**, 91,954 measured binary, 22 unreadable
- bytes committed: 1,449 in `raw/interface/`, 12 added here

## What decides text vs binary

A file is text if its decompressed bytes contain no NUL and fewer than one C0 control byte per 512 bytes outside tab/newline/CR/FF/VT; an empty file is text. Its encoding is recorded as utf-8 when it decodes strictly as UTF-8 and latin-1 otherwise. The rule reads the bytes - no extension list, no filename pattern, and no judgment about which files matter decides it.

## Why binary bytes are not committed

Bytes are committed for every file measured as text. For binary files the record carries path, uncompressed size and sha256 and the bytes stay in the client. This is a repository-size decision, not a curation decision: the Interface tree is 4.45 GB and is 99% art. Every binary file's sha256 is here, so the exact bytes this census saw can be pulled from the client and verified at any time.
