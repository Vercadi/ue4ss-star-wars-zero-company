# UE4SS compatibility for Star Wars Zero Company

Game-specific Lua signatures and a diagnostic tool maintained by Vercadi, with community fixes welcome.

**Download the complete loader from [Nexus Mods](https://www.nexusmods.com/starwarszerocompany/mods/9?tab=files).** This repository contains the compatibility layer, not a standalone UE4SS installation or the full native loader source. It does not include the loader DLL, proxy or bundled helpers.

## What is here

- `signatures/`: the four published v1.1.2 signature scripts, preserved byte for byte.
- `config/`: the published game settings.
- `diagnostics/`: the optional Diagnostic Tool v1.3 source and launcher.
- `tools/`: offline verification and packaging tools.
- [Compatibility evidence](docs/compatibility.md), [support instructions](SUPPORT.md) and [contribution guide](CONTRIBUTING.md).

The resolvers scan for function patterns and validate the result. The EA loaded-code fallback admits two reviewed executable identities; an unknown identity is rejected. Future game updates can still require changes to signatures, build profiles or the native loader.

## Current status

On 16 October 2026, local executable **199049** initialized with the existing v1.1.1 runtime. F10 and loading an existing save worked. The published v1.1.2 scripts also passed offline checks against that executable. These are different kinds of evidence: the v1.1.2 scripts were not installed for that game session. A current retail Steam build ID and updated EA executable were not independently verified in that check. See [the evidence table](docs/compatibility.md) for the limits.

There is no guaranteed update schedule. Useful bug reports and tested pull requests are welcome. A compatibility change in this repository does not establish that every third-party mod supports the game update.

## Development

Use Python 3.11 or newer and install the verification dependencies:

```powershell
python -m pip install -r requirements-dev.txt
python tools/verify.py
python tools/verify_game.py --exe "X:\Games\Star Wars Zero Company\SWZeroCompany\Binaries\Win64\SWZeroCompany.exe"
```

Verification reads the supplied executable; it does not launch the game. A passing offline check still needs a fresh game session and log.

To make a full package, supply an existing complete v1.1.2 release ZIP or the exact [upstream UE4SS v3.0.1-1088 archive](https://github.com/UE4SS-RE/RE-UE4SS/releases/download/experimental/UE4SS_v3.0.1-1088-ga1e7f571.zip). The tool verifies the base archive's hash before packaging:

```powershell
python tools/package.py --base-package "X:\Downloads\UE4SS_for_Star_Wars_Zero_Company_v1.1.2_Steam-EA.zip" --output "X:\Builds\UE4SS-community-test.zip"
```

The upstream path applies the recorded two-byte native DLL patch, settings and signatures to reconstruct the published 24-file runtime. See [native provenance](docs/native-provenance.md) for its scope and standalone patch command. The generated archive's documentation and ZIP bytes can differ from the historical release.

Package output is for testing until its exact files have been qualified. Keep game executables, PDBs, dumps and private reports outside this repository.

## Credits

[UE4SS developers and contributors](https://github.com/UE4SS-RE/RE-UE4SS) created the underlying loader. Vercadi maintains this game's compatibility package. Thanks to **dvsreemo24, Fobio266, shancb9, Mace225, toki64136413 and rhpchong80** for reports, files and testing, and to everyone contributing useful evidence. These acknowledgments do not imply that every contributor tested every version.
