import Vapor
import Fluent
import LOCore
import LOAuth

struct AuthController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        routes.get("signin", use: signinPage)
        let auth = routes.grouped("auth")
        auth.get("apple", use: appleSignIn)
        auth.post("apple", "callback", use: appleCallback)
        auth.get("logout", use: logout)
        auth.get("me", use: me)
    }

    @Sendable
    func signinPage(req: Request) async throws -> View {
        try await req.view.render("signin", ["title": "Sign In | Like One"])
    }

    @Sendable
    func appleSignIn(req: Request) async throws -> Response {
        let state = [UInt8].random(count: 16).map { String(format: "%02x", $0) }.joined()
        let clientID = AppleAuthConfig.clientID
        let redirectURI = "\(req.application.baseURL)/auth/apple/callback"
        let url = "https://appleid.apple.com/auth/authorize?client_id=\(clientID)&redirect_uri=\(redirectURI)&response_type=code&scope=name%20email&response_mode=form_post&state=\(state)"
        return req.redirect(to: url)
    }

    @Sendable
    func appleCallback(req: Request) async throws -> Response {
        struct AppleCallbackData: Content {
            let code: String
            let state: String?
            let id_token: String?
        }

        let callback = try req.content.decode(AppleCallbackData.self)

        // Exchange authorization code for tokens
        let clientSecret = try AppleAuthConfig.clientSecret()
        let redirectURI = "\(req.application.baseURL)/auth/apple/callback"

        struct TokenRequest: Content {
            let client_id: String
            let client_secret: String
            let code: String
            let grant_type: String
            let redirect_uri: String
        }

        let tokenReq = TokenRequest(
            client_id: AppleAuthConfig.clientID,
            client_secret: clientSecret,
            code: callback.code,
            grant_type: "authorization_code",
            redirect_uri: redirectURI
        )

        let tokenResponse = try await req.client.post("https://appleid.apple.com/auth/token") { tokenReq2 in
            try tokenReq2.content.encode(tokenReq, as: .urlEncodedForm)
        }

        struct AppleTokenResponse: Content {
            let access_token: String?
            let id_token: String?
            let refresh_token: String?
            let error: String?
        }

        let tokens = try tokenResponse.content.decode(AppleTokenResponse.self)

        guard let idToken = tokens.id_token else {
            throw Abort(.unauthorized, reason: tokens.error ?? "No ID token received")
        }

        // Decode the ID token (JWT) to get user info
        let parts = idToken.split(separator: ".")
        guard parts.count >= 2,
              let payloadData = Data(base64URLDecoded: String(parts[1])) else {
            throw Abort(.unauthorized, reason: "Invalid ID token")
        }

        struct AppleClaims: Codable {
            let sub: String
            let email: String?
        }

        let claims = try JSONDecoder().decode(AppleClaims.self, from: payloadData)

        guard let email = claims.email else {
            throw Abort(.unauthorized, reason: "No email in Apple ID token")
        }

        // Find or create user
        let user: UserModel
        if let existing = try await UserModel.query(on: req.db).filter(\.$email == email).first() {
            user = existing
        } else {
            user = UserModel(from: User(email: email, provider: .apple))
            try await user.save(on: req.db)
        }

        // Create session
        let token = [UInt8].random(count: 32).map { String(format: "%02x", $0) }.joined()
        let session = SessionModel(userID: user.id!, token: token)
        try await session.save(on: req.db)

        // Set session cookie
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

    @Sendable
    func logout(req: Request) async throws -> Response {
        if let token = req.cookies["lo_session"]?.string {
            try await SessionModel.query(on: req.db).filter(\.$token == token).delete()
        }
        let response = req.redirect(to: "/")
        response.cookies["lo_session"] = HTTPCookies.Value(
            string: "",
            expires: Date(timeIntervalSince1970: 0),
            isHTTPOnly: true
        )
        response.cookies["lo_authed"] = HTTPCookies.Value(
            string: "",
            expires: Date(timeIntervalSince1970: 0)
        )
        return response
    }

    @Sendable
    func me(req: Request) async throws -> UserModel {
        guard let token = req.cookies["lo_session"]?.string,
              let session = try await SessionModel.query(on: req.db).filter(\.$token == token).first(),
              !session.isExpired,
              let user = try await UserModel.find(session.userID, on: req.db) else {
            throw Abort(.unauthorized)
        }
        return user
    }
}

// Base64URL decoding for JWT
extension Data {
    init?(base64URLDecoded string: String) {
        var base64 = string
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        while base64.count % 4 != 0 { base64.append("=") }
        self.init(base64Encoded: base64)
    }
}
