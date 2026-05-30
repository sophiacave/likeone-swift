import SwiftUI
import LODesign

struct AccountView: View {
    @EnvironmentObject var progress: ProgressViewModel

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Like One Academy")
                            .font(.headline)
                            .foregroundStyle(Color.loTextPrimary)
                        Text("Sign in to sync progress across devices, earn certificates, and manage your subscription.")
                            .font(.subheadline)
                            .foregroundStyle(Color.loTextSecondary)
                    }
                    .listRowBackground(Color.loBgCard)

                    Button {
                        // TODO: Sign in with Apple
                    } label: {
                        Label("Sign in with Apple", systemImage: "apple.logo")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.white)
                    .foregroundStyle(.black)
                    .listRowBackground(Color.loBgCard)
                }

                Section("Progress") {
                    let courseCount = progress.completed.count
                    let lessonCount = progress.completed.values.reduce(0) { $0 + $1.count }

                    HStack {
                        Label("\(courseCount) courses started", systemImage: "book.fill")
                            .foregroundStyle(Color.loTextSecondary)
                        Spacer()
                        Text("\(lessonCount) lessons")
                            .foregroundStyle(Color.loTextMuted)
                    }
                    .listRowBackground(Color.loBgCard)

                    Link(destination: URL(string: "https://likeone.ai/pricing")!) {
                        Label("Upgrade to Pro", systemImage: "star.fill")
                            .foregroundStyle(Color.loPurple400)
                    }
                    .listRowBackground(Color.loBgCard)

                    Link(destination: URL(string: "https://likeone.ai/account")!) {
                        Label("Manage Account on Web", systemImage: "globe")
                            .foregroundStyle(Color.loPurple400)
                    }
                    .listRowBackground(Color.loBgCard)
                }

                Section("About") {
                    Link(destination: URL(string: "https://likeone.ai/about")!) {
                        Label("About Like One", systemImage: "info.circle")
                    }
                    .listRowBackground(Color.loBgCard)
                    Link(destination: URL(string: "https://likeone.ai/foundation")!) {
                        Label("Foundation", systemImage: "heart.fill")
                    }
                    .listRowBackground(Color.loBgCard)
                    Link(destination: URL(string: "https://likeone.ai/privacy")!) {
                        Label("Privacy Policy", systemImage: "hand.raised.fill")
                    }
                    .listRowBackground(Color.loBgCard)
                    Link(destination: URL(string: "https://likeone.ai/terms")!) {
                        Label("Terms of Service", systemImage: "doc.text")
                    }
                    .listRowBackground(Color.loBgCard)
                }
            }
            .navigationTitle("Account")
            .scrollContentBackground(.hidden)
            .background(Color.loBgDark)
        }
    }
}
