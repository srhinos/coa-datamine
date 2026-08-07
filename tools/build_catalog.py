"""Generate the searchable catalog over the raw table layer.

Step 3 of the raw table layer. Step 1 is tools/extract_all.py (MPQ chain ->
work/), step 2 is tools/decode_all.py (-> raw/tables/, positional f0..fN). This
step reads *only* what step 2 wrote and adds no facts of its own: every number
below is either copied from a decode measurement or computed from the decoded
values. Nothing here knows what a table means, and nothing here may learn.

Regenerate: `python -m tools.build_catalog`.

What it writes
--------------
  CATALOG.md                  repo root. One line per table - rows, fields,
                              bytes, the glob that matches its shards, and its
                              text columns with a real value each. The file an
                              agent reads first.
  raw/_catalog/tables.json    one line per table, every column of it: the
                              inferred type, the full decode evidence, and
                              distinct/min/max/pctZero.
  raw/_catalog/joins.json     candidate foreign keys, found by containment, one
                              line per source column. Rates and a null-model
                              baseline only - no semantics are asserted.
  raw/_catalog/strings.json   every string column in the client with sample
                              values, so "who holds this text" is one grep.

Why containment is reported with a baseline
-------------------------------------------
Ascension's id spaces are dense and overlapping, and a bare containment rate
lies about them: if a target's f0 covers most of the integers a source column
happens to span, the source will "join" at 1.0 by coincidence. So every
candidate carries the density of the target id space and a `baseline` - the
containment a column of values drawn uniformly from its own observed range
would score against that same target - plus `lift` = containment / baseline.
lift ~ 1.0 means the rate is what chance predicts. The reader judges; this file
never concludes.

Cost is bounded by construction, not by taste: only int-inferred columns are
sources (a float or a string offset is not a reference, and an all-zero column
has nothing to match), only f0 is a target, the identity pair is dropped, and
a pair whose value ranges do not overlap is skipped without being intersected -
which is exact, never a false negative. The caps are recorded in the output.
"""
import bisect
import gzip
import json
import sys
import time
from collections import Counter
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from tools import config, layerstate, sharding

TABLES_DIR = config.RAW_DIR / "tables"
CATALOG_DIR = config.RAW_DIR / "_catalog"
CATALOG_MD = config.REPO_ROOT / "CATALOG.md"

# ---- caps, all recorded in the emitted files ------------------------------
MIN_CONTAINMENT = 0.95      # a candidate must reach this to be listed
MIN_SOURCE_DISTINCT = 2     # one distinct value joins anything; it is not evidence
TOP_K = 8                   # candidates kept per source column, best first
CHANCE_LIFT = 1.05          # at or under this, a candidate is what chance predicts
MIN_MATCHED_EVIDENCE = 5    # under this many matched values, lift is anecdote
STRING_SAMPLES = 25         # sample values per string column in strings.json
STRING_SAMPLES_MD = 3       # text columns shown per table in CATALOG.md
SAMPLE_CHARS_MD = 46        # sample truncation in CATALOG.md only
# A string column with more distinct values than this is sampled from the first
# this-many distinct values encountered in shard order rather than from all of
# them, so one pathological column cannot blow the build's memory. Shard order
# is fixed, so the choice stays deterministic. Recorded per column as `partial`.
STRING_COLLECT_CAP = 300000

JOIN_RULE = (
    "For every (source column, target table) pair the rate reported is "
    "containment: the share of the source column's DISTINCT NON-ZERO values "
    "that appear in the target table's f0. Zero is excluded because it is the "
    "layer's absent-reference sentinel and would otherwise inflate every rate. "
    "A zero on the TARGET side is kept, because there f0 = 0 is a real row's "
    "real key rather than a missing reference - the asymmetry is deliberate. "
    "Sources are int-inferred columns only - a float is not an id, a "
    "string-inferred column holds a string-block offset rather than a "
    "reference, an all-zero column has nothing to match, and a column with "
    f"fewer than {MIN_SOURCE_DISTINCT} distinct non-zero values joins anything "
    "by accident. Targets are the f0 of every table whose f0 decodes to "
    "integers. The identity pair (a table's own f0 against itself) is dropped; "
    "other self-references are kept. Pairs whose value ranges do not overlap "
    f"are skipped without intersecting, which is exact. Candidates at or above "
    f"{MIN_CONTAINMENT} containment are listed, at most {TOP_K} per source "
    "column, ordered by containment, then strong evidence before weak, then "
    "lift; `candidatesFound` is the count before that truncation. "
    f"`weakEvidence` marks a candidate backed by fewer than "
    f"{MIN_MATCHED_EVIDENCE} matched values, and it is the trap to watch: lift "
    "carries no sample size, so a column holding {1, 2} scores the same "
    "spectacular lift against a sparse target as a real reference with eleven "
    "matched ids does - the two smallest integers are ids in a great many "
    "tables. Read `matched` before believing `lift`. NOTHING HERE IS A FOREIGN "
    "KEY: this file reports measured overlap, and naming the relation is the "
    "reader's job."
)

