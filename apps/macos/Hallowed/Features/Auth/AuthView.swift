import SwiftUI

struct AuthView: View {

    @EnvironmentObject var appEnv: AppEnvironment

    @State private var email: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil
    @State private var magicLinkSent: Bool = false

    private var displayedError: String? {
        errorMessage ?? appEnv.authCallbackError
    }

    var body: some View {
        ZStack {
            HallowedExperimentalBackground()

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 12) {
                    Text("Hallowed")
                        .font(.system(size: 48, weight: .semibold, design: .serif))
                        .foregroundColor(HallowedDesign.Experimental.text)

                    Text("A daily place to pray")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(HallowedDesign.Experimental.muted)
                }

                Spacer().frame(height: 52)

                // Auth card
                VStack(spacing: 24) {

                    // Google sign-in
                    Button(action: signInWithGoogle) {
                        Text("Sign in with Google")
                            .font(.system(size: 15, weight: .medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(HallowedDesign.Experimental.glassStrong)
                        .foregroundColor(HallowedDesign.Experimental.text)
                        .clipShape(RoundedRectangle(cornerRadius: HallowedDesign.Radius.md))
                        .overlay(
                            RoundedRectangle(cornerRadius: HallowedDesign.Radius.md)
                                .stroke(HallowedDesign.Experimental.line, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(isLoading)

                    // Divider
                    HStack(spacing: 12) {
                        Rectangle()
                            .fill(HallowedDesign.Experimental.line)
                            .frame(height: 1)
                        Text("or")
                            .font(.system(size: 12))
                            .foregroundColor(HallowedDesign.Experimental.faint)
                        Rectangle()
                            .fill(HallowedDesign.Experimental.line)
                            .frame(height: 1)
                    }

                    // Magic link
                    if magicLinkSent {
                        VStack(spacing: 8) {
                            Text("Check your email")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(HallowedDesign.Experimental.text)
                            Text("We sent a sign-in link to \(email)")
                                .font(.system(size: 13))
                                .foregroundColor(HallowedDesign.Experimental.muted)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.vertical, 8)
                    } else {
                        VStack(spacing: 12) {
                            TextField("Email address", text: $email)
                                .textFieldStyle(.plain)
                                .font(.system(size: 14))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 11)
                                .background(HallowedDesign.Experimental.glassStrong)
                                .clipShape(RoundedRectangle(cornerRadius: HallowedDesign.Radius.md))
                                .overlay(
                                    RoundedRectangle(cornerRadius: HallowedDesign.Radius.md)
                                        .stroke(HallowedDesign.Experimental.line, lineWidth: 1)
                                )
                                .onSubmit(sendMagicLink)

                            Button(action: sendMagicLink) {
                                Group {
                                    if isLoading {
                                        ProgressView()
                                            .controlSize(.small)
                                    } else {
                                        Text("Send Magic Link")
                                            .font(.system(size: 15, weight: .medium))
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    LinearGradient(
                                        colors: [HallowedDesign.Experimental.amber, Color(hex: "A15F26")],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .foregroundColor(.white)
                                .clipShape(RoundedRectangle(cornerRadius: HallowedDesign.Radius.md))
                            }
                            .buttonStyle(.plain)
                            .disabled(email.trimmingCharacters(in: .whitespaces).isEmpty || isLoading)
                        }
                    }

                    // Error message
                    if let displayedError {
                        Text(displayedError)
                            .font(.system(size: 13))
                            .foregroundColor(HallowedDesign.Experimental.rose)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(32)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(HallowedDesign.Experimental.glass)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                        .shadow(color: Color.black.opacity(0.18), radius: 24, x: 0, y: 12)
                )
                .frame(maxWidth: 360)

                Spacer()

                // Footer
                Text("By signing in, you agree to pray daily.")
                    .font(.system(size: 11))
                    .foregroundColor(HallowedDesign.Experimental.faint)
                    .padding(.bottom, 24)
            }
            .padding(.horizontal, 32)
        }
    }

    // MARK: - Actions

    private func signInWithGoogle() {
        isLoading = true
        errorMessage = nil
        Task {
            do {
                try await appEnv.supabaseService.signInWithGoogle()
            } catch {
                errorMessage = UserFacingError.message(for: error)
            }
            isLoading = false
        }
    }

    private func sendMagicLink() {
        let trimmedEmail = email.trimmingCharacters(in: .whitespaces)
        guard !trimmedEmail.isEmpty else { return }
        isLoading = true
        errorMessage = nil
        Task {
            do {
                try await appEnv.supabaseService.signInWithMagicLink(email: trimmedEmail)
                magicLinkSent = true
            } catch {
                errorMessage = UserFacingError.message(for: error)
            }
            isLoading = false
        }
    }
}

#Preview {
    AuthView()
        .environmentObject(AppEnvironment())
        .frame(width: 800, height: 600)
}
