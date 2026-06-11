import Fluent
import Vapor

/// One-time code bridging the cross-site OAuth callback to a first-party
/// cookie-set navigation. iOS Safari drops cookies set on responses to
/// cross-site POSTs (Google/Apple callbacks), so the callback redirects to
/// GET /auth/complete?c=<code> which sets the session cookies in a clean
/// first-party context. Codes are single-use and expire after 60 seconds. S273.
final class AuthHandoffModel: Model, @unchecked Sendable {
    static let schema = "auth_handoffs"

    @ID(key: .id) var id: UUID?
    @Field(key: "code") var code: String
    @Field(key: "session_token") var sessionToken: String
    @Field(key: "expires_at") var expiresAt: Date

    init() {}

    init(sessionToken: String, expiresIn: TimeInterval = 60) {
        self.id = UUID()
        self.code = [UInt8].random(count: 32).map { String(format: "%02x", $0) }.joined()
        self.sessionToken = sessionToken
        self.expiresAt = Date().addingTimeInterval(expiresIn)
    }

    var isExpired: Bool { Date() > expiresAt }
}
