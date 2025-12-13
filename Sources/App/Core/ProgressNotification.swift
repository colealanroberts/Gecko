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

            let bar = try! AppNotificationProgressBar()
                .bindValue()
                .bindStatus()
                .bindValueStringOverride()

            let button = try! AppNotificationButton(cancel.title)
                .setButtonStyle(cancel.style)
                .addArgument("actionHandler", cancel.identifier)
            
            _ = try! builder
                .addText(title)
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
            progress: Double
        ) -> AppNotificationProgressData? {
            var sequence = UInt32(progress * 100.0)

            // Round to two decimal places.
            let percent = round(progress * 100) / 100

            // Only update if we have a unique sequence.
            guard sequence != lastSequence else {
                return nil
            }

            lastSequence = sequence

            let bar = AppNotificationProgressData(sequence)
                bar.title = title
                bar.value = percent
                bar.valueStringOverride = "\(Int(progress * 100))%"
                bar.status = "Downloading..."

            return bar
        }
    }
}