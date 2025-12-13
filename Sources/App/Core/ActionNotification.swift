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
            let builder = try! AppNotificationBuilder()

            _ = try! builder
                .addText(title)
                .transform {
                    if let subtitle {
                        return try! $0.addText(subtitle)
                    }
                    return $0
                }

            let id = Foundation.UUID()

            actions.forEach {
                let button = try! AppNotificationButton($0.title)
                    .setButtonStyle($0.style)
                    .addArgument("actionHandler", $0.identifier)

                _ = try! builder.addButton(button)
            }

            self.id = id
            self.actions = actions
            self.builder = builder
        }
    }
}