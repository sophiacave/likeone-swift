import Fluent

/// Add mobile flag to auth_handoffs — replaces lo_auth_mobile cookie
/// which iOS 17+ ITP strips during Google OAuth cross-site redirect. S[current].
struct AddAuthHandoffMobile: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("auth_handoffs")
            .field("mobile", .bool, .required, .sql(.default("0")))
            .update()
    }

    func revert(on database: Database) async throws {
        try await database.schema("auth_handoffs")
            .deleteField("mobile")
            .update()
    }
}
