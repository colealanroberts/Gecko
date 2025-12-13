import Foundation
import WinAppSDK

// MARK: - AppNotificationButton+UI.Action.Style

extension AppNotificationButton {
    @discardableResult
    func setButtonStyle(_ style: UI.Action.Style) throws -> AppNotificationButton {
        let buttonStyle: AppNotificationButtonStyle

        switch style {
        case .default:
            buttonStyle = .default
        case .success:
            buttonStyle = .success
        case .critical:
            buttonStyle = .critical
        }

        return try setButtonStyle(buttonStyle)
    }
}
