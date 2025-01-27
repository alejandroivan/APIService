import Foundation

public struct Request {

    // MARK: - Constants
    
    /// The HTTP method to be used for this particular request.
    public enum HTTPMethod: String {
        case delete = "DELETE"
        case get = "GET"
        case post = "POST"
        case put = "PUT"
    }

    private enum Constants {

        static let encodingSet: CharacterSet = {
            var characterSet: CharacterSet = .urlQueryAllowed
            characterSet.remove(charactersIn: "/?&=")
            return characterSet
        }()
    }

    // MARK: - Public Properties

    public let baseURL: URL
    public let headers: [String: String]?
    public let method: HTTPMethod
    public let parameters: [String: any Encodable]

    // MARK: - Initialization

    public init(
        baseURL: URL,
        headers: [String: String]? = nil,
        method: HTTPMethod,
        parameters: [String: any Encodable] = [:]
    ) {
        self.baseURL = baseURL
        self.headers = headers
        self.method = method
        self.parameters = parameters
    }
}

// MARK: - Extensions

extension Request {

    var urlRequest: URLRequest {
        var request = URLRequest(url: finalURL)
        request.allHTTPHeaderFields = headers
        request.httpMethod = method.rawValue

        switch method {
        case .delete, .get:
            break
        case .post, .put:
            request.httpBody = parametersData
        }

        return request
    }

    private var parametersData: Data {
        let data = try? JSONSerialization.data(withJSONObject: parameters, options: .sortedKeys)
        return data ?? Data()
    }

    public var finalURL: URL {
        switch method {
        case .delete, .get:
            var components = URLComponents(string: baseURL.absoluteString)

            if !parameters.isEmpty {
                components?.percentEncodedQueryItems = parameters.map { key, value in
                    let value = value as? String ?? "\(value)"
                    let encodedValue = value.addingPercentEncoding(withAllowedCharacters: Constants.encodingSet)
                    return URLQueryItem(name: key, value: encodedValue)
                }
            }

            return components?.url ?? baseURL
        case .post, .put:
            return baseURL
        }
    }
}

extension Request: CustomStringConvertible {

    public var description: String {
        var output = "("

        output += "baseURL: \(self.baseURL.absoluteString), "
        output += "headers: \(self.headers?.description ?? "<no custom headers>"), "
        output += "method: \(self.method), "
        output += "parameters: \(!self.parameters.isEmpty ? self.parameters.description : "<no parameters>"), "
        output += "finalURL: \(self.finalURL.absoluteString)"

        output += ")"

        return output
    }
}
