"""Rebuild the full 24-file runtime using a hash-pinned base ZIP. Never install it."""
import argparse
from pathlib import Path
import re
import zipfile
from common import ROOT, manifest, patch_native, sha


def build(base, output, version=None):
    info = manifest()
    version = version or info["version"]
    if not re.fullmatch(r"[0-9][0-9A-Za-z.+-]{0,63}", version):
        raise ValueError("Invalid release version")
    digest = sha(base.read_bytes())
    if digest not in {info["upstream_archive"]["sha256"], info["released_base_archive_sha256"],
                      info["runtime_only_base_archive_sha256"]}:
        raise ValueError("Base ZIP is not the pinned official archive or published v1.1.2 package")
    payload = {}
    with zipfile.ZipFile(base) as archive:
        names = archive.namelist()
        if len(names) != len(set(names)):
            raise ValueError("Duplicate ZIP members")
        for name in info["baseline_runtime_files"]:
            if name.startswith("ue4ss/UE4SS_Signatures/"):
                data = (ROOT / "signatures" / Path(name).name).read_bytes()
            elif name == "ue4ss/UE4SS-settings.ini":
                data = (ROOT / "config/UE4SS-settings.ini").read_bytes()
            else:
                data = archive.read(name)
                if name == "ue4ss/UE4SS.dll" and sha(data) == info["original_dll_sha256"]:
                    data = patch_native(data)
            if sha(data) != info["baseline_runtime_files"][name]:
                raise ValueError(f"Unexpected payload hash: {name}; update reviewed release.json for an intentional change")
            payload[name] = data
    payload["README.txt"] = (
        f"UE4SS for Star Wars Zero Company {version}\n\n"
        "Close the game. Back up dwmapi.dll and ue4ss outside the game folder.\n"
        "Extract into SWZeroCompany/Binaries/Win64 beside SWZeroCompany.exe,\n"
        "replacing included files. Existing additional mods are not removed.\n"
        "This supplies the compatibility settings and helpers.\n\n"
        "A reconstructed package needs runtime qualification before a new release.\n"
        "See the repository's compatibility evidence and support guide.\n"
        "Keep saves and shader caches. To disable, move this package's dwmapi.dll\n"
        "outside Win64 with the game closed. Restore the complete backup to roll back.\n\n"
        "https://github.com/Vercadi/ue4ss-star-wars-zero-company\n"
    ).encode()
    for source, destination in [("LICENSE", "COMPATIBILITY_LICENSE.txt"), ("CREDITS.txt", "CREDITS.txt"),
                                ("docs/compatibility.md", "SUPPORTED_BUILDS.md"),
                                ("docs/native-provenance.md", "NATIVE_PROVENANCE.md")]:
        payload[destination] = (ROOT / source).read_bytes()
    payload["FILE_HASHES.sha256"] = "".join(
        f"{sha(data)}  {name}\n" for name, data in sorted(payload.items())
    ).encode()
    output.parent.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(output, "x", compression=zipfile.ZIP_DEFLATED, compresslevel=9) as archive:
        for name, data in sorted(payload.items()):
            entry = zipfile.ZipInfo(name, date_time=(2026, 10, 17, 0, 0, 0))
            entry.compress_type = zipfile.ZIP_DEFLATED
            entry.external_attr = 0o644 << 16
            archive.writestr(entry, data, compresslevel=9)
    with zipfile.ZipFile(output) as archive:
        if archive.testzip() is not None or {n: archive.read(n) for n in archive.namelist()} != payload:
            raise ValueError("Output ZIP verification failed")
    digest = sha(output.read_bytes())
    with output.with_suffix(output.suffix + ".sha256").open("x", encoding="utf-8") as handle:
        handle.write(f"{digest}  {output.name}\n")
    print(f"Verified {len(info['baseline_runtime_files'])} runtime files; {digest}  {output.name}")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--base-package", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--version")
    args = parser.parse_args()
    try:
        build(args.base_package, args.output, args.version)
    except (OSError, ValueError, KeyError, zipfile.BadZipFile) as error:
        parser.exit(1, f"Refused: {error}\n")


if __name__ == "__main__":
    main()
