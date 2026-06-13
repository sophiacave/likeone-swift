import Vapor
import LOCore
import LOContent

struct APIController: RouteCollection {
    let courses: CourseProvider
    let blog: BlogProvider
    let catalog: ProductCatalog
    let lessons: LessonProvider
    let tracks: TrackProvider

    func boot(routes: RoutesBuilder) throws {
        let api = routes.grouped("api")

        // Info
        api.get("info", use: info)

        // V1 API
        let v1 = api.grouped("v1")

        // Courses
        v1.get("courses", use: allCourses)
        v1.get("courses", ":slug", use: getCourse)
        v1.get("courses", ":slug", "lessons", use: courseLessons)

        // Blog
        v1.get("blog", use: allPosts)
        v1.get("blog", ":slug", use: getPost)

        // Products
        v1.get("products", use: allProducts)
        v1.get("products", ":slug", use: getProduct)

        // Tracks
        v1.get("tracks", use: allTracks)
        v1.get("tracks", ":slug", use: getTrack)

        // Lesson HTML for the iOS app — raw fragment, gated like the web.
        // The app sends `Authorization: Bearer <token>` for pro access.
        v1.grouped(OptionalAuthMiddleware())
            .get("lessons", ":course", ":lesson", "html", use: lessonHTML)
    }

    @Sendable
    func info(req: Request) async -> [String: String] {
        [
            "name": "LikeOne Swift",
            "version": "0.3.0",
            "runtime": "Vapor 4 + Leaf + HTMX",
            "swift": "6.0",
            "packages": "LOCore, LOBrain, LOAuth, LODesign, LOContent, LOServer",
        ]
    }

    @Sendable
    func allCourses(req: Request) async throws -> Response {
        let response = Response(status: .ok)
        try response.content.encode(courses.allCourses())
        return response
    }

    @Sendable
    func getCourse(req: Request) async throws -> Response {
        guard let slug = req.parameters.get("slug"),
              let course = courses.course(slug: slug) else {
            throw Abort(.notFound, reason: "Course not found")
        }
        let response = Response(status: .ok)
        try response.content.encode(course)
        return response
    }

    @Sendable
    func courseLessons(req: Request) async throws -> Response {
        guard let slug = req.parameters.get("slug") else {
            throw Abort(.badRequest, reason: "Course slug required")
        }
        let courseLessons = lessons.lessons(forCourse: slug)
        guard !courseLessons.isEmpty else {
            throw Abort(.notFound, reason: "No lessons found for course '\(slug)'")
        }
        let response = Response(status: .ok)
        try response.content.encode(courseLessons)
        return response
    }

    @Sendable
    func allPosts(req: Request) async throws -> Response {
        let response = Response(status: .ok)
        try response.content.encode(blog.allPosts())
        return response
    }

    @Sendable
    func getPost(req: Request) async throws -> Response {
        guard let slug = req.parameters.get("slug"),
              let post = blog.post(slug: slug) else {
            throw Abort(.notFound, reason: "Blog post not found")
        }
        let response = Response(status: .ok)
        try response.content.encode(post)
        return response
    }

    @Sendable
    func allProducts(req: Request) async throws -> Response {
        let response = Response(status: .ok)
        try response.content.encode(catalog.allProducts())
        return response
    }

    @Sendable
    func getProduct(req: Request) async throws -> Response {
        guard let slug = req.parameters.get("slug"),
              let product = catalog.product(slug: slug) else {
            throw Abort(.notFound, reason: "Product not found")
        }
        let response = Response(status: .ok)
        try response.content.encode(product)
        return response
    }

    /// Raw lesson HTML fragment for the native app's WKWebView, which applies
    /// its own styling and quiz engine. Same gate as the web: first 3 lessons
    /// free, the rest require pro/founding. Gated lessons return 200 with an
    /// upgrade card so the app renders a clean paywall instead of an error.
    @Sendable
    func lessonHTML(req: Request) async throws -> Response {
        guard let courseSlug = req.parameters.get("course"),
              let lessonSlug = req.parameters.get("lesson"),
              courses.course(slug: courseSlug) != nil,
              let lesson = lessons.lesson(courseSlug: courseSlug, lessonSlug: lessonSlug) else {
            throw Abort(.notFound, reason: "Lesson not found")
        }

        let isFreeLesson = lesson.order <= 3
        var isPro = false
        if let user = req.authenticatedUser {
            isPro = user.subscription == "pro" || user.subscription == "founding"
        }

        let html: String
        if isFreeLesson || isPro {
            // Slugs are validated against the catalog above, so they cannot
            // contain path traversal — only known lesson files are reachable.
            let contentPath = req.application.directory.resourcesDirectory + "Content/lessons/\(courseSlug)/\(lessonSlug).html"
            html = (try? String(contentsOfFile: contentPath, encoding: .utf8)) ?? "<p>Lesson content coming soon.</p>"
        } else {
            html = """
            <div class="learn-card">
                <span class="section-label">Academy Pro</span>
                <h3>\(lesson.title)</h3>
                <p>This lesson is part of Academy Pro. The first 3 lessons of every course are free — upgrade to unlock all 595+ lessons, certificates, and learning tracks.</p>
                <p><a href="https://likeone.ai/pricing">Upgrade at likeone.ai/pricing</a>, then sign in here to unlock everything.</p>
            </div>
            """
        }

        let response = Response(status: .ok)
        response.headers.replaceOrAdd(name: .contentType, value: "text/html; charset=utf-8")
        response.headers.replaceOrAdd(name: .cacheControl, value: "no-store")
        response.body = .init(string: html)
        return response
    }

    @Sendable
    func allTracks(req: Request) async throws -> Response {
        let response = Response(status: .ok)
        try response.content.encode(tracks.allTracks())
        return response
    }

    @Sendable
    func getTrack(req: Request) async throws -> Response {
        guard let slug = req.parameters.get("slug"),
              let track = tracks.track(bySlug: slug) else {
            throw Abort(.notFound, reason: "Learning track not found")
        }
        let response = Response(status: .ok)
        try response.content.encode(track)
        return response
    }
}
