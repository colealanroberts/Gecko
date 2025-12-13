import Foundation
import WinAppSDK

extension AppNotificationBuilder {
    /// Construct a new `AppNotificationBuilder`.
    static func make() -> AppNotificationBuilder {
        try! AppNotificationBuilder()
    }

    func text(_ string: String) -> AppNotificationBuilder {
        try! addText(string)
    }

    func button(_ button: AppNotificationButton) -> AppNotificationBuilder {
        try! addButton(button)
    }
}