BASELINE_RULE = (
    "Containment on its own cannot tell a relation from a coincidence, because "
    "a dense target id space is hit by any column of small integers. So each "
    "candidate carries the null model it has to beat. `targetDensity` is the "
    "share of the integers between the target's lowest and highest id that are "
    "real ids - the rate at which a value that lands anywhere in that range "
    "hits something by chance. `inSpan` is how many of the source's distinct "
    "values land in that range at all, so `expectedMatches` = inSpan x "
    "targetDensity is what chance alone predicts, and `lift` = matched / "
    "expectedMatches. lift at or near 1.0 means the rate is exactly what "
    "chance predicts and the candidate is noise; a lift far above 1.0 means "
    "the column hit a SPARSE id space, which chance does not do. Note what "
    "this baseline deliberately does NOT depend on: the source column's own "
    "min and max. A range-based null is destroyed by one outlier - a single "
    "large value widens the range, collapses the expected rate and reports a "
    "dense, meaningless target as a spectacular hit. Values outside the "
    "target's span simply do not count toward inSpan here."
)

BY_TARGET_RULE = (
    "`columns` is indexed by SOURCE column and answers 'what does this column "
    "join to'. `byTarget` is the same candidate set indexed by TARGET table and "
    "answers 'which columns join to THIS table's f0' - the question an agent "
    "asks first, and the one that previously required traversing the whole file "
    "by hand. It introduces no new measurement and applies no extra filter: "
    "every entry is a candidate already present in `columns`, so the same caps, "
    "the same containment rule and the same chance baseline govern it. "
    "`aboveChance` counts the inbound columns whose lift reaches "
    f"{CHANCE_LIFT}; `aboveChanceStrong` counts those of them that ALSO have at "
    f"least {MIN_MATCHED_EVIDENCE} matched values, and it is the one to read - a "
    "column holding two values that happen to be ids clears the chance bar as "
    "easily as a real reference with a hundred. The rest are listed because "
    "suppressing a rate is a hidden judgement, not because they are evidence. "
    "`python -m tools.find --joins-to <Table>` reads this index.")

STRING_RULE = (
    "Every column the decode inferred as a string, with sample values taken "
    "from its distinct values in sorted order - all of them when the column "
    f"has at most {STRING_SAMPLES} (then `exhaustive` is true and a grep of "
    "this file is authoritative for that column), otherwise evenly spaced "
    "across the sorted distinct values so the samples span the range instead "
    "of clustering at its start. Samples are examples, not an index: to find "
    "an arbitrary string anywhere in the client, run `python -m tools.find "
    "\"<text>\"`, which scans every shard."
)


# --------------------------------------------------------------------------
# reading the layer
# --------------------------------------------------------------------------
def write_text(path: Path, text: str) -> None:
    """UTF-8, LF, no BOM, written as bytes - Path.write_text() would translate
    newlines to the platform's and make this layer's bytes depend on the OS
    that generated them. Same rule the shards are written under."""
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(text.encode("utf-8"))


def load_json(path: Path) -> dict:
    return json.loads(path.read_bytes().decode("utf-8"))


def layer_index() -> dict:
    return load_json(TABLES_DIR / "index.json")


def colinfo(stem: str) -> dict:
    return load_json(TABLES_DIR / stem / (stem + ".colinfo.json"))


def table_index(stem: str) -> dict:
    return load_json(TABLES_DIR / stem / "index.json")


def shard_paths(stem: str, ix: dict = None) -> list:
    ix = ix or table_index(stem)
    d = TABLES_DIR / stem
    return [d / s["file"] for s in ix["shards"]]


