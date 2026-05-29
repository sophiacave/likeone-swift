import Testing
import LOBrain
import LOCore

@Suite("LOBrain")
struct BrainTests {
    @Test("LocalBrainClient initializes with default path")
    func localClientInit() {
        let client = LocalBrainClient()
        // should not crash
        #expect(client is BrainClient)
    }

    @Test("RemoteBrainClient initializes with default URL")
    func remoteClientInit() {
        let client = RemoteBrainClient()
        #expect(client is BrainClient)
    }
}
