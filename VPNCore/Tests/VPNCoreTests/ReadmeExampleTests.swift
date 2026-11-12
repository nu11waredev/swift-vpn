// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import Testing
import VPNCore

/// The usage example in the README, word for word.
struct ReadmeExampleTests {
  @Test func `the README example compiles and restores the same public key`() throws {
    // README begins. The sentence before the sample names the import, which is at the top of
    // this file.
    let pair = KeyPair()
    let privateKey = pair.privateKeyBase64
    let publicKey = pair.publicKeyBase64

    let restored = try KeyPair(privateKeyBase64: privateKey)
    // README ends

    // These assertions are not in the README.
    #expect(restored.publicKeyBase64 == publicKey)
  }
}
