import Foundation

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
