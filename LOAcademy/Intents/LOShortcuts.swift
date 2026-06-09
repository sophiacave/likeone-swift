import AppIntents

/// Registers Like One Academy shortcuts with Siri and Shortcuts app.
struct LOShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: SearchCoursesIntent(),
            phrases: [
                "Search \(.applicationName) courses",
                "Find courses on \(.applicationName)"
            ],
            shortTitle: "Search Courses",
            systemImageName: "magnifyingglass"
        )
        AppShortcut(
            intent: OpenCourseIntent(),
            phrases: [
                "Open \(\.$course) on \(.applicationName)"
            ],
            shortTitle: "Open Course",
            systemImageName: "book.fill"
        )
    }
}
