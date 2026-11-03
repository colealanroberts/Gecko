param(
    [Parameter(Mandatory)][string]$Version,
    [string]$BuildDirectory
)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$Version = $Version -replace '^v', ''
if ($Version -notmatch '^\d+\.\d+\.\d+(?:-[0-9A-Za-z.-]+)?$') { throw 'Version must be MAJOR.MINOR.PATCH with an optional prerelease suffix.' }
$root = Split-Path $PSScriptRoot -Parent
if (-not $BuildDirectory) {
    $BuildDirectory = (& swift build -c release --show-bin-path | Select-Object -Last 1)
    if ($LASTEXITCODE -ne 0) { throw 'Unable to locate the release build.' }
}
$BuildDirectory = (Resolve-Path $BuildDirectory).Path
if (-not (Test-Path "$BuildDirectory/Gecko.exe")) { throw 'Build Gecko in release mode before packaging.' }
$dist = Join-Path $root 'dist'
$stage = Join-Path $dist 'installer/app'
$redist = Join-Path $dist 'installer/redist'
# Only clear this script's staging directory; retain other release artifacts.
if (Test-Path "$dist/installer") { Remove-Item "$dist/installer" -Recurse -Force }
New-Item -ItemType Directory -Force $stage, $redist | Out-Null
Copy-Item "$BuildDirectory/Gecko.exe" $stage
Get-ChildItem $BuildDirectory -Filter '*.dll' | Copy-Item -Destination $stage
Get-ChildItem $BuildDirectory -Directory | Where-Object { $_.Name -match '\.(resources|bundle)$' } | Copy-Item -Destination $stage -Recurse
Copy-Item "$root/LICENSE" $stage
$bootstrap = "$root/Dependencies/swift-windowsappsdk/Sources/CWinAppSDK/nuget/bin/Microsoft.WindowsAppRuntime.Bootstrap.dll"
if (Test-Path $bootstrap) { Copy-Item $bootstrap $stage -Force }

# Resolve the transitive PE import graph, not the compiler's entire bin folder.
$dumpbin = Get-Command dumpbin.exe -ErrorAction SilentlyContinue
if (-not $dumpbin) {
    $vswhere = "${env:ProgramFiles(x86)}/Microsoft Visual Studio/Installer/vswhere.exe"
    $dumpbin = & $vswhere -latest -products '*' -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -find 'VC/Tools/MSVC/**/bin/Hostx64/x64/dumpbin.exe' | Select-Object -Last 1
} else { $dumpbin = $dumpbin.Source }
if (-not $dumpbin) { throw 'The Visual C++ x64 tools (dumpbin.exe) are required.' }
$target = & swift -print-target-info | ConvertFrom-Json
if ($LASTEXITCODE -ne 0 -or $target.target.triple -notlike 'x86_64-*-windows-msvc*') { throw 'Packaging requires the Swift Windows x64 toolchain.' }
$search = @($BuildDirectory, (Split-Path (Get-Command swift.exe).Source)) + @($target.paths.runtimeLibraryPaths) + @($env:Path -split ';')
if ($env:SDKROOT) { $search += @("$env:SDKROOT/usr/bin", "$env:SDKROOT/usr/bin/x86_64") }
$search = $search | Where-Object { $_ -and (Test-Path $_ -PathType Container) } | Select-Object -Unique
$queue = [Collections.Generic.Queue[string]]::new()
Get-ChildItem $stage -File | Where-Object { $_.Extension -in '.exe', '.dll' } | ForEach-Object { $queue.Enqueue($_.FullName) }
$seen = @{}
while ($queue.Count) {
    $file = $queue.Dequeue()
    $imports = & $dumpbin /nologo /dependents $file
    if ($LASTEXITCODE -ne 0) { throw "Cannot inspect PE imports: $file" }
    foreach ($line in $imports) {
        if ($line -notmatch '^\s+([^\s]+\.dll)\s*$') { continue }
        $name = $Matches[1]
        if ($seen.ContainsKey($name)) { continue }
        $seen[$name] = $true
        $destination = Join-Path $stage $name
        if (-not (Test-Path $destination)) {
            # Windows system components and API sets stay on the operating system.
            if ($name -match '^(api-ms-|ext-ms-)' -or (Test-Path "$env:SystemRoot/System32/$name")) { continue }
            $source = $search | ForEach-Object { Join-Path $_ $name } | Where-Object { Test-Path $_ -PathType Leaf } | Select-Object -First 1
            if (-not $source) { throw "Unresolved runtime DLL '$name' imported by '$file'." }
            Copy-Item $source $destination
        }
        $queue.Enqueue($destination)
    }
}

# Retain the license notices for the bundled native bindings and Swift runtime.
$licenses = New-Item -ItemType Directory -Force "$stage/licenses"
Get-ChildItem "$root/Dependencies" -Directory -Filter 'swift-*' | ForEach-Object {
    foreach ($name in @('LICENSE', 'LICENSE.txt', 'NOTICE', 'NOTICE.txt')) {
        if (Test-Path "$($_.FullName)/$name") { Copy-Item "$($_.FullName)/$name" "$licenses/$($_.Name)-$name" }
    }
}
$swiftVersion = (& swift --version | Select-Object -First 1)
if ($swiftVersion -notmatch 'Swift version (\d+\.\d+(?:\.\d+)?)') { throw 'Cannot determine the Swift runtime version.' }
$swiftTag = "swift-$($Matches[1])-RELEASE"
foreach ($name in @('LICENSE.txt')) {
    Invoke-WebRequest "https://raw.githubusercontent.com/swiftlang/swift/$swiftTag/$name" -OutFile "$licenses/Swift-$name"
}
$downloads = @{
    'vc_redist.x64.exe' = 'https://aka.ms/vs/17/release/vc_redist.x64.exe'
    'WindowsAppRuntimeInstall-x64.exe' = 'https://aka.ms/windowsappsdk/1.7/1.7.250909003/windowsappruntimeinstall-x64.exe'
}
foreach ($name in $downloads.Keys) {
    $file = Join-Path $redist $name
    Invoke-WebRequest $downloads[$name] -OutFile $file
    $signature = Get-AuthenticodeSignature $file
    if ($signature.Status -ne 'Valid' -or $signature.SignerCertificate.Subject -notmatch 'O=Microsoft Corporation(?:,|$)') {
        throw "Invalid Microsoft signature on prerequisite: $name"
    }
}
$iscc = Get-Command ISCC.exe -ErrorAction SilentlyContinue
if ($iscc) { $iscc = $iscc.Source } else { $iscc = "${env:ProgramFiles(x86)}/Inno Setup 6/ISCC.exe" }
if (-not (Test-Path $iscc)) { throw 'Install Inno Setup 6 and add ISCC.exe to PATH.' }
& $iscc "/DAppVersion=$Version" "/DStageDir=$stage" "/DRedistDir=$redist" "/DOutputDir=$dist" "$root/Installer/Gecko.iss"
if ($LASTEXITCODE -ne 0) { throw 'Installer compilation failed.' }
Get-FileHash "$dist/GeckoSetup.exe" -Algorithm SHA256 | ForEach-Object { "$($_.Hash.ToLower())  GeckoSetup.exe" } | Set-Content "$dist/GeckoSetup.exe.sha256" -Encoding ascii
Write-Host "Installer: $dist/GeckoSetup.exe"
