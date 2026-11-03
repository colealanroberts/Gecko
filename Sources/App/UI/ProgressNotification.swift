import Foundation
import WinAppSDK

// MARK: - UI.ActionNotification

extension UI {
    final class ProgressNotification: GeckoNotificationActionable {

        // MARK: - Public Properties

        let id: String
        let builder: AppNotificationBuilder
        let actions: [UI.Action]

        // MARK: - Private Properties

        private let title: String
        private var lastBytesWritten: Int64 = -1
        private var lastSequence: UInt32 = 0

        // MARK: - Init

        init(
            title: String,
            subtitle: String? = nil,
            actions: [UI.Action]
        ) {
            let builder = AppNotificationBuilder()
            let id = Foundation.UUID().uuidString

            let bar = AppNotificationProgressBar.make()
                .attachValue()
                .attachStatus()
                .attachValueString()

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
            
            builder
                .text(title)
                .transform {
                    if let subtitle {
                        return $0.text(subtitle)
                    }

                    return $0
                }
                .progressBar(bar)

            self.id = id
            self.title = title
            self.actions = actions
            self.builder = builder
        }

        // MARK: - Public Methods

        func update(
            snapshot: DownloadSnapshot
        ) -> AppNotificationProgressData? {
            guard snapshot.bytesWritten != lastBytesWritten else {
                return nil
            }

            lastBytesWritten = snapshot.bytesWritten
            lastSequence += 1

            let data = AppNotificationProgressData(lastSequence)
                data.title = title
                data.value = snapshot.progress

                if let percentage = snapshot.percentage {
                    data.valueStringOverride = "\(percentage)%"
                } else {
                    data.valueStringOverride = "Downloading"
                }

                let written = ByteCountFormatter.string(fromByteCount: snapshot.bytesWritten, countStyle: .file)
                let total = ByteCountFormatter.string(fromByteCount: snapshot.totalBytes, countStyle: .file)
                
                data.status = snapshot.totalBytes > 0 ? "\(written)/\(total)" : written
            return data
        }
    }
}