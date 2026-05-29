import Foundation

// MARK: - User

public struct User: Codable, Identifiable, Sendable {
    public let id: UUID
    public let email: String
    public let name: String?
    public let avatarURL: String?
    public let provider: AuthProvider
    public let stripeCustomerID: String?
    public let subscription: SubscriptionTier
    public let createdAt: Date

    public init(
        id: UUID = UUID(),
        email: String,
        name: String? = nil,
        avatarURL: String? = nil,
        provider: AuthProvider = .apple,
        stripeCustomerID: String? = nil,
        subscription: SubscriptionTier = .free,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.email = email
        self.name = name
        self.avatarURL = avatarURL
        self.provider = provider
        self.stripeCustomerID = stripeCustomerID
        self.subscription = subscription
        self.createdAt = createdAt
    }
}

public enum AuthProvider: String, Codable, Sendable {
    case apple
    case google
    case magicLink = "magic_link"
}

public enum SubscriptionTier: String, Codable, Sendable {
    case free
    case pro
    case founding
}

// MARK: - Course

public struct Course: Codable, Identifiable, Sendable {
    public let id: UUID
    public let slug: String
    public let title: String
    public let description: String
    public let level: Level
    public let tier: SubscriptionTier
    public let lessonCount: Int
    public let emoji: String
    public let order: Int

    public init(
        id: UUID = UUID(),
        slug: String,
        title: String,
        description: String,
        level: Level,
        tier: SubscriptionTier = .free,
        lessonCount: Int,
        emoji: String,
        order: Int
    ) {
        self.id = id
        self.slug = slug
        self.title = title
        self.description = description
        self.level = level
        self.tier = tier
        self.lessonCount = lessonCount
        self.emoji = emoji
        self.order = order
    }
}

public enum Level: Int, Codable, Sendable, CaseIterable {
    case awareness = 0
    case tools = 1
    case integration = 2
    case collaboration = 3
    case automation = 4
    case orchestration = 5
    case convergence = 6

    public var name: String {
        switch self {
        case .awareness: "Awareness"
        case .tools: "Tools"
        case .integration: "Integration"
        case .collaboration: "Collaboration"
        case .automation: "Automation"
        case .orchestration: "Orchestration"
        case .convergence: "Convergence"
        }
    }

    public var emoji: String {
        switch self {
        case .awareness: "\u{1F441}"       // eye
        case .tools: "\u{1F527}"           // wrench
        case .integration: "\u{1F517}"     // link
        case .collaboration: "\u{1F91D}"   // handshake
        case .automation: "\u{1F680}"      // rocket
        case .orchestration: "\u{1F9E0}"   // brain
        case .convergence: "\u{2728}"      // sparkles
        }
    }
}

// MARK: - Lesson

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

// MARK: - Blog

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

// MARK: - Product

public struct Product: Codable, Identifiable, Sendable {
    public let id: UUID
    public let slug: String
    public let name: String
    public let description: String
    public let stripeProductID: String?
    public let stripePriceID: String?
    public let price: Decimal?
    public let emoji: String

    public init(
        id: UUID = UUID(),
        slug: String,
        name: String,
        description: String,
        stripeProductID: String? = nil,
        stripePriceID: String? = nil,
        price: Decimal? = nil,
        emoji: String = ""
    ) {
        self.id = id
        self.slug = slug
        self.name = name
        self.description = description
        self.stripeProductID = stripeProductID
        self.stripePriceID = stripePriceID
        self.price = price
        self.emoji = emoji
    }
}

// MARK: - Progress

public struct LearningProgress: Codable, Sendable {
    public let userID: UUID
    public let courseSlug: String
    public let lessonSlug: String
    public let completedAt: Date

    public init(userID: UUID, courseSlug: String, lessonSlug: String, completedAt: Date = Date()) {
        self.userID = userID
        self.courseSlug = courseSlug
        self.lessonSlug = lessonSlug
        self.completedAt = completedAt
    }
}

// MARK: - Brain

public struct BrainEntry: Codable, Identifiable, Sendable {
    public let id: UUID
    public let key: String
    public let category: String
    public let description: String
    public let value: String
    public let priority: Int
    public let updatedAt: Date

    public init(
        id: UUID = UUID(),
        key: String,
        category: String = "session",
        description: String,
        value: String,
        priority: Int = 5,
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.key = key
        self.category = category
        self.description = description
        self.value = value
        self.priority = priority
        self.updatedAt = updatedAt
    }
}
