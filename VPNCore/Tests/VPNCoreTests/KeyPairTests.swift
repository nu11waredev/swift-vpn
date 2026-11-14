// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import Testing
import VPNCore

/// A key pair from RFC 7748, section 6.1, with each key also written in base64.
/// The RFC gives the keys in hexadecimal. The base64 strings are the standard
/// base64 encodings of those hexadecimal values.
struct RFC7748KeyPair: CustomTestStringConvertible, Sendable {
  let name: String
  let privateHex: String
  let publicHex: String
  let privateBase64: String
  let publicBase64: String

  var testDescription: String {
    name
  }

  static let alice = RFC7748KeyPair(
    name: "Alice",
    privateHex: "77076d0a7318a57d3c16c17251b26645df4c2f87ebc0992ab177fba51db92c2a",
    publicHex: "8520f0098930a754748b7ddcb43ef75a0dbf3a0d26381af4eba4a98eaa9b4e6a",
    privateBase64: "dwdtCnMYpX08FsFyUbJmRd9ML4frwJkqsXf7pR25LCo=",
    publicBase64: "hSDwCYkwp1R0i33ctD73Wg2/Og0mOBr066SpjqqbTmo=",
  )

  static let bob = RFC7748KeyPair(
    name: "Bob",
    privateHex: "5dab087e624a8a4b79e17f8b83800ee66f3bb1292618b6fd1c2f8b27ff88e0eb",
    publicHex: "de9edb7d7b7dc1b4d35b61c2ece435373f8343c85b78674dadfc7e146f882b4f",
    privateBase64: "XasIfmJKikt54X+Lg4AO5m87sSkmGLb9HC+LJ/+I4Os=",
    publicBase64: "3p7bfXt9wbTTW2HC7OQ1Nz+DQ8hbeGdNrfx+FG+IK08=",
  )

  static let all = [alice, bob]
}

/// The bytes that a string of hexadecimal digit pairs spells.
func bytesFromHex(_ hex: String) -> [UInt8] {
  var result: [UInt8] = []
  var index = hex.startIndex
  while index < hex.endIndex {
    let next = hex.index(index, offsetBy: 2)
    result.append(UInt8(hex[index ..< next], radix: 16)!)
    index = next
  }
  return result
}

struct KeyPairTests {
  /// Texts of 44 characters, the length of a key, that are not canonical base64.
  /// They are built around the base64 of 32 zero bytes, which is 43 "A" and one
  /// "=".
  static let textsThatAreNotBase64: [String] = {
    let a42 = String(repeating: "A", count: 42)
    let a43 = String(repeating: "A", count: 43)
    var texts = [String(repeating: "!", count: 44)]
    // A character outside the alphabet.
    texts.append(a42 + "*=")
    // The URL-safe spelling of 63.
    texts.append(a42 + "_=")
    // Padding in the wrong place.
    texts.append("=" + a43)
    // A space inside.
    texts.append(String(repeating: "A", count: 20) + " " + String(repeating: "A", count: 22) + "=")
    // A newline where the padding belongs.
    texts.append(a42 + "=\n")
    // A nonzero bit in the padding.
    texts.append(a42 + "B=")
    return texts
  }()

  @Test(arguments: RFC7748KeyPair.all)
  func `the public key of an RFC 7748 private key`(published: RFC7748KeyPair) throws {
    let keyPair = try KeyPair(privateKeyBytes: bytesFromHex(published.privateHex))
    #expect(keyPair.privateKeyBytes == bytesFromHex(published.privateHex))
    #expect(keyPair.publicKeyBytes == bytesFromHex(published.publicHex))
  }

  @Test(arguments: RFC7748KeyPair.all)
  func `the base64 of an RFC 7748 pair`(published: RFC7748KeyPair) throws {
    let keyPair = try KeyPair(privateKeyBytes: bytesFromHex(published.privateHex))
    #expect(keyPair.privateKeyBase64 == published.privateBase64)
    #expect(keyPair.publicKeyBase64 == published.publicBase64)
  }

  @Test(arguments: RFC7748KeyPair.all)
  func `a pair made from base64`(published: RFC7748KeyPair) throws {
    let keyPair = try KeyPair(privateKeyBase64: published.privateBase64)
    #expect(keyPair.privateKeyBytes == bytesFromHex(published.privateHex))
    #expect(keyPair.publicKeyBytes == bytesFromHex(published.publicHex))
    #expect(keyPair.publicKeyBase64 == published.publicBase64)
  }

