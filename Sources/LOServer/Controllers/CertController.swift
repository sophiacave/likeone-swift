import Vapor
import Fluent
import Foundation
import LOContent

struct CertController: RouteCollection {
    let tracks: TrackProvider

    func boot(routes: RoutesBuilder) throws {
        routes.get("cert", ":id", use: verifyCert)
        routes.get("cert", ":id", "pdf", use: downloadPDF)
    }

    @Sendable
    func verifyCert(req: Request) async throws -> View {
        let (cert, id) = try await findCert(req: req)
        let ctx = buildCertContext(cert: cert, id: id)
        return try await req.view.render("certificate", ctx)
    }

    @Sendable
    func downloadPDF(req: Request) async throws -> Response {
        // PDF downloads require Pro subscription
        let user = try await req.requireUser()
        guard user.subscription == "pro" || user.subscription == "founding" else {
            return req.redirect(to: "/pricing")
        }

        let (cert, id) = try await findCert(req: req)
        let ctx = buildCertContext(cert: cert, id: id)

        // Load and fill the HTML template
        let templatePath = req.application.directory.resourcesDirectory + "Templates/cert-pdf.html"
        guard let templateData = FileManager.default.contents(atPath: templatePath),
              let template = String(data: templateData, encoding: .utf8) else {
            throw Abort(.internalServerError, reason: "Certificate template not found")
        }

        let typeLabel = cert.type == "track" ? "Learning Track Certificate" : "Course Certificate"
        let badgeBg = "\(ctx.badgeColor)20"

        let html = template
            .replacingOccurrences(of: "{{RECIPIENT_NAME}}", with: ctx.recipientName.htmlEscaped)
            .replacingOccurrences(of: "{{CERT_TITLE}}", with: ctx.certTitle.htmlEscaped)
            .replacingOccurrences(of: "{{CERT_TYPE_LABEL}}", with: typeLabel)
            .replacingOccurrences(of: "{{EARNED_DATE}}", with: ctx.earnedDate)
            .replacingOccurrences(of: "{{CERT_ID}}", with: ctx.certId)
            .replacingOccurrences(of: "{{BADGE_COLOR}}", with: ctx.badgeColor)
            .replacingOccurrences(of: "{{BADGE_BG}}", with: badgeBg)

        // Run WeasyPrint to convert HTML to PDF
        let pdfData = try await generatePDF(from: html)

        let safeTitle = ctx.certTitle
            .replacingOccurrences(of: " ", with: "-")
            .replacingOccurrences(of: "/", with: "-")
            .lowercased()
        let filename = "likeone-cert-\(safeTitle).pdf"

        let response = Response(status: .ok)
        response.headers.contentType = .pdf
        response.headers.add(name: .contentDisposition, value: "attachment; filename=\"\(filename)\"")
        response.body = .init(data: pdfData)
        return response
    }

    // MARK: - Helpers

    private func findCert(req: Request) async throws -> (CertificateModel, UUID) {
        guard let idString = req.parameters.get("id"),
              let id = UUID(uuidString: idString),
              let cert = try await CertificateModel.find(id, on: req.db) else {
            throw Abort(.notFound, reason: "Certificate not found")
        }
        return (cert, id)
    }

    private func buildCertContext(cert: CertificateModel, id: UUID) -> CertPageContext {
        let earnedDate = cert.earnedAt ?? Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        let dateStr = formatter.string(from: earnedDate)

        let cal = Calendar.current
        let year = String(cal.component(.year, from: earnedDate))
        let month = String(cal.component(.month, from: earnedDate))

        var badgeColor = "#c084fc"
        if let trackSlug = cert.trackSlug, let track = tracks.track(bySlug: trackSlug) {
            badgeColor = track.badgeColor
        }

        return CertPageContext(
            title: "\(cert.title) Certificate | Like One",
            description: "Verified certificate for \(cert.recipientName) — \(cert.title)",
            certId: id.uuidString.lowercased(),
            certType: cert.type,
            certTitle: cert.title,
            recipientName: cert.recipientName,
            earnedDate: dateStr,
            earnedYear: year,
            earnedMonth: month,
            badgeColor: badgeColor
        )
    }

    private func generatePDF(from html: String) async throws -> Data {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global().async {
                let process = Process()
                process.executableURL = URL(fileURLWithPath: "/opt/homebrew/bin/weasyprint")
                process.arguments = ["-", "-"]

                let inputPipe = Pipe()
                let outputPipe = Pipe()
                let errorPipe = Pipe()
                process.standardInput = inputPipe
                process.standardOutput = outputPipe
                process.standardError = errorPipe

                do {
                    try process.run()
                } catch {
                    continuation.resume(throwing: Abort(.internalServerError, reason: "Failed to run PDF generator"))
                    return
                }

                // Write HTML to stdin
                if let htmlData = html.data(using: .utf8) {
                    inputPipe.fileHandleForWriting.write(htmlData)
                }
                inputPipe.fileHandleForWriting.closeFile()

                process.waitUntilExit()

                if process.terminationStatus != 0 {
                    let errData = errorPipe.fileHandleForReading.readDataToEndOfFile()
                    let errMsg = String(data: errData, encoding: .utf8) ?? "Unknown error"
                    continuation.resume(throwing: Abort(.internalServerError, reason: "PDF generation failed: \(errMsg)"))
                    return
                }

                let pdfData = outputPipe.fileHandleForReading.readDataToEndOfFile()
                if pdfData.isEmpty {
                    continuation.resume(throwing: Abort(.internalServerError, reason: "PDF generation produced empty output"))
                    return
                }

                continuation.resume(returning: pdfData)
            }
        }
    }
}

private extension String {
    var htmlEscaped: String {
        self.replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
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
    let earnedYear: String
    let earnedMonth: String
    let badgeColor: String
}
