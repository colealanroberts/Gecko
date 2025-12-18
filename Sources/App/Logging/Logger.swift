import Foundation
import Dispatch

// MARK: - Logging

protocol Logging: AnyObject {
    /// The session identifier associated with this logger.
    /// - Note: This is automatically attached with all logs in the given session.
    var sessionIdentifier: UUID { get }

    /// Logs a message using the provided message, level, and metadata, if any.
    func log(_ message: String, level: LogLevel, metadata: [String: String]?)
}

// MARK: - Logging+Utility

extension Logging {
    func debug(
        _ message: String,
        metadata: [String: String]? = nil
    ) {
        log(message, level: .debug, metadata: metadata)
    }

    func warning(
        _ message: String,
        metadata: [String: String]? = nil
    ) {
        log(message, level: .warning, metadata: metadata)
    }

    func critical(
        _ message: String,
        metadata: [String: String]? = nil
    ) {
        log(message, level: .critical, metadata: metadata)
    }
}

// MARK: - Logger

final class Logger: Logging {

    // MARK: - Public Properties

    let sessionIdentifier = UUID()

    // MARK: - Private Properties

    private lazy var decoder = JSONDecoder()

    private lazy var encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return encoder
    }()

    private lazy var queue: DispatchQueue = { 
        .init(label: "com.gecko.logger") 
    }()

    private let logLevel: LogLevel

    // MARK: - Init

    init(
        logLevel: LogLevel
    ) {
        self.logLevel = logLevel
    }

    // MARK: - Public Methods
    
    func log(
        _ message: String,
        level: LogLevel,
        metadata: [String: String]?
    ) {
        guard logLevel != .none else { 
            return
        }

        // Ensure that hierarchical order is respected.
        // - i.e. we only log if the level is higher than `Logger.logLevel`,
        // preventing unintentional noise.
        guard level.rawValue <= logLevel.rawValue else {
            return
        }

        queue.async { [weak self] in
            self?.handle(
                message,
                level: level,
                metadata: metadata
            )
        }
    }

    // MARK: - Private Methods

    private func handle(
        _ message: String,
        level: LogLevel,
        metadata: [String: String]?
    ) {
        queue.async { [weak self] in
            guard let self else { return }

            let message = LogMessage(
                sessionIdentifier: sessionIdentifier,
                value: message,
                level: level,
                metadata: metadata
            )

            debugPrint(message.description)

            if level.isDiskPersisted {      
                do {
                    let data = try encoder.encode(message)
                    try write(data: data)
                }  catch {
                    debugPrint(error.localizedDescription)
                }   
            }
        }
    }

    private func write(
        data: Data
    ) throws {
        let url = URL.logURL
        let directory = URL.geckoDirectory

        // Ensure directory exists.
        if !FileManager.default.fileExists(atPath: directory.path) {
            try FileManager.default.createDirectory(
                at: directory,
                withIntermediateDirectories: true
            )
        }

        // Create file if it doesn't exist.
        if !FileManager.default.fileExists(atPath: url.path) {
            FileManager.default.createFile(atPath: url.path, contents: nil)
        }

        // Append new data
        let handle = try FileHandle(forWritingTo: url)

        defer {
            try? handle.close()
        }

        try handle.seekToEnd()
        handle.write(data)
        handle.write(Data("\n".utf8))
    }
}

// MARK: - LogLevel+Utility

private extension LogLevel {
    var isDiskPersisted: Bool {
        self == .critical || self == .warning
    }
}

// MARK: - URL+Utility

private extension URL {
    static var logURL: Self {
        URL.geckoDirectory.appending(path: "log.jsonl")
    }
}

// MARK: - LogMessage+CustomStringConvertible

extension LogMessage: CustomStringConvertible {
    var description: String {
        var desc = """
        session: \(sessionIdentifier)
        timestamp: \(timestamp)
        level: \(level)
        value: \(value)
        """

        if let metadata {
            desc += "metadata: \(metadata)"
        }

        return desc
    }
}