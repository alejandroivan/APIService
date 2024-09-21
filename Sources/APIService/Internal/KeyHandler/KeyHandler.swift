import Foundation

protocol KeyHandler: AnyObject, Sendable {
    var pinnedSSLHashes: [String] { get }
}
