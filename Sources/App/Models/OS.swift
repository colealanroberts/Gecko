import FoundationEssentials

struct OS {
    /// The backing version.
    let version: Version
 
    /// Whether the system is 32 or 64 bit.
    let is64Bit: Bool
}