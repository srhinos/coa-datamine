"""Gate for the non-DBC raw layers: content (+ .loc), the Interface census, and
the WDB caches.

What this actually proves, in order of how much it would hurt to get wrong:

[1] The .loc decode is CLOSED - every file consumes to EOF, and the record
    counts in the index equal the lines actually on disk. A partial parse would
    show up as a shortfall, not as plausible-looking text.
[2] The WDB field layouts are EARNED - re-decoded here and cross-checked against
    ground truth an independent source fixes (item 100248's name/ilvl/armor,
    Hogger's rank, real quest titles). A wrong field order survives neither.
[3] Nothing is lost between the client and the layer: file counts equal the
    files on disk, shard line counts equal the record counts, and every
    `bytesAt` pointer resolves to a real file whose sha256 matches its record.
[4] The Interface census covers EVERY Interface path the inventory knows about -
    not a subset - and its binary-not-committed rule is a size rule, so every
    such record still carries a sha256.
[5] Determinism: content and cache rewrite byte-identically. (The Interface
    stage re-reads 4.4 GB, so it is checked against the committed layer rather
    than re-run here; its own run cross-verifies every sha256 against the
    inventory, which is the stronger check anyway.)
"""
import glob
import gzip
import hashlib
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from tools import config, extract_cache, extract_content, extract_interface_all, loc

SHARD_MAX = 5000


def read_shards(d: Path):
    for fp in sorted(d.glob("*.jsonl")) + sorted(d.glob("*.jsonl.gz")):
        op = gzip.open if fp.suffix == ".gz" else open
        with op(fp, "rt", encoding="utf-8") as f:
            for line in f:
                yield fp, json.loads(line)


def snapshot(paths):
    h = hashlib.sha256()
    n = 0
    for root in paths:
        p = Path(root)
        files = [p] if p.is_file() else sorted(x for x in p.rglob("*") if x.is_file())
        for f in files:
            h.update(str(f).replace("\\", "/").encode())
            h.update(f.read_bytes())
            n += 1
    return n, h.hexdigest()


# ==========================================================================
# [1] content + localization
# ==========================================================================
before = snapshot(["raw/content", "raw/cache"])
cix = extract_content.extract_all(verbose=False)

assert cix["failureCount"] == 0, cix["failures"]
assert cix["unhandledCount"] == 0, "an unhandled file class appeared under Data\\Content"

on_disk = sorted(p for p in config.CONTENT_DIR.rglob("*") if p.is_file())
assert cix["fileCount"] == len(on_disk), (cix["fileCount"], len(on_disk))
assert cix["jsonCount"] + cix["locCount"] == cix["fileCount"]

# every .loc really closes: decode independently, compare to the index
loc_files = [p for p in on_disk if p.suffix.lower() == ".loc"]
assert cix["locCount"] == len(loc_files) == 64, (cix["locCount"], len(loc_files))
total = 0
for p in loc_files:
    rows = loc.read(p.read_bytes())          # raises unless it consumes exactly
    total += len(rows)
assert total == cix["locRecordTotal"], (total, cix["locRecordTotal"])
assert total > 1_500_000, total

# shard line counts equal the decoded record counts, and the cap holds
for g in cix["localizationGroups"]:
    d = config.RAW_CONTENT_DIR / "localization" / g["entity"] / g["locale"]
    lines = sum(1 for _ in read_shards(d))
    assert lines == g["records"], (g["entity"], g["locale"], lines, g["records"])
    for s in g["shards"]:
        assert s["rows"] <= SHARD_MAX, (g, s)
    assert not g["oversizeShards"], g

# the id really is the entity id of the directory, not a row ordinal
spell_de = dict((r["id"], r["text"]) for _, r in read_shards(
    config.RAW_CONTENT_DIR / "localization" / "Spell/Name" / "deDE"))
assert spell_de[17] == "Machtwort: Schild", spell_de.get(17)   # spell 17 = Power Word: Shield
item_de = dict((r["id"], r["text"]) for _, r in read_shards(
    config.RAW_CONTENT_DIR / "localization" / "Item/Name" / "deDE"))
assert item_de[17] == "Martinsfuror", item_de.get(17)          # item 17 = Martin's Fury
print(f"[1] content: {cix['fileCount']} files, {cix['locCount']} .loc closed exactly, "
      f"{cix['locRecordTotal']:,} records, 0 failures")

# ==========================================================================
# [2] WDB caches - schemas earned, realms kept apart
# ==========================================================================
kix = extract_cache.extract_all(verbose=False)
cache_on_disk = sorted(p for p in extract_cache.CACHE_DIR.rglob("*") if p.is_file())
assert kix["fileCount"] == len(cache_on_disk), (kix["fileCount"], len(cache_on_disk))
assert kix["tierCounts"]["schema"] >= 18, kix["tierCounts"]
# nothing may be dropped: an undecoded file is either committed inline or hashed
for f in kix["failures"]:
    assert f["tier"] == "raw" and ("bytesBase64" in f or f.get("bytesCommitted") is False), f

