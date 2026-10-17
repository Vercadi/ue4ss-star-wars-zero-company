# Interactive wrapper for the read-only file checker.
# Writes only a new support folder outside the game installation. No uploads.
[CmdletBinding()]
param(
    [string]$GameFolder,
    [string]$OutputFolder,
    [switch]$NoUI
)
$ErrorActionPreference = 'Stop'

function Resolve-GameFolder {
    param([Parameter(Mandatory=$true)][string]$SelectedFolder)
    $root = (Resolve-Path -LiteralPath $SelectedFolder).ProviderPath
    # Check the actual game binaries before any launcher in the selected root.
    $candidates = @(
        (Join-Path $root 'SWZeroCompany\Binaries\Win64'),
        (Join-Path $root 'Binaries\Win64'),
        (Join-Path $root 'Win64'),
        $root
    )
    foreach ($candidate in $candidates) {
        if ((Split-Path -Leaf $candidate) -ieq 'Win64' -and
            (Test-Path -LiteralPath (Join-Path $candidate 'SWZeroCompany.exe') -PathType Leaf)) {
            return (Resolve-Path -LiteralPath $candidate).ProviderPath
        }
    }
    throw 'Could not find SWZeroCompany\Binaries\Win64\SWZeroCompany.exe. Choose the Star Wars Zero Company installation folder, or its SWZeroCompany\Binaries\Win64 folder.'
}

function New-GameFolderDialog {
    $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
    $dialog.Description = 'Choose your Star Wars Zero Company game folder on any drive. You can also select SWZeroCompany\Binaries\Win64 directly.'
    $dialog.ShowNewFolderButton = $false
    $dialog.RootFolder = [System.Environment+SpecialFolder]::MyComputer
    return $dialog
}

function Select-GameFolder {
    $dialog = New-GameFolderDialog
    try {
        if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            return $dialog.SelectedPath
        }
        return $null
    }
    finally { $dialog.Dispose() }
}

function Write-SupportFolder {
    param(
        [Parameter(Mandatory=$true)][string]$GameDirectory,
        [Parameter(Mandatory=$true)][string]$Destination
    )
    $destinationPath = [IO.Path]::GetFullPath($Destination)
    $gameRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $GameDirectory))
    $gameRoot = [IO.Path]::GetFullPath($gameRoot).TrimEnd('\')
    if ($destinationPath.TrimEnd('\').Equals($gameRoot, [StringComparison]::OrdinalIgnoreCase) -or
        $destinationPath.StartsWith($gameRoot + '\', [StringComparison]::OrdinalIgnoreCase)) {
        throw 'Extract the diagnostic ZIP into a folder outside the game installation, such as Downloads, then double-click START_DIAGNOSTICS.cmd again.'
    }

    $checker = Join-Path $PSScriptRoot 'Inspect-UE4SSInstallation.ps1'
    if (-not (Test-Path -LiteralPath $checker -PathType Leaf)) {
        throw 'The file checker is missing. Extract all files from the diagnostic ZIP into the same folder.'
    }
    Write-Host 'Reading game and UE4SS file details. This may take a moment...'
    $json = (& $checker -Win64 $GameDirectory) -join [Environment]::NewLine
    $report = $json | ConvertFrom-Json
    if ($null -eq $report.Files -or @($report.Files).Count -ne 8) {
        throw 'The checker did not produce a complete report. Please send the displayed error to Vercadi.'
    }

    $folderName = 'UE4SS-report-' + (Get-Date -Format 'yyyyMMdd-HHmmss') + '-' + [Guid]::NewGuid().ToString('N').Substring(0, 6)
    $supportFolder = Join-Path $destinationPath $folderName
    [void][IO.Directory]::CreateDirectory($supportFolder)
    $encoding = New-Object System.Text.UTF8Encoding($false)
    [IO.File]::WriteAllText((Join-Path $supportFolder 'UE4SS-diagnostics.txt'), $json + [Environment]::NewLine, $encoding)

    $logNote = 'No UE4SS.log was found in the selected installation. Tell Vercadi that no log was available.'
    $logPath = Join-Path $GameDirectory 'ue4ss\UE4SS.log'
    if (Test-Path -LiteralPath $logPath -PathType Leaf) {
        try {
            [IO.File]::Copy($logPath, (Join-Path $supportFolder 'UE4SS.log'), $false)
            $logNote = 'UE4SS.log was copied from your installation. Check that it belongs to the failed launch you are reporting; the tool does not launch the game or create a fresh game log.'
        }
        catch {
            $logNote = 'UE4SS.log exists but could not be copied. Send UE4SS-diagnostics.txt and tell Vercadi the log could not be copied. Close the game before retrying.'
        }
    }
    $instructions = @"
SEND THESE RESULTS TO VERCADI

Review UE4SS-diagnostics.txt and UE4SS.log (if present), then DM those files
or their contents to Vercadi on Nexus Mods. Add:
- Your storefront: Steam, EA App or Epic.
- What happens when you launch, and whether F10 works.

$logNote

A hash mismatch identifies a different file; it does not prove corruption.
Logs may contain personal folder paths. Nothing has been uploaded automatically.
The game installation was only read. This folder was created by Diagnostic Tool v1.3.
"@
    [IO.File]::WriteAllText((Join-Path $supportFolder 'SEND_TO_VERCADI.txt'), $instructions, $encoding)
    return $supportFolder
}

function Invoke-Diagnostics {
    try {
        if (-not $NoUI) {
            Add-Type -AssemblyName System.Windows.Forms
            [System.Windows.Forms.Application]::EnableVisualStyles()
        }
        $selectedFolder = $GameFolder
        if ([string]::IsNullOrWhiteSpace($selectedFolder)) {
            if ($NoUI) { throw 'GameFolder is required when using NoUI.' }
            $selectedFolder = Select-GameFolder
            if ([string]::IsNullOrWhiteSpace($selectedFolder)) {
                Write-Host 'Cancelled. No report was created.'
                return 0
            }
        }
        $gameDirectory = Resolve-GameFolder -SelectedFolder $selectedFolder
        $destination = $OutputFolder
        if ([string]::IsNullOrWhiteSpace($destination)) { $destination = $PSScriptRoot }
        $supportFolder = Write-SupportFolder -GameDirectory $gameDirectory -Destination $destination
        Write-Host ('Report saved: ' + $supportFolder)
        if (-not $NoUI) {
            [void][System.Windows.Forms.MessageBox]::Show(
                "Your report is ready. The results folder will open next.`n`nDM UE4SS-diagnostics.txt and UE4SS.log (if present) to Vercadi. Add your storefront and what happens when you launch.",
                'UE4SS diagnostic report ready',
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Information)
            try { Invoke-Item -LiteralPath $supportFolder }
            catch { Write-Host ('Open the results folder manually: ' + $supportFolder) }
        }
        return 0
    }
    catch {
        $message = $_.Exception.Message
        [Console]::Error.WriteLine($message)
        if (-not $NoUI -and ('System.Windows.Forms.MessageBox' -as [type])) {
            [void][System.Windows.Forms.MessageBox]::Show($message, 'UE4SS diagnostic tool',
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Error)
        }
        return 1
    }
}

# Dot-sourcing exposes the small functions for automated checks without a dialog.
if ($MyInvocation.InvocationName -ne '.') {
    exit (Invoke-Diagnostics)
}
