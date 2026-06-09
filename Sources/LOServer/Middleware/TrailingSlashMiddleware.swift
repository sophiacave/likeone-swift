import Vapor

struct TrailingSlashMiddleware: AsyncMiddleware {
    func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
        let path = request.url.path

        // Redirect GET and HEAD requests; skip root, trailing-slash, static assets, API, health
        guard (request.method == .GET || request.method == .HEAD),
              !path.hasSuffix("/"),
              path != "/",
              !path.contains("."),
              !path.hasPrefix("/api/"),
              path != "/health" else {
            return try await next.respond(to: request)
        }

        // 301 redirect to trailing slash version
        var redirectURL = path + "/"
        if let query = request.url.query, !query.isEmpty {
            redirectURL += "?" + query
        }
        return request.redirect(to: redirectURL, redirectType: .permanent)
    }
}
