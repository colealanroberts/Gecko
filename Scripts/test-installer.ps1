param(
    [Parameter(Mandatory)][string]$Installer,
    [switch]$LaunchFixture
)
$ErrorActionPreference = 'Stop'
$destination = Join-Path $env:TEMP 'Gecko Installer Smoke Test'
$arguments = @('/VERYSILENT', '/SUPPRESSMSGBOXES', '/NORESTART', '/SP-', "/DIR=`"$destination`"", "/LOG=`"$env:TEMP/Gecko-install.log`"")
# Reinstall as well, exercising prerequisite detection and upgrade behavior.
foreach ($attempt in 1..2) {
    Write-Host "Install attempt $attempt"
    # -Wait follows the whole process tree, including runtime background brokers.
    # The setup process itself waits for prerequisites and reports their failures.
    $setup = Start-Process $Installer -ArgumentList $arguments -PassThru
    if (-not $setup.WaitForExit(120000)) {
        if (Test-Path "$env:TEMP/Gecko-install.log") { Get-Content "$env:TEMP/Gecko-install.log" -Tail 60 }
        throw 'Setup did not finish within two minutes.'
    }
    if ($setup.ExitCode -ne 0) {
        if (Test-Path "$env:TEMP/Gecko-install.log") { Get-Content "$env:TEMP/Gecko-install.log" -Tail 60 }
        throw "Installer returned $($setup.ExitCode). See $env:TEMP/Gecko-install.log"
    }
}
try {
    if (-not (Test-Path "$destination/Gecko.exe")) { throw 'The installed executable is missing.' }
    Add-Type @'
using System;
using System.Runtime.InteropServices;
public static class InstallerLoader {
    [DllImport("kernel32", CharSet=CharSet.Unicode, SetLastError=true)]
    public static extern IntPtr LoadLibraryEx(string file, IntPtr reserved, uint flags);
    [DllImport("kernel32")]
    public static extern bool FreeLibrary(IntPtr module);
}
'@
    # Search the installed DLL's directory and Windows defaults, excluding PATH.
    # This prevents a developer toolchain on PATH from hiding missing runtime files.
    Get-ChildItem $destination -Filter '*.dll' | ForEach-Object {
        $module = [InstallerLoader]::LoadLibraryEx($_.FullName, [IntPtr]::Zero, 0x1100)
        if ($module -eq [IntPtr]::Zero) {
            throw "Cannot load $($_.Name): Win32 error $([Runtime.InteropServices.Marshal]::GetLastWin32Error())"
        }
        [void][InstallerLoader]::FreeLibrary($module)
    }
    if ($LaunchFixture) {
        $env:Path = "$env:SystemRoot/System32;$env:SystemRoot"
        & "$destination/Gecko.exe"
        if ($LASTEXITCODE -ne 0) { throw "Runtime fixture failed: $LASTEXITCODE" }
    }
} finally {
    $uninstaller = Start-Process "$destination/unins000.exe" -ArgumentList '/VERYSILENT /SUPPRESSMSGBOXES /NORESTART' -PassThru
    if (-not $uninstaller.WaitForExit(60000)) { throw 'Uninstall timed out.' }
    if ($uninstaller.ExitCode -ne 0) { throw "Uninstall failed: $($uninstaller.ExitCode)" }
}
