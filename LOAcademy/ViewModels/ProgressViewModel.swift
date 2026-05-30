import SwiftUI
import LOCore

@MainActor
final class ProgressViewModel: ObservableObject {
    @Published private(set) var completed: [String: [String]] = [:]  // courseSlug → [lessonSlug]

    private let storageKey = "lo_progress"

    init() {
        load()
    }

    // MARK: - Local Progress

    func isCompleted(courseSlug: String, lessonSlug: String) -> Bool {
        completed[courseSlug]?.contains(lessonSlug) ?? false
    }

    func completedCount(for courseSlug: String) -> Int {
        completed[courseSlug]?.count ?? 0
    }

    func markComplete(courseSlug: String, lessonSlug: String) {
        if completed[courseSlug] == nil {
            completed[courseSlug] = []
        }
        guard !(completed[courseSlug]?.contains(lessonSlug) ?? false) else { return }
        completed[courseSlug]?.append(lessonSlug)
        save()
        syncToServer(courseSlug: courseSlug, lessonSlug: lessonSlug)
    }

    // MARK: - Persistence

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([String: [String]].self, from: data) else { return }
        completed = decoded
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(completed) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }

    // MARK: - Server Sync

    func syncAllToServer() async {
        var items: [[String: String]] = []
        for (course, lessons) in completed {
            for lesson in lessons {
                items.append(["courseSlug": course, "lessonSlug": lesson])
            }
        }
        guard !items.isEmpty else { return }

        guard let url = URL(string: "https://likeone.ai/api/v1/progress/sync"),
              let body = try? JSONSerialization.data(withJSONObject: items) else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body

        _ = try? await URLSession.shared.data(for: request)
    }

    func loadFromServer() async {
        guard let url = URL(string: "https://likeone.ai/api/v1/progress/all") else { return }
        guard let (data, response) = try? await URLSession.shared.data(from: url),
              (response as? HTTPURLResponse)?.statusCode == 200,
              let serverProgress = try? JSONDecoder().decode([String: [String]].self, from: data) else { return }

        // Merge server into local
        var merged = false
        for (course, lessons) in serverProgress {
            if completed[course] == nil { completed[course] = [] }
            for lesson in lessons {
                if !(completed[course]?.contains(lesson) ?? false) {
                    completed[course]?.append(lesson)
                    merged = true
                }
            }
        }
        if merged { save() }
    }

    private func syncToServer(courseSlug: String, lessonSlug: String) {
        Task {
            guard let url = URL(string: "https://likeone.ai/api/v1/progress/complete") else { return }
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            let body = ["courseSlug": courseSlug, "lessonSlug": lessonSlug]
            request.httpBody = try? JSONEncoder().encode(body)
            _ = try? await URLSession.shared.data(for: request)
        }
    }
}
