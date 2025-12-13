import Foundation
import WinAppSDK
import WindowsFoundation

// MARK: - BuilderTransformable

protocol BuilderTransformable {
    /// A function that allows _inline_ transformation of a `Builder` type, 
    /// enabling inline chaining.
    func transform(_ transformer: (Self) -> Self) -> Self
}

// MARK: - AppNotificationBuilder+BuilderTransformable

extension AppNotificationBuilder: BuilderTransformable {
    func transform(
        _ transformer: (AppNotificationBuilder) -> AppNotificationBuilder
    ) -> AppNotificationBuilder {
        transformer(self)
    }
}