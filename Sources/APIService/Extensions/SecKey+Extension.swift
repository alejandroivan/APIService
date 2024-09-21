import CryptoKit
import Foundation

extension SecKey {

    /// RSA-2048 ASN.1 metadata, required for being fully compliant with the standard.
    /// This data should be prepended to the raw data that the server provides.
    enum ASN1Header {

        static let rsa2048: [UInt8] = [
            0x30, 0x82, 0x01, 0x22, 0x30, 0x0d, 0x06, 0x09, 0x2a, 0x86, 0x48, 0x86,
            0xf7, 0x0d, 0x01, 0x01, 0x01, 0x05, 0x00, 0x03, 0x82, 0x01, 0x0f, 0x00
        ]
    }

    func hash() throws(APICertificateError) -> String {
        guard let publicKeyData = SecKeyCopyExternalRepresentation(self, nil) else {
            throw .failedToGetDataFromPublicKey
        }

        let secKeyData = publicKeyData as NSData as Data

        var data = Data(ASN1Header.rsa2048)
        data.append(secKeyData)

        let sha256Digest = SHA256.hash(data: data)
        let sha256Data = Data(sha256Digest)

        return sha256Data.base64EncodedString()
    }
}
