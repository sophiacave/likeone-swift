import Vapor
import LOCore

// Bridge LOCore models to Vapor's Content protocol
// LOCore stays Vapor-free. LOServer adds the conformance.

extension Course: Content {}
extension Lesson: Content {}
extension BlogPost: Content {}
extension Product: Content {}
extension User: Content {}
extension BrainEntry: Content {}
extension LearningProgress: Content {}
