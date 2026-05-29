import Foundation

public struct Lesson: Codable, Identifiable, Sendable {
    public let id: UUID
    public let slug: String
    public let courseSlug: String
    public let title: String
    public let content: String
    public let order: Int
    public let tier: SubscriptionTier

    public init(
        id: UUID = UUID(),
        slug: String,
        courseSlug: String,
        title: String,
        content: String,
        order: Int,
        tier: SubscriptionTier = .free
    ) {
        self.id = id
        self.slug = slug
        self.courseSlug = courseSlug
        self.title = title
        self.content = content
        self.order = order
        self.tier = tier
    }
}
