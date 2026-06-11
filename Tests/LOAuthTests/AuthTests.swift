import Testing
import Foundation
import LOAuth

@Suite("LOAuth")
struct AuthTests {
    @Test("Apple auth config has correct team ID")
    func teamID() {
        #expect(AppleAuthConfig.teamID == "MW42T97LV9")
    }

    @Test("Apple auth config has correct key ID")
    func keyID() {
        #expect(AppleAuthConfig.keyID == "LN2HDCXL6U")
    }

    @Test("Apple auth client ID is web services ID")
    func clientID() {
        #expect(AppleAuthConfig.clientID == "ai.likeone.web")
    }

    @Test("Apple auth bundle ID is app ID")
    func bundleID() {
        #expect(AppleAuthConfig.bundleID == "ai.likeone.app")
    }

    @Test("Base64URL encoding removes padding and replaces chars")
    func base64URL() {
        let data = Data("Hello, World!".utf8)
        let encoded = data.base64URLEncoded()
        #expect(!encoded.contains("+"), "Base64URL should not contain +")
        #expect(!encoded.contains("/"), "Base64URL should not contain /")
        #expect(!encoded.contains("="), "Base64URL should not contain =")
        #expect(encoded == "SGVsbG8sIFdvcmxkIQ")
    }
}
