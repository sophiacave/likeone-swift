import Vapor
import Foundation

/// In-memory IP-based rate limiter for auth endpoints.
/// Tokens refill over time (token bucket algorithm).
final class RateLimitMiddleware: AsyncMiddleware, @unchecked Sendable {
    private let maxTokens: Int
    private let refillRate: Double // tokens per second
    private let lock = NSLock()
    private var buckets: [String: Bucket] = [:]
    private var lastCleanup: Date = Date()

    struct Bucket {
        var tokens: Double
        var lastRefill: Date
    }

    /// - Parameters:
    ///   - maxRequests: Max burst size
    ///   - perSeconds: Time window for refill (e.g. 60 = maxRequests per minute)
    init(maxRequests: Int, perSeconds: Int) {
        self.maxTokens = maxRequests
        self.refillRate = Double(maxRequests) / Double(perSeconds)
    }

    func respond(to request: Request, chainingTo next: any AsyncResponder) async throws -> Response {
        let ip = request.headers.first(name: "CF-Connecting-IP")
            ?? request.headers.first(name: "X-Forwarded-For")?.split(separator: ",").first.map(String.init)
            ?? request.remoteAddress?.ipAddress
            ?? "unknown"

        let now = Date()

        let allowed: Bool = lock.withLock {
            // Periodic cleanup of stale buckets (every 5 min)
            if now.timeIntervalSince(lastCleanup) > 300 {
                buckets = buckets.filter { now.timeIntervalSince($0.value.lastRefill) < 600 }
                lastCleanup = now
            }

            var bucket = buckets[ip] ?? Bucket(tokens: Double(maxTokens), lastRefill: now)

            // Refill tokens
            let elapsed = now.timeIntervalSince(bucket.lastRefill)
            bucket.tokens = min(Double(maxTokens), bucket.tokens + elapsed * refillRate)
            bucket.lastRefill = now

            if bucket.tokens >= 1.0 {
                bucket.tokens -= 1.0
                buckets[ip] = bucket
                return true
            } else {
                buckets[ip] = bucket
                return false
            }
        }

        guard allowed else {
            let response = Response(status: .tooManyRequests)
            response.headers.add(name: "Retry-After", value: "60")
            try response.content.encode(["error": "Too many requests. Please try again later."])
            return response
        }

        return try await next.respond(to: request)
    }
}
