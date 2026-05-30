import Vapor
import Fluent

struct SubscribeController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        routes.post("api", "subscribe", use: subscribe)
        routes.get("api", "unsubscribe", use: unsubscribe)
    }

    @Sendable
    func subscribe(req: Request) async throws -> Response {
        let input = try req.content.decode(SubscribeInput.self)

        // Basic email validation
        guard input.email.contains("@"), input.email.contains(".") else {
            return htmlResponse("<p class=\"subscribe-error\">Please enter a valid email.</p>")
        }

        // Check for existing subscriber
        let existing = try await SubscriberModel.query(on: req.db)
            .filter(\.$email == input.email.lowercased())
            .first()

        if existing != nil {
            // Silent success — don't reveal if email exists
            return htmlResponse("<p class=\"subscribe-success\">You're in! Check your inbox.</p>")
        }

        // Create new subscriber
        let subscriber = SubscriberModel(
            email: input.email.lowercased(),
            name: input.name,
            sourcePage: input.sourcePage ?? "/"
        )
        try await subscriber.save(on: req.db)

        // Send welcome email (fire and forget)
        let resend = ResendService(client: req.client)
        Task {
            await resend.sendWelcomeEmail(
                to: subscriber.email,
                name: subscriber.name,
                unsubscribeToken: subscriber.unsubscribeToken
            )
        }

        req.logger.info("New subscriber: \(subscriber.email) from \(subscriber.sourcePage)")
        return htmlResponse("<p class=\"subscribe-success\">You're in! Check your inbox.</p>")
    }

    @Sendable
    func unsubscribe(req: Request) async throws -> View {
        let token = req.query[String.self, at: "token"] ?? ""

        if let subscriber = try await SubscriberModel.query(on: req.db)
            .filter(\.$unsubscribeToken == token)
            .first() {
            subscriber.active = false
            try await subscriber.save(on: req.db)
            req.logger.info("Unsubscribed: \(subscriber.email)")
        }

        struct Ctx: Content {
            let title: String
            let description: String
        }
        return try await req.view.render("unsubscribe", Ctx(
            title: "Unsubscribed | Like One",
            description: "You've been unsubscribed from Like One updates."
        ))
    }

    private func htmlResponse(_ html: String) -> Response {
        var headers = HTTPHeaders()
        headers.contentType = .html
        return Response(status: .ok, headers: headers, body: .init(string: html))
    }
}

struct SubscribeInput: Content {
    let email: String
    let name: String?
    let sourcePage: String?
}
