// swift-tools-version: 6.2
import PackageDescription

/// Platform-neutral core shared by the watch and phone apps:
/// pin model, sync merge rules, and (next) the return detector state machine.
/// Kept free of CoreLocation and UIKit so it tests on the Mac with `swift test`.
let package = Package(
    name: "PinHereKit",
    platforms: [.iOS(.v26), .watchOS(.v26), .macOS(.v26)],
    products: [
        .library(name: "PinHereKit", targets: ["PinHereKit"]),
    ],
    targets: [
        .target(name: "PinHereKit"),
        .testTarget(name: "PinHereKitTests", dependencies: ["PinHereKit"]),
    ]
)
