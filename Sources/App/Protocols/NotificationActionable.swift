/// Defines a notification where actions can be taken.
protocol GeckoNotificationActionable: GeckoNotification {
    /// The list of available actions.
    var actions: [UI.Action] { get }
}