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
    dependencies: [],
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
                .linkedFramework("ServiceManagement"),
                .linkedFramework("Translation"),
                .linkedFramework("NaturalLanguage")
            ]
        ),
        .executableTarget(
            name: "Cometrans",
            dependencies: [
                "CometransCore",
                "CometransMacSupport"
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
            resources: [
                .process("Resources")
            ],
            linkerSettings: [
                .linkedFramework("AppKit")
            ]
        ),
        .testTarget(
            name: "CometransTests",
            dependencies: ["CometransCore"],
            path: "Tests/CometransTests"
        )
    ]
)
