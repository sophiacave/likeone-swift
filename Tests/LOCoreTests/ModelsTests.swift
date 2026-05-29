import Testing
import LOCore

@Suite("LOCore Models")
struct ModelsTests {
    @Test("User creates with defaults")
    func userDefaults() {
        let user = User(email: "test@likeone.ai")
        #expect(user.email == "test@likeone.ai")
        #expect(user.provider == .apple)
        #expect(user.subscription == .free)
        #expect(user.name == nil)
    }

    @Test("Course levels have correct names")
    func levelNames() {
        #expect(Level.awareness.name == "Awareness")
        #expect(Level.convergence.name == "Convergence")
        #expect(Level.allCases.count == 7)
    }

    @Test("Level has emoji")
    func levelEmoji() {
        for level in Level.allCases {
            #expect(!level.emoji.isEmpty)
        }
    }

    @Test("Course creates with required fields")
    func courseCreation() {
        let course = Course(
            slug: "test-course",
            title: "Test Course",
            description: "A test",
            level: .tools,
            lessonCount: 5,
            emoji: "\u{1F527}",
            order: 1
        )
        #expect(course.slug == "test-course")
        #expect(course.level == .tools)
    }

    @Test("BrainEntry creates with defaults")
    func brainEntry() {
        let entry = BrainEntry(key: "test.key", description: "test", value: "{}")
        #expect(entry.key == "test.key")
        #expect(entry.category == "session")
        #expect(entry.priority == 5)
    }

    @Test("BlogPost uses Sophie Cave as default author")
    func blogAuthor() {
        let post = BlogPost(slug: "test", title: "Test", description: "desc", content: "# Hello")
        #expect(post.author == "Sophie Cave")
    }

    @Test("AuthProvider raw values are correct")
    func authProviders() {
        #expect(AuthProvider.apple.rawValue == "apple")
        #expect(AuthProvider.magicLink.rawValue == "magic_link")
    }

    @Test("SubscriptionTier covers all tiers")
    func subscriptionTiers() {
        let _: SubscriptionTier = .free
        let _: SubscriptionTier = .pro
        let _: SubscriptionTier = .founding
    }
}
