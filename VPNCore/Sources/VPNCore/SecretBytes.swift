// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import Darwin

/// Overwrites every byte of `bytes` with zero in a way the optimizer keeps.
///
/// The array must be the only reference to its storage, as an array that was
/// made in the same scope and never copied is. A shared array is copied before
/// it is written, and the copy is the one that gets wiped.
func wipe(_ bytes: inout [UInt8]) {
  // Safe because the buffer is used only inside the closure, and `memset_s`
  // writes exactly `buffer.count` bytes starting at `base`, which is the extent
  // of the array's storage. Nothing is read from the buffer, and the pointer is
  // not kept.
  bytes.withUnsafeMutableBytes { buffer in
    // An empty array has no address and nothing to wipe.
    guard let base = buffer.baseAddress else { return }
    _ = memset_s(base, buffer.count, 0, buffer.count)
  }
}

/// Whether two byte strings hold the same bytes. The time taken depends on the
/// lengths, which are not secret, and never on where the contents differ.
func constantTimeEqual(_ first: Span<UInt8>, _ second: Span<UInt8>) -> Bool {
  guard first.count == second.count else { return false }
  var difference: UInt8 = 0
  for index in 0 ..< first.count {
    difference |= first[index] ^ second[index]
  }
  return difference == 0
}
