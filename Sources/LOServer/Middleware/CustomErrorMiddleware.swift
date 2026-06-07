import Vapor
import Leaf

struct CustomErrorMiddleware: AsyncMiddleware {
    func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
        do {
            let response = try await next.respond(to: request)
            if response.status == .notFound {
                return try await renderError(request: request, status: .notFound)
            }
            return response
        } catch let abort as AbortError {
            if abort.status == .notFound {
                return try await renderError(request: request, status: .notFound)
            }
            throw abort
        }
    }

    private func renderError(request: Request, status: HTTPResponseStatus) async throws -> Response {
        let heading: String
        let message: String

        switch status {
        case .notFound:
            heading = "Page Not Found"
            message = "The page you're looking for doesn't exist or has been moved."
        default:
            heading = "Something Went Wrong"
            message = "We're working on it. Try again in a moment."
        }

        struct ErrorContext: Content {
            let title: String
            let description: String
            let code: String
            let heading: String
            let message: String
        }

        let context = ErrorContext(
            title: "\(status.code) | Like One",
            description: message,
            code: "\(status.code)",
            heading: heading,
            message: message
        )

        let buffer = try await request.view.render("error", context).get().data
        var headers = HTTPHeaders()
        headers.contentType = .html
        return Response(status: status, headers: headers, body: .init(buffer: buffer))
    }
}
