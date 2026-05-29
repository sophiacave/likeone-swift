import Vapor
import Foundation

struct AppleAuthConfig {
    static let teamID = "MW42T97LV9"
    static let keyID = "B9DSKAL85T"
    static let clientID = "ai.likeone.web"  // Services ID
    static let bundleID = "ai.likeone.app"  // App ID

    static func clientSecret(keyPath: String? = nil) throws -> String {
        let path = keyPath ?? Self.defaultKeyPath()
        let keyData = try String(contentsOfFile: path, encoding: .utf8)
            .replacingOccurrences(of: "-----BEGIN PRIVATE KEY-----", with: "")
            .replacingOccurrences(of: "-----END PRIVATE KEY-----", with: "")
            .replacingOccurrences(of: "\n", with: "")

        let now = Date()
        let expiry = now.addingTimeInterval(15_777_000)  // ~6 months

        let header = try base64url(["alg": "ES256", "kid": keyID, "typ": "JWT"])
        let claims = try base64url([
            "iss": teamID,
            "iat": Int(now.timeIntervalSince1970),
            "exp": Int(expiry.timeIntervalSince1970),
            "aud": "https://appleid.apple.com",
            "sub": clientID,
        ] as [String: Any])

        let message = "\(header).\(claims)"

        guard let keyBytes = Data(base64Encoded: keyData) else {
            throw Abort(.internalServerError, reason: "Invalid Apple private key")
        }

        let privateKey = try P256.Signing.PrivateKey(derRepresentation: keyBytes)
        let signature = try privateKey.signature(for: Data(message.utf8))
        let signatureBase64 = signature.rawRepresentation.base64URLEncoded()

        return "\(message).\(signatureBase64)"
    }

    private static func defaultKeyPath() -> String {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        return "\(home)/.appstoreconnect/private_keys/AuthKey_\(keyID).p8"
    }

    private static func base64url(_ dict: [String: Any]) throws -> String {
        let data = try JSONSerialization.data(withJSONObject: dict)
        return data.base64URLEncoded()
    }
}

import Crypto

extension Data {
    func base64URLEncoded() -> String {
        base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}
