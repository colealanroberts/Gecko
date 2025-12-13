import Foundation

// MARK: - NotificationEphemeral

protocol NotificationEphemeral {
    /// Whether the notification persists in the notification center after a restart.
    var expiresOnReboot: Bool { get }
}

// MARK: - NotificationEphemeral+Util

extension NotificationEphemeral {
    var expiresOnReboot: Bool { true }
}