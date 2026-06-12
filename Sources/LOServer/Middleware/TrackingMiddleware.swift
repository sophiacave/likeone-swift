import Vapor
import Fluent

/// Privacy-first page view tracking (Phase 6 — Living AI App)
/// Logs page views async (fire-and-forget). No third-party services.
/// Skips static assets, API calls, and bot traffic.
struct TrackingMiddleware: AsyncMiddleware {
    func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
        let response = try await next.respond(to: request)

        let path = request.url.path

        // Skip non-page requests
        guard response.status == .ok,
              !path.hasPrefix("/api/"),
              !path.hasPrefix("/css/"),
              !path.hasPrefix("/js/"),
              !path.hasPrefix("/images/"),
              !path.hasPrefix("/health"),
              !path.hasSuffix(".xml"),
              !path.hasSuffix(".webp"),
              !path.hasSuffix(".png"),
              !path.hasSuffix(".ico") else {
            return response
        }

        // Skip bots and our own tooling (curl canary, lo-verify, scripts)
        let ua = request.headers.first(name: .userAgent)?.lowercased() ?? ""
        let botMarkers = ["bot", "crawler", "spider", "curl/", "wget/", "lo-verify",
                          "python-requests", "python-urllib", "go-http-client", "headless"]
        guard !ua.isEmpty, !botMarkers.contains(where: { ua.contains($0) }) else {
            return response
        }

        // Fire-and-forget page view log
        let userID = request.authenticatedUser?.id
        let referrer = request.headers.first(name: .referer)
        let userAgent = request.headers.first(name: .userAgent)

        Task {
            let view = PageViewModel(
                path: String(path.prefix(500)),
                userID: userID,
                referrer: referrer.map { String($0.prefix(500)) },
                userAgent: userAgent.map { String($0.prefix(200)) }
            )
            try? await view.save(on: request.db)
        }

        return response
    }
}
