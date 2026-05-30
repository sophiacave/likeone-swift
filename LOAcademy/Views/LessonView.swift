import SwiftUI
import LOCore
import LOContent

struct LessonView: View {
    let courseSlug: String
    let lesson: LessonSummary
    @EnvironmentObject var progress: ProgressViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Lesson content
            if let html = loadLessonHTML() {
                LessonWebView(html: html)
            } else {
                VStack(spacing: 16) {
                    Spacer()
                    Image(systemName: "doc.text")
                        .font(.system(size: 48))
                        .foregroundStyle(Color.loTextMuted)
                    Text("Lesson content loading...")
                        .foregroundStyle(Color.loTextSecondary)
                    Spacer()
                }
            }

            // Bottom bar
            HStack {
                if isDone {
                    Label("Complete", systemImage: "checkmark.circle.fill")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.green)
                } else {
                    Button {
                        progress.markComplete(courseSlug: courseSlug, lessonSlug: lesson.slug)
                    } label: {
                        Label("Mark Complete", systemImage: "checkmark")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color.loPurple400)
                            .clipShape(Capsule())
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.loBgCard)
        }
        .navigationTitle(lesson.title)
        .navigationBarTitleDisplayMode(.inline)
        .background(Color.loBgDark)
    }

    private var isDone: Bool {
        progress.isCompleted(courseSlug: courseSlug, lessonSlug: lesson.slug)
    }

    private func loadLessonHTML() -> String? {
        // Try to load from bundle
        let path = Bundle.main.path(forResource: lesson.slug, ofType: "html", inDirectory: "Content/lessons/\(courseSlug)")
        if let path, let content = try? String(contentsOfFile: path, encoding: .utf8) {
            return content
        }
        return nil
    }
}
