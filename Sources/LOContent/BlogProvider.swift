import Foundation
import LOCore

private struct RawBlogData: Codable {
    let posts: [RawBlogPost]
}

private struct RawBlogPost: Codable {
    let slug: String
    let title: String
    let description: String
    let author: String
    let date: String
    let category: String
    let tags: [String]
    let image: String
    let content: String
}

public struct BlogProvider: Sendable {
    private let posts: [BlogPost]

    public init() {
        self.posts = Self.loadPosts()
    }

    public func allPosts() -> [BlogPost] { posts }

    public func post(slug: String) -> BlogPost? {
        posts.first { $0.slug == slug }
    }

    public func posts(tagged tag: String) -> [BlogPost] {
        posts.filter { $0.tags.contains(tag) }
    }

    public func relatedPosts(to post: BlogPost, limit: Int = 3) -> [BlogPost] {
        let postTags = Set(post.tags)
        return posts
            .filter { $0.slug != post.slug }
            .sorted { a, b in
                Set(a.tags).intersection(postTags).count > Set(b.tags).intersection(postTags).count
            }
            .prefix(limit)
            .map { $0 }
    }

    public var tags: [String] {
        Array(Set(posts.flatMap { $0.tags })).sorted()
    }

    private static func loadPosts() -> [BlogPost] {
        guard let url = Bundle.module.url(forResource: "blogs", withExtension: "json", subdirectory: "Data"),
              let data = try? Data(contentsOf: url),
              let raw = try? JSONDecoder().decode(RawBlogData.self, from: data)
        else { return [] }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        return raw.posts.compactMap { post in
            BlogPost(
                slug: post.slug,
                title: post.title,
                description: post.description,
                content: post.content,
                author: post.author,
                publishedAt: formatter.date(from: post.date) ?? Date(),
                tags: post.tags,
                image: post.image
            )
        }
    }
}
