import Vapor
import Leaf
import LOContent

struct HomeController: RouteCollection {
    let courses: CourseProvider
    let blog: BlogProvider
    let lessons: LessonProvider

    func boot(routes: RoutesBuilder) throws {
        routes.get(use: index)
    }

    @Sendable
    func index(req: Request) async throws -> View {
        let allCourses = courses.allCourses()
        let allPosts = blog.allPosts()

        // Pick 6 featured courses (first from each tier)
        let beginnerCourses = courses.courses(forTier: "beginner")
        let intermediateCourses = courses.courses(forTier: "intermediate")
        let advancedCourses = courses.courses(forTier: "advanced")

        var featured: [FeaturedCourse] = []
        for course in (beginnerCourses.prefix(2) + intermediateCourses.prefix(2) + advancedCourses.prefix(2)) {
            featured.append(FeaturedCourse(
                slug: course.slug,
                title: course.title,
                emoji: course.emoji,
                description: course.description,
                tier: course.level.tierName
            ))
        }

        // Latest 3 blog posts
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        let latestPosts = allPosts.prefix(3).map { post in
            BlogPreview(slug: post.slug, title: post.title, description: post.description, date: formatter.string(from: post.publishedAt))
        }

        let totalLessons = allCourses.reduce(0) { $0 + max(lessons.lessonCount(forCourse: $1.slug), 1) }

        let context = HomeContext(
            title: "Like One | Free AI Academy",
            description: "\(allCourses.count) free courses. \(totalLessons)+ hands-on lessons. From your first AI conversation to building autonomous systems.",
            canonicalUrl: siteBaseURL,
            stats: [
                Stat(number: "\(allCourses.count)", label: "Courses"),
                Stat(number: "\(totalLessons)", label: "Lessons"),
                Stat(number: "$0", label: "To Start"),
                Stat(number: "7", label: "Levels"),
            ],
            featured: featured,
            tiers: [
                TierPreview(name: "Beginner", emoji: "\u{1F331}", count: beginnerCourses.count, description: "Start here. No experience needed."),
                TierPreview(name: "Intermediate", emoji: "\u{1F527}", count: intermediateCourses.count, description: "Build real workflows and automations."),
                TierPreview(name: "Advanced", emoji: "\u{1F680}", count: advancedCourses.count, description: "Architect autonomous AI systems."),
            ],
            latestPosts: Array(latestPosts)
        )
        return try await req.view.render("index", context)
    }
}

struct HomeContext: Content {
    let title: String
    let description: String
    let canonicalUrl: String?
    let stats: [Stat]
    let featured: [FeaturedCourse]
    let tiers: [TierPreview]
    let latestPosts: [BlogPreview]
}

struct Stat: Content {
    let number: String
    let label: String
}

struct FeaturedCourse: Content {
    let slug: String
    let title: String
    let emoji: String
    let description: String
    let tier: String
}

struct TierPreview: Content {
    let name: String
    let emoji: String
    let count: Int
    let description: String
}

struct BlogPreview: Content {
    let slug: String
    let title: String
    let description: String
    let date: String
}
