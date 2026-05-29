import Fluent

struct CreateUsers: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("users")
            .id()
            .field("email", .string, .required)
            .field("name", .string)
            .field("avatar_url", .string)
            .field("provider", .string, .required, .custom("DEFAULT 'apple'"))
            .field("stripe_customer_id", .string)
            .field("subscription", .string, .required, .custom("DEFAULT 'free'"))
            .field("created_at", .datetime)
            .unique(on: "email")
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("users").delete()
    }
}
