import Vapor
import Fluent

/// Restricts a route group to admin users only.
///
/// Must be chained AFTER `AuthMiddleware` so `request.authenticatedUser` is set.
///
/// Behavior:
/// - Anonymous / unauthenticated → handled upstream by `AuthMiddleware` (redirects to /signin).
/// - Authenticated non-admin → 404 (do not reveal that the admin surface exists).
/// - Authenticated admin → request proceeds.
///
/// Founder bootstrap: emails listed in the `ADMIN_EMAILS` environment variable
/// (comma-separated) are auto-promoted to `role = "admin"` on first hit. This avoids
/// the cold-start chicken/egg where no admin exists yet to grant the first admin.
struct AdminOnlyMiddleware: AsyncMiddleware {
    func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
        guard let user = request.authenticatedUser else {
            // AuthMiddleware should have redirected already, but defend in depth.
            return request.redirect(to: "/signin/")
        }

        // Founder bootstrap: auto-promote configured emails to admin.
        if !user.isAdmin, Self.isFounderEmail(user.email) {
            user.role = "admin"
            try? await user.update(on: request.db)
            request.logger.info("Auto-promoted founder email to admin: \(user.email)")
        }

        guard user.isAdmin else {
            // 404 — do not reveal that /admin exists to non-admins.
            throw Abort(.notFound)
        }

        return try await next.respond(to: request)
    }

    /// Comma-separated `ADMIN_EMAILS` env var. Falls back to founder defaults
    /// so the dashboard works out-of-box in dev without env setup.
    static func isFounderEmail(_ email: String) -> Bool {
        let configured = Environment.get("ADMIN_EMAILS") ?? "sophiacave.me@gmail.com,hello@likeone.ai"
        let allowed = configured
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces).lowercased() }
            .filter { !$0.isEmpty }
        return allowed.contains(email.lowercased())
    }
}
