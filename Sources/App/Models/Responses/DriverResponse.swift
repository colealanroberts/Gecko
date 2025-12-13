import FoundationEssentials

// MARK: - DriverResponse

struct DriverResponse: Decodable {
    /// Whether the request was successful.
    let success: String

    /// A list of downloads.
    let downloads: [Download]

    enum CodingKeys: String, CodingKey {
        case success = "Success"
        case downloads = "IDS"
    }
}

// MARK: - DriverResponse+Download

extension DriverResponse {
    /// Represents a downloadable driver.
    struct Download: Decodable {
        /// The url to the download.
        let url: URL

        /// The version of the driver.
        let version: String

        enum CodingKeys: String, CodingKey {
            case downloadInfo
        }

        enum DownloadInfoKeys: String, CodingKey {
            case url = "DownloadURL"
            case version = "Version"
        }

        init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let info = try container.nestedContainer(keyedBy: DownloadInfoKeys.self, forKey: .downloadInfo)

            self.url = try info.decode(URL.self, forKey: .url)
            self.version = try info.decode(String.self, forKey: .version)
        }
    }
}