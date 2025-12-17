import WinAppSDK

extension AppNotificationManager {
    var isSupported: Bool {
        do {
            return try Self.isSupported()
        } catch {
            return false
        }
    }

    func present(_ notification: GeckoNotification) {
        try! show(notification.materialize())
        do {
            try show(notification.materialize())
        } catch {
            debugPrint(error)
        }
    }

    func update(data: AppNotificationProgressData, in notification: UI.ProgressNotification) {
        do {
            _ = try updateAsync(data, notification.tag)
        } catch {
            debugPrint(error)
        }
    }
}