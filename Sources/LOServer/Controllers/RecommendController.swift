import Vapor
import LOContent
import LOBrain

/// Brain-powered content recommendations (Phase 4 — Living AI App)
/// Any page can call GET /api/v1/recommend?topic=X to get related content.
/// Returns HTMX-ready HTML partial. Only searches public content.
struct RecommendController: RouteCollection {
    let courses: CourseProvider
    let lessons: LessonProvider
    let blog: BlogProvider
    let brain: LocalBrainClient

    func boot(routes: RoutesBuilder) throws {
        let api = routes.grouped("api", "v1")
        api.get("recommend", use: recommend)
    }

    @Sendable
    func recommend(req: Request) async throws -> Response {
        let topic = req.query[String.self, at: "topic"] ?? ""
        let limitParam = req.query[Int.self, at: "limit"] ?? 4
        let excludeSlug = req.query[String.self, at: "exclude"] ?? ""
        let limit = min(limitParam, 6)

        guard !topic.isEmpty, brain.isAvailable else {
            return Response(status: .ok, body: .init(string: ""))
        }

        let brainResults = try await brain.contentSearch(query: topic, limit: limit + 5)
        var html = ""
        var count = 0
        var seenURLs: Set<String> = []

        for r in brainResults {
            guard count < limit else { break }

            var title = ""
            var url = ""
            var meta = ""
            var emoji = ""

            switch r.collection {
            case "blog_content", "blog_posts":
                var slug = r.collection == "blog_content" ? String(r.docID.dropFirst(5)) : ""
                if r.collection == "blog_content" {
                    if let i = slug.lastIndex(of: "_"), let _ = Int(slug[slug.index(after: i)...]) {
                        slug = String(slug[..<i])
                    }
                }
                if let post = (r.collection == "blog_content")
                    ? blog.allPosts().first(where: { $0.slug == slug })
                    : blog.allPosts().first(where: { r.docID.dropFirst(5).lowercased().contains($0.slug.replacingOccurrences(of: "-", with: "_")) }) {
                    if post.slug == excludeSlug { continue }
                    title = post.title
                    url = "/blog/\(post.slug)/"
                    meta = "Blog Post"
                    emoji = "\u{1F4DD}"
                } else { continue }
            case "lessons":
                let body = String(r.docID.dropFirst(7))
                var matched = false
                for course in courses.allCourses() {
                    let prefix = course.slug + "_"
                    guard body.hasPrefix(prefix) else { continue }
                    var lessonPart = String(body.dropFirst(prefix.count))
                    if let i = lessonPart.lastIndex(of: "_"), let _ = Int(lessonPart[lessonPart.index(after: i)...]) {
                        lessonPart = String(lessonPart[..<i])
                    }
                    if lessonPart == excludeSlug || course.slug == excludeSlug { continue }
                    let lessonTitle = lessons.lessons(forCourse: course.slug).first(where: { $0.slug == lessonPart })?.title
                        ?? lessonPart.replacingOccurrences(of: "-", with: " ").capitalized
                    title = lessonTitle
                    url = "/academy/\(course.slug)/\(lessonPart)/"
                    meta = "Lesson · \(course.title)"
                    emoji = course.emoji
                    matched = true
                    break
                }
                if !matched { continue }
            case "faqs":
                var slug = String(r.docID.dropFirst(4))
                if let i = slug.lastIndex(of: "_"), let _ = Int(slug[slug.index(after: i)...]) {
                    slug = String(slug[..<i])
                }
                if slug == excludeSlug { continue }
                if let post = blog.allPosts().first(where: { $0.slug == slug }) {
                    title = post.title
                    url = "/blog/\(post.slug)/"
                    meta = "FAQ · Blog Post"
                    emoji = "\u{2753}"
                } else { continue }
            case "academy":
                let courseSlug = String(r.docID.dropFirst(7))
                if courseSlug == excludeSlug { continue }
                if let course = courses.course(slug: courseSlug) {
                    title = course.title
                    url = "/academy/\(course.slug)/"
                    meta = "Course"
                    emoji = course.emoji
                } else { continue }
            default:
                continue
            }

            guard !seenURLs.contains(url) else { continue }
            seenURLs.insert(url)

            html += """
            <a href="\(url)" style="display:flex;align-items:center;gap:12px;padding:12px;background:var(--bg-card);border:1px solid var(--border);border-radius:8px;text-decoration:none;color:inherit;transition:border-color .3s;">
                <span style="font-size:1.2rem;">\(emoji)</span>
                <div>
                    <div style="font-size:.85rem;font-weight:600;color:var(--text-primary);">\(escapeHTML(title))</div>
                    <div style="font-size:.7rem;color:var(--text-muted);">\(meta)</div>
                </div>
            </a>
            """
            count += 1
        }

        guard count > 0 else {
            return Response(status: .ok, body: .init(string: ""))
        }

        let wrapper = """
        <div style="margin-top:2rem;padding-top:1.5rem;border-top:1px solid var(--border);">
            <h3 style="font-size:.9rem;font-weight:600;color:var(--text-muted);margin-bottom:12px;">Related Content</h3>
            <div style="display:flex;flex-direction:column;gap:8px;">
                \(html)
            </div>
        </div>
        """

        let response = Response(status: .ok)
        response.headers.contentType = .html
        response.body = .init(string: wrapper)
        return response
    }

    private func escapeHTML(_ s: String) -> String {
        s.replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
    }
}
