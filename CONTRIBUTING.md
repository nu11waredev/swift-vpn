# Contributing

Issues and pull requests are welcome. For anything larger than a fix, open an issue first so the approach can be agreed before the work is done.

## Building and testing

```
scripts/check
```

`scripts/check` tests the signing step, runs the package tests, builds the app for the iOS Simulator and macOS without code signing, runs `swiftformat --lint` and fails when a tracked file carries signing values. `scripts/check signing` runs that last step alone, and `scripts/test-signing-check` tests it. `swift test --package-path VPNCore` runs the package tests alone. CI runs `scripts/check` on macOS and on Linux for every pull request and every push to `main`. `scripts/install-hooks.sh` makes `git push` run `scripts/check --pushed` first. On Linux, `scripts/check` runs the signing tests, the package tests and the signing step, and skips the app builds and the format lint, which need macOS. It needs `zsh`, `git` and `iconv`.

Signing values belong in `Config/Local.xcconfig`, which Git ignores. The signing step reads the tracked files as Git stores them, and it fails when Git does. With `--pushed` it also reads every commit being pushed, from the refs that git gives a pre-push hook on standard input, so a value that was committed and then removed is still found. A text file written as UTF-16, with or without a byte order mark and in either byte order, is read like any other. It refuses these:

- A development team, a code signing identity other than `-`, or a provisioning profile, set as `KEY = value`, `KEY=value`, `KEY: value` or `"KEY": "value"` anywhere on a line.
- A bundle identifier prefix other than `com.example`, and a `PRODUCT_BUNDLE_IDENTIFIER` that does not start with the prefix.
- In a property list or entitlements file: a development team or team identifier under `DevelopmentTeam`, `teamID` or `com.apple.developer.team-identifier`, a `CFBundleIdentifier` that does not start with `$(BUNDLE_ID_PREFIX)` or `$(PRODUCT_BUNDLE_IDENTIFIER)`, or the same names in braces, and is neither `com.example` nor a name under `com.example.`, and any string that is a team id or begins with one, such as `ABCDE12345.com.example`.
- A file that Git treats as binary, that is not UTF-16 text, and that names one of these settings or keys, because the step cannot read it. A UTF-16 file with a byte order mark that cannot be decoded is refused for the same reason.
- A signing file: a provisioning profile, certificate, key, `ExportOptions.plist` or `Config/Local.xcconfig`.

An empty value, a `-` identity and a reference such as `$(inherited)` pass.

## Tests

The key pair tests check the public keys of the two private keys in RFC 7748, section 6.1, the base64 form of both pairs, round trips through bytes and base64, and the error for each rejected input: private keys of the wrong length, base64 text that is not 44 UTF-8 bytes long, base64 that spells the wrong number of bytes, and text that is not canonical base64.

The base64 code is checked against the vectors in RFC 4648, section 10, and its length limit has its own tests. The tests of the byte comparison check its result for equal byte strings, for byte strings that differ at one position and for byte strings of different lengths. The tests of `wipe()` check that it sets every byte of an array to zero, for arrays of several sizes. It calls `memset_s` on Apple platforms and `explicit_bzero` on Linux, and `scripts/check` on Linux runs the same tests.

`scripts/test-signing-check` tests the signing step of `scripts/check` in throwaway Git repositories, with a case for each kind of value it refuses and each kind it accepts, for values in UTF-16 files and for values in commits that a push sends and that the index no longer holds.

Tests compile and check the usage example in the README.

## Commits

A commit subject is a sentence in the imperative mood. It starts with a capital letter, has no period and has no type or scope prefix, as in `Reject base64 text of the wrong length`. Names from the code are in backticks.

A pull request has the same sentence as its title. A branch is named for what it does, in lowercase words joined by hyphens, as in `packet-tunnel`, with no prefix and no issue number.

## The code

Protocol and cryptography code is written from the specification: the WireGuard paper and the RFCs it cites. Code translated from another implementation is not accepted. Other implementations are used only from the outside, for interoperability tests and benchmarks.

A change comes with tests, and a test's expected values come from a published vector or an independent implementation. A test holds the usage example in the README word for word, so a change to the example is made in `README.md` and in `VPNCore/Tests/VPNCoreTests/ReadmeExampleTests.swift` together.

## What the code protects

`KeyPair` takes its private key from the system random number generator and holds it in swift-tunnel's `X25519PrivateKey`, which cannot be copied and overwrites its 32 bytes with zeros in its deinitializer, immediately before the memory is released. A `KeyPair` cannot be copied either.

`init(privateKeyBase64:)` rejects any text that is not exactly 44 UTF-8 bytes long before it copies or decodes anything. It then decodes the text, encodes the bytes again and checks that the two texts match. Each buffer in between is overwritten with zeros before it is released, and the comparison takes the same time wherever the texts differ.

`privateKeyBytes` and `privateKeyBase64` return copies that the caller owns and looks after. The caller overwrites a returned array when it is done with it. Pass and read the key as bytes when it must be wiped. A `String` stays in memory until the system reuses it, whether `privateKeyBase64` returned it or `init(privateKeyBase64:)` received it.

## Security

Report a vulnerability privately, as [`SECURITY.md`](SECURITY.md) describes.

## License

Contributions are made under the Mozilla Public License 2.0, the license of the repository.
