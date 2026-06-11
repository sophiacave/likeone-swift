import Fluent

struct CreateAuthHandoffs: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("auth_handoffs")
            .id()
            .field("code", .string, .required)
            .field("session_token", .string, .required)
            .field("expires_at", .datetime, .required)
            .unique(on: "code")
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("auth_handoffs").delete()
    }
}
