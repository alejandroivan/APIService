import Foundation

public enum APICertificateError: Error {
    case failedToGetPublicKey
    case failedToGetDataFromPublicKey
    case invalidCertificateFromServer
    case invalidData
    case noCertificatesFromServer
    case noHashesFromKeyHandler
}
