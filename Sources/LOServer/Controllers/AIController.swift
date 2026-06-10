import Vapor
#if canImport(FoundationModels)
import FoundationModels
#endif
import LOContent

#if canImport(FoundationModels)

/// AI endpoints powered by Apple Foundation Models (on-device, free, private).
/// Phase 2: @Generable structured output, study notes, AI course search.
struct AIController: RouteCollection {
    let courses: CourseProvider
    let lessons: LessonProvider

    func boot(routes: RoutesBuilder) throws {
        // AI endpoints require authentication (prevents abuse of Neural Engine)
        let ai = routes.grouped("api", "v1", "ai").grouped(AuthMiddleware())
        ai.post("generate", use: generate)
        ai.post("summarize", use: summarize)
        ai.post("quiz", use: quiz)
        ai.post("notes", use: studyNotes)
        ai.post("search", use: aiSearch)
        ai.post("classify", use: classify)
    }

    // MARK: - Generate (free-form text generation)

    @Sendable
    func generate(req: Request) async throws -> Response {
        guard #available(macOS 26.0, *) else { throw Abort(.serviceUnavailable) }
        let body = try req.content.decode(GenerateRequest.self)
        let session = LanguageModelSession()
        let result = try await session.respond(to: body.prompt)
        return try encodeJSON(GenerateResponse(output: result.content), for: req)
    }

    // MARK: - Summarize (lesson content → structured bullet points)

    @Sendable
    func summarize(req: Request) async throws -> Response {
        guard #available(macOS 26.0, *) else { throw Abort(.serviceUnavailable) }
        let body = try req.content.decode(SummarizeRequest.self)

        let prompt = """
        Summarize the following lesson content in 3-5 bullet points. \
        Focus on the key concepts a student needs to remember. \
        Be concise — each point should be one sentence.

        Content:
        \(String(body.content.prefix(3000)))
        """

        let session = LanguageModelSession()
        let result = try await session.respond(to: prompt, generating: AILessonSummary.self)

        let response = SummarizeResponse(
            points: result.content.points,
            keyTakeaway: result.content.keyTakeaway
        )
        return try encodeJSON(response, for: req)
    }

    // MARK: - Quiz (@Generable type-safe quiz questions)

    @Sendable
    func quiz(req: Request) async throws -> Response {
        guard #available(macOS 26.0, *) else { throw Abort(.serviceUnavailable) }
        let body = try req.content.decode(QuizRequest.self)
        let count = min(body.count, 5)

        let prompt = """
        Based on this lesson content, generate \(count) multiple-choice quiz questions. \
        Each question should test understanding of a key concept. \
        Make the wrong options plausible but clearly incorrect to someone who studied.

        Content:
        \(String(body.content.prefix(3000)))
        """

        let session = LanguageModelSession()
        let result = try await session.respond(to: prompt, generating: QuizOutput.self)

        let response = QuizResponse(questions: result.content.questions.prefix(count).map { q in
            QuizQuestionDTO(
                question: q.question,
                options: q.options,
                correctIndex: q.correctIndex,
                explanation: q.explanation
            )
        })
        return try encodeJSON(response, for: req)
    }

    // MARK: - Study Notes (lesson → structured study notes with flashcards)

    @Sendable
    func studyNotes(req: Request) async throws -> Response {
        guard #available(macOS 26.0, *) else { throw Abort(.serviceUnavailable) }
        let body = try req.content.decode(SummarizeRequest.self)

        let prompt = """
        Create study notes from this lesson content. Include: \
        a brief overview, the key concepts explained simply, \
        and flashcard-style term/definition pairs for review.

        Content:
        \(String(body.content.prefix(3000)))
        """

        let session = LanguageModelSession()
        let result = try await session.respond(to: prompt, generating: StudyNotes.self)

        let response = StudyNotesResponse(
            overview: result.content.overview,
            concepts: result.content.concepts,
            flashcards: result.content.flashcards.map { f in
                FlashcardDTO(term: f.term, definition: f.definition)
            }
        )
        return try encodeJSON(response, for: req)
    }

    // MARK: - AI Course Search (natural language → course recommendations)

    @Sendable
    func aiSearch(req: Request) async throws -> Response {
        guard #available(macOS 26.0, *) else { throw Abort(.serviceUnavailable) }
        let body = try req.content.decode(SearchRequest.self)

        let allCourses = courses.allCourses()
        let catalog = allCourses.map { "\($0.title) — \($0.description)" }.joined(separator: "\n")

        let prompt = """
        A student is looking for: "\(body.query)"

        Here are the available courses:
        \(String(catalog.prefix(2500)))

        Recommend the top 3 most relevant courses. \
        For each, explain in one sentence why it matches the student's need.
        """

        let session = LanguageModelSession()
        let result = try await session.respond(to: prompt, generating: CourseRecommendations.self)

        let response = SearchResponse(
            query: body.query,
            recommendations: result.content.recommendations.prefix(3).map { r in
                RecommendationDTO(title: r.title, reason: r.reason)
            }
        )
        return try encodeJSON(response, for: req)
    }

