// swift-tools-version: 5.10
import PackageDescription
import Foundation

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

let package = Package(
    name: "Gecko",
    products: products,
    dependencies: dependencies,
    targets: [app]
)
