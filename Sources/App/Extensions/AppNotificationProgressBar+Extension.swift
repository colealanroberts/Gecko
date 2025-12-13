import Foundation
import WinAppSDK

extension AppNotificationProgressBar {
    static func make() -> AppNotificationProgressBar {
        try! AppNotificationProgressBar()
    }

    func attachValue() -> AppNotificationProgressBar {
        try! bindValue()
    }

    func attachStatus() -> AppNotificationProgressBar {
        try! bindStatus()
    }

    func attachValueString() -> AppNotificationProgressBar {
        try! bindValueStringOverride()
    }
}