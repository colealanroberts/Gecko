import FoundationEssentials

/// Represents an operating system.
struct OperatingSystemResponse: Decodable {
    /// The operating system identifier - e.g. `56`.
    let id: String

    /// The operating system code - e.g. `10.0`.
    let code: String

    /// The human-readable name - e.g. `Windows 11`
    let name: String
}