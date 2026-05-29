import Vapor
import Foundation
import LOCore
import Crypto

public struct AppleAuthConfig: Sendable {
    public static let teamID = "MW42T97LV9"
    public static let keyID = "B9DSKAL85T"
    public static let clientID = "ai.likeone.web"
    public static let bundleID = "ai.likeone.app"

    public static func clientSecret(keyPath: String? = nil) throws -> String {
        let path = keyPath ?? defaultKeyPath()
        let pem = try String(contentsOfFile: path, encoding: .utf8)
        let keyData = pem
            .replacingOccurrences(of: "-----BEGIN PRIVATE KEY-----", with: "")
            .replacingOccurrences(of: "-----END PRIVATE KEY-----", with: "")
            .replacingOccurrences(of: "\n", with: "")

        let now = Date()
        let expiry = now.addingTimeInterval(15_777_000)

        let header: [String: String] = ["alg": "ES256", "kid": keyID, "typ": "JWT"]
        let headerB64 = try jsonBase64URL(header)

        let claims: [String: Any] = [
            "iss": teamID,
            "iat": Int(now.timeIntervalSince1970),
            "exp": Int(expiry.timeIntervalSince1970),
            "aud": "https://appleid.apple.com",
            "sub": clientID,
        ]
        let claimsB64 = try dictBase64URL(claims)

        let message = "\(headerB64).\(claimsB64)"

        guard let derBytes = Data(base64Encoded: keyData) else {
            throw Abort(.internalServerError, reason: "Invalid Apple private key encoding")
        }

        let privateKey = try P256.Signing.PrivateKey(derRepresentation: derBytes)
        let signature = try privateKey.signature(for: Data(message.utf8))
        let sigB64 = signature.rawRepresentation.base64URLEncoded()

        return "\(message).\(sigB64)"
    }

    private static func defaultKeyPath() -> String {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        return "\(home)/.appstoreconnect/private_keys/AuthKey_\(keyID).p8"
    }

    private static func jsonBase64URL<T: Encodable>(_ value: T) throws -> String {
        let data = try JSONEncoder().encode(value)
        return data.base64URLEncoded()
    }

    private static func dictBase64URL(_ dict: [String: Any]) throws -> String {
        let data = try JSONSerialization.data(withJSONObject: dict)
        return data.base64URLEncoded()
    }
}
