import Vapor

struct CacheMiddleware: AsyncMiddleware {
    func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
        let response = try await next.respond(to: request)
        let path = request.url.path

        if path.hasSuffix(".webp") || path.hasSuffix(".jpg") || path.hasSuffix(".png") ||
           path.hasSuffix(".css") || path.hasSuffix(".js") || path.hasSuffix(".woff2") {
            response.headers.replaceOrAdd(name: .cacheControl, value: "public, max-age=31536000, immutable")
        } else if path == "/sitemap.xml" || path == "/robots.txt" {
            response.headers.replaceOrAdd(name: .cacheControl, value: "public, max-age=3600")
        } else if response.headers.contentType == .html {
            response.headers.replaceOrAdd(name: .cacheControl, value: "public, max-age=600, stale-while-revalidate=60")
        }

        return response
    }
}
