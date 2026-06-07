import Fluent

struct AddSubscriberPreferences: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("subscribers")
            .field("interests", .string)
            .update()
        try await database.schema("subscribers")
            .field("frequency", .string)
            .update()
    }

    func revert(on database: Database) async throws {
        try await database.schema("subscribers")
            .deleteField("interests")
            .update()
        try await database.schema("subscribers")
            .deleteField("frequency")
            .update()
    }
}
