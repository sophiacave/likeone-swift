import Foundation
import LOCore

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

private func tierToLevel(_ tier: String) -> Level {
    switch tier {
    case "beginner": .awareness
    case "intermediate": .collaboration
    case "advanced": .orchestration
    default: .awareness
    }
}

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
        guard let url = Bundle.module.url(forResource: "courses", withExtension: "json", subdirectory: "Data"),
              let data = try? Data(contentsOf: url),
              let raw = try? JSONDecoder().decode(RawCourseData.self, from: data)
        else {
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
                    lessonCount: 10,
                    emoji: rawCourse.emoji,
                    order: order
                ))
                order += 1
            }
        }
        return courses
    }
}
