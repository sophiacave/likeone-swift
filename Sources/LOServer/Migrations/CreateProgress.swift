import Fluent

struct CreateProgress: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("progress")
            .id()
            .field("user_id", .uuid, .required)
            .field("course_slug", .string, .required)
            .field("lesson_slug", .string, .required)
            .field("completed_at", .datetime)
            .unique(on: "user_id", "course_slug", "lesson_slug")
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("progress").delete()
    }
}
