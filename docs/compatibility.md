# Compatibility evidence

Evidence cutoff: **17 October 2026**. These observations describe particular files and sessions; they are not a guarantee for every storefront, future patch, mod or save.

| Executable | Evidence retained | Limits |
| --- | --- | --- |
| Local 199049 | Fresh v1.1.1 initialization log; owner-confirmed F10 at menu and existing-save load. All four published v1.1.2 scripts passed offline disk and actual Lua callback checks. | The observed installation was `F:\Games`; a retail Steam build ID or byte parity was not independently established. v1.1.2 was not launched for this test. Mission loading, extended gameplay and normal-exit qualification were not recorded. Updated EA identity was not supplied. |
| Local 197649 | v1.1.1 initialization and F10; v1.1.2 disk-path offline regression. | Retail Steam parity and save/gameplay acceptance were not established for that session. |
| Steam 196985, build 25134257 | Historical v1.1.1 startup, save loading, brief gameplay, F10/stat unit and normal exit on matching executable bytes; v1.1.2 offline regression. | No separate runtime launch of the exact final v1.1.2 package was recorded in that release evidence. |
| EA 196985 | Historical v1.1.1 initialization logs and tester-reported menu, F10, gameplay and normal exit; v1.1.2 regression against captured loaded memory. | Historical sessions do not qualify a later executable. |
| EA 197649 | v1.1.2 adds the identity from the supplied executable and matching diagnostic. Metadata and resolver-control-flow checks passed. | At packaging, no new successful runtime capture was available. Synthetic positive fixtures did not establish actual loaded function bytes. Later community reports must be accompanied by exact package and executable evidence to extend this record. |

## Executable identities

FileVersion is useful for reports, but different storefront files can share it. SHA-256 identifies the actual bytes:

| Variant | SHA-256 |
| --- | --- |
| Local 199049 | `AA3FF2E0759C90BAE58054F2A68398E5B705FDFD05659242404D8C3602C6F36E` |
| Local 197649 | `5C82C5628682FF58AEC57283840EDF7719CCDCA96B730FDB8FD83028EA5B6B4D` |
| Steam 196985 | `D12F2318D1B9DA731A631340E147B226C5844B62110662F3DAAA36AD91FE2571` |
| EA 196985 | `665CA2E0CB1FED13C01574BA1F4F6F1C1B7494ECF056E9319F830E2DB1436687` |
| EA 197649 | `B619F16EEDCFAF40B5972931C01E9E867FEDB60FABC690ED1F94A34C01E4E76F` |

## Resolver behavior

Readable executable code follows the validated disk path. The EA fallback searches loaded code only after the specific no-recognized-entry result, and only for its reviewed executable profiles. It retains loaded identity, unwind/prologue, function-pattern, cross-reference and callback checks. It does not store fixed target addresses or automatically approve an unknown build.

Passing a pattern scan establishes a candidate address under those checks. It does not prove every native hook, gameplay transition or third-party mod works. The native DLL, proxy, settings and helpers were unchanged in v1.1.2. The existing native loader retains its historical FName branch patch; see [native provenance](native-provenance.md) before proposing a DLL change.

Optional hash-table and ConsoleManager warnings have appeared in accepted logs. Custom `GUObjectHashTables.lua` or `ConsoleManager.lua` files are not part of this package; failed overrides can make those scans fatal. See [support](../SUPPORT.md).

Epic, Linux/Proton, every third-party mod, and later unexamined executables are unqualified here. Future updates may require new build identities, signatures or native loader work. No update-proof or performance claim is made.
