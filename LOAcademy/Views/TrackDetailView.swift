import SwiftUI
import LOCore
import LODesign

struct TrackDetailView: View {
    let track: LearningTrack
    @EnvironmentObject var academy: AcademyViewModel
    @EnvironmentObject var progress: ProgressViewModel

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text(track.emoji)
                        .font(.system(size: 48))
                    Text(track.description)
                        .font(.subheadline)
                        .foregroundStyle(Color.loTextSecondary)
                    HStack {
                        Text("\(track.courses.count) courses")
                            .font(.caption)
                            .foregroundStyle(Color.loTextMuted)
                        Text("~\(track.estimatedHours) hours")
                            .font(.caption)
                            .foregroundStyle(Color.loTextMuted)
                    }
                }
                .listRowBackground(Color.loBgCard)
            }

            Section("Courses") {
                ForEach(Array(track.courses.enumerated()), id: \.element) { index, courseSlug in
                    if let course = academy.courses.first(where: { $0.slug == courseSlug }) {
                        let total = academy.lessonCount(for: courseSlug)
                        let done = progress.completedCount(for: courseSlug)
                        let isComplete = done >= total && total > 0

                        NavigationLink {
                            CourseDetailView(course: course)
                        } label: {
                            HStack {
                                Text("\(index + 1)")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundStyle(Color.loTextMuted)
                                    .frame(width: 24)

                                Text(course.emoji)
                                Text(course.title)
                                    .foregroundStyle(Color.loTextPrimary)

                                Spacer()

                                if isComplete {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.green)
                                } else if done > 0 {
                                    Text("\(Int(Double(done) / Double(total) * 100))%")
                                        .font(.caption2)
                                        .foregroundStyle(Color.loTextMuted)
                                }
                            }
                        }
                        .listRowBackground(Color.loBgCard)
                    }
                }
            }
        }
        .navigationTitle(track.title)
        .scrollContentBackground(.hidden)
        .background(Color.loBgDark)
    }
}
