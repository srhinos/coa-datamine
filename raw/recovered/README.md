# Recovered / archive forensics (generated)

Regenerate: `python datamine.py`.

- `attributes/` - the CRC32 + MD5 + mtime each archive records per member. The
  oracle everything else is checked against.
- `deleted/` - **4,911** patch tombstones: paths a patch layer REMOVES.
- `empty/` - **13** genuinely zero-length members.
- `containers/` - **9** members whose bytes are themselves an archive.
- `_verify.json` - **763,928** members verified against their archive's own MD5,
  **0** mismatched.

## The tombstone rule

An MPQ DELETE_MARKER entry is a patch REMOVING a path at its layer. It carries no bytes by design, so it is archive semantics rather than a failed read, and it is enumerated here rather than counted as damage.

## The MD5 rule

Every member read by the traversal is checked against the MD5 the archive itself records for it in its `(attributes)` block - an oracle outside this code and outside the reader. `noRecord` counts members whose archive keeps no MD5 for them, which is a property of that archive, not a failure.
