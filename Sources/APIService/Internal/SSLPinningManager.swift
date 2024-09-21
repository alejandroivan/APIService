import Foundation

final class SSLPinningManager: @unchecked Sendable {

    // MARK: - Constants

    enum PinningError {
        case noCertificatesFromServer

    }

    struct ValidationResult {
        let disposition: URLSession.AuthChallengeDisposition
        let credential: URLCredential?
    }

    // MARK: - Properties

    private let keyHandler: KeyHandler
    private let queue = DispatchQueue(label: "SSLPinningManager.queue")
    private var _lastError: APIError?

    private(set) var lastError: APIError? {
        get {
            queue.sync {
                self._lastError
            }
        }
        set {
            queue.async {
                self._lastError = newValue
            }
        }
    }

    // MARK: - Initialization

    init(keyHandler: KeyHandler) {
        self.keyHandler = keyHandler
    }

    // MARK: - Private Methods

    private func validateAndGetTrust(
        challenge: URLAuthenticationChallenge
    ) throws(APICertificateError) -> SecTrust {
        guard
            let trust = challenge.protectionSpace.serverTrust,
            let certificateChain = SecTrustCopyCertificateChain(trust) as? [SecCertificate],
            !certificateChain.isEmpty
        else {
            self.lastError = apiError(from: .noCertificatesFromServer)
            throw .noCertificatesFromServer
        }

        guard try containsValidHash(certificateChain: certificateChain) else {
            self.lastError = apiError(from: .invalidCertificateFromServer)
            throw .invalidCertificateFromServer
        }

        return trust
    }

    private func containsValidHash(
        certificateChain: [SecCertificate]
    ) throws(APICertificateError) -> Bool {
        guard !keyHandler.pinnedSSLHashes.isEmpty else {
            self.lastError = apiError(from: .noHashesFromKeyHandler)
            throw .noHashesFromKeyHandler
        }

        var validHash: String?

        for certificate in certificateChain {
            let publicKey = try certificate.getPublicKey()
            let hash = try publicKey.hash()

            guard keyHandler.pinnedSSLHashes.contains(hash) else {
                continue
            }

            validHash = hash
            break
        }

        return validHash != nil
    }

    private func apiError(from error: APICertificateError) -> APIError {
        switch error {
        case .failedToGetPublicKey: .invalidResponse(error)
        case .failedToGetDataFromPublicKey: .invalidResponse(error)
        case .invalidCertificateFromServer: .invalidResponse(error)
        case .invalidData: .invalidResponse(error)
        case .noCertificatesFromServer: .invalidResponse(error)
        case .noHashesFromKeyHandler: .invalidRequest(error)
        }
    }

    // MARK: - Internal Methods

    func validate(challenge: URLAuthenticationChallenge) -> ValidationResult {
        do {
            let trust = try validateAndGetTrust(challenge: challenge)
            let credential = URLCredential(trust: trust)
            self.lastError = nil

            return .init(
                disposition: .useCredential,
                credential: credential
            )
        } catch {
            self.lastError = apiError(from: error)

            return .init(
                disposition: .cancelAuthenticationChallenge,
                credential: nil
            )
        }
    }
}
