import Testing
import LOBrain
import LOCore

@Suite("LOBrain")
struct BrainTests {
    @Test("LocalBrainClient initializes with default path")
    func localClientInit() {
        let client = LocalBrainClient()
        #expect(client is BrainClient)
        #expect(client.dbPath.contains("local_brain.db"))
    }

    @Test("RemoteBrainClient initializes with default URL")
    func remoteClientInit() {
        let client = RemoteBrainClient()
        #expect(client is BrainClient)
    }

    @Test("LocalBrainClient reads a known key from local brain")
    func readKey() async throws {
        let client = LocalBrainClient()
        let entry = try await client.read(key: "directive.prime_directive_name")
        #expect(entry != nil, "Expected to find directive.prime_directive_name in brain")
        #expect(entry?.category == "directive")
    }

    @Test("LocalBrainClient search finds results")
    func searchBrain() async throws {
        let client = LocalBrainClient()
        let results = try await client.search(query: "sprint", limit: 3)
        #expect(results.count > 0, "Expected brain search for 'sprint' to return results")
    }

    @Test("LocalBrainClient boot returns high-priority entries")
    func bootBrain() async throws {
        let client = LocalBrainClient()
        let entries = try await client.boot()
        #expect(entries.count > 5, "Expected boot to return many entries, got \(entries.count)")
        let categories = Set(entries.map { $0.category })
        #expect(categories.contains("directive"), "Expected boot to include directives")
    }
}