def open_shard(path: Path):
    if path.suffix == ".gz":
        return gzip.open(path, "rt", encoding="utf-8")
    return open(path, "rt", encoding="utf-8")


def iter_lines(stem: str, ix: dict = None):
    """Raw shard lines, in index order. The text is yielded before it is parsed
    so callers that only need a substring test never pay for json."""
    for p in shard_paths(stem, ix):
        with open_shard(p) as f:
            for line in f:
                if line.strip():
                    yield p, line


def iter_records(stem: str, ix: dict = None):
    for p, line in iter_lines(stem, ix):
        yield p, json.loads(line)


_F0_AT = len('{"f0":')


def line_f0(line: str):
    """The integer f0 of a record, without parsing the record.

    Records are compact and key-sorted, so "f0" is always the first key. Returns
    None when f0 is not an integer (a string- or float-inferred f0), and the
    caller falls back to a real parse."""
    end = len(line)
    for ch in (",", "}"):
        i = line.find(ch, _F0_AT)
        if 0 < i < end:
            end = i
    tok = line[_F0_AT:end]
    if not tok or tok[0] == '"':
        return None
    try:
        return int(tok)
    except ValueError:
        return None


# --------------------------------------------------------------------------
# pass A - the target id spaces
# --------------------------------------------------------------------------
def build_targets(stems: list, infos: dict, verbose: bool) -> tuple:
    """{table: (set_of_f0, sorted_list, min, max)} for every table whose f0
    decodes to integers, plus the list of tables that have no integer key."""
    targets, keyless = {}, []
    t0 = time.time()
    for n, stem in enumerate(stems, 1):
        ci = infos[stem]
        if not ci["columns"]:
            keyless.append({"table": stem, "reason": "no columns"})
            continue
        kind = ci["columns"][0]["inferred"]
        ix = table_index(stem)
        if ix["rows"] == 0:
            keyless.append({"table": stem, "reason": "no rows"})
            continue
        vals = set()
        if kind == "string":
            # f0 is a string; its raw int rides alongside as f0i.
            for _, rec in iter_records(stem, ix):
                v = rec.get("f0i")
                if isinstance(v, int):
                    vals.add(v)
        else:
            for _, line in iter_lines(stem, ix):
                v = line_f0(line)
                if v is not None:
                    vals.add(v)
        if not vals:
            keyless.append({"table": stem, "reason": "f0 holds no integer"})
            continue
        lo, hi = min(vals), max(vals)
        targets[stem] = {"ids": vals, "lowest": lo, "highest": hi,
                         "density": rate(len(vals), hi - lo + 1)}
        if verbose and n % 40 == 0:
            print(f"  [targets] {n}/{len(stems)}  {time.time()-t0:.0f}s", flush=True)
    return targets, keyless


# --------------------------------------------------------------------------
# pass B - per table: source value sets, string values, containment
# --------------------------------------------------------------------------
def rate(part: int, whole: int) -> float:
    return round(part / whole, 6) if whole else 0.0


def score_column(stem: str, name: str, values: set, targets: dict,
                 histogram: Counter) -> tuple:
    """Containment of one source column against every target id space, each
    scored against the chance rate it has to beat (see BASELINE_RULE)."""
    ordered = sorted(values)
    lo, hi, n = ordered[0], ordered[-1], len(ordered)
    found, skipped, evaluated = [], 0, 0
    for tname in targets:
        if tname == stem and name == "f0":
            continue                      # identity, not information
        t = targets[tname]
        tmin, tmax = t["lowest"], t["highest"]
        if hi < tmin or lo > tmax:
            skipped += 1
            continue
        evaluated += 1
        hit = len(values & t["ids"])
        c = hit / n
        histogram[min(int(c * 20), 19)] += 1
        if c < MIN_CONTAINMENT:
            continue
        # How many of THIS column's values even land in the target's id range;
        # the ones that do not are not evidence either way, and counting them
        # is what makes a range-based baseline collapse on a single outlier.
        in_span = (bisect.bisect_right(ordered, tmax)
                   - bisect.bisect_left(ordered, tmin))
        expected = in_span * t["density"]
        found.append({
            "table": tname,
            "containment": round(c, 6),
            "matched": hit,
            "inSpan": in_span,
            "targetDistinct": len(t["ids"]),
            "targetMin": tmin,
            "targetMax": tmax,
            "targetDensity": t["density"],
            "expectedMatches": float(f"{expected:.4g}"),
            "lift": round(hit / expected, 4) if expected > 0 else None,
            # Lift is an effect size with no sample size in it. Two values that
            # both happen to be real ids score exactly what eleven do.
            "weakEvidence": hit < MIN_MATCHED_EVIDENCE,
        })
    found.sort(key=lambda r: (-r["containment"], r["weakEvidence"],
                              -(r["lift"] or 0), r["targetDistinct"], r["table"]))
    return found, skipped, evaluated


