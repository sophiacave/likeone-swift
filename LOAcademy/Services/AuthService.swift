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

    /// Google sign-in via ASWebAuthenticationSession: opens /signin/mobile/
    /// (GIS redirect flow), receives likeoneacademy://auth?c=<one-time code>,
    /// then exchanges the code for a bearer token at /auth/mobile/exchange. S280.
    private var webAuthSession: ASWebAuthenticationSession?

    func signInWithGoogle() {
        guard let url = URL(string: "\(baseURL)/signin/mobile/") else { return }

        let session = ASWebAuthenticationSession(
            url: url,
            callbackURLScheme: "likeoneacademy"
        ) { [weak self] callbackURL, _ in
            guard let callbackURL,
                  let code = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false)?
                      .queryItems?.first(where: { $0.name == "c" })?.value else { return }
            Task { @MainActor in
                await self?.exchangeHandoffCode(code)
            }
        }
        session.presentationContextProvider = self
        session.prefersEphemeralWebBrowserSession = false
        webAuthSession = session
        session.start()
    }

    private func exchangeHandoffCode(_ code: String) async {
        guard let url = URL(string: "\(baseURL)/auth/mobile/exchange") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONEncoder().encode(["code": code])

        guard let (data, response) = try? await URLSession.shared.data(for: request),
              (response as? HTTPURLResponse)?.statusCode == 200,
              let result = try? JSONDecoder().decode(AuthResponse.self, from: data) else { return }

        storeSession(result)
    }

    func signOut() {
        UserDefaults.standard.removeObject(forKey: tokenKey)
        UserDefaults.standard.removeObject(forKey: emailKey)
        UserDefaults.standard.removeObject(forKey: subKey)
        isSignedIn = false
        email = nil
        subscription = "free"
    }

    struct AuthResponse: Decodable {
        let token: String
        let email: String
        let subscription: String
    }

    private func storeSession(_ result: AuthResponse) {
        UserDefaults.standard.set(result.token, forKey: tokenKey)
        UserDefaults.standard.set(result.email, forKey: emailKey)
        UserDefaults.standard.set(result.subscription, forKey: subKey)

        isSignedIn = true
        email = result.email
        subscription = result.subscription
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
              (response as? HTTPURLResponse)?.statusCode == 200,
              let result = try? JSONDecoder().decode(AuthResponse.self, from: data) else { return }

        storeSession(result)
    }
}

extension AuthService: ASWebAuthenticationPresentationContextProviding {
    nonisolated func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        MainActor.assumeIsolated {
            UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap(\.windows)
                .first(where: \.isKeyWindow) ?? ASPresentationAnchor()
        }
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
