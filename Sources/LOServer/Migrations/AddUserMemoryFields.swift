import Fluent

struct AddUserMemoryFields: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("users")
            .field("last_active_at", .datetime)
            .update()
        try await database.schema("users")
            .field("interests", .string)
            .update()
    }

    func revert(on database: Database) async throws {
        try await database.schema("users")
            .deleteField("last_active_at")
            .update()
        try await database.schema("users")
            .deleteField("interests")
            .update()
    }
}
