
import WinAppSDK

// MARK: - NotificationMaterializable

protocol NotificationMaterializable: NotificationEphemeral {
    /// A concrete builder (`AppNotificationBuilder`).
    var builder: AppNotificationBuilder { get }

    /// Materializes a native notification (`AppNotification`).
    func materialize() -> AppNotification
}

// MARK: NotificationMaterializable+Util

extension NotificationMaterializable {
    func materialize() -> AppNotification {
        let notification = builder.build()
        notification.expiresOnReboot = expiresOnReboot

        return notification
    }
}