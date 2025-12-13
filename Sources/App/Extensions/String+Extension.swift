import FoundationEssentials
import WinSDK

extension String {
    var wide: [WCHAR] {
        utf16.map { WCHAR($0) } + [0]
    }
}