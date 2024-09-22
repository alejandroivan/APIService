import Foundation

public enum APIError: Error, Sendable {
    case invalidRequest(_ error: APICertificateError)
    case invalidResponse(_ error: APICertificateError)
    case invalidURLResponse(_ urlResponse: URLResponse)
    case invalidStatusCode(_ statusCode: Int, data: Data)
    case undecodableResponseData(_ data: Data)
    case unknown(_ error: Error)
}

// MARK: - Extensions

extension APIError {

    public var data: Data? {
        switch self {
        case .invalidRequest: nil
        case .invalidResponse: nil
        case .invalidURLResponse: nil
        case .invalidStatusCode(_, let data): data
        case .undecodableResponseData(let data): data
        case .unknown: nil
        }
    }

    public var responseBody: String? {
        guard
            let data,
            let body = String(data: data, encoding: .utf8)
        else {
            return nil
        }
        return body
    }

    public var statusCode: Int? {
        switch self {
        case .invalidStatusCode(let statusCode, data: _): statusCode
        default: nil
        }
    }
}
