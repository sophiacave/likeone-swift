import SwiftUI
import LOCore
import LODesign

struct TrackListView: View {
    @EnvironmentObject var academy: AcademyViewModel
    @EnvironmentObject var progress: ProgressViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(academy.tracks) { track in
                        NavigationLink(value: track) {
                            TrackCard(track: track, progress: progress, academy: academy)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
            .navigationTitle("Learning Tracks")
            .navigationDestination(for: LearningTrack.self) { track in
                TrackDetailView(track: track)
            }
            .background(Color.loBgDark)
        }
    }
}

struct TrackCard: View {
    let track: LearningTrack
    let progress: ProgressViewModel
    let academy: AcademyViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(track.emoji)
                    .font(.system(size: 32))
                Spacer()
                Text(track.difficulty)
                    .font(.caption2)
                    .fontWeight(.bold)
                    .textCase(.uppercase)
                    .foregroundStyle(Color.loTextMuted)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.05))
                    .clipShape(Capsule())
            }

            Text(track.title)
                .font(.headline)
                .foregroundStyle(Color.loTextPrimary)

            Text(track.description)
                .font(.caption)
                .foregroundStyle(Color.loTextSecondary)
                .lineLimit(2)

            HStack {
                Text("\(track.courses.count) courses")
                    .font(.caption2)
                    .foregroundStyle(Color.loTextMuted)
                Text("~\(track.estimatedHours)h")
                    .font(.caption2)
                    .foregroundStyle(Color.loTextMuted)
            }

            // Progress bar
            let pct = trackProgress
            ProgressView(value: pct)
                .tint(pct >= 1.0 ? .green : Color(hex: track.badgeColor))
        }
        .padding(16)
        .background(Color.loBgCard)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.loBorder, lineWidth: 1)
        )
    }

    var trackProgress: Double {
        var totalLessons = 0
        var totalDone = 0
        for courseSlug in track.courses {
            let count = academy.lessonCount(for: courseSlug)
            totalLessons += count
            totalDone += progress.completedCount(for: courseSlug)
        }
        return totalLessons > 0 ? Double(totalDone) / Double(totalLessons) : 0
    }
}
