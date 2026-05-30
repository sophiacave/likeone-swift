import AuthenticationServices
import SwiftUI

@MainActor
final class AuthService: NSObject, ObservableObject {
    @Published var isSignedIn = false
    @Published var email: String?
    @Published var subscription: String = "free"

    private let tokenKey = "lo_session_token"
    private let emailKey = "lo_user_email"
    private let subKey = "lo_user_subscription"
    private let baseURL = "https://likeone.ai"

    override init() {
        super.init()
        // Restore from UserDefaults
        if let token = UserDefaults.standard.string(forKey: tokenKey), !token.isEmpty {
            isSignedIn = true
            email = UserDefaults.standard.string(forKey: emailKey)
            subscription = UserDefaults.standard.string(forKey: subKey) ?? "free"
        }
    }

    var isPro: Bool { subscription == "pro" }
    var sessionToken: String? { UserDefaults.standard.string(forKey: tokenKey) }

    func signInWithApple() {
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]

        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.performRequests()
    }

    func signOut() {
        UserDefaults.standard.removeObject(forKey: tokenKey)
        UserDefaults.standard.removeObject(forKey: emailKey)
        UserDefaults.standard.removeObject(forKey: subKey)
        isSignedIn = false
        email = nil
        subscription = "free"
    }

    private func authenticate(identityToken: String, name: String?) async {
        guard let url = URL(string: "\(baseURL)/auth/apple/mobile") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        struct AuthBody: Encodable {
            let identityToken: String
            let name: String?
        }

        request.httpBody = try? JSONEncoder().encode(AuthBody(identityToken: identityToken, name: name))

        guard let (data, response) = try? await URLSession.shared.data(for: request),
              (response as? HTTPURLResponse)?.statusCode == 200 else { return }

        struct AuthResponse: Decodable {
            let token: String
            let email: String
            let subscription: String
        }

        guard let result = try? JSONDecoder().decode(AuthResponse.self, from: data) else { return }

        UserDefaults.standard.set(result.token, forKey: tokenKey)
        UserDefaults.standard.set(result.email, forKey: emailKey)
        UserDefaults.standard.set(result.subscription, forKey: subKey)

        isSignedIn = true
        email = result.email
        subscription = result.subscription
    }
}

extension AuthService: ASAuthorizationControllerDelegate {
    nonisolated func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let tokenData = credential.identityToken,
              let identityToken = String(data: tokenData, encoding: .utf8) else { return }

        let fullName = [credential.fullName?.givenName, credential.fullName?.familyName]
            .compactMap { $0 }
            .joined(separator: " ")
        let name = fullName.isEmpty ? nil : fullName

        Task { @MainActor in
            await authenticate(identityToken: identityToken, name: name)
        }
    }

    nonisolated func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        // User cancelled or error — silently handle
    }
}
