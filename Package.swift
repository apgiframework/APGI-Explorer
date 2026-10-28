// swift-tools-version: 6.2
// Portable (Foundation-only) core of Explorer: transport, hashing, outbox,
// upload coordinator, credentials and research-contract validation. The same
// sources are compiled into the macOS app by Xcode (APGI-Explorer/Core is part
// of the synchronized app group). This package does NOT build the native app.
import PackageDescription

let package = Package(
  name: "ExplorerCore",
  platforms: [.macOS(.v14)],
  products: [.library(name: "ExplorerCore", targets: ["ExplorerCore"])],
  targets: [
    .target(
      name: "ExplorerCore",
      path: "APGI-Explorer/Core",
      swiftSettings: [.swiftLanguageMode(.v6)]),
    .testTarget(
      name: "ExplorerCoreTests",
      dependencies: ["ExplorerCore"],
      path: "Tests/ExplorerCoreTests",
      resources: [.copy("Fixtures")],
      swiftSettings: [.swiftLanguageMode(.v6)])
  ]
)
