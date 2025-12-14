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

    // MARK: - Init

    init(
        httpClient: HTTPClient,
        gpuLookupService: GPULookupServicing
    ) {
        self.httpClient = httpClient
        self.gpuLookupService = gpuLookupService
    }

    // MARK: - Public Methods

    func fetch() async throws -> DriverResponse.Download? {
        guard let gpu = SystemInfoProvider.currentGPU() else {
            return nil
        }

        guard let os = SystemInfoProvider.currentOS() else {
            return nil
        }

        let (gpuID, osID) = try await gpuLookupService.identifiers(gpu: gpu, os: os)

        guard let gpuID else {
            assertionFailure("Unable to identify gpu id.")
            return nil
        }

        guard let osID else {
            assertionFailure("Unable to identify os id.")
            return nil
        }

        var components = URLComponents(string: "https://gfwsl.geforce.com/services_toolkit/services/com/nvidia/services/AjaxDriverService.php")

        components?.queryItems = [
            URLQueryItem(name: "func", value: "DriverManualLookup"),
            URLQueryItem(name: "pfid", value: gpuID),
            URLQueryItem(name: "osID", value: osID),
            URLQueryItem(name: "dch", value: "1")
        ]

        guard let url = components?.url else {
            return nil
        }

        let response: DriverResponse = try await httpClient.request(url: url)

        guard let download = response.downloads.first else {
            assertionFailure("Request succeeded, but download array was empty.")
            return nil
        }

        guard let local = Version(gpu.formattedVersion) else {
            assertionFailure("Unable to construct a local version.")
            return nil
        }
        
        guard let remote = Version(download.version) else {
            assertionFailure("Unable to construct a remote version.")
            return nil
        }

        if remote <= local {
            return download
        } else {
            return nil
        }
    }
}