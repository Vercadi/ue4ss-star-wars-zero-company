"""Check source syntax, required issue fields, payload hashes and publication hygiene."""
import json
from pathlib import Path
import subprocess
from lupa.lua54 import LuaRuntime
import yaml
from common import ROOT, manifest, sha


def main():
    info = manifest()
    paths = {p.name for p in (ROOT / "signatures").glob("*.lua")}
    expected = {Path(n).name for n in info["baseline_runtime_files"] if n.startswith("ue4ss/UE4SS_Signatures/")}
    assert paths == expected and len(paths) == 4
    lua = LuaRuntime(unpack_returned_tuples=True)
    for name in sorted(paths):
        file = ROOT / "signatures" / name
        lua.execute("return assert(load(...))", file.read_text(encoding="utf-8"), "@" + name)
        assert sha(file.read_bytes()) == info["baseline_runtime_files"]["ue4ss/UE4SS_Signatures/" + name], name
    assert sha((ROOT / "config/UE4SS-settings.ini").read_bytes()) == info["baseline_runtime_files"]["ue4ss/UE4SS-settings.ini"]
    for file in (ROOT / "tools").glob("*.py"):
        compile(file.read_text(encoding="utf-8"), str(file), "exec")
    for file in (ROOT / ".github").rglob("*.yml"):
        parsed = yaml.safe_load(file.read_text(encoding="utf-8"))
        assert isinstance(parsed, dict), file
        if "ISSUE_TEMPLATE" in file.parts and file.name != "config.yml":
            assert parsed.get("name") and parsed.get("body"), file
            assert any(row.get("validations", {}).get("required") for row in parsed["body"]), file
    listing = subprocess.run(["git", "ls-files", "-z"], cwd=ROOT, capture_output=True, check=True).stdout
    tracked = listing.decode().strip("\0").split("\0")
    assert tracked and tracked != [""]
    forbidden = {".exe", ".dll", ".pdb", ".dmp", ".zip", ".log", ".runtime-xml"}
    for name in tracked:
        file = Path(name)
        assert file.suffix.lower() not in forbidden, name
        assert not any(part in {"Research", "Runtime Testing", "Release Candidates", ".venv"} for part in file.parts), name
        assert file.name != ".env" and not file.name.startswith(".env."), name
        assert (ROOT / file).stat().st_size < 256 * 1024, name
    print(json.dumps({"status": "PASS", "signature_syntax_and_hashes": 4, "tracked_files": len(tracked),
                      "private_game_artifacts_present": False, "runtime_verified": False}))


if __name__ == "__main__":
    main()
