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

        // Brain-powered HYBRID search (FTS5 keyword + sqlite-vec semantic, RRF fused)
        // Phase 1: Living AI App megaplan — site instantly feels intelligent.
        if brain.isAvailable {
            let brainResults = (try? await brain.hybridContentSearch(query: query, limit: 15)) ?? []
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
        case "blog_content":
            // Format: blog_{slug}_{chunk} — slug uses hyphens
            var slug = String(docID.dropFirst(5))
            if let i = slug.lastIndex(of: "_"), let _ = Int(slug[slug.index(after: i)...]) {
                slug = String(slug[..<i])
            }
            if let post = blog.allPosts().first(where: { $0.slug == slug }) {
                return SearchResult(type: "blog", title: post.title, description: String(r.snippet.prefix(120)),
                                   url: "/blog/\(post.slug)/", emoji: "\u{1F4DD}", meta: "Blog Post")
            }
            return nil
        case "blog_posts":
            // Format: blog_{underscored_title} — fuzzy match against posts
            let norm = docID.dropFirst(5).lowercased()
            if let post = blog.allPosts().first(where: { norm.contains($0.slug.replacingOccurrences(of: "-", with: "_")) }) {
                return SearchResult(type: "blog", title: post.title, description: String(r.snippet.prefix(120)),
                                   url: "/blog/\(post.slug)/", emoji: "\u{1F4DD}", meta: "Blog Post")
            }
            return nil
        case "lessons":
            // Format: lesson_{course}_{lesson}_{chunk}
            let body = String(docID.dropFirst(7))
            for course in courses.allCourses() {
                let prefix = course.slug + "_"
                guard body.hasPrefix(prefix) else { continue }
                var lessonPart = String(body.dropFirst(prefix.count))
                if let i = lessonPart.lastIndex(of: "_"), let _ = Int(lessonPart[lessonPart.index(after: i)...]) {
                    lessonPart = String(lessonPart[..<i])
                }
                let title = lessons.lessons(forCourse: course.slug)
                    .first(where: { $0.slug == lessonPart })?.title ?? String(r.snippet.prefix(60))
                return SearchResult(type: "lesson", title: title, description: course.title,
                                   url: "/academy/\(course.slug)/\(lessonPart)/", emoji: course.emoji,
                                   meta: "Lesson \u{00B7} \(course.title)")
            }
            return nil
        case "faqs":
            // Format: faq_{blog-slug}_{number}
            var slug = String(docID.dropFirst(4))
            if let i = slug.lastIndex(of: "_"), let _ = Int(slug[slug.index(after: i)...]) {
                slug = String(slug[..<i])
            }
            if let post = blog.allPosts().first(where: { $0.slug == slug }) {
                return SearchResult(type: "faq", title: String(r.snippet.prefix(120)), description: post.title,
                                   url: "/blog/\(post.slug)/", emoji: "\u{2753}", meta: "FAQ")
            }
            return nil
        case "academy":
            // Format: course_{slug}
            let slug = String(docID.dropFirst(7))
            if let course = courses.allCourses().first(where: { $0.slug == slug }) {
                return SearchResult(type: "course", title: course.title, description: course.description,
                                   url: "/academy/\(course.slug)/", emoji: course.emoji,
                                   meta: "\(course.level.tierName) \u{00B7} \(lessons.lessonCount(forCourse: course.slug)) lessons")
            }
            return nil
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
