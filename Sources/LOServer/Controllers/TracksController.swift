import Vapor
import Leaf
import LOCore
import LOContent

struct TracksController: RouteCollection {
    let tracks: TrackProvider
    let courses: CourseProvider

    func boot(routes: RoutesBuilder) throws {
        routes.get("tracks", use: index)
        routes.get("tracks", ":slug", use: detail)
    }

    @Sendable
    func index(req: Request) async throws -> View {
        let allTracks = tracks.allTracks()
        let context = TracksContext(
            title: "Learning Tracks | Like One",
            description: "Curated learning paths from AI foundations to agent architecture. Complete a track, earn a certificate.",
            canonicalUrl: siteBaseURL + "/tracks",
            tracks: allTracks.map { t in
                TrackCard(
                    slug: t.slug,
                    title: t.title,
                    description: t.description,
                    emoji: t.emoji,
                    courseCount: t.courses.isEmpty ? 52 : t.courses.count,
                    estimatedHours: t.estimatedHours,
                    difficulty: t.difficulty,
                    badgeColor: t.badgeColor
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

        let trackCourses: [TrackCourseRow]
        if track.courses.isEmpty {
            // AI Master = all courses
            trackCourses = courses.allCourses().enumerated().map { i, c in
                TrackCourseRow(slug: c.slug, title: c.title, description: c.description, emoji: c.emoji, order: i + 1)
            }
        } else {
            trackCourses = track.courses.enumerated().compactMap { i, slug in
                guard let c = courses.course(slug: slug) else { return nil }
                return TrackCourseRow(slug: c.slug, title: c.title, description: c.description, emoji: c.emoji, order: i + 1)
            }
        }

        let context = TrackDetailContext(
            title: "\(track.title) | Like One",
            description: track.description,
            canonicalUrl: siteBaseURL + "/tracks/\(track.slug)",
            track: TrackCard(
                slug: track.slug,
                title: track.title,
                description: track.description,
                emoji: track.emoji,
                courseCount: trackCourses.count,
                estimatedHours: track.estimatedHours,
                difficulty: track.difficulty,
                badgeColor: track.badgeColor
            ),
            courses: trackCourses,
            firstCourseSlug: trackCourses.first?.slug ?? ""
        )
        return try await req.view.render("track-detail", context)
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
}

struct TrackDetailContext: Content {
    let title: String
    let description: String
    let canonicalUrl: String?
    let track: TrackCard
    let courses: [TrackCourseRow]
    let firstCourseSlug: String
}

struct TrackCourseRow: Content {
    let slug: String
    let title: String
    let description: String
    let emoji: String
    let order: Int
}
