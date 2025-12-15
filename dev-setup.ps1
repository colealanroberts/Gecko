# Development Setup Script
# Copies required runtime DLLs to debug build directory

$ErrorActionPreference = "Stop"

$WinAppSDKDLL = "D:\Development\Workspace\swift-windowsappsdk\.packages\Microsoft.WindowsAppSDK.1.7.250909003\runtimes\win-x64\native\Microsoft.WindowsAppRuntime.Bootstrap.dll"
$DebugDir = ".\.build\x86_64-unknown-windows-msvc\debug"

Write-Host "Setting up development environment..." -ForegroundColor Cyan

# Create debug directory if it doesn't exist
if (-not (Test-Path $DebugDir)) {
    New-Item -ItemType Directory -Path $DebugDir -Force | Out-Null
    Write-Host "Created debug directory" -ForegroundColor Green
}

# Copy Windows App SDK Bootstrap DLL
if (Test-Path $WinAppSDKDLL) {
    Copy-Item $WinAppSDKDLL $DebugDir -Force
    Write-Host "[OK] Copied Microsoft.WindowsAppRuntime.Bootstrap.dll" -ForegroundColor Green
} else {
    Write-Host "[ERROR] Could not find $WinAppSDKDLL" -ForegroundColor Red
    exit 1
}

Write-Host "`nDevelopment environment ready!" -ForegroundColor Cyan
Write-Host "You can now run: swift build && .\.build\x86_64-unknown-windows-msvc\debug\Gecko.exe"
