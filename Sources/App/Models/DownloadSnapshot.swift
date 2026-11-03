/// Represents a slice of the current download at a given time.
struct DownloadSnapshot {
    /// The identifier associated with this update.
    let identifier: String?

    /// The total number of bytes written.
    let bytesWritten: Int64

    /// The total number of bytes to write.
    let totalBytes: Int64

    // MARK: - Utility

    /// The current progress - 0.0 -> 1.0.
    var progress: Double {
        guard totalBytes > 0 else { return 0 }
        return min(1, max(0, Double(bytesWritten) / Double(totalBytes)))
    }

    /// The current percentage - 0% -> 100%
    var percentage: Int? {
        guard totalBytes > 0 else { return nil }
        return Int(progress * 100)
    }
}