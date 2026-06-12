import Vapor
import Fluent
import Foundation
import LOContent
import Crypto

struct StripeController: RouteCollection {
    let catalog: ProductCatalog

    func boot(routes: RoutesBuilder) throws {
        // Checkout (requires auth)
        let auth = routes.grouped(AuthMiddleware())
        auth.post("checkout", use: createCheckout)
        auth.get("billing", use: billingPortal)

        // Success/cancel pages (no auth required — user may have cleared session)
        routes.get("checkout", "success", use: checkoutSuccess)
        routes.get("checkout", "cancel", use: checkoutCancel)

        // Webhook (no auth — Stripe calls this)
        routes.post("stripe", "webhook", use: handleWebhook)
        // Legacy path — Stripe dashboard was configured with this URL
        routes.post("api", "stripe-webhook", use: handleWebhook)
    }

    // MARK: - Create Checkout Session

    @Sendable
    func createCheckout(req: Request) async throws -> Response {
        let user = req.authenticatedUser!
        let input = try req.content.decode(CheckoutInput.self)

        guard let product = catalog.product(slug: input.plan),
              let priceID = product.stripePriceID else {
            throw Abort(.badRequest, reason: "Invalid plan")
        }

        let baseURL = req.application.baseURL
        let stripe = StripeService(client: req.client)
        let checkoutURL = try await stripe.createCheckoutSession(
            priceID: priceID,
            customerEmail: user.email,
            userID: user.id!.uuidString,
            successURL: "\(baseURL)/checkout/success?session_id={CHECKOUT_SESSION_ID}",
            cancelURL: "\(baseURL)/checkout/cancel"
        )

        return req.redirect(to: checkoutURL)
    }

    // MARK: - Billing Portal

    @Sendable
    func billingPortal(req: Request) async throws -> Response {
        let user = req.authenticatedUser!

        guard let customerID = user.stripeCustomerID, !customerID.isEmpty else {
            return req.redirect(to: "/pricing")
        }

        let stripe = StripeService(client: req.client)
        let portalURL = try await stripe.createBillingPortalSession(
            customerID: customerID,
            returnURL: "\(req.application.baseURL)/account"
        )

        return req.redirect(to: portalURL)
    }

    // MARK: - Success / Cancel Pages

    @Sendable
    func checkoutSuccess(req: Request) async throws -> View {
        struct Ctx: Content {
            let title: String
            let description: String
        }
        return try await req.view.render("checkout-success", Ctx(
            title: "Welcome to Academy Pro | Like One",
            description: "Your subscription is active. You now have full access to all courses and lessons."
        ))
    }

    @Sendable
    func checkoutCancel(req: Request) async throws -> Response {
        return req.redirect(to: "/pricing")
    }

    // MARK: - Stripe Webhook

    @Sendable
    func handleWebhook(req: Request) async throws -> Response {
        // Verify Stripe webhook signature
        let rawBody: String
        if let bodyData = req.body.data {
            rawBody = String(buffer: bodyData)
        } else {
            return Response(status: .badRequest)
        }

        if let sigHeader = req.headers.first(name: "Stripe-Signature") {
            guard verifyStripeSignature(payload: rawBody, header: sigHeader) else {
                req.logger.warning("Invalid Stripe webhook signature")
                return Response(status: .unauthorized)
            }
        }

        let event: StripeWebhookEvent
        do {
            event = try JSONDecoder().decode(StripeWebhookEvent.self, from: Data(rawBody.utf8))
        } catch {
            req.logger.error("Failed to parse Stripe webhook: \(error)")
            return Response(status: .badRequest)
        }

        req.logger.info("Stripe webhook: \(event.type)")

        switch event.type {
        case "checkout.session.completed":
            try await handleCheckoutCompleted(event: event, db: req.db, logger: req.logger)

        case "customer.subscription.updated":
            try await handleSubscriptionUpdated(event: event, db: req.db, logger: req.logger)

        case "customer.subscription.deleted":
            try await handleSubscriptionDeleted(event: event, db: req.db, logger: req.logger)

        default:
            req.logger.info("Unhandled Stripe event: \(event.type)")
        }

        return Response(status: .ok)
    }

    // MARK: - Webhook Handlers

