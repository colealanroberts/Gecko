import FoundationEssentials
import FoundationNetworking

// MARK: - GPULookupServicing

protocol GPULookupServicing {
    /// Returns a string identifier for a given GPU name.
    /// For example, `GeForce RTX 5090` -> `1066`, if any.
    func gpuID(for name: String) async throws -> String?

    /// Returns an operating system (`OperatingSystem`) for the current system, if any.
    func osID(for os: OS) async throws -> String?
}

// MARK: - GPULookupServicing+Util

extension GPULookupServicing {
    /// A utility method for fetching both gpu and os identifiers.
    func identifiers(
        gpu: GPU,
        os: OS
    ) async throws -> (String?, String?) {
        async let gpuID = gpuID(for: gpu.formattedName)
        async let osID = osID(for: os)

        return try await (gpuID, osID)
    }
}

// MARK: - GPULookupService

final class GPULookupService: GPULookupServicing {

    // MARK: - Private Properties

    private let baseURL = URL(string: "https://raw.githubusercontent.com/ZenitH-AT/nvidia-data/main")!
    private let httpClient: HTTPClient

    // MARK: - Init

    init(
        httpClient: HTTPClient
    ) {
        self.httpClient = httpClient
    }

    // MARK: - Public Methods

    func gpuID(for name: String) async throws -> String? {
        let request = URLRequest(
            url: baseURL.appendingPathComponent("gpu-data.json"),
            cachePolicy: .reloadRevalidatingCacheData 
        )

        let gpus: GPUContainerResponse = try await httpClient.request(request: request)

        if let desktop = gpus.desktop[name] {
            return desktop
        }

        if let notebook = gpus.notebook[name] {
            return notebook
        }

        return nil
    }

    func osID(for os: OS) async throws -> String? {
        let request = URLRequest(
            url: baseURL.appendingPathComponent("os-data.json"),
            cachePolicy: .reloadRevalidatingCacheData 
        )

        let oses: [OperatingSystemResponse] = try await httpClient.request(request: request)

        let version = "\(os.version.major).\(os.version.minor)"
        let bit = os.is64Bit ? "64" : "32"

        return oses.first { $0.code == version && $0.name.contains(bit) }?.id
    }
}