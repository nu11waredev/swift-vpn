// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import X25519

/// A WireGuard key pair: an X25519 private key of 32 bytes and the public key
/// derived from it.
///
/// RFC 7748, section 5, defines the private key, which it calls the scalar, and
/// the public key as the scalar times the base point. The WireGuard paper,
/// section 1, writes each key as standard base64 in 44 characters.
///
/// The pair cannot be copied, and the private key inside is wiped when the
/// pair ends. A value that leaves the pair, such as `privateKeyBytes` or
/// `privateKeyBase64`, is a copy that the caller owns and must look after.
public struct KeyPair: ~Copyable, Sendable {
  /// The length of a key in standard base64. Ten groups of 3 bytes and a last
  /// group of 2 bytes make 11 groups of 4 characters, the last with one padding
  /// mark.
  private static let base64Length = 44

  /// The private key, which RFC 7748 calls the scalar.
  private let scalar: X25519PrivateKey
  private let derivedPublicKey: X25519PublicKey

  /// Makes a new pair. The private key is 32 bytes from the system random
  /// number generator, and the public key is derived from it as RFC 7748,
  /// section 6.1, describes.
  public init() {
    self.init(scalar: X25519PrivateKey())
  }

  /// Makes the pair for a stored private key, which is 32 bytes as in RFC 7748,
  /// section 5. The bytes are used as given and not changed.
  ///
  /// - Parameter privateKeyBytes: The 32 bytes of the private key. The caller
  ///   owns this array and wipes it when it is no longer needed.
  /// - Throws: `KeyPairError.invalidLength` when `privateKeyBytes` is not
  ///   32 bytes long.
  public init(privateKeyBytes: [UInt8]) throws(KeyPairError) {
    try self.init(scalar: Self.makePrivateKey(from: privateKeyBytes.span))
  }

  /// Makes the pair for a stored private key written in standard base64, the
  /// form the WireGuard paper, section 1, uses for keys.
  ///
  /// The text must be the canonical spelling of its bytes: the standard
  /// alphabet, padding where RFC 4648, section 4, puts it, and zero bits in
  /// the padding. The decoding works on buffers that this initializer wipes
  /// before it returns. The `String` passed in belongs to the caller, who
  /// decides how long it lives.
  ///
  /// - Parameter privateKeyBase64: The private key in standard base64, 44
  ///   characters.
  /// - Throws: `KeyPairError.invalidTextLength` when the text is not exactly 44
  ///   UTF-8 bytes long, which is checked before the text is copied or decoded.
  ///   The length is counted in bytes, so a text of 44 characters is rejected
  ///   for its length when any of them takes more than one byte.
  ///   `KeyPairError.invalidBase64` when the text is not canonical standard
  ///   base64. `KeyPairError.invalidLength` when the bytes it spells are not
  ///   32 bytes long.
  public init(privateKeyBase64: String) throws(KeyPairError) {
    guard privateKeyBase64.utf8.count == Self.base64Length else {
      throw .invalidTextLength
    }
    var text = Array(privateKeyBase64.utf8)
    defer { wipe(&text) }
    guard var bytes = Base64.decodeCanonical(text.span, maximumLength: Self.base64Length) else {
      throw .invalidBase64
    }
    defer { wipe(&bytes) }
    try self.init(privateKeyBytes: bytes)
  }

  private init(scalar: consuming X25519PrivateKey) {
    derivedPublicKey = scalar.publicKey
    self.scalar = scalar
  }

  /// The 32 bytes of the private key as RFC 7748, section 5, defines them,
  /// before clamping.
  ///
  /// The array is a copy that the caller owns. It is not wiped when the pair
  /// ends, so the caller wipes it, or lets it go as soon as it has used it.
  public var privateKeyBytes: [UInt8] {
    Self.copy(of: scalar.span)
  }

  /// The 32 bytes of the public key, the u-coordinate of RFC 7748, section 5,
  /// in little-endian order.
  public var publicKeyBytes: [UInt8] {
    Self.copy(of: derivedPublicKey.span)
  }

  /// The private key in standard base64, 44 characters.
  ///
  /// The string is a copy that the caller owns. Swift cannot overwrite a
  /// `String`, so the text stays in memory until the system reuses it. A caller
  /// that needs the key in memory for less time reads `privateKeyBytes`
  /// instead.
  public var privateKeyBase64: String {
    Self.base64(of: scalar.span)
  }

  /// The public key in standard base64, 44 characters.
  public var publicKeyBase64: String {
    Self.base64(of: derivedPublicKey.span)
  }

  /// The private key for 32 bytes, with the one error the key can raise
  /// mapped to this type's own.
  private static func makePrivateKey(
    from bytes: Span<UInt8>,
  ) throws(KeyPairError) -> X25519PrivateKey {
    do throws(X25519KeyError) {
      return try X25519PrivateKey(bytes.bytes)
    } catch {
      switch error {
      case .invalidLength:
        throw .invalidLength
      }
    }
  }

  /// A copy of the bytes in a new array that the caller owns.
  private static func copy(of span: Span<UInt8>) -> [UInt8] {
    // Safe because the buffer is read only inside the closure, `Array` copies
    // exactly its `count` elements into new storage, and the pointer does not
    // outlive the span it came from.
    span.withUnsafeBufferPointer { Array($0) }
  }

  /// The base64 of the bytes, built in a buffer that is wiped once the string
  /// has been made.
  private static func base64(of span: Span<UInt8>) -> String {
    var text = Base64.encode(span)
    defer { wipe(&text) }
    return String(decoding: text, as: UTF8.self)
  }
}

/// The reason a key pair could not be made from a stored private key.
public enum KeyPairError: Error, Equatable {
  /// The private key is not 32 bytes long, the size RFC 7748, section 5, gives
  /// an X25519 private key. The bytes are the ones given or the ones that the
  /// base64 text spells.
  case invalidLength
  /// The base64 text is not 44 UTF-8 bytes long, the length of 32 bytes in
  /// standard base64. Standard base64 is ASCII, so a valid key is also 44
  /// characters.
  case invalidTextLength
  /// The text is not the canonical standard base64 of RFC 4648, section 4.
  case invalidBase64
}
