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
            )},
            canonicalUrl: "https://likeone.ai/blog/"
        )
        return try await req.view.render("blog", context)
    }

    // Legacy blog URLs from old Next.js site that Google still indexes (~3,400 monthly impressions).
    private static let legacyRedirects: [String: String] = [
        // Batch 2: additional high-impression legacy URLs
        "custom-gpts-vs-claude-projects": "/blog/custom-gpts-vs-claude-projects-which-is-better-2026/",
        "chatgpt-vs-claude-vs-gemini-for-coding": "/blog/chatgpt-vs-claude-vs-gemini-2026/",
        "claude-vs-chatgpt-for-writing-2026": "/blog/chatgpt-vs-claude-vs-gemini-2026/",
        "chatgpt-vs-claude-vs-gemini": "/blog/chatgpt-vs-claude-vs-gemini-2026/",
        "claude-built-in-tools-vs-custom-tools-explained": "/blog/model-context-protocol-mcp-future-of-ai-integration-2026/",
        "make-com-claude-stack-complete-guide": "/blog/the-ai-stack-that-runs-our-company-2026/",
        "how-to-build-ai-agent-no-code-2026": "/blog/how-to-build-ai-agent-that-works-2026/",
        "best-free-ai-courses-2026": "/academy/",
        "how-to-train-ai-to-write-like-you": "/blog/train-ai-on-your-writing-style/",
        "why-your-ai-has-amnesia-how-to-fix-it": "/blog/how-to-give-ai-agent-persistent-memory-2026/",
        "how-to-use-claude-ai-complete-guide": "/academy/claude-for-beginners/what-claude-can-do/",
        "how-to-use-claude-code-complete-guide": "/academy/claude-for-beginners/what-claude-can-do/",
        "build-first-mcp-server-connect-claude-any-api": "/blog/model-context-protocol-mcp-future-of-ai-integration-2026/",
        "what-every-ceo-needs-to-know-about-ai-2026": "/blog/why-businesses-fail-at-ai-implementation-2026/",
        "one-person-agency-playbook": "/blog/autonomous-freelancing-ai-upwork-2026/",
        "best-mcp-servers-claude-2026": "/blog/model-context-protocol-mcp-future-of-ai-integration-2026/",
        "how-to-write-business-plan-with-ai": "/blog/autonomous-freelancing-ai-upwork-2026/",
        "prompt-library-every-team-needs": "/academy/",
        "student-loan-borrower-rights-doge-era-2026": "/blog/",
        "claude-opus-4-vs-gpt-4o-honest-comparison": "/blog/chatgpt-vs-claude-vs-gemini-2026/",
        "how-to-build-second-brain-ai": "/blog/build-personal-ai-assistant-with-memory-2026/",
        "build-ai-first-company-culture": "/blog/why-businesses-fail-at-ai-implementation-2026/",
        "build-custom-ai-assistant-no-code": "/blog/build-personal-ai-assistant-with-memory-2026/",
        "from-ai-curious-to-ai-native": "/academy/",
        "one-person-ai-business": "/blog/autonomous-freelancing-ai-upwork-2026/",
        "prompt-chains-multi-step-ai-workflows": "/blog/how-to-build-ai-agent-that-works-2026/",
        "prompt-engineering-framework": "/academy/advanced-prompt-engineering/01-beyond-basic-prompts/",
        "welcome-to-likeone": "/",
        "revenue-machine-autonomous-ai-business": "/blog/autonomous-freelancing-ai-upwork-2026/",
        "replaced-virtual-assistant-ai-agents": "/blog/ai-agents-replacing-saas-2026/",
        "getting-started-with-claude-ai-beginner-to-power-user": "/academy/claude-for-beginners/what-claude-can-do/",
        "chatgpt-plus-vs-claude-pro-which-worth-20": "/blog/chatgpt-vs-claude-vs-gemini-2026/",
        "building-passive-income-ai-content": "/blog/autonomous-freelancing-ai-upwork-2026/",
        "build-first-ai-workflow-30-minutes": "/blog/the-ai-stack-that-runs-our-company-2026/",
        "ai-for-content-marketing-complete-guide": "/blog/the-ai-stack-that-runs-our-company-2026/",
        "claude-vs-chatgpt-business-automation-2026": "/blog/chatgpt-vs-claude-vs-gemini-2026/",
        // Batch 3: fixed redirects
        "chatgpt-vs-claude-vs-gemini-comparison-2026": "/blog/chatgpt-vs-claude-vs-gemini-2026/",
        "claude-agent-sdk-tutorial-build-first-ai-agent": "/blog/how-to-build-ai-agent-that-works-2026/",
        // Batch 1: original high-impression legacy URLs (deduplicated)
        // "claude-custom-instructions-guide" — REMOVED: now a real blog post
        // "what-are-agentic-loops-explained" — REMOVED: now a real blog post
        // "how-to-use-claude-projects-complete-guide" — REMOVED: now a real blog post
        // "how-to-use-claude-for-data-analysis-2026" — REMOVED: now a real blog post
        "best-ai-tools-2026-ranked": "/blog/chatgpt-vs-claude-vs-gemini-2026/",
        "best-free-ai-automation-courses-2026": "/academy/",
        "ai-automation-tools-compared-2026": "/blog/the-ai-stack-that-runs-our-company-2026/",
        // "train-ai-on-your-writing-style" — REMOVED: now a real blog post
        "ai-solopreneur-tech-stack-under-100": "/blog/the-ai-stack-that-runs-our-company-2026/",
        "ai-survey-analysis-complete-guide": "/blog/how-to-use-claude-for-data-analysis-2026/",
        "ai-feedback-analysis-guide": "/blog/how-to-use-claude-for-data-analysis-2026/",
        "ai-governance-small-teams-practical-guide": "/blog/why-businesses-fail-at-ai-implementation-2026/",
        "ai-governance-small-teams": "/blog/why-businesses-fail-at-ai-implementation-2026/",
        "10-claude-tips-changed-how-i-work": "/academy/claude-for-beginners/what-claude-can-do/",
        "5-workflows-automate-first-small-business": "/blog/the-ai-stack-that-runs-our-company-2026/",
        "academy-is-live-30-courses-free": "/academy/",
        "advanced-claude-techniques-business-analysis": "/academy/claude-for-beginners/custom-instructions/",
        "ai-company-business-plan-2026": "/blog/autonomous-freelancing-ai-upwork-2026/",
        "ai-fluency-new-literacy": "/academy/",
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
        let canonicalUrl = "https://likeone.ai/blog/\(post.slug)/"
        let ogImage: String? = post.image.flatMap { img in
            let path = "Public\(img)"
            return FileManager.default.fileExists(atPath: path) ? "https://likeone.ai\(img)?v=268" : nil
        }
        let isoFormatter = DateFormatter()
        isoFormatter.dateFormat = "yyyy-MM-dd"
        let isoDate = isoFormatter.string(from: post.publishedAt)

        let related = blog.relatedPosts(to: post, limit: 3).map { BlogCardContext(
            slug: $0.slug,
            title: $0.title,
            description: $0.description,
            author: $0.author,
            date: formatDate($0.publishedAt),
            tags: $0.tags
        )}

        let faqContexts = post.faqs?.map { BlogFAQContext(question: $0.question, answer: $0.answer) }

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
            content: post.content,
            canonicalUrl: canonicalUrl,
            ogImage: ogImage,
            ogType: "article",
            ogUrl: canonicalUrl,
            isoDate: isoDate,
            relatedPosts: related,
            faqs: faqContexts
        )
        let buffer = try await req.view.render("blog-post", context).get().data
        var headers = HTTPHeaders()
        headers.contentType = .html
        return Response(status: .ok, headers: headers, body: .init(buffer: buffer))
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
    let canonicalUrl: String
}

struct BlogCardContext: Content {
    let slug: String
    let title: String
    let description: String
    let author: String
    let date: String
    let tags: [String]
}

struct BlogFAQContext: Content {
    let question: String
    let answer: String
}

struct BlogDetailContext: Content {
    let title: String
    let description: String
    let post: BlogCardContext
    let content: String
    let canonicalUrl: String?
    let ogImage: String?
    let ogType: String?
    let ogUrl: String?
    let isoDate: String?
    let relatedPosts: [BlogCardContext]?
    let faqs: [BlogFAQContext]?
}
