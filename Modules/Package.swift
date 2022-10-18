// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let architecture = Target.Dependency.product(name: "ComposableArchitecture", package: "swift-composable-architecture")

let targets: [Target] = [
  .target(
    name: "ApiClient",
    dependencies: [
      architecture,
      "Models",
      "NetworkClient"
    ]
  ),
  .target(
    name: "AppArchitecture",
    dependencies: [architecture]
  ),
  .target(
    name: "CurrencyListFeature",
    dependencies: [
      architecture,
      "AppArchitecture",
      "Models"
    ]
  ),
  .target(
    name: "NetworkClient"
  ),
  .target(
    name: "UserDefaultsClient",
    dependencies: ["Models"]
  ),
  .target(
    name: "RateListFeature",
    dependencies: [
      "ApiClient",
      architecture,
      "AppArchitecture",
      "CurrencyListFeature",
      "Models",
      "UserDefaultsClient",
      "RateDetailsFeature"
    ]
  ),
  .target(
    name: "RateDetailsFeature",
    dependencies: [
      "ApiClient",
      architecture,
      "AppArchitecture",
      "Models"
    ]
  ),
  .target(
    name: "Models"
  )
]

let testTargets: [Target] = []

let package = Package(
  name: "Modules",
  platforms: [.iOS(.v14)],
  products: targets
    .map { .library(name: $0.name, targets: [$0.name]) },
  dependencies: [
    .package(
      url: "https://github.com/pointfreeco/swift-composable-architecture",
      from: "0.40.2"
    )
  ],
  targets: targets + testTargets
)
