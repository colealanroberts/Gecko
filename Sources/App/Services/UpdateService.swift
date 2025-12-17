import Foundation
import FoundationNetworking
import WinSDK

// MARK: - UpdateServicing

protocol UpdateServicing {
    /// Fetches a driver update, if necessary.
    func fetch() async throws -> DriverResponse.Download?
}

// MARK: - UpdateService

final class UpdateService: UpdateServicing {

    // MARK: - Private Properties

    private let httpClient: HTTPClient
    private let gpuLookupService: GPULookupServicing
    private let logger: Logging
    private let systemInfoProvider: SystemInfoProviding

    // MARK: - Init

    init(
        httpClient: HTTPClient,
        gpuLookupService: GPULookupServicing,
        systemInfoProvider: SystemInfoProviding,
        logger: Logging
    ) {
        self.httpClient = httpClient
        self.gpuLookupService = gpuLookupService
        self.systemInfoProvider = systemInfoProvider
        self.logger = logger
    }

    // MARK: - Public Methods

    func fetch() async throws -> DriverResponse.Download? {
        guard let gpu = systemInfoProvider.currentGPU() else {
            logger.warning("Unable to retrieve current gpu.")
            return nil
        }

        guard let os = systemInfoProvider.currentOS() else {
            logger.warning("Unable to retrieve current operating system.")
            return nil
        }

        let (gpuID, osID) = try await gpuLookupService.identifiers(gpu: gpu, os: os)

        guard let gpuID else {
            logger.warning("Unable to identify gpu id.")
            return nil
        }

        guard let osID else {
            logger.warning("Unable to identify os id.")
            return nil
        }

        var components = URLComponents(string: "https://gfwsl.geforce.com/services_toolkit/services/com/nvidia/services/AjaxDriverService.php")

        components?.queryItems = [
            URLQueryItem(name: "func", value: "DriverManualLookup"),
            URLQueryItem(name: "pfid", value: gpuID),
            URLQueryItem(name: "osID", value: osID),
            URLQueryItem(name: "dch", value: "1"),
            URLQueryItem(name: "ts", value: "\(Date.now.timeIntervalSince1970)")
        ]

        guard let url = components?.url else {
            logger.warning("Unable to construct url.")
            return nil
        }

        let response: DriverResponse = try await httpClient.request(url: url)

        guard let download = response.downloads.first else {
            logger.warning("Request succeeded, but download array was empty.")
            return nil
        }

        guard let local = Version(gpu.formattedVersion) else {
            logger.warning("Unable to construct a local version.")
            return nil
        }
        
        guard let remote = Version(download.version) else {
            logger.warning("Unable to construct a remote version.")
            return nil
        }

        logger.debug("Local version: \(local.description)")
        logger.debug("Remote version: \(remote.description)")

        if remote <= local {
            return download
        } else {
            logger.debug("The installed driver is the latest available.")
            return nil
        }
    }
}