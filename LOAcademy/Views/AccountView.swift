import SwiftUI
import LODesign

struct AccountView: View {
    @EnvironmentObject var progress: ProgressViewModel
    @EnvironmentObject var auth: AuthService

    var body: some View {
        NavigationStack {
            List {
                if auth.isSignedIn {
                    signedInSection
                } else {
                    signInSection
                }

                progressSection

                aboutSection
            }
            .navigationTitle("Account")
            .scrollContentBackground(.hidden)
            .background(Color.loBgDark)
        }
    }

    // MARK: - Signed In

    private var signedInSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.title)
                        .foregroundStyle(Color.loPurple400)
                    VStack(alignment: .leading) {
                        Text(auth.email ?? "Academy Member")
                            .font(.headline)
                            .foregroundStyle(Color.loTextPrimary)
                        Text(auth.isPro ? "Academy Pro" : "Free Plan")
                            .font(.subheadline)
                            .foregroundStyle(auth.isPro ? Color.loPurple400 : Color.loTextMuted)
                    }
                }
            }
            .listRowBackground(Color.loBgCard)

            Button(role: .destructive) {
                auth.signOut()
            } label: {
                Label("Sign Out", systemImage: "arrow.right.square")
            }
            .listRowBackground(Color.loBgCard)
        }
    }

    // MARK: - Sign In

    private var signInSection: some View {
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
                auth.signInWithApple()
            } label: {
                Label("Sign in with Apple", systemImage: "apple.logo")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.white)
            .foregroundStyle(.black)
            .listRowBackground(Color.loBgCard)
        }
    }

    // MARK: - Progress

    private var progressSection: some View {
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

            if !auth.isPro {
                Link(destination: URL(string: "https://likeone.ai/pricing")!) {
                    Label("Upgrade to Pro", systemImage: "star.fill")
                        .foregroundStyle(Color.loPurple400)
                }
                .listRowBackground(Color.loBgCard)
            }

            Link(destination: URL(string: "https://likeone.ai/account")!) {
                Label("Manage Account on Web", systemImage: "globe")
                    .foregroundStyle(Color.loPurple400)
            }
            .listRowBackground(Color.loBgCard)
        }
    }

    // MARK: - About

    private var aboutSection: some View {
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
}
