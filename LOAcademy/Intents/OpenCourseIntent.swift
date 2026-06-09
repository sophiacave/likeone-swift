import AppIntents

/// "Hey Siri, open the Claude for Beginners course on Like One"
struct OpenCourseIntent: AppIntent {
    static let title: LocalizedStringResource = "Open Course"
    static let description = IntentDescription("Open a specific course in Like One Academy")
    static let openAppWhenRun = true

    @Parameter(title: "Course")
    var course: CourseEntity

    func perform() async throws -> some IntentResult & ProvidesDialog {
        .result(dialog: "Opening \(course.title)")
    }
}
