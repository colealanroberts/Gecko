import Foundation

// MARK: - ConfigurationProviding

protocol ConfigurationProviding {
    /// Loads the current configuration from disk.
    /// However, if one is not present, we'll utilize
    /// `Configuration.default`.
    func load() -> Configuration
}

// MARK: - ConfigurationProvider

final class ConfigurationProvider: ConfigurationProviding {

    // MARK: - Private Properties

    private lazy var decoder = JSONDecoder()

    private lazy var encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        return encoder
    }()

    // MARK: - Init

    private let url: URL

    init(url: URL = URL.geckoDirectory.appendingPathComponent("config.json")) {
        self.url = url
    }

    // MARK: - Public Methods

    func load() -> Configuration {
        guard FileManager.default.fileExists(atPath: url.path) else {
            print("No custom `config.json` file found at \(url.absoluteString). Creating a new config.")
            writeConfigIfNecessary(at: url)

            return .default
        }

        do {
            let data = try Data(contentsOf: url)
            let config = try decoder.decode(Configuration.self, from: data)

            if config.containsIncompletes {
                writeConfigIfNecessary(at: url, configuration: config)
            }

            return config
        } catch {
            debugPrint(error)
            return .default
        }
    }

    // MARK: - Private Methods

    private func writeConfigIfNecessary(at url: URL, configuration: Configuration = .default) {
        do {
            let parentDirectory = url.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: parentDirectory, withIntermediateDirectories: true)
            let data = try encoder.encode(configuration)
            try data.write(to: url, options: .atomic)
        } catch {
            debugPrint(error)
        }
    }
}