import FoundationEssentials

/// A codable struct that's utilized for storing logs.
struct LogMessage: Codable {
    /// The session identifier this message is associated with.
    let sessionIdentifier: UUID

    /// The raw text to store.
    let value: String

    /// The level of the log.
    let level: LogLevel

    /// The timestamp of the log.
    let timestamp = Date()

    /// Any metadata to associate with the log.
    let metadata: [String: String]?
}