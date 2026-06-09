import Fluent
import Vapor

final class CertificateModel: Model, Content, @unchecked Sendable {
    static let schema = "certificates"

    @ID(key: .id) var id: UUID?
    @Field(key: "user_id") var userID: UUID
    @Field(key: "type") var type: String
    @OptionalField(key: "course_slug") var courseSlug: String?
    @OptionalField(key: "track_slug") var trackSlug: String?
    @Field(key: "title") var title: String
    @Field(key: "recipient_name") var recipientName: String
    @Timestamp(key: "earned_at", on: .create) var earnedAt: Date?

    init() {}

    init(userID: UUID, type: String, courseSlug: String? = nil, trackSlug: String? = nil, title: String, recipientName: String) {
        self.id = UUID()
        self.userID = userID
        self.type = type
        self.courseSlug = courseSlug
        self.trackSlug = trackSlug
        self.title = title
        self.recipientName = recipientName
    }
}
