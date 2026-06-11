import Vapor

struct HealthController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        routes.get("health", use: health)
    }

    @Sendable
    func health(req: Request) async -> String {
        // DEPLOY_SHA is injected by lo-swift-deploy so the canary can verify
        // WHICH build is serving, not just that something answers. S273:
        // a stale orphan process passed canary while new code never bound.
        if let sha = Environment.get("DEPLOY_SHA") {
            return "ok \(sha)"
        }
        return "ok"
    }
}
