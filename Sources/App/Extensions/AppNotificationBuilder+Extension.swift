import WinAppSDK

extension AppNotificationBuilder {
    /// Construct a new `AppNotificationBuilder`.
    static func make() -> AppNotificationBuilder {
        try! AppNotificationBuilder()
    }

    @discardableResult
    func build() -> AppNotification {
        try! buildNotification()!
    }

    @discardableResult
    func text(_ string: String) -> AppNotificationBuilder {
        try! addText(string)
    }

    @discardableResult
    func button(_ button: AppNotificationButton) -> AppNotificationBuilder {
        try! addButton(button)
    }

    @discardableResult
    func progressBar(_ progressBar: AppNotificationProgressBar) -> AppNotificationBuilder {
        try! addProgressBar(progressBar)
    }

    @discardableResult
    func tag(_ tag: String) -> AppNotificationBuilder {
        try! setTag(tag)
    }

    @discardableResult
    func scenario(_ scenario: AppNotificationScenario) -> AppNotificationBuilder {
        try! setScenario(scenario)
    }
}

// MARK: - AppNotificationBuilder+BuilderTransformable

extension AppNotificationBuilder: Transformable {
    @discardableResult
    func transform(
        _ transformer: (AppNotificationBuilder) -> AppNotificationBuilder
    ) -> AppNotificationBuilder {
        transformer(self)
    }
}