# the realm cache is its own group and is NOT the base one
groups = kix["groups"]
realm = [g for g in groups if "rexxar" in g]
assert realm, groups
base_item = [e for e in kix["files"] if e["path"] == "enUS/itemcache.wdb"][0]
realm_item = [e for e in kix["files"] if e["path"].startswith("enUS/Rexxar")
              and e["name"] == "itemcache.wdb"][0]
assert realm_item["records"] > base_item["records"], (realm_item, base_item)
assert realm_item["sha256"] != base_item["sha256"]

# ground truth an independent source fixes - a wrong field order fails these
items = {r["_entry"]: r for _, r in read_shards(
    config.RAW_DIR / "cache" / realm[0] / "itemcache")}
belt = items[100248]
assert belt["name0"] == "Beaststalker's Belt", belt["name0"]
assert (belt["itemLevel"], belt["quality"], belt["armor"]) == (61, 4, 277), belt
assert belt["statsCount"] == 5 and belt["statType0"] == 3

npcs = {r["_entry"]: r for _, r in read_shards(
    config.RAW_DIR / "cache" / realm[0] / "creaturecache")}
assert npcs[448]["name0"] == "Hogger" and npcs[448]["rank"] == 1, npcs[448]
assert npcs[334]["subname"] == "Warlord of the Blackrock Clan", npcs[334]
assert 1.0 < npcs[448]["healthModifier"] < 100.0, npcs[448]["healthModifier"]

quests = {r["_entry"]: r for _, r in read_shards(
    config.RAW_DIR / "cache" / realm[0] / "questcache")}
assert quests[170]["title"] == "A New Threat", quests[170]["title"]
assert "Rockjaw" in quests[170]["objectives"], quests[170]["objectives"]

# the two headerless Ascension caches decoded flat, with a DERIVED record size
flat = [e for e in kix["files"] if e["tier"] == "flat"]
assert len(flat) == 2, flat
for e in flat:
    assert e["recordSize"] % 4 == 0 and e["recordSize"] > 0, e
    assert e["records"] * e["recordSize"] + 8 == e["bytes"], e   # closes exactly
    assert all(k.startswith("f") for k in
               next(r for _, r in read_shards(
                   config.RAW_DIR / "cache" / e["group"] /
                   extract_cache.slug(e["name"].rsplit(".", 1)[0])))), e
print(f"[2] cache: {kix['fileCount']} files, {kix['recordTotal']:,} records, "
      f"tiers {kix['tierCounts']}, realm kept separate from base")

# ==========================================================================
# [3]+[4] Interface census
# ==========================================================================
iix = json.loads((extract_interface_all.OUT_DIR / "index.json").read_text(encoding="utf-8"))
inv = extract_interface_all._inventory_interface_records()
assert iix["pathCount"] == len(inv), (iix["pathCount"], len(inv))
assert iix["sha256MismatchCount"] == 0, iix["sha256Mismatches"][:5]

seen = {}
for fp in sorted(extract_interface_all.PATHS_DIR.glob("*.jsonl")):
    rows = [json.loads(l) for l in fp.read_text(encoding="utf-8").splitlines()]
    assert len(rows) <= SHARD_MAX, (fp.name, len(rows))
    for r in rows:
        assert r["path"] not in seen, r["path"]
        seen[r["path"]] = r
assert len(seen) == iix["pathCount"] == len({r["path"] for r in inv}), len(seen)

committed = [r for r in seen.values() if r.get("bytesAt")]
for r in committed:
    p = Path(r["bytesAt"])
    assert p.is_file(), r["bytesAt"]
    assert hashlib.sha256(p.read_bytes()).hexdigest() == r["sha256"], r["path"]
assert len(committed) == iix["textCount"], (len(committed), iix["textCount"])

# every binary record keeps its hash - the bytes are recoverable, not curated away
for r in seen.values():
    if r.get("readable") is not False:
        assert r["sha256"], r["path"]
        assert (r["isText"] is True) == bool(r.get("bytesAt")), r["path"]

# the census really is a superset of the code layer
code = json.loads((config.RAW_INTERFACE_DIR / "_manifest.json").read_text(encoding="utf-8"))
arch_code = {("Interface/" + k.replace("\\", "/")) for k, m in code["files"].items()
             if m["source"] != "disk"}
assert arch_code <= set(seen), sorted(arch_code - set(seen))[:5]
print(f"[3+4] interface: {iix['pathCount']:,} paths ({iix['textCount']:,} text bytes "
      f"committed, {iix['binaryCount']:,} binary hashed), 0 sha256 mismatches, "
      f"superset of the {len(arch_code)} archive-sourced code files")

# ==========================================================================
# [5] determinism
# ==========================================================================
after = snapshot(["raw/content", "raw/cache"])
assert after == before, (before, after)
print(f"[5] determinism: {after[0]} files byte-identical to the committed layer")

print("ALL PASS")
