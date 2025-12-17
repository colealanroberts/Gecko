import Foundation
import WinSDK

// MARK: - LinkHanlding

/// A contract for opening urls in the browser.
protocol URLRouter: AnyObject {
    /// The URL to open.
    func open(url: URL)
}

/// A contract for opening filesystem paths.
protocol LocalRouter: AnyObject {

}

// MARK: - ApplicationRouter

typealias ApplicationRouter = URLRouter & LocalRouter

// MARK: - LinkHandler

final class Router: ApplicationRouter {

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