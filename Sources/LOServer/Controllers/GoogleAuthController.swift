import Vapor
import Fluent
import LOCore

struct GoogleAuthController: RouteCollection {
    // Use the same client ID as the Vercel site
    static let clientID = "469463762089-i84flm8nn1spmk79qf5kp67pp8u0idlq.apps.googleusercontent.com"

    func boot(routes: RoutesBuilder) throws {
        let auth = routes.grouped("auth", "google")
        auth.post("token", use: verifyToken)
    }

    /// Verify a Google ID token from the client-side Sign In button
    @Sendable
    func verifyToken(req: Request) async throws -> Response {
        struct TokenInput: Content {
            let credential: String
        }

        let input = try req.content.decode(TokenInput.self)

        // Decode JWT payload (Google ID token)
        let parts = input.credential.split(separator: ".")
        guard parts.count >= 2,
              let payloadData = Data(base64URLDecoded: String(parts[1])) else {
            throw Abort(.unauthorized, reason: "Invalid token format")
        }

        struct GoogleClaims: Codable {
            let iss: String?
            let aud: String?
            let sub: String
            let email: String?
            let email_verified: Bool?
            let name: String?
            let picture: String?
            let exp: Int?
        }

        let claims = try JSONDecoder().decode(GoogleClaims.self, from: payloadData)

        // Verify issuer and audience
        guard claims.iss == "https://accounts.google.com" || claims.iss == "accounts.google.com" else {
            throw Abort(.unauthorized, reason: "Invalid token issuer")
        }
        guard claims.aud == Self.clientID else {
            throw Abort(.unauthorized, reason: "Invalid token audience")
        }
        // Check expiry
        if let exp = claims.exp, Date(timeIntervalSince1970: TimeInterval(exp)) < Date() {
            throw Abort(.unauthorized, reason: "Token expired")
        }

        guard let email = claims.email else {
            throw Abort(.unauthorized, reason: "No email in Google token")
        }

        // Find or create user
        let user: UserModel
        if let existing = try await UserModel.query(on: req.db).filter(\.$email == email).first() {
            user = existing
            if user.name == nil, let name = claims.name { user.name = name }
            if user.avatarURL == nil, let picture = claims.picture { user.avatarURL = picture }
            try await user.update(on: req.db)
        } else {
            user = UserModel(from: User(
                email: email,
                name: claims.name,
                avatarURL: claims.picture,
                provider: .google
            ))
            try await user.save(on: req.db)
        }

        // Create session
        let token = [UInt8].random(count: 32).map { String(format: "%02x", $0) }.joined()
        let session = SessionModel(userID: user.id!, token: token)
        try await session.save(on: req.db)

        let response = Response(status: .ok)
        response.cookies["lo_session"] = HTTPCookies.Value(
            string: token,
            expires: session.expiresAt,
            maxAge: 30 * 24 * 3600,
            domain: ".likeone.ai",
            isSecure: true,
            isHTTPOnly: true,
            sameSite: .lax
        )
        response.cookies["lo_authed"] = HTTPCookies.Value(
            string: "1",
            maxAge: 30 * 24 * 3600,
            domain: ".likeone.ai",
            isSecure: true,
            isHTTPOnly: false,
            sameSite: .lax
        )
        try response.content.encode(["status": "ok", "redirect": "/account/"])
        return response
    }
}
