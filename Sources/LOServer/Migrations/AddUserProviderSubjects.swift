import Fluent

/// Stable provider identity (S273). Store the verified token `sub` claim so
/// users are matched by immutable provider ID first — an email change at
/// Google/Apple no longer forks the account. Nullable; backfilled on sign-in.
struct AddUserProviderSubjects: AsyncMigration {
    func prepare(on database: Database) async throws {
        // SQLite: one ADD COLUMN per ALTER TABLE — two separate updates.
        try await database.schema("users")
            .field("google_sub", .string)
            .update()
        try await database.schema("users")
            .field("apple_sub", .string)
            .update()
    }

    func revert(on database: Database) async throws {
        try await database.schema("users")
            .deleteField("google_sub")
            .update()
        try await database.schema("users")
            .deleteField("apple_sub")
            .update()
    }
}
