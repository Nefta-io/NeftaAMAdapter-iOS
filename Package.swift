// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "NeftaAMAdapter",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "NeftaAMAdapter",
            targets: ["NeftaAMAdapter"]
        )
    ],
    targets: [
        .target(
            name: "NeftaAMAdapter",
            dependencies: ["NeftaSDK"],
            publicHeadersPath: "."
        ),
        .binaryTarget(
            name: "NeftaSDK",
            url: "https://github.com/Nefta-io/NeftaSDK-iOS/releases/download/REL_4.5.3/NeftaSDK.xcframework-4.5.3.zip",
            checksum: "2c035a98a1f5f4b02cd8afb7e5e873dfd7bad2e6077233e4e615af551bd943ed"
        )
    ]
)
