import XCTest
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
@testable import Gecko

final class GeckoTests: XCTestCase {
    func testUnknownAndInvalidDownloadLengths() {
        for length: Int64 in [-1, 0] {
            let snapshot = DownloadSnapshot(identifier: nil, bytesWritten: 100, totalBytes: length)
            XCTAssertEqual(snapshot.progress, 0)
            XCTAssertNil(snapshot.percentage)
        }
        XCTAssertEqual(DownloadSnapshot(identifier: nil, bytesWritten: 200, totalBytes: 100).percentage, 100)
        XCTAssertEqual(DownloadSnapshot(identifier: nil, bytesWritten: -1, totalBytes: 100).percentage, 0)
    }

    func testConfigurationDefaultsAndClamps() throws {
        let defaults = try JSONDecoder().decode(Configuration.self, from: Data("{}".utf8))
        XCTAssertEqual(defaults.updateCheckInterval, 43_200)
        XCTAssertTrue(defaults.shouldLaunchAtStartup)
        XCTAssertTrue(defaults.containsIncompletes)
        let config = try JSONDecoder().decode(Configuration.self, from: Data(
            #"{"updateCheckInterval":-10,"logLevel":99,"shouldLaunchAtStartup":false}"#.utf8))
        XCTAssertEqual(config.updateCheckInterval, 300)
        XCTAssertEqual(config.logLevel, .debug)
        XCTAssertFalse(config.shouldLaunchAtStartup)
        XCTAssertFalse(config.containsIncompletes)
    }

    func testIncompleteConfigurationRepairPreservesUserValues() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("config.json")
        try Data(#"{"shouldLaunchAtStartup":false}"#.utf8).write(to: url)
        _ = ConfigurationProvider(url: url).load()
        let repaired = try JSONDecoder().decode(Configuration.self, from: Data(contentsOf: url))
        XCTAssertFalse(repaired.shouldLaunchAtStartup)
        XCTAssertEqual(repaired.updateCheckInterval, 43_200)
        XCTAssertFalse(repaired.containsIncompletes)
    }

    func testVersionOrderingAndDriverFormatting() {
        XCTAssertTrue(Version("591.44")! > Version("590.99")!)
        XCTAssertEqual(GPU(rawName: "NVIDIA GeForce RTX 5090", rawVersion: "32.0.15.9144").formattedVersion, "591.44")
    }
}

final class DownloadTests: XCTestCase {
    private var directory: URL!
    private var server: URL!
    private var client: CoreHTTPClient!

    override func setUpWithError() throws {
        guard let url = ProcessInfo.processInfo.environment["GECKO_TEST_SERVER"] else {
            throw XCTSkip("Run python3 Scripts/test.py to include HTTP integration tests")
        }
        server = URL(string: url)!
        directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        client = CoreHTTPClient(logger: Logger(logLevel: .none), downloadDirectory: directory)
    }

    override func tearDownWithError() throws {
        if let directory { try FileManager.default.removeItem(at: directory) }
    }

    func testDownloadPreservesExistingFileAndReportsProgress() async throws {
        let existing = directory.appendingPathComponent("driver.exe")
        try Data("existing".utf8).write(to: existing)
        var snapshots: [DownloadSnapshot] = []
        let result = try await client.download(url: server.appendingPathComponent("driver.exe")) { snapshots.append($0) }
        XCTAssertNotEqual(existing, result)
        XCTAssertEqual(try Data(contentsOf: existing), Data("existing".utf8))
        XCTAssertEqual(try Data(contentsOf: result).count, 2_200_123)
        XCTAssertEqual(snapshots.first?.bytesWritten, 0)
        XCTAssertNotNil(snapshots.first?.identifier)
        XCTAssertTrue(snapshots.contains { $0.bytesWritten >= 1_048_576 && $0.bytesWritten < 2_200_123 })
        XCTAssertEqual(snapshots.last?.percentage, 100)
        XCTAssertFalse(try FileManager.default.contentsOfDirectory(atPath: directory.path).contains { $0.hasSuffix(".partial") })
    }

    func testUnknownContentLength() async throws {
        var last: DownloadSnapshot?
        let result = try await client.download(url: server.appendingPathComponent("unknown")) { last = $0 }
        XCTAssertEqual(try Data(contentsOf: result).count, 2_200_123)
        XCTAssertNil(last?.percentage)
    }

    func testHTTPErrorCompletesOnceAndCleansUp() async throws {
        do {
            _ = try await client.download(url: server.appendingPathComponent("error")) { _ in }
            XCTFail("Expected an HTTP error")
        } catch {
            XCTAssertEqual((error as? URLError)?.code, .badServerResponse)
        }
        XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath: directory.path), [])
    }

    func testImmediateCancellation() async throws {
        do {
            _ = try await client.download(url: server.appendingPathComponent("driver.exe")) { snapshot in
                self.client.cancel(id: snapshot.identifier!)
            }
            XCTFail("Expected cancellation")
        } catch {
            XCTAssertEqual((error as? URLError)?.code, .cancelled)
        }
        XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath: directory.path), [])
    }

    func testMidDownloadCancellation() async throws {
        do {
            _ = try await client.download(url: server.appendingPathComponent("slow")) { snapshot in
                if snapshot.bytesWritten > 0 { self.client.cancel(id: snapshot.identifier!) }
            }
            XCTFail("Expected cancellation")
        } catch {
            XCTAssertEqual((error as? URLError)?.code, .cancelled)
        }
        XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath: directory.path), [])
    }

    func testTaskCancellation() async throws {
        let started = expectation(description: "Task registered")
        let task = Task {
            try await client.download(url: server.appendingPathComponent("slow")) { snapshot in
                if snapshot.bytesWritten == 0 { started.fulfill() }
            }
        }
        await fulfillment(of: [started], timeout: 5)
        task.cancel()
        do {
            _ = try await task.value
            XCTFail("Expected cancellation")
        } catch {
            XCTAssertTrue(error is CancellationError || (error as? URLError)?.code == .cancelled)
        }
        XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath: directory.path), [])
    }

    func testRequestRejectsHTTPErrorBeforeDecoding() async throws {
        do {
            let _: [String: String] = try await client.request(url: server.appendingPathComponent("error"))
            XCTFail("Expected an HTTP error")
        } catch {
            XCTAssertEqual((error as? URLError)?.code, .badServerResponse)
        }
    }

    func testFileCreationErrorCompletesOnce() async throws {
        let file = directory.appendingPathComponent("not-a-directory")
        try Data().write(to: file)
        let client = CoreHTTPClient(logger: Logger(logLevel: .none), downloadDirectory: file)
        do {
            _ = try await client.download(url: server.appendingPathComponent("driver.exe")) { _ in }
            XCTFail("Expected a filesystem error")
        } catch {
            XCTAssertFalse(error is CancellationError)
        }
    }
}
