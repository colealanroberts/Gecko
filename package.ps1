# Gecko Packaging Script
# Creates a distributable package with minimal Swift runtime dependencies

param(
    [switch]$IncludeICU = $false,
    [string]$OutputDir = ".\dist"
)

$ErrorActionPreference = "Stop"

$SwiftRuntimeDir = "C:\Users\16086\AppData\Local\Programs\Swift\Runtimes\6.2.2\usr\bin"
$BuildDir = ".\.build\x86_64-unknown-windows-msvc\release"
$WinAppSDKDir = "D:\Development\Workspace\swift-windowsappsdk\.packages\Microsoft.WindowsAppSDK.1.7.250909003\runtimes\win-x64\native"

# Core Swift runtime DLLs (always required)
$CoreDLLs = @(
    "swiftCore.dll",
    "swiftCRT.dll",
    "swift_Concurrency.dll",
    "BlocksRuntime.dll",
    "dispatch.dll",
    "swiftDispatch.dll",
    "swiftWinSDK.dll"
)

# Foundation DLLs (required for your app since you use FoundationEssentials & FoundationNetworking)
$FoundationDLLs = @(
    "FoundationEssentials.dll",
    "FoundationNetworking.dll",
    "Foundation.dll"
)

# ICU and internationalization DLLs (35 MB+ - optional if no i18n needed)
$ICUDLLs = @(
    "_FoundationICU.dll",              # 35 MB
    "FoundationInternationalization.dll" # 1.6 MB
)

# Regex support (optional - only if you use regex in your code)
$RegexDLLs = @(
    "swift_RegexParser.dll",
    "swift_StringProcessing.dll",
    "swiftRegexBuilder.dll"
)

# Microsoft Visual C++ Runtime (required)
$MSVCDLLs = @(
    "msvcp140.dll",
    "msvcp140_1.dll",
    "msvcp140_2.dll",
    "msvcp140_atomic_wait.dll",
    "msvcp140_codecvt_ids.dll",
    "vcruntime140.dll",
    "vcruntime140_1.dll",
    "vcruntime140_threads.dll",
    "concrt140.dll"
)

# Your custom libraries (from build output)
$CustomDLLs = @(
    "WindowsFoundation.dll",
    "WinAppSDK.dll",
    "CWinRT.dll"
)

# Windows App SDK runtime DLLs (from nuget package)
$WinAppSDKDLLs = @(
    "Microsoft.WindowsAppRuntime.Bootstrap.dll"
)

# Create output directory
Write-Host "Creating distribution package in: $OutputDir" -ForegroundColor Cyan
if (Test-Path $OutputDir) {
    Remove-Item $OutputDir -Recurse -Force
}
New-Item -ItemType Directory -Path $OutputDir | Out-Null

# Copy executable
Write-Host "`nCopying Gecko.exe..." -ForegroundColor Green
Copy-Item "$BuildDir\Gecko.exe" $OutputDir

# Copy custom DLLs
Write-Host "Copying custom libraries..." -ForegroundColor Green
foreach ($dll in $CustomDLLs) {
    $source = Join-Path $BuildDir $dll
    if (Test-Path $source) {
        Copy-Item $source $OutputDir
        Write-Host "  [OK] $dll" -ForegroundColor Gray
    } else {
        Write-Host "  [SKIP] $dll (not found)" -ForegroundColor Yellow
    }
}

# Copy Windows App SDK DLLs
Write-Host "`nCopying Windows App SDK runtime..." -ForegroundColor Green
foreach ($dll in $WinAppSDKDLLs) {
    $source = Join-Path $WinAppSDKDir $dll
    if (Test-Path $source) {
        Copy-Item $source $OutputDir
        $size = (Get-Item $source).Length
        $totalSize += $size
        $sizeKB = [math]::Round($size / 1KB, 0)
        Write-Host "  [OK] $dll (${sizeKB} KB)" -ForegroundColor Gray
    } else {
        Write-Host "  [ERROR] $dll (not found at $WinAppSDKDir)" -ForegroundColor Red
        Write-Host "  The app will NOT launch without this DLL!" -ForegroundColor Red
    }
}

