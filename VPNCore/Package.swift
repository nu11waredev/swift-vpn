// swift-tools-version: 6.4
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import PackageDescription

let package = Package(
  name: "VPNCore",
  platforms: [
    .iOS(.v26),
    .macOS(.v26),
  ],
  products: [
    .library(name: "VPNCore", targets: ["VPNCore"]),
  ],
  dependencies: [
    .package(
      url: "https://github.com/nu11waredev/swift-tunnel",
      revision: "28f41ace3e10048852d4bd04cab19ddec8756072",
    ),
  ],
  targets: [
    .target(
      name: "VPNCore",
      dependencies: [
        .product(name: "X25519", package: "swift-tunnel"),
      ],
      swiftSettings: [.treatAllWarnings(as: .error)],
    ),
    .testTarget(
      name: "VPNCoreTests",
      dependencies: ["VPNCore"],
      swiftSettings: [.treatAllWarnings(as: .error)],
    ),
  ],
  swiftLanguageModes: [.v6],
)
