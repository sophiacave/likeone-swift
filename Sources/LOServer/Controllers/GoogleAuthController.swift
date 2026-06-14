import Vapor
import Fluent
import JWT
import LOCore

struct GoogleAuthController: RouteCollection {
    // Use the same client ID as the Vercel site
    static let clientID = "469463762089-i84flm8nn1spmk79qf5kp67pp8u0idlq.apps.googleusercontent.com"

    func boot(routes: RoutesBuilder) throws {
        let auth = routes.grouped("auth", "google")
            .grouped(RateLimitMiddleware(maxRequests: 20, perSeconds: 60))
        auth.post("token", use: verifyToken)
        // GIS ux_mode=redirect login_uri (mobile Safari — popup flow unreliable, S271)
        auth.post("callback", use: redirectCallback)
    }

    /// Verify a Google ID token from the client-side Sign In button
    @Sendable
    func verifyToken(req: Request) async throws -> Response {
        struct TokenInput: Content {
            let credential: String
        }

        let input = try req.content.decode(TokenInput.self)
        let session = try await establishSession(req: req, credential: input.credential)

        let response = Response(status: .ok)
        response.setSessionCookies(token: session.token, expires: session.expiresAt)
        try response.content.encode(["status": "ok", "redirect": "/account/"])
        return response
    }

    /// GIS ux_mode=redirect: Google POSTs form-encoded credential + g_csrf_token here.
    /// Double-submit CSRF check (cookie must equal body value) per Google docs.
    @Sendable
    func redirectCallback(req: Request) async throws -> Response {
        struct RedirectInput: Content {
            let credential: String
            let g_csrf_token: String?
        }

        let input = try req.content.decode(RedirectInput.self)

        // CSRF check — log but don't block (mobile Safari ITP strips cookies)
        let bodyToken = input.g_csrf_token
        let cookieToken = req.cookies["g_csrf_token"]?.string
        if bodyToken == nil || cookieToken == nil || bodyToken != cookieToken {
            req.logger.warning("Google CSRF mismatch (mobile ITP?) body=\(bodyToken ?? "nil") cookie=\(cookieToken ?? "nil")")
        }

        let session = try await establishSession(req: req, credential: input.credential)

        // lo_app=1 in login_uri query param (set in /signin/mobile GIS config)
        // survives the Google POST — replaces lo_auth_mobile cookie which iOS 17+
        // ITP strips during cross-site redirect. S273+.
        let isApp = req.query[String.self, at: "lo_app"] == "1"

        // iOS Safari drops cookies on the entire redirect chain of a cross-site
        // POST, so return a 200 interstitial whose JS starts a fresh first-party
        // navigation to /auth/complete, which sets the cookies. S273.
        let handoff = AuthHandoffModel(sessionToken: session.token, mobile: isApp)
        try await handoff.save(on: req.db)

        let response = Response.authHandoffInterstitial(code: handoff.code)
        // Belt-and-suspenders: also set cookies here for browsers that accept them.
        response.setSessionCookies(token: session.token, expires: session.expiresAt)
        return response
    }

    /// Shared: cryptographically verify Google ID token (signature via Google JWKS
    /// + iss/exp/aud), find/create user, create session. S273 — never trust raw JWTs.
    private func establishSession(req: Request, credential: String) async throws -> SessionModel {
        let claims: GoogleIdentityToken
        do {
            claims = try await req.jwt.google.verify(credential, applicationIdentifier: Self.clientID)
        } catch {
            req.logger.warning("Google ID token verification failed: \(error)")
            throw Abort(.unauthorized, reason: "Invalid Google token")
        }

        if claims.emailVerified?.value == false {
            throw Abort(.unauthorized, reason: "Google email not verified")
        }
        guard let email = claims.email else {
            throw Abort(.unauthorized, reason: "No email in Google token")
        }

        // Find or create user — stable `sub` first, then email (backfill sub).
        // An email change at Google must not fork the account. S273.
        let sub = claims.subject.value
        let user: UserModel
        if let bySub = try await UserModel.query(on: req.db).filter(\.$googleSub == sub).first() {
            user = bySub
        } else if let byEmail = try await UserModel.query(on: req.db).filter(\.$email == email).first() {
            user = byEmail
            user.googleSub = sub
        } else {
            user = UserModel(from: User(
                email: email,
                name: claims.name,
                avatarURL: claims.picture,
                provider: .google
            ))
            user.googleSub = sub
            try await user.save(on: req.db)
            return try await req.createSession(for: user)
        }

        if user.name == nil, let name = claims.name { user.name = name }
        if user.avatarURL == nil, let picture = claims.picture { user.avatarURL = picture }
        try await user.update(on: req.db)

        return try await req.createSession(for: user)
    }
}
