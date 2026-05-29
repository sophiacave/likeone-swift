import Foundation
import LOCore

private struct LessonIndex: Codable {
    let course_slug: String
    let lesson_count: Int
    let lessons: [LessonMeta]
}

private struct LessonMeta: Codable {
    let slug: String
    let title: String
    let order: Int
    let free: Bool
    let content_length: Int
}

public struct LessonProvider: Sendable {
    private let index: [String: [LessonSummary]]

    public init() {
        self.index = Self.loadIndex()
    }

    public func lessons(forCourse courseSlug: String) -> [LessonSummary] {
        index[courseSlug] ?? []
    }

    public func lesson(courseSlug: String, lessonSlug: String) -> LessonSummary? {
        index[courseSlug]?.first { $0.slug == lessonSlug }
    }

    public func lessonCount(forCourse courseSlug: String) -> Int {
        index[courseSlug]?.count ?? 0
    }

    private static func loadIndex() -> [String: [LessonSummary]] {
        guard let url = Bundle.module.url(forResource: "lessons-index", withExtension: "json", subdirectory: "Data"),
              let data = try? Data(contentsOf: url),
              let raw = try? JSONDecoder().decode([String: LessonIndex].self, from: data)
        else { return [:] }

        var result: [String: [LessonSummary]] = [:]
        for (courseSlug, courseData) in raw {
            result[courseSlug] = courseData.lessons.map { meta in
                LessonSummary(
                    slug: meta.slug,
                    courseSlug: courseSlug,
                    title: meta.title,
                    order: meta.order,
                    isFree: meta.free
                )
            }
        }
        return result
    }
}

public struct LessonSummary: Codable, Sendable {
    public let slug: String
    public let courseSlug: String
    public let title: String
    public let order: Int
    public let isFree: Bool
}
