import Vapor
import Leaf

struct PagesController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        routes.get("about", use: about)
        routes.get("pricing", use: pricing)
        routes.get("foundation", use: foundation)
    }

    @Sendable
    func about(req: Request) async throws -> View {
        let context = PageContext(
            title: "About | Like One",
            heading: "About",
            description: "Like One is a 501(c)(3) nonprofit making AI education free and accessible to everyone. Founded by Sophia Cave.",
            path: "/about"
        )
        return try await req.view.render("about", context)
    }

    @Sendable
    func pricing(req: Request) async throws -> View {
        let context = PageContext(
            title: "Pricing | Like One",
            heading: "Pricing",
            description: "Like One Academy is 100% free. 52 courses, 521 lessons, no credit card required. Ever.",
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
}
