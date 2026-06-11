import Vapor
import Fluent

extension Request {
    func requireUser() async throws -> UserModel {
        guard let token = cookies["lo_session"]?.string,
              let session = try await SessionModel.query(on: db).filter(\.$token == token).first(),
              !session.isExpired,
              let user = try await UserModel.find(session.userID, on: db) else {
            // Diagnostic: distinguish missing cookie vs unknown/expired session (S273)
            let hasCookie = cookies["lo_session"]?.string != nil
            logger.info("auth 401: path=\(url.path) hasSessionCookie=\(hasCookie) ua=\(headers.first(name: .userAgent) ?? "-")")
            throw Abort(.unauthorized, reason: "Sign in required")
        }
        return user
    }
}

extension Response {
    /// Set the auth session cookies: lo_session (httpOnly) + lo_authed (JS-readable).
    func setSessionCookies(token: String, expires: Date) {
        cookies["lo_session"] = HTTPCookies.Value(
            string: token,
            expires: expires,
            maxAge: 30 * 24 * 3600,
            domain: ".likeone.ai",
            isSecure: true,
            isHTTPOnly: true,
            sameSite: .lax
        )
        cookies["lo_authed"] = HTTPCookies.Value(
            string: "1",
            maxAge: 30 * 24 * 3600,
            domain: ".likeone.ai",
            isSecure: true,
            isHTTPOnly: false,
            sameSite: .lax
        )
    }
}
