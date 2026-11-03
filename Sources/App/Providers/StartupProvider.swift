import Foundation
import WinSDK

/// Registers only this executable for the current user; no elevation is required.
final class StartupProvider {
    private let logger: Logging

    init(logger: Logging) {
        self.logger = logger
    }

    func configure(enabled: Bool) {
        do {
            let process = Process()
            process.executableURL = URL(fileURLWithPath:
                "\(ProcessInfo.systemRoot)\\System32\\reg.exe")
            let key = "HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Run"
            if enabled {
                var buffer = [WCHAR](repeating: 0, count: 32_768)
                let count = GetModuleFileNameW(nil, &buffer, DWORD(buffer.count))
                guard count > 0, count < buffer.count else {
                    logger.warning("Unable to locate executable for startup registration.")
                    return
                }
                let executable = String(decoding: buffer.prefix(Int(count)), as: UTF16.self)
                process.arguments = ["add", key, "/v", "Gecko", "/t", "REG_SZ",
                                     "/d", "\"\(executable)\"", "/f"]
            } else {
                process.arguments = ["delete", key, "/v", "Gecko", "/f"]
            }
            process.standardOutput = FileHandle.nullDevice
            process.standardError = FileHandle.nullDevice
            try process.run()
            process.waitUntilExit()
            if enabled && process.terminationStatus != 0 {
                logger.warning("Unable to register Gecko at startup (\(process.terminationStatus)).")
            }
        } catch {
            logger.warning("Unable to configure startup: \(error.localizedDescription)")
        }
    }
}
