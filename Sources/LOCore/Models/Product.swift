import Foundation

public struct Product: Codable, Identifiable, Sendable {
    public let id: UUID
    public let slug: String
    public let name: String
    public let description: String
    public let stripeProductID: String?
    public let stripePriceID: String?
    public let price: Decimal?
    public let emoji: String

    public init(
        id: UUID = UUID(),
        slug: String,
        name: String,
        description: String,
        stripeProductID: String? = nil,
        stripePriceID: String? = nil,
        price: Decimal? = nil,
        emoji: String = ""
    ) {
        self.id = id
        self.slug = slug
        self.name = name
        self.description = description
        self.stripeProductID = stripeProductID
        self.stripePriceID = stripePriceID
        self.price = price
        self.emoji = emoji
    }
}
