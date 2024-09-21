import CryptoKit
import Foundation

final class DERCertificateKeyHandler: KeyHandler, @unchecked Sendable {

    // MARK: - Properties

    private let certificateURLs: [URL]
    private let queue = DispatchQueue(label: "DERCertificateKeyHandler.queue")
    private var _pinnedSSLHashes: [String] = []

    var pinnedSSLHashes: [String] {
        get {
            queue.sync {
                self._pinnedSSLHashes
            }
        }
        set {
            queue.async {
                self._pinnedSSLHashes = newValue
            }
        }
    }

    // MARK: - Initialization

    init(certificateURLs: [URL]) {
        self.certificateURLs = certificateURLs
        buildHashes()
    }

    // MARK: - Private Methods

    private func buildHashes() {
        var hashes: [String] = []

        for url in certificateURLs {
            guard
                let data = try? Data(contentsOf: url),
                let certificate = try? SecCertificate.from(data: data),
                let publicKey = try? certificate.getPublicKey(),
                let hash = try? publicKey.hash()
            else {
                continue
            }
            hashes.append(hash)
        }

        self.pinnedSSLHashes = hashes
    }
}
