import Vapor
import Foundation

struct StripeService {
    private let apiKey: String
    private let client: Client

    init(client: Client) {
        // Load from config file
        let configPath = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".fractal_brain/faye_config.json").path
        if let data = FileManager.default.contents(atPath: configPath),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let key = json["stripe_api_key"] as? String {
            self.apiKey = key
        } else if let envKey = Environment.get("STRIPE_API_KEY") {
            self.apiKey = envKey
        } else {
            self.apiKey = ""
        }
        self.client = client
    }

    // MARK: - Create Checkout Session

    func createCheckoutSession(
        priceID: String,
        customerEmail: String,
        userID: String,
        successURL: String,
        cancelURL: String
    ) async throws -> String {
        let body = [
            "mode": "subscription",
            "line_items[0][price]": priceID,
            "line_items[0][quantity]": "1",
            "customer_email": customerEmail,
            "success_url": successURL,
            "cancel_url": cancelURL,
            "metadata[user_id]": userID,
            "allow_promotion_codes": "true"
        ]

        let response = try await stripeRequest(
            path: "/v1/checkout/sessions",
            body: body
        )

        guard let json = try? response.content.decode(StripeCheckoutSession.self) else {
            throw Abort(.internalServerError, reason: "Failed to parse Stripe response")
        }

        guard let url = json.url else {
            throw Abort(.internalServerError, reason: "No checkout URL returned")
        }

        return url
    }

    // MARK: - Create Billing Portal Session

    func createBillingPortalSession(
        customerID: String,
        returnURL: String
    ) async throws -> String {
        let body = [
            "customer": customerID,
            "return_url": returnURL
        ]

        let response = try await stripeRequest(
            path: "/v1/billing_portal/sessions",
            body: body
        )

        guard let json = try? response.content.decode(StripeBillingPortal.self) else {
            throw Abort(.internalServerError, reason: "Failed to parse Stripe portal response")
        }

        return json.url
    }

    // MARK: - Get Customer Subscription Status

    func getCustomerSubscriptions(customerID: String) async throws -> [StripeSubscription] {
        let response = try await stripeRequest(
            path: "/v1/subscriptions?customer=\(customerID)&status=active",
            method: .GET
        )

        guard let json = try? response.content.decode(StripeSubscriptionList.self) else {
            return []
        }

        return json.data
    }

    // MARK: - Private

    private func stripeRequest(
        path: String,
        method: HTTPMethod = .POST,
        body: [String: String]? = nil
    ) async throws -> ClientResponse {
        var headers = HTTPHeaders()
        let credentials = "\(apiKey):"
        let authValue = Data(credentials.utf8).base64EncodedString()
        headers.add(name: .authorization, value: "Basic \(authValue)")
        headers.add(name: .contentType, value: "application/x-www-form-urlencoded")

        let uri = URI(string: "https://api.stripe.com\(path)")

        if method == .POST, let body = body {
            let formBody = body.map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? $0.value)" }.joined(separator: "&")
            return try await client.post(uri, headers: headers) { req in
                req.body = ByteBuffer(string: formBody)
            }
        } else {
            return try await client.get(uri, headers: headers)
        }
    }
}

// MARK: - Stripe Response Types

struct StripeCheckoutSession: Content {
    let id: String
    let url: String?
}

struct StripeBillingPortal: Content {
    let id: String
    let url: String
}

struct StripeSubscription: Content {
    let id: String
    let status: String
    let items: StripeSubscriptionItems?
}

struct StripeSubscriptionItems: Content {
    let data: [StripeSubscriptionItem]
}

struct StripeSubscriptionItem: Content {
    let price: StripePrice?
}

struct StripePrice: Content {
    let id: String
    let product: String?
}

struct StripeSubscriptionList: Content {
    let data: [StripeSubscription]
}

struct StripeWebhookEvent: Content {
    let id: String
    let type: String
    let data: StripeEventData
}

struct StripeEventData: Content {
    let object: StripeEventObject
}

struct StripeEventObject: Content {
    let id: String?
    let customer: String?
    let customer_email: String?
    let metadata: [String: String]?
    let subscription: String?
    let status: String?
}
