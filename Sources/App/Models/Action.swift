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

        /// The placement of the button.
        let placement: Placement

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

// MARK: - UI.Action.Placement

extension UI.Action {
    /// Represents where a button is placed in a notification.
    enum Placement {
        /// The button is placed in the body.
        case `default`

        /// The button is placed as a secondary context menu item.
        /// - Note: These are visibile when right-clicking the notification *or* selecting the ellipsis (overflow) menu.
        case contextMenu

        // MARK: - Utility

        var isContextMenu: Bool { self == .contextMenu }
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
            placement: .default,
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
            placement: .default,
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
            placement: .default,
            onClick: onClick
        )
    }

    static func contextMenuItem(
        _ title: String,
        _ onClick: @escaping () -> Void
    )-> Self {
        .init(
            style: .default, 
            title: title,
            placement: .contextMenu,
            onClick: onClick
        )
    }

    static var cancel: Self {
        .default("Cancel", {})
    }
}