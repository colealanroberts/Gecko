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

    /// The concrete Windows notification manager.
    private lazy var manager = AppNotificationManager.default!
    
    /// A dictionary of identifiers and associated closures to execute - keyed by identifier (`Action.identifier`).
    private var actionHandlers: [String: () -> Void] = [:]

    // MARK: - Init

    init() {
        registerNotificationHandler()
    }

    // MARK: - Public Methods

    func present(_ notification: GeckoNotification) {
        manager.present(notification)

        if let actionable = notification as? GeckoNotificationActionable {
            actionable.actions.forEach {
                actionHandlers[$0.identifier] = $0.onClick 
            }
        }
    }

    func update(data: AppNotificationProgressData, in notification: UI.ProgressNotification) {
       manager.update(data: data, in: notification)
    }

    // MARK: - Private Methods

    private func registerNotificationHandler() {
        manager.notificationInvoked.addHandler {  [weak self] _, eventArgs in
            guard let self, let id = eventArgs?.arguments["actionHandler"] else { return }

            if let action = actionHandlers[id].take() {
                action()
            }
        }

        do {
            try manager.register()  
        } catch {
            debugPrint(error)
        }
    }
}