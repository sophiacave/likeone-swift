import Fluent
import Vapor

final class PageViewModel: Model, Content, @unchecked Sendable {
    static let schema = "page_views"

    @ID(key: .id) var id: UUID?
    @Field(key: "path") var path: String
    @OptionalField(key: "user_id") var userID: UUID?
    @OptionalField(key: "referrer") var referrer: String?
    @OptionalField(key: "user_agent") var userAgent: String?
    @Timestamp(key: "created_at", on: .create) var createdAt: Date?

    init() {}

    init(path: String, userID: UUID? = nil, referrer: String? = nil, userAgent: String? = nil) {
        self.id = UUID()
        self.path = path
        self.userID = userID
        self.referrer = referrer
        self.userAgent = userAgent
    }
}
