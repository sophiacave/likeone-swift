import Foundation
import LOCore

// MARK: - Raw JSON Models (match lyra-app/content/academy/courses.json)

private struct RawCourseData: Codable {
    let tiers: [RawTier]
}

private struct RawTier: Codable {
    let name: String
    let slug: String
    let emoji: String
    let description: String
    let courses: [RawCourse]
}

private struct RawCourse: Codable {
    let slug: String
    let title: String
    let emoji: String
    let description: String
    let tier: String
    let audience: [String]
    let status: String
}

// MARK: - Tier to Level mapping

private func tierToLevel(_ tier: String) -> Level {
    switch tier {
    case "beginner": .awareness
    case "intermediate": .collaboration
    case "advanced": .orchestration
    default: .awareness
    }
}

// MARK: - Course Provider

public struct CourseProvider: Sendable {
    private let courses: [Course]

    public init() {
        self.courses = Self.loadCourses()
    }

    public func allCourses() -> [Course] { courses }

    public func course(slug: String) -> Course? {
        courses.first { $0.slug == slug }
    }

    public func courses(forTier tier: String) -> [Course] {
        let level = tierToLevel(tier)
        return courses.filter { $0.level == level }
    }

    public var tierSummary: [(name: String, emoji: String, count: Int)] {
        [
            ("Beginner", "\u{1F331}", courses(forTier: "beginner").count),
            ("Intermediate", "\u{1F527}", courses(forTier: "intermediate").count),
            ("Advanced", "\u{1F680}", courses(forTier: "advanced").count),
        ]
    }

    private static func loadCourses() -> [Course] {
        // Try loading from embedded JSON data
        guard let url = Bundle.module.url(forResource: "courses", withExtension: "json", subdirectory: "Data"),
              let data = try? Data(contentsOf: url),
              let raw = try? JSONDecoder().decode(RawCourseData.self, from: data)
        else {
            // Fallback: return level stubs
            return Level.allCases.map { level in
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

        var order = 0
        var courses: [Course] = []
        for tier in raw.tiers {
            for rawCourse in tier.courses {
                courses.append(Course(
                    slug: rawCourse.slug,
                    title: rawCourse.title,
                    description: rawCourse.description,
                    level: tierToLevel(rawCourse.tier),
                    lessonCount: 10, // default until lesson data loaded
                    emoji: rawCourse.emoji,
                    order: order
                ))
                order += 1
            }
        }
        return courses
    }
}

// MARK: - Raw Blog JSON Models

private struct RawBlogData: Codable {
    let posts: [RawBlogPost]
}

private struct RawBlogPost: Codable {
    let slug: String
    let title: String
    let description: String
    let author: String
    let date: String
    let category: String
    let tags: [String]
    let image: String
    let content: String
}

// MARK: - Blog Provider

public struct BlogProvider: Sendable {
    private let posts: [BlogPost]

    public init() {
        self.posts = Self.loadPosts()
    }

    public func allPosts() -> [BlogPost] { posts }

    public func post(slug: String) -> BlogPost? {
        posts.first { $0.slug == slug }
    }

    public func posts(tagged tag: String) -> [BlogPost] {
        posts.filter { $0.tags.contains(tag) }
    }

    public var tags: [String] {
        Array(Set(posts.flatMap { $0.tags })).sorted()
    }

    private static func loadPosts() -> [BlogPost] {
        guard let url = Bundle.module.url(forResource: "blogs", withExtension: "json", subdirectory: "Data"),
              let data = try? Data(contentsOf: url),
              let raw = try? JSONDecoder().decode(RawBlogData.self, from: data)
        else { return [] }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        return raw.posts.compactMap { post in
            BlogPost(
                slug: post.slug,
                title: post.title,
                description: post.description,
                content: post.content,
                author: post.author,
                publishedAt: formatter.date(from: post.date) ?? Date(),
                tags: post.tags
            )
        }
    }
}

// MARK: - Raw Product JSON Models

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

// MARK: - Product Catalog

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
