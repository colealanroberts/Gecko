import Foundation
import FoundationNetworking

// MARK: - HTTPClient

protocol HTTPClient {
    /// Performs a request using the supplied `URLRequest` and returns `<T>`.
    func request<T: Decodable>(request: URLRequest) async throws -> T

    /// Attempts to download a file from the supplied url - calling the `onProgress` closure as the download progresses.
    func download(url: URL, onChange: @escaping ((CoreHTTPClient.DownloadTaskDelegate.DownloadTask) -> Void)) async throws -> URL

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
    private lazy var downloadDelegate = DownloadTaskDelegate()
    
    // MARK: - Public Methods

    func request<T: Decodable>(request: URLRequest) async throws -> T {
        let (data, _) = try await URLSession.shared.data(for: request)
        return try decoder.decode(T.self, from: data)
    }

    func download(url: URL, onChange: @escaping ((DownloadTaskDelegate.DownloadTask) -> Void)) async throws -> URL {
        downloadDelegate.onChange = onChange

        let session = URLSession(
            configuration: .default,
            delegate: downloadDelegate,
            delegateQueue: nil
        )

        return try await downloadDelegate.download(session: session, url: url)
    }

    func cancel(id: String) {
        if let task = downloadDelegate.tasks[id] {
            task.cancel()
        }
    }
}

// MARK: - CoreHTTPClient+DownloadTaskDelegate

extension CoreHTTPClient {
    final class DownloadTaskDelegate: NSObject, URLSessionDownloadDelegate {

        // MARK: - Typealiases

        typealias DownloadTask = (taskIdentifier: String?, progress: Double)

        // MARK: - Public Properties

        /// Fired each time new data arrives - yielding a `DownloadTask`.
        nonisolated(unsafe) var onChange: ((DownloadTask) -> Void)?

        /// A dictionary containing in-flight download tasks.
        nonisolated(unsafe) private(set) var tasks: [String: URLSessionTask] = [:]
        
        // MARK: - Private Properties

        /// The stored continuation.
        nonisolated(unsafe) private var continuation: CheckedContinuation<URL, Error>?

        // MARK: - Delegate Methods

        func download(
            session: URLSession,
            url: URL
        ) async throws -> URL {
            try await withCheckedThrowingContinuation { continuation in
                self.continuation = continuation
                let task = session.downloadTask(with: url)
                let description = UUID().uuidString
                task.taskDescription = description
                tasks[description] = task

                task.resume()
            }
        }

        func urlSession(
            _ session: URLSession, 
            downloadTask: URLSessionDownloadTask, 
            didWriteData bytesWritten: Int64,
            totalBytesWritten: Int64, 
            totalBytesExpectedToWrite: Int64
        ) {
            let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
            onChange?((downloadTask.taskDescription, progress))
        }

        func urlSession(
            _ session: URLSession, 
            downloadTask: URLSessionDownloadTask, 
            didFinishDownloadingTo location: URL
        ) {
            if let taskDescription = downloadTask.taskDescription {
                tasks[taskDescription] = nil
            }
            continuation?.resume(returning: location)
        }

        func urlSession(
            _ session: URLSession, 
            task: URLSessionTask,
            didCompleteWithError error: (any Error)?
        ) {
            if let error {
                if let taskDescription = task.taskDescription {
                    tasks[taskDescription] = nil 
                }
                continuation?.resume(throwing: error)
            }
        }
    }
}