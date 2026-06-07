import Vapor
import Fluent
import LOBrain
import LOContent

/// Brain-curated weekly digest (Phase 5 — Living AI App)
/// Picks top content for each subscriber based on their interests.
struct DigestService {
    let brain: LocalBrainClient
    let blog: BlogProvider
    let client: Client

    /// Generate a personalized digest for a subscriber
    func generateDigest(for subscriber: SubscriberModel) async -> [DigestItem] {
        let query = subscriber.interests ?? "AI education agents automation"
        guard brain.isAvailable else { return defaultDigest() }

        let results = (try? await brain.contentSearch(query: query, limit: 8)) ?? []
        var items: [DigestItem] = []
        var seenSlugs: Set<String> = []

        for r in results where r.collection == "blog_content" || r.collection == "blog_posts" {
            var slug = r.collection == "blog_content" ? String(r.docID.dropFirst(5)) : ""
            if r.collection == "blog_content" {
                if let i = slug.lastIndex(of: "_"), let _ = Int(slug[slug.index(after: i)...]) {
                    slug = String(slug[..<i])
                }
            }

            if let post = (r.collection == "blog_content")
                ? blog.allPosts().first(where: { $0.slug == slug })
                : blog.allPosts().first(where: { r.docID.dropFirst(5).lowercased().contains($0.slug.replacingOccurrences(of: "-", with: "_")) }) {
                guard !seenSlugs.contains(post.slug) else { continue }
                seenSlugs.insert(post.slug)
                items.append(DigestItem(
                    title: post.title,
                    url: "https://likeone.ai/blog/\(post.slug)/",
                    description: post.description
                ))
                if items.count >= 3 { break }
            }
        }

        return items.isEmpty ? defaultDigest() : items
    }

    /// Fallback: latest 3 posts
    private func defaultDigest() -> [DigestItem] {
        blog.allPosts().prefix(3).map { post in
            DigestItem(
                title: post.title,
                url: "https://likeone.ai/blog/\(post.slug)/",
                description: post.description
            )
        }
    }

    /// Send digest email to a subscriber via Resend
    func sendDigest(to subscriber: SubscriberModel, items: [DigestItem], client: Client) async {
        guard subscriber.active else { return }

        let articlesHTML = items.map { item in
            """
            <tr>
                <td style="padding:12px 0;border-bottom:1px solid #2d2d3d;">
                    <a href="\(item.url)?utm_source=digest&utm_medium=email" style="color:#c084fc;font-weight:600;text-decoration:none;font-size:16px;">\(item.title)</a>
                    <p style="color:#9ca3af;margin:4px 0 0;font-size:14px;">\(item.description)</p>
                </td>
            </tr>
            """
        }.joined()

        let html = """
        <div style="max-width:600px;margin:0 auto;background:#0f0f14;color:#e5e5e5;font-family:system-ui,sans-serif;padding:32px;">
            <h1 style="color:#c084fc;font-size:20px;margin-bottom:4px;">Your Weekly Brain Picks</h1>
            <p style="color:#6b7280;font-size:14px;margin-bottom:24px;">Curated by the Like One brain, just for you.</p>
            <table style="width:100%;border-collapse:collapse;">\(articlesHTML)</table>
            <p style="color:#6b7280;font-size:12px;margin-top:24px;">
                <a href="https://likeone.ai/api/unsubscribe?token=\(subscriber.unsubscribeToken)" style="color:#6b7280;">Unsubscribe</a>
            </p>
        </div>
        """

        let resend = ResendService(client: client)
        await resend.sendEmail(
            to: subscriber.email,
            subject: "Your weekly AI picks from Like One",
            html: html
        )
    }
}

struct DigestItem {
    let title: String
    let url: String
    let description: String
}
