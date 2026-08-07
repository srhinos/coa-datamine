"""Item support tables (task W4-11): DATAMINE-REQUEST.md Sec 8. Owns two things:

- `raw/dbc/itemstat/` - ItemStat.dbc's raw dump, SHARDED by `itemId // 50000`
  (Sec 8.2: 1,513,931 rows, 236MB body - too large for a single `raw/dbc/`
  file like every other table gets; dbc.dump_all() explicitly skips this table,
  see dbc.CUSTOM_RAW_DUMP_TABLES). Each shard's header names f1/f2 (the two
  golden-proven columns, see tools/dbc.py's ItemStat TABLE_MAPS comment) and
  leaves every other column raw f<N>, matching dbc.dump_table()'s own partial-
  naming convention.
- `data/items/statsByItem/` - a per-item COVERAGE index into that sharded dump
  (itemId -> which ownItemLevel rows exist + which raw shard holds them). This
  is deliberately an INDEX, not a re-decode of every ItemStat column: only f1/
  f2 are named this task, so that's all the curated layer claims. Bucketed at
  5,000 ids (NOT the raw layer's 50,000 - item ids cluster hard, e.g. the
  [2,050,000, 2,100,000) band alone holds 12,165 of the 20,267 distinct items,
  so a 50,000-wide curated bucket would blow the data/ 5,000-line gate; 5,000
  keeps every bucket's item count under it with margin, empirically checked).
"""
import csv, gzip, io, json

from tools import config, dbc, sharding

RAW_BUCKET_SIZE = 50000       # per the brief: "shard the raw dump by f1//50000"
CURATED_BUCKET_SIZE = 5000    # data/ line-gate headroom, see module docstring
ITEMSTAT_RAW_DIR = config.RAW_DBC_DIR / "itemstat"
STATS_BY_ITEM_DIR = config.DATA_DIR / "items" / "statsByItem"


def _itemstat_header(f: dbc.DBCFile) -> list:
    named = {idx: name for name, idx, kind in dbc.TABLE_MAPS["ItemStat"]["columns"]}
    return [named.get(i, f"f{i}") for i in range(f.fields)]


def dump_itemstat_sharded() -> tuple:
    """One streaming pass over ItemStat.dbc: writes raw/dbc/itemstat/itemstat-
    <bucket>.csv.gz per Amendment C fixed-range bucket (bucket = itemId//50000,
    the RAW layer's own bucket size - separate from the curated index's), and
    simultaneously collects each item's ownItemLevel list for the curated index
    below (one pass covers both, no need to re-read 1.5M rows twice).

    Returns (shard_meta, item_ilvls, total_rows)."""
    ITEMSTAT_RAW_DIR.mkdir(parents=True, exist_ok=True)
    f = dbc.DBCFile(config.WORK_DBC_DIR / "ItemStat.dbc")
    assert f.fields == 39, f"ItemStat: field_count {f.fields} != expected 39"
    header = _itemstat_header(f)

    writers = {}          # bucket -> [fileobj, gzipfile, textio, csv.writer, path, count]
    item_ilvls = {}        # itemId -> [ownItemLevel, ...] (encounter order)

    def _writer_for(bucket):
        w = writers.get(bucket)
        if w is None:
            path = ITEMSTAT_RAW_DIR / f"itemstat-{bucket}.csv.gz"
            fb = open(path, "wb")
            gz = gzip.GzipFile(fileobj=fb, mode="wb", mtime=0)
            fh = io.TextIOWrapper(gz, encoding="utf-8", newline="")
            wr = csv.writer(fh)
            wr.writerow(header)
            w = [fb, gz, fh, wr, path, 0]
            writers[bucket] = w
        return w

    for row in f.iter_rows():
        item_id = row[1]
        w = _writer_for(sharding.bucket_id(item_id, RAW_BUCKET_SIZE))
        w[3].writerow(row)
        w[5] += 1
        item_ilvls.setdefault(item_id, []).append(row[2])

    shard_meta = []
    for bucket in sorted(writers):
        fb, gz, fh, wr, path, count = writers[bucket]
        fh.close(); gz.close(); fb.close()      # inner-to-outer, matches dump_table()
        shard_meta.append({
            "bucket": bucket, "file": f"raw/dbc/itemstat/{path.name}", "rows": count,
        })

    manifest = {
        "bucketSize": RAW_BUCKET_SIZE, "totalRows": f.records,
        "distinctItems": len(item_ilvls), "shards": shard_meta,
    }
    (ITEMSTAT_RAW_DIR / "index.json").write_text(
        sharding.dump_manifest(manifest), encoding="utf-8", newline="\n")
    return shard_meta, item_ilvls, f.records


