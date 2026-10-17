# UE4SS for Star Wars Zero Company

The complete **v1.1.2 release**, in its normal installation layout: `dwmapi.dll` and the `ue4ss` folder. This mirrors the existing package; it is not a new compatibility fix.

## Download and install

[Download the complete v1.1.2 ZIP](https://github.com/Vercadi/ue4ss-star-wars-zero-company/releases/download/v1.1.2/UE4SS_for_Star_Wars_Zero_Company_v1.1.2_Steam-EA.zip) or use [Nexus Mods](https://www.nexusmods.com/starwarszerocompany/mods/9?tab=files).

Close the game and back up your existing `dwmapi.dll` and complete `ue4ss` folder outside the game directory. Extract the ZIP into `SWZeroCompany\Binaries\Win64`, beside `SWZeroCompany.exe`, replacing included files. Custom settings are replaced; extra mods are not removed. Launch normally through your store client.

To roll back, close the game and restore your backup. To disable this loader temporarily, move its `dwmapi.dll` outside `Win64`.

## Help patch it

1. Download and extract the complete release. Change the relevant files, usually in `ue4ss/UE4SS_Signatures/`.
2. Test your changes in-game: startup, F10, save loading, entering a mission and normal exit. State anything you could not test.
3. Submit a **pull request with the changed files**, or [open an issue](https://github.com/Vercadi/ue4ss-star-wars-zero-company/issues/new) and attach your changed Lua files in a ZIP.

Include what failed, what you changed, your storefront/game version, mods used and a fresh `UE4SS.log`. If no log was created, say so. A diagnostic report is helpful if available. Remove personal details before posting; keep game EXEs, PDBs, saves and dumps private.

**No Python, packaging tools or manual hash updates are required to contribute.** Community test files are reviewed before becoming an official Nexus update. Further updates are not guaranteed.

## Version and credits

On local executable 199049, v1.1.1 initialized and the owner confirmed F10 and save loading. The v1.1.2 scripts passed offline checks against that executable; they were not runtime-tested in that session. This does not confirm every storefront or mod.

Based on [UE4SS source a1e7f571](https://github.com/UE4SS-RE/RE-UE4SS/tree/a1e7f571c789f63f3de6773d056be6f778c14dc8). The included DLL retains the existing two-byte FName branch patch at file offset `0x34E550` (`74 49` to `90 90`). For DLL changes, include the corresponding source changes and build/test details.

See [CREDITS.txt](CREDITS.txt) and the original [UE4SS license](ue4ss/LICENSE). This repository contains the released runtime, not the full native UE4SS source tree.
