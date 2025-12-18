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

        /// The details url, opening the default web browser.
        let detailsURL: URL?

        /// The filename of the download.
        var fileName: String {
            url.lastPathComponent
        }

        enum CodingKeys: String, CodingKey {
            case downloadInfo
        }

        enum DownloadInfoKeys: String, CodingKey {
            case url = "DownloadURL"
            case version = "Version"
            case detailsURL = "DetailsURL"
        }

        init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let info = try container.nestedContainer(keyedBy: DownloadInfoKeys.self, forKey: .downloadInfo)

            self.url = try info.decode(URL.self, forKey: .url)
            self.version = try info.decode(String.self, forKey: .version)
            let urlString = try info.decode(String.self, forKey: .detailsURL)
            self.detailsURL = URL(string: urlString)
        }
    }
}