import Foundation
import WinSDK

// MARK: - LinkHanlding

/// A contract for opening urls in the browser.
protocol ApplicationRouting: AnyObject {
    /// The URL to open.
    func open(url: URL)
}

// MARK: - LinkHandler

final class ApplicationRouter: ApplicationRouting {

    // MARK: - Private Properties

    private let logger: Logging

    // MARK: - Init

    init(
        logger: Logging
    ) {
        self.logger = logger
    }

    // MARK: - Link

    func open(url: URL) {
        logger.debug("Opening URL: \(url.absoluteString)")

        url.absoluteString.withCString(encodedAs: UTF16.self) { urlPtr in
            "open".withCString(encodedAs: UTF16.self) { operationPtr in
                ShellExecuteW(nil, operationPtr, urlPtr, nil, nil, SW_SHOWNORMAL)
            }
        }
    }
}