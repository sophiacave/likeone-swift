import Vapor
import Leaf
import LOCore
import LOContent

struct BlogController: RouteCollection {
    let blog: BlogProvider

    func boot(routes: RoutesBuilder) throws {
        let blogRoutes = routes.grouped("blog")
        blogRoutes.get(use: index)
        blogRoutes.get(":slug", use: detail)
    }

    @Sendable
    func index(req: Request) async throws -> View {
        let posts = blog.allPosts()
        let context = BlogListContext(
            title: "Blog | Like One",
            description: "Insights on AI agents, automation, accessibility, and building in public.",
            posts: posts.map { BlogCardContext(
                slug: $0.slug,
                title: $0.title,
                description: $0.description,
                author: $0.author,
                date: formatDate($0.publishedAt),
                tags: $0.tags
            )}
        )
        return try await req.view.render("blog", context)
    }

    // Legacy blog URLs from old Next.js site that Google still indexes (~2,300 monthly impressions).
    private static let legacyRedirects: [String: String] = [
        "claude-custom-instructions-guide": "/academy/claude-for-beginners/custom-instructions/",
        "what-are-agentic-loops-explained": "/blog/how-to-build-ai-agent-that-works-2026/",
        "how-to-use-claude-projects-complete-guide": "/academy/claude-for-beginners/what-claude-can-do/",
        "how-to-use-claude-for-data-analysis-2026": "/blog/chatgpt-vs-claude-vs-gemini-2026/",
        "best-ai-tools-2026-ranked": "/blog/chatgpt-vs-claude-vs-gemini-2026/",
        "best-free-ai-automation-courses-2026": "/academy/",
        "ai-automation-tools-compared-2026": "/blog/the-ai-stack-that-runs-our-company-2026/",
        "train-ai-on-your-writing-style": "/blog/how-to-give-ai-agent-persistent-memory-2026/",
        "ai-solopreneur-tech-stack-under-100": "/blog/the-ai-stack-that-runs-our-company-2026/",
        "ai-survey-analysis-complete-guide": "/blog/chatgpt-vs-claude-vs-gemini-2026/",
        "ai-feedback-analysis-guide": "/blog/chatgpt-vs-claude-vs-gemini-2026/",
        "ai-governance-small-teams-practical-guide": "/blog/why-businesses-fail-at-ai-implementation-2026/",
        "ai-governance-small-teams": "/blog/why-businesses-fail-at-ai-implementation-2026/",
        "10-claude-tips-changed-how-i-work": "/academy/claude-for-beginners/what-claude-can-do/",
        "5-workflows-automate-first-small-business": "/blog/the-ai-stack-that-runs-our-company-2026/",
        "academy-is-live-30-courses-free": "/academy/",
        "advanced-claude-techniques-business-analysis": "/academy/claude-for-beginners/custom-instructions/",
        "ai-company-business-plan-2026": "/blog/autonomous-freelancing-ai-upwork-2026/",
        "ai-fluency-new-literacy": "/academy/",
        "ai-for-content-marketing-complete-guide": "/blog/the-ai-stack-that-runs-our-company-2026/",
        "ai-for-freelancers-double-output": "/blog/autonomous-freelancing-ai-upwork-2026/",
        "ai-grant-writing-guide-2026": "/foundation/",
        "ai-meeting-notes-never-take-notes-again": "/blog/the-ai-stack-that-runs-our-company-2026/",
        "ai-powered-email-that-converts": "/blog/the-ai-stack-that-runs-our-company-2026/",
        "ai-readiness-assessment-guide": "/blog/why-businesses-fail-at-ai-implementation-2026/",
        "ai-workflows-that-make-money-2026": "/blog/autonomous-freelancing-ai-upwork-2026/",
        "automate-business-ai-2026-guide": "/blog/the-ai-stack-that-runs-our-company-2026/",
        "automating-client-onboarding-with-ai": "/blog/the-ai-stack-that-runs-our-company-2026/",
        "how-we-used-ai-to-file-501c3-one-day": "/foundation/",
    ]

    @Sendable
    func detail(req: Request) async throws -> Response {
        guard let slug = req.parameters.get("slug") else {
            throw Abort(.notFound, reason: "Blog post not found")
        }

        // Check for legacy redirect first
        if blog.post(slug: slug) == nil {
            if let target = Self.legacyRedirects[slug] {
                return req.redirect(to: target, redirectType: .permanent)
            }
            throw Abort(.notFound, reason: "Blog post not found")
        }

        let post = blog.post(slug: slug)!
        let context = BlogDetailContext(
            title: "\(post.title) | Like One",
            description: post.description,
            post: BlogCardContext(
                slug: post.slug,
                title: post.title,
                description: post.description,
                author: post.author,
                date: formatDate(post.publishedAt),
                tags: post.tags
            ),
            content: post.content
        )
        let view = try await req.view.render("blog-post", context)
        var headers = HTTPHeaders()
        headers.contentType = .html
        return Response(status: .ok, headers: headers, body: .init(buffer: view.data))
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }
}

struct BlogListContext: Content {
    let title: String
    let description: String
    let posts: [BlogCardContext]
}

struct BlogCardContext: Content {
    let slug: String
    let title: String
    let description: String
    let author: String
    let date: String
    let tags: [String]
}

struct BlogDetailContext: Content {
    let title: String
    let description: String
    let post: BlogCardContext
    let content: String
}
