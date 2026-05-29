import Vapor
import Leaf

func routes(_ app: Application) throws {
    // Health check
    app.get("health") { req async -> String in
        "ok"
    }

    // Home page
    app.get { req async throws -> View in
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

    // Academy stub
    app.get("academy") { req async throws -> View in
        let context = PageContext(
            title: "Academy | Like One",
            heading: "Free AI Academy",
            description: "52 courses from awareness to convergence. Start free."
        )
        return try await req.view.render("academy", context)
    }

    // API info endpoint
    app.get("api", "info") { req async -> [String: String] in
        [
            "name": "LikeOne Swift",
            "version": "0.1.0",
            "runtime": "Vapor 4 + Leaf",
            "swift": "6.3"
        ]
    }
}

struct HomeContext: Content {
    let title: String
    let description: String
    let stats: [Stat]
}

struct Stat: Content {
    let number: String
    let label: String
}

struct PageContext: Content {
    let title: String
    let heading: String
    let description: String
}
