import Testing
import Foundation

@testable import LOServer
import Vapor
import XCTVapor
import Leaf

@Suite("LOServer Routes")
struct ServerTests {
    private func withApp(_ test: (Application) async throws -> Void) async throws {
        let app = try await Application.make(.testing)
        app.views.use(.leaf)
        try routes(app)
        try await XCTVaporContext.$emitWarningIfCurrentTestInfoIsAvailable.withValue(false) {
            try await test(app)
        }
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

    @Test("API blog returns 18 posts")
    func apiBlog() async throws {
        try await withApp { app in
            try await app.test(.GET, "api/v1/blog") { res async throws in
                #expect(res.status == .ok)
                let posts = try res.content.decode([CodableBlogPost].self)
                #expect(posts.count == 22)
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

    @Test("API course lessons returns lesson list")
    func apiCourseLessons() async throws {
        try await withApp { app in
            try await app.test(.GET, "api/v1/courses/ai-foundations/lessons") { res async throws in
                #expect(res.status == .ok)
                let lessons = try res.content.decode([CodableLesson].self)
                #expect(lessons.count == 9)
                #expect(lessons.first?.title == "What Is a Neuron?")
            }
        }
    }

    @Test("Auth me without session returns 401")
    func authMeUnauthorized() async throws {
        try await withApp { app in
            try await app.test(.GET, "auth/me") { res async in
                #expect(res.status == .unauthorized)
            }
        }
    }

    @Test("About page returns 200")
    func aboutPage() async throws {
        try await withApp { app in
            try await app.test(.GET, "about") { res async in
                #expect(res.status == .ok)
                #expect(res.body.string.contains("Like One"))
            }
        }
    }

    @Test("Pricing page returns 200")
    func pricingPage() async throws {
        try await withApp { app in
            try await app.test(.GET, "pricing") { res async in
                #expect(res.status == .ok)
                #expect(res.body.string.contains("free"))
            }
        }
    }

    @Test("Foundation page returns 200")
    func foundationPage() async throws {
        try await withApp { app in
            try await app.test(.GET, "foundation") { res async in
                #expect(res.status == .ok)
                #expect(res.body.string.contains("501(c)(3)"))
            }
        }
    }

    @Test("API tracks returns 6 learning tracks")
    func apiTracks() async throws {
        try await withApp { app in
            try await app.test(.GET, "api/v1/tracks") { res async throws in
                #expect(res.status == .ok)
                let tracks = try res.content.decode([CodableTrack].self)
                #expect(tracks.count == 6)
            }
        }
    }

    @Test("API track by slug returns correct track")
    func apiTrackBySlug() async throws {
        try await withApp { app in
            try await app.test(.GET, "api/v1/tracks/ai-foundations-path") { res async throws in
                #expect(res.status == .ok)
                let track = try res.content.decode(CodableTrack.self)
                #expect(track.slug == "ai-foundations-path")
                #expect(track.courses.count == 3)
            }
        }
    }

    @Test("Tracks page returns 200")
    func tracksPage() async throws {
        try await withApp { app in
            try await app.test(.GET, "tracks") { res async in
                #expect(res.status == .ok)
                #expect(res.body.string.contains("Learning Tracks"))
            }
        }
    }

    @Test("Track detail page returns 200")
    func trackDetailPage() async throws {
        try await withApp { app in
            try await app.test(.GET, "tracks/ai-foundations-path") { res async in
                #expect(res.status == .ok)
                #expect(res.body.string.contains("AI Foundations Path"))
            }
        }
    }
}

// Decodable structs for testing
struct CodableCourse: Content { let slug: String; let title: String }
struct CodableBlogPost: Content { let slug: String; let title: String }
struct CodableProduct: Content { let slug: String; let name: String }
struct CodableLesson: Content { let slug: String; let title: String; let order: Int }
struct CodableTrack: Content { let slug: String; let title: String; let courses: [String] }