    private func handleCheckoutCompleted(event: StripeWebhookEvent, db: Database, logger: Logger) async throws {
        let obj = event.data.object

        // Find user by metadata user_id or by email
        var user: UserModel?

        if let userIDStr = obj.metadata?["user_id"], let userID = UUID(uuidString: userIDStr) {
            user = try await UserModel.find(userID, on: db)
        }

        if user == nil, let email = obj.customer_email {
            user = try await UserModel.query(on: db).filter(\.$email == email).first()
        }

        guard let user = user else {
            logger.warning("Stripe checkout completed but no user found: \(obj.customer_email ?? "unknown")")
            return
        }

        // Update stripe customer ID and subscription tier
        if let customerID = obj.customer {
            user.stripeCustomerID = customerID
        }
        user.subscription = "pro"

        try await user.save(on: db)
        logger.info("User \(user.email) upgraded to pro via Stripe checkout")

        // Send welcome email
        sendWelcomeEmail(to: user.email, name: user.name ?? "Academy Member", logger: logger)
    }

    private func sendWelcomeEmail(to email: String, name: String, logger: Logger) {
        let subject = "Welcome to Academy Pro!"
        let body = """
        Hi \(name),

        Your Academy Pro subscription is active. You now have full access to:

        - Verified completion certificates for all 52 courses
        - PDF certificate downloads
        - LinkedIn-ready credentials
        - Learning track certificates
        - Priority support

        Start learning: https://likeone.ai/academy
        Your account: https://likeone.ai/account

        Thank you for supporting free AI education. Your subscription directly funds keeping the Academy free for everyone and donating to HIV cure research at UCSF.

        -- Sophie Cave
        Founder, Like One
        """

        // Fire and forget — use send-email CLI
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/Users/sophiacave/bin/send-email")
        process.arguments = ["--to", email, "--subject", subject, "--body", body]
        do {
            try process.run()
            logger.info("Welcome email sent to \(email)")
        } catch {
            logger.error("Failed to send welcome email: \(error)")
        }
    }

    private func handleSubscriptionUpdated(event: StripeWebhookEvent, db: Database, logger: Logger) async throws {
        let obj = event.data.object
        guard let customerID = obj.customer else { return }

        guard let user = try await UserModel.query(on: db)
            .filter(\.$stripeCustomerID == customerID)
            .first() else {
            logger.warning("Subscription updated for unknown customer: \(customerID)")
            return
        }

        if obj.status == "active" {
            user.subscription = "pro"
        } else if obj.status == "past_due" || obj.status == "unpaid" {
            user.subscription = "pro" // Grace period
        }

        try await user.save(on: db)
        logger.info("Subscription updated for \(user.email): \(obj.status ?? "unknown")")
    }

    private func handleSubscriptionDeleted(event: StripeWebhookEvent, db: Database, logger: Logger) async throws {
        let obj = event.data.object
        guard let customerID = obj.customer else { return }

        guard let user = try await UserModel.query(on: db)
            .filter(\.$stripeCustomerID == customerID)
            .first() else { return }

        user.subscription = "free"
        try await user.save(on: db)
        logger.info("Subscription canceled for \(user.email)")
    }
    // MARK: - Signature Verification

    private func verifyStripeSignature(payload: String, header: String) -> Bool {
        // Load webhook secret from config
        let configPath = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".fractal_brain/faye_config.json").path
        guard let data = FileManager.default.contents(atPath: configPath),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let secret = json["stripe_webhook_secret"] as? String else {
            return true // No secret configured — allow (development mode)
        }

        // Parse header: t=timestamp,v1=signature
        var timestamp = ""
        var signatures: [String] = []
        for part in header.split(separator: ",") {
            let kv = part.split(separator: "=", maxSplits: 1)
            guard kv.count == 2 else { continue }
            if kv[0] == "t" { timestamp = String(kv[1]) }
            if kv[0] == "v1" { signatures.append(String(kv[1])) }
        }

        guard !timestamp.isEmpty, !signatures.isEmpty else { return false }

        // Check timestamp tolerance (5 minutes)
        if let ts = Double(timestamp) {
            let age = Date().timeIntervalSince1970 - ts
            if age > 300 { return false }
        }

        // Compute expected signature
        let signedPayload = "\(timestamp).\(payload)"
        let key = SymmetricKey(data: Data(secret.utf8))
        let mac = HMAC<SHA256>.authenticationCode(for: Data(signedPayload.utf8), using: key)
        let expectedSig = mac.map { String(format: "%02x", $0) }.joined()

        return signatures.contains(expectedSig)
    }
}

struct CheckoutInput: Content {
    let plan: String
}
