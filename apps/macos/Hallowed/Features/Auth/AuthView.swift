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
            // Warm off-white background
            Color(hex: "FAF8F5")
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // App icon + wordmark
                VStack(spacing: 16) {
                    Image(systemName: "hands.and.sparkles.fill")
                        .font(.system(size: 52, weight: .light))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(hex: "8B6F4E"), Color(hex: "C49A6C")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    Text("Hallowed")
                        .font(.system(size: 40, weight: .light, design: .serif))
                        .foregroundColor(Color(hex: "2D2420"))

                    Text("A daily place to pray")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(Color(hex: "8B7B6E"))
                }

                Spacer().frame(height: 52)

                // Auth card
                VStack(spacing: 24) {

                    // Google sign-in
                    Button(action: signInWithGoogle) {
                        HStack(spacing: 10) {
                            Image(systemName: "globe")
                                .font(.system(size: 15, weight: .medium))
                            Text("Sign in with Google")
                                .font(.system(size: 15, weight: .medium))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.white)
                        .foregroundColor(Color(hex: "2D2420"))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color(hex: "DDD5CB"), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(isLoading)

                    // Divider
                    HStack(spacing: 12) {
                        Rectangle()
                            .fill(Color(hex: "DDD5CB"))
                            .frame(height: 1)
                        Text("or")
                            .font(.system(size: 12))
                            .foregroundColor(Color(hex: "B0A098"))
                        Rectangle()
                            .fill(Color(hex: "DDD5CB"))
                            .frame(height: 1)
                    }

                    // Magic link
                    if magicLinkSent {
                        VStack(spacing: 8) {
                            Image(systemName: "envelope.badge.fill")
                                .font(.system(size: 24))
                                .foregroundColor(Color(hex: "8B6F4E"))
                            Text("Check your email")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(Color(hex: "2D2420"))
                            Text("We sent a sign-in link to \(email)")
                                .font(.system(size: 13))
                                .foregroundColor(Color(hex: "8B7B6E"))
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
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color(hex: "DDD5CB"), lineWidth: 1)
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
                                        colors: [Color(hex: "8B6F4E"), Color(hex: "7A5F3E")],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .foregroundColor(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                            .buttonStyle(.plain)
                            .disabled(email.trimmingCharacters(in: .whitespaces).isEmpty || isLoading)
                        }
                    }

                    // Error message
                    if let displayedError {
                        Text(displayedError)
                            .font(.system(size: 13))
                            .foregroundColor(Color(red: 0.8, green: 0.2, blue: 0.2))
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(32)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(hex: "FFFFFF").opacity(0.8))
                        .shadow(color: Color(hex: "2D2420").opacity(0.06), radius: 20, x: 0, y: 4)
                )
                .frame(maxWidth: 360)

                Spacer()

                // Footer
                Text("By signing in, you agree to pray daily.")
                    .font(.system(size: 11))
                    .foregroundColor(Color(hex: "B0A098"))
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
