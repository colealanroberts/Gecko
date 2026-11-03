# Gecko

A lightweight Windows desktop utility that automatically checks for Nvidia driver updates and provides one-click downloads through native notifications. Written in Swift.

## Requirements

- Windows 10+ (x64)
- Windows App Runtime 1.7 (x64)
- Nvidia GPU

## Installation

Download the latest release from the [Releases](https://github.com/colealanroberts/Gecko/releases) page and run the executable. Gecko runs in the background and will notify you when new drivers are available.

### Configuration

Gecko stores its configuration in `%APPDATA%\Local\Gecko\config.json`. You can customize:

- `logLevel` - Logging verbosity: `debug`, `info`, `warning`, or `critical`.
- `updateCheckInterval` - How often to check for updates in seconds.
- `shouldLaunchAtStartup` - Whether Gecko should run on system boot.

**Example Configuration:**
```json
{
    "logLevel": 0,
    "updateCheckInterval": 43200,
    "shouldLaunchAtStartup": true
}
```

## How It Works

Gecko automatically detects your GPU and Windows version, then queries Nvidia's official API for driver availability. When a new driver is found, you'll receive a native Windows notification with version details and the option to download.

**Features:**
- Non-intrusive native Windows notifications
- Automatic GPU detection via WMI
- Simple customization via JSON config
- Lightweight background process

## Contributing

Contributions to Gecko are welcomed! 

If you would like to report a bug, discuss the current state of the code, submit a fix, or propose a new feature, please use GitHub's Issues or Pull Request features.

## Building from Source

Requires [Swift for Windows](https://www.swift.org/install/windows/) (6.2.1+), Git, PowerShell 7, and the Windows App Runtime 1.7 (x64).

Run in PowerShell from a path without spaces (the upstream SwiftWinRT toolchain may not support paths with spaces):

```
git clone https://github.com/colealanroberts/Gecko.git
cd Gecko
pwsh -File Scripts/setup-dependencies.ps1
swift build -c release
```

The setup script downloads pinned projection repositories and NuGet packages into the ignored `Dependencies/` directory and generates the notification bindings missing from upstream's checked-in snapshot. Re-running a completed setup is a no-op. If the setup script changes, use a fresh `Dependencies/` directory; it refuses to overwrite modified dependency checkouts.

Keep the generated DLLs and resource directories beside the executable when distributing a build. The bootstrap DLL must also be beside `Gecko.exe` (copy it from `Dependencies/swift-windowsappsdk/Sources/CWinAppSDK/nuget/bin`).

### Tests

On macOS, run `python3 Scripts/test.py`. This builds the platform-independent sources and runs unit and HTTP integration tests against a local server, including cancellation, HTTP failures, filesystem failures, progress, and unknown content lengths. `swift test` alone skips HTTP tests unless `GECKO_TEST_SERVER` is set. CI also builds the full Windows executable. Native notification interaction requires a Windows smoke test.

## License

Gecko is available under the MIT license. See LICENSE for details.

## Contact

Cole Roberts
https://github.com/colealanroberts