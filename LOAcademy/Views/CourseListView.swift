import SwiftUI
import LOCore
import LODesign

struct CourseListView: View {
    @EnvironmentObject var academy: AcademyViewModel
    @EnvironmentObject var progress: ProgressViewModel
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(filteredCourses) { course in
                        NavigationLink(value: course) {
                            CourseCard(course: course, completedCount: progress.completedCount(for: course.slug), totalLessons: academy.lessonCount(for: course.slug))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
            .navigationTitle("Academy")
            .searchable(text: $searchText, prompt: "Search courses")
            .navigationDestination(for: Course.self) { course in
                CourseDetailView(course: course)
            }
            .background(Color.loBgDark)
        }
    }

    var filteredCourses: [Course] {
        if searchText.isEmpty { return academy.courses }
        let q = searchText.lowercased()
        return academy.courses.filter {
            $0.title.lowercased().contains(q) ||
            $0.description.lowercased().contains(q)
        }
    }
}

struct CourseCard: View {
    let course: Course
    let completedCount: Int
    let totalLessons: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(course.emoji)
                .font(.system(size: 32))

            Text(course.title)
                .font(.headline)
                .foregroundStyle(Color.loTextPrimary)
                .lineLimit(2)

            Text(course.description)
                .font(.caption)
                .foregroundStyle(Color.loTextSecondary)
                .lineLimit(2)

            Spacer()

            HStack {
                Text(course.level.tierName)
                    .font(.caption2)
                    .fontWeight(.bold)
                    .textCase(.uppercase)
                    .foregroundStyle(Color.loPurple400)

                Spacer()

                Text("\(totalLessons) lessons")
                    .font(.caption2)
                    .foregroundStyle(Color.loTextMuted)
            }

            if completedCount > 0 {
                ProgressView(value: Double(completedCount), total: Double(max(totalLessons, 1)))
                    .tint(completedCount >= totalLessons ? .green : Color.loPurple400)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.loBgCard)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.loBorder, lineWidth: 1)
        )
    }
}
