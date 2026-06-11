import Vapor
import Leaf
import Fluent
import LOCore
import LOContent

struct TracksController: RouteCollection {
    let tracks: TrackProvider
    let courses: CourseProvider
    let lessons: LessonProvider

    func boot(routes: RoutesBuilder) throws {
        // Optional auth for server-rendered progress (S273 — DB truth, not localStorage)
        let authed = routes.grouped(OptionalAuthMiddleware())
        authed.get("tracks", use: index)
        authed.get("tracks", ":slug", use: detail)
    }

    @Sendable
    func index(req: Request) async throws -> View {
        let allTracks = tracks.allTracks()
        let progress = try await progressByCourse(req: req)
        let context = TracksContext(
            title: "Learning Tracks | Like One",
            description: "Curated learning paths from AI foundations to agent architecture. Complete a track, earn a certificate.",
            canonicalUrl: siteBaseURL + "/tracks/",
            tracks: allTracks.map { t in
                let courseSlugs = t.courses.isEmpty ? courses.allCourses().map(\.slug) : t.courses
                let totalLessons = courseSlugs.reduce(0) { $0 + realLessonCount($1) }
                let doneLessons = courseSlugs.reduce(0) { $0 + min(progress[$1] ?? 0, realLessonCount($1)) }
                let pct = totalLessons > 0 ? Int(Double(doneLessons) / Double(totalLessons) * 100) : 0
                return TrackCard(
                    slug: t.slug,
                    title: t.title,
                    description: t.description,
                    emoji: t.emoji,
                    courseCount: t.courses.isEmpty ? 52 : t.courses.count,
                    estimatedHours: t.estimatedHours,
                    difficulty: t.difficulty,
                    badgeColor: t.badgeColor,
                    progressPct: pct
                )
            }
        )
        return try await req.view.render("tracks", context)
    }

    @Sendable
    func detail(req: Request) async throws -> View {
        guard let slug = req.parameters.get("slug"),
              let track = tracks.track(bySlug: slug) else {
            throw Abort(.notFound, reason: "Learning track not found")
        }

        let progress = try await progressByCourse(req: req)

        func row(_ c: Course, order: Int) -> TrackCourseRow {
            let total = realLessonCount(c.slug)
            let done = min(progress[c.slug] ?? 0, total)
            return TrackCourseRow(
                slug: c.slug,
                title: c.title,
                description: c.description,
                emoji: c.emoji,
                order: order,
                isComplete: done >= total,
                pct: total > 0 ? Int(Double(done) / Double(total) * 100) : 0
            )
        }

        let trackCourses: [TrackCourseRow]
        if track.courses.isEmpty {
            // AI Master = all courses
            trackCourses = courses.allCourses().enumerated().map { i, c in row(c, order: i + 1) }
        } else {
            trackCourses = track.courses.enumerated().compactMap { i, slug in
                guard let c = courses.course(slug: slug) else { return nil }
                return row(c, order: i + 1)
            }
        }

        let completedCourses = trackCourses.filter(\.isComplete).count
        let trackPct = trackCourses.isEmpty ? 0
            : Int(Double(completedCourses) / Double(trackCourses.count) * 100)

        let context = TrackDetailContext(
            title: "\(track.title) | Like One",
            description: track.description,
            canonicalUrl: siteBaseURL + "/tracks/\(track.slug)/",
            track: TrackCard(
                slug: track.slug,
                title: track.title,
                description: track.description,
                emoji: track.emoji,
                courseCount: trackCourses.count,
                estimatedHours: track.estimatedHours,
                difficulty: track.difficulty,
                badgeColor: track.badgeColor,
                progressPct: trackPct
            ),
            courses: trackCourses,
            firstCourseSlug: trackCourses.first?.slug ?? "",
            completedCourses: completedCourses,
            trackPct: trackPct,
            hasProgress: trackCourses.contains { $0.pct > 0 }
        )
        return try await req.view.render("track-detail", context)
    }

    /// Per-course completed-lesson counts for the authenticated user (server truth).
    private func progressByCourse(req: Request) async throws -> [String: Int] {
        guard let user = req.authenticatedUser else { return [:] }
        let all = try await ProgressModel.query(on: req.db)
            .filter(\.$userID == user.id!)
            .all()
        return Dictionary(grouping: all, by: \.courseSlug)
            .mapValues { Set($0.map(\.lessonSlug)).count }
    }

    private func realLessonCount(_ courseSlug: String) -> Int {
        let count = lessons.lessonCount(forCourse: courseSlug)
        return count > 0 ? count : 10
    }
}

struct TracksContext: Content {
    let title: String
    let description: String
    let canonicalUrl: String?
    let tracks: [TrackCard]
}

struct TrackCard: Content {
    let slug: String
    let title: String
    let description: String
    let emoji: String
    let courseCount: Int
    let estimatedHours: Int
    let difficulty: String
    let badgeColor: String
    /// Server-rendered progress (0 when anonymous or none)
    let progressPct: Int
}

struct TrackDetailContext: Content {
    let title: String
    let description: String
    let canonicalUrl: String?
    let track: TrackCard
    let courses: [TrackCourseRow]
    let firstCourseSlug: String
    let completedCourses: Int
    let trackPct: Int
    let hasProgress: Bool
}

struct TrackCourseRow: Content {
    let slug: String
    let title: String
    let description: String
    let emoji: String
    let order: Int
    let isComplete: Bool
    let pct: Int
}
