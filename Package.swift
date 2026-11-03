// swift-tools-version: 5.10
import PackageDescription
import Foundation

#if os(Windows)
let dependencies: [Package.Dependency] = [
    .package(path: "Dependencies/swift-windowsfoundation"),
    .package(path: "Dependencies/swift-windowsappsdk"),
]
let app: Target = .executableTarget(
    name: "Gecko",
    dependencies: [
        .product(name: "WindowsFoundation", package: "swift-windowsfoundation"),
        .product(name: "WinAppSDK", package: "swift-windowsappsdk"),
    ],
    path: "Sources/App",
    swiftSettings: [.enableUpcomingFeature("BareSlashRegexLiterals")],
    linkerSettings: [
        .unsafeFlags(["-Xlinker", "/SUBSYSTEM:WINDOWS"], .when(configuration: .release)),
        .unsafeFlags(["-Xlinker", "/ENTRY:mainCRTStartup"], .when(configuration: .release)),
        .unsafeFlags(["-L", Context.packageDirectory + "/Dependencies/swift-windowsappsdk/Sources/CWinAppSDK/nuget/lib"]),
        .linkedLibrary("Microsoft.WindowsAppRuntime.Bootstrap"),
    ]
)
let products: [Product] = [.executable(name: "Gecko", targets: ["Gecko"])]
#else
// Exercise platform-independent behavior without requiring Windows projections.
let dependencies: [Package.Dependency] = []
let app: Target = .target(
    name: "Gecko",
    path: "Sources/App",
    exclude: ["GeckoApp.swift", "GeckoAppHost.swift", "Models/Action.swift", "Services", "Routing", "Protocols", "UI",
              "Providers/SystemInfoProvider.swift", "Providers/StartupProvider.swift",
              "Extensions/AppNotificationProgressBar+Extension.swift",
              "Extensions/AppNotificationManager+Extension.swift",
              "Extensions/AppNotificationButton+Extension.swift",
              "Extensions/AppNotificationBuilder+Extension.swift", "Extensions/String+Extension.swift",
              "Extensions/ProcessInfo+Extension.swift"],
    sources: ["Networking", "Logging", "Models", "Providers/ConfigurationProvider.swift", "Extensions/URL+Extension.swift"]
)
let products: [Product] = []
#endif

let package = Package(
    name: "Gecko",
    platforms: [.macOS(.v13)],
    products: products,
    dependencies: dependencies,
    targets: [app, .testTarget(name: "GeckoTests", dependencies: ["Gecko"]) ]
)
