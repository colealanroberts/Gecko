import FoundationEssentials
import WinAppSDK
import WindowsFoundation

@_spi(WinRTImplements) import WindowsFoundation

// MARK: - UI.ActionNotification

extension UI {
    final class ActionNotification: GeckoNotificationActionable {

        // MARK: - Public Properties

        let id: FoundationEssentials.UUID
        let actions: [UI.Action]
        let builder: AppNotificationBuilder

        // MARK: - Init

        init(
            title: String,
            subtitle: String?,
            actions: [UI.Action] = []
        ) {
            let builder = AppNotificationBuilder.make()
            let id = FoundationEssentials.UUID()

            builder
                .add(title)
                .transform {
                    if let subtitle {
                        return $0.add(subtitle)
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

                builder.add(button)
            }

            self.id = id
            self.actions = actions
            self.builder = builder
        }
    }
}