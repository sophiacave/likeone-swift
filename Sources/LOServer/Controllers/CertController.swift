import Vapor
import Fluent
import LOContent

struct CertController: RouteCollection {
    let tracks: TrackProvider

    func boot(routes: RoutesBuilder) throws {
        routes.get("cert", ":id", use: verifyCert)
    }

    @Sendable
    func verifyCert(req: Request) async throws -> View {
        guard let idString = req.parameters.get("id"),
              let id = UUID(uuidString: idString),
              let cert = try await CertificateModel.find(id, on: req.db) else {
            throw Abort(.notFound, reason: "Certificate not found")
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        let dateStr = formatter.string(from: cert.earnedAt ?? Date())

        // Determine badge color from track or default purple
        var badgeColor = "#c084fc"
        if let trackSlug = cert.trackSlug, let track = tracks.track(bySlug: trackSlug) {
            badgeColor = track.badgeColor
        }

        let context = CertPageContext(
            title: "\(cert.title) Certificate | Like One",
            description: "Verified certificate for \(cert.recipientName) — \(cert.title)",
            certId: id.uuidString.lowercased(),
            certType: cert.type,
            certTitle: cert.title,
            recipientName: cert.recipientName,
            earnedDate: dateStr,
            badgeColor: badgeColor
        )
        return try await req.view.render("certificate", context)
    }
}

struct CertPageContext: Content {
    let title: String
    let description: String
    let certId: String
    let certType: String
    let certTitle: String
    let recipientName: String
    let earnedDate: String
    let badgeColor: String
}
