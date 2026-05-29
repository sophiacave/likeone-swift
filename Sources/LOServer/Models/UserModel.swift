import Fluent
import Vapor
import LOCore

final class UserModel: Model, Content, @unchecked Sendable {
    static let schema = "users"

    @ID(key: .id) var id: UUID?
    @Field(key: "email") var email: String
    @OptionalField(key: "name") var name: String?
    @OptionalField(key: "avatar_url") var avatarURL: String?
    @Field(key: "provider") var provider: String
    @OptionalField(key: "stripe_customer_id") var stripeCustomerID: String?
    @Field(key: "subscription") var subscription: String
    @Timestamp(key: "created_at", on: .create) var createdAt: Date?

    init() {}

    init(from user: User) {
        self.id = user.id
        self.email = user.email
        self.name = user.name
        self.avatarURL = user.avatarURL
        self.provider = user.provider.rawValue
        self.stripeCustomerID = user.stripeCustomerID
        self.subscription = user.subscription.rawValue
    }

    func toUser() -> User {
        User(
            id: id ?? UUID(),
            email: email,
            name: name,
            avatarURL: avatarURL,
            provider: AuthProvider(rawValue: provider) ?? .apple,
            stripeCustomerID: stripeCustomerID,
            subscription: SubscriptionTier(rawValue: subscription) ?? .free,
            createdAt: createdAt ?? Date()
        )
    }
}
