import Vapor
import Fluent

extension Request {
    /// Session token from `Authorization: Bearer` (iOS app) or `lo_session`
    /// cookie (web). The native app stores the token from /auth/apple/mobile
    /// and sends it as a Bearer header — it never has the cookie. S273.
    var sessionToken: String? {
        if let bearer = headers.bearerAuthorization?.token, !bearer.isEmpty {
            return bearer
        }
        return cookies["lo_session"]?.string
    }

    /// Create a session for the user. Opportunistically prunes expired
    /// sessions so the table doesn't grow unbounded (sign-in is a cheap,
    /// low-frequency place to do this).
    func createSession(for user: UserModel) async throws -> SessionModel {
        try await SessionModel.query(on: db)
            .filter(\.$expiresAt < Date())
            .delete()
        let token = [UInt8].random(count: 32).map { String(format: "%02x", $0) }.joined()
        let session = SessionModel(userID: user.id!, token: token)
        try await session.save(on: db)
        return session
    }

    func requireUser() async throws -> UserModel {
        guard let token = sessionToken,
              let session = try await SessionModel.query(on: db).filter(\.$token == token).first(),
              !session.isExpired,
              let user = try await UserModel.find(session.userID, on: db) else {
            // Diagnostic: distinguish missing token vs unknown/expired session (S273)
            logger.info("auth 401: path=\(url.path) hasToken=\(sessionToken != nil) ua=\(headers.first(name: .userAgent) ?? "-")")
            throw Abort(.unauthorized, reason: "Sign in required")
        }
        return user
    }
}

extension Response {
    /// 200 HTML interstitial that JS-navigates to /auth/complete/?c=<code>.
    /// An HTTP redirect does NOT work here: Safari attributes the whole
    /// redirect chain to the cross-site OAuth POST and drops cookies on every
    /// response in it. A client-side navigation starts a fresh first-party
    /// navigation, so cookies set on /auth/complete stick. S273.
    static func authHandoffInterstitial(code: String) -> Response {
        let url = "/auth/complete/?c=\(code)"
        let html = """
        <!doctype html><html><head><meta charset="utf-8"><title>Signing in…</title>
        <meta http-equiv="refresh" content="1;url=\(url)">
        </head><body style="font-family:-apple-system,sans-serif;display:flex;align-items:center;justify-content:center;min-height:100vh;margin:0;background:#0a0a0f;color:#e8e8f0">
        <p>Signing you in…</p>
        <script>location.replace('\(url)')</script>
        </body></html>
        """
        let response = Response(status: .ok, body: .init(string: html))
        response.headers.replaceOrAdd(name: .contentType, value: "text/html; charset=utf-8")
        response.headers.replaceOrAdd(name: .cacheControl, value: "no-store")
        return response
    }

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
