import Foundation

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
