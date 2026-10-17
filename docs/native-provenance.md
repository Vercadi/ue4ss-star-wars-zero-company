# Native runtime provenance

The published native runtime is reproducible without a large source checkout. The complete package uses the [official UE4SS v3.0.1-1088-ga1e7f571 archive](https://github.com/UE4SS-RE/RE-UE4SS/releases/download/experimental/UE4SS_v3.0.1-1088-ga1e7f571.zip) and exactly two modified DLL bytes. All other native bytes are unchanged.

| Artifact | SHA-256 |
|---|---|
| Official archive | `7306A7799881344936DDEAD14B66030C402FCE7D45D0F81A4DE0B38055EEBCD8` |
| Original `ue4ss/UE4SS.dll` | `58DB28775BECD6257DB7C3BE758FDE245B2A0D228B5F16DBAE12E062A5A952DA` |
| Released patched DLL | `8CB45C18230547A1EAD97BFEB34A2B5EF710B778890DDFC01877A7E9C61A07F4` |
| Unmodified `dwmapi.dll` | `EEDE335907F229C2F1DF9742C73053988F962AF0EB2E1B99735527C8D296C964` |

The DLL is 19,763,712 bytes. At file offset `0x34E550`, its historical FName-verification branch bytes `74 49` become `90 90`. Whole-file comparison confirms exactly those two changed bytes. `tools/patch_runtime.py` checks the full original hash and expected bytes, performs that transformation and verifies the complete resulting hash. It refuses an already-patched or different DLL and never installs it.

```powershell
python tools/patch_runtime.py --input "X:\ExtractedOfficialArchive\ue4ss\UE4SS.dll" --output "X:\Builds\UE4SS.dll"
```

The FName constructor signature and verification flow are still present. This historical branch change is carried forward from the published loader; startup alone does not prove that it remains appropriate for every future engine build.

The package tool can instead consume the original v1.1.2 full ZIP, SHA-256 `540B59EA3B3074C29411A729E146E62BD476908311FE65713AC9396D9CF65966`, which already contains the patch. A later runtime-only v1.1.2 repack, SHA-256 `25D5C21B48C693127D6F58C706E64D9A8ED1717923AFA98701AC5C673D908FC1`, was also compared member by member and contains the same 24 runtime files. These are separate accepted archive identities; no other ZIP is implicitly trusted. All accepted base paths reproduce the same runtime. The game-specific source changes are the four signatures and settings. Remaining helpers, SDK configuration and proxy are copied unchanged from the verified upstream asset; they are not vendored here.

## Source changes to the native loader

Upstream source pin: [`a1e7f571c789f63f3de6773d056be6f778c14dc8`](https://github.com/UE4SS-RE/RE-UE4SS/tree/a1e7f571c789f63f3de6773d056be6f778c14dc8). Its Unreal submodule is `885ba757bf8ddcc1599a7b0be770fe2ec1143d4f`. Consult the build instructions at that pin for its MSVC/CMake/Rust toolchain and recursively pinned submodules; the released configuration reports `Game__Shipping__Win64`.

A fresh source build has not been shown to be byte-reproducible with the official asset. Do not apply the historical fixed-offset patch to a newly compiled DLL. A native change needs source review, its own output identity and new runtime qualification. No Dawnwalker-specific native changes are part of this package.

UE4SS's MIT notice is preserved in [`licenses/UE4SS-MIT.txt`](../licenses/UE4SS-MIT.txt). The existing community acknowledgments are in [`CREDITS.txt`](../CREDITS.txt).
