import FoundationEssentials

protocol NotificationIdentifiable {
    /// A unique identifier for the notification.
    var id: FoundationEssentials.UUID { get }
}