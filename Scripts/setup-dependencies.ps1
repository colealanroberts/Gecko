$ErrorActionPreference = 'Stop'
$root = Join-Path $PSScriptRoot '../Dependencies'
New-Item -ItemType Directory -Force $root | Out-Null
$stamp = Join-Path $root 'setup.sha256'
$scriptHash = (Get-FileHash $PSCommandPath -Algorithm SHA256).Hash
if ((Test-Path $stamp) -and (Get-Content $stamp) -eq $scriptHash) { return }

# SwiftWinRT 0.6 projections require sibling checkouts. Keep the set pinned.
$revisions = [ordered]@{
    'swift-cwinrt' = 'eb46cdb66f770a1e006f9fcfebbf9e99a0fba811'
    'swift-windowsfoundation' = '1efad430c4920d80d063bfaa526dd011d8ee8379'
    'swift-uwp' = 'd1a96986570189f8aa9ed089e9c4dab3c96e688c'
    'swift-windowsappsdk' = '317527def617c5b7b3153380a85390bf7d3ec5b2'
}
foreach ($name in $revisions.Keys) {
    $destination = Join-Path $root $name
    if (-not (Test-Path $destination)) {
        git clone "https://github.com/thebrowsercompany/$name.git" $destination
        if ($LASTEXITCODE -ne 0) { throw "Clone failed: $name" }
    }
    $changes = git -C $destination status --porcelain
    if ($LASTEXITCODE -ne 0 -or $changes) {
        throw "Dependency is not clean: $destination. Use a fresh Dependencies directory; local changes will not be overwritten."
    }
    git -C $destination fetch origin $revisions[$name]
    if ($LASTEXITCODE -ne 0) { throw "Fetch failed: $name" }
    git -C $destination checkout --detach $revisions[$name]
    if ($LASTEXITCODE -ne 0) { throw "Checkout failed: $name" }
}

# Upstream's snapshot omits AppNotifications. Generate a consistent set of
# projections, including its dependent collection types, using the pinned tool.
$packages = Join-Path $root '.packages'
$nuget = Join-Path $root 'nuget.exe'
if (-not (Test-Path $nuget)) {
    Invoke-WebRequest 'https://dist.nuget.org/win-x86-commandline/v6.12.1/nuget.exe' -OutFile $nuget
}
$packageVersions = [ordered]@{
    'TheBrowserCompany.SwiftWinRT' = '0.6.0'
    'Microsoft.WindowsAppSDK' = '1.7.250909003'
    'Microsoft.Windows.SDK.Contracts' = '10.0.18362.2005'
    'Microsoft.Web.WebView2' = '1.0.2903.40'
}
foreach ($name in $packageVersions.Keys) {
    & $nuget install $name -Version $packageVersions[$name] -OutputDirectory $packages -NonInteractive -Source 'https://api.nuget.org/v3/index.json'
    if ($LASTEXITCODE -ne 0) { throw "NuGet restore failed: $name" }
}
$output = Join-Path $root '.generated'
$arguments = @("-output `"$output`"")
$includes = @('Microsoft.Windows.AppNotifications', 'Microsoft.Windows.AppNotifications.Builder')
$excludes = @()
foreach ($name in @('swift-windowsfoundation', 'swift-uwp', 'swift-windowsappsdk')) {
    $projection = Get-Content (Join-Path $root "$name/projections.json") -Raw | ConvertFrom-Json
    $includes += $projection.include
    $excludes += $projection.exclude
}
$includes | Select-Object -Unique | ForEach-Object { $arguments += "-include $_" }
$excludes | Select-Object -Unique | ForEach-Object { $arguments += "-exclude $_" }
foreach ($name in @('Microsoft.WindowsAppSDK', 'Microsoft.Windows.SDK.Contracts', 'Microsoft.Web.WebView2')) {
    Get-ChildItem (Join-Path $packages "$name.$($packageVersions[$name])") -Recurse -Filter '*.winmd' | ForEach-Object {
        $arguments += "-input `"$($_.FullName)`""
    }
}
$responseFile = Join-Path $root 'swift-winrt.rsp'
$arguments | Set-Content $responseFile -Encoding ascii
& (Join-Path $packages 'TheBrowserCompany.SwiftWinRT.0.6.0/bin/swiftwinrt.exe') "@$responseFile"
if ($LASTEXITCODE -ne 0) { throw 'SwiftWinRT generation failed' }
foreach ($pair in @(
    @('swift-cwinrt', 'CWinRT'),
    @('swift-windowsfoundation', 'WindowsFoundation'),
    @('swift-uwp', 'UWP'),
    @('swift-windowsappsdk', 'WinAppSDK')
)) {
    $source = Join-Path $output "Sources/$($pair[1])"
    if (-not (Test-Path $source)) { throw "Missing generated module: $($pair[1])" }
    $destination = Join-Path $root "$($pair[0])/Sources/$($pair[1])"
    if ($pair[1] -ne 'CWinRT') { $destination = Join-Path $destination 'Generated' }
    if (Test-Path $destination) { Remove-Item $destination -Recurse -Force }
    Copy-Item $source $destination -Recurse -Force
}
# The upstream snapshot includes an ARM64 bootstrap DLL alongside x64 import
# libraries. Use the x64 asset matching Gecko's supported architecture.
$sdk = Join-Path $root 'swift-windowsappsdk/Sources/CWinAppSDK/nuget'
Copy-Item (Join-Path $packages 'Microsoft.WindowsAppSDK.1.7.250909003/runtimes/win-x64/native/Microsoft.WindowsAppRuntime.Bootstrap.dll') (Join-Path $sdk 'bin') -Force
$scriptHash | Set-Content $stamp
