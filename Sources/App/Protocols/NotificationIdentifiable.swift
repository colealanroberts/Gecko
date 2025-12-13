import Foundation

protocol NotificationIdentifiable {
    /// A unique identifier for the notification.
    var id: Foundation.UUID { get }
}