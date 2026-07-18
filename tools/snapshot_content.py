"""Verbatim snapshot of Data\\Content\\*.json into raw/content/ with hashes."""
import hashlib, shutil

from tools import config


def snapshot() -> dict:
    config.ensure_dirs()
    prov = {}
    for src in sorted(config.CONTENT_DIR.glob("*.json")):
        data = src.read_bytes()
        (config.RAW_CONTENT_DIR / src.name).write_bytes(data)
        prov[src.name] = {"sha256": hashlib.sha256(data).hexdigest(), "bytes": len(data)}
    return prov


if __name__ == "__main__":
    for name, e in snapshot().items():
        print(f"{name:55s} {e['bytes']:10d} {e['sha256'][:12]}")
