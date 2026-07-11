// swift-tools-version:5.9
import PackageDescription

// HRVCore is the platform-agnostic passive HRV core (Foundation only). It
// compiles and tests on Windows/Linux/macOS -- the app targets that import
// HealthKit/SwiftUI live in the Xcode project (project.yml), not here.
let package = Package(
    name: "HRVCore",
    platforms: [.macOS(.v13), .iOS(.v17), .watchOS(.v10)],
    products: [
        .library(name: "HRVCore", targets: ["HRVCore"]),
    ],
    targets: [
        .target(name: "HRVCore"),
        .testTarget(name: "HRVCoreTests", dependencies: ["HRVCore"]),
    ]
)