def scan_tables(stems: list, infos: dict, targets: dict, verbose: bool) -> dict:
    """One read of the whole layer: builds each table's per-column distinct
    value sets, scores them against every target, and collects the distinct
    values of every string column. Per-table state is dropped as soon as it has
    been scored, so peak memory is one table plus the target spaces."""
    joins, strings = [], []
    histogram = Counter()
    pairs = evaluated = skipped_total = 0
    t0 = time.time()

    for n, stem in enumerate(stems, 1):
        ci = infos[stem]
        ix = table_index(stem)
        int_cols = [c for c in ci["columns"] if c["inferred"] == "int"]
        str_cols = [c for c in ci["columns"] if c["inferred"] == "string"]
        if ix["rows"] and (int_cols or str_cols):
            int_sets = {c["name"]: set() for c in int_cols}
            str_sets = {c["name"]: set() for c in str_cols}
            adders = [(c["name"], int_sets[c["name"]].add) for c in int_cols]
            str_adders = [(c["name"], str_sets[c["name"]]) for c in str_cols]
            for _, rec in iter_records(stem, ix):
                for name, add in adders:
                    v = rec.get(name)
                    if v:                       # non-zero; zero is "no reference"
                        add(v)
                for name, bag in str_adders:
                    if len(bag) < STRING_COLLECT_CAP:
                        v = rec.get(name)
                        if v is not None:
                            bag.add(v)
        else:
            int_sets, str_sets = {}, {}

        for c in int_cols:
            values = int_sets.get(c["name"]) or set()
            if len(values) < MIN_SOURCE_DISTINCT:
                continue
            pairs += 1
            found, skipped, seen = score_column(stem, c["name"], values,
                                                targets, histogram)
            evaluated += seen
            skipped_total += skipped
            if found:
                joins.append({
                    "table": stem,
                    "column": c["name"],
                    "columnIndex": c["index"],
                    "sourceDistinct": len(values),
                    "sourceMin": min(values),
                    "sourceMax": max(values),
                    "candidatesFound": len(found),
                    "candidates": found[:TOP_K],
                })

        for c in str_cols:
            vals = str_sets.get(c["name"]) or set()
            distinct = c["evidence"].get("distinct", 0)
            ordered = sorted(vals)
            strings.append({
                "table": stem,
                "column": c["name"],
                "columnIndex": c["index"],
                "rows": ix["rows"],
                "distinctOffsets": distinct,
                "distinctValues": len(ordered),
                "hasEmpty": "" in vals,
                "partial": len(vals) >= STRING_COLLECT_CAP,
                "exhaustive": len(ordered) <= STRING_SAMPLES,
                "path": f"raw/tables/{stem}/*.jsonl" + (".gz" if ix["format"] == "gzip" else ""),
                "samples": spread(ordered, STRING_SAMPLES),
            })

        int_sets = str_sets = None
        if verbose and n % 20 == 0:
            print(f"  [scan] {n}/{len(stems)}  {len(joins)} join rows  "
                  f"{time.time()-t0:.0f}s", flush=True)

    joins.sort(key=lambda r: (r["table"].lower(), r["columnIndex"]))
    strings.sort(key=lambda r: (r["table"].lower(), r["columnIndex"]))
    return {"joins": joins, "strings": strings, "histogram": histogram,
            "sourceColumns": pairs, "pairsEvaluated": evaluated,
            "pairsSkippedByRange": skipped_total}


def spread(ordered: list, k: int) -> list:
    """k evenly spaced picks across a sorted list (all of it when it is short).
    Deterministic, and it samples the whole range instead of just its start."""
    if len(ordered) <= k or k < 2:
        return list(ordered[:k]) if k < 2 else list(ordered)
    step = (len(ordered) - 1) / (k - 1)
    return [ordered[round(i * step)] for i in range(k)]


