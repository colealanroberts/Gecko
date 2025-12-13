import Foundation
import CWinRT
import WinAppSDK
import WindowsFoundation

@_spi(WinRTImplements) import WindowsFoundation

// MARK: - UI.ActionNotification

extension UI {
    final class ProgressNotification: GeckoNotificationActionable {

        // MARK: - Public Properties

        let id: Foundation.UUID
        let builder: AppNotificationBuilder
        let actions: [UI.Action]
        let tag: String

        // MARK: - Private Properties

        private let title: String
        private var currentProgress: Double = 0.0
        private var lastSequence: UInt32 = 0

        // MARK: - Init

        init(
            title: String,
            subtitle: String? = nil,
            cancel: UI.Action
        ) {
            let builder = AppNotificationBuilder()
            let id = Foundation.UUID()
            let tag = id.uuidString

            let bar = AppNotificationProgressBar.make()
                .attachValue()
                .attachStatus()
                .attachValueString()

            let button = AppNotificationButton.make(cancel.title)
                .buttonStyle(cancel.style)
                .argument("actionHandler", cancel.identifier)
            
            _ = try! builder
                .text(title)
                .transform {
                    if let subtitle {
                        return try! $0.addText(subtitle)
                    }

                    return $0
                }
                .addProgressBar(bar)
                .addButton(button)
                .setTag(tag)

            self.id = id
            self.title = title
            self.actions = [cancel]
            self.builder = builder
            self.tag = tag
        }

        // MARK: - Public Methods

        func update(
            snapshot: DownloadSnapshot
        ) -> AppNotificationProgressData? {
            var sequence = UInt32(snapshot.progress * 100.0)
            
            guard sequence != lastSequence else {
                return nil
            }

            lastSequence = sequence

            let data = AppNotificationProgressData(sequence)
                data.title = title
                data.value = snapshot.progress

                if let percentage = snapshot.percentage {
                    data.valueStringOverride = "\(percentage)%"
                }

                let written = ByteCountFormatter.string(fromByteCount: snapshot.bytesWritten, countStyle: .file)
                let total = ByteCountFormatter.string(fromByteCount: snapshot.totalBytes, countStyle: .file)
                
                data.status = "\(written)/\(total)"
            return data
        }
    }
}