import Vapor
import Leaf

func configure(_ app: Application) async throws {
    // Leaf templates
    app.views.use(.leaf)

    // Serve static files from Public/
    app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    // Register routes
    try routes(app)
}
