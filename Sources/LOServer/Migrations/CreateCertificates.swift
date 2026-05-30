import Fluent

struct CreateCertificates: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("certificates")
            .id()
            .field("user_id", .uuid, .required)
            .field("type", .string, .required)
            .field("course_slug", .string)
            .field("track_slug", .string)
            .field("title", .string, .required)
            .field("recipient_name", .string, .required)
            .field("earned_at", .datetime)
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("certificates").delete()
    }
}
