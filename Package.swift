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
    .library(name: "BBCodeParser", targets: ["BBCodeParser"]),
    .library(name: "BBCodeUI", targets: ["BBCodeUI"]),
  ],
  dependencies: [
    .package(url: "https://github.com/ordo-one/package-benchmark", .upToNextMajor(from: "1.4.0"))
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
    .target(
      name: "BBCodeUI",
      dependencies: [
        "BBCodeParser"
      ]
    ),
  ]
)

// Benchmark of BBCode parsing
package.targets += [
  .executableTarget(
    name: "BBCodeParseBenchmark",
    dependencies: [
      .product(name: "Benchmark", package: "package-benchmark"),
      .target(name: "BBCodeParser"),
    ],
    path: "Benchmarks/BBCodeParseBenchmark",
    resources: [
      .copy("../Resources")
    ],
    plugins: [
      .plugin(name: "BenchmarkPlugin", package: "package-benchmark")
    ],
  )
]

// Benchmark of HTML rendering
package.targets += [
  .executableTarget(
    name: "HTMLRenderBenchmark",
    dependencies: [
      .product(name: "Benchmark", package: "package-benchmark"),
      .target(name: "BBCodeParser"),
    ],
    path: "Benchmarks/HTMLRenderBenchmark",
    resources: [
      .copy("../Resources")
    ],
    plugins: [
      .plugin(name: "BenchmarkPlugin", package: "package-benchmark")
    ],
  )
]
