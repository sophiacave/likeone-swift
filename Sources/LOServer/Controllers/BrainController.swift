import Vapor
import LOCore
import LOBrain

struct BrainController: RouteCollection {
    let brain: LocalBrainClient

    func boot(routes: RoutesBuilder) throws {
        // Status is safe to expose publicly (no private data)
        let publicAPI = routes.grouped("api", "v1", "brain")
        publicAPI.get("status", use: status)

        // All other brain endpoints require authentication (private data)
        let protectedAPI = routes.grouped("api", "v1", "brain").grouped(AuthMiddleware())
        protectedAPI.get("boot", use: bootBrain)
        protectedAPI.get("search", use: search)
        protectedAPI.get(":key", use: readKey)
    }

    @Sendable
    func status(req: Request) async -> [String: String] {
        ["available": String(brain.isAvailable), "mode": brain.isAvailable ? "local" : "unavailable"]
    }

    @Sendable
    func bootBrain(req: Request) async throws -> Response {
        guard brain.isAvailable else {
            let response = Response(status: .ok)
            try response.content.encode([String: String]())
            return response
        }
        let entries = try await brain.boot()
        let response = Response(status: .ok)
        try response.content.encode(entries)
        return response
    }

    @Sendable
    func search(req: Request) async throws -> Response {
        let q = req.query[String.self, at: "q"] ?? ""
        let limit = req.query[Int.self, at: "limit"] ?? 5
        guard !q.isEmpty else {
            throw Abort(.badRequest, reason: "Query parameter 'q' is required")
        }
        guard brain.isAvailable else {
            let response = Response(status: .ok)
            try response.content.encode([[String: String]]())
            return response
        }
        let entries = try await brain.search(query: q, limit: limit)
        let response = Response(status: .ok)
        try response.content.encode(entries)
        return response
    }

    @Sendable
    func readKey(req: Request) async throws -> Response {
        guard brain.isAvailable else {
            throw Abort(.notFound, reason: "Brain not available on this server")
        }
        guard let key = req.parameters.get("key"),
              let entry = try await brain.read(key: key) else {
            throw Abort(.notFound, reason: "Brain key not found")
        }
        let response = Response(status: .ok)
        try response.content.encode(entry)
        return response
    }
}
