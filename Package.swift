// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "KoreanTranslator",
    platforms: [
        .macOS(.v13)
    ],
    targets: [
        .executableTarget(
            name: "KoreanTranslator",
            path: "Sources/KoreanTranslator"
        )
    ]
)
