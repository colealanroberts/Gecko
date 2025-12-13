import Foundation
import CWinRT
import WinAppSDK
import WindowsFoundation

@_spi(WinRTImplements) import WindowsFoundation

// MARK: - UI.ActionNotification

extension UI {
    final class ActionNotification: GeckoNotificationActionable {

        // MARK: - Public Properties

        let id: Foundation.UUID
        let actions: [UI.Action]
        let builder: AppNotificationBuilder

        // MARK: - Init

        init(
            title: String,
            subtitle: String?,
            actions: [UI.Action] = []
        ) {
            let builder = AppNotificationBuilder.make()

            builder
                .text(title)
                .transform {
                    if let subtitle {
                        return $0.text(subtitle)
                    }
                    return $0
                }

            let id = Foundation.UUID()

            actions.forEach {
                let button = AppNotificationButton.make($0.title)
                    .buttonStyle($0.style)
                    .argument("actionHandler", $0.identifier)

                _ = try! builder.addButton(button)
            }

            self.id = id
            self.actions = actions
            self.builder = builder
        }
    }
}