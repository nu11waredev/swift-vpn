# swift-vpn

[![CI](https://img.shields.io/github/actions/workflow/status/nu11waredev/swift-vpn/ci.yml?branch=main&label=CI)](https://github.com/nu11waredev/swift-vpn/actions/workflows/ci.yml)
[![Swift 6.4](https://img.shields.io/badge/Swift-6.4-F05138?logo=swift&logoColor=white)](https://www.swift.org)
[![Platforms](https://img.shields.io/badge/Platforms-macOS%20%7C%20iOS-0969DA)](VPNCore/Package.swift)
[![License MPL 2.0](https://img.shields.io/badge/License-MPL%202.0-8250DF)](LICENSE)

swift-vpn is a WireGuard VPN client for iOS and macOS, written in Swift and SwiftUI.

- [Learn more](#learn-more)
- [Basic usage](#basic-usage)
- [Building](#building)
- [Community](#community)
- [License](#license)

## Learn more

Today the repository contains the Xcode project with the app and a packet tunnel extension, and VPNCore with the key pair type. The tunnel will run in the packet tunnel extension, a subclass of `NEPacketTunnelProvider` that the system starts in its own process. It comes from swift-tunnel, whose [roadmap](https://github.com/nu11waredev/swift-tunnel/blob/main/ROADMAP.md) plans the tunnel state for 2027-01-15.

VPNCore is a local Swift package. Its tests run with `swift test --package-path VPNCore`, without a simulator. VPNCore uses the `X25519` product of [swift-tunnel](https://github.com/nu11waredev/swift-tunnel) for its key pair. The key pair follows RFC 7748 for X25519 and the WireGuard paper for the key format.

## Basic usage

Make a key pair and read it back from its base64 form:

```swift
import VPNCore

let pair = KeyPair()
let privateKey = pair.privateKeyBase64
let publicKey = pair.publicKeyBase64

let restored = try KeyPair(privateKeyBase64: privateKey)
```

| Type | Description |
| --- | --- |
| `KeyPair` | `KeyPair` is a private key of 32 random bytes from the system generator, and the public key derived from it with X25519. `init(privateKeyBytes:)` and `init(privateKeyBase64:)` make a pair from a stored private key. `privateKeyBytes`, `publicKeyBytes`, `privateKeyBase64` and `publicKeyBase64` return copies of the keys that the caller owns. |
| `KeyPairError` | `KeyPairError` is thrown when a key cannot be read. `invalidLength` means the private key is not 32 bytes long, `invalidTextLength` means base64 text is not exactly 44 UTF-8 bytes long, and `invalidBase64` means the text is not the canonical standard base64 of a byte string. |

## Building

Clone the repository and open `VPN.xcodeproj` in Xcode. The `VPN` scheme builds the app and embeds the packet tunnel extension. From a terminal, the same build for the iOS Simulator is:

```
xcodebuild build -project VPN.xcodeproj -scheme VPN -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO
```

Use `generic/platform=macOS` for the Mac.

Signing values stay out of the tracked files. `Config/Base.xcconfig` sets an empty development team and the bundle identifier prefix `com.example`, so the project builds on any Mac with Xcode 27. To sign a build, create `Config/Local.xcconfig`, which the base file includes and Git ignores, and set `DEVELOPMENT_TEAM` and `BUNDLE_ID_PREFIX` in it. The team needs the Network Extensions capability for the packet tunnel.

VPN requires Swift 6.4 and Xcode 27. It runs on iOS 26 and macOS 26. Linting needs [SwiftFormat](https://github.com/nicklockwood/SwiftFormat).

`scripts/check` runs the whole check, and [`CONTRIBUTING.md`](CONTRIBUTING.md) describes it and the signing values it refuses.

## Community

For casual chat about the project, join the [Discord server](https://discord.gg/d8KgvpAKcv). Report a bug or ask a question in the repository's [issues](https://github.com/nu11waredev/swift-vpn/issues). Report a vulnerability privately from the repository's Security tab. [`SECURITY.md`](SECURITY.md) has the details.

## License

VPN is available under the Mozilla Public License 2.0. See [`LICENSE`](LICENSE).

"WireGuard" is a registered trademark of Jason A. Donenfeld.
