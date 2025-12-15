// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "Gecko",
    products: [
        .executable(name: "Gecko", targets: ["Gecko"])
    ],
    dependencies: [
        .package(path: "D:\\Development\\Workspace\\swift-windowsfoundation"),
        .package(path: "D:\\Development\\Workspace\\swift-windowsappsdk"),
    ],
    targets: [
        .executableTarget(
            name: "Gecko",
            dependencies: [
                .product(name: "WindowsFoundation", package: "swift-windowsfoundation"),
                .product(name: "WinAppSDK", package: "swift-windowsappsdk"),
            ],
            path: "Sources/App",
            swiftSettings: [
                .enableUpcomingFeature("BareSlashRegexLiterals")
            ],
            linkerSettings: [
                .unsafeFlags(["-Xlinker", "/SUBSYSTEM:WINDOWS"], .when(configuration: .release)),
                .unsafeFlags(
                    ["-Xlinker", "/ENTRY:mainCRTStartup"], .when(configuration: .release)),
                .unsafeFlags([
                    "-L",
                    "D:\\Development\\Workspace\\swift-windowsappsdk\\Sources\\CWinAppSDK\\nuget\\lib",
                ]),
                .linkedLibrary("Microsoft.WindowsAppRuntime.Bootstrap"),
            ]
        )
    ]
)
