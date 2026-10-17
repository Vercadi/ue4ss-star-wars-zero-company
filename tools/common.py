"""Shared paths and the exact historical native transformation."""
from pathlib import Path
import hashlib
import json

ROOT = Path(__file__).resolve().parents[1]


def manifest():
    return json.loads((ROOT / "release.json").read_text(encoding="utf-8"))


def sha(data):
    return hashlib.sha256(data).hexdigest().upper()


def patch_native(data):
    info = manifest()
    if sha(data) != info["original_dll_sha256"]:
        raise ValueError("Input is not the pinned official UE4SS DLL; refusing fixed-offset patch")
    patch = info["dll_patch"]
    at = patch["offset"]
    old, new = bytes.fromhex(patch["before"]), bytes.fromhex(patch["after"])
    if data[at:at + len(old)] != old or len(old) != len(new):
        raise ValueError("Native patch bytes differ")
    output = data[:at] + new + data[at + len(old):]
    if sha(output) != info["patched_dll_sha256"]:
        raise ValueError("Native output hash differs from the released DLL")
    return output
