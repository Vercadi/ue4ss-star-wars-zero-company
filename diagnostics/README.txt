UE4SS DIAGNOSTIC TOOL v1.3 - STAR WARS ZERO COMPANY

HOW TO USE

1. Close the game. Extract the entire ZIP into its own folder outside the game
   installation, for example in Downloads.
2. Double-click START_DIAGNOSTICS.cmd.
3. Choose your Star Wars Zero Company installation folder in the window.
   Any drive is supported. You can also choose its
   SWZeroCompany\Binaries\Win64 folder directly. Click OK.
4. Wait for the report to finish. Click OK on the completion message.
   The results folder opens automatically.
5. Review UE4SS-diagnostics.txt and UE4SS.log (if included), then DM those
   files or their contents to Vercadi on Nexus Mods. Include your storefront
   (Steam, EA App or Epic) and what happens when you launch the game.

You do not need to edit any file, type a command, or install PowerShell.
Use START_DIAGNOSTICS.cmd to start; the PS1 files are used by the launcher.
Keep all four extracted files together. Do not run the tool inside the ZIP.

WHERE ARE MY RESULTS?

A new folder named UE4SS-report-[date and time]-[identifier] is created beside
the tool. It contains UE4SS-diagnostics.txt, a copy of UE4SS.log if available,
and SEND_TO_VERCADI.txt. Existing report folders are preserved.

The copied log is the existing log, not a new game session. The tool does not
launch the game. If no log is available, tell Vercadi when you send the report.

IF SOMETHING GOES WRONG

Cancel closes the folder picker without collecting a report.
If the game folder is not found, run the tool again and select the folder
containing SWZeroCompany\Binaries\Win64\SWZeroCompany.exe.
If Windows blocks the launcher or the tool reports an error, send that error
to Vercadi. No administrator access is required.

WHAT THE TOOL DOES

This is a support tool, not a mod update or a compatibility fix. It reads the
game executable and UE4SS file identities, checks for a log and PDB, and copies
the existing log into the new results folder. It does not change game files,
load game DLLs, launch or stop the game, access saves, or upload anything.

A different executable hash is expected for some storefront builds and does
not prove corruption. Matching files do not prove runtime compatibility.
Logs may contain personal folder paths; review them before sharing.

The launcher uses built-in Windows PowerShell. It permits the included scripts
for that PowerShell process only; it does not change saved execution-policy
settings. Organization-enforced restrictions may still prevent it from running.

VERSION 1.3
Recognizes release 1.1.2, previous 1.1.1 and legacy RC3 files separately.
Recognizes the supplied EA executable 197649 as known but not runtime-confirmed.
Recognizes the owner's local 197649 hash without claiming retail Steam parity.
Known executable bytes and matching loader files do not prove compatibility.
No performance capture, automatic permissions changes or mod inventory added.
