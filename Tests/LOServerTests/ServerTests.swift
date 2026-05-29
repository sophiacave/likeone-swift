import Testing
import Foundation

@testable import LOServer
import Vapor
import XCTVapor

@Suite("LOServer Routes")
struct ServerTests {
    private func withApp(_ test: (Application) async throws -> Void) async throws {
        let app = try await Application.make(.testing)
        try routes(app)
        try await test(app)
        try await app.asyncShutdown()
    }

    @Test("Health endpoint returns ok")
    func healthCheck() async throws {
        try await withApp { app in
            try await app.test(.GET, "health") { res async in
                #expect(res.status == .ok)
                #expect(res.body.string == "ok")
            }
        }
    }

    @Test("API info returns version and package info")
    func apiInfo() async throws {
        try await withApp { app in
            try await app.test(.GET, "api/info") { res async in
                #expect(res.status == .ok)
                let body = res.body.string
                #expect(body.contains("LikeOne Swift"))
                #expect(body.contains("Vapor"))
            }
        }
    }

    @Test("API courses returns 52 courses")
    func apiCourses() async throws {
        try await withApp { app in
            try await app.test(.GET, "api/v1/courses") { res async throws in
                #expect(res.status == .ok)
                let courses = try res.content.decode([CodableCourse].self)
                #expect(courses.count == 52)
            }
        }
    }

    @Test("API blog returns 16 posts")
    func apiBlog() async throws {
        try await withApp { app in
            try await app.test(.GET, "api/v1/blog") { res async throws in
                #expect(res.status == .ok)
                let posts = try res.content.decode([CodableBlogPost].self)
                #expect(posts.count == 16)
            }
        }
    }

    @Test("API products returns 10 products")
    func apiProducts() async throws {
        try await withApp { app in
            try await app.test(.GET, "api/v1/products") { res async throws in
                #expect(res.status == .ok)
                let products = try res.content.decode([CodableProduct].self)
                #expect(products.count == 10)
            }
        }
    }

    @Test("API course by slug returns correct course")
    func apiCourseBySlug() async throws {
        try await withApp { app in
            try await app.test(.GET, "api/v1/courses/claude-for-beginners") { res async throws in
                #expect(res.status == .ok)
                let course = try res.content.decode(CodableCourse.self)
                #expect(course.slug == "claude-for-beginners")
            }
        }
    }

    @Test("API missing course returns 404")
    func apiCourseMissing() async throws {
        try await withApp { app in
            try await app.test(.GET, "api/v1/courses/nonexistent") { res async in
                #expect(res.status == .notFound)
            }
        }
    }
}

// Decodable structs for testing
struct CodableCourse: Content { let slug: String; let title: String }
struct CodableBlogPost: Content { let slug: String; let title: String }
struct CodableProduct: Content { let slug: String; let name: String }
