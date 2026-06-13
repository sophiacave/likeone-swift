import Vapor
import Fluent
import LOBrain
import LOContent

/// Cron-triggered tasks (digest send, etc.)
/// Gated by shared secret (X-Cron-Token header).
struct CronController: RouteCollection {
    let brain: LocalBrainClient
    let blog: BlogProvider

    func boot(routes: RoutesBuilder) throws {
        let cron = routes.grouped("api", "cron").grouped(CronTokenMiddleware())
        cron.post("digest", use: digest)
        cron.get("digest", "preview", use: digestPreview)
    }

    /// Send weekly brain-picks digest to all active "weekly" subscribers.
    /// POST /api/cron/digest?dryRun=true|false
    @Sendable
    func digest(req: Request) async throws -> Response {
        let dryRun = (try? req.query.get(Bool.self, at: "dryRun")) ?? false
        let limitOverride = try? req.query.get(Int.self, at: "limit")

        var query = SubscriberModel.query(on: req.db)
            .filter(\.$active == true)
        if let limit = limitOverride {
            query = query.limit(limit)
        }
        let subscribers = try await query.all()

        let weekly = subscribers.filter { ($0.frequency ?? "weekly").lowercased() == "weekly" }
        let service = DigestService(brain: brain, blog: blog, client: req.client)

        var sent = 0
        var skipped = 0
        let errors = 0  // sendDigest is fire-and-forget; Resend failures are logged inside ResendService

        for sub in weekly {
            let items = await service.generateDigest(for: sub)
            if items.isEmpty {
                skipped += 1
                continue
            }
            if dryRun {
                sent += 1
                continue
            }
            await service.sendDigest(to: sub, items: items, client: req.client)
            sent += 1
            // Be gentle on Resend rate limits (10 req/sec on free)
            try? await Task.sleep(nanoseconds: 150_000_000) // 150ms
        }

        let result = DigestRunResult(
            ranAt: Date(),
            totalActive: subscribers.count,
            weekly: weekly.count,
            sent: sent,
            skipped: skipped,
            errors: errors,
            dryRun: dryRun
        )

        req.logger.info("[digest-cron] sent=\(sent) skipped=\(skipped) errors=\(errors) dryRun=\(dryRun)")

        let response = Response(status: .ok)
        try response.content.encode(result)
        return response
    }

    /// Preview the digest a specific subscriber would receive (by email).
    /// GET /api/cron/digest/preview?email=foo@bar.com
    @Sendable
    func digestPreview(req: Request) async throws -> Response {
        guard let email = try? req.query.get(String.self, at: "email") else {
            throw Abort(.badRequest, reason: "email query param required")
        }
        guard let sub = try await SubscriberModel.query(on: req.db)
            .filter(\.$email == email.lowercased())
            .first() else {
            throw Abort(.notFound, reason: "subscriber not found")
        }
        let service = DigestService(brain: brain, blog: blog, client: req.client)
        let items = await service.generateDigest(for: sub)
        let response = Response(status: .ok)
        try response.content.encode(DigestPreview(email: sub.email, interests: sub.interests, items: items.map {
            PreviewItem(title: $0.title, url: $0.url, description: $0.description)
        }))
        return response
    }
}

struct DigestRunResult: Content {
    let ranAt: Date
    let totalActive: Int
    let weekly: Int
    let sent: Int
    let skipped: Int
    let errors: Int
    let dryRun: Bool
}

struct DigestPreview: Content {
    let email: String
    let interests: String?
    let items: [PreviewItem]
}

struct PreviewItem: Content {
    let title: String
    let url: String
    let description: String
}

/// Middleware: requires X-Cron-Token header matching CRON_TOKEN env or faye_config.cron_token.
struct CronTokenMiddleware: AsyncMiddleware {
    func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
        let expected = Self.expectedToken()
        guard !expected.isEmpty else {
            throw Abort(.serviceUnavailable, reason: "cron token not configured on server")
        }
        let provided = request.headers.first(name: "X-Cron-Token") ?? ""
        guard provided == expected else {
            throw Abort(.unauthorized, reason: "invalid cron token")
        }
        return try await next.respond(to: request)
    }

    static func expectedToken() -> String {
        // 1. Env var wins
        if let env = Environment.get("CRON_TOKEN"), !env.isEmpty { return env }
        // 2. Fall back to faye_config.json (same pattern as ResendService)
        let configPath = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".fractal_brain/faye_config.json").path
        if let data = FileManager.default.contents(atPath: configPath),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let key = json["cron_token"] as? String {
            return key
        }
        return ""
    }
}
