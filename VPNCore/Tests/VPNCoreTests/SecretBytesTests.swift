// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import Testing
@testable import VPNCore

struct SecretBytesTests {
  @Test func `equal byte strings compare equal`() {
    let bytes = (0 ..< 32).map { UInt8($0) }
    let empty: [UInt8] = []
    let sameBytes = constantTimeEqual(bytes.span, bytes.span)
    let sameEmpty = constantTimeEqual(empty.span, empty.span)
    #expect(sameBytes)
    #expect(sameEmpty)
  }

  @Test(arguments: [0, 15, 31])
  func `a difference at any position is found`(position: Int) {
    let bytes = [UInt8](repeating: 9, count: 32)
    var other = bytes
    other[position] ^= 0x80
    let equal = constantTimeEqual(bytes.span, other.span)
    #expect(!equal)
  }

  @Test func `byte strings of different lengths differ`() {
    let bytes = [UInt8](repeating: 9, count: 32)
    let shorter = Array(bytes.dropLast())
    let empty: [UInt8] = []
    let equalToShorter = constantTimeEqual(bytes.span, shorter.span)
    let equalToEmpty = constantTimeEqual(bytes.span, empty.span)
    #expect(!equalToShorter)
    #expect(!equalToEmpty)
  }

  @Test func `wiping overwrites every byte with zero`() {
    var bytes = [UInt8](repeating: 0xFF, count: 44)
    wipe(&bytes)
    #expect(bytes == [UInt8](repeating: 0, count: 44))
  }

  @Test func `wiping an empty array does nothing`() {
    var bytes: [UInt8] = []
    wipe(&bytes)
    #expect(bytes.isEmpty)
  }
}
