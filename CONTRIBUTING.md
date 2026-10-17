# Contributing

When changing a signature or the settings, update its reviewed SHA-256 in
`release.json` as part of the same pull request. The verifier and packager reject
unrecorded payload changes. Update the package version and compatibility evidence
for an intended release.

Keep fixes small and tied to a demonstrated failure. Include the storefront, executable identity, affected package version and the log showing what fails. Reported game patch names alone can refer to different executable files.

## Making a fix

1. Start from an issue with a reproducible failure. Preserve a copy of the existing files and a rollback path.
2. Change only what the evidence supports. Preserve the correct FName constructor overload, function-entry checks, cross-references, ambiguity rejection and native callback checks. Do not bypass an unknown-build rejection by broadly removing validation.
3. Check the actual executables available to you. Comparing old signature text is not a test against an older executable. A supplied PDB must match the executable's CodeView identity before using its symbols.
4. Run the offline tools and describe their results. Add meaningful checks for changed resolver behavior where practical. State when test data is synthetic.
5. Test the exact candidate in-game where possible: fresh startup, F10, save loading, a mission transition and normal exit. Record which steps you observed and which were reported by another person. Include Steam and EA regression evidence where available; mark the rest untested.

See [README](README.md) for tool commands and [compatibility](docs/compatibility.md) for the retained evidence. Do not install or launch anything on behalf of another person.

## Pull requests

Explain the failure, the correction and its remaining limits. Identify any changes to DLLs, settings, helpers or hook behavior separately. A signature match alone does not establish native-hook compatibility or prove that a crash belongs to another mod.

Do not commit game binaries, PDBs, memory dumps, saves, private messages, personal logs or release ZIPs. Use sanitized excerpts and hashes. Discuss a private transfer with the maintainer if a binary is necessary for investigation.

Native loader changes require the corresponding source, provenance and reproducible build instructions. This repository does not contain the complete native loader build. Contributions remain subject to review; no public release or turnaround is guaranteed.
