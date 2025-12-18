import Foundation
import FoundationNetworking
import FoundationEssentials

// MARK: - HTTPClient

protocol HTTPClient {
    /// Performs a request using the supplied `URLRequest` and returns `<T>`.
    func request<T: Decodable>(request: URLRequest) async throws -> T

    /// Attempts to download a file from the supplied url - calling the `onChange` closure as the download progresses.
    func download(url: URL, onChange: @escaping ((DownloadSnapshot) -> Void)) async throws -> URL

    /// Cancels a download task with the specified identifier.
    func cancel(id: String)
}

extension HTTPClient {
    func request<T: Decodable>(url: URL) async throws -> T {
        let req = URLRequest(url: url)
        return try await request(request: req)
    }
}

// MARK: - CoreHTTPClient

final class CoreHTTPClient: HTTPClient {

    // MARK: - Private Properties

    private lazy var decoder: JSONDecoder = .init() 
    private var downloadDelegate: DownloadDelegate?
    private let logger: Logging

    // MARK: - Init

    init(
        logger: Logging
    ) {
        self.logger = logger
    }
    
    // MARK: - Public Methods

    func request<T: Decodable>(request: URLRequest) async throws -> T {
        let (data, _) = try await URLSession.shared.data(for: request)
        return try decoder.decode(T.self, from: data)
    }

    func download(
        url: URL, 
        onChange: @escaping ((DownloadSnapshot) -> Void)
    ) async throws -> URL {
        guard let downloads = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first else {
            logger.warning("Unable to locate Downloads directory")
            throw URLError(.badURL)
        }

        let filename = url.lastPathComponent
        let destination = downloads.appendingPathComponent(filename)

        // Remove an existing download if one alreay exists.
        try? FileManager.default.removeItem(at: destination)

        // Create an empty file.
        FileManager.default.createFile(atPath: destination.path, contents: nil)

        // Use streaming delegate to write raw bytes directly to Downloads
        let downloadDelegate = DownloadDelegate(
            destination: destination, 
            logger: logger,
            onChange: onChange    
        )
        
        // Configure our URLSession
        let session = URLSession(
            configuration: .default,
            delegate: downloadDelegate,
            delegateQueue: nil
        )

        self.downloadDelegate = downloadDelegate

        return try await withCheckedThrowingContinuation { continuation in
            downloadDelegate.continuation = continuation
            let task = session.dataTask(with: url)
            task.resume()
        }
    }

    func cancel(id: String) {
        downloadDelegate?.cancel(id: id)
    }
}

// MARK: - CoreHTTPClient+StreamingDataDelegate

extension CoreHTTPClient {
    final class DownloadDelegate: NSObject, URLSessionDataDelegate {

        // MARK: - Public Properties

        nonisolated(unsafe) var continuation: CheckedContinuation<URL, Error>?

        // MARK: - Private Properties

        private var fileHandle: FileHandle?
        private var totalBytesExpected: Int64 = 0
        private var totalBytesWritten: Int64 = 0
        private var tasks: [String: URLSessionDataTask] = [:]
        private let logger: Logging
        private let destination: URL
        private let onChange: (DownloadSnapshot) -> Void

        // MARK: - Init

        init(
            destination: URL, 
            logger: Logging,
            onChange: @escaping (DownloadSnapshot) -> Void
        ) {
            self.destination = destination
            self.onChange = onChange
            self.logger = logger

            super.init()
        }

        // MARK: - Public Methods

        func cancel(id: String) {
            guard let task = tasks[id].take() else {
                logger.debug("Unable to cancel task: \(id)")
                return
            }

            logger.debug("Cancelling task: \(id)")
            task.cancel()

            do {
                // Remove our half-written file.
                try FileManager.default.removeItem(at: destination)
            } catch {
                logger.warning(error.localizedDescription)
            }
        }

        // MARK: - Delegate Methods

        func urlSession(
            _ session: URLSession, 
            dataTask: URLSessionDataTask, 
            didReceive response: URLResponse, 
            completionHandler: @escaping ((URLSession.ResponseDisposition) -> Void)
        ) {
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                logger.warning(response.debugDescription)
                continuation?.resume(throwing: URLError(.badServerResponse))
                completionHandler(.cancel)

                return
            }

            totalBytesExpected = response.expectedContentLength

            let identifier = Foundation.UUID().uuidString
            dataTask.taskDescription = identifier
            tasks[identifier] = dataTask

            do {
                fileHandle = try FileHandle(forWritingTo: destination)
                completionHandler(.allow)
            } catch {
                logger.warning(error.localizedDescription)
                continuation?.resume(throwing: error)
                completionHandler(.cancel)
            }
        }

        func urlSession(
            _ session: URLSession,
            dataTask: URLSessionDataTask, 
            didReceive data: Data
        ) {
            guard let fileHandle = fileHandle else {
                logger.warning("No file handle available.")
                return
            }

            do {
                try fileHandle.write(contentsOf: data)
                totalBytesWritten += Int64(data.count)

                // Dispatch a snapshot update for every 1MB (1,024kb) of data written.
                if totalBytesWritten % 1_024 == 0 {
                    let snapshot = DownloadSnapshot(
                        identifier: dataTask.taskDescription,
                        bytesWritten: totalBytesWritten,
                        totalBytes: totalBytesExpected
                    )

                    onChange(snapshot)
                }
            } catch {
                logger.warning(error.localizedDescription)
                continuation?.resume(throwing: error)
                dataTask.cancel()
            }
        }

        func urlSession(
            _ session: URLSession,
            task: URLSessionTask, 
            didCompleteWithError error: Error?
        ) {
            defer {
                do {
                    try fileHandle?.close()

                    if let taskIdentifier = task.taskDescription {
                        tasks[taskIdentifier] = nil
                    }
                } catch {
                    logger.warning(error.localizedDescription)
                }
            }

            if let error = error {
                logger.warning(error.localizedDescription)
                continuation?.resume(throwing: error)
            } else {
                continuation?.resume(returning: destination)
            }
        }
    }
}