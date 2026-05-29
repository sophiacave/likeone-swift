import Foundation
import LOCore

// MARK: - Brain Client Protocol

public protocol BrainClient: Sendable {
    func read(key: String) async throws -> BrainEntry?
    func write(_ entry: BrainEntry) async throws
    func search(query: String, limit: Int) async throws -> [BrainEntry]
    func boot() async throws -> [BrainEntry]
}

// MARK: - Local Brain Client (SQLite)

public final class LocalBrainClient: BrainClient, @unchecked Sendable {
    private let dbPath: String

    public init(dbPath: String? = nil) {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        self.dbPath = dbPath ?? "\(home)/.fractal_brain/local_brain.db"
    }

    public func read(key: String) async throws -> BrainEntry? {
        // SQLite read — implementation uses swift-sqlite or GRDB
        fatalError("TODO: implement SQLite read")
    }

    public func write(_ entry: BrainEntry) async throws {
        fatalError("TODO: implement SQLite write")
    }

    public func search(query: String, limit: Int = 5) async throws -> [BrainEntry] {
        fatalError("TODO: implement SQLite search")
    }

    public func boot() async throws -> [BrainEntry] {
        fatalError("TODO: implement boot (all high-priority keys)")
    }
}

// MARK: - Remote Brain Client (Vapor API)

public final class RemoteBrainClient: BrainClient, @unchecked Sendable {
    private let baseURL: URL

    public init(baseURL: URL = URL(string: "https://likeone-swift.fly.dev")!) {
        self.baseURL = baseURL
    }

    public func read(key: String) async throws -> BrainEntry? {
        fatalError("TODO: implement API read")
    }

    public func write(_ entry: BrainEntry) async throws {
        fatalError("TODO: implement API write")
    }

    public func search(query: String, limit: Int = 5) async throws -> [BrainEntry] {
        fatalError("TODO: implement API search")
    }

    public func boot() async throws -> [BrainEntry] {
        fatalError("TODO: implement API boot")
    }
}
