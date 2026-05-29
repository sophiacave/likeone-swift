import Vapor

struct HealthController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        routes.get("health", use: health)
    }

    @Sendable
    func health(req: Request) async -> String {
        "ok"
    }
}
