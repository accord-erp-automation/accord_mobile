// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "pdfx",
    platforms: [
        .iOS("12.0")
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
