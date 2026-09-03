"""Regression: curated CAD entries preserve RequiredLevel source semantics."""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from tools import build_classes

missing = build_classes._curate_entry({"ID": 1}, [])
zero = build_classes._curate_entry({"ID": 2, "RequiredLevel": 0}, [])
positive = build_classes._curate_entry({"ID": 3, "RequiredLevel": 17}, [])

assert missing["requiredLevel"] is None
assert zero["requiredLevel"] == 0
assert positive["requiredLevel"] == 17
assert build_classes._FalseNegativeMeter._heuristic(
    {"requiredLevel": None, "type": "Ability"}) is False

print("ALL PASS")
