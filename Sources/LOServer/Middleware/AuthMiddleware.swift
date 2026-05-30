import Vapor
import Fluent

struct AuthMiddleware: AsyncMiddleware {
    func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
        guard let token = request.cookies["lo_session"]?.string,
              let session = try await SessionModel.query(on: request.db).filter(\.$token == token).first(),
              !session.isExpired,
              let user = try await UserModel.find(session.userID, on: request.db) else {
            return request.redirect(to: "/signin")
        }
        request.storage[AuthenticatedUserKey.self] = user
        return try await next.respond(to: request)
    }
}

/// Optional auth — sets user if logged in, but doesn't redirect
struct OptionalAuthMiddleware: AsyncMiddleware {
    func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
        if let token = request.cookies["lo_session"]?.string,
           let session = try await SessionModel.query(on: request.db).filter(\.$token == token).first(),
           !session.isExpired,
           let user = try await UserModel.find(session.userID, on: request.db) {
            request.storage[AuthenticatedUserKey.self] = user
        }
        return try await next.respond(to: request)
    }
}

struct AuthenticatedUserKey: StorageKey {
    typealias Value = UserModel
}

extension Request {
    var authenticatedUser: UserModel? {
        storage[AuthenticatedUserKey.self]
    }
}
