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
    func add(_ string: String) -> AppNotificationBuilder {
        try! addText(string)
    }

    @discardableResult
    func add(_ button: AppNotificationButton) -> AppNotificationBuilder {
        try! addButton(button)
    }

    @discardableResult
    func add(_ progressBar: AppNotificationProgressBar) -> AppNotificationBuilder {
        try! addProgressBar(progressBar)
    }

    @discardableResult
    func set(_ tag: String) -> AppNotificationBuilder {
        try! setTag(tag)
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