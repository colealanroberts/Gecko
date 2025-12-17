# Gecko

A lightweight Windows desktop utility that automatically checks for Nvidia driver updates and provides one-click downloads through native notifications. Written in Swift.

## Requirements

- Windows 10+
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
    "logLevel": 0, // None
    "updateCheckInterval": 43200, // 12 hours
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

Requires https://www.swift.org/install/windows/ (5.9+):

```
git clone https://github.com/colealanroberts/Gecko.git
cd Gecko
swift build -c release
```

## License

Gecko is available under the MIT license. See LICENSE for details.

## Contact

Cole Roberts
https://github.com/colealanroberts