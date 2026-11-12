// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import Foundation
import NetworkExtension

final class PacketTunnelProvider: NEPacketTunnelProvider {
  override func startTunnel(
    options _: [String: NSObject]?,
    completionHandler: @escaping @Sendable (Error?) -> Void,
  ) {
    completionHandler(PacketTunnelError.tunnelUnavailable)
  }
}

enum PacketTunnelError: LocalizedError {
  case tunnelUnavailable

  var errorDescription: String? {
    switch self {
    case .tunnelUnavailable:
      "The tunnel is unavailable in this version of VPN."
    }
  }
}