# --------------------------------------------------------------------------
# emitting
# --------------------------------------------------------------------------
def column_record(c: dict) -> dict:
    ev = c["evidence"]
    rows = ev.get("rows", 0)
    rec = {
        "index": c["index"],
        "name": c["name"],
        "inferred": c["inferred"],
        "width": c["width"],
        "rows": rows,
        "distinct": ev.get("distinct", 0),
        "zeroCount": ev.get("zeroCount", 0),
        "nonZeroCount": ev.get("nonZeroCount", 0),
        "pctZero": rate(ev.get("zeroCount", 0), rows),
        "minSigned": ev.get("minSigned"),
        "maxSigned": ev.get("maxSigned"),
        "minUnsigned": ev.get("minUnsigned"),
        "maxUnsigned": ev.get("maxUnsigned"),
        "evidence": ev,
    }
    # Samples ride only on columns the decode actually called a string. Every
    # column carries a string-hypothesis decode in colinfo, and on an int column
    # those "values" are whatever bytes sit at that offset in the string block -
    # reading them as content is how a wrong answer gets written down.
    if c["inferred"] == "string":
        rec["samples"] = c.get("samples", [])
    return rec


def write_tables_json(stems: list, infos: dict, layer: dict, targets: dict,
                      keyless: list) -> dict:
    by_table = {t["table"]: t for t in layer["tables"]}
    records = []
    for stem in stems:
        ci = infos[stem]
        t = by_table[stem]
        ix = table_index(stem)
        records.append({
            "table": stem,
            "file": t["file"],
            "winner": t.get("winner"),
            "rows": t["rows"],
            "columns": t["columns"],
            "shards": t["shards"],
            "format": t["format"],
            "storedBytes": t["storedBytes"],
            "plainBytes": t["plainBytes"],
            "shardKey": t["shardKey"],
            "path": f"raw/tables/{stem}/*.jsonl" + (".gz" if t["format"] == "gzip" else ""),
            "colinfo": f"raw/tables/{stem}/{stem}.colinfo.json",
            "keyDistinct": len(targets[stem]["ids"]) if stem in targets else 0,
            "keyMin": targets[stem]["lowest"] if stem in targets else None,
            "keyMax": targets[stem]["highest"] if stem in targets else None,
            "keyDensity": targets[stem]["density"] if stem in targets else 0.0,
            "inferredCounts": ix["inferredCounts"],
            "columnDetail": [column_record(c) for c in ci["columns"]],
        })
    payload = {
        "note": "Every column of every table in the client: the type the decode "
                "inferred, the evidence it inferred it from, and the "
                "distribution of the values. One line per table - the column "
                "detail is nested inside it, so this file stays under the "
                "5,000-line rule and `json.load` gives an agent the whole "
                "layer's shape in one read. Column names are positional "
                "(f0..fN) because nothing in this repo knows what they mean. "
                "Load this file, do not grep it: a table's line carries all of "
                "its columns and can run to hundreds of KB. CATALOG.md and "
                "raw/_catalog/strings.json are the views built for grep.",
        "sampleRule": "`samples` appears only on columns inferred as strings. "
                      "Every column has a string-hypothesis decode recorded in "
                      "its colinfo, but on an int column those bytes are not "
                      "content and must not be read as any.",
        "keyRule": "`keyDistinct`/`keyMin`/`keyMax`/`keyDensity` describe the "
                   "table's f0 id space, measured from the decoded rows. "
                   "Density is the share of the integers between min and max "
                   "that are real ids - the closer to 1.0, the more readily "
                   "any column of small integers will appear to join to it.",
        "generatedBy": "python -m tools.build_catalog",
        "tableCount": len(records),
        "columnCount": sum(len(r["columnDetail"]) for r in records),
        "tablesWithoutIntegerKey": sorted(keyless, key=lambda r: r["table"]),
        "tables": records,
    }
    write_text(CATALOG_DIR / "tables.json", sharding.dump_manifest(payload))
    return payload


