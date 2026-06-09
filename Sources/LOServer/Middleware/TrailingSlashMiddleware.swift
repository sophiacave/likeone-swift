import Vapor

struct TrailingSlashMiddleware: AsyncMiddleware {
    func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
        let path = request.url.path

        guard request.method == .GET || request.method == .HEAD else {
            return try await next.respond(to: request)
        }

        // Strip .html extension and redirect (legacy Next.js URLs)
        if path.hasSuffix(".html") {
            let stripped = String(path.dropLast(5)) + "/"
            return request.redirect(to: stripped, redirectType: .permanent)
        }

        // Skip root, trailing-slash, static assets, API, health
        guard !path.hasSuffix("/"),
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