# Copy Swift core runtime DLLs
Write-Host "`nCopying Swift core runtime..." -ForegroundColor Green
$totalSize = 0
foreach ($dll in $CoreDLLs) {
    $source = Join-Path $SwiftRuntimeDir $dll
    if (Test-Path $source) {
        Copy-Item $source $OutputDir
        $size = (Get-Item $source).Length
        $totalSize += $size
        $sizeKB = [math]::Round($size / 1KB, 0)
        Write-Host "  [OK] $dll (${sizeKB} KB)" -ForegroundColor Gray
    } else {
        Write-Host "  ✗ $dll (not found)" -ForegroundColor Yellow
    }
}

# Copy Foundation DLLs
Write-Host "`nCopying Foundation libraries..." -ForegroundColor Green
foreach ($dll in $FoundationDLLs) {
    $source = Join-Path $SwiftRuntimeDir $dll
    if (Test-Path $source) {
        Copy-Item $source $OutputDir
        $size = (Get-Item $source).Length
        $totalSize += $size
        $sizeMB = [math]::Round($size / 1MB, 1)
        Write-Host "  [OK] $dll (${sizeMB} MB)" -ForegroundColor Gray
    } else {
        Write-Host "  ✗ $dll (not found)" -ForegroundColor Yellow
    }
}

# Copy ICU DLLs (optional)
if ($IncludeICU) {
    Write-Host "`nCopying ICU and internationalization libraries..." -ForegroundColor Green
    foreach ($dll in $ICUDLLs) {
        $source = Join-Path $SwiftRuntimeDir $dll
        if (Test-Path $source) {
            Copy-Item $source $OutputDir
            $size = (Get-Item $source).Length
            $totalSize += $size
            $sizeMB = [math]::Round($size / 1MB, 1)
            Write-Host "  [OK] $dll (${sizeMB} MB)" -ForegroundColor Gray
        } else {
            Write-Host "  ✗ $dll (not found)" -ForegroundColor Yellow
        }
    }
} else {
    Write-Host "`nSkipping ICU libraries (35+ MB saved)" -ForegroundColor Yellow
    Write-Host "  Note: If app crashes, you may need ICU. Run with -IncludeICU flag" -ForegroundColor Yellow
}

# Copy Regex DLLs (optional but recommended)
Write-Host "`nCopying regex support libraries..." -ForegroundColor Green
foreach ($dll in $RegexDLLs) {
    $source = Join-Path $SwiftRuntimeDir $dll
    if (Test-Path $source) {
        Copy-Item $source $OutputDir
        $size = (Get-Item $source).Length
        $totalSize += $size
        $sizeKB = [math]::Round($size / 1KB, 0)
        Write-Host "  [OK] $dll (${sizeKB} KB)" -ForegroundColor Gray
    } else {
        Write-Host "  ✗ $dll (not found)" -ForegroundColor Yellow
    }
}

# Copy MSVC runtime DLLs
Write-Host "`nCopying Microsoft Visual C++ Runtime..." -ForegroundColor Green
foreach ($dll in $MSVCDLLs) {
    $source = Join-Path $SwiftRuntimeDir $dll
    if (Test-Path $source) {
        Copy-Item $source $OutputDir
        $size = (Get-Item $source).Length
        $totalSize += $size
        Write-Host "  [OK] $dll" -ForegroundColor Gray
    } else {
        Write-Host "  [SKIP] $dll (not found)" -ForegroundColor Yellow
    }
}

# Add custom DLL sizes to total
foreach ($dll in $CustomDLLs) {
    $path = Join-Path $BuildDir $dll
    if (Test-Path $path) {
        $totalSize += (Get-Item $path).Length
    }
}
$totalSize += (Get-Item "$BuildDir\Gecko.exe").Length

# Summary
Write-Host "`n" + ("=" * 60) -ForegroundColor Cyan
Write-Host "Package created successfully!" -ForegroundColor Green
Write-Host ("=" * 60) -ForegroundColor Cyan

$totalMB = [math]::Round($totalSize / 1MB, 1)
$fileCount = (Get-ChildItem $OutputDir).Count

Write-Host "Location: $OutputDir"
Write-Host "Total size: $totalMB MB"
Write-Host "File count: $fileCount files"

if (-not $IncludeICU) {
    Write-Host "`nICU NOT included - saved ~40 MB" -ForegroundColor Yellow
    Write-Host "If the app fails to run, try: .\package.ps1 -IncludeICU" -ForegroundColor Yellow
}

Write-Host "`nTo test the package:"
Write-Host "  cd $OutputDir"
Write-Host "  .\Gecko.exe"
