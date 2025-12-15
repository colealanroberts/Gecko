import WinAppSDK

extension AppNotificationProgressBar {
    /// Constructs a new `AppNotificationProgressBar`.
    static func make() -> AppNotificationProgressBar {
        AppNotificationProgressBar()
    }

    @discardableResult
    func attachValue() -> AppNotificationProgressBar {
        try! bindValue()
    }

    @discardableResult
    func attachStatus() -> AppNotificationProgressBar {
        try! bindStatus()
    }

    @discardableResult
    func attachValueString() -> AppNotificationProgressBar {
        try! bindValueStringOverride()
    }
}