def write_joins_json(scan: dict, targets: dict) -> dict:
    hist = [{"from": round(i / 20, 2), "to": round((i + 1) / 20, 2),
             "pairs": scan["histogram"][i]} for i in range(20)
            if scan["histogram"][i]]
    payload = {
        "note": "Mechanically discovered candidate joins. Read `rule` before "
                "reading a rate, and `baselineRule` before believing one.",
        "rule": JOIN_RULE,
        "baselineRule": BASELINE_RULE,
        "generatedBy": "python -m tools.build_catalog",
        "caps": {"minContainment": MIN_CONTAINMENT,
                 "minSourceDistinct": MIN_SOURCE_DISTINCT,
                 "candidatesPerColumn": TOP_K,
                 "minMatchedEvidence": MIN_MATCHED_EVIDENCE,
                 "chanceLift": CHANCE_LIFT},
        "targetTables": len(targets),
        "sourceColumns": scan["sourceColumns"],
        "pairsEvaluated": scan["pairsEvaluated"],
        "pairsSkippedByRange": scan["pairsSkippedByRange"],
        "columnsWithCandidates": len(scan["joins"]),
        "candidateCount": sum(len(r["candidates"]) for r in scan["joins"]),
        "candidatesAtChanceLevel": sum(
            1 for r in scan["joins"] for c in r["candidates"]
            if c["lift"] is None or c["lift"] < CHANCE_LIFT),
        "candidatesWeakEvidence": sum(
            1 for r in scan["joins"] for c in r["candidates"]
            if c["weakEvidence"]),
        "chanceLevelNote": f"Candidates whose lift is below {CHANCE_LIFT} are "
                           "listed but score no better than random integers in "
                           "the same id range. They are kept because a "
                           "suppressed rate is a hidden judgement; they are "
                           "not evidence of a relation.",
        "containmentHistogram": hist,
        "byTargetRule": BY_TARGET_RULE,
        "byTarget": by_target(scan["joins"]),
        "columns": scan["joins"],
    }
    write_text(CATALOG_DIR / "joins.json", sharding.dump_manifest(payload))
    return payload


def by_target(joins: list) -> list:
    """The same candidates, inverted: target table -> every column that points at
    its f0.

    `columns` answers "what does THIS column join to". Nothing answered the
    question an agent actually asks first - "what joins to Spell?" - which had to
    be hand-derived by traversing the whole file. Same measurements, same caps,
    no new evidence: this is an index, not a claim."""
    inv = {}
    for row in joins:
        for c in row["candidates"]:
            inv.setdefault(c["table"], []).append({
                "table": row["table"], "column": row["column"],
                "containment": c["containment"], "matched": c["matched"],
                "lift": c["lift"], "weakEvidence": c["weakEvidence"],
                "targetDensity": c["targetDensity"],
                "sourceDistinct": row["sourceDistinct"]})
    out = []
    for target in sorted(inv):
        rows = sorted(inv[target],
                      key=lambda r: (-r["containment"], r["weakEvidence"],
                                     -(r["lift"] or 0), r["table"].lower(),
                                     r["column"]))
        strong = [r for r in rows if not r["weakEvidence"]
                  and r["lift"] is not None and r["lift"] >= CHANCE_LIFT]
        out.append({"target": target, "targetColumn": "f0",
                    "inboundColumns": len(rows),
                    "inboundTables": len({r["table"] for r in rows}),
                    # Two counts, because one of them alone misleads. A column
                    # can clear the chance bar on two matched values, and this
                    # layer has already been burned by a spectacular lift with
                    # no sample size behind it (see JOIN_RULE).
                    "aboveChance": sum(1 for r in rows
                                       if r["lift"] is not None
                                       and r["lift"] >= CHANCE_LIFT),
                    "aboveChanceStrong": len(strong),
                    "aboveChanceStrongTables": len({r["table"] for r in strong}),
                    "weakEvidence": sum(1 for r in rows if r["weakEvidence"]),
                    "columns": rows})
    return out


def write_strings_json(scan: dict) -> dict:
    payload = {
        "note": "Every string column in the client, with real values from it.",
        "rule": STRING_RULE,
        "generatedBy": "python -m tools.build_catalog",
        "samplesPerColumn": STRING_SAMPLES,
        "columnCount": len(scan["strings"]),
        "tableCount": len({r["table"] for r in scan["strings"]}),
        "distinctValueTotal": sum(r["distinctValues"] for r in scan["strings"]),
        "columns": scan["strings"],
    }
    write_text(CATALOG_DIR / "strings.json", sharding.dump_manifest(payload))
    return payload


