// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "Vigie",
    platforms: [
        .iOS(.v18),
        .macOS(.v14),
    ],
    products: [
        // xtool exige exactement un produit .library : c'est l'app.
        .library(name: "Vigie", targets: ["Vigie"]),
    ],
    targets: [
        // Noyau pur : aucun import SwiftUI ni UIKit, donc compilable et
        // testable nativement sur Arch par `swift test`. C'est la seule parade
        // à l'absence de simulateur et de débogueur.
        .target(name: "VigieNoyau"),
        .target(
            name: "Vigie",
            dependencies: ["VigieNoyau"],
            exclude: ["Charte/CHARTE.md"]
        ),
        .testTarget(name: "VigieNoyauTests", dependencies: ["VigieNoyau"]),
    ]
)
