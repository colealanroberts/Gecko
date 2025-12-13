import FoundationEssentials

struct GPU {
    /// The raw name of the device.
    private let rawName: String

    /// The raw version string.
    /// - e.g. `32.0.15.9144.
    private let rawVersion: String

    init(
        rawName: String,
        rawVersion: String
    ) {
        self.rawName = rawName
        self.rawVersion = rawVersion
    }

    /// The formatted name - replacing the string `NVIDIA`.
    var formattedName: String {
        rawName.replacingOccurrences(of: "NVIDIA", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// The formatted version - e.g. `591.44`
    var formattedVersion: String {
        let trimmed = rawVersion
            .replacingOccurrences(of: ".", with: "")
            .dropFirst(4)
    
        guard trimmed.count >= 3 else {
            return String(trimmed)
        }

        let index = trimmed.index(trimmed.startIndex, offsetBy: 3)

        return trimmed.prefix(upTo: index) + "." + trimmed.suffix(from: index)
    }
}