def human_bytes(n: int) -> str:
    """Decimal units, matching raw/tables/README.md - the same byte count must
    not read as two different numbers in two generated files."""
    for unit, size in (("GB", 1e9), ("MB", 1e6), ("KB", 1e3)):
        if n >= size:
            return f"{n / size:.1f} {unit}"
    return f"{n} B"


def pct(x: float) -> str:
    """Two significant figures, so a sparse id space reads as 0.04% instead of
    rounding to the 0% that makes it look identical to a dense one."""
    return f"{float(f'{x * 100:.2g}'):g}%"


def md_cell(s: str) -> str:
    """A sample value made safe for one markdown table cell."""
    s = " ".join(str(s).split())
    if len(s) > SAMPLE_CHARS_MD:
        s = s[:SAMPLE_CHARS_MD - 1] + "…"
    return s.replace("\\", "\\\\").replace("|", "\\|").replace("`", "'")


def write_catalog_md(layer: dict) -> None:
    """Generated from the JSON that was just written and read back off disk, so
    the markdown can never quote a number the catalog does not contain."""
    tj = load_json(CATALOG_DIR / "tables.json")
    sj = load_json(CATALOG_DIR / "strings.json")
    jj = load_json(CATALOG_DIR / "joins.json")

    by_table = {}
    for c in sj["columns"]:
        by_table.setdefault(c["table"], []).append(c)

    L = ["# Client data catalog (generated)\n"]
    L.append("**Generated file - never hand-edit.** Every line below is written "
             "by `python -m tools.build_catalog` from `raw/tables/`, which "
             "`python -m tools.decode_all` writes from the client's MPQ chain. "
             "An edit here is overwritten on the next run and, worse, becomes a "
             "hand-authored fact in a layer whose whole point is that it "
             "contains none.\n")
    L.append("## What is here\n")
    L.append(f"- **{tj['tableCount']} tables**, "
             f"**{layer['totalRows']:,} rows**, "
             f"**{tj['columnCount']:,} columns**, "
             f"{human_bytes(layer['storedBytes'])} stored "
             f"({human_bytes(layer['plainBytes'])} decoded)")
    L.append("- Columns are positional: `f0`, `f1`, ... `fN`. Nothing in this "
             "repo knows what a column means, so nothing here names one.")
    L.append("- Types are measured, not asserted: "
             + ", ".join(f"{v:,} {k}" for k, v in
                         sorted(layer["inferredColumnCounts"].items()))
             + ". The evidence behind every call is in "
               "`raw/tables/<Table>/<Table>.colinfo.json` and "
               "`raw/_catalog/tables.json`.\n")
    L.append("## Finding things\n")
    L.append("```")
    L.append('python -m tools.find "Tide Lash"      # which table/column holds a string')
    L.append("python -m tools.find --id 133         # every table an integer appears in")
    L.append("python -m tools.find --joins-to Spell # which columns point at Spell.f0")
    L.append("```")
    L.append("The first two also scan `raw/content` (the .loc localization store) "
             "and `raw/cache` (the WDB query caches), because quest and item "
             "TEXT lives there and not in the DBC - `Quest` and `Item` carry no "
             "string column at all. Add `--layer tables` to restrict.\n")
    L.append("| file | what it answers |")
    L.append("| --- | --- |")
    L.append("| `raw/_catalog/tables.json` | every column of every table: "
             "inferred type, decode evidence, distinct/min/max/pctZero |")
    L.append(f"| `raw/_catalog/strings.json` | {sj['columnCount']} string "
             "columns with sample values - grep it for text |")
    L.append(f"| `raw/_catalog/joins.json` | {jj['columnsWithCandidates']} "
             f"columns with {jj['candidateCount']} candidate joins, each with "
             "the target's id density and a chance baseline; `byTarget` inverts "
             f"them over {len(jj['byTarget'])} target tables |")
    L.append("| `raw/tables/index.json` | shard map, byte counts, source archive "
             "per table |")
    L.append("| `raw/README.md` | the other raw layers: content/.loc, Interface, "
             "WDB caches |\n")
    L.append("## Reading a row\n")
    L.append("Every record is one line of one shard, keyed positionally: "
             "`{\"f0\":133,\"f136\":\"Fireball\"}`. `f5i` is the raw int when "
             "`f5` decoded as a string, `f5s` the decoded string when `f5` "
             "decoded as an int - so a wrong type call loses nothing. "
             "`raw/tables/README.md` states the full rule.\n")
    L.append("## A warning this repo paid for\n")
    L.append("CoA ids collide across generations - the same ability exists under "
             "a catalog id, a trainer rank id and a live talent-node id, with "
             "the same name and no join table. A containment rate of 1.0 in "
             "`joins.json` is overlap, not identity, which is why every "
             "candidate ships with `targetDensity`, `lift` and `matched`. "
             "`lift` near 1.0 is chance. A high `lift` on a small `matched` is "
             "also chance - two values that happen to be ids score what eleven "
             "do. Read both before believing a join.\n")
    L.append("## Tables\n")
    L.append("Sorted by name. `size` is stored bytes; `key` is the f0 id space "
             "(distinct ids, and the share of its min..max range they occupy). "
             "`inbound` is how many columns elsewhere in the client join to this "
             "table's f0, and how many of those beat chance on at least "
             f"{MIN_MATCHED_EVIDENCE} matched values - `python -m "
             "tools.find --joins-to <Table>` lists them. `text columns` are the "
             "string columns with the most distinct values, one real value "
             "each.\n")
    inbound = {b["target"]: b for b in jj["byTarget"]}
    L.append("| table | rows | cols | size | key | inbound | shards | text columns |")
    L.append("| --- | ---: | ---: | ---: | --- | --- | --- | --- |")
    for t in tj["tables"]:
        cols = sorted(by_table.get(t["table"], []),
                      key=lambda c: (-c["distinctValues"], c["columnIndex"]))
        bits = []
        for c in cols[:STRING_SAMPLES_MD]:
            # The first sample sorts first, and "" sorts before everything - so
            # taking samples[0] blanks exactly the big name columns that carry
            # an empty string somewhere. Show the first sample with content.
            v = next((s for s in c["samples"] if s.strip()), "")
            bits.append(f"`{c['column']}` {md_cell(v)}" if v else f"`{c['column']}`")
        key = (f"{t['keyDistinct']:,} @ {pct(t['keyDensity'])}"
               if t["keyDistinct"] else "-")
        b = inbound.get(t["table"])
        inb = (f"{b['inboundColumns']} ({b['aboveChanceStrong']} strong)"
               if b else "-")
        L.append(f"| **{t['table']}** | {t['rows']:,} | {t['columns']} | "
                 f"{human_bytes(t['storedBytes'])} | {key} | {inb} | "
                 f"`{t['path']}` | {' · '.join(bits) or '-'} |")
    L.append("")
    write_text(CATALOG_MD, "\n".join(L))


