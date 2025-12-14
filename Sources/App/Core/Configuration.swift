import Foundation

/// Allows user-configurable properties Gecko. 
/// - Note: If necessary, a `config.json` file is written to disk with the 
/// values found in the `default` property - these are then configurable by a user.
struct Configuration: Codable {

    /// MARK: - Properties

    /// Whether logging is enabled.
    /// - Note: The default value is `false`.
    let isLoggingEnabled: Bool

    /// MARK: - Utility 
    
    static var `default`: Self {
        .init(isLoggingEnabled: false)
    }
}