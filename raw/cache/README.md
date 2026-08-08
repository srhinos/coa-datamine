# Client query caches (generated)

Regenerate: `python datamine.py`. Extracted from the snapshot of `Cache\WDB`.

This is the ONE layer whose source is not static client files, so it is also the
one that reproduces byte for byte only against the same `Cache\WDB` tree:
playing the game appends to that cache. Everywhere else "unchanged client" means
"unchanged archives"; here it means "unchanged cache too".

## Totals

- **22 files**, 19.3 MB
- **47,438 records** decoded
- tiers: {"schema": 18, "blocks": 0, "flat": 2, "raw": 2}

## How a field layout earns the right to be used

A field LAYOUT is applied to a WDB file only if it consumes every block of that file exactly: each block declares its own byte length in its header, and the decode must land on that length for all blocks, with no block skipped. One mismatch anywhere disqualifies the layout for the whole file (never per-block), and the file falls back to a lossless base64 block dump with the mismatch recorded. WHAT THIS DOES NOT CATCH, stated so it is not over-trusted: (1) reading a uint32 as a float32 consumes the same bytes and passes; (2) PERMUTING any two same-kind same-width fields consumes the same bytes and passes. Both were measured - removing a field, or moving a string by one position, fail on the first block; a width-preserving swap does not. Because (2) is unfalsifiable from the bytes alone, THIS LAYER SHIPS NO FIELD NAMES: every decoded record is positional (f0..fN), exactly like raw/tables. The TrinityCore-derived names are published separately in raw/cache/_interpretation.json, labelled as the unverified interpretation they are. A reader can therefore never mistake a name for a measurement.

## The field names, and why they are not in the data

The field names below are an INTERPRETATION, not a measurement. They were read off TrinityCore 3.3.5's query-response handlers by a human and mapped onto the positions this layer measured. The measurement is the layout - field count, widths, kinds, and the variable-length runs - which is proven by exact block consumption. The names are not proven by anything: any two same-kind same-width fields can be swapped without changing a single byte of consumption, so `f21` being called `flags` is a claim about what the server meant, verifiable only against an external source. Use the positions for data and treat every name here as a hypothesis to check.
