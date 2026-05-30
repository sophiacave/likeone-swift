import Fluent

struct CreateSubscribers: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("subscribers")
            .id()
            .field("email", .string, .required)
            .field("name", .string)
            .field("source_page", .string, .required)
            .field("unsubscribe_token", .string, .required)
            .field("active", .bool, .required)
            .field("created_at", .datetime)
            .unique(on: "email")
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("subscribers").delete()
    }
}
