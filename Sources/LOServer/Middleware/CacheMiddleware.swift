import Vapor

struct CacheMiddleware: AsyncMiddleware {
    func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
        let response = try await next.respond(to: request)
        let path = request.url.path

        if path.hasPrefix("/auth/") {
            // Auth flows (OAuth callbacks, /auth/complete cookie handoff) must
            // never be cached — caching a one-time code page breaks sign-in. S273.
            response.headers.replaceOrAdd(name: .cacheControl, value: "no-store")
        } else if path.hasSuffix(".webp") || path.hasSuffix(".jpg") || path.hasSuffix(".png") ||
           path.hasSuffix(".css") || path.hasSuffix(".js") || path.hasSuffix(".woff2") {
            response.headers.replaceOrAdd(name: .cacheControl, value: "public, max-age=31536000, immutable")
        } else if path == "/sitemap.xml" || path == "/robots.txt" {
            response.headers.replaceOrAdd(name: .cacheControl, value: "public, max-age=3600")
        } else if response.headers.contentType == .html {
            if request.cookies["lo_session"] != nil {
                // Personalized HTML (progress, account, Pro gating) must never be
                // served from a shared or stale browser cache. S273.
                response.headers.replaceOrAdd(name: .cacheControl, value: "private, no-cache")
            } else {
                response.headers.replaceOrAdd(name: .cacheControl, value: "public, max-age=600, stale-while-revalidate=60")
                // Signing in changes the Cookie header → cached anonymous HTML no longer matches
                response.headers.replaceOrAdd(name: .vary, value: "Cookie")
            }
        }

        return response
    }
}
