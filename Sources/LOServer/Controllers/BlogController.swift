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

    @Sendable
    func detail(req: Request) async throws -> View {
        guard let slug = req.parameters.get("slug"),
              let post = blog.post(slug: slug) else {
            throw Abort(.notFound, reason: "Blog post not found")
        }
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
        return try await req.view.render("blog-post", context)
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