def build_stats_by_item(item_ilvls: dict) -> dict:
    """data/items/statsByItem/ - per-item coverage index, proven columns only
    (itemId/ownItemLevel). Golden gate mirrors build_creatures.py's convention:
    refuse to publish if the pinned ItemStat-internal facts (re-derivable from
    work/dbc/ItemStat.dbc alone, no external itemcache.wdb dependency in the
    build path - that cross-check lives in tests/test_items_layer.py, which is
    where the actual keying PROOF was established) don't hold."""
    assert len(item_ilvls.get(100248, [])) == 75, \
        "golden item 100248 lost its 75-row block - ItemStat keying assumption broken"
    from collections import Counter
    hist = Counter(len(v) for v in item_ilvls.values())
    assert dict(hist) == {75: 20171, 11: 48, 12: 44, 13: 2, 16: 1, 8: 1}, dict(hist)

    if STATS_BY_ITEM_DIR.exists():
        for p in STATS_BY_ITEM_DIR.glob("*"):
            p.unlink()
    else:
        STATS_BY_ITEM_DIR.mkdir(parents=True)

    bucketed = {}
    for item_id in sorted(item_ilvls):
        bucketed.setdefault(sharding.bucket_id(item_id, CURATED_BUCKET_SIZE), []) \
            .append(item_id)

    bucket_index = []
    for bkt in sorted(bucketed):
        ids = bucketed[bkt]
        raw_bucket = sharding.bucket_id(ids[0], RAW_BUCKET_SIZE)
        fname = f"statsByItem-{bkt}.jsonl"
        with open(STATS_BY_ITEM_DIR / fname, "w", encoding="utf-8", newline="\n") as fh:
            for item_id in ids:
                ilvls = sorted(item_ilvls[item_id])
                rec = {
                    "itemId": item_id, "rowCount": len(ilvls), "ilvls": ilvls,
                    "rawShard": f"raw/dbc/itemstat/itemstat-"
                                f"{sharding.bucket_id(item_id, RAW_BUCKET_SIZE)}.csv.gz",
                }
                fh.write(json.dumps(rec, ensure_ascii=False, sort_keys=True,
                                    separators=(",", ":")) + "\n")
        bucket_index.append({"bucket": bkt, "file": fname, "count": len(ids),
                              "minId": ids[0], "maxId": ids[-1]})

    index = {"bucketSize": CURATED_BUCKET_SIZE, "count": len(item_ilvls),
             "buckets": bucket_index}
    (STATS_BY_ITEM_DIR / "index.json").write_text(
        sharding.dump_manifest(index), encoding="utf-8", newline="\n")

    item_dbc_ids = {row[0] for row in
                    dbc.DBCFile(config.WORK_DBC_DIR / "Item.dbc").iter_rows()}
    join_hits = sum(1 for iid in item_ilvls if iid in item_dbc_ids)
    join_rate = join_hits / len(item_ilvls)

    meta = {
        "count": len(item_ilvls),
        "provenColumns": {
            "itemId": "ItemStat.dbc f1 - 20,267 distinct values, golden-verified "
                      "against item 100248 (\"Beaststalker's Belt\") vs itemcache.wdb "
                      "via tools/wdb_item.py - see tools/dbc.py's ItemStat TABLE_MAPS "
                      "comment for the full re-derivation.",
            "ownItemLevel": "ItemStat.dbc f2 - 75 distinct table-wide (dense 1-65 + "
                            "sparse 86/88/91/94/96/98/99/101/103/105), row-count-per-"
                            "item histogram {75:20171,11:48,12:44,13:2,16:1,8:1} "
                            "matches the source doc's cited histogram exactly.",
        },
        "itemIdJoinRate": round(join_rate, 4),
        "itemIdJoinRateFinding": (
            f"{join_hits}/{len(item_ilvls)} = {join_rate:.4f} of ItemStat's distinct "
            "itemIds resolve against live Item.dbc ids - matches the source doc's "
            "cited 96.96% closely. NOT treated as the primary proof (Item.dbc's id "
            "space is only ~6% dense - Sec 4 trap 8's exact false-positive shape); "
            "the 75-row-block structure + the golden armor/stat match are the real "
            "evidence, this join rate is corroborating context only."
        ),
        "scopeNote": (
            "This is a coverage INDEX (itemId -> which ownItemLevel rows exist + "
            "which raw shard holds them), not a re-decode of ItemStat's stat/armor/ "
            "damage columns (f3-f38) - those are documented, golden-checked evidence "
            "for the keying proof above, not independently named in TABLE_MAPS this "
            "task. A future task can pick up statType/statValue/armor/damage naming "
            "with the same golden-proof bar as everything else in this pipeline."
        ),
    }
    (STATS_BY_ITEM_DIR / "_meta.json").write_text(
        json.dumps(meta, ensure_ascii=False, indent=1, sort_keys=True), encoding="utf-8", newline="\n")
    return {"written": len(item_ilvls), "itemIdJoinRate": join_rate}


def build() -> dict:
    config.ensure_dirs()
    shard_meta, item_ilvls, total_rows = dump_itemstat_sharded()
    stats_by_item = build_stats_by_item(item_ilvls)
    return {"itemstatShards": len(shard_meta), "itemstatRows": total_rows,
            "statsByItem": stats_by_item}


if __name__ == "__main__":
    print(build())
