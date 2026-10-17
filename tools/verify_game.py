"""Read-only Lua resolver check against a supplied executable; no process launch."""
import argparse
import json
from pathlib import Path
import re
import struct
import pefile
from lupa.lua54 import LuaRuntime
from common import ROOT, sha


def inspect(path):
    if path.name.lower() != "swzerocompany.exe":
        raise ValueError("Supply the actual SWZeroCompany.exe in its original filename")
    data = path.read_bytes()
    pe = pefile.PE(data=data, fast_load=True)
    base = 0x140000000

    def read32(address):
        rva = int(address) - base
        if rva < 0 or rva + 4 > pe.OPTIONAL_HEADER.SizeOfImage:
            return None
        try:
            value = struct.unpack("<i", pe.get_data(rva, 4))[0]
        except (struct.error, ValueError):
            return None
        return value if value else None  # Matches this UE4SS API's nil-for-zero behavior.

    checks = []
    for script in sorted((ROOT / "signatures").glob("*.lua")):
        lua = LuaRuntime(unpack_returned_tuples=True)
        messages = []
        lua.globals().DerefToInt32 = read32
        lua.globals().LoadExport = lambda name: 0
        lua.globals().print = lambda text: messages.append(str(text).strip())
        virtual = path.parent / "ue4ss/UE4SS_Signatures" / script.name
        item = {"script": script.name}
        try:
            lua.execute("assert(load(...))()", script.read_text(encoding="utf-8"), "@" + str(virtual))
            pattern = lua.globals().Register()
            regex = b"".join(b"." if t == "??" else re.escape(bytes([int(t, 16)])) for t in pattern.split())
            hits = set()
            for section in pe.sections:
                if section.Characteristics & 0x20000000:
                    hits.update(section.VirtualAddress + m.start() for m in re.finditer(regex, section.get_data(), re.DOTALL))
            if len(hits) != 1:
                raise ValueError(f"Expected one code match, found {len(hits)}")
            rva, = hits
            resolved = lua.globals().OnMatchFound(base + rva)
            item.update(status="OFFLINE_PASS", match_rva=hex(rva), result_rva=hex(resolved - base))
        except Exception as error:
            message = str(error).splitlines()[0]
            status = "RUNTIME_MEMORY_REQUIRED" if "cannot resolve game export anchor" in message else "REJECTED"
            item.update(status=status, error=message)
        item["messages"] = messages
        checks.append(item)
    result = {"exe_sha256": sha(data), "timestamp_identity": hex(pe.FILE_HEADER.TimeDateStamp),
              "checks": checks, "runtime_verified": False,
              "scope": "Actual Lua with simulated native reads of PE-mapped file bytes. Protected EA code needs real runtime evidence; this tool cannot supply it."}
    print(json.dumps(result, indent=2))
    return all(c["status"] == "OFFLINE_PASS" for c in checks)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--exe", required=True, type=Path)
    args = parser.parse_args()
    try:
        raise SystemExit(0 if inspect(args.exe.resolve()) else 1)
    except (OSError, ValueError, pefile.PEFormatError) as error:
        parser.exit(1, f"Refused: {error}\n")


if __name__ == "__main__":
    main()
