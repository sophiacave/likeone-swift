import Vapor
import Leaf
import Fluent

struct AccountController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let protected = routes.grouped(AuthMiddleware())
        protected.get("account", use: account)
    }

    @Sendable
    func account(req: Request) async throws -> View {
        let user = req.authenticatedUser!
        let context = AccountContext(
            title: "Account | Like One",
            email: user.email,
            name: user.name ?? "Academy Member",
            subscription: user.subscription
        )
        return try await req.view.render("account", context)
    }
}

struct AccountContext: Content {
    let title: String
    let email: String
    let name: String
    let subscription: String
}
