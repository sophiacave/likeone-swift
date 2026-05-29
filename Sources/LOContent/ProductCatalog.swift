import Foundation
import LOCore

private struct RawProductData: Codable {
    let products: [RawProduct]
}

private struct RawProduct: Codable {
    let slug: String
    let name: String
    let description: String
    let stripeProductID: String?
    let stripePriceID: String?
    let price: Double?
    let emoji: String
}

public struct ProductCatalog: Sendable {
    private let products: [Product]

    public init() {
        self.products = Self.loadProducts()
    }

    public func allProducts() -> [Product] { products }

    public func product(slug: String) -> Product? {
        products.first { $0.slug == slug }
    }

    private static func loadProducts() -> [Product] {
        guard let url = Bundle.module.url(forResource: "products", withExtension: "json", subdirectory: "Data"),
              let data = try? Data(contentsOf: url),
              let raw = try? JSONDecoder().decode(RawProductData.self, from: data)
        else { return [] }

        return raw.products.map { p in
            Product(
                slug: p.slug,
                name: p.name,
                description: p.description,
                stripeProductID: p.stripeProductID,
                stripePriceID: p.stripePriceID,
                price: p.price.map { Decimal($0) },
                emoji: p.emoji
            )
        }
    }
}
