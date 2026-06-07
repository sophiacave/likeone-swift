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

/// Result from public content FTS5 search (safe — no private brain data)
public struct ContentSearchResult: Codable, Sendable {
    public let docID: String
    public let collection: String
    public let snippet: String
    public let score: Double

    public init(docID: String, collection: String, snippet: String, score: Double) {
        self.docID = docID
        self.collection = collection
        self.snippet = snippet
        self.score = score
    }
}
