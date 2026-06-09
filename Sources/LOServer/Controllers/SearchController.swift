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

        // Brain-powered search (hybrid: FTS5 + semantic vec, typo-tolerant)
        if brain.isAvailable {
            let brainResults = try await brain.hybridContentSearch(query: query, limit: 20)
                .filter { $0.score >= 0.016 } // Filter low-ranked vec-only noise while preserving typo tolerance
            var seenURLs: Set<String> = []
            for r in brainResults {
                if let result = mapBrainResult(r), !seenURLs.contains(result.url) {
                    seenURLs.insert(result.url)
                    results.append(result)
                }
            }
        }

        // Fallback: if brain returned few results, supplement with basic search
        if results.count < 5 {
            let queryLower = query.lowercased()
            for course in courses.allCourses() {
                if course.title.lowercased().contains(queryLower) || course.description.lowercased().contains(queryLower) {
                    let sr = SearchResult(type: "course", title: course.title, description: course.description,
                                         url: "/academy/\(course.slug)/", emoji: course.emoji,
                                         meta: "\(course.level.tierName) \u{00B7} \(lessons.lessonCount(forCourse: course.slug)) lessons")
                    if !results.contains(where: { $0.url == sr.url }) { results.append(sr) }
                }
            }
            for post in blog.allPosts() {
                if post.title.lowercased().contains(queryLower) || post.description.lowercased().contains(queryLower) {
                    let sr = SearchResult(type: "blog", title: post.title, description: post.description,
                                         url: "/blog/\(post.slug)/", emoji: "\u{1F4DD}", meta: "Blog Post")
                    if !results.contains(where: { $0.url == sr.url }) { results.append(sr) }
                }
            }
        }

        let context = SearchResultsContext(results: Array(results.prefix(20)), query: query, total: results.count)
        return try await req.view.render("partials/search-results", context)
    }

    /// Clean raw brain snippet — strip "path (chunk N): " prefixes and titles
    private func cleanSnippet(_ raw: String) -> String {
        var text = raw
        // Strip "course/lesson (chunk N): " prefix
        if let colonRange = text.range(of: "): ") {
            text = String(text[colonRange.upperBound...])
        } else if let colonRange = text.range(of: ": ", range: text.startIndex..<text.index(text.startIndex, offsetBy: min(150, text.count))) {
            // Strip "Title: " prefix from blog content (only if within first 150 chars)
            let prefix = text[..<colonRange.lowerBound]
            if prefix.count > 20 { // likely a title, strip it
                text = String(text[colonRange.upperBound...])
            }
        }
        return String(text.prefix(140)).trimmingCharacters(in: .whitespaces)
    }

    /// Map brain content search result to display-friendly SearchResult
    private func mapBrainResult(_ r: ContentSearchResult) -> SearchResult? {
        let docID = r.docID
        switch r.collection {
        case "blog_content":
            var slug = String(docID.dropFirst(5))
            if let i = slug.lastIndex(of: "_"), let _ = Int(slug[slug.index(after: i)...]) {
                slug = String(slug[..<i])
            }
            if let post = blog.allPosts().first(where: { $0.slug == slug }) {
                return SearchResult(type: "blog", title: post.title, description: cleanSnippet(r.snippet),
                                   url: "/blog/\(post.slug)/", emoji: "\u{1F4DD}", meta: "Blog Post")
            }
            return nil
        case "blog_posts":
            let norm = docID.dropFirst(5).lowercased()
            if let post = blog.allPosts().first(where: { norm.contains($0.slug.replacingOccurrences(of: "-", with: "_")) }) {
                return SearchResult(type: "blog", title: post.title, description: post.description,
                                   url: "/blog/\(post.slug)/", emoji: "\u{1F4DD}", meta: "Blog Post")
            }
            return nil
        case "lessons":
            let body = String(docID.dropFirst(7))
            for course in courses.allCourses() {
                let prefix = course.slug + "_"
                guard body.hasPrefix(prefix) else { continue }
                var lessonPart = String(body.dropFirst(prefix.count))
                if let i = lessonPart.lastIndex(of: "_"), let _ = Int(lessonPart[lessonPart.index(after: i)...]) {
                    lessonPart = String(lessonPart[..<i])
                }
                let lesson = lessons.lessons(forCourse: course.slug).first(where: { $0.slug == lessonPart })
                let title = lesson?.title ?? lessonPart.replacingOccurrences(of: "-", with: " ").capitalized
                return SearchResult(type: "lesson", title: title, description: cleanSnippet(r.snippet),
                                   url: "/academy/\(course.slug)/\(lessonPart)/", emoji: course.emoji,
                                   meta: "Lesson \u{00B7} \(course.title)")
            }
            return nil
        case "faqs":
            var slug = String(docID.dropFirst(4))
            if let i = slug.lastIndex(of: "_"), let _ = Int(slug[slug.index(after: i)...]) {
                slug = String(slug[..<i])
            }
            // Extract just the question from "Q: ... A: ..."
            let faqText = r.snippet
            let displayText: String
            if faqText.hasPrefix("Q: ") {
                let afterQ = faqText.dropFirst(3)
                if let aRange = afterQ.range(of: "\nA: ") ?? afterQ.range(of: " A: ") {
                    displayText = String(afterQ[..<aRange.lowerBound])
                } else {
                    displayText = String(afterQ.prefix(120))
                }
            } else {
                displayText = cleanSnippet(faqText)
            }
            if let post = blog.allPosts().first(where: { $0.slug == slug }) {
                return SearchResult(type: "faq", title: displayText, description: "",
                                   url: "/blog/\(post.slug)/", emoji: "\u{2753}", meta: "FAQ \u{00B7} \(post.title)")
            }
            return nil
        case "academy":
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
