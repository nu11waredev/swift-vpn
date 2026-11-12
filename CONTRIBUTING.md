# Contributing

Issues and pull requests are welcome. For anything larger than a fix, open an issue first so the approach can be agreed before the work is done.

## Building and testing

```
scripts/check
```

`scripts/check` tests the signing step, runs the package tests, builds the app for the iOS Simulator and macOS without code signing, runs `swiftformat --lint` and fails when a tracked file carries signing values. `scripts/check signing` runs that last step alone, and `scripts/test-signing-check` tests it. `scripts/install-hooks.sh` makes `git push` run it first.

Signing values belong in `Config/Local.xcconfig`, which Git ignores. The signing step reads the tracked files as Git stores them, and it fails when Git does. It refuses these:

- A development team, a code signing identity other than `-`, or a provisioning profile, set as `KEY = value`, `KEY=value`, `KEY: value` or `"KEY": "value"` anywhere on a line.
- A bundle identifier prefix other than `com.example`, and a `PRODUCT_BUNDLE_IDENTIFIER` that does not start with the prefix.
- In a property list or entitlements file: a development team or team identifier under `DevelopmentTeam`, `teamID` or `com.apple.developer.team-identifier`, a `CFBundleIdentifier` that does not start with `$(BUNDLE_ID_PREFIX)` or `com.example` and is not `$(PRODUCT_BUNDLE_IDENTIFIER)`, and any string that is a team id or begins with one, such as `ABCDE12345.com.example`.
- A file that Git treats as binary and that names one of these settings or keys, because the step cannot read it.
- A signing file: a provisioning profile, certificate, key, `ExportOptions.plist` or `Config/Local.xcconfig`.

An empty value, a `-` identity and a reference such as `$(inherited)` pass.

## The code

Protocol and cryptography code is written from the specification: the WireGuard paper and the RFCs it cites. Code translated from another implementation is not accepted. Other implementations are used only from the outside, for interoperability tests and benchmarks.

A change comes with tests, and a test's expected values come from a published vector or an independent implementation.

## Commits

A commit message is a conventional commit, such as `feat: key pair in a local package`.

## Security

A vulnerability is reported privately, as `SECURITY.md` describes.

## Licence

Contributions are made under the Mozilla Public License 2.0, the licence of the repository.
