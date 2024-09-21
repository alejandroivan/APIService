import Foundation

public protocol APIService: Sendable {

    // MARK: - Errors

    var lastError: APIError? { get }

    // MARK: - Custom Request

    /// Generic network request for getting some `Data` and a `HTTPURLResponse`.
    /// - Parameters:
    ///   - request: A `Request` that determines the type of network request to perform.
    ///   - validatesStatusCode: If `true` and the status code is invalid, this will throw an exception.
    ///                          If `false`, the status code won't be checked and the method will return nomally.
    func perform(
        _ request: Request,
        validatesStatusCode: Bool
    ) async throws(APIError) -> (Data, HTTPURLResponse)

    // MARK: - Delete

    func delete<Output: Decodable>(
        _ url: URL
    ) async throws(APIError) -> Output

    // MARK: - Get

    func get<Output: Decodable>(
        _ url: URL
    ) async throws(APIError) -> Output

    // MARK: - Post

    func post<Output: Decodable>(
        _ url: URL,
        parameters: [String: any Encodable]
    ) async throws(APIError) -> Output

    // MARK: - Put

    func put<Output: Decodable>(
        _ url: URL,
        parameters: [String: any Encodable]
    ) async throws(APIError) -> Output
}
