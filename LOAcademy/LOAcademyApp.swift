import SwiftUI
import LOCore
import LOContent
import LODesign

@main
struct LOAcademyApp: App {
    @StateObject private var academy = AcademyViewModel()
    @StateObject private var progress = ProgressViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(academy)
                .environmentObject(progress)
                .preferredColorScheme(.dark)
        }
    }
}

struct ContentView: View {
    var body: some View {
        TabView {
            CourseListView()
                .tabItem {
                    Label("Learn", systemImage: "book.fill")
                }

            TrackListView()
                .tabItem {
                    Label("Tracks", systemImage: "map.fill")
                }

            AccountView()
                .tabItem {
                    Label("Account", systemImage: "person.fill")
                }
        }
        .tint(Color.loPurple400)
    }
}
