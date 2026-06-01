import Foundation

public struct BlogFAQ: Codable, Sendable {
    public let question: String
    public let answer: String

    public init(question: String, answer: String) {
        self.question = question
        self.answer = answer
    }
}

public struct BlogPost: Codable, Identifiable, Sendable {
    public let id: UUID
    public let slug: String
    public let title: String
    public let description: String
    public let content: String
    public let author: String
    public let publishedAt: Date
    public let tags: [String]
    public let image: String?
    public let faqs: [BlogFAQ]?

    public init(
        id: UUID = UUID(),
        slug: String,
        title: String,
        description: String,
        content: String,
        author: String = "Sophie Cave",
        publishedAt: Date = Date(),
        tags: [String] = [],
        image: String? = nil,
        faqs: [BlogFAQ]? = nil
    ) {
        self.id = id
        self.slug = slug
        self.title = title
        self.description = description
        self.content = content
        self.author = author
        self.publishedAt = publishedAt
        self.tags = tags
        self.image = image
        self.faqs = faqs
    }
}
