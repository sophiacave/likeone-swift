import Foundation

public struct BlogPost: Codable, Identifiable, Sendable {
    public let id: UUID
    public let slug: String
    public let title: String
    public let description: String
    public let content: String
    public let author: String
    public let publishedAt: Date
    public let tags: [String]

    public init(
        id: UUID = UUID(),
        slug: String,
        title: String,
        description: String,
        content: String,
        author: String = "Sophie Cave",
        publishedAt: Date = Date(),
        tags: [String] = []
    ) {
        self.id = id
        self.slug = slug
        self.title = title
        self.description = description
        self.content = content
        self.author = author
        self.publishedAt = publishedAt
        self.tags = tags
    }
}
