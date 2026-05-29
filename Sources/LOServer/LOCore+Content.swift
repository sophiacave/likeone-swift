import Vapor
import LOCore
import LOContent

// Bridge LOCore/LOContent models to Vapor's Content protocol
// LOCore stays Vapor-free. LOServer adds the conformance.

extension Course: Content {}
extension Lesson: Content {}
extension BlogPost: Content {}
extension Product: Content {}
extension User: Content {}
extension BrainEntry: Content {}
extension LearningProgress: Content {}
extension LessonSummary: Content {}
extension LearningTrack: Content {}
extension Certificate: Content {}
