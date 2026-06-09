import Fluent

/// Add role-based access control to users (S265).
/// role = "user" (default) | "admin"
/// Admins get access to /admin dashboard.
struct AddUserRole: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("users")
            .field("role", .string, .required, .custom("DEFAULT 'user'"))
            .update()
    }

    func revert(on database: Database) async throws {
        try await database.schema("users")
            .deleteField("role")
            .update()
    }
}
