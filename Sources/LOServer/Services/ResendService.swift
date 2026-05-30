import Vapor
import Foundation

struct ResendService {
    private let apiKey: String
    private let client: Client

    init(client: Client) {
        let configPath = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".fractal_brain/faye_config.json").path
        if let data = FileManager.default.contents(atPath: configPath),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let key = json["resend_api_key"] as? String {
            self.apiKey = key
        } else if let envKey = Environment.get("RESEND_API_KEY") {
            self.apiKey = envKey
        } else {
            self.apiKey = ""
        }
        self.client = client
    }

    func sendWelcomeEmail(to email: String, name: String?, unsubscribeToken: String) async {
        let displayName = name ?? "there"
        let unsubURL = "https://likeone.ai/api/unsubscribe?token=\(unsubscribeToken)"

        let html = """
        <div style="font-family:-apple-system,sans-serif;max-width:560px;margin:0 auto;padding:40px 20px;color:#f5f5f7;background:#0a0a0f;">
            <div style="font-size:20px;font-weight:800;margin-bottom:24px;">like<span style="color:#c084fc;">one</span></div>
            <p style="color:#d4d4dc;line-height:1.6;margin-bottom:16px;">Hey \(displayName),</p>
            <p style="color:#d4d4dc;line-height:1.6;margin-bottom:16px;">Welcome to Like One. You'll get updates on new courses, AI insights, and what we're building — no spam, ever.</p>
            <p style="color:#d4d4dc;line-height:1.6;margin-bottom:24px;">Start learning: <a href="https://likeone.ai/academy" style="color:#c084fc;">likeone.ai/academy</a></p>
            <p style="color:#828288;font-size:12px;margin-top:40px;border-top:1px solid #27272a;padding-top:16px;">
                <a href="\(unsubURL)" style="color:#828288;">Unsubscribe</a> &bull; Like One &bull; hello@likeone.ai
            </p>
        </div>
        """

        let payload: [String: Any] = [
            "from": "Sophie Cave <hello@likeone.ai>",
            "to": [email],
            "subject": "Welcome to Like One",
            "html": html
        ]

        guard let jsonData = try? JSONSerialization.data(withJSONObject: payload) else { return }

        var headers = HTTPHeaders()
        headers.add(name: .authorization, value: "Bearer \(apiKey)")
        headers.add(name: .contentType, value: "application/json")

        let uri = URI(string: "https://api.resend.com/emails")
        _ = try? await client.post(uri, headers: headers) { req in
            req.body = ByteBuffer(data: jsonData)
        }
    }
}
