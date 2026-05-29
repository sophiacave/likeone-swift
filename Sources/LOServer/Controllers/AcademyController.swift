import Vapor
import Leaf
import LOCore
import LOContent

struct AcademyController: RouteCollection {
    let courses: CourseProvider
    let lessons: LessonProvider

    func boot(routes: RoutesBuilder) throws {
        let academy = routes.grouped("academy")
        academy.get(use: index)
        academy.get(":slug", use: courseDetail)
        academy.get("filter", use: filterCourses)
    }

    @Sendable
    func index(req: Request) async throws -> View {
        let allCourses = courses.allCourses()
        let tierFilter = req.query[String.self, at: "tier"]

        let filtered: [Course]
        if let tier = tierFilter, tier != "all" {
            filtered = courses.courses(forTier: tier)
        } else {
            filtered = allCourses
        }

        let tiers = courses.tierSummary
        let totalLessons = allCourses.reduce(0) { $0 + realLessonCount($1.slug) }

        let context = AcademyContext(
            title: "Free AI Academy | Like One",
            description: "52 courses, \(totalLessons)+ hands-on lessons. From your first AI conversation to building autonomous systems.",
            totalCourses: allCourses.count,
            totalLessons: totalLessons,
            tiers: tiers.map { TierInfo(name: $0.name, emoji: $0.emoji, count: $0.count) },
            courses: filtered.map { courseCard($0) },
            activeTier: tierFilter ?? "all"
        )
        return try await req.view.render("academy", context)
    }

    @Sendable
    func courseDetail(req: Request) async throws -> View {
        guard let slug = req.parameters.get("slug"),
              let course = courses.course(slug: slug) else {
            throw Abort(.notFound, reason: "Course not found")
        }

        let courseLessons = lessons.lessons(forCourse: slug)

        let context = CourseDetailContext(
            title: "\(course.title) | Like One Academy",
            course: courseCard(course),
            lessons: courseLessons.map { LessonItem(
                slug: $0.slug,
                title: $0.title,
                order: $0.order,
                isFree: $0.isFree,
                courseSlug: slug
            )}
        )
        return try await req.view.render("course", context)
    }

    @Sendable
    func filterCourses(req: Request) async throws -> View {
        let tier = req.query[String.self, at: "tier"] ?? "all"
        let filtered: [Course]
        if tier != "all" {
            filtered = courses.courses(forTier: tier)
        } else {
            filtered = courses.allCourses()
        }
        let context = CourseGridContext(
            courses: filtered.map { courseCard($0) }
        )
        return try await req.view.render("partials/course-grid", context)
    }

    private func courseCard(_ course: Course) -> CourseCard {
        CourseCard(
            slug: course.slug,
            title: course.title,
            description: course.description,
            emoji: course.emoji,
            level: course.level.tierName,
            lessonCount: realLessonCount(course.slug),
            tier: course.tier.rawValue
        )
    }

    private func realLessonCount(_ courseSlug: String) -> Int {
        let count = lessons.lessonCount(forCourse: courseSlug)
        return count > 0 ? count : 10
    }
}

struct AcademyContext: Content {
    let title: String
    let description: String
    let totalCourses: Int
    let totalLessons: Int
    let tiers: [TierInfo]
    let courses: [CourseCard]
    let activeTier: String
}

struct TierInfo: Content {
    let name: String
    let emoji: String
    let count: Int
}

struct CourseCard: Content {
    let slug: String
    let title: String
    let description: String
    let emoji: String
    let level: String
    let lessonCount: Int
    let tier: String
}

struct CourseDetailContext: Content {
    let title: String
    let course: CourseCard
    let lessons: [LessonItem]
}

struct LessonItem: Content {
    let slug: String
    let title: String
    let order: Int
    let isFree: Bool
    let courseSlug: String
}

struct CourseGridContext: Content {
    let courses: [CourseCard]
}
