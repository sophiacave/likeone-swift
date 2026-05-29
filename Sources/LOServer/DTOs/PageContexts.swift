import Vapor

let siteBaseURL = "https://likeone-swift.fly.dev"

struct PageContext: Content {
    let title: String
    let heading: String
    let description: String
    let canonicalUrl: String?

    init(title: String, heading: String, description: String, path: String? = nil) {
        self.title = title
        self.heading = heading
        self.description = description
        self.canonicalUrl = path.map { siteBaseURL + $0 }
    }
}
