import CWinAppSDK
import WinSDK
import Dispatch

// MARK: - GeckoAppHost

@main
enum GeckoAppHost {
    public static func main() {

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

        let app = GeckoApp()
        app.launch()

        dispatchMain()
    }
}