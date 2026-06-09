import AppIntents
import LOCore
import LOContent

/// Makes courses discoverable in Spotlight and Siri.
struct CourseEntity: AppEntity {
    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Course")
    static let defaultQuery = CourseQuery()

    var id: String
    var title: String
    var courseDescription: String
    var tier: String
    var lessonCount: Int

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(title)",
            subtitle: "\(lessonCount) lessons \u{00B7} \(tier)",
            image: .init(systemName: "book.fill")
        )
    }

    init(from course: Course, lessonCount: Int) {
        self.id = course.slug
        self.title = course.title
        self.courseDescription = course.description
        self.tier = course.tier.rawValue
        self.lessonCount = lessonCount
    }
}

struct CourseQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [CourseEntity] {
        let courseProvider = CourseProvider()
        let lessonProvider = LessonProvider()
        return courseProvider.allCourses()
            .filter { identifiers.contains($0.slug) }
            .map { CourseEntity(from: $0, lessonCount: lessonProvider.lessonCount(forCourse: $0.slug)) }
    }

    func suggestedEntities() async throws -> [CourseEntity] {
        let courseProvider = CourseProvider()
        let lessonProvider = LessonProvider()
        return courseProvider.allCourses().prefix(10).map {
            CourseEntity(from: $0, lessonCount: lessonProvider.lessonCount(forCourse: $0.slug))
        }
    }
}

extension CourseQuery: EntityStringQuery {
    func entities(matching string: String) async throws -> [CourseEntity] {
        let courseProvider = CourseProvider()
        let lessonProvider = LessonProvider()
        let q = string.lowercased()
        return courseProvider.allCourses()
            .filter { $0.title.lowercased().contains(q) || $0.description.lowercased().contains(q) }
            .prefix(5)
            .map { CourseEntity(from: $0, lessonCount: lessonProvider.lessonCount(forCourse: $0.slug)) }
    }
}
