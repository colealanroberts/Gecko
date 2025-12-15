/// Represents versioning and bitness of the operating system.
struct OS {
    /// The backing version.
    let version: Version
 
    /// Whether the system is 32 or 64 bit.
    let is64Bit: Bool
}