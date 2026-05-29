import Vapor
import LOCore
import LOContent

struct APIController: RouteCollection {
    let courses: CourseProvider
    let blog: BlogProvider
    let catalog: ProductCatalog
    let lessons: LessonProvider

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
}
