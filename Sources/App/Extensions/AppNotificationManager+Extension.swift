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
        do {
            try show(notification.materialize())
        } catch {
            debugPrint(error)
        }
    }

    func update(data: AppNotificationProgressData, in notification: UI.ProgressNotification) {
        do {
            _ = try updateAsync(data, notification.id)
        } catch {
            debugPrint(error)
        }
    }

    func dismiss(id: String) {
        do {
            try removeByTagAsync(id)
        } catch {
            debugPrint(error)
        }
    }
}