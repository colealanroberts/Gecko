import Foundation
import CWinRT
import WinAppSDK
import WindowsFoundation

// MARK: - NotificationPresenting

protocol NotificationPresenting {
    /// Presents a notification in the native Windows sidebar.
    func present(_ notification: GeckoNotification)

    /// Updates a progress bar for the specified notification.
    func update(data: AppNotificationProgressData, in notification: UI.ProgressNotification)
}

// MARK: - NotificationPresenter

final class NotificationPresenter: NotificationPresenting {

    // MARK: - Private Properties

    private lazy var manager = AppNotificationManager.default!
    private var notifications: [Foundation.UUID: GeckoNotification] = [:]

    // MARK: - Init

    init() {
        manager.notificationInvoked.addHandler { [weak self] _, eventArgs in
            guard let self, let id = eventArgs?.arguments["actionHandler"] else { return }

            for notification in notifications.values {
                if let actionable = notification as? GeckoNotificationActionable,
                   let action = actionable.actions.first(where: { $0.identifier == id }) {
                    action.onClick()
                    // When invoked, we'll remove our notification from our store.
                    self.notifications[actionable.id] = nil
                    break
                }
            }
        }

        do {
            try manager.register()  
        } catch {
            debugPrint(error)
        }
    }

    // MARK: - Public Methods

    func present(_ notification: GeckoNotification) {
        manager.present(notification)
        notifications[notification.id] = notification
    }

    func update(data: AppNotificationProgressData, in notification: UI.ProgressNotification) {
       manager.update(data: data, in: notification)
    }
}