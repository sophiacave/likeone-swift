import Testing
import Foundation

@testable import LOServer
import LOContent
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

    @Test("API courses returns 53 courses")
    func apiCourses() async throws {
        try await withApp { app in
            try await app.test(.GET, "api/v1/courses") { res async throws in
                #expect(res.status == .ok)
                let courses = try res.content.decode([CodableCourse].self)
                #expect(courses.count == 53)
            }
        }
    }

    @Test("API blog returns all posts")
    func apiBlog() async throws {
        try await withApp { app in
            try await app.test(.GET, "api/v1/blog") { res async throws in
                #expect(res.status == .ok)
                let posts = try res.content.decode([CodableBlogPost].self)
                #expect(posts.count >= 30)
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

    @Test("API lesson HTML returns content for free lesson")
    func apiLessonHTMLFree() async throws {
        try await withApp { app in
            try await app.test(.GET, "api/v1/lessons/ai-foundations/what-is-a-neuron/html") { res async in
                #expect(res.status == .ok)
                #expect(res.headers.contentType?.subType == "html")
                #expect(res.body.string.contains("lesson-section") || res.body.string.contains("learn-card"))
                #expect(!res.body.string.contains("Academy Pro</span>"))
            }
        }
    }

    @Test("API lesson HTML returns paywall for gated lesson without auth")
    func apiLessonHTMLGated() async throws {
        try await withApp { app in
            // ai-foundations lesson 9 of 9 — beyond the free first 3
            let lessons = LessonProvider().lessons(forCourse: "ai-foundations")
            let gated = try #require(lessons.first(where: { $0.order > 3 }))
            try await app.test(.GET, "api/v1/lessons/ai-foundations/\(gated.slug)/html") { res async in
                #expect(res.status == .ok)
                #expect(res.body.string.contains("Academy Pro"))
                #expect(res.body.string.contains("likeone.ai/pricing"))
            }
        }
    }

    @Test("API lesson HTML returns 404 for unknown lesson")
    func apiLessonHTMLMissing() async throws {
        try await withApp { app in
            try await app.test(.GET, "api/v1/lessons/ai-foundations/not-a-lesson/html") { res async in
                #expect(res.status == .notFound)
            }
        }
    }

    @Test("Mobile signin page serves GIS button and sets mobile flag cookie")
    func mobileSigninPage() async throws {
        try await withApp { app in
            try await app.test(.GET, "signin/mobile") { res async in
                #expect(res.status == .ok)
                #expect(res.body.string.contains("g_id_onload"))
                #expect(res.body.string.contains("auth/google/callback"))
                #expect(res.headers.setCookie?.all["lo_auth_mobile"]?.string == "1")
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
