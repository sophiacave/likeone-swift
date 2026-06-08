import Testing
import LOContent
import LOCore

@Suite("LOContent")
struct ContentTests {
    @Test("CourseProvider loads 53 courses from embedded JSON")
    func courseCount() {
        let provider = CourseProvider()
        let courses = provider.allCourses()
        #expect(courses.count == 53, "Expected 53 courses, got \(courses.count)")
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
        #expect(total == 53)
    }

    // MARK: - Blog Provider

    @Test("BlogProvider loads 20 posts from embedded JSON")
    func blogCount() {
        let provider = BlogProvider()
        let posts = provider.allPosts()
        #expect(posts.count >= 30, "Expected at least 30 blog posts, got \(posts.count)")
    }

    @Test("Blog post lookup by slug works")
    func blogLookup() {
        let provider = BlogProvider()
        let post = provider.post(slug: "ai-agent-frameworks-compared-claude-langchain-crewai-2026")
        #expect(post != nil)
        #expect(post?.title.contains("AI Agent Frameworks") == true)
    }

    @Test("All blog posts have non-empty fields")
    func blogFieldsValid() {
        let provider = BlogProvider()
        for post in provider.allPosts() {
            #expect(!post.slug.isEmpty, "Post has empty slug")
            #expect(!post.title.isEmpty, "Post has empty title")
            #expect(!post.content.isEmpty, "Post has empty content")
            #expect(!post.author.isEmpty, "Post has empty author")
        }
    }

    @Test("Blog tags are collected correctly")
    func blogTags() {
        let provider = BlogProvider()
        let tags = provider.tags
        #expect(tags.count > 5, "Expected many tags, got \(tags.count)")
    }

    // MARK: - Product Catalog

    @Test("ProductCatalog loads 10 products from embedded JSON")
    func productCount() {
        let catalog = ProductCatalog()
        let products = catalog.allProducts()
        #expect(products.count == 10, "Expected 10 products, got \(products.count)")
    }

    @Test("Product lookup by slug works")
    func productLookup() {
        let catalog = ProductCatalog()
        let product = catalog.product(slug: "academy-pro-monthly")
        #expect(product != nil)
        #expect(product?.stripeProductID == "prod_UCoTPM3jRCrn2I")
    }

    @Test("All products have Stripe product IDs")
    func productStripeIDs() {
        let catalog = ProductCatalog()
        for product in catalog.allProducts() {
            #expect(product.stripeProductID != nil, "\(product.slug) missing Stripe product ID")
        }
    }

    // MARK: - Lesson Provider

    @Test("LessonProvider loads 542 lessons across 53 courses")
    func lessonCount() {
        let provider = LessonProvider()
        let courses = CourseProvider()
        var total = 0
        for course in courses.allCourses() {
            total += provider.lessonCount(forCourse: course.slug)
        }
        #expect(total == 542, "Expected 542 lessons, got \(total)")
    }

    @Test("AI Foundations has 9 lessons")
    func aiFoundationsLessons() {
        let provider = LessonProvider()
        let lessons = provider.lessons(forCourse: "ai-foundations")
        #expect(lessons.count == 9)
        #expect(lessons.first?.title == "What Is a Neuron?")
        #expect(lessons.first?.order == 1)
    }

    @Test("Lesson lookup by slug works")
    func lessonLookup() {
        let provider = LessonProvider()
        let lesson = provider.lesson(courseSlug: "ai-foundations", lessonSlug: "what-is-a-neuron")
        #expect(lesson != nil)
        #expect(lesson?.title == "What Is a Neuron?")
        #expect(lesson?.isFree == true)
    }

    @Test("All lessons have ordered, non-empty titles")
    func lessonFieldsValid() {
        let provider = LessonProvider()
        let courses = CourseProvider()
        for course in courses.allCourses() {
            let lessons = provider.lessons(forCourse: course.slug)
            for lesson in lessons {
                #expect(!lesson.slug.isEmpty, "Lesson has empty slug in \(course.slug)")
                #expect(!lesson.title.isEmpty, "Lesson has empty title in \(course.slug)")
                #expect(lesson.order > 0, "Lesson has invalid order in \(course.slug)")
            }
        }
    }

    @Test("Lessons are sorted by order")
    func lessonsSorted() {
        let provider = LessonProvider()
        let lessons = provider.lessons(forCourse: "advanced-prompt-engineering")
        for i in 1..<lessons.count {
            #expect(lessons[i].order >= lessons[i-1].order,
                    "Lessons not sorted: \(lessons[i-1].title) before \(lessons[i].title)")
        }
    }

    @Test("TrackProvider loads 6 learning tracks")
    func trackCount() {
        let provider = TrackProvider()
        let tracks = provider.allTracks()
        #expect(tracks.count == 6, "Expected 6 tracks, got \(tracks.count)")
    }

    @Test("Track lookup by slug works")
    func trackBySlug() {
        let provider = TrackProvider()
        let track = provider.track(bySlug: "agent-architect")
        #expect(track != nil)
        #expect(track?.title == "Agent Architect")
        #expect(track?.courses.count == 3)
    }
}
