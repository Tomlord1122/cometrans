// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Cometrans",
    platforms: [
        .macOS("26.0")
    ],
    products: [
        .library(name: "CometransCore", targets: ["CometransCore"]),
        .executable(name: "Cometrans", targets: ["Cometrans"])
    ],
    dependencies: [
        .package(url: "https://github.com/sparkle-project/Sparkle", from: "2.6.0")
    ],
    targets: [
        .target(
            name: "CometransCore",
            dependencies: []
        ),
        .target(
            name: "CometransMacSupport",
            dependencies: ["CometransCore"],
            linkerSettings: [
                .linkedFramework("Carbon"),
                .linkedFramework("AppKit"),
                .linkedFramework("ApplicationServices"),
                .linkedFramework("ServiceManagement")
            ]
        ),
        .executableTarget(
            name: "Cometrans",
            dependencies: [
                "CometransCore",
                "CometransMacSupport",
                .product(name: "Sparkle", package: "Sparkle")
            ],
            path: "Sources/Cometrans",
            exclude: [
                "Contracts",
                "Model",
                "Providers",
                "Services"
            ],
            sources: [
                "CometransApp.swift",
                "UI/SettingsView.swift",
                "UI/ShortcutEditView.swift",
                "UI/ShortcutRecorderView.swift",
                "UI/AIProviderSettingsView.swift"
            ],
            linkerSettings: [
                .linkedFramework("AppKit"),
                .unsafeFlags(["-Xlinker", "-rpath", "-Xlinker", "@executable_path/../Frameworks"])
            ]
        ),
        .testTarget(
            name: "CometransTests",
            dependencies: ["CometransCore"],
            path: "Tests/CometransTests"
        )
    ]
)
