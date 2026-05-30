import Vapor

extension Application {
    var baseURL: String {
        let env = Environment.get("BASE_URL")
        if let env { return env }
        return environment == .production
            ? "https://likeone.ai"
            : "http://localhost:8080"
    }
}
