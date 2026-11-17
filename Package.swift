// swift-tools-version: 5.7

import PackageDescription

let package = Package(
    name: "VLCKit",
    platforms: [.macOS(.v12)],
    products: [
        .library(
            name: "VLCKit",
            targets: ["VLCKitWrapper"]),
    ],
    targets: [
        // Built by build.sh from VLCKit 3.7.3 with patches/.
        .binaryTarget(
            name: "VLCKitBinary",
            url: "https://github.com/cathandnya/vlckit-macos-patched/releases/download/3.7.3-patched.1/VLCKit.xcframework.zip",
            checksum: "5f0edd1ca7d292e5dc1ea9c49b46902631ee4af02849b9379aae0f149f46ffee"),
        // A binary target cannot have linker settings, so a wrapper target adds
        // the frameworks and libraries listed in the official podspec.
        .target(
            name: "VLCKitWrapper",
            dependencies: ["VLCKitBinary"],
            linkerSettings: [
                .linkedFramework("Foundation"),
                .linkedLibrary("iconv"),
            ]),
    ]
)
