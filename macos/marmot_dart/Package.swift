// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "marmot_dart",
    platforms: [
        .macOS("10.15")
    ],
    products: [
        .library(name: "marmot-dart", targets: ["marmot_dart"])
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework")
    ],
    targets: [
        .target(
            name: "marmot_dart",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ],
            path: "Sources/marmot_dart",
            sources: ["dummy_file.c"],
            linkerSettings: [
                .linkedLibrary("marmot_dart"),
                .unsafeFlags(["-L", "$(BUILT_PRODUCTS_DIR)/marmot_dart"])
            ]
        )
    ]
)
