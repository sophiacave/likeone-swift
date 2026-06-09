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
    app.migrations.add(CreateCertificates())
    app.migrations.add(CreateSubscribers())
    app.migrations.add(AddUserMemoryFields())
    app.migrations.add(AddSubscriberPreferences())
    app.migrations.add(CreatePageViews())
    app.migrations.add(AddUserRole())
    try await app.autoMigrate()

    // Leaf templates
    app.views.use(.leaf)

    // Trailing slash normalization (301 redirect for SEO canonicalization)
    app.middleware.use(TrailingSlashMiddleware())

    // Cache headers (registered before FileMiddleware so it wraps static file responses)
    app.middleware.use(CacheMiddleware())

    // Serve static files from Public/
    app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    // Page view tracking (privacy-first, local only — Phase 6)
    app.middleware.use(TrackingMiddleware())

    // Custom error pages (404, 500)
    app.middleware.use(CustomErrorMiddleware())

    // Register routes
    try routes(app)
}
