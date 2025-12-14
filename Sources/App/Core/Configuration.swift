import Foundation

/// Allows user-configurable properties Gecko. 
/// - Note: If necessary, a `config.json` file is written to disk with the 
/// values found in the `default` property - these are then configurable by a user.
struct Configuration: Codable {

    /// MARK: - Public Properties

    /// Whether logging is enabled.
    /// - Note: The default value is `false`.
    let isLoggingEnabled: Bool

    /// How often updates are checked in seconds.
    /// - Note: 
    ///  - The default value is 12 hours or `43_200` seconds. However, this value is discarded if a reboot occurs.
    ///  - The value here is internally clamped to 5 minutes (`300`) and 1 week (`604800`) and the value you provide.
    ///  - Negative numbers are discarded - clamping to lower bound.
    let updateCheckInterval: Int
    
    /// Internal flag to track if any values were missing during decoding.
    /// - Note: This is *not* persisted to the configuration file.
    private(set) var containsIncompletes: Bool = false

    // MARK: - Init

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let _isLoggingEnabled = try container.decodeIfPresent(Bool.self, forKey: .isLoggingEnabled)
        let _updateCheckInterval = try container.decodeIfPresent(Int.self, forKey: .updateCheckInterval)

        // We'll capture the default config, loading these values in place *if* the `config.json` file
        // is missing or incomplete.
        let initial = Configuration.default
        let updateCheckInterval = _updateCheckInterval ?? initial.updateCheckInterval

        self.isLoggingEnabled = _isLoggingEnabled ?? initial.isLoggingEnabled
        self.updateCheckInterval = updateCheckInterval.clamped(from: .fiveMinutes, to: .oneWeek)
        self.containsIncompletes = _isLoggingEnabled == nil || _updateCheckInterval == nil
    }

    private init(
        isLoggingEnabled: Bool,
        updateCheckInterval: Int
    ) {
        self.isLoggingEnabled = isLoggingEnabled
        self.updateCheckInterval = updateCheckInterval
    }

    /// MARK: - Utility 
    
    static var `default`: Self {
        .init(
            isLoggingEnabled: false,
            updateCheckInterval: 43_200
        )
    }
}

// MARK: - Configuration+CodingKeys

private extension Configuration {
    enum CodingKeys: String, CodingKey {
        case isLoggingEnabled, updateCheckInterval
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