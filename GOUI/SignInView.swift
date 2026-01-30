import AuthenticationServices
import SwiftUI

struct SignInView: View {
    @EnvironmentObject var authManager: AuthManager

    var allowDemo: () -> Void

    var body: some View {
        ZStack {
            GoStatsTheme.bg.ignoresSafeArea()

            VStack(spacing: 20) {
                VStack(spacing: 6) {
                    Text("Sign in to GoStats")
                        .font(.system(size: 20, weight: .semibold))
                    Text("Sync teams, share with coaches, and unlock recruiter access.")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(GoStatsTheme.text2)
                        .multilineTextAlignment(.center)
                }

                SignInWithAppleButton(.signIn) { _ in
                } onCompletion: { _ in
                }
                .frame(height: 48)
                .overlay {
                    Button {
                        Task { await authManager.signIn() }
                    } label: {
                        Color.clear
                    }
                }

                if authManager.isSigningIn {
                    ProgressView("Signing in...")
                        .font(.system(size: 12, weight: .medium))
                }

                if let message = authManager.lastErrorMessage {
                    Text(message)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                #if DEBUG
                Button("Browse demo") {
                    allowDemo()
                }
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(GoStatsTheme.text2)
                #endif
            }
            .padding(24)
        }
    }
}
