import Vapor
import Fluent
import LOCore
import LOContent

struct ProgressController: RouteCollection {
    let courses: CourseProvider
    let lessons: LessonProvider
    let tracks: TrackProvider

    func boot(routes: RoutesBuilder) throws {
        let api = routes.grouped("api", "v1", "progress")

        api.post("complete", use: markComplete)
        api.get("course", ":slug", use: courseProgress)
        api.get("track", ":slug", use: trackProgress)
        api.get("certificates", use: myCertificates)
    }

    // MARK: - Mark a lesson complete

    @Sendable
    func markComplete(req: Request) async throws -> Response {
        let user = try await req.requireUser()
        let input = try req.content.decode(CompleteInput.self)

        // Verify course and lesson exist
        guard courses.course(slug: input.courseSlug) != nil else {
            throw Abort(.notFound, reason: "Course not found")
        }
        guard lessons.lesson(courseSlug: input.courseSlug, lessonSlug: input.lessonSlug) != nil else {
            throw Abort(.notFound, reason: "Lesson not found")
        }

        // Upsert: don't duplicate if already completed
        let existing = try await ProgressModel.query(on: req.db)
            .filter(\.$userID == user.id!)
            .filter(\.$courseSlug == input.courseSlug)
            .filter(\.$lessonSlug == input.lessonSlug)
            .first()

        if existing == nil {
            let progress = ProgressModel(
                userID: user.id!,
                courseSlug: input.courseSlug,
                lessonSlug: input.lessonSlug
            )
            try await progress.save(on: req.db)
        }

        // Check if course is now complete
        let isPro = user.subscription == "pro" || user.subscription == "founding"
        let courseComplete = try await checkCourseCompletion(
            userID: user.id!,
            courseSlug: input.courseSlug,
            isPro: isPro,
            db: req.db
        )

        // Check if any track is now complete (certs only for Pro)
        var trackCompleted: String? = nil
        if courseComplete {
            trackCompleted = try await checkTrackCompletion(
                userID: user.id!,
                isPro: isPro,
                db: req.db
            )
        }

        let response = Response(status: .ok)
        try response.content.encode(CompleteResult(
            courseSlug: input.courseSlug,
            lessonSlug: input.lessonSlug,
            courseComplete: courseComplete,
            trackCompleted: trackCompleted,
            needsPro: courseComplete && !isPro
        ))
        return response
    }

    // MARK: - Course progress

    @Sendable
    func courseProgress(req: Request) async throws -> Response {
        let user = try await req.requireUser()
        guard let slug = req.parameters.get("slug") else {
            throw Abort(.badRequest)
        }

        let totalLessons = lessons.lessonCount(forCourse: slug)
        let completed = try await ProgressModel.query(on: req.db)
            .filter(\.$userID == user.id!)
            .filter(\.$courseSlug == slug)
            .all()

        let completedSlugs = completed.map(\.lessonSlug)
        let pct = totalLessons > 0 ? Int(Double(completedSlugs.count) / Double(totalLessons) * 100) : 0

        let response = Response(status: .ok)
        try response.content.encode(CourseProgressResult(
            courseSlug: slug,
            completedLessons: completedSlugs,
            totalLessons: totalLessons,
            percentComplete: pct,
            isComplete: completedSlugs.count >= totalLessons && totalLessons > 0
        ))
        return response
    }

    // MARK: - Track progress

