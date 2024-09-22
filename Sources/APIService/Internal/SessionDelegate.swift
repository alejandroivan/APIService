import Foundation

final class SessionDelegate: NSObject, URLSessionTaskDelegate, Sendable, DebugLogger {

    // MARK: - Properties

    let sslPinningManager: SSLPinningManager

    var lastError: APIError? {
        sslPinningManager.lastError
    }

    // MARK: - Initialization

    required init(keyHandler: KeyHandler) {
        self.sslPinningManager = SSLPinningManager(
            keyHandler: keyHandler
        )
    }

    // MARK: - URLSessionDelegate

    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge
    ) async -> (URLSession.AuthChallengeDisposition, URLCredential?) {
        let result = sslPinningManager.validate(challenge: challenge)
        self.log("(\(#function) Output: (\(result.disposition), \(result.credential))")
        return (result.disposition, result.credential)
    }

    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didReceive challenge: URLAuthenticationChallenge
    ) async -> (URLSession.AuthChallengeDisposition, URLCredential?) {
        let result = sslPinningManager.validate(challenge: challenge)
        self.log("(\(#function) Output: (\(result.disposition), \(result.credential))")
        return (result.disposition, result.credential)
    }
}
