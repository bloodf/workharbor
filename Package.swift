// swift-tools-version: 6.0
import PackageDescription
let package = Package(
    name: "WorkHarbor",
    platforms: [.macOS(.v14)],
    products: [.executable(name: "WorkHarbor", targets: ["WorkHarbor"]), .library(name: "HarborCore", targets: ["HarborCore"])],
    targets: [.target(name: "HarborCore"), .executableTarget(name: "WorkHarbor", dependencies: ["HarborCore"]), .testTarget(name: "HarborCoreTests", dependencies: ["HarborCore"])],
    swiftLanguageModes: [.v5]
)
