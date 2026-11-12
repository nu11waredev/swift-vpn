// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

/// The standard base64 encoding of RFC 4648, section 4, with padding, over
/// buffers the caller can wipe.
///
/// Key text goes through this type instead of Foundation so that no copy of a
/// private key sits in a `Data` or `String` that cannot be overwritten. The
/// arithmetic that maps characters to sextet values and back uses no table and
/// no branch on the sextet values. The code does branch on lengths and on where
/// padding sits, which are not secret.
enum Base64 {
  /// The standard base64 of `bytes`, as ASCII bytes.
  static func encode(_ bytes: Span<UInt8>) -> [UInt8] {
    var text = [UInt8](repeating: 0, count: (bytes.count + 2) / 3 * 4)
    var group = 0
    while group * 3 < bytes.count {
      let start = group * 3
      let remaining = bytes.count - start
      let first = UInt32(bytes[start])
      let second = remaining > 1 ? UInt32(bytes[start + 1]) : 0
      let third = remaining > 2 ? UInt32(bytes[start + 2]) : 0
      let word = first << 16 | second << 8 | third
      // One byte gives two characters, two bytes give three, three give four.
      let characters = min(remaining + 1, 4)
      for position in 0 ..< 4 {
        text[group * 4 + position] =
          position < characters
            ? character(for: (word >> UInt32(18 - 6 * position)) & 0x3F)
            : padding
      }
      group += 1
    }
    return text
  }

  /// The bytes that `text` spells in canonical standard base64, or `nil` when
  /// it is anything else: longer than `maximumLength`, a length that is not a
  /// multiple of 4, a character outside the alphabet, padding in the wrong
  /// place, or nonzero bits in the padding. The length is checked first, before
  /// anything is allocated or decoded. The caller wipes the result when it
  /// holds a secret.
  ///
  /// A text is canonical when encoding the decoded bytes gives the text back.
  /// That is checked in constant time, so a wrong guess at a key reveals
  /// nothing about where it differs.
  static func decodeCanonical(_ text: Span<UInt8>, maximumLength: Int) -> [UInt8]? {
    guard text.count <= maximumLength else { return nil }
    guard var bytes = decode(text) else { return nil }
    var canonical = encode(bytes.span)
    defer { wipe(&canonical) }
    guard constantTimeEqual(canonical.span, text) else {
      wipe(&bytes)
      return nil
    }
    return bytes
  }

  /// The bytes of `text`, which may carry nonzero padding bits, or `nil` for a
  /// bad length, a character outside the alphabet or misplaced padding.
  private static func decode(_ text: Span<UInt8>) -> [UInt8]? {
    guard text.count % 4 == 0 else { return nil }
    if text.isEmpty {
      return []
    }

    var paddingCount = 0
    if text[text.count - 1] == padding {
      paddingCount = text[text.count - 2] == padding ? 2 : 1
    }
    let groups = text.count / 4
    var bytes = [UInt8](repeating: 0, count: groups * 3 - paddingCount)
    // All ones once any character fell outside the alphabet.
    var invalid: Int32 = 0

    for group in 0 ..< groups {
      let characters = group == groups - 1 ? 4 - paddingCount : 4
      var word: UInt32 = 0
      for position in 0 ..< 4 {
        var sextet: Int32 = 0
        if position < characters {
          let decoded = value(of: text[group * 4 + position])
          sextet = decoded.value
          invalid |= ~decoded.valid
        }
        word = word << 6 | UInt32(truncatingIfNeeded: sextet)
      }
      // Two characters hold one byte, three hold two, four hold three.
      for index in 0 ..< characters * 6 / 8 {
        bytes[group * 3 + index] = UInt8(truncatingIfNeeded: word >> UInt32(16 - 8 * index))
      }
    }

    guard invalid == 0 else {
      wipe(&bytes)
      return nil
    }
    return bytes
  }

  private static let padding = UInt8(ascii: "=")

  /// All ones when `first` is greater than `second` and zero otherwise, for
  /// values below 2^30.
  private static func greater(_ first: Int32, _ second: Int32) -> Int32 {
    (second &- first) >> 31
  }

  /// All ones when `value` lies in `low` through `high`, zero otherwise.
  private static func isBetween(_ value: Int32, _ low: Int32, _ high: Int32) -> Int32 {
    ~greater(low, value) & ~greater(value, high)
  }

  /// The character for a value of 0 through 63: A to Z, a to z, 0 to 9, `+`, `/`.
  private static func character(for sextet: UInt32) -> UInt8 {
    let value = Int32(sextet)
    var code = value + 65
    code += greater(value, 25) & 6
    code -= greater(value, 51) & 75
    code -= greater(value, 61) & 15
    code += greater(value, 62) & 3
    return UInt8(truncatingIfNeeded: code)
  }

  /// The value of an alphabet character, and an all-ones mask in `valid` when
  /// the byte is one.
  private static func value(of byte: UInt8) -> (value: Int32, valid: Int32) {
    let code = Int32(byte)
    let upper = isBetween(code, 65, 90)
    let lower = isBetween(code, 97, 122)
    let digit = isBetween(code, 48, 57)
    let plus = isBetween(code, 43, 43)
    let slash = isBetween(code, 47, 47)
    let value = (upper & (code - 65)) | (lower & (code - 71)) | (digit & (code + 4))
      | (plus & 62) | (slash & 63)
    return (value, upper | lower | digit | plus | slash)
  }
}
