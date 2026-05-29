import Foundation

public struct LearningTrack: Codable, Identifiable, Sendable {
    public let id: UUID
    public let slug: String
    public let title: String
    public let description: String
    public let emoji: String
    public let courses: [String]
    public let estimatedHours: Int
    public let difficulty: String
    public let badgeColor: String

    public init(
        id: UUID = UUID(),
        slug: String,
        title: String,
        description: String,
        emoji: String,
        courses: [String],
        estimatedHours: Int,
        difficulty: String,
        badgeColor: String
    ) {
        self.id = id
        self.slug = slug
        self.title = title
        self.description = description
        self.emoji = emoji
        self.courses = courses
        self.estimatedHours = estimatedHours
        self.difficulty = difficulty
        self.badgeColor = badgeColor
    }
}

public enum CertType: String, Codable, Sendable {
    case course
    case track
}

public struct Certificate: Codable, Identifiable, Sendable {
    public let id: UUID
    public let userId: UUID
    public let type: CertType
    public let courseSlug: String?
    public let trackSlug: String?
    public let title: String
    public let earnedAt: Date
    public let recipientName: String

    public var verificationPath: String {
        "/cert/\(id.uuidString.lowercased())"
    }

    public init(
        id: UUID = UUID(),
        userId: UUID,
        type: CertType,
        courseSlug: String? = nil,
        trackSlug: String? = nil,
        title: String,
        earnedAt: Date = Date(),
        recipientName: String
    ) {
        self.id = id
        self.userId = userId
        self.type = type
        self.courseSlug = courseSlug
        self.trackSlug = trackSlug
        self.title = title
        self.earnedAt = earnedAt
        self.recipientName = recipientName
    }
}
