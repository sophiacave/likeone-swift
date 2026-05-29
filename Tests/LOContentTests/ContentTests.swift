import Testing
import LOContent
import LOCore

@Suite("LOContent")
struct ContentTests {
    @Test("CourseProvider loads 52 courses from embedded JSON")
    func courseCount() {
        let provider = CourseProvider()
        let courses = provider.allCourses()
        #expect(courses.count == 52, "Expected 52 courses, got \(courses.count)")
    }

    @Test("First course is Claude for Beginners")
    func firstCourse() {
        let provider = CourseProvider()
        let courses = provider.allCourses()
        #expect(courses.first?.slug == "claude-for-beginners")
        #expect(courses.first?.title == "Claude for Beginners")
    }

    @Test("Course lookup by slug works")
    func courseLookup() {
        let provider = CourseProvider()
        let course = provider.course(slug: "rag-vector-search")
        #expect(course != nil)
        #expect(course?.title == "RAG & Vector Search")
    }

    @Test("All courses have non-empty fields")
    func courseFieldsValid() {
        let provider = CourseProvider()
        for course in provider.allCourses() {
            #expect(!course.slug.isEmpty, "Course has empty slug")
            #expect(!course.title.isEmpty, "Course has empty title")
            #expect(!course.description.isEmpty, "Course has empty description")
            #expect(!course.emoji.isEmpty, "Course has empty emoji")
        }
    }

    @Test("Tier summary covers all courses")
    func tierSummary() {
        let provider = CourseProvider()
        let summary = provider.tierSummary
        let total = summary.reduce(0) { $0 + $1.count }
        #expect(total == 52)
    }
}
