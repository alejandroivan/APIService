import Foundation

public struct API: APIService, DebugLogger {

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
    
    /// Defines the base headers for all HTTP requests made using this particular API instance.
    /// If any method specifies additional headers and there's a conflict, the method's particular
    /// one takes priority.
    public let baseHeaders: [String: String]?

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
        validStatusCodes: [Int] = Array(200...299),
        baseHeaders: [String: String]? = nil
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

        // Set up the base headers for all requests
        self.baseHeaders = baseHeaders

        // Set up the URLSession
        let configuration = URLSessionConfiguration.ephemeral
        configuration.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData

        self.session = URLSession(
            configuration: configuration,
            delegate: self.sessionDelegate,
            delegateQueue: nil
        )

        self.log("""
        Initialized.
        - SSL pinning: \(sslPinning)
        - Valid status codes: \(validStatusCodes.debugDescription)
        - Base headers: \(baseHeaders?.debugDescription ?? "<not set>")
        - Session: \(self.session.debugDescription)
        """)
    }

    // MARK: - Private Methods

    private func getHeaders(adding headers: [String: String]?) -> [String: String]? {
        guard let headers else {
            return self.baseHeaders
        }

        let baseHeaders = self.baseHeaders ?? [:]

        return baseHeaders.merging(headers) { _, newValue in
            newValue // If there's a conflict, we prioritize the custom header.
        }
    }

    // MARK: - Public Methods - APIService

    public func perform(
        _ request: Request,
        validatesStatusCode: Bool = false
    ) async throws(APIError) -> (Data, HTTPURLResponse) {
        self.log("""
        \(#function)
        - request: \(request)
        - validatesStatusCode: \(validatesStatusCode)
        """)
        do {
            let (data, urlResponse) = try await session.data(for: request.urlRequest)

            guard let httpURLResponse = urlResponse as? HTTPURLResponse else {
                throw APIError.invalidURLResponse(urlResponse)
            }

            if validatesStatusCode, !validStatusCodes.contains(httpURLResponse.statusCode) {
                throw APIError.invalidStatusCode(httpURLResponse.statusCode, data: data)
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
        _ url: URL,
        headers: [String: String]? = nil
    ) async throws(APIError) -> Output {
        let request = Request(
            baseURL: url,
            headers: getHeaders(adding: headers),
            method: .delete
        )
        let (data, _) = try await perform(request, validatesStatusCode: true)

        do {
            let object = try decoder.decode(Output.self, from: data)
            return object
        } catch {
            throw .undecodableResponseData(data)
        }
    }

    public func get<Output: Decodable>(
        _ url: URL,
        headers: [String: String]? = nil
    ) async throws(APIError) -> Output {
        let request = Request(
            baseURL: url,
            headers: getHeaders(adding: headers),
            method: .get
        )
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
        headers: [String: String]? = nil,
        parameters: [String: any Encodable]
    ) async throws(APIError) -> Output {
        let request = Request(
            baseURL: url,
            headers: getHeaders(adding: headers),
            method: .post,
            parameters: parameters
        )
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
        headers: [String: String]? = nil,
        parameters: [String: any Encodable]
    ) async throws(APIError) -> Output {
        let request = Request(
            baseURL: url,
            headers: getHeaders(adding: headers),
            method: .put,
            parameters: parameters
        )
        let (data, _) = try await perform(request, validatesStatusCode: true)

        do {
            let object = try decoder.decode(Output.self, from: data)
            return object
        } catch {
            throw .undecodableResponseData(data)
        }
    }
}
