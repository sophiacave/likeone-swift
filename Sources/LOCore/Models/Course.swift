import Foundation

public struct Course: Codable, Identifiable, Sendable, Hashable {
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

    public var tierName: String {
        switch self {
        case .awareness, .tools, .integration: "Beginner"
        case .collaboration, .automation: "Intermediate"
        case .orchestration, .convergence: "Advanced"
        }
    }

    public var emoji: String {
        switch self {
        case .awareness: "\u{1F441}"
        case .tools: "\u{1F527}"
        case .integration: "\u{1F517}"
        case .collaboration: "\u{1F91D}"
        case .automation: "\u{1F680}"
        case .orchestration: "\u{1F9E0}"
        case .convergence: "\u{2728}"
        }
    }
}
