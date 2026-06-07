import Vapor
import LOContent
import LOCore

struct RSSController: RouteCollection {
    let blog: BlogProvider

    private static let baseURL = "https://likeone.ai"
    private static let feedTitle = "Like One Blog"
    private static let feedDescription = "Insights on AI agents, automation, accessibility, and building in public from Like One."
    private static let feedLanguage = "en-us"

    func boot(routes: RoutesBuilder) throws {
        routes.get("rss.xml", use: feed)
        routes.get("feed.xml", use: feed)
        routes.get("feed", use: feed)
    }

    @Sendable
    func feed(req: Request) async throws -> Response {
        let posts = blog.allPosts()
        let context = RSSContext(
            title: Self.feedTitle,
            link: Self.baseURL,
            feedURL: "\(Self.baseURL)/rss.xml",
            description: Self.feedDescription,
            language: Self.feedLanguage,
            lastBuildDate: Self.rfc822(Date()),
            items: posts.map { post in
                RSSItemContext(
                    title: post.title,
                    link: "\(Self.baseURL)/blog/\(post.slug)/",
                    guid: "\(Self.baseURL)/blog/\(post.slug)/",
                    description: post.description,
                    author: post.author,
                    categories: post.tags,
                    pubDate: Self.rfc822(post.publishedAt)
                )
            }
        )

        let xml = Self.renderXML(context)

        let response = Response(status: .ok)
        response.headers.contentType = HTTPMediaType(type: "application", subType: "rss+xml", parameters: ["charset": "utf-8"])
        response.body = .init(string: xml)
        return response
    }

    // MARK: - XML rendering

    private static func renderXML(_ ctx: RSSContext) -> String {
        var xml = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
        xml += "<rss version=\"2.0\" xmlns:atom=\"http://www.w3.org/2005/Atom\" xmlns:content=\"http://purl.org/rss/1.0/modules/content/\">\n"
        xml += "  <channel>\n"
        xml += "    <title>\(escape(ctx.title))</title>\n"
        xml += "    <link>\(escape(ctx.link))</link>\n"
        xml += "    <atom:link href=\"\(escape(ctx.feedURL))\" rel=\"self\" type=\"application/rss+xml\" />\n"
        xml += "    <description>\(escape(ctx.description))</description>\n"
        xml += "    <language>\(escape(ctx.language))</language>\n"
        xml += "    <lastBuildDate>\(ctx.lastBuildDate)</lastBuildDate>\n"
        xml += "    <generator>LOServer/Vapor</generator>\n"

        for item in ctx.items {
            xml += "    <item>\n"
            xml += "      <title>\(escape(item.title))</title>\n"
            xml += "      <link>\(escape(item.link))</link>\n"
            xml += "      <guid isPermaLink=\"true\">\(escape(item.guid))</guid>\n"
            xml += "      <description>\(escape(item.description))</description>\n"
            xml += "      <dc:creator xmlns:dc=\"http://purl.org/dc/elements/1.1/\">\(escape(item.author))</dc:creator>\n"
            for cat in item.categories {
                xml += "      <category>\(escape(cat))</category>\n"
            }
            xml += "      <pubDate>\(item.pubDate)</pubDate>\n"
            xml += "    </item>\n"
        }

        xml += "  </channel>\n"
        xml += "</rss>"
        return xml
    }

    private static func escape(_ s: String) -> String {
        s.replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&apos;")
    }

    private static func rfc822(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "GMT")
        formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss 'GMT'"
        return formatter.string(from: date)
    }
}

struct RSSContext: Content {
    let title: String
    let link: String
    let feedURL: String
    let description: String
    let language: String
    let lastBuildDate: String
    let items: [RSSItemContext]
}

struct RSSItemContext: Content {
    let title: String
    let link: String
    let guid: String
    let description: String
    let author: String
    let categories: [String]
    let pubDate: String
}
