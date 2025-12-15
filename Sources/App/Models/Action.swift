import FoundationEssentials

// MARK: - UI.Action

extension UI {
    struct Action {

        // MARK: - Public Properties

        /// A unique identifier for handling clicks with Windows.
        /// - Note: This is derived from the `id`.
        var identifier: String { "action-\(id)" }

        /// The style (`Style`) of the button.
        let style: Style

        /// The title of the button.
        let title: String

        /// The action to execute when the button is clicked.
        let onClick: () -> Void

        // MARK: - Private Properties

        /// A unique identifier for the button.
        /// - Note: This is assigned automatically.
        private let id = FoundationEssentials.UUID().uuidString
    }
}

// MARK: - UI.Action.Priority

extension UI.Action {
    enum Style {
        /// The default color - i.e. gray or secondary.
        case `default`

        /// A success style.
        case success

        /// A color for destructive actions, like deletion.
        case critical
    }
}

// MARK: - UI.Action+Util

extension UI.Action {
    static func critical(
        _ title: String, 
        _ onClick: @escaping () -> Void
    ) -> Self {
        .init(
            style: .critical,
            title: title, 
            onClick: onClick
        )
    }

    static func `default`(
        _ title: String,
        _ onClick: @escaping () -> Void
    ) -> Self {
        .init(
            style: .default, 
            title: title, 
            onClick: onClick
        )
    }

    static func success(
        _ title: String,
        _ onClick: @escaping () -> Void
    ) -> Self {
        .init(
            style: .success, 
            title: title, 
            onClick: onClick
        )
    }

    static var cancel: Self {
        .default("Cancel", {})
    }
}