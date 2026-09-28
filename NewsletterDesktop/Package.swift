// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "NewsletterDesktop",
    platforms: [.macOS(.v14)],
    products: [.executable(name: "NewsletterDesktop", targets: ["NewsletterDesktop"])],
    targets: [.executableTarget(name: "NewsletterDesktop", path: ".", exclude: ["Backend", "Resources", "Package.swift", "README.md"]) ]
)
