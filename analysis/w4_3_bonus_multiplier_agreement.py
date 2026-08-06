"""Task W4-3 evidence script: re-derive the DATAMINE-REQUEST.md Sec 2 claim that
`EffectBonusMultiplier` (f229-231, emitted as `effects[].bonusMultiplierStock`)
contradicts CoA's own tooltip-authored coefficient far more often than it agrees.

Run: python -m analysis.w4_3_bonus_multiplier_agreement   (from repo root)

Method: for every Spell.dbc effect slot carrying a nonzero f229-231 value, look for
a `${...}` formula block in that spell's description/tooltip text that references
the same slot (`$m<slot>` or `$s<slot>`) and contains a `$stat*coefficient` term;
compare the parsed coefficient against f229-231 at 5% relative tolerance. This is a
DELIBERATELY SIMPLE regex heuristic (not a full formula-language parser), so its
exact counts will differ from the source doc's own tooling - what matters is the
CONCLUSION (near-zero agreement) and that the measured percentage lands close to
the doc's cited figure, which it does on both populations:

    stock (id<100000, excluding the CoA class set): 0/65 agree (0.0%) - doc: 0/37 (0.0%)
    CoA class set:                                  7/113 agree (6.2%) - doc: 4/63 (6.3%)

Population definitions:
  - "CoA class set" = build_spells._coa_class_spell_ids() (every spell id, incl.
    rank-chain ids, referenced by the 21 coa-custom-tagged classes in
    data/classes/, intersected with live Spell.dbc ids) - same population used
    throughout .superpowers/sdd/task-w4-3-report.md and tests/test_spells_columns.py.
  - "stock" = Spell.dbc ids < 100000, EXCLUDING anything in the CoA class set (a
    few sub-100k ids are CoA-reused per DATAMINE-REQUEST.md Sec 4 trap 4).

See AGENT-GUIDE.md's "Spell column completion" section (the EffectBonusMultiplier
warning box) and .superpowers/sdd/task-w4-3-report.md for how these numbers are
used and cited.
"""
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from tools import config, dbc, build_spells

STAT_COEF_RE = re.compile(r'\$[a-zA-Z]+\s*\*\s*([0-9]*\.[0-9]+|[0-9]+)')
BRACE_RE = re.compile(r'\$\{([^}]*)\}')
TOLERANCE = 0.05


def find_coef_for_slot(text, slot):
    """Return the last $stat*coefficient value inside a ${...} block that
    references $m<slot> or $s<slot>, or None if no such block/term exists."""
    if not text:
        return None
    for block in BRACE_RE.findall(text):
        if re.search(rf'\$m{slot}\b', block) or re.search(rf'\$s{slot}\b', block):
            matches = STAT_COEF_RE.findall(block)
            if matches:
                try:
                    return float(matches[-1])
                except ValueError:
                    continue
    return None


def load_rows():
    f = dbc.DBCFile(config.WORK_DBC_DIR / "Spell.dbc")
    rows = []
    for row in f.iter_rows():
        sid = dbc.u32(row[0])
        rows.append((sid, row, f.string(row[170]), f.string(row[187])))  # id, row, desc, tip
    return rows


def agreement(rows, idset, label):
    both = agree = 0
    for sid, row, desc, tip in rows:
        if sid not in idset:
            continue
        for slot in range(3):
            bm_raw = row[229 + slot]
            if bm_raw == 0:
                continue
            bm = dbc.f32(bm_raw)
            coef = find_coef_for_slot(desc, slot + 1) or find_coef_for_slot(tip, slot + 1)
            if coef is None:
                continue
            both += 1
            if bm != 0 and abs(coef - bm) / abs(bm) <= TOLERANCE:
                agree += 1
    pct = (agree / both) if both else 0.0
    print(f"{label}: {agree}/{both} agree ({pct:.1%}, {TOLERANCE:.0%} tolerance)")
    return agree, both


def main():
    coa_ids = build_spells._coa_class_spell_ids()
    rows = load_rows()
    stock_ids = {sid for sid, *_ in rows if sid < 100000} - coa_ids
    agreement(rows, stock_ids, "stock (id<100000, excl. CoA class set)")
    agreement(rows, coa_ids, "CoA class set")


if __name__ == "__main__":
    main()
