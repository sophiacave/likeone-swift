import Fluent
import Vapor

final class SubscriberModel: Model, Content, @unchecked Sendable {
    static let schema = "subscribers"

    @ID(key: .id) var id: UUID?
    @Field(key: "email") var email: String
    @OptionalField(key: "name") var name: String?
    @Field(key: "source_page") var sourcePage: String
    @Field(key: "unsubscribe_token") var unsubscribeToken: String
    @Field(key: "active") var active: Bool
    @OptionalField(key: "interests") var interests: String?
    @OptionalField(key: "frequency") var frequency: String?
    @Timestamp(key: "created_at", on: .create) var createdAt: Date?

    init() {}

    init(email: String, name: String? = nil, sourcePage: String = "/", interests: String? = nil) {
        self.id = UUID()
        self.email = email
        self.name = name
        self.sourcePage = sourcePage
        self.unsubscribeToken = UUID().uuidString
        self.active = true
        self.interests = interests
        self.frequency = "weekly"
    }
}
