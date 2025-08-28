// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PreCacheGen",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "PreCacheGen", targets: ["PreCacheGen"])
    ],
    dependencies: [.package(path: "../../")],
    targets: [
        .executableTarget(
            name: "PreCacheGen",
            dependencies: [
                .productItem(name: "DoriKit", package: "Greatdori", moduleAliases: nil, condition: nil)
            ]
        )
    ]
)
