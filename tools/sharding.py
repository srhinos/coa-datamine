"""Shared helpers for Amendment C file sharding (fixed id-range buckets + slugs).

Used by build_spells (id buckets), build_classes (cadId buckets for oversized
tab/type groups), and build_dungeons (name slugs). Kept generic so V2 writers
(creatures/quests/trainers/mythic) can reuse the same rules without copying them."""
import json, re

_NON_ALNUM = re.compile(r"[^a-z0-9]+")


def bucket_id(entity_id: int, size: int) -> int:
    """Fixed id-range bucket key: id // size * size. Stable per id - never shifts
    on insertion (unlike count-based chunking), so bucket membership never churns."""
    return entity_id // size * size


def slugify(name: str, max_len: int = 40) -> str:
    """Deterministic filename slug: lowercase, non-alnum runs -> '-', collapsed,
    stripped, truncated to max_len. Never empty (falls back to 'unnamed')."""
    s = _NON_ALNUM.sub("-", (name or "").lower()).strip("-")
    return s[:max_len].strip("-") or "unnamed"


def dump_manifest(payload: dict) -> str:
    """Deterministic index.json serialization for large manifests: any key whose
    value is a non-empty list of dicts gets ONE COMPACT RECORD PER LINE; every other
    key (scalars, small nested dicts, plain-value lists) is a single compact line.
    This is what keeps e.g. a 431-dungeon or 96-bucket index under the 5,000-line gate
    while staying meaningfully diffable per-record (a nested-object indent=1 dump
    puts one FIELD per line instead, burying record boundaries and multiplying line
    count many times over for manifests with hundreds of small records)."""
    keys = sorted(payload)
    lines = ["{"]
    for i, k in enumerate(keys):
        comma = "," if i < len(keys) - 1 else ""
        v = payload[k]
        if isinstance(v, list) and v and all(isinstance(x, dict) for x in v):
            lines.append(f' "{k}": [')
            for j, rec in enumerate(v):
                rc = "," if j < len(v) - 1 else ""
                lines.append("  " + json.dumps(rec, ensure_ascii=False, sort_keys=True,
                                               separators=(",", ":")) + rc)
            lines.append(f' ]{comma}')
        else:
            lines.append(f' "{k}": ' + json.dumps(v, ensure_ascii=False, sort_keys=True,
                                                   separators=(",", ":")) + comma)
    lines.append("}")
    return "\n".join(lines) + "\n"
