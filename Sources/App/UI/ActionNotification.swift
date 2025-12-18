import FoundationEssentials
import WinAppSDK

// MARK: - UI.ActionNotification

extension UI {
    final class ActionNotification: GeckoNotificationActionable {

        // MARK: - Public Properties

        let id: String
        let actions: [UI.Action]
        let builder: AppNotificationBuilder

        // MARK: - Init

        init(
            title: String,
            subtitle: String? = nil,
            actions: [UI.Action] = []
        ) {
            let builder = AppNotificationBuilder.make()
            let id = FoundationEssentials.UUID().uuidString

            builder
                .text(title)
                .transform {
                    if let subtitle {
                        return $0.text(subtitle)
                    }
                    return $0
                }

            actions.forEach { action in
                let button = AppNotificationButton.make(action.title)
                    .style(action.style)
                    .argument("actionHandler", action.identifier)
                    .transform {
                        if action.placement.isContextMenu {
                            return $0.asContextMenuItem()
                        }

                        return $0
                    }

                builder.button(button)
            }

            self.id = id
            self.actions = actions
            self.builder = builder
        }
    }
}