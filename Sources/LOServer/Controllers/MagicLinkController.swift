import Vapor
import Fluent
import LOCore
import Foundation
import Crypto

struct MagicLinkController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let auth = routes.grouped("auth")
        auth.post("magic-link", use: sendMagicLink)
        auth.get("verify", use: verifyMagicLink)
    }

    @Sendable
    func sendMagicLink(req: Request) async throws -> Response {
        struct EmailInput: Content {
            let email: String
        }

        let input = try req.content.decode(EmailInput.self)
        let email = input.email.lowercased().trimmingCharacters(in: .whitespaces)

        guard email.contains("@"), email.contains(".") else {
            throw Abort(.badRequest, reason: "Invalid email")
        }

        // Generate HMAC token: email + timestamp + secret
        let timestamp = String(Int(Date().timeIntervalSince1970))
        let secret = Environment.get("MAGIC_LINK_SECRET") ?? "lo-magic-link-default-secret-change-me"
        let payload = "\(email):\(timestamp)"
        let key = SymmetricKey(data: Data(secret.utf8))
        let signature = HMAC<SHA256>.authenticationCode(for: Data(payload.utf8), using: key)
        let token = Data(signature).map { String(format: "%02x", $0) }.joined()

        let verifyURL = "\(req.application.baseURL)/auth/verify?email=\(email.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? email)&t=\(timestamp)&sig=\(token)"

        // Send the email via lo-mail or send-email
        let emailBody = """
        Hi there!

        Click the link below to sign in to Like One Academy:

        \(verifyURL)

        This link expires in 15 minutes. If you didn't request this, you can safely ignore this email.

        — Like One
        """

        // Use send-email CLI
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/Users/sophiacave/bin/send-email")
        process.arguments = ["--to", email, "--subject", "Sign in to Like One", "--body", emailBody]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            req.logger.error("Failed to send magic link email: \(error)")
        }

        let response = Response(status: .ok)
        try response.content.encode(["status": "sent", "email": email])
        return response
    }

    @Sendable
    func verifyMagicLink(req: Request) async throws -> Response {
        guard let email = req.query[String.self, at: "email"],
              let timestamp = req.query[String.self, at: "t"],
              let signature = req.query[String.self, at: "sig"] else {
            throw Abort(.badRequest, reason: "Missing verification parameters")
        }

        // Check expiry (15 minutes)
        guard let ts = Int(timestamp) else {
            throw Abort(.badRequest, reason: "Invalid timestamp")
        }
        let linkAge = Date().timeIntervalSince1970 - Double(ts)
        guard linkAge < 900 else {
            throw Abort(.gone, reason: "This link has expired. Please request a new one.")
        }

        // Verify HMAC
        let secret = Environment.get("MAGIC_LINK_SECRET") ?? "lo-magic-link-default-secret-change-me"
        let payload = "\(email):\(timestamp)"
        let key = SymmetricKey(data: Data(secret.utf8))
        let expectedSig = HMAC<SHA256>.authenticationCode(for: Data(payload.utf8), using: key)
        let expectedToken = Data(expectedSig).map { String(format: "%02x", $0) }.joined()

        guard signature == expectedToken else {
            throw Abort(.unauthorized, reason: "Invalid verification link")
        }

        // Find or create user
        let user: UserModel
        if let existing = try await UserModel.query(on: req.db).filter(\.$email == email).first() {
            user = existing
        } else {
            user = UserModel(from: User(email: email, provider: .google))
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
