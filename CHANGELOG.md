# Changelog

## Unreleased

- Corrected the documentation of the base64 length limit, which `init(privateKeyBase64:)` counts in UTF-8 bytes and not in characters, and added tests for a text of 44 characters that is 45 bytes long and a text of 43 characters that is 44 bytes long. Corrected the `CFBundleIdentifier` rule in `CONTRIBUTING.md` to the values the signing step accepts, and added test cases for them.
- Reordered the README into a definition, Learn more, Basic usage, Building, Community and License, with the tunnel dated from the swift-tunnel roadmap, macOS first in the Platforms badge, License spelled in American English, and a link to the Discord server in Community.
- Moved the test notes and the notes on what the code protects into `CONTRIBUTING.md`, which also gives the forms of a commit subject, a pull request title and a branch name.
- Merged two consecutive guards with the same body in the base64 decoder.
- Added a manual trigger to CI.
- Extended the signing step. It refuses a setting written as `KEY: value` or `"KEY": "value"` anywhere on a line, a `CFBundleIdentifier` in a property list that does not start with the prefix, a team identifier under `com.apple.developer.team-identifier`, a team id in an entitlement value, and a file that Git treats as binary and that names a signing setting. `scripts/test-signing-check` has a case for each.
- Pinned swift-tunnel at the revision that names its module `Tunnel`. VPNCore links the `X25519` product.
- Removed `GCC_TREAT_WARNINGS_AS_ERRORS` and `ASSETCATALOG_COMPILER_APPICON_NAME`.
- Split `KeyPairError.invalidLength` in two. `invalidLength` covers a private key that is not 32 bytes long, and `invalidTextLength` covers base64 text that is not 44 characters long.
- Added the check script, the pre-push hook and the CI workflow. The check reads the tracked files as Git stores them and fails when one sets a development team, a code signing identity or a provisioning profile, sets a bundle identifier prefix other than `com.example`, sets a bundle identifier that does not start with the prefix, or is a signing asset such as a key, certificate, `ExportOptions.plist` or `Config/Local.xcconfig`. It also fails outside a Git repository and when Git returns an error. `scripts/test-signing-check` tests it in throwaway repositories.
- Added the app and the packet tunnel extension.
- Added the key pair, with its private and public keys as bytes and as standard base64. The base64 text is encoded and decoded in buffers that are overwritten with zeros before release, and the check that a text is canonical compares in constant time. `init(privateKeyBase64:)` rejects text that is not exactly 44 characters before it copies or decodes anything. The package tests the RFC 7748 keys, the RFC 4648 base64 vectors and the usage example in the README.
- Pinned swift-tunnel to a commit instead of a branch, turned warnings into errors for the package and the Xcode project, and removed the code signing identity from the project file.
