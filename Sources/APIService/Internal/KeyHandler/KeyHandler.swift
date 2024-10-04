import Foundation

protocol KeyHandler: AnyObject, Sendable, CustomStringConvertible {
    var pinnedSSLHashes: [String] { get }
}

extension KeyHandler {

    var description: String {
        "\(Self.self)(pinnedSSLHashes: \(pinnedSSLHashes))"
    }
}
