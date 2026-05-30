import Vapor
import LOContent
import LOCore

struct SEOController: RouteCollection {
    let courses: CourseProvider
    let blog: BlogProvider
    let tracks: TrackProvider
    let lessons: LessonProvider

    func boot(routes: RoutesBuilder) throws {
        routes.get("sitemap.xml", use: sitemap)
        routes.get("robots.txt", use: robots)
    }

    @Sendable
    func sitemap(req: Request) async throws -> Response {
        let baseURL = "https://likeone.ai"
        var xml = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
        xml += "<urlset xmlns=\"http://www.sitemaps.org/schemas/sitemap/0.9\">\n"

        // Static pages
        let staticPages: [(String, String, String)] = [
            ("/", "weekly", "1.0"),
            ("/academy", "weekly", "0.9"),
            ("/tracks", "weekly", "0.9"),
            ("/blog", "weekly", "0.8"),
            ("/about", "monthly", "0.7"),
            ("/pricing", "monthly", "0.7"),
            ("/foundation", "monthly", "0.7"),
            ("/consulting", "monthly", "0.7"),
            ("/privacy", "monthly", "0.3"),
            ("/terms", "monthly", "0.3"),
            ("/signin", "monthly", "0.3"),
            ("/search", "monthly", "0.5"),
        ]

        for (path, freq, priority) in staticPages {
            xml += "  <url>\n"
            xml += "    <loc>\(baseURL)\(path)</loc>\n"
            xml += "    <changefreq>\(freq)</changefreq>\n"
            xml += "    <priority>\(priority)</priority>\n"
            xml += "  </url>\n"
        }

        // Courses
        for course in courses.allCourses() {
            xml += "  <url>\n"
            xml += "    <loc>\(baseURL)/academy/\(course.slug)</loc>\n"
            xml += "    <changefreq>weekly</changefreq>\n"
            xml += "    <priority>0.8</priority>\n"
            xml += "  </url>\n"

            // Individual lessons
            for lesson in lessons.lessons(forCourse: course.slug) {
                xml += "  <url>\n"
                xml += "    <loc>\(baseURL)/academy/\(course.slug)/\(lesson.slug)</loc>\n"
                xml += "    <changefreq>monthly</changefreq>\n"
                xml += "    <priority>0.6</priority>\n"
                xml += "  </url>\n"
            }
        }

        // Tracks
        for track in tracks.allTracks() {
            xml += "  <url>\n"
            xml += "    <loc>\(baseURL)/tracks/\(track.slug)</loc>\n"
            xml += "    <changefreq>weekly</changefreq>\n"
            xml += "    <priority>0.8</priority>\n"
            xml += "  </url>\n"
        }

        // Blog posts
        for post in blog.allPosts() {
            xml += "  <url>\n"
            xml += "    <loc>\(baseURL)/blog/\(post.slug)</loc>\n"
            xml += "    <changefreq>monthly</changefreq>\n"
            xml += "    <priority>0.7</priority>\n"
            xml += "  </url>\n"
        }

        xml += "</urlset>"

        let response = Response(status: .ok)
        response.headers.contentType = HTTPMediaType(type: "application", subType: "xml")
        response.body = .init(string: xml)
        return response
    }

    @Sendable
    func robots(req: Request) async throws -> Response {
        let txt = """
        User-agent: *
        Allow: /
        Disallow: /api/
        Disallow: /account/

        # AI Search Crawlers — ALLOW for GEO visibility
        User-agent: ChatGPT-User
        Allow: /

        User-agent: OAI-SearchBot
        Allow: /

        User-agent: PerplexityBot
        Allow: /

        User-agent: Claude-SearchBot
        Allow: /

        User-agent: Applebot-Extended
        Allow: /

        User-agent: cohere-ai
        Allow: /

        # Training crawlers — allow for visibility
        User-agent: GPTBot
        Allow: /

        User-agent: ClaudeBot
        Allow: /

        User-agent: Google-Extended
        Allow: /

        # Block hostile crawlers
        User-agent: Bytespider
        Disallow: /

        User-agent: Amazonbot
        Disallow: /

        Sitemap: https://likeone.ai/sitemap.xml
        """

        let response = Response(status: .ok)
        response.headers.contentType = HTTPMediaType(type: "text", subType: "plain")
        response.body = .init(string: txt)
        return response
    }
}