    // MARK: - Classify (auto-tag and categorize content)

    @Sendable
    func classify(req: Request) async throws -> Response {
        guard #available(macOS 26.0, *) else { throw Abort(.serviceUnavailable) }
        let body = try req.content.decode(ClassifyRequest.self)

        let prompt = """
        Classify this content into a category and generate relevant tags. \
        Categories: session, directive, infrastructure, content, product, milestone, research, archive. \
        Tags should be 3-5 specific, lowercase keywords.

        Content:
        \(String(body.content.prefix(2000)))
        """

        let session = LanguageModelSession()
        let result = try await session.respond(to: prompt, generating: ContentClassification.self)

        let response = ClassifyResponse(
            category: result.content.category,
            tags: result.content.tags,
            priority: result.content.priority
        )
        return try encodeJSON(response, for: req)
    }

    // MARK: - Helpers

    private func encodeJSON<T: Content>(_ value: T, for req: Request) throws -> Response {
        let res = Response(status: .ok)
        try res.content.encode(value)
        return res
    }
}

// MARK: - @Generable Structs (Apple FM type-safe output)

@available(macOS 26.0, *)
@Generable
struct AILessonSummary {
    @Guide(description: "3-5 bullet point summaries, each one sentence")
    var points: [String]
    @Guide(description: "The single most important takeaway from this lesson")
    var keyTakeaway: String
}

@available(macOS 26.0, *)
@Generable
struct QuizOutput {
    @Guide(description: "Array of quiz questions")
    var questions: [QuizItem]
}

@available(macOS 26.0, *)
@Generable
struct QuizItem {
    @Guide(description: "The quiz question")
    var question: String
    @Guide(description: "Exactly 4 answer options")
    var options: [String]
    @Guide(description: "Zero-based index of the correct answer (0-3)")
    var correctIndex: Int
    @Guide(description: "Brief explanation of why the correct answer is right")
    var explanation: String
}

@available(macOS 26.0, *)
@Generable
struct StudyNotes {
    @Guide(description: "A 2-3 sentence overview of the lesson")
    var overview: String
    @Guide(description: "Key concepts explained in simple terms")
    var concepts: [String]
    @Guide(description: "Flashcard pairs for review")
    var flashcards: [Flashcard]
}

@available(macOS 26.0, *)
@Generable
struct Flashcard {
    @Guide(description: "The term or concept name")
    var term: String
    @Guide(description: "Simple definition or explanation")
    var definition: String
}

@available(macOS 26.0, *)
@Generable
struct CourseRecommendations {
    @Guide(description: "Top 3 recommended courses")
    var recommendations: [CourseRec]
}

@available(macOS 26.0, *)
@Generable
struct CourseRec {
    @Guide(description: "Course title exactly as listed")
    var title: String
    @Guide(description: "One sentence explaining why this course matches the query")
    var reason: String
}

@available(macOS 26.0, *)
@Generable
struct ContentClassification {
    @Guide(description: "One of: session, directive, infrastructure, content, product, milestone, research, archive")
    var category: String
    @Guide(description: "3-5 relevant lowercase keyword tags")
    var tags: [String]
    @Guide(description: "Priority from 1 (low) to 10 (critical)")
    var priority: Int
}

#else

/// Stub for platforms without FoundationModels (CI runners, older macOS).
/// Keeps the route surface identical; every endpoint returns 503.
struct AIController: RouteCollection {
    let courses: CourseProvider
    let lessons: LessonProvider

    func boot(routes: RoutesBuilder) throws {
        let ai = routes.grouped("api", "v1", "ai").grouped(AuthMiddleware())
        for endpoint in ["generate", "summarize", "quiz", "notes", "search", "classify"] {
            ai.post(.constant(endpoint)) { (_: Request) async throws -> Response in
                throw Abort(.serviceUnavailable, reason: "Apple Foundation Models unavailable on this platform")
            }
        }
    }
}

#endif

// MARK: - Request/Response DTOs

struct GenerateRequest: Content {
    let prompt: String
}

struct GenerateResponse: Content {
    let output: String
}

struct SummarizeRequest: Content {
    let content: String
}

struct SummarizeResponse: Content {
    let points: [String]
    let keyTakeaway: String
}

struct QuizRequest: Content {
    let content: String
    let count: Int
}

struct QuizResponse: Content {
    let questions: [QuizQuestionDTO]
}

struct QuizQuestionDTO: Content {
    let question: String
    let options: [String]
    let correctIndex: Int
    let explanation: String
}

struct StudyNotesResponse: Content {
    let overview: String
    let concepts: [String]
    let flashcards: [FlashcardDTO]
}

struct FlashcardDTO: Content {
    let term: String
    let definition: String
}

struct ClassifyRequest: Content {
    let content: String
}

struct ClassifyResponse: Content {
    let category: String
    let tags: [String]
    let priority: Int
}

struct SearchRequest: Content {
    let query: String
}

struct SearchResponse: Content {
    let query: String
    let recommendations: [RecommendationDTO]
}

struct RecommendationDTO: Content {
    let title: String
    let reason: String
}
