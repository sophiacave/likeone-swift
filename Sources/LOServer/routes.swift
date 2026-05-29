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
    try app.register(collection: SearchController(courses: courses, lessons: lessons, blog: blog))
    try app.register(collection: AuthController())
    try app.register(collection: GoogleAuthController())
    try app.register(collection: AccountController())
    try app.register(collection: PagesController())
}
