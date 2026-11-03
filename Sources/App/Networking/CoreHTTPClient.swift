import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

protocol HTTPClient {
    func request<T: Decodable>(request: URLRequest) async throws -> T
    func download(url: URL, onChange: @escaping (DownloadSnapshot) -> Void) async throws -> URL
    func cancel(id: String)
}

extension HTTPClient {
    func request<T: Decodable>(url: URL) async throws -> T {
        try await request(request: URLRequest(url: url))
    }
}

final class CoreHTTPClient: HTTPClient {
    private let logger: Logging
    private let downloadDirectory: URL
    private let lock = NSLock()
    private var tasks: [String: URLSessionDataTask] = [:]

    init(logger: Logging, downloadDirectory: URL? = nil) {
        self.logger = logger
        self.downloadDirectory = downloadDirectory ?? FileManager.default.urls(
            for: .downloadsDirectory, in: .userDomainMask
        )[0]
    }

    func request<T: Decodable>(request: URLRequest) async throws -> T {
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let response = response as? HTTPURLResponse,
              (200..<300).contains(response.statusCode) else {
            throw URLError(.badServerResponse)
        }
        return try JSONDecoder().decode(T.self, from: data)
    }

    func download(url: URL, onChange: @escaping (DownloadSnapshot) -> Void) async throws -> URL {
        try Task.checkCancellation()
        let id = UUID().uuidString
        let delegate = DownloadDelegate(
            id: id, directory: downloadDirectory, filename: url.lastPathComponent,
            onChange: onChange
        )
        let session = URLSession(configuration: .default, delegate: delegate, delegateQueue: nil)
        return try await withTaskCancellationHandler {
            return try await withCheckedThrowingContinuation { continuation in
                delegate.continuation = continuation
                let task = session.dataTask(with: url)
                register(task, id: id)
                delegate.onComplete = { [weak self] in self?.removeTask(id: id) }
                // Publish cancellation identity before the request or any body bytes arrive.
                onChange(DownloadSnapshot(identifier: id, bytesWritten: 0, totalBytes: 0))
                task.resume()
                // Covers cancellation between the initial check and registration.
                if Task.isCancelled { task.cancel() }
            }
        } onCancel: {
            self.cancel(id: id)
        }
    }

    func cancel(id: String) {
        lock.lock()
        let task = tasks[id]
        lock.unlock()
        task?.cancel()
    }

    private func register(_ task: URLSessionDataTask, id: String) {
        lock.lock()
        tasks[id] = task
        lock.unlock()
    }

    private func removeTask(id: String) {
        lock.lock()
        tasks[id] = nil
        lock.unlock()
    }
}

extension CoreHTTPClient {
    // URLSession serializes this delegate's callbacks. Only the task itself is
    // accessed from other threads, through CoreHTTPClient's synchronized registry.
    final class DownloadDelegate: NSObject, URLSessionDataDelegate, @unchecked Sendable {
        var continuation: CheckedContinuation<URL, Error>?
        var onComplete: (() -> Void)?
        private let id: String
        private let directory: URL
        private let filename: String
        private let temporaryURL: URL
        private let onChange: (DownloadSnapshot) -> Void
        private var fileHandle: FileHandle?
        private var totalBytesExpected: Int64 = 0
        private var totalBytesWritten: Int64 = 0
        private var lastReportedBytes: Int64 = 0

        init(id: String, directory: URL, filename: String, onChange: @escaping (DownloadSnapshot) -> Void) {
            self.id = id
            self.directory = directory
            self.filename = filename.isEmpty ? "driver.exe" : filename
            self.temporaryURL = directory.appendingPathComponent(".\(id).partial")
            self.onChange = onChange
        }

        func urlSession(_ session: URLSession, dataTask: URLSessionDataTask,
                        didReceive response: URLResponse,
                        completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
            guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
                finish(.failure(URLError(.badServerResponse)))
                completionHandler(.cancel)
                return
            }
            totalBytesExpected = response.expectedContentLength
            do {
                try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
                guard FileManager.default.createFile(atPath: temporaryURL.path, contents: nil) else {
                    throw CocoaError(.fileWriteUnknown)
                }
                fileHandle = try FileHandle(forWritingTo: temporaryURL)
                completionHandler(.allow)
            } catch {
                finish(.failure(error))
                completionHandler(.cancel)
            }
        }

        func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
            guard continuation != nil, let fileHandle else { return }
            do {
                try fileHandle.write(contentsOf: data)
                totalBytesWritten += Int64(data.count)
                if totalBytesWritten - lastReportedBytes >= 1_048_576 {
                    lastReportedBytes = totalBytesWritten
                    reportProgress()
                }
            } catch {
                finish(.failure(error))
                dataTask.cancel()
            }
        }

        func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
            defer {
                onComplete?()
                session.finishTasksAndInvalidate()
            }
            guard continuation != nil else { return }
            if let error {
                finish(.failure(error))
                return
            }
            do {
                try fileHandle?.close()
                fileHandle = nil
                // Never replace a user's existing installer. Rename only after success.
                var destination = directory.appendingPathComponent(filename)
                if FileManager.default.fileExists(atPath: destination.path) {
                    let base = destination.deletingPathExtension().lastPathComponent
                    let ext = destination.pathExtension
                    destination = directory.appendingPathComponent("\(base)-\(id)" + (ext.isEmpty ? "" : ".\(ext)"))
                }
                try FileManager.default.moveItem(at: temporaryURL, to: destination)
                reportProgress()
                finish(.success(destination))
            } catch {
                finish(.failure(error))
            }
        }

        private func reportProgress() {
            onChange(DownloadSnapshot(identifier: id, bytesWritten: totalBytesWritten, totalBytes: totalBytesExpected))
        }

        private func finish(_ result: Result<URL, Error>) {
            guard let continuation else { return }
            self.continuation = nil
            try? fileHandle?.close()
            fileHandle = nil
            if case .failure = result {
                try? FileManager.default.removeItem(at: temporaryURL)
            }
            continuation.resume(with: result)
        }
    }
}
