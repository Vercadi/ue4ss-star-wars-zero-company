# Support

Use the latest complete package from [Nexus Files](https://www.nexusmods.com/starwarszerocompany/mods/9?tab=files). Repository source files alone are not a complete installation.

## Before reporting

With the game closed, back up `dwmapi.dll` and the complete `ue4ss` folder outside the game directory. For a comparison, temporarily move added UE4SS mods out of `ue4ss\Mods`, leaving the supplied helpers. Close the game between changes. Keep existing saves; a campaign can retain effects of previously installed mods, so a separate new campaign can be a useful comparison for a save-specific failure.

Collect evidence immediately after the failed run, before launching again:

1. Run the optional **UE4SS Diagnostic Tool v1.3** from Nexus Files. Extract it outside the game folder, double-click `START_DIAGNOSTICS.cmd`, and select your game folder. It can be on any drive.
2. Save the report and the fresh `ue4ss\UE4SS.log`, beside the actual `SWZeroCompany\Binaries\Win64\SWZeroCompany.exe`. If no log exists, say so.
3. Include your storefront, UE4SS package version, game version if known, all installed mods and what happens. Say which comparison you actually tried and its result.

Remove personal paths or account details before posting. Do not post executables, PDBs, dumps or saves publicly. The diagnostic tool reads installation information; it does not fix compatibility or measure stuttering.

Reports without enough information may be marked **needs information** or closed pending evidence. Complaints alone do not identify a change we can safely make.

## Two extra signature files

The package supplies `FName_Constructor.lua`, `GUObjectArray.lua`, `ProcessLocalScriptFunction.lua` and `StaticConstructObject.lua`.

It does **not** supply `GUObjectHashTables.lua` or `ConsoleManager.lua`. If a fatal error specifically names either extra Lua override, close the game, back up those two extra files and temporarily move them outside `ue4ss\UE4SS_Signatures`. Keep the four supplied files. Launch again and collect a fresh log. Accepted sessions have contained optional built-in scan warnings for these functions; an extra stale override can instead make initialization fail.

## Other failures

- **No log and a background hang:** report that exact symptom and your install path. A previous EA case involved denied log-write access; this does not establish that permissions explain every hang. Do not grant broad permissions or run as administrator without evidence.
- **F10 does nothing:** confirm the game is responsive, click inside it, and try Fn + F10 if your keyboard uses an Fn layer. The fresh log can distinguish missing initialization from an input issue.
- **A mod says unsupported game build:** include that mod's name and version. A native mod's build guard can refuse independently of a working loader.
- **Crashes or stuttering after initialization:** describe when it happens and compare the same situation with added mods removed. For a fair loader comparison, close the game and temporarily move this package's `dwmapi.dll` out of Win64, then restore it afterward. Preserve files and saves. Initialization logs alone do not measure performance or identify a crash's cause.
