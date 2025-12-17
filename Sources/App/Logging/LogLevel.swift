import FoundationEssentials

/// Describes the different log levels that the logger accepts.
enum LogLevel: Int, Codable, CaseIterable {
    /// No logs are reported or recorded to disk.
    case none = 0
    
     /// The level suitable for critical errors.
    /// - Note: Logs at this level are persisted to disk.
    case critical = 1

    /// The level suitable for warnings.
    /// - Note: Logs at this level are persisted to disk.
    case warning = 2

    /// A log level suitable for debugging.
    /// - Note: Logs at this level are *not* persisted to disk.
    case debug = 3
}