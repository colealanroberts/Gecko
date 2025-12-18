
import WinAppSDK

// MARK: - NotificationMaterializable

protocol NotificationMaterializable: (Identifiable & NotificationEphemeral) {
    /// A concrete builder (`AppNotificationBuilder`).
    var builder: AppNotificationBuilder { get }

    /// Materializes a native notification (`AppNotification`).
    func materialize() -> AppNotification
}

// MARK: NotificationMaterializable+Util

extension NotificationMaterializable where ID == String {
    func materialize() -> AppNotification {
        let notification = builder
            .tag(id)
            .build()

        notification.expiresOnReboot = expiresOnReboot

        return notification
    }
}