import Vapor
import Leaf
import Fluent
import FluentSQLiteDriver

func configure(_ app: Application) async throws {
    // Database — SQLite with persistent volume on Fly.io, local file in dev
    let dbPath: String
    if FileManager.default.isWritableFile(atPath: "/data") {
        dbPath = "/data/likeone.db"
    } else {
        dbPath = "likeone.db"
    }
    app.databases.use(.sqlite(.file(dbPath)), as: .sqlite)

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
