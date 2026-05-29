import Vapor

struct PageContext: Content {
    let title: String
    let heading: String
    let description: String
}
