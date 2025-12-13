import Foundation
import CWinRT
import WinAppSDK
import WindowsFoundation

extension AppNotificationManager {
    func present(_ notification: GeckoNotification) {
        do {
            try show(notification.materialize())
        } catch {
            print(error.localizedDescription)
        }
    }

    func update(data: AppNotificationProgressData, in notification: UI.ProgressNotification) {
        do {
            _ = try updateAsync(data, notification.tag)
        } catch {
            print(error.localizedDescription)
        }
    }
}