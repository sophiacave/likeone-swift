import Vapor

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
