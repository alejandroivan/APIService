import CryptoKit
import Foundation

extension SecCertificate {

    static func from(data: Data?) throws(APICertificateError) -> SecCertificate {
        guard
            let data,
            let certificate = SecCertificateCreateWithData(nil, data as NSData)
        else {
            throw .invalidData
        }
        return certificate
    }

    func getPublicKey() throws(APICertificateError) -> SecKey {
        var trust: SecTrust?
        let policy = SecPolicyCreateBasicX509()
        let trustCreationStatus = SecTrustCreateWithCertificates(self, policy, &trust)

        guard
            let trust,
            trustCreationStatus == errSecSuccess,
            let publicKey = SecTrustCopyKey(trust)
        else {
            throw .failedToGetPublicKey
        }

        return publicKey
    }
}
