import Vapor
import Fluent
import LOCore

struct GoogleAuthController: RouteCollection {
    static let clientID = "469463762089-vhoi6gice7kj64tnru7v9q466suea49o.apps.googleusercontent.com"

    func boot(routes: RoutesBuilder) throws {
        let auth = routes.grouped("auth", "google")
        auth.get(use: googleSignIn)
        auth.get("callback", use: googleCallback)
    }

    @Sendable
    func googleSignIn(req: Request) async throws -> Response {
        let state = [UInt8].random(count: 16).map { String(format: "%02x", $0) }.joined()
        let redirectURI = "\(req.application.baseURL)/auth/google/callback"
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let url = "https://accounts.google.com/o/oauth2/v2/auth"
            + "?client_id=\(Self.clientID)"
            + "&redirect_uri=\(redirectURI)"
            + "&response_type=code"
            + "&scope=openid%20email%20profile"
            + "&state=\(state)"
            + "&access_type=offline"
        return req.redirect(to: url)
    }

    @Sendable
    func googleCallback(req: Request) async throws -> Response {
        struct CallbackQuery: Content {
            let code: String
            let state: String?
        }

        let callback = try req.query.decode(CallbackQuery.self)

        guard let clientSecret = Environment.get("GOOGLE_CLIENT_SECRET") else {
            throw Abort(.internalServerError, reason: "Google client secret not configured")
        }

        let redirectURI = "\(req.application.baseURL)/auth/google/callback"

        // Exchange code for tokens
        struct TokenRequest: Content {
            let client_id: String
            let client_secret: String
            let code: String
            let grant_type: String
            let redirect_uri: String
        }

        let tokenResponse = try await req.client.post("https://oauth2.googleapis.com/token") { tokenReq in
            try tokenReq.content.encode(TokenRequest(
                client_id: Self.clientID,
                client_secret: clientSecret,
                code: callback.code,
                grant_type: "authorization_code",
                redirect_uri: redirectURI
            ), as: .urlEncodedForm)
        }

        struct GoogleTokenResponse: Content {
            let access_token: String?
            let id_token: String?
            let error: String?
        }

        let tokens = try tokenResponse.content.decode(GoogleTokenResponse.self)

        guard let idToken = tokens.id_token else {
            throw Abort(.unauthorized, reason: tokens.error ?? "No ID token from Google")
        }

        // Decode JWT payload for user info
        let parts = idToken.split(separator: ".")
        guard parts.count >= 2,
              let payloadData = Data(base64URLDecoded: String(parts[1])) else {
            throw Abort(.unauthorized, reason: "Invalid Google ID token")
        }

        struct GoogleClaims: Codable {
            let sub: String
            let email: String?
            let name: String?
            let picture: String?
        }

        let claims = try JSONDecoder().decode(GoogleClaims.self, from: payloadData)

        guard let email = claims.email else {
            throw Abort(.unauthorized, reason: "No email in Google token")
        }

        // Find or create user
        let user: UserModel
        if let existing = try await UserModel.query(on: req.db).filter(\.$email == email).first() {
            user = existing
            // Update name/avatar if provided and not yet set
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

        let response = req.redirect(to: "/account")
        response.cookies["lo_session"] = HTTPCookies.Value(
            string: token,
            expires: session.expiresAt,
            maxAge: 30 * 24 * 3600,
            isSecure: true,
            isHTTPOnly: true,
            sameSite: .lax
        )
        return response
    }
}