    @Sendable
    func trackProgress(req: Request) async throws -> Response {
        let user = try await req.requireUser()
        guard let slug = req.parameters.get("slug"),
              let track = tracks.track(bySlug: slug) else {
            throw Abort(.notFound, reason: "Track not found")
        }

        let courseSlugs = track.courses.isEmpty ? courses.allCourses().map(\.slug) : track.courses
        var courseStatuses: [CourseStatus] = []

        for cs in courseSlugs {
            let totalLessons = lessons.lessonCount(forCourse: cs)
            let completed = try await ProgressModel.query(on: req.db)
                .filter(\.$userID == user.id!)
                .filter(\.$courseSlug == cs)
                .count()
            courseStatuses.append(CourseStatus(
                courseSlug: cs,
                completedLessons: completed,
                totalLessons: totalLessons,
                isComplete: completed >= totalLessons && totalLessons > 0
            ))
        }

        let allDone = courseStatuses.allSatisfy(\.isComplete)

        // Check for existing certificate
        let cert = try await CertificateModel.query(on: req.db)
            .filter(\.$userID == user.id!)
            .filter(\.$trackSlug == slug)
            .first()

        let response = Response(status: .ok)
        try response.content.encode(TrackProgressResult(
            trackSlug: slug,
            courses: courseStatuses,
            isComplete: allDone,
            certificateId: cert?.id?.uuidString
        ))
        return response
    }

    // MARK: - My certificates

    @Sendable
    func myCertificates(req: Request) async throws -> Response {
        let user = try await req.requireUser()
        let certs = try await CertificateModel.query(on: req.db)
            .filter(\.$userID == user.id!)
            .sort(\.$earnedAt, .descending)
            .all()

        let response = Response(status: .ok)
        try response.content.encode(certs)
        return response
    }

    // MARK: - Completion logic

    private func checkCourseCompletion(userID: UUID, courseSlug: String, isPro: Bool, db: Database) async throws -> Bool {
        let totalLessons = lessons.lessonCount(forCourse: courseSlug)
        guard totalLessons > 0 else { return false }

        let completed = try await ProgressModel.query(on: db)
            .filter(\.$userID == userID)
            .filter(\.$courseSlug == courseSlug)
            .count()

        if completed >= totalLessons {
            // Only issue certificates for Pro/Founding subscribers
            if isPro {
                let existing = try await CertificateModel.query(on: db)
                    .filter(\.$userID == userID)
                    .filter(\.$courseSlug == courseSlug)
                    .first()

                if existing == nil {
                    let course = courses.course(slug: courseSlug)
                    let cert = CertificateModel(
                        userID: userID,
                        type: "course",
                        courseSlug: courseSlug,
                        title: course?.title ?? courseSlug,
                        recipientName: ""
                    )
                    try await cert.save(on: db)
                }
            }
            return true
        }
        return false
    }

    private func checkTrackCompletion(userID: UUID, isPro: Bool, db: Database) async throws -> String? {
        for track in tracks.allTracks() {
            let courseSlugs = track.courses.isEmpty ? courses.allCourses().map(\.slug) : track.courses

            var allDone = true
            for cs in courseSlugs {
                let total = lessons.lessonCount(forCourse: cs)
                guard total > 0 else { allDone = false; break }
                let completed = try await ProgressModel.query(on: db)
                    .filter(\.$userID == userID)
                    .filter(\.$courseSlug == cs)
                    .count()
                if completed < total { allDone = false; break }
            }

            if allDone && !courseSlugs.isEmpty && isPro {
                let existing = try await CertificateModel.query(on: db)
                    .filter(\.$userID == userID)
                    .filter(\.$trackSlug == track.slug)
                    .first()

                if existing == nil {
                    let cert = CertificateModel(
                        userID: userID,
                        type: "track",
                        trackSlug: track.slug,
                        title: track.title,
                        recipientName: ""
                    )
                    try await cert.save(on: db)
                    return track.slug
                }
            }
        }
        return nil
    }
}

// MARK: - DTOs

struct CompleteInput: Content {
    let courseSlug: String
    let lessonSlug: String
}

struct CompleteResult: Content {
    let courseSlug: String
    let lessonSlug: String
    let courseComplete: Bool
    let trackCompleted: String?
    let needsPro: Bool?
}

struct CourseProgressResult: Content {
    let courseSlug: String
    let completedLessons: [String]
    let totalLessons: Int
    let percentComplete: Int
    let isComplete: Bool
}

struct TrackProgressResult: Content {
    let trackSlug: String
    let courses: [CourseStatus]
    let isComplete: Bool
    let certificateId: String?
}

struct CourseStatus: Content {
    let courseSlug: String
    let completedLessons: Int
    let totalLessons: Int
    let isComplete: Bool
}
