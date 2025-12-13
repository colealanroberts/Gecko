import FoundationEssentials

/// A structure that contains *all* GPU names and identifiers for desktop and notebooks.
struct GPUContainerResponse: Decodable {
    /// A dictionary-backed structure containg *desktop* GPUs.
    let desktop: [String: String]

    /// A dictionary-backed structure containg *notebook* GPUs.
    let notebook: [String: String]
}