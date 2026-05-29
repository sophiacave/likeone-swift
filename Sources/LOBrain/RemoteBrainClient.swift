import Foundation
import LOCore

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

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
