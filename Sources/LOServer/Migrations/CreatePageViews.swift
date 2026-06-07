import Fluent

struct CreatePageViews: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("page_views")
            .id()
            .field("path", .string, .required)
            .field("user_id", .uuid)
            .field("referrer", .string)
            .field("user_agent", .string)
            .field("created_at", .datetime)
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("page_views").delete()
    }
}
