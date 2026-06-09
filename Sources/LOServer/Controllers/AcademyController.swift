import Vapor
import Leaf
import Fluent
import LOCore
import LOContent

struct AcademyController: RouteCollection {
    let courses: CourseProvider
    let lessons: LessonProvider

    func boot(routes: RoutesBuilder) throws {
        let academy = routes.grouped("academy")
        academy.get(use: index)
        // Course detail and lessons use optional auth for Pro gating
        let authAcademy = academy.grouped(OptionalAuthMiddleware())
        authAcademy.get(":slug", use: courseDetail)
        authAcademy.get(":slug", ":lessonSlug", use: lessonPage)
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
            title: "Free AI Courses — Claude, Agents & Prompt Engineering | Like One Academy",
            description: "\(allCourses.count) courses, \(totalLessons)+ lessons. First 3 free on every course. From prompts to autonomous agents.",
            totalCourses: allCourses.count,
            totalLessons: totalLessons,
            tiers: tiers.map { TierInfo(name: $0.name, emoji: $0.emoji, count: $0.count) },
            courses: filtered.map { courseCard($0) },
            activeTier: tierFilter ?? "all",
            canonicalUrl: "https://likeone.ai/academy/"
        )
        return try await req.view.render("academy", context)
    }

    @Sendable
    func courseDetail(req: Request) async throws -> View {
        guard let slug = req.parameters.get("slug"),
              let course = courses.course(slug: slug) else {
            throw Abort(.notFound, reason: "Course not found")
        }

        var isPro = false
        var completedSlugs: Set<String> = []
        if let user = req.authenticatedUser {
            isPro = user.subscription == "pro" || user.subscription == "founding"
            let progress = try await ProgressModel.query(on: req.db)
                .filter(\.$userID == user.id!)
                .filter(\.$courseSlug == slug)
                .all()
            completedSlugs = Set(progress.map(\.lessonSlug))
        }

        let courseLessons = lessons.lessons(forCourse: slug)
        let totalLessons = courseLessons.count
        let completedCount = completedSlugs.count
        let progressPct = totalLessons > 0 ? Int(Double(completedCount) / Double(totalLessons) * 100) : 0

        let canonicalUrl = "https://likeone.ai/academy/\(slug)/"
        let context = CourseDetailContext(
            title: "\(course.title) | Like One Academy",
            course: courseCard(course),
            lessons: courseLessons.map { LessonItem(
                slug: $0.slug,
                title: $0.title,
                order: $0.order,
                isFree: isPro || $0.order <= 3,
                courseSlug: slug,
                isCompleted: completedSlugs.contains($0.slug)
            )},
            isPro: isPro,
            completedCount: completedCount,
            totalLessons: totalLessons,
            progressPct: progressPct,
            canonicalUrl: canonicalUrl,
            ogUrl: canonicalUrl
        )
        return try await req.view.render("course", context)
    }

    @Sendable
    func lessonPage(req: Request) async throws -> View {
        guard let courseSlug = req.parameters.get("slug"),
              let lessonSlug = req.parameters.get("lessonSlug"),
              let course = courses.course(slug: courseSlug),
              let lesson = lessons.lesson(courseSlug: courseSlug, lessonSlug: lessonSlug) else {
            throw Abort(.notFound, reason: "Lesson not found")
        }

        let courseLessons = lessons.lessons(forCourse: courseSlug)
        let currentIndex = courseLessons.firstIndex(where: { $0.slug == lessonSlug }) ?? 0
        let prevLesson = currentIndex > 0 ? courseLessons[currentIndex - 1] : nil
        let nextLesson = currentIndex < courseLessons.count - 1 ? courseLessons[currentIndex + 1] : nil

        // Gate: first 3 lessons are free, rest require Pro
        let isFreeLesson = lesson.order <= 3
        var isPro = false
        if let user = req.authenticatedUser {
            isPro = user.subscription == "pro" || user.subscription == "founding"
        }

        let content: String
        if isFreeLesson || isPro {
            let contentPath = req.application.directory.resourcesDirectory + "Content/lessons/\(courseSlug)/\(lessonSlug).html"
            content = (try? String(contentsOfFile: contentPath, encoding: .utf8)) ?? "<p>Lesson content coming soon.</p>"
        } else {
            // Paywall content
            content = ""
        }

        let canonicalUrl = "https://likeone.ai/academy/\(courseSlug)/\(lessonSlug)/"
        let context = LessonPageContext(
            title: "\(lesson.title) | \(course.title) | Like One Academy",
            description: course.description,
            courseTitle: course.title,
            courseSlug: courseSlug,
            courseEmoji: course.emoji,
            lessonTitle: lesson.title,
            lessonOrder: lesson.order,
            totalLessons: courseLessons.count,
            content: content,
            prevSlug: prevLesson?.slug,
            prevTitle: prevLesson?.title,
            nextSlug: nextLesson?.slug,
            nextTitle: nextLesson?.title,
            isLocked: !isFreeLesson && !isPro,
            canonicalUrl: canonicalUrl,
            ogUrl: canonicalUrl
        )
        return try await req.view.render("lesson", context)
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
    let canonicalUrl: String
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
    let isPro: Bool
    let completedCount: Int
    let totalLessons: Int
    let progressPct: Int
    let canonicalUrl: String?
    let ogUrl: String?
}

struct LessonItem: Content {
    let slug: String
    let title: String
    let order: Int
    let isFree: Bool
    let courseSlug: String
    let isCompleted: Bool
}

struct CourseGridContext: Content {
    let courses: [CourseCard]
}

struct LessonPageContext: Content {
    let title: String
    let description: String
    let courseTitle: String
    let courseSlug: String
    let courseEmoji: String
    let lessonTitle: String
    let lessonOrder: Int
    let totalLessons: Int
    let content: String
    let prevSlug: String?
    let prevTitle: String?
    let nextSlug: String?
    let nextTitle: String?
    let isLocked: Bool
    let canonicalUrl: String?
    let ogUrl: String?
}
