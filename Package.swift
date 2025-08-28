// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "Greatdori",
    platforms: [.iOS(.v17), .macCatalyst(.v17), .macOS(.v14), .visionOS(.v1), .watchOS(.v10)],
    products: [
        .library(name: "DoriKit", type: .dynamic, targets: ["DoriKit"])
    ],
    dependencies: [
        .package(url: "https://github.com/Alamofire/Alamofire", from: "5.10.2"),
        .package(url: "https://github.com/SwiftyJSON/SwiftyJSON", from: "5.0.2"),
        .package(url: "https://github.com/swift-library/swift-gyb", from: "0.0.1"),
        .package(url: "https://github.com/swiftlang/swift-syntax", from: "601.0.1")
    ],
    targets: [
        .target(
            name: "DoriKit",
            dependencies: [
                "Alamofire",
                "SwiftyJSON",
                "DoriKitMacros"
            ],
            path: "DoriKit/",
            resources: [
                .process("Localizable.xcstrings")
            ],
            swiftSettings: [
                .unsafeFlags(["-enable-experimental-feature", "SymbolLinkageMarkers"]),
                .unsafeFlags(["-enable-experimental-feature", "BuiltinModule"]),
                .unsafeFlags(["-enable-experimental-feature", "ClosureBodyMacro"])
            ],
            plugins: [
                .plugin(name: "Gyb", package: "swift-gyb")
            ]
        ),
        .macro(
            name: "DoriKitMacros",
            dependencies: [
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftSyntaxBuilder", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
                .product(name: "SwiftDiagnostics", package: "swift-syntax")
            ],
            path: "DoriKitMacros/"
        )
    ]
)
