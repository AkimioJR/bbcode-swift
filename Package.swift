// swift-tools-version:6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "BBCode",
  platforms: [
    .macOS(.v14),
    .iOS(.v17),
    .tvOS(.v17),
    .watchOS(.v10),
    .visionOS(.v1),
  ],
  products: [
    .library(name: "BBCodeParser", targets: ["BBCodeParser"])

  ],
  dependencies: [

  ],
  targets: [
    .target(
      name: "BBCodeParser",
      dependencies: []
    ),
    .testTarget(
      name: "BBCodeParserTests",
      dependencies: ["BBCodeParser"]
    ),
  ]
)
