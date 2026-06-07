import Vapor
import Leaf
import LOContent
import LOBrain

struct SearchController: RouteCollection {
    let courses: CourseProvider
    let lessons: LessonProvider
    let blog: BlogProvider
    let brain: LocalBrainClient

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
        let query = (req.query[String.self, at: "q"] ?? "").trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else {
            return try await req.view.render("partials/search-results", SearchResultsContext(results: [], query: "", total: 0))
        }

        var results: [SearchResult] = []

        // Brain-powered FTS5 search (semantic ranking across all public content)
        if brain.isAvailable {
            let brainResults = try await brain.contentSearch(query: query, limit: 15)
            for r in brainResults {
                let result = mapBrainResult(r)
                if let result { results.append(result) }
            }
        }

        // Fallback: if brain returned few results, supplement with basic search
        if results.count < 5 {
            let queryLower = query.lowercased()
            for course in courses.allCourses() {
                if course.title.lowercased().contains(queryLower) || course.description.lowercased().contains(queryLower) {
                    let sr = SearchResult(type: "course", title: course.title, description: course.description,
                                         url: "/academy/\(course.slug)", emoji: course.emoji,
                                         meta: "\(course.level.tierName) \u{00B7} \(lessons.lessonCount(forCourse: course.slug)) lessons")
                    if !results.contains(where: { $0.url == sr.url }) { results.append(sr) }
                }
            }
            for post in blog.allPosts() {
                if post.title.lowercased().contains(queryLower) || post.description.lowercased().contains(queryLower) {
                    let sr = SearchResult(type: "blog", title: post.title, description: post.description,
                                         url: "/blog/\(post.slug)", emoji: "\u{1F4DD}", meta: "Blog Post")
                    if !results.contains(where: { $0.url == sr.url }) { results.append(sr) }
                }
            }
        }

        let context = SearchResultsContext(results: Array(results.prefix(20)), query: query, total: results.count)
        return try await req.view.render("partials/search-results", context)
    }

    /// Map brain content search result to display-friendly SearchResult
    private func mapBrainResult(_ r: ContentSearchResult) -> SearchResult? {
        let docID = r.docID
        switch r.collection {
        case "blog_posts", "blog_content":
            let slug = docID
                .replacingOccurrences(of: "blog_", with: "")
                .components(separatedBy: "_").dropLast().joined(separator: "_")
                .replacingOccurrences(of: "_", with: "-")
            // Try to find the blog post
            if let post = blog.allPosts().first(where: { docID.contains($0.slug.replacingOccurrences(of: "-", with: "_")) || docID.contains($0.slug) }) {
                return SearchResult(type: "blog", title: post.title, description: String(r.snippet.prefix(120)),
                                   url: "/blog/\(post.slug)", emoji: "\u{1F4DD}", meta: "Blog Post")
            }
            return SearchResult(type: "blog", title: String(r.snippet.prefix(80)), description: "",
                               url: "/blog", emoji: "\u{1F4DD}", meta: "Blog")
        case "lessons":
            // Format: course_slug/lesson_slug (chunk N)
            let parts = docID.replacingOccurrences(of: "lesson_", with: "").components(separatedBy: "_")
            if parts.count >= 2 {
                let coursePart = parts[0]
                let lessonPart = parts.dropFirst().joined(separator: "_").components(separatedBy: "_").first ?? ""
                // Find matching course
                if let course = courses.allCourses().first(where: { $0.slug.contains(coursePart) || coursePart.contains($0.slug.replacingOccurrences(of: "-", with: "_")) }) {
                    return SearchResult(type: "lesson", title: String(r.snippet.prefix(80)), description: course.title,
                                       url: "/academy/\(course.slug)", emoji: course.emoji, meta: "Lesson \u{00B7} \(course.title)")
                }
            }
            return SearchResult(type: "lesson", title: String(r.snippet.prefix(80)), description: "",
                               url: "/academy", emoji: "\u{1F393}", meta: "Academy Lesson")
        case "faqs":
            return SearchResult(type: "faq", title: String(r.snippet.prefix(120)), description: "",
                               url: "/blog", emoji: "\u{2753}", meta: "FAQ")
        case "academy":
            if let course = courses.allCourses().first(where: { docID.contains($0.slug.replacingOccurrences(of: "-", with: "_")) || docID.contains($0.slug) }) {
                return SearchResult(type: "course", title: course.title, description: course.description,
                                   url: "/academy/\(course.slug)", emoji: course.emoji,
                                   meta: "\(course.level.tierName) \u{00B7} \(lessons.lessonCount(forCourse: course.slug)) lessons")
            }
            return SearchResult(type: "course", title: String(r.snippet.prefix(80)), description: "",
                               url: "/academy", emoji: "\u{1F393}", meta: "Course")
        default:
            return nil
        }
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
