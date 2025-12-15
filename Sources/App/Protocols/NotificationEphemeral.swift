// MARK: - NotificationEphemeral

/// A contract that specifies whether notifications are cleared on reboot.
/// - Note: The default conformance is `true`.
protocol NotificationEphemeral {
    /// Whether the notification persists in the notification center after a restart.
    var expiresOnReboot: Bool { get }
}

// MARK: - NotificationEphemeral+Util

extension NotificationEphemeral {
    var expiresOnReboot: Bool { true }
}