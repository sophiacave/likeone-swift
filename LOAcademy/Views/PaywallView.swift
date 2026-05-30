import SwiftUI
import LODesign

struct PaywallView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "lock.fill")
                .font(.system(size: 48))
                .foregroundStyle(Color.loTextMuted)

            Text("This lesson requires Pro")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(Color.loTextPrimary)

            Text("The first 3 lessons in every course are free. Upgrade to Pro to unlock all 520+ lessons and earn verified certificates.")
                .font(.subheadline)
                .foregroundStyle(Color.loTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Link(destination: URL(string: "https://likeone.ai/pricing")!) {
                Text("Upgrade to Pro — $19/mo")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 14)
                    .background(Color.loPurple400)
                    .clipShape(Capsule())
            }

            Button("Go Back") {
                dismiss()
            }
            .foregroundStyle(Color.loTextMuted)

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background(Color.loBgDark)
    }
}
