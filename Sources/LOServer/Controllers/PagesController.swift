import Vapor
import Leaf

struct PagesController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        routes.get("about", use: about)
        routes.get("pricing", use: pricing)
        routes.get("foundation", use: foundation)
        routes.get("consulting", use: consulting)
        routes.get("privacy", use: privacy)
        routes.get("terms", use: terms)
    }

    @Sendable
    func about(req: Request) async throws -> View {
        let context = PageContext(
            title: "About | Like One",
            heading: "About",
            description: "Like One builds AI education and tools. The Like One Foundation is a 501(c)(3) nonprofit funding HIV cure research. Founded by Sophia Cave.",
            path: "/about"
        )
        return try await req.view.render("about", context)
    }

    @Sendable
    func pricing(req: Request) async throws -> View {
        let context = PageContext(
            title: "Pricing | Like One",
            heading: "Pricing",
            description: "52 courses, 520+ lessons. First 3 free on every course. Pro unlocks full access and certificates.",
            path: "/pricing"
        )
        return try await req.view.render("pricing", context)
    }

    @Sendable
    func foundation(req: Request) async throws -> View {
        let context = PageContext(
            title: "Foundation | Like One",
            heading: "Foundation",
            description: "The Like One Foundation funds HIV cure research and AI accessibility. 501(c)(3) tax-exempt nonprofit.",
            path: "/foundation"
        )
        return try await req.view.render("foundation", context)
    }

    @Sendable
    func privacy(req: Request) async throws -> View {
        let context = PageContext(
            title: "Privacy Policy | Like One",
            heading: "Privacy",
            description: "Like One privacy policy. How we handle your data, cookies, and third-party services.",
            path: "/privacy"
        )
        return try await req.view.render("privacy", context)
    }

    @Sendable
    func terms(req: Request) async throws -> View {
        let context = PageContext(
            title: "Terms of Service | Like One",
            heading: "Terms",
            description: "Like One terms of service. Account, subscription, certificate, and usage terms.",
            path: "/terms"
        )
        return try await req.view.render("terms", context)
    }

    @Sendable
    func consulting(req: Request) async throws -> View {
        let context = PageContext(
            title: "AI Consulting | Like One",
            heading: "Consulting",
            description: "AI systems that run your operations autonomously. Custom agents, MCP servers, full-stack AI applications. From $500/month.",
            path: "/consulting"
        )
        return try await req.view.render("consulting", context)
    }
}
