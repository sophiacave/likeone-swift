import Fluent

struct CreateSessions: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("sessions")
            .id()
            .field("user_id", .uuid, .required)
            .field("token", .string, .required)
            .field("created_at", .datetime)
            .field("expires_at", .datetime, .required)
            .unique(on: "token")
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("sessions").delete()
    }
}
