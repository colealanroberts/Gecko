import WinAppSDK

// MARK: - AppNotificationButton+UI.Action.Style

extension AppNotificationButton {
    /// Construct a new `AppNotificationBuilder`.
    static func make(_ title: String) -> AppNotificationButton {
        try! AppNotificationButton(title)
    }

    @discardableResult
    func style(_ style: UI.Action.Style) -> AppNotificationButton {
        let buttonStyle: AppNotificationButtonStyle

        switch style {
        case .default:
            buttonStyle = .default
        case .success:
            buttonStyle = .success
        case .critical:
            buttonStyle = .critical
        }

        return try! setButtonStyle(buttonStyle)
    }
    
    @discardableResult
    func argument(_ a: String, _ b: String) -> AppNotificationButton {
        try! addArgument(a, b)
    }
}
