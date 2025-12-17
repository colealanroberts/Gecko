struct Version: Comparable {
    /// The major version.
    let major: Int

    /// The minor version.
    let minor: Int

    init(
        major: Int,
        minor: Int
    ) {
        self.major = major
        self.minor = minor
    }

    init?(
        _ string: String 
    ) {
        let components = string
            .split(separator: ".")
            .compactMap { Int($0) }
    
        guard components.count == 2 else {
            assertionFailure("Expected two components, got \(components.count)")
            return nil
        }

        self.major = components[0]
        self.minor = components[1]
    }

    static func ==(lhs: Self, rhs: Self) -> Bool {
        lhs.major == rhs.major && lhs.minor == rhs.minor
    }

    static func <(lhs: Self, rhs: Self) -> Bool {
        (lhs.major, lhs.minor) < (rhs.major, rhs.minor)
    }
}

// MARK: Version+CustomStringConvertible

extension Version: CustomStringConvertible {
    var description: String {
        "\(major).\(minor)"
    }
}