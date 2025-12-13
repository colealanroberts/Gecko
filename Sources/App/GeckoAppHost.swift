import CWinAppSDK
import Foundation
import WinSDK
import WinUI

// MARK: - GeckoAppHost

@main
enum GeckoAppHost {
    public static func main() async throws {

        defer {
            MddBootstrapShutdown()
        }

        RoInitialize(RO_INIT_SINGLETHREADED)

        MddBootstrapInitialize2(
            UINT32(WINDOWSAPPSDK_RELEASE_MAJORMINOR),
            WINDOWSAPPSDK_RELEASE_VERSION_TAG_SWIFT,
            .init(),
            MddBootstrapInitializeOptions(MddBootstrapInitializeOptions_OnNoMatch_ShowUI.rawValue | MddBootstrapInitializeOptions_OnError_DebugBreak_IfDebuggerAttached.rawValue)
        )

        try! Application.start { _ in
            _ = GeckoApp()
        }
    }
}