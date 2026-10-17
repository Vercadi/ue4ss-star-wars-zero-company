@echo off
setlocal DisableDelayedExpansion
title UE4SS Diagnostic Tool - Star Wars Zero Company
rem Use the Windows PowerShell module path, not one inherited from PowerShell 7.
set "PSModulePath="
echo UE4SS Diagnostic Tool - Star Wars Zero Company
echo.
echo Choose your game folder in the window that opens.
echo The game files will only be read. Nothing is uploaded.
echo.
"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoLogo -NoProfile -STA -ExecutionPolicy Bypass -File "%~dp0Start-UE4SSDiagnostics.ps1"
if errorlevel 1 (
    echo.
    echo The diagnostic could not finish. Please send the error to Vercadi.
    pause
    exit /b 1
)
exit /b 0
