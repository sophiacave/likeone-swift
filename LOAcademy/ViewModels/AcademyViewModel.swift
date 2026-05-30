import SwiftUI
import LOCore
import LOContent

@MainActor
final class AcademyViewModel: ObservableObject {
    @Published var courses: [Course] = []
    @Published var tracks: [LearningTrack] = []
    @Published var searchQuery = ""

    private let courseProvider = CourseProvider()
    private let lessonProvider = LessonProvider()
    private let trackProvider = TrackProvider()

    init() {
        courses = courseProvider.allCourses()
        tracks = trackProvider.allTracks()
    }

    var filteredCourses: [Course] {
        if searchQuery.isEmpty { return courses }
        let q = searchQuery.lowercased()
        return courses.filter {
            $0.title.lowercased().contains(q) ||
            $0.description.lowercased().contains(q)
        }
    }

    func lessons(for courseSlug: String) -> [LessonSummary] {
        lessonProvider.lessons(forCourse: courseSlug)
    }

    func lessonCount(for courseSlug: String) -> Int {
        lessonProvider.lessonCount(forCourse: courseSlug)
    }

    func track(slug: String) -> LearningTrack? {
        trackProvider.track(bySlug: slug)
    }

    func isLessonFree(_ lesson: LessonSummary) -> Bool {
        lesson.order <= 3
    }
}
