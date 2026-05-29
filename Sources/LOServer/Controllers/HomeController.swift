import Vapor
import Leaf

struct HomeController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        routes.get(use: index)
    }

    @Sendable
    func index(req: Request) async throws -> View {
        let context = HomeContext(
            title: "Like One | Free AI Academy",
            description: "52 courses, 520+ hands-on lessons on autonomous agents, automation, and AI memory.",
            stats: [
                Stat(number: "52", label: "Courses"),
                Stat(number: "520+", label: "Lessons"),
                Stat(number: "$0", label: "To Start"),
                Stat(number: "7", label: "Levels"),
            ]
        )
        return try await req.view.render("index", context)
    }
}
