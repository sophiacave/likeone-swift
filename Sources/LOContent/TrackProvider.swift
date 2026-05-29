import Foundation
import LOCore

public struct TrackProvider: Sendable {
    private let tracks: [LearningTrack]

    public init() {
        self.tracks = Self.loadTracks()
    }

    public func allTracks() -> [LearningTrack] { tracks }

    public func track(bySlug slug: String) -> LearningTrack? {
        tracks.first { $0.slug == slug }
    }

    public func tracks(forDifficulty difficulty: String) -> [LearningTrack] {
        tracks.filter { $0.difficulty == difficulty }
    }

    private static func loadTracks() -> [LearningTrack] {
        guard let url = Bundle.module.url(forResource: "tracks", withExtension: "json", subdirectory: "Data"),
              let data = try? Data(contentsOf: url),
              let raw = try? JSONDecoder().decode([RawTrack].self, from: data) else {
            return []
        }
        return raw.map { t in
            LearningTrack(
                slug: t.slug,
                title: t.title,
                description: t.description,
                emoji: t.emoji,
                courses: t.courses,
                estimatedHours: t.estimatedHours,
                difficulty: t.difficulty,
                badgeColor: t.badgeColor
            )
        }
    }
}

private struct RawTrack: Codable {
    let slug: String
    let title: String
    let description: String
    let emoji: String
    let courses: [String]
    let estimatedHours: Int
    let difficulty: String
    let badgeColor: String
}
