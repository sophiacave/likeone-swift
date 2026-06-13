import SwiftUI
import LOCore
import LOContent

struct LessonView: View {
    let courseSlug: String
    let lesson: LessonSummary
    @EnvironmentObject var progress: ProgressViewModel
    @EnvironmentObject var auth: AuthService
    @State private var html: String?
    @State private var isLoading = true

    var body: some View {
        VStack(spacing: 0) {
            if let html {
                LessonWebView(
                    html: html,
                    courseSlug: courseSlug,
                    lessonSlug: lesson.slug,
                    onQuizPassed: {
                        progress.markComplete(courseSlug: courseSlug, lessonSlug: lesson.slug)
                    }
                )
            } else if isLoading {
                VStack(spacing: 16) {
                    Spacer()
                    ProgressView()
                        .tint(Color.loPurple400)
                    Text("Loading lesson...")
                        .foregroundStyle(Color.loTextSecondary)
                    Spacer()
                }
            } else {
                VStack(spacing: 16) {
                    Spacer()
                    Image(systemName: "wifi.slash")
                        .font(.system(size: 48))
                        .foregroundStyle(Color.loTextMuted)
                    Text("Could not load lesson")
                        .foregroundStyle(Color.loTextSecondary)
                    Button("Try Again") { Task { await loadLesson() } }
                        .buttonStyle(.borderedProminent)
                        .tint(Color.loPurple400)
                    Spacer()
                }
            }

            // Bottom bar — quiz-aware
            HStack {
                if isDone {
                    Label("Complete", systemImage: "checkmark.circle.fill")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.green)
                } else if hasQuiz {
                    Label("Pass the quiz to complete", systemImage: "questionmark.circle")
                        .font(.subheadline)
                        .foregroundStyle(Color.loPurple400)
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
        .task { await loadLesson() }
    }

    private var isDone: Bool {
        progress.isCompleted(courseSlug: courseSlug, lessonSlug: lesson.slug)
    }

    private var hasQuiz: Bool {
        html?.contains("quiz-block") ?? false
    }

    private func loadLesson() async {
        guard let url = URL(string: "https://likeone.ai/api/v1/lessons/\(courseSlug)/\(lesson.slug)/html") else {
            isLoading = false
            return
        }

        // Bearer token unlocks pro lessons; without it the server returns the
        // free content or an upgrade card. S280.
        var request = URLRequest(url: url)
        if let token = auth.sessionToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        guard let (data, response) = try? await URLSession.shared.data(for: request),
              (response as? HTTPURLResponse)?.statusCode == 200,
              let content = String(data: data, encoding: .utf8) else {
            isLoading = false
            return
        }

        html = content
        isLoading = false
    }
}
