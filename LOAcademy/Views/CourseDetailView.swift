import SwiftUI
import LOCore
import LOContent
import LODesign

struct CourseDetailView: View {
    let course: Course
    @EnvironmentObject var academy: AcademyViewModel
    @EnvironmentObject var progress: ProgressViewModel

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text(course.emoji)
                        .font(.system(size: 48))
                    Text(course.description)
                        .font(.subheadline)
                        .foregroundStyle(Color.loTextSecondary)

                    let lessons = academy.lessons(for: course.slug)
                    let done = progress.completedCount(for: course.slug)
                    if done > 0 {
                        ProgressView(value: Double(done), total: Double(max(lessons.count, 1)))
                            .tint(done >= lessons.count ? .green : Color.loPurple400)
                        Text("\(done) of \(lessons.count) complete")
                            .font(.caption)
                            .foregroundStyle(Color.loTextMuted)
                    }
                }
                .listRowBackground(Color.loBgCard)
            }

            Section("Lessons") {
                ForEach(academy.lessons(for: course.slug), id: \.slug) { lesson in
                    let isFree = academy.isLessonFree(lesson)
                    let isDone = progress.isCompleted(courseSlug: course.slug, lessonSlug: lesson.slug)

                    NavigationLink {
                        if isFree {
                            LessonView(courseSlug: course.slug, lesson: lesson)
                        } else {
                            PaywallView()
                        }
                    } label: {
                        HStack {
                            Text("\(lesson.order)")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundStyle(Color.loTextMuted)
                                .frame(width: 24)

                            Text(lesson.title)
                                .font(.body)
                                .foregroundStyle(Color.loTextPrimary)

                            Spacer()

                            if isDone {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                            } else if isFree {
                                Text("Free")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.green)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(.green.opacity(0.1))
                                    .clipShape(Capsule())
                            } else {
                                Image(systemName: "lock.fill")
                                    .font(.caption)
                                    .foregroundStyle(Color.loTextMuted)
                            }
                        }
                    }
                    .listRowBackground(Color.loBgCard)
                }
            }
        }
        .navigationTitle(course.title)
        .scrollContentBackground(.hidden)
        .background(Color.loBgDark)
    }
}