# --------------------------------------------------------------------------
def run(verbose: bool = True) -> dict:
    # raw/tables left half-written by a crash still has a readable index.json for
    # the tables that survived; cataloguing it would publish a partial client as
    # the whole one.
    layerstate.require_complete(TABLES_DIR, "python -m tools.decode_all")
    layerstate.begin(CATALOG_DIR)
    layer = layer_index()
    stems = sorted((t["table"] for t in layer["tables"]), key=str.lower)
    infos = {s: colinfo(s) for s in stems}
    if verbose:
        print(f"catalog: {len(stems)} tables, {layer['totalRows']:,} rows",
              flush=True)

    targets, keyless = build_targets(stems, infos, verbose)
    if verbose:
        print(f"  {len(targets)} target id spaces, {len(keyless)} tables "
              f"without an integer key", flush=True)

    scan = scan_tables(stems, infos, targets, verbose)
    tables = write_tables_json(stems, infos, layer, targets, keyless)
    joins = write_joins_json(scan, targets)
    strings = write_strings_json(scan)
    write_catalog_md(layer)
    layerstate.finish(CATALOG_DIR, {
        "layer": "raw/_catalog", "generatedBy": "python -m tools.build_catalog",
        "tableCount": tables["tableCount"], "columnCount": tables["columnCount"],
        "joinCandidateCount": joins["candidateCount"],
        "stringColumnCount": strings["columnCount"]})

    if verbose:
        print(f"  CATALOG.md, tables.json ({tables['columnCount']:,} columns), "
              f"joins.json ({joins['candidateCount']:,} candidates over "
              f"{joins['columnsWithCandidates']:,} columns), "
              f"strings.json ({strings['columnCount']} columns)", flush=True)
    return {"tables": tables, "joins": joins, "strings": strings}


if __name__ == "__main__":
    run()
