import Vapor
import Leaf
import Fluent
import FluentSQLiteDriver

func configure(_ app: Application) async throws {
    // Database — SQLite for now, swap to Postgres when scale demands
    app.databases.use(.sqlite(.file("likeone.db")), as: .sqlite)

    // Migrations
    app.migrations.add(CreateUsers())
    app.migrations.add(CreateSessions())
    app.migrations.add(CreateProgress())
    try await app.autoMigrate()

    // Leaf templates
    app.views.use(.leaf)

    // Serve static files from Public/
    app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    // Register routes
    try routes(app)
}
