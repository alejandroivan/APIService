import Foundation

public enum APIError: Error, Sendable {
    case invalidRequest(_ error: APICertificateError)
    case invalidResponse(_ error: APICertificateError)
    case invalidURLResponse(_ urlResponse: URLResponse)
    case invalidStatusCode(_ statusCode: Int)
    case undecodableResponseData(_ data: Data)
    case unknown(_ error: Error)
}
