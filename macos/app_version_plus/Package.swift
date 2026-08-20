// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "app_version_plus",
    platforms: [
        .macOS("10.15")
    ],
    products: [
        .library(name: "app-version-plus", targets: ["app_version_plus"])
    ],
    dependencies: [
        .package(name: "FlutterMacOSFramework", path: "../FlutterMacOSFramework")
    ],
    targets: [
        .target(
            name: "app_version_plus",
            dependencies: [
                .product(name: "FlutterMacOSFramework", package: "FlutterMacOSFramework")
            ],
            resources: [
                .process("PrivacyInfo.xcprivacy")
            ]
        )
    ]
)
