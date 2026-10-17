# Reads file identities only. Does not load DLLs, change the installation,
# launch the game, access saves, or upload anything.
[CmdletBinding()]
param([Parameter(Mandatory=$true)][string]$Win64)
$ErrorActionPreference = 'Stop'
$gameDirectory = (Resolve-Path -LiteralPath $Win64).Path
$gameExecutable = Join-Path $gameDirectory 'SWZeroCompany.exe'
if (-not (Test-Path -LiteralPath $gameExecutable -PathType Leaf)) {
    throw 'Choose the SWZeroCompany\Binaries\Win64 folder containing SWZeroCompany.exe.'
}
$currentHashes = @{
    'dwmapi.dll' = 'EEDE335907F229C2F1DF9742C73053988F962AF0EB2E1B99735527C8D296C964'
    'ue4ss/UE4SS.dll' = '8CB45C18230547A1EAD97BFEB34A2B5EF710B778890DDFC01877A7E9C61A07F4'
    'ue4ss/UE4SS-settings.ini' = '191007424E51A812B91E60A4E510DAD284E2ED164C20C81FEC7E1104A1D13723'
    'ue4ss/UE4SS_Signatures/StaticConstructObject.lua' = '7BCABCA7C848A00FA543B317E5CE319CA8E7974000B579AE7C6009881EDB37C3'
    'ue4ss/UE4SS_Signatures/FName_Constructor.lua' = '083488759FA31E52513A7B5C39AB6E6E7944E7F4D9A41CB1916CFF5C78944AB4'
    'ue4ss/UE4SS_Signatures/GUObjectArray.lua' = '26E227002DC99F9E715CC722B2D774739843A7EBF07EE3D848E6B1D55C37CB13'
    'ue4ss/UE4SS_Signatures/ProcessLocalScriptFunction.lua' = 'E3D0A38162A6006B67F75A7DA6E60A2F16F66C8CC856E66126D0D48030819807'
}
$previousHashes = $currentHashes.Clone()
$previousHashes['ue4ss/UE4SS_Signatures/FName_Constructor.lua'] = '837790577F2FE09E2EEBE67AAE3259949A645E5BF2DB28380F81C18C12CE9D3C'
$previousHashes['ue4ss/UE4SS_Signatures/GUObjectArray.lua'] = 'EC7BBC99493B46FDF7B1599AEC99FE074DA71D420681270AFD4AC68F6D3E807C'
$previousHashes['ue4ss/UE4SS_Signatures/ProcessLocalScriptFunction.lua'] = 'CE79A255E225DCF87B0936E5D9B024726496AC27EA8AB97F12CD6DA2D576CF0F'
$previousHashes['ue4ss/UE4SS_Signatures/StaticConstructObject.lua'] = 'BF6D2B042DB464C427FDFCFC689BB7F6D67E3B26235A221DBF28A6F100BBC612'
$legacyHashes = $previousHashes.Clone()
$legacyHashes['ue4ss/UE4SS_Signatures/StaticConstructObject.lua'] = '526084FAD563ED8115B582ABE6776D61A6646647C9E7DFEA742728EB0D708206'
$legacyHashes['ue4ss/UE4SS_Signatures/FName_Constructor.lua'] = '365099694E45142B7C6FD55B500010255ABC8B652CE310BCF88B2A268B018CD8'
$legacyHashes['ue4ss/UE4SS_Signatures/GUObjectArray.lua'] = '601CE810199E2723A29E9035F522084669A999A409C51F28F4F1E1C167C97DA0'
$legacyHashes['ue4ss/UE4SS_Signatures/ProcessLocalScriptFunction.lua'] = '69D7F9D375AE4AAAEEF9D058079677E030EB980B43D13F397D98545B895E6D17'
$knownExecutables = @{
    'D12F2318D1B9DA731A631340E147B226C5844B62110662F3DAAA36AD91FE2571' = 'Steam build 25134257 / executable 196985'
    '665CA2E0CB1FED13C01574BA1F4F6F1C1B7494ECF056E9319F830E2DB1436687' = 'EA App / executable 196985'
}
$knownExecutables['B619F16EEDCFAF40B5972931C01E9E867FEDB60FABC690ED1F94A34C01E4E76F'] = 'EA App / executable 197649'
$knownExecutables['5C82C5628682FF58AEC57283840EDF7719CCDCA96B730FDB8FD83028EA5B6B4D'] = 'Local executable 197649 (retail Steam parity unverified)'
$rows = @(
    foreach ($relativePath in (@($currentHashes.Keys) + @('SWZeroCompany.exe') | Sort-Object)) {
        $filePath = Join-Path $gameDirectory $relativePath
        $present = Test-Path -LiteralPath $filePath -PathType Leaf
        $fileHash = if ($present) { (Get-FileHash -LiteralPath $filePath -Algorithm SHA256).Hash } else { $null }
        $fileLength = if ($present) { (Get-Item -LiteralPath $filePath).Length } else { $null }
        $isGame = $relativePath -eq 'SWZeroCompany.exe'
        [pscustomobject]@{
            File = $relativePath
            Present = $present
            Bytes = $fileLength
            SHA256 = $fileHash
            # The game EXE is not distributed in either loader package.
            MatchesCurrentReleaseFile = $(if ($isGame) { $null } else { $present -and $fileHash -eq $currentHashes[$relativePath] })
            MatchesPrevious111File = $(if ($isGame) { $null } else { $present -and $fileHash -eq $previousHashes[$relativePath] })
            MatchesLegacyRC3File = $(if ($isGame) { $null } else { $present -and $fileHash -eq $legacyHashes[$relativePath] })
        }
    }
)
$runtimeRows = @($rows | Where-Object { $_.File -ne 'SWZeroCompany.exe' })
$currentMatch = @($runtimeRows | Where-Object { -not $_.MatchesCurrentReleaseFile }).Count -eq 0
$previousMatch = @($runtimeRows | Where-Object { -not $_.MatchesPrevious111File }).Count -eq 0
$legacyMatch = @($runtimeRows | Where-Object { -not $_.MatchesLegacyRC3File }).Count -eq 0
$exeRow = $rows | Where-Object { $_.File -eq 'SWZeroCompany.exe' }
$knownVariant = $knownExecutables[$exeRow.SHA256]
$runtimeFileSet = if ($currentMatch) { 'Matches 1.1.2' }
    elseif ($previousMatch) { 'Matches previous 1.1.1 (same runtime as 1.1.1-rc1)' }
    elseif ($legacyMatch) { 'Matches legacy 1.1 / RC3' }
    else { 'Mixed, modified, missing, or unrecognized files; inspect individual hashes' }
