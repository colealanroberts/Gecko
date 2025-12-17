import FoundationEssentials

/// Allows user-configurable properties Gecko. 
/// - Note: If necessary, a `config.json` file is written to disk with the 
/// values found in the `default` property - these are then configurable by a user.
struct Configuration: Codable {

    /// MARK: - Public Properties

    /// The logging level of the application.
    /// - Note: The default value is `none`.
    let logLevel: LogLevel

    /// How often updates are checked in seconds.
    /// - Note: 
    ///  - The default value is 12 hours or `43_200` seconds. However, this value is discarded if a reboot occurs.
    ///  - The value here is internally clamped to 5 minutes (`300`) and 1 week (`604800`) and the value you provide.
    ///  - Negative numbers are discarded - clamping to lower bound.
    let updateCheckInterval: Int

    /// Whether Gecko should run on system boot.
    /// - Note: The default value is `true`.
    let shouldLaunchAtStartup: Bool
    
    /// Internal flag to track if any values were missing during decoding.
    /// - Note: This is *not* persisted to the configuration file.
    private(set) var containsIncompletes: Bool = false

    // MARK: - Init

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let _logLevel = try container.decodeIfPresent(LogLevel.self, forKey: .logLevel)
        let _updateCheckInterval = try container.decodeIfPresent(Int.self, forKey: .updateCheckInterval)
        let _shouldLaunchAtStartup = try container.decodeIfPresent(Bool.self, forKey: .shouldLaunchAtStartup)

        // We'll capture the default config, loading these values in place *if* the `config.json` file
        // is missing or incomplete.
        let initial = Configuration.default
        let updateCheckInterval = _updateCheckInterval ?? initial.updateCheckInterval

        self.logLevel = _logLevel ?? initial.logLevel
        self.updateCheckInterval = updateCheckInterval.clamped(from: .fiveMinutes, to: .oneWeek)
        self.shouldLaunchAtStartup = _shouldLaunchAtStartup ?? initial.shouldLaunchAtStartup

        self.containsIncompletes = _logLevel == nil || _updateCheckInterval == nil || _shouldLaunchAtStartup == nil
    }

    private init(
        logLevel: LogLevel,
        updateCheckInterval: Int,
        shouldLaunchAtStartup: Bool
    ) {
        self.logLevel = logLevel
        self.updateCheckInterval = updateCheckInterval
        self.shouldLaunchAtStartup = shouldLaunchAtStartup
    }

    /// MARK: - Utility 
    
    static var `default`: Self {
        .init(
            logLevel: .none,
            updateCheckInterval: 43_200,
            shouldLaunchAtStartup: true
        )
    }
}

// MARK: - Configuration+CodingKeys

private extension Configuration {
    enum CodingKeys: String, CodingKey {
        case logLevel, updateCheckInterval, shouldLaunchAtStartup
    }
}

// MARK: - UInt+Extension

private extension Int {
    /// Five minutes in seconds.
    static let fiveMinutes: Self = 300

    /// One week in seconds.
    static let oneWeek: Self = 604_800

    func clamped(from lower: Self, to upper: Self) -> Self {
        Swift.min(Swift.max(self, lower), upper)
    }
}