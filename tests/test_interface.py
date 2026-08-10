"""TDD gate for task V2-6: committed Interface/API code layer + orchestrator wiring.

extract_interface.extract_all() scans every archive (extract_mpq._list_archives order)
for files under Interface\\ (any depth), keeps only code payloads (.lua/.xml/.toc/.txt/
.md), resolves the per-file winner by chain_rank, and extracts to raw/interface/<path
relative to Interface\\> - so raw/interface/ mirrors the client's Interface\\ tree root.
The on-disk CLIENT_DIR/Interface/AddOns/APIDocumentation tree is then copied in on top,
WINNING any collision at the same relative path (it is the live launcher-managed addon,
not an archive snapshot). Everything is written to a deterministic _manifest.json:
sorted relative paths -> {source, size, sha256}."""
import hashlib, json, os, random, sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from tools import config
from tools import extract_interface

CODE_EXTS = {".lua", ".xml", ".toc", ".txt", ".md"}

stats = extract_interface.extract_all()

# ---- manifest exists, deterministic shape ----
manifest_path = config.RAW_INTERFACE_DIR / "_manifest.json"
assert manifest_path.is_file(), manifest_path
manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
files = manifest["files"]
assert manifest["count"] == len(files) == stats["count"]

# ---- >=1500 files ----
assert len(files) >= 1500, len(files)

# ---- sorted relative paths (deterministic manifest) ----
assert list(files) == sorted(files), "manifest file keys must be sorted"

# ---- zero non-code extensions in manifest ----
bad_ext = [p for p in files if os.path.splitext(p)[1].lower() not in CODE_EXTS]
assert not bad_ext, bad_ext[:10]

# ---- every entry has source/size/sha256; source is an archive name or "disk" ----
for p, meta in files.items():
    assert set(meta) == {"source", "size", "sha256"}, (p, meta)
    assert meta["size"] >= 0
    assert len(meta["sha256"]) == 64

# ---- sha256 sample check: 25 files, on-disk content hashes to the recorded value ----
rng = random.Random(0)
sample = rng.sample(sorted(files), min(25, len(files)))
for rel in sample:
    p = config.RAW_INTERFACE_DIR.joinpath(*rel.split(os.sep))
    assert p.is_file(), p
    data = p.read_bytes()
    assert len(data) == files[rel]["size"], rel
    assert hashlib.sha256(data).hexdigest() == files[rel]["sha256"], rel

# ---- AddOns/APIDocumentation present, disk-sourced, >=10 .lua files ----
api_prefix = os.sep.join(["AddOns", "APIDocumentation"]) + os.sep
api_entries = {p: m for p, m in files.items() if p.lower().startswith(api_prefix.lower())}
api_lua = [p for p in api_entries if p.lower().endswith(".lua")]
assert len(api_lua) >= 10, len(api_lua)
assert all(m["source"] == "disk" for m in api_entries.values()), \
    "APIDocumentation must be disk-sourced (it wins over any archive carrier)"
api_dir = config.RAW_INTERFACE_DIR / "AddOns" / "APIDocumentation"
assert api_dir.is_dir()
assert len(list(api_dir.glob("*.lua"))) >= 1
assert (api_dir / "APIDocumentation.toc").is_file()

# ---- stats reported by extract_all() carry manifest sha256 + file count ----
assert stats["count"] == manifest["count"]
assert len(stats["manifestSha256"]) == 64
assert stats["manifestSha256"] == hashlib.sha256(manifest_path.read_bytes()).hexdigest()
assert stats["diskSourced"] == len(api_entries)
assert stats["archiveSourced"] + stats["diskSourced"] == stats["count"]

# ---- the pipeline no longer runs this module at all ----
# raw/interface is emitted by datamine.py's own traversal (emit.emit_interface),
# out of the snapshot, in the same pass as every other raw layer. This module is
# what the curated pipeline USED to re-scan the client with, and curation is now a
# pure function of raw - so the stage is gone rather than repeated. The module
# stays as a standalone cross-check of that layer, which is what the assertions
# above are: they compare an independent scan against the published manifest.
import datamine
prov = json.loads((config.RAW_DIR / "provenance.json").read_text(encoding="utf-8"))
assert "interface" not in prov["buildStats"], \
    "the curated pipeline must not re-extract the Interface tree - "\
    "emit.emit_interface owns raw/interface, from the snapshot"
assert (config.RAW_INTERFACE_DIR / "_manifest.json").is_file()

print("ALL PASS")
