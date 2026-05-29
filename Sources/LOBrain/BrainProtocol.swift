import Foundation
import LOCore

public protocol BrainClient: Sendable {
    func read(key: String) async throws -> BrainEntry?
    func write(_ entry: BrainEntry) async throws
    func search(query: String, limit: Int) async throws -> [BrainEntry]
    func boot() async throws -> [BrainEntry]
}

public enum BrainError: Error {
    case databaseNotFound(String)
    case queryFailed(String)
    case writeFailed(String)
}
