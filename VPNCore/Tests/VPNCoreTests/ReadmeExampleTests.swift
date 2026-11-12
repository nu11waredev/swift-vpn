// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import Testing

// README begins with the import, and the rest of the sample is the body of the test.
import VPNCore

/// The usage example in the README, word for word.
struct ReadmeExampleTests {
  @Test func `the README example compiles and restores the same public key`() throws {
    let pair = KeyPair()
    let privateKey = pair.privateKeyBase64
    let publicKey = pair.publicKeyBase64

    let restored = try KeyPair(privateKeyBase64: privateKey)

    // These assertions are not in the README.
    #expect(restored.publicKeyBase64 == publicKey)
  }
}
