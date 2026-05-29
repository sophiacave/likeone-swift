import Foundation
import LOCore
import CSQLite3

// MARK: - Brain Client Protocol

public protocol BrainClient: Sendable {
    func read(key: String) async throws -> BrainEntry?
    func write(_ entry: BrainEntry) async throws
    func search(query: String, limit: Int) async throws -> [BrainEntry]
    func boot() async throws -> [BrainEntry]
}

// MARK: - SQLite Error

public enum BrainError: Error {
    case databaseNotFound(String)
    case queryFailed(String)
    case writeFailed(String)
}

// MARK: - Local Brain Client (SQLite)

public final class LocalBrainClient: BrainClient, @unchecked Sendable {
    public let dbPath: String
    private let lock = NSLock()

    public init(dbPath: String? = nil) {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        self.dbPath = dbPath ?? "\(home)/.fractal_brain/local_brain.db"
    }

    public func read(key: String) async throws -> BrainEntry? {
        let sql = "SELECT id, key, category, description, value, priority, updated_at FROM brain_context WHERE key = ? LIMIT 1"
        let results = try query(sql: sql, params: [key])
        return results.first
    }

    public func write(_ entry: BrainEntry) async throws {
        let sql = """
            INSERT OR REPLACE INTO brain_context (id, key, category, description, value, priority, created_at, updated_at)
            VALUES (?, ?, ?, ?, ?, ?, datetime('now'), datetime('now'))
            """
        try execute(sql: sql, params: [
            entry.id.uuidString,
            entry.key,
            entry.category,
            entry.description,
            entry.value,
            String(entry.priority),
        ])
    }

    public func search(query searchTerm: String, limit: Int = 5) async throws -> [BrainEntry] {
        // Use FTS5 if available, fall back to LIKE
        let sql = """
            SELECT id, key, category, description, value, priority, updated_at FROM brain_context
            WHERE key LIKE ? OR description LIKE ? OR value LIKE ?
            ORDER BY priority DESC LIMIT ?
            """
        let pattern = "%\(searchTerm)%"
        return try self.query(sql: sql, params: [pattern, pattern, pattern, String(limit)])
    }

    public func boot() async throws -> [BrainEntry] {
        let sql = """
            SELECT id, key, category, description, value, priority, updated_at FROM brain_context
            WHERE category IN ('directive', 'identity', 'session', 'infrastructure', 'system', 'giving')
            ORDER BY priority DESC
            """
        return try query(sql: sql, params: [])
    }

    // MARK: - SQLite Operations

    private func withDB<T>(_ body: (OpaquePointer) throws -> T) throws -> T {
        lock.lock()
        defer { lock.unlock() }

        var db: OpaquePointer?
        guard sqlite3_open_v2(dbPath, &db, SQLITE_OPEN_READWRITE, nil) == SQLITE_OK,
              let db else {
            let msg = db.map { String(cString: sqlite3_errmsg($0)) } ?? "unknown"
            sqlite3_close(db)
            throw BrainError.databaseNotFound("Cannot open \(dbPath): \(msg)")
        }
        defer { sqlite3_close(db) }
        return try body(db)
    }

    private func query(sql: String, params: [String]) throws -> [BrainEntry] {
        try withDB { db in
            var stmt: OpaquePointer?
            guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
                let msg = String(cString: sqlite3_errmsg(db))
                throw BrainError.queryFailed(msg)
            }
            defer { sqlite3_finalize(stmt) }

            for (i, param) in params.enumerated() {
                sqlite3_bind_text(stmt, Int32(i + 1), param, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
            }

            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

            var results: [BrainEntry] = []
            while sqlite3_step(stmt) == SQLITE_ROW {
                let id = col(stmt, 0)
                let key = col(stmt, 1)
                let category = col(stmt, 2)
                let description = col(stmt, 3)
                let value = col(stmt, 4)
                let priority = Int(col(stmt, 5)) ?? 5
                let updatedStr = col(stmt, 6)
                let updatedAt = formatter.date(from: updatedStr) ?? Date()

                results.append(BrainEntry(
                    id: UUID(uuidString: id) ?? UUID(),
                    key: key,
                    category: category,
                    description: description,
                    value: value,
                    priority: priority,
                    updatedAt: updatedAt
                ))
            }
            return results
        }
    }

    private func execute(sql: String, params: [String]) throws {
        try withDB { db in
            var stmt: OpaquePointer?
            guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
                let msg = String(cString: sqlite3_errmsg(db))
                throw BrainError.writeFailed(msg)
            }
            defer { sqlite3_finalize(stmt) }

            for (i, param) in params.enumerated() {
                sqlite3_bind_text(stmt, Int32(i + 1), param, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
            }

            guard sqlite3_step(stmt) == SQLITE_DONE else {
                let msg = String(cString: sqlite3_errmsg(db))
                throw BrainError.writeFailed(msg)
            }
        }
    }

    private func col(_ stmt: OpaquePointer?, _ index: Int32) -> String {
        guard let cStr = sqlite3_column_text(stmt, index) else { return "" }
        return String(cString: cStr)
    }
}

// MARK: - Remote Brain Client (Vapor API)

public final class RemoteBrainClient: BrainClient, @unchecked Sendable {
    private let baseURL: URL

    public init(baseURL: URL = URL(string: "https://likeone-swift.fly.dev")!) {
        self.baseURL = baseURL
    }

    public func read(key: String) async throws -> BrainEntry? {
        let url = baseURL.appendingPathComponent("api/v1/brain/\(key)")
        let (data, _) = try await URLSession.shared.data(from: url)
        return try? JSONDecoder().decode(BrainEntry.self, from: data)
    }

    public func write(_ entry: BrainEntry) async throws {
        var request = URLRequest(url: baseURL.appendingPathComponent("api/v1/brain"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(entry)
        _ = try await URLSession.shared.data(for: request)
    }

    public func search(query: String, limit: Int = 5) async throws -> [BrainEntry] {
        var components = URLComponents(url: baseURL.appendingPathComponent("api/v1/brain/search"), resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "limit", value: String(limit)),
        ]
        let (data, _) = try await URLSession.shared.data(from: components.url!)
        return (try? JSONDecoder().decode([BrainEntry].self, from: data)) ?? []
    }

    public func boot() async throws -> [BrainEntry] {
        let url = baseURL.appendingPathComponent("api/v1/brain/boot")
        let (data, _) = try await URLSession.shared.data(from: url)
        return (try? JSONDecoder().decode([BrainEntry].self, from: data)) ?? []
    }
}
