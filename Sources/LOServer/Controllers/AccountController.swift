import Vapor
import Leaf
import Fluent
import LOContent
import LOBrain

struct AccountController: RouteCollection {
    let courses: CourseProvider
    let lessons: LessonProvider
    let brain: LocalBrainClient

    func boot(routes: RoutesBuilder) throws {
        let protected = routes.grouped(AuthMiddleware())
        protected.get("account", use: account)
    }

    @Sendable
    func account(req: Request) async throws -> View {
        let user = req.authenticatedUser!

        // Fetch server-side progress (authoritative)
        let allProgress = try await ProgressModel.query(on: req.db)
            .filter(\.$userID == user.id!)
            .all()

        // Group by course and calculate completion
        var courseProgress: [AccountCourseProgress] = []
        let progressByCourse = Dictionary(grouping: allProgress, by: \.courseSlug)

        for (courseSlug, completed) in progressByCourse {
            guard let course = courses.course(slug: courseSlug) else { continue }
            let totalLessons = lessons.lessonCount(forCourse: courseSlug)
            guard totalLessons > 0 else { continue }
            let completedCount = completed.count
            let pct = Int(Double(completedCount) / Double(totalLessons) * 100)
            let isComplete = completedCount >= totalLessons

            // Find next uncompleted lesson
            let completedSlugs = Set(completed.map(\.lessonSlug))
            let nextLesson = lessons.lessons(forCourse: courseSlug)
                .first(where: { !completedSlugs.contains($0.slug) })

            courseProgress.append(AccountCourseProgress(
                slug: courseSlug,
                title: course.title,
                emoji: course.emoji,
                completed: completedCount,
                total: totalLessons,
                percent: pct,
                isComplete: isComplete,
                nextLessonSlug: nextLesson?.slug,
                nextLessonTitle: nextLesson?.title
            ))
        }

        // Sort: in-progress first (by completion %), then complete
        courseProgress.sort { a, b in
            if a.isComplete != b.isComplete { return !a.isComplete }
            return a.percent > b.percent
        }

        // Fetch certificates
        let certs = try await CertificateModel.query(on: req.db)
            .filter(\.$userID == user.id!)
            .sort(\.$earnedAt, .descending)
            .all()

        // Stats
        let totalLessonsCompleted = allProgress.count
        let totalCoursesCompleted = courseProgress.filter(\.isComplete).count

        // Brain-powered suggestions: find related courses the user hasn't started
        var suggestions: [AccountSuggestion] = []
        if brain.isAvailable, let topCourse = courseProgress.first {
            let brainResults = try await brain.contentSearch(query: topCourse.title, limit: 5)
            let startedSlugs = Set(courseProgress.map(\.slug))
            for r in brainResults where r.collection == "academy" {
                let slug = String(r.docID.dropFirst(7)) // strip "course_"
                guard !startedSlugs.contains(slug),
                      let course = courses.course(slug: slug) else { continue }
                suggestions.append(AccountSuggestion(
                    slug: course.slug, title: course.title, emoji: course.emoji,
                    reason: "Related to \(topCourse.title)"
                ))
                if suggestions.count >= 3 { break }
            }
        }

        let context = AccountContext(
            title: "Account | Like One",
            email: user.email,
            name: user.name ?? "Academy Member",
            avatarURL: user.avatarURL,
            subscription: user.subscription,
            courses: courseProgress,
            certificates: certs.map { AccountCert(id: $0.id?.uuidString ?? "", type: $0.type, title: $0.title) },
            stats: AccountStats(
                lessonsCompleted: totalLessonsCompleted,
                coursesCompleted: totalCoursesCompleted,
                certificatesEarned: certs.count
            ),
            suggestions: suggestions
        )
        return try await req.view.render("account", context)
    }
}

struct AccountContext: Content {
    let title: String
    let email: String
    let name: String
    let avatarURL: String?
    let subscription: String
    let courses: [AccountCourseProgress]
    let certificates: [AccountCert]
    let stats: AccountStats
    let suggestions: [AccountSuggestion]
}

struct AccountSuggestion: Content {
    let slug: String
    let title: String
    let emoji: String
    let reason: String
}

struct AccountCourseProgress: Content {
    let slug: String
    let title: String
    let emoji: String
    let completed: Int
    let total: Int
    let percent: Int
    let isComplete: Bool
    let nextLessonSlug: String?
    let nextLessonTitle: String?
}

struct AccountCert: Content {
    let id: String
    let type: String
    let title: String
}

struct AccountStats: Content {
    let lessonsCompleted: Int
    let coursesCompleted: Int
    let certificatesEarned: Int
}
