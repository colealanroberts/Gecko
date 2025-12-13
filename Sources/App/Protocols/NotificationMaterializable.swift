
import WinAppSDK

// MARK: - NotificationMaterializable

protocol NotificationMaterializable {
    /// A concrete builder (`AppNotificationBuilder`).
    var builder: AppNotificationBuilder { get }

    /// Materializes a native notification (`AppNotification`).
    func materialize() -> AppNotification
}

// MARK: NotificationMaterializable+Util

extension NotificationMaterializable {
    func materialize() -> AppNotification {
        try! builder.buildNotification()
    }
}