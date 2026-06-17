import Vapor
import Fluent
import JWT
import LOCore
import LOAuth

struct AuthController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        routes.get("signin", use: signinPage)
        // Common alias users type directly; avoid 404 (no canonical conflict — 303)
        routes.get("login") { $0.redirect(to: "/signin/", redirectType: .normal) }
        // Minimal Google sign-in page for the native app's ASWebAuthenticationSession
        routes.get("signin", "mobile", use: mobileSigninPage)
        let auth = routes.grouped("auth")
            .grouped(RateLimitMiddleware(maxRequests: 20, perSeconds: 60))
        auth.get("apple", use: appleSignIn)
        auth.post("apple", "callback", use: appleCallback)
        auth.post("apple", "mobile", use: appleMobile)
        auth.post("mobile", "exchange", use: mobileExchange)
        auth.get("complete", use: authComplete)
        auth.post("set-session", use: setSession)
        auth.get("logout", use: logout)
        auth.get("me", use: me)
    }

    @Sendable
    func signinPage(req: Request) async throws -> View {
        try await req.view.render("signin", ["title": "Sign In | Like One"])
    }

    /// Google sign-in page for the native app, opened inside
    /// ASWebAuthenticationSession. Reuses the registered GIS redirect flow;
    /// the `lo_auth_mobile` cookie tells /auth/complete to hand the session
    /// back to the app via the likeoneacademy:// callback scheme instead of
    /// setting web cookies and going to /account/. S280.
    @Sendable
    func mobileSigninPage(req: Request) async throws -> Response {
        let html = """
        <!doctype html><html lang="en"><head><meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <meta name="robots" content="noindex">
        <title>Sign In | Like One Academy</title>
        <style>
        body { font-family: -apple-system, system-ui, sans-serif; background: #0a0a0f; color: #e8e8f0;
               display: flex; flex-direction: column; align-items: center; justify-content: center;
               min-height: 100vh; margin: 0; gap: 20px; padding: 24px; text-align: center; }
        h1 { font-size: 1.3rem; font-weight: 600; margin: 0; }
        p { color: #a1a1aa; font-size: 0.95rem; margin: 0; max-width: 320px; }
        </style></head><body>
        <h1>Sign in to Like One Academy</h1>
        <p>Use your Google account to sync progress and unlock your subscription.</p>
        <div id="g_id_onload"
             data-client_id="\(GoogleAuthController.clientID)"
             data-ux_mode="redirect"
             data-login_uri="https://likeone.ai/auth/google/callback?lo_app=1"
             data-auto_prompt="false"></div>
        <div class="g_id_signin" data-type="standard" data-size="large"
             data-theme="filled_black" data-text="signin_with" data-width="280"></div>
        <script src="https://accounts.google.com/gsi/client" async defer></script>
        </body></html>
        """
        let response = Response(status: .ok, body: .init(string: html))
        response.headers.replaceOrAdd(name: .contentType, value: "text/html; charset=utf-8")
        response.headers.replaceOrAdd(name: .cacheControl, value: "no-store")
        // First-party Lax cookie — sent on the same-site JS navigation to
        // /auth/complete, where it flips the flow to the app handoff.
        response.cookies["lo_auth_mobile"] = HTTPCookies.Value(
            string: "1",
            maxAge: 600,
            domain: ".likeone.ai",
            isSecure: true,
            isHTTPOnly: true,
            sameSite: .lax
        )
        return response
    }

    /// Exchange a one-time handoff code for a bearer token — the native app
    /// calls this after ASWebAuthenticationSession returns
    /// likeoneacademy://auth?c=<code>. Mirrors /auth/apple/mobile's response. S280.
    @Sendable
    func mobileExchange(req: Request) async throws -> Response {
        struct ExchangeInput: Content {
            let code: String
        }
        struct MobileAuthResponse: Content {
            let token: String
            let email: String
            let subscription: String
        }

        let input = try req.content.decode(ExchangeInput.self)

        guard let handoff = try await AuthHandoffModel.query(on: req.db)
                  .filter(\.$code == input.code).first(),
              !handoff.isExpired,
              let session = try await SessionModel.query(on: req.db)
                  .filter(\.$token == handoff.sessionToken).first(),
              !session.isExpired,
              let user = try await UserModel.find(session.userID, on: req.db) else {
            throw Abort(.unauthorized, reason: "Invalid or expired code")
        }

        // Single-use: burn the code
        try await handoff.delete(on: req.db)

        let response = Response(status: .ok)
        try response.content.encode(
            MobileAuthResponse(token: session.token, email: user.email, subscription: user.subscription),
            as: .json
        )
        return response
    }

    @Sendable
    func appleSignIn(req: Request) async throws -> Response {
        let state = [UInt8].random(count: 16).map { String(format: "%02x", $0) }.joined()
        let clientID = AppleAuthConfig.clientID
        let redirectURI = "\(req.application.baseURL)/auth/apple/callback"
        let url = "https://appleid.apple.com/auth/authorize?client_id=\(clientID)&redirect_uri=\(redirectURI)&response_type=code&scope=name%20email&response_mode=form_post&state=\(state)"
        let response = req.redirect(to: url)
        // SameSite=None: Apple posts the callback cross-site — Lax cookies
        // are not sent with cross-site POSTs, so the state check would always fail.
        response.cookies["apple_oauth_state"] = HTTPCookies.Value(
            string: state,
            maxAge: 600,
            domain: ".likeone.ai",
            isSecure: true,
            isHTTPOnly: true,
            sameSite: HTTPCookies.SameSitePolicy.none
        )
        return response
    }

    @Sendable
    func appleCallback(req: Request) async throws -> Response {
        struct AppleCallbackData: Content {
            let code: String
            let state: String?
            let id_token: String?
        }

        let callback = try req.content.decode(AppleCallbackData.self)

        // Verify CSRF state — enforce when the cookie arrives; Safari ITP can
        // strip even SameSite=None cookies on cross-site POSTs, so degrade to a
        // warning rather than breaking sign-in (code exchange is the real auth).
        if let expectedState = req.cookies["apple_oauth_state"]?.string {
            guard let returnedState = callback.state, expectedState == returnedState else {
                throw Abort(.forbidden, reason: "Invalid OAuth state")
            }
        } else {
            req.logger.warning("Apple OAuth state cookie missing (ITP?) — proceeding with code exchange")
        }

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

        // Verify the ID token (signature via Apple JWKS + iss/exp/aud). S273.
        let claims: AppleIdentityToken
        do {
            claims = try await req.jwt.apple.verify(idToken, applicationIdentifier: AppleAuthConfig.clientID)
        } catch {
            req.logger.warning("Apple ID token verification failed: \(error)")
            throw Abort(.unauthorized, reason: "Invalid ID token")
        }

        guard let email = claims.email else {
            throw Abort(.unauthorized, reason: "No email in Apple ID token")
        }

        // Find or create user — stable `sub` first, then email (backfill sub).
        // An email change (or Hide My Email toggle) must not fork the account. S273.
        let sub = claims.subject.value
        let user: UserModel
        if let bySub = try await UserModel.query(on: req.db).filter(\.$appleSub == sub).first() {
            user = bySub
        } else if let byEmail = try await UserModel.query(on: req.db).filter(\.$email == email).first() {
            user = byEmail
            user.appleSub = sub
            try await user.update(on: req.db)
        } else {
            user = UserModel(from: User(email: email, provider: .apple))
            user.appleSub = sub
            try await user.save(on: req.db)
        }

        let session = try await req.createSession(for: user)

        // iOS Safari drops cookies on the entire redirect chain of a cross-site
        // POST, so return a 200 interstitial whose JS starts a fresh first-party
        // navigation to /auth/complete, which sets the cookies. S273.
        let handoff = AuthHandoffModel(sessionToken: session.token)
        try await handoff.save(on: req.db)

        let response = Response.authHandoffInterstitial(code: handoff.code)
        // Belt-and-suspenders: also set cookies here for browsers that accept them.
        response.setSessionCookies(token: session.token, expires: session.expiresAt)
        // Clear used OAuth state cookie
        response.cookies["apple_oauth_state"] = HTTPCookies.Value(
            string: "",
            expires: Date(timeIntervalSince1970: 0),
            domain: ".likeone.ai",
            isHTTPOnly: true
        )
        return response
    }

    @Sendable
    func appleMobile(req: Request) async throws -> Response {
        struct MobileAuthInput: Content {
            let identityToken: String
            let name: String?
        }

        struct MobileAuthResponse: Content {
            let token: String
            let email: String
            let subscription: String
        }

        let input = try req.content.decode(MobileAuthInput.self)

        // Verify identity token (signature via Apple JWKS + iss/exp). S273.
        // Native app tokens carry aud = bundle ID; web tokens carry the Services ID.
        let claims: AppleIdentityToken
        do {
            claims = try await req.jwt.apple.verify(input.identityToken)
        } catch {
            req.logger.warning("Apple identity token verification failed: \(error)")
            throw Abort(.unauthorized, reason: "Invalid identity token")
        }

        let allowedAudiences: Set<String> = [AppleAuthConfig.bundleID, AppleAuthConfig.clientID]
        guard claims.audience.value.contains(where: allowedAudiences.contains) else {
            throw Abort(.unauthorized, reason: "Invalid token audience")
        }

        guard let email = claims.email else {
            throw Abort(.unauthorized, reason: "No email in identity token")
        }

        // Find or create user — stable `sub` first, then email (backfill sub). S273.
        let sub = claims.subject.value
        let user: UserModel
        if let bySub = try await UserModel.query(on: req.db).filter(\.$appleSub == sub).first() {
            user = bySub
            if let name = input.name, user.name == nil {
                user.name = name
                try await user.save(on: req.db)
            }
        } else if let byEmail = try await UserModel.query(on: req.db).filter(\.$email == email).first() {
            user = byEmail
            user.appleSub = sub
            if let name = input.name, user.name == nil { user.name = name }
            try await user.save(on: req.db)
        } else {
            user = UserModel(from: User(email: email, name: input.name, provider: .apple))
            user.appleSub = sub
            try await user.save(on: req.db)
        }

        let session = try await req.createSession(for: user)

        let responseBody = MobileAuthResponse(
            token: session.token,
            email: user.email,
            subscription: user.subscription
        )

        let response = Response(status: .ok)
        try response.content.encode(responseBody, as: .json)
        return response
    }

    /// First-party cookie handoff: the OAuth callback redirects here with a
    /// one-time code so session cookies are set on a same-site GET — iOS Safari
    /// drops cookies set on cross-site POST responses. S273.
    @Sendable
    func authComplete(req: Request) async throws -> Response {
        // Opportunistic cleanup of expired codes
        try await AuthHandoffModel.query(on: req.db)
            .filter(\.$expiresAt < Date())
            .delete()

        guard let code = req.query[String.self, at: "c"],
              let handoff = try await AuthHandoffModel.query(on: req.db)
                  .filter(\.$code == code).first(),
              !handoff.isExpired,
              let session = try await SessionModel.query(on: req.db)
                  .filter(\.$token == handoff.sessionToken).first(),
              !session.isExpired else {
            // Code missing/expired/used. If the redirect's cookies stuck, the
            // account page will load; otherwise it bounces to sign-in.
            return req.redirect(to: "/account/")
        }

        // Single-use: burn the code
        try await handoff.delete(on: req.db)

        // Native app flow (ASWebAuthenticationSession): hand the session back
        // to the app via the callback scheme with a fresh one-time code, which
        // the app exchanges at /auth/mobile/exchange. S280.
        if handoff.mobile {
            let appHandoff = AuthHandoffModel(sessionToken: session.token)
            try await appHandoff.save(on: req.db)
            let appURL = "likeoneacademy://auth?c=\(appHandoff.code)"
            let mobileHTML = """
            <!doctype html><html><head><meta charset="utf-8"><title>Signing in…</title>
            </head><body style="font-family:-apple-system,sans-serif;display:flex;align-items:center;justify-content:center;min-height:100vh;margin:0;background:#0a0a0f;color:#e8e8f0">
            <p>Returning to the app…</p>
            <script>location.replace('\(appURL)')</script>
            </body></html>
            """
            let response = Response(status: .ok, body: .init(string: mobileHTML))
            response.headers.replaceOrAdd(name: .contentType, value: "text/html; charset=utf-8")
            response.headers.replaceOrAdd(name: .cacheControl, value: "no-store")
            // Burn the mobile flag so a later web sign-in isn't misrouted
            response.cookies["lo_auth_mobile"] = HTTPCookies.Value(
                string: "",
                expires: Date(timeIntervalSince1970: 0),
                domain: ".likeone.ai",
                isHTTPOnly: true
            )
            return response
        }

        // ITP (iOS 18.7+) blocks both HTTP Set-Cookie on redirect chains AND
        // document.cookie from JS in that context. Same-origin fetch() responses
        // are pure first-party and never restricted by ITP. We POST the token to
        // /auth/set-session which sets the HttpOnly cookie cleanly. S273++.
        let token = session.token  // 64-char hex — XSS-safe, safe to inline
        let html = """
        <!doctype html><html><head><meta charset="utf-8"><title>Signing in\u{2026}</title>
        </head><body style="font-family:-apple-system,sans-serif;display:flex;align-items:center;justify-content:center;min-height:100vh;margin:0;background:#0a0a0f;color:#e8e8f0">
        <p>Signing you in\u{2026}</p>
        <script>
        fetch('/auth/set-session',{method:'POST',headers:{'Content-Type':'application/json'},body:'{"token":"\(token)"}'})
        .then(function(r){r.ok?location.replace('/account/'):location.replace('/signin/?error=auth');})
        .catch(function(){location.replace('/signin/?error=auth');});
        </script>
        </body></html>
        """
        let response = Response(status: .ok, body: .init(string: html))
        response.headers.replaceOrAdd(name: .contentType, value: "text/html; charset=utf-8")
        response.headers.replaceOrAdd(name: .cacheControl, value: "no-store")
        return response
    }

    /// Promote a valid session token to a first-party HttpOnly cookie.
    /// Called via same-origin fetch() from /auth/complete — same-origin
    /// fetch responses are never subject to ITP cookie restrictions. S273++.
    @Sendable
    func setSession(req: Request) async throws -> Response {
        struct SetSessionInput: Content {
            let token: String
        }
        let input = try req.content.decode(SetSessionInput.self)
        guard let session = try await SessionModel.query(on: req.db)
                  .filter(\.$token == input.token).first(),
              !session.isExpired else {
            throw Abort(.unauthorized, reason: "Invalid or expired session")
        }
        let response = Response(status: .ok)
        response.setSessionCookies(token: input.token, expires: session.expiresAt)
        return response
    }

    @Sendable
    func logout(req: Request) async throws -> Response {
        if let token = req.sessionToken {
            try await SessionModel.query(on: req.db).filter(\.$token == token).delete()
        }
        let response = req.redirect(to: "/")
        response.cookies["lo_session"] = HTTPCookies.Value(
            string: "",
            expires: Date(timeIntervalSince1970: 0),
            domain: ".likeone.ai",
            isHTTPOnly: true
        )
        response.cookies["lo_authed"] = HTTPCookies.Value(
            string: "",
            expires: Date(timeIntervalSince1970: 0),
            domain: ".likeone.ai"
        )
        return response
    }

    @Sendable
    func me(req: Request) async throws -> UserModel {
        try await req.requireUser()
    }
}
