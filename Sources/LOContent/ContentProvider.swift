import Foundation
import LOCore

// MARK: - Course Provider

public struct CourseProvider: Sendable {
    public init() {}

    public func allCourses() -> [Course] {
        // TODO: load from JSON data files
        // for now, return the 7 level headers
        Level.allCases.map { level in
            Course(
                slug: "level-\(level.rawValue)-\(level.name.lowercased())",
                title: "Level \(level.rawValue): \(level.name)",
                description: "Master \(level.name.lowercased()) in your AI journey.",
                level: level,
                lessonCount: 10,
                emoji: level.emoji,
                order: level.rawValue
            )
        }
    }

    public func course(slug: String) -> Course? {
        allCourses().first { $0.slug == slug }
    }
}

// MARK: - Blog Provider

public struct BlogProvider: Sendable {
    public init() {}

    public func allPosts() -> [BlogPost] {
        // TODO: load from markdown files in Resources/Content/blog/
        []
    }

    public func post(slug: String) -> BlogPost? {
        allPosts().first { $0.slug == slug }
    }
}

// MARK: - Product Catalog

public struct ProductCatalog: Sendable {
    public init() {}

    public func allProducts() -> [Product] {
        // TODO: load from data + Stripe product IDs
        []
    }

    public func product(slug: String) -> Product? {
        allProducts().first { $0.slug == slug }
    }
}
