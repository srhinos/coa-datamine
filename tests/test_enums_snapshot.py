import hashlib, sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from tools import config, enums335
from tools.snapshot_content import snapshot

assert enums335.DISPEL_NAMES[1] == "Magic" and enums335.DISPEL_NAMES[3] == "Disease"
assert enums335.school_names(0x2) == ["Holy"]
assert enums335.school_names(0x44) == ["Fire", "Arcane"]
assert enums335.aura_name(12) == "MOD_STUN"
assert enums335.aura_name(69) == "SCHOOL_ABSORB"
assert enums335.aura_name(99999) == "AURA_99999"
assert enums335.effect_name(6) == "APPLY_AURA"
assert enums335.effect_name(99999) == "EFFECT_99999"
assert enums335.POWER_TYPES[1] == "Rage" and enums335.POWER_TYPES[6] == "RunicPower"
assert enums335.INSTANCE_TYPES[2] == "Raid"

prov = snapshot()
assert "CharacterAdvancementData.json" in prov
src = config.CONTENT_DIR / "CharacterAdvancementData.json"
dst = config.RAW_CONTENT_DIR / "CharacterAdvancementData.json"
assert dst.is_file()
h = hashlib.sha256(dst.read_bytes()).hexdigest()
assert h == prov["CharacterAdvancementData.json"]["sha256"]
assert h == hashlib.sha256(src.read_bytes()).hexdigest()
print("ALL PASS")
