import AppIntents
import LOContent

/// "Hey Siri, search Like One for Claude courses"
struct SearchCoursesIntent: AppIntent {
    static let title: LocalizedStringResource = "Search Courses"
    static let description = IntentDescription("Search Like One Academy courses by topic")
    static let openAppWhenRun = true

    @Parameter(title: "Search query")
    var query: String

    func perform() async throws -> some IntentResult & ProvidesDialog & ReturnsValue<[CourseEntity]> {
        let provider = CourseProvider()
        let lessonProvider = LessonProvider()
        let q = query.lowercased()

        let matches = provider.allCourses()
            .filter { $0.title.lowercased().contains(q) || $0.description.lowercased().contains(q) }
            .prefix(3)
            .map { CourseEntity(from: $0, lessonCount: lessonProvider.lessonCount(forCourse: $0.slug)) }

        if matches.isEmpty {
            return .result(
                value: [],
                dialog: "I couldn't find any courses matching \"\(query)\". Try a different search term."
            )
        }

        let names = matches.map(\.title).joined(separator: ", ")
        return .result(
            value: Array(matches),
            dialog: "I found \(matches.count) course\(matches.count == 1 ? "" : "s"): \(names)"
        )
    }
}
