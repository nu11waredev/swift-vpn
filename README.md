# VPN

[![CI](https://img.shields.io/github/actions/workflow/status/nu11waredev/swift-vpn/ci.yml?branch=main&label=CI)](https://github.com/nu11waredev/swift-vpn/actions/workflows/ci.yml)
[![Swift 6.4](https://img.shields.io/badge/Swift-6.4-F05138?logo=swift&logoColor=white)](https://www.swift.org)
[![Platforms](https://img.shields.io/badge/Platforms-iOS%20%7C%20macOS-0969DA)](VPNCore/Package.swift)
[![Licence MPL 2.0](https://img.shields.io/badge/Licence-MPL%202.0-8250DF)](LICENSE)

VPN is a WireGuard VPN client for iOS and macOS, written in Swift and SwiftUI. The finished app covers the WireGuard tunnel and handshake, a kill switch, DNS filtering on the device, a post-quantum handshake, obfuscation, multihop and the server lists of VPN providers. Today the repository contains the Xcode project with the app and a packet tunnel extension, and a Swift package, VPNCore, with the key pair type.

## Design

The app is a SwiftUI shell around VPNCore, a local Swift package that holds the logic. The package is built and tested with `swift test`, so its tests run without a simulator. The tunnel runs in a packet tunnel extension, a subclass of `NEPacketTunnelProvider` that the system starts in its own process.

VPNCore uses [swift-tunnel](https://github.com/nu11waredev/swift-tunnel) for the WireGuard primitives, starting with X25519. The key pair follows RFC 7748 for X25519 and the WireGuard paper for the key format.

Signing values stay out of the tracked files. `Config/Base.xcconfig` sets an empty development team and the bundle identifier prefix `com.example`, and includes `Config/Local.xcconfig` when it exists. Git ignores that file, so the project builds on any Mac with Xcode.

## What is being built

Each part is tested and recorded in `CHANGELOG.md` as it lands. A part is In the package once VPNCore contains and tests it, and In the app once the app uses it.

| Part | Description | State |
| --- | --- | --- |
| Key pair | The key pair makes a WireGuard private key and its public key on the device, readable as bytes and as standard base64. | In the package |
| WireGuard tunnel and handshake | The tunnel and handshake run the WireGuard protocol in the packet tunnel extension. | Next |
| Kill switch and always-on | The kill switch blocks traffic while the tunnel is down, and always-on starts the tunnel again after a restart. | Planned |
| On-device DNS filtering | DNS filtering applies blocklists to DNS queries inside the tunnel. | Planned |
| Post-quantum handshake | The post-quantum handshake adds a post-quantum key exchange to the WireGuard handshake. | Planned |
| Obfuscation | Obfuscation carries WireGuard packets over UDP over TCP, Shadowsocks or QUIC. | Planned |
| Multihop | Multihop routes traffic through two servers in turn. | Planned |
| Provider server lists | The provider server lists are read from the lists that VPN providers publish. | Planned |
| Control Center control, widget and Shortcuts | The control, the widget and the Shortcuts actions start and stop the tunnel from Control Center, the Home Screen and the Shortcuts app. | Planned |

## Building

Clone the repository and open `VPN.xcodeproj` in Xcode. The `VPN` scheme builds the app and embeds the packet tunnel extension. From a terminal, the same build for the iOS Simulator is:

```
xcodebuild build -project VPN.xcodeproj -scheme VPN -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO
```

Use `generic/platform=macOS` for the Mac. To sign a build, create `Config/Local.xcconfig` and set `DEVELOPMENT_TEAM` and `BUNDLE_ID_PREFIX` in it. The team needs the Network Extensions capability for the packet tunnel.

`scripts/check` runs the whole check, and `CONTRIBUTING.md` describes it and the signing values it refuses.

## Usage

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
| `KeyPairError` | `KeyPairError` is thrown when a key cannot be read. `invalidLength` means the private key is not 32 bytes long, `invalidTextLength` means base64 text is not exactly 44 characters, and `invalidBase64` means the text is not the canonical standard base64 of a byte string. |

## Security

`KeyPair` takes its private key from the system random number generator and holds it in swift-tunnel's `X25519PrivateKey`, which cannot be copied and overwrites its 32 bytes with zeros in its deinitializer, immediately before the memory is released. A `KeyPair` cannot be copied either.

`init(privateKeyBase64:)` rejects any text that is not exactly 44 characters before it copies or decodes anything. It then decodes the text, encodes the bytes again and checks that the two texts match. Each buffer in between is overwritten with zeros before it is released, and the comparison takes the same time wherever the texts differ.

`privateKeyBytes` and `privateKeyBase64` return copies that the caller owns and looks after. The caller overwrites a returned array when it is done with it. Pass and read the key as bytes when it must be wiped. A `String` stays in memory until the system reuses it, whether `privateKeyBase64` returned it or `init(privateKeyBase64:)` received it.

Report a vulnerability privately from the repository's Security tab. `SECURITY.md` has the details.

## Tests

Run the package tests with `swift test --package-path VPNCore`, or run `scripts/check` to build, test and lint. The key pair tests check the public keys of the two private keys in RFC 7748, section 6.1, the base64 form of both pairs, round trips through bytes and base64, and the error for each rejected input: private keys of the wrong length, base64 text that is not 44 characters long, base64 that spells the wrong number of bytes, and text that is not canonical base64.

The base64 code is checked against the vectors in RFC 4648, section 10, and its length limit has its own tests. The tests of the byte comparison check its result for equal byte strings, for byte strings that differ at one position and for byte strings of different lengths. The test of `wipe()` checks that it sets every byte of an array to zero.

`scripts/test-signing-check` tests the signing step of `scripts/check` in throwaway Git repositories, with a case for each kind of value it refuses and each kind it accepts. A test compiles and checks the usage example above. CI runs `scripts/check` on macOS for every pull request.

## Requirements

VPN requires Swift 6.4 and Xcode 27. It runs on iOS 26 and macOS 26. Linting needs [SwiftFormat](https://github.com/nicklockwood/SwiftFormat).

## Licence

VPN is available under the Mozilla Public License 2.0. See `LICENSE`.

"WireGuard" is a registered trademark of Jason A. Donenfeld.
