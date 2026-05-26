// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "pdfx",
    platforms: [
        .macOS("10.11")
    ],
    products: [
        .library(name: "pdfx", targets: ["pdfx"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "pdfx",
            dependencies: [],
            cSettings: [
                .headerSearchPath(".")
            ]
        )
    ]
)