$logPath = Join-Path $gameDirectory 'ue4ss/UE4SS.log'
$logPresent = Test-Path -LiteralPath $logPath -PathType Leaf
$gameInfo = (Get-Item -LiteralPath $gameExecutable).VersionInfo
$report = [ordered]@{
    ReportVersion = 3
    DiagnosticToolVersion = '1.3'
    CurrentRelease = '1.1.2'
    ObservedUTC = [DateTime]::UtcNow.ToString('o')
    FileVersion = $gameInfo.FileVersion
    ProductVersion = $gameInfo.ProductVersion
    KnownExecutableVariant = $(if ($knownVariant) { $knownVariant } else { 'Unknown executable hash' })
    ExecutableMatchesKnownBuild = [bool]$knownVariant
    ExecutableMatchesTestedBuild = ([bool]$knownVariant -and $exeRow.SHA256 -ne 'B619F16EEDCFAF40B5972931C01E9E867FEDB60FABC690ED1F94A34C01E4E76F')
    CurrentReleaseRuntimeValidated = $false
    ExecutableValidationStatus = $(if ($exeRow.SHA256 -eq 'B619F16EEDCFAF40B5972931C01E9E867FEDB60FABC690ED1F94A34C01E4E76F') { 'EA 197649: offline checked; runtime feedback pending' } elseif ($knownVariant) { 'Prior-release runtime evidence; 1.1.2 offline regression checked' } else { 'Unknown executable; investigate with log' })
    CheckedRuntimeFilesMatchCurrentRelease = $currentMatch
    CheckedRuntimeFilesMatchPrevious111 = $previousMatch
    CheckedRuntimeFilesMatchLegacyRC3 = $legacyMatch
    RuntimeFileSet = $runtimeFileSet
    Files = $rows
    PDBPresent = (Test-Path -LiteralPath (Join-Path $gameDirectory 'SWZeroCompany.pdb') -PathType Leaf)
    LogPresent = $logPresent
    LogLastWriteUTC = $(if ($logPresent) { (Get-Item -LiteralPath $logPath).LastWriteTimeUtc.ToString('o') } else { $null })
    RootUE4SSDllPresent = (Test-Path -LiteralPath (Join-Path $gameDirectory 'UE4SS.dll') -PathType Leaf)
    OverrideFilePresent = (Test-Path -LiteralPath (Join-Path $gameDirectory 'override.txt') -PathType Leaf)
    VersionProxyPresent = (Test-Path -LiteralPath (Join-Path $gameDirectory 'version.dll') -PathType Leaf)
    AdditionalModsEnvironmentConfigured = [bool]$env:UE4SS_MODS_PATHS
    Notes = 'Executable identity identifies known bytes, not the launcher used. Unknown or different files do not prove corruption. Only seven loader/signature/settings files are compared; helpers and all installed mods are not inventoried. Matching files do not prove runtime compatibility. Report the storefront and symptoms. Known identity is separate from runtime testing. ExecutableMatchesTestedBuild describes prior-release evidence, not a new 1.1.2 game session. New EA 197649 runtime feedback is pending. No PDB is required for these resolvers.'
}
$report | ConvertTo-Json -Depth 6
