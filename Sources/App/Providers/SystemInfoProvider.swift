import Foundation
import WinSDK

// MARK: - OSProviding

protocol OSProviding {
    /// Returns the current version of Windows on this machine, including bitness.
    func currentOS() -> OS?
}

// MARK: - GPUProviding
protocol GPUProviding {
    /// Returns the current gpu (`GPU`), if any.
    func currentGPU() -> GPU? 
}

// MARK: - SystemInfoProviding

typealias SystemInfoProviding = OSProviding & GPUProviding

// MARK: - SystemInfoProvider

final class SystemInfoProvider: SystemInfoProviding {

    // MARK: - Private Properties

    private let logger: Logging

    // MARK: - Init

    init(
        logger: Logging
    ) {
        self.logger = logger
    }

    // MARK: - Public Methods

    func currentGPU() -> GPU? {
        let process = Process()
        let powershellPath = "\(ProcessInfo.systemRoot)\\System32\\WindowsPowerShell\\v1.0\\powershell.exe"
        
        process.executableURL = URL(fileURLWithPath: powershellPath)

        process.arguments = [
            "-NoProfile",
            "-NonInteractive",
            "-Command",
            "Get-CimInstance Win32_VideoController | Select-Object -First 1 Name, DriverVersion | ConvertTo-Json -Compress"
        ]
        
        let output = Pipe()
        let error = Pipe()

        process.standardOutput = output
        process.standardError = error
        
        do {
            try process.run()
            process.waitUntilExit()
            
            guard process.terminationStatus == 0 else {
                logger.warning("terminationStatus: \(process.terminationReason)")
                return nil
            }

            guard let data = try output.fileHandleForReading.readToEnd() else {
                logger.warning("Unable to construct data.")
                return nil
            }

            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                logger.warning("Unable to construct a valid JSON object.")
                return nil
            }

            logger.debug(json.description)

            guard let name = json["Name"] as? String else {
                logger.warning("Unable to find a valid name.")
                return nil
            } 

            guard let version = json["DriverVersion"] as? String else {
                logger.warning("Unablet to construct a valid driver version.")
                return nil
            }

            return GPU(
                rawName: name, 
                rawVersion: version
            )
        } catch {
            logger.warning(error.localizedDescription)
            return nil
        }
    }

    func currentOS() -> OS? {
        var osvi = OSVERSIONINFOEXW()
        
        osvi.dwOSVersionInfoSize = UInt32(MemoryLayout<OSVERSIONINFOEXW>.size)

        guard let ntdll = "ntdll.dll".wide.withUnsafeBufferPointer ({ LoadLibraryW($0.baseAddress) }) else {
            logger.critical("Unable to load library ntdll.dll")
            return nil
        }

        defer {
            FreeLibrary(ntdll)
        }
        
        guard let proc = GetProcAddress(ntdll, "RtlGetVersion") else {
            logger.critical("Failed to retrieve os information.")
            return nil
        }

        typealias RtlGetVersionType = @convention(c) (UnsafeMutablePointer<OSVERSIONINFOEXW>) -> Int32
        let getVersion = unsafeBitCast(proc, to: RtlGetVersionType.self)

        _ = getVersion(&osvi)

        let is64Bit: Bool = {
            var info = SYSTEM_INFO()
            GetNativeSystemInfo(&info)

            switch info.wProcessorArchitecture {
                case UInt16(PROCESSOR_ARCHITECTURE_AMD64),
                    UInt16(PROCESSOR_ARCHITECTURE_ARM64),
                    UInt16(PROCESSOR_ARCHITECTURE_IA64):
                    return true
                default:
                return false
            }
        }()

        return OS(
            version: .init(
                major: Int(osvi.dwMajorVersion), 
                minor: Int(osvi.dwMinorVersion)
            ),
            is64Bit: is64Bit
        )
    }
}