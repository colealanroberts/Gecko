import Foundation

extension ProcessInfo {
    static var systemRoot: String {
        processInfo.environment["SystemRoot"] ?? "C:\\Windows"
    }
}