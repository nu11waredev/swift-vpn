// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import Testing
@testable import VPNCore

struct Base64Tests {
  /// The test vectors of RFC 4648, section 10.
  static let rfc4648Vectors: [(plain: String, encoded: String)] = [
    ("", ""),
    ("f", "Zg=="),
    ("fo", "Zm8="),
    ("foo", "Zm9v"),
    ("foob", "Zm9vYg=="),
    ("fooba", "Zm9vYmE="),
    ("foobar", "Zm9vYmFy"),
  ]

  /// The 64 characters of the standard alphabet in order, and the 48 bytes they
  /// stand for, from Python's `base64.b64decode`.
  static let alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
  static let alphabetBytes: [UInt8] = [
    0x00, 0x10, 0x83, 0x10, 0x51, 0x87, 0x20, 0x92, 0x8B, 0x30, 0xD3, 0x8F, 0x41, 0x14, 0x93, 0x51,
    0x55, 0x97, 0x61, 0x96, 0x9B, 0x71, 0xD7, 0x9F, 0x82, 0x18, 0xA3, 0x92, 0x59, 0xA7, 0xA2, 0x9A,
    0xAB, 0xB2, 0xDB, 0xAF, 0xC3, 0x1C, 0xB3, 0xD3, 0x5D, 0xB7, 0xE3, 0x9E, 0xBB, 0xF3, 0xDF, 0xBF,
  ]

  /// Texts that are not the canonical standard base64 of any byte string.
  static let rejectedTexts: [String] = [
    // A length that is not a multiple of 4, with and without padding.
    "Zg=",
    "Zg",
    "Zm9vY",
    // Padding in the wrong place or too much of it.
    "Z===",
    "====",
    "Zg==Zg==",
    "Zm9vYg=A",
    // A character outside the standard alphabet.
    "Zm9*",
    "Zm9_",
    "Zm-v",
    "Zm9v\n",
    " Zm9v",
    "Zmé",
    // Nonzero bits in the padding, which a second spelling of the same bytes would use.
    "Zh==",
    "Zm9=",
  ]

  @Test(arguments: rfc4648Vectors)
  func `encodes the RFC 4648 vectors`(plain: String, encoded: String) {
    let plainBytes = Array(plain.utf8)
    let text = Base64.encode(plainBytes.span)
    #expect(String(decoding: text, as: UTF8.self) == encoded)
  }

  @Test(arguments: rfc4648Vectors)
  func `decodes the RFC 4648 vectors`(plain: String, encoded: String) {
    let text = Array(encoded.utf8)
    let bytes = Base64.decodeCanonical(text.span, maximumLength: 64)
    #expect(bytes == Array(plain.utf8))
  }

  @Test func `every character of the alphabet encodes and decodes`() {
    let text = Base64.encode(Self.alphabetBytes.span)
    #expect(String(decoding: text, as: UTF8.self) == Self.alphabet)
    let alphabetText = Array(Self.alphabet.utf8)
    let bytes = Base64.decodeCanonical(alphabetText.span, maximumLength: 64)
    #expect(bytes == Self.alphabetBytes)
  }

  @Test(arguments: rejectedTexts)
  func `text that is not canonical base64 is rejected`(text: String) {
    let bytes = Array(text.utf8)
    #expect(Base64.decodeCanonical(bytes.span, maximumLength: 64) == nil)
  }

  @Test func `text exactly as long as the limit is decoded`() {
    let text = Array("Zm9vYmFy".utf8)
    let bytes = Base64.decodeCanonical(text.span, maximumLength: 8)
    #expect(bytes == Array("foobar".utf8))
  }

  @Test(arguments: ["Zm9vYmFy", "Zm9vYmFyZm9v", "Zg=="])
  func `text longer than the limit is rejected`(encoded: String) {
    let text = Array(encoded.utf8)
    let bytes = Base64.decodeCanonical(text.span, maximumLength: encoded.utf8.count - 1)
    #expect(bytes == nil)
  }

  @Test func `a limit of zero accepts only the empty text`() {
    let empty: [UInt8] = []
    let one = Array("Zg==".utf8)
    #expect(Base64.decodeCanonical(empty.span, maximumLength: 0) == [])
    #expect(Base64.decodeCanonical(one.span, maximumLength: 0) == nil)
  }

  @Test(arguments: rfc4648Vectors)
  func `the encoded length matches the RFC 4648 vectors`(plain: String, encoded: String) {
    #expect(Base64.encodedLength(forByteCount: plain.utf8.count) == encoded.utf8.count)
  }

  @Test(arguments: [0, 1, 2, 3, 4, 31, 32, 33, 48, 100])
  func `the encoded length is the length of the text that is encoded`(count: Int) {
    let bytes = [UInt8](repeating: 0xA5, count: count)
    #expect(Base64.encodedLength(forByteCount: count) == Base64.encode(bytes.span).count)
  }

  /// The WireGuard paper, section 1, writes a key of 32 bytes in 44 characters.
  /// The limit that `init(privateKeyBase64:)` applies is this one length.
  @Test func `a key is 44 characters of base64`() {
    #expect(KeyPair.keyLength == 32)
    #expect(KeyPair.base64Length == 44)
    #expect(KeyPair.base64Length == Base64.encodedLength(forByteCount: KeyPair.keyLength))
  }
}
