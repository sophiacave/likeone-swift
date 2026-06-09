import Vapor
import Fluent
import LOBrain
import LOContent

/// Admin dashboard (Phase 6 — Living AI App)
/// Privacy-first analytics. All data local. No third-party.
struct AdminController: RouteCollection {
    let brain: LocalBrainClient
    let blog: BlogProvider
    let courses: CourseProvider

    func boot(routes: RoutesBuilder) throws {
        // Admin routes require auth AND admin role (S265).
        // AuthMiddleware sets request.authenticatedUser or redirects to /signin.
        // AdminOnlyMiddleware enforces role == "admin" (404 for non-admins).
        let admin = routes
            .grouped("admin")
            .grouped(AuthMiddleware())
            .grouped(AdminOnlyMiddleware())
        admin.get(use: dashboard)
        admin.get("api", "stats", use: apiStats)
    }

    @Sendable
    func dashboard(req: Request) async throws -> View {
        let stats = try await gatherStats(on: req.db)
        return try await req.view.render("admin", stats)
    }

    @Sendable
    func apiStats(req: Request) async throws -> Response {
        let stats = try await gatherStats(on: req.db)
        let response = Response(status: .ok)
        try response.content.encode(stats)
        return response
    }

    private func gatherStats(on db: Database) async throws -> AdminStats {
        let now = Date()
        let oneDayAgo = now.addingTimeInterval(-86400)
        let sevenDaysAgo = now.addingTimeInterval(-7 * 86400)
        let thirtyDaysAgo = now.addingTimeInterval(-30 * 86400)

        // Page views
        let viewsToday = try await PageViewModel.query(on: db)
            .filter(\.$createdAt >= oneDayAgo).count()
        let views7d = try await PageViewModel.query(on: db)
            .filter(\.$createdAt >= sevenDaysAgo).count()
        let views30d = try await PageViewModel.query(on: db)
            .filter(\.$createdAt >= thirtyDaysAgo).count()
        let viewsTotal = try await PageViewModel.query(on: db).count()

        // Top pages (last 7 days)
        let allViews7d = try await PageViewModel.query(on: db)
            .filter(\.$createdAt >= sevenDaysAgo)
            .all()
        let topPages = Dictionary(grouping: allViews7d, by: \.path)
            .map { (path: $0.key, count: $0.value.count) }
            .sorted { $0.count > $1.count }
            .prefix(10)
            .map { TopPage(path: $0.path, views: $0.count) }

        // Users
        let totalUsers = try await UserModel.query(on: db).count()
        let activeUsers7d = try await UserModel.query(on: db)
            .filter(\.$lastActiveAt >= sevenDaysAgo).count()

        // Subscribers
        let totalSubs = try await SubscriberModel.query(on: db)
            .filter(\.$active == true).count()

        // Progress
        let totalLessonsCompleted = try await ProgressModel.query(on: db).count()
        let certs = try await CertificateModel.query(on: db).count()

        // Brain stats (real count, not hardcoded)
        let brainVectors = brain.contentCount()

        // Content stats
        let blogCount = blog.allPosts().count
        let courseCount = courses.allCourses().count

        return AdminStats(
            title: "Admin | Like One",
            viewsToday: viewsToday,
            views7d: views7d,
            views30d: views30d,
            viewsTotal: viewsTotal,
            topPages: topPages,
            totalUsers: totalUsers,
            activeUsers7d: activeUsers7d,
            totalSubscribers: totalSubs,
            lessonsCompleted: totalLessonsCompleted,
            certificates: certs,
            brainVectors: brainVectors,
            blogPosts: blogCount,
            courses: courseCount
        )
    }
}

struct AdminStats: Content {
    let title: String
    let viewsToday: Int
    let views7d: Int
    let views30d: Int
    let viewsTotal: Int
    let topPages: [TopPage]
    let totalUsers: Int
    let activeUsers7d: Int
    let totalSubscribers: Int
    let lessonsCompleted: Int
    let certificates: Int
    let brainVectors: Int
    let blogPosts: Int
    let courses: Int
}

struct TopPage: Content {
    let path: String
    let views: Int
}
