// swift-tools-version: 5.9
import PackageDescription

let package = Package(
  name: "swift-tracing",
  platforms: [
    .macOS(.v10_15),
    .iOS(.v13),
    .tvOS(.v13),
    .watchOS(.v6),
  ],
  products: [
    .library(name: "Tracing", targets: ["Tracing"]),
    .library(name: "InMemoryTracing", targets: ["InMemoryTracing"]),
    .library(name: "TracingInstrumentation", targets: ["TracingInstrumentation"]),
  ],
  targets: [
    .target(
      name: "Tracing",
      swiftSettings: [.enableUpcomingFeature("StrictConcurrency")]
    ),
    .target(
      name: "InMemoryTracing",
      dependencies: ["Tracing"],
      swiftSettings: [.enableUpcomingFeature("StrictConcurrency")]
    ),
    .target(
      name: "TracingInstrumentation",
      dependencies: ["Tracing"],
      swiftSettings: [.enableUpcomingFeature("StrictConcurrency")]
    ),
    .testTarget(
      name: "TracingTests",
      dependencies: ["Tracing", "InMemoryTracing"]
    ),
    .testTarget(
      name: "InMemoryTracingTests",
      dependencies: ["InMemoryTracing"]
    ),
  ]
)
