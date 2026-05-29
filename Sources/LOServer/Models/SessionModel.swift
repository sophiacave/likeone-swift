import Fluent
import Vapor

final class SessionModel: Model, Content, @unchecked Sendable {
    static let schema = "sessions"

    @ID(key: .id) var id: UUID?
    @Field(key: "user_id") var userID: UUID
    @Field(key: "token") var token: String
    @Timestamp(key: "created_at", on: .create) var createdAt: Date?
    @Field(key: "expires_at") var expiresAt: Date

    init() {}

    init(userID: UUID, token: String, expiresIn: TimeInterval = 30 * 24 * 3600) {
        self.id = UUID()
        self.userID = userID
        self.token = token
        self.expiresAt = Date().addingTimeInterval(expiresIn)
    }

    var isExpired: Bool { Date() > expiresAt }
}
