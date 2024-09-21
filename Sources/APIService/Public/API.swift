import Foundation

public struct API: APIService {

    // MARK: - Constants

    /// Determines the type of SSL pinning to be used for the network request.
    public enum SSLPinning {

        /// Configures SSL pinning using local file URLs for DER certificates.
        case enabledWithCertificateURLs(_ certificateURLs: [URL])

        /// Configures SSL pinning using manually given key hashes (base64 encoded strings).
        case enabledWithKeyHashes(_ keyHashes: [String])

        // Disables SSL pinning.
        case disabled
    }

    // MARK: - Public Properties

    /// Determines the status codes to be considered valid. If any other status code is returned
    /// from the network request, the API call will throw `APIError.invalidStatusCode(_:)`.
    public let validStatusCodes: [Int]

    public var lastError: APIError? {
        sessionDelegate?.lastError
    }

    // MARK: - Private Properties

    private let decoder = JSONDecoder()
    private let session: URLSession
    private let sessionDelegate: SessionDelegate?

    // MARK: - Initialization

    public init(
        sslPinning: SSLPinning = .disabled,
        validStatusCodes: [Int] = Array(200...299)
    ) {
        // Set up the SessionDelegate for SSL pinning (if required)
        switch sslPinning {
        case .enabledWithCertificateURLs(let urls):
            self.sessionDelegate = SessionDelegate(
                keyHandler: DERCertificateKeyHandler(
                    certificateURLs: urls
                )
            )
        case .enabledWithKeyHashes(let hashes):
            self.sessionDelegate = SessionDelegate(
                keyHandler: StringKeyHandler(
                    pinnedSSLHashes: hashes
                )
            )
        case .disabled:
            self.sessionDelegate = nil
        }

        // Set up the valid status codes
        self.validStatusCodes = validStatusCodes

        // Set up the URLSession
        let configuration = URLSessionConfiguration.ephemeral
        configuration.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData

        self.session = URLSession(
            configuration: configuration,
            delegate: self.sessionDelegate,
            delegateQueue: nil
        )
    }

    // MARK: - Public Methods - APIService

    public func perform(
        _ request: Request,
        validatesStatusCode: Bool = false
    ) async throws(APIError) -> (Data, HTTPURLResponse) {
        do {
            let (data, urlResponse) = try await session.data(for: request.urlRequest)

            guard let httpURLResponse = urlResponse as? HTTPURLResponse else {
                throw APIError.invalidURLResponse(urlResponse)
            }

            if validatesStatusCode, !validStatusCodes.contains(httpURLResponse.statusCode) {
                throw APIError.invalidStatusCode(httpURLResponse.statusCode)
            }

            return (data, httpURLResponse)
        } catch let error as APIError {
            throw error
        } catch {
            let error = sessionDelegate?.lastError ?? APIError.unknown(error)
            throw error
        }
    }

    public func delete<Output: Decodable>(
        _ url: URL
    ) async throws(APIError) -> Output {
        let request = Request(baseURL: url, method: .delete)
        let (data, _) = try await perform(request, validatesStatusCode: true)

        do {
            let object = try decoder.decode(Output.self, from: data)
            return object
        } catch {
            throw .undecodableResponseData(data)
        }
    }

    public func get<Output: Decodable>(
        _ url: URL
    ) async throws(APIError) -> Output {
        let request = Request(baseURL: url, method: .get)
        let (data, _) = try await perform(request, validatesStatusCode: true)

        do {
            let object = try decoder.decode(Output.self, from: data)
            return object
        } catch {
            throw .undecodableResponseData(data)
        }
    }

    public func post<Output: Decodable>(
        _ url: URL,
        parameters: [String: any Encodable]
    ) async throws(APIError) -> Output {
        let request = Request(baseURL: url, method: .post, parameters: parameters)
        let (data, _) = try await perform(request, validatesStatusCode: true)

        do {
            let object = try decoder.decode(Output.self, from: data)
            return object
        } catch {
            throw .undecodableResponseData(data)
        }
    }

    public func put<Output: Decodable>(
        _ url: URL,
        parameters: [String: any Encodable]
    ) async throws(APIError) -> Output {
        let request = Request(baseURL: url, method: .put, parameters: parameters)
        let (data, _) = try await perform(request, validatesStatusCode: true)

        do {
            let object = try decoder.decode(Output.self, from: data)
            return object
        } catch {
            throw .undecodableResponseData(data)
        }
    }
}
