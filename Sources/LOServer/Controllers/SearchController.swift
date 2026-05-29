import Vapor
import Leaf
import LOContent

struct SearchController: RouteCollection {
    let courses: CourseProvider
    let lessons: LessonProvider
    let blog: BlogProvider

    func boot(routes: RoutesBuilder) throws {
        routes.get("search", use: searchPage)
        routes.get("search", "results", use: searchResults)
    }

    @Sendable
    func searchPage(req: Request) async throws -> View {
        let query = req.query[String.self, at: "q"] ?? ""
        let context = SearchPageContext(
            title: "Search | Like One Academy",
            query: query
        )
        return try await req.view.render("search", context)
    }

    @Sendable
    func searchResults(req: Request) async throws -> View {
        let query = (req.query[String.self, at: "q"] ?? "").lowercased().trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else {
            return try await req.view.render("partials/search-results", SearchResultsContext(results: [], query: "", total: 0))
        }

        var results: [SearchResult] = []

        // Search courses
        for course in courses.allCourses() {
            if course.title.lowercased().contains(query) || course.description.lowercased().contains(query) {
                results.append(SearchResult(
                    type: "course",
                    title: course.title,
                    description: course.description,
                    url: "/academy/\(course.slug)",
                    emoji: course.emoji,
                    meta: "\(course.level.tierName) \u{00B7} \(lessons.lessonCount(forCourse: course.slug)) lessons"
                ))
            }
        }

        // Search lessons
        for course in courses.allCourses() {
            for lesson in lessons.lessons(forCourse: course.slug) {
                if lesson.title.lowercased().contains(query) {
                    results.append(SearchResult(
                        type: "lesson",
                        title: lesson.title,
                        description: course.title,
                        url: "/academy/\(course.slug)/\(lesson.slug)",
                        emoji: course.emoji,
                        meta: "Lesson \(lesson.order) \u{00B7} \(course.title)"
                    ))
                }
            }
        }

        // Search blog
        for post in blog.allPosts() {
            if post.title.lowercased().contains(query) || post.description.lowercased().contains(query) {
                results.append(SearchResult(
                    type: "blog",
                    title: post.title,
                    description: post.description,
                    url: "/blog/\(post.slug)",
                    emoji: "\u{1F4DD}",
                    meta: "Blog Post"
                ))
            }
        }

        let context = SearchResultsContext(results: Array(results.prefix(20)), query: query, total: results.count)
        return try await req.view.render("partials/search-results", context)
    }
}

struct SearchPageContext: Content {
    let title: String
    let query: String
}

struct SearchResultsContext: Content {
    let results: [SearchResult]
    let query: String
    let total: Int
}

struct SearchResult: Content {
    let type: String
    let title: String
    let description: String
    let url: String
    let emoji: String
    let meta: String
}
