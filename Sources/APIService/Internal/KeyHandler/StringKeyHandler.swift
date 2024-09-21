import Foundation

final class StringKeyHandler: KeyHandler {

    let pinnedSSLHashes: [String]

    init(pinnedSSLHashes: [String]) {
        self.pinnedSSLHashes = pinnedSSLHashes
    }
}