  @Test func `generated keys are 32 bytes`() {
    let pair = KeyPair()
    #expect(pair.privateKeyBytes.count == 32)
    #expect(pair.publicKeyBytes.count == 32)
  }

  @Test func `generated pairs differ`() {
    let first = KeyPair()
    let second = KeyPair()
    #expect(first.privateKeyBytes != second.privateKeyBytes)
    #expect(first.publicKeyBytes != second.publicKeyBytes)
  }

  @Test func `generated pair round trips through bytes`() throws {
    let pair = KeyPair()
    let copy = try KeyPair(privateKeyBytes: pair.privateKeyBytes)
    #expect(copy.privateKeyBytes == pair.privateKeyBytes)
    #expect(copy.publicKeyBytes == pair.publicKeyBytes)
  }

  @Test func `generated pairs round trip through base64`() throws {
    for _ in 0 ..< 100 {
      let pair = KeyPair()
      let copy = try KeyPair(privateKeyBase64: pair.privateKeyBase64)
      #expect(copy.privateKeyBytes == pair.privateKeyBytes)
      #expect(copy.publicKeyBase64 == pair.publicKeyBase64)
    }
  }

  @Test(arguments: [0, 1, 31, 33, 64])
  func `a private key of the wrong length is rejected`(count: Int) {
    #expect(throws: KeyPairError.invalidLength) {
      _ = try KeyPair(privateKeyBytes: [UInt8](repeating: 7, count: count))
    }
  }

  /// The base64 of 32 zero bytes: 43 "A" and one "=".
  static let validText = String(repeating: "A", count: 43) + "="

  /// Texts that are shorter or longer than 44 UTF-8 bytes, none of them long.
  static let textsOfTheWrongLength: [String] = [
    // Empty.
    "",
    // Truncated: a short text, and the valid text with one or two characters cut.
    "AAAAAA==",
    String(validText.dropLast(1)),
    String(validText.dropLast(2)),
    // Text that is not base64 and a key with a trailing newline.
    "not base64!",
    validText + "\n",
  ]

  @Test(arguments: Self.textsOfTheWrongLength)
  func `base64 that is not 44 UTF-8 bytes is rejected`(text: String) {
    #expect(throws: KeyPairError.invalidTextLength) {
      _ = try KeyPair(privateKeyBase64: text)
    }
  }

  /// The length is counted in UTF-8 bytes, not characters. "é" is one character
  /// and two bytes, so 43 "A" and "é" is 44 characters and 45 bytes.
  @Test func `text of 44 characters that is longer in UTF-8 is rejected for its length`() {
    let text = String(repeating: "A", count: 43) + "\u{E9}"
    #expect(text.count == 44)
    #expect(text.utf8.count == 45)
    #expect(throws: KeyPairError.invalidTextLength) {
      _ = try KeyPair(privateKeyBase64: text)
    }
  }

  /// 42 "A" and "é" is 43 characters and 44 bytes, so it passes the length check
  /// and fails as text that is not base64.
  @Test func `text of 44 UTF-8 bytes that is shorter in characters is not base64`() {
    let text = String(repeating: "A", count: 42) + "\u{E9}"
    #expect(text.count == 43)
    #expect(text.utf8.count == 44)
    #expect(throws: KeyPairError.invalidBase64) {
      _ = try KeyPair(privateKeyBase64: text)
    }
  }

  /// The valid text followed by this many more characters: one too many, twice
  /// as long, and far too long. The text is built in the test so that a report
  /// does not print it.
  @Test(arguments: [1, 44, 4052, 1 << 20])
  func `oversized base64 is rejected`(extra: Int) {
    let text = Self.validText + String(repeating: "A", count: extra)
    #expect(throws: KeyPairError.invalidTextLength) {
      _ = try KeyPair(privateKeyBase64: text)
    }
  }

  @Test(
    arguments: [
      // 31 zero bytes and 33 zero bytes, each 44 characters long.
      String(repeating: "A", count: 41) + "A==",
      String(repeating: "A", count: 44),
    ],
  )
  func `base64 of the wrong number of bytes is rejected`(text: String) {
    #expect(text.utf8.count == 44)
    #expect(throws: KeyPairError.invalidLength) {
      _ = try KeyPair(privateKeyBase64: text)
    }
  }

  @Test(arguments: Self.textsThatAreNotBase64)
  func `text that is not base64 is rejected`(text: String) {
    #expect(throws: KeyPairError.invalidBase64) {
      _ = try KeyPair(privateKeyBase64: text)
    }
  }
}
