import Vapor
import LOContent
import LOBrain

func routes(_ app: Application) throws {
    let courses = CourseProvider()
    let lessons = LessonProvider()
    let blog = BlogProvider()
    let catalog = ProductCatalog()
    let tracks = TrackProvider()
    let brain = LocalBrainClient()

    try app.register(collection: HealthController())
    try app.register(collection: HomeController(courses: courses, blog: blog, lessons: lessons))
    try app.register(collection: AcademyController(courses: courses, lessons: lessons))
    try app.register(collection: APIController(courses: courses, blog: blog, catalog: catalog, lessons: lessons, tracks: tracks))
    try app.register(collection: BrainController(brain: brain))
    try app.register(collection: BlogController(blog: blog))
    try app.register(collection: SearchController(courses: courses, lessons: lessons, blog: blog, brain: brain))
    try app.register(collection: AuthController())
    try app.register(collection: GoogleAuthController())
    try app.register(collection: AccountController(courses: courses, lessons: lessons, brain: brain))
    try app.register(collection: PagesController())
    try app.register(collection: TracksController(tracks: tracks, courses: courses, lessons: lessons))
    try app.register(collection: ProgressController(courses: courses, lessons: lessons, tracks: tracks))
    try app.register(collection: CertController(tracks: tracks))
    try app.register(collection: MagicLinkController())
    try app.register(collection: SEOController(courses: courses, blog: blog, tracks: tracks, lessons: lessons))
    try app.register(collection: RSSController(blog: blog))
    try app.register(collection: StripeController(catalog: catalog))
    try app.register(collection: SubscribeController())
    try app.register(collection: RecommendController(courses: courses, lessons: lessons, blog: blog, brain: brain))
    try app.register(collection: AdminController(brain: brain, blog: blog, courses: courses))
    try app.register(collection: CronController(brain: brain, blog: blog))
    try app.register(collection: AIController(courses: courses, lessons: lessons))

    // Legacy redirects for 404 paths found in GSC
    app.get("courses") { req -> Response in
        req.redirect(to: "/academy/", redirectType: .permanent)
    }
    app.get("artists") { req -> Response in
        req.redirect(to: "/", redirectType: .permanent)
    }
}
