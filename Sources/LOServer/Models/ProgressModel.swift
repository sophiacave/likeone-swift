import Fluent
import Vapor

final class ProgressModel: Model, Content, @unchecked Sendable {
    static let schema = "progress"

    @ID(key: .id) var id: UUID?
    @Field(key: "user_id") var userID: UUID
    @Field(key: "course_slug") var courseSlug: String
    @Field(key: "lesson_slug") var lessonSlug: String
    @Timestamp(key: "completed_at", on: .create) var completedAt: Date?

    init() {}

    init(userID: UUID, courseSlug: String, lessonSlug: String) {
        self.id = UUID()
        self.userID = userID
        self.courseSlug = courseSlug
        self.lessonSlug = lessonSlug
    }
}
