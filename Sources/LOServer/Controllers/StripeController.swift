import Vapor
import Fluent
import LOContent

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
        // Parse the event (in production, verify signature with webhook secret)
        let event: StripeWebhookEvent
        do {
            event = try req.content.decode(StripeWebhookEvent.self)
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
}

struct CheckoutInput: Content {
    let plan: String
}
