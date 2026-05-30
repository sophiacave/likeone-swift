import Vapor
import Fluent

extension Request {
    func requireUser() async throws -> UserModel {
        guard let token = cookies["lo_session"]?.string,
              let session = try await SessionModel.query(on: db).filter(\.$token == token).first(),
              !session.isExpired,
              let user = try await UserModel.find(session.userID, on: db) else {
            throw Abort(.unauthorized, reason: "Sign in required")
        }
        return user
    }
}
