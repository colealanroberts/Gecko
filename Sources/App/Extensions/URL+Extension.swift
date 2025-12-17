import FoundationEssentials

extension URL {
    /// The base directory for all Gecko-related files.
    static var geckoDirectory: Self {
        // Default location: %APPDATA%\Local\Gecko\config.json.
        let supportDirectory = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        )[0]

        return supportDirectory.appendingPathComponent(
            "Gecko", 
            isDirectory: true
        )
    }
}