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

            actions.forEach {
                let button = AppNotificationButton.make($0.title)
                    .style($0.style)
                    .argument("actionHandler", $0.identifier)

                builder.add(button)
            }

            self.id = id
            self.actions = actions
            self.builder = builder
        }
    }
}