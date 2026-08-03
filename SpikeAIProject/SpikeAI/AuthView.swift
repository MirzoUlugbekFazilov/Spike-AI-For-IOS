//
//  AuthView.swift
//  Spike AI
//

import SwiftUI
import AuthenticationServices
import CryptoKit

/// Helper to trigger Apple Sign In programmatically with a custom button.
private class AppleSignInCoordinator: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    var onCompletion: ((Result<ASAuthorization, Error>) -> Void)?
    private var activeController: ASAuthorizationController?

    /// The raw nonce used for the current sign-in attempt (passed to Supabase).
    private(set) var currentNonce: String?

    func performSignIn() {
        let nonce = Self.randomNonceString()
        currentNonce = nonce
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.email, .fullName]
        request.nonce = Self.sha256(nonce)
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        activeController = controller
        controller.performRequests()
    }

    private static func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess { fatalError("Unable to generate nonce.") }
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        return String(randomBytes.map { charset[Int($0) % charset.count] })
    }

    private static func sha256(_ input: String) -> String {
        let hashed = SHA256.hash(data: Data(input.utf8))
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        activeController = nil
        onCompletion?(.success(authorization))
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        activeController = nil
        onCompletion?(.failure(error))
    }

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow) ?? ASPresentationAnchor()
    }
}

struct AuthView: View {
    var authManager: AuthManager
    @Environment(AppLocalization.self) private var loc
    @Environment(\.colorScheme) private var colorScheme

    private var isLight: Bool { colorScheme == .light }

    // MARK: - Adaptive palette
    /// Primary text (Spike AI title, button labels on light surfaces)
    private var titleColor: Color {
        isLight ? Color(red: 0.07, green: 0.09, blue: 0.13) : .white
    }
    /// Subtitle / secondary copy
    private var subtitleColor: Color {
        isLight ? Color(red: 0.40, green: 0.44, blue: 0.50) : .white.opacity(0.62)
    }
    /// Filled CTA (Apple button) background
    private var primaryFill: Color {
        isLight ? .black : Color.white.opacity(0.08)
    }
    /// Filled CTA border (visible only in dark mode)
    private var primaryStroke: Color {
        isLight ? .clear : Color.white.opacity(0.22)
    }
    /// Filled CTA text/icon color (white in both modes for Apple)
    private var primaryText: Color { .white }
    /// Outlined CTA (Google / Email) background
    private var secondaryFill: Color {
        isLight ? .white : Color.white.opacity(0.08)
    }
    /// Outlined CTA border
    private var secondaryStroke: Color {
        isLight ? Color(red: 0.83, green: 0.85, blue: 0.89) : Color.white.opacity(0.22)
    }
    /// Outlined CTA text / icon color
    private var secondaryText: Color {
        isLight ? Color(red: 0.07, green: 0.09, blue: 0.13) : .white
    }
    /// Soft shadow for cards on light backgrounds; none in dark
    private var lightCardShadow: Color {
        isLight ? Color.black.opacity(0.06) : .clear
    }
    /// Email field background
    private var fieldBackground: Color {
        isLight ? Color(red: 0.95, green: 0.96, blue: 0.97) : Color.white.opacity(0.08)
    }
    /// Email field border
    private var fieldBorder: Color {
        isLight ? Color(red: 0.86, green: 0.88, blue: 0.91) : Color.white.opacity(0.18)
    }
    /// Continue button (email screen) fill — dark in light mode, white in dark
    private var continueFill: Color {
        isLight ? .black : .white
    }
    /// Continue button text color
    private var continueText: Color {
        isLight ? .white : .black
    }
    /// Disabled continue button fill
    private var continueDisabledFill: Color {
        isLight ? Color.black.opacity(0.25) : Color.white.opacity(0.40)
    }

    enum AuthScreen { case main, email, checkEmail }
    enum AuthLegalDocument: String, Identifiable {
        case terms
        case privacy

        var id: String { rawValue }
    }

    @State private var screen: AuthScreen = .main
    @State private var email = ""
    @State private var isLoading = false
    @State private var isGoogleLoading = false
    @State private var errorMsg = ""
    @State private var appleCoordinator = AppleSignInCoordinator()
    @State private var resendCooldown = 0
    @State private var resendSuccess = false
    @State private var showMailOptions = false
    @State private var cooldownTask: Task<Void, Never>?
    @State private var legalDocument: AuthLegalDocument?

    private var isWide: Bool { DeviceLayout.isPad }

    // Animation states
    @State private var logoScale: CGFloat = 0.5
    @State private var buttonsOffset: CGFloat = 40
    @State private var buttonsOpacity: Double = 0
    @State private var viewBounce: CGFloat = 0.95

    var body: some View {
        ZStack {
            SpikeGradientBackground()

            switch screen {
            case .main:
                mainView
            case .email:
                emailView
            case .checkEmail:
                checkEmailView
            }
        }
        .sheet(item: $legalDocument) { document in
            NavigationStack {
                LegalDetailView(title: legalTitle(for: document), bodyText: legalBody(for: document))
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button(loc["done"]) { legalDocument = nil }
                        }
                    }
            }
        }
    }

    private func legalTitle(for document: AuthLegalDocument) -> String {
        switch document {
        case .terms: loc["terms_of_service"]
        case .privacy: loc["privacy_policy"]
        }
    }

    private func legalBody(for document: AuthLegalDocument) -> String {
        switch document {
        case .terms: loc["terms_body"]
        case .privacy: loc["privacy_body"]
        }
    }

    // MARK: - Main Screen

    private var mainView: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: isWide ? 18 : 14) {
                Image("SpikeLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: isWide ? 100 : 80, height: isWide ? 100 : 80)
                    .scaleEffect(logoScale)
                    .onAppear {
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.6, blendDuration: 0)) {
                            logoScale = 1.0
                        }
                    }
                Text(loc["spike_ai"])
                    .font(.system(size: isWide ? 48 : 40, weight: .bold))
                    .foregroundStyle(titleColor)
                Text(loc["productivity_system"])
                    .font(isWide ? .body : .subheadline)
                    .foregroundColor(subtitleColor)
            }
            .padding(.bottom, isWide ? 80 : 60)

            VStack(spacing: 14) {
                // Auth buttons constrained for iPad readability
                // Apple — custom button with same styling as others
                Button {
                    appleCoordinator.onCompletion = { result in
                        handleAppleSignIn(result: result)
                    }
                    appleCoordinator.performSignIn()
                } label: {
                    HStack(spacing: 14) {
                        Image(systemName: "apple.logo")
                            .font(.system(size: 22, weight: .medium))
                            .foregroundColor(primaryText)
                        Text(loc["continue_apple"])
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(primaryText)
                    }
                    .frame(maxWidth: .infinity, minHeight: 56)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(primaryFill)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(primaryStroke, lineWidth: 1)
                    )
                    .shadow(color: lightCardShadow, radius: 10, x: 0, y: 4)
                    .contentShape(RoundedRectangle(cornerRadius: 14))
                }
                .offset(y: buttonsOffset)
                .opacity(buttonsOpacity)

                // Google — outlined button with real logo
                Button {
                    handleGoogleSignIn()
                } label: {
                    HStack(spacing: 14) {
                        if isGoogleLoading {
                            ProgressView()
                                .controlSize(.small)
                                .tint(secondaryText)
                        } else {
                            Image("GoogleLogo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 22, height: 22)
                        }
                        Text(loc["continue_google"])
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(secondaryText)
                    }
                    .frame(maxWidth: .infinity, minHeight: 56)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(secondaryFill)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(secondaryStroke, lineWidth: 1)
                    )
                    .shadow(color: lightCardShadow, radius: 10, x: 0, y: 4)
                    .contentShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(isGoogleLoading)
                .offset(y: buttonsOffset)
                .opacity(buttonsOpacity)

                // Email — outlined button
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        screen = .email
                        errorMsg = ""
                    }
                } label: {
                    HStack(spacing: 14) {
                        Image(systemName: "envelope.fill")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(secondaryText)
                        Text(loc["continue_email"])
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(secondaryText)
                    }
                    .frame(maxWidth: .infinity, minHeight: 56)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(secondaryFill)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(secondaryStroke, lineWidth: 1)
                    )
                    .shadow(color: lightCardShadow, radius: 10, x: 0, y: 4)
                    .contentShape(RoundedRectangle(cornerRadius: 14))
                }
                .offset(y: buttonsOffset)
                .opacity(buttonsOpacity)
            }
            .padding(.horizontal, 24)
            .onAppear {
                withAnimation(.easeOut(duration: 0.5).delay(0.3)) {
                    buttonsOffset = 0
                    buttonsOpacity = 1
                }
            }

            if !errorMsg.isEmpty {
                Text(errorMsg)
                    .font(.caption)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .padding(.top, 12)
            }

            Spacer()

            legalFooter
                .padding(.bottom, 24)
        }
        .iPadReadable(maxWidth: 500)
        .scaleEffect(viewBounce)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7, blendDuration: 0).delay(0.1)) {
                viewBounce = 1.0
            }
        }
    }

    // MARK: - Email Input Screen

    private var emailView: some View {
        VStack(spacing: 0) {
            HStack {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        screen = .main
                        errorMsg = ""
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.top, 4)

            VStack(alignment: .leading, spacing: 8) {
                Text(loc["enter_email"])
                    .font(.system(size: 28, weight: .bold))
                Text(loc["send_sign_in_link"])
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.top, 12)

            TextField("name@example.com", text: $email)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .keyboardType(.emailAddress)
                .font(.system(size: 17))
                .foregroundColor(titleColor)
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(fieldBackground)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(fieldBorder, lineWidth: 1)
                )
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .onChange(of: email) {
                    email = normalizedEmail(email)
                }

            if !errorMsg.isEmpty {
                Text(errorMsg)
                    .font(.caption)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .padding(.top, 12)
            }

            Button {
                handleSendMagicLink()
            } label: {
                Group {
                    if isLoading {
                        ProgressView()
                            .tint(continueText)
                    } else {
                        Text(loc["continue_btn"])
                            .font(.body.weight(.semibold))
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 52)
                .foregroundColor(continueText)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(email.isEmpty ? continueDisabledFill : continueFill)
                )
                .shadow(color: email.isEmpty ? .clear : lightCardShadow, radius: 10, x: 0, y: 4)
                .contentShape(RoundedRectangle(cornerRadius: 14))
            }
            .disabled(email.isEmpty || isLoading)
            .padding(.horizontal, 24)
            .padding(.top, 20)

            Spacer()
        }
        .iPadReadable(maxWidth: 480)
    }

    private var legalFooter: some View {
        VStack(spacing: 4) {
            Text(loc["by_continuing"])
                .font(.caption2)
                .foregroundColor(subtitleColor)

            HStack(spacing: 4) {
                Link(loc["terms_of_service"], destination: URL(string: "https://spikeai.tech/terms.html")!)
                Text(loc["and_word"])
                    .foregroundColor(subtitleColor)
                Link(loc["privacy_policy"], destination: URL(string: "https://spikeai.tech/privacy.html")!)
            }
            .font(.caption2.weight(.semibold))
            .foregroundColor(isLight ? Color(red: 0.20, green: 0.22, blue: 0.28) : .white.opacity(0.8))
        }
        .multilineTextAlignment(.center)
        .padding(.horizontal, 24)
    }

    // MARK: - Check Your Email Screen

    private var checkEmailView: some View {
        VStack(spacing: 0) {
            HStack {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        screen = .email
                        errorMsg = ""
                        resendSuccess = false
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.top, 4)

            Spacer()

            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(isLight ? Color.black.opacity(0.05) : Color.white.opacity(0.12))
                        .frame(width: 88, height: 88)
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 36))
                        .foregroundColor(isLight ? Color.black.opacity(0.7) : .white.opacity(0.8))
                }

                Text(loc["check_email"])
                    .font(.title2.weight(.bold))
                    .foregroundColor(titleColor)

                Text(loc["sent_link_to"])
                    .font(.subheadline)
                    .foregroundColor(subtitleColor)
                Text(email)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(titleColor)

                Text(loc["tap_link"])
                    .font(.footnote)
                    .foregroundColor(subtitleColor)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            .padding(.bottom, 36)

            Button {
                let availableApps = availableMailApps()
                if availableApps.count == 1, let app = availableApps.first,
                   let url = URL(string: app.urlScheme) {
                    UIApplication.shared.open(url)
                } else {
                    showMailOptions = true
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "envelope.fill")
                    Text(loc["open_mail"])
                        .font(.body.weight(.semibold))
                }
                .frame(maxWidth: .infinity, minHeight: 52)
                .foregroundColor(continueText)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(continueFill)
                )
                .shadow(color: lightCardShadow, radius: 10, x: 0, y: 4)
                .contentShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 24)
            .confirmationDialog(loc["open_with"], isPresented: $showMailOptions, titleVisibility: .visible) {
                ForEach(availableMailApps(), id: \.name) { app in
                    Button(app.name) {
                        if let url = URL(string: app.urlScheme) {
                            UIApplication.shared.open(url)
                        }
                    }
                }
                Button(loc["cancel"], role: .cancel) {}
            }

            if !errorMsg.isEmpty {
                Text(errorMsg)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal, 24)
                    .padding(.top, 12)
            }

            if resendSuccess {
                Text(loc["new_link_sent"])
                    .font(.caption)
                    .foregroundColor(.green)
                    .padding(.top, 12)
            }

            HStack(spacing: 4) {
                Text(loc["didnt_get_email"])
                    .font(.subheadline)
                    .foregroundColor(subtitleColor)
                if resendCooldown > 0 {
                    Text(String(format: loc["resend_in"], resendCooldown))
                        .font(.subheadline)
                        .foregroundColor(subtitleColor)
                } else {
                    Button(loc["resend"]) {
                        handleResend()
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(titleColor)
                }
            }
            .padding(.top, 16)

            Spacer()
        }
        .iPadReadable(maxWidth: 480)
    }

    // MARK: - Actions

    private func handleSendMagicLink() {
        guard isValidEmail(email) else {
            errorMsg = loc["valid_email"]
            return
        }
        isLoading = true; errorMsg = ""
        Task {
            do {
                try await authManager.sendMagicLink(email: email)
                withAnimation(.easeInOut(duration: 0.2)) {
                    screen = .checkEmail
                }
                startResendCooldown()
            } catch {
                errorMsg = error.localizedDescription
            }
            isLoading = false
        }
    }

    private func handleResend() {
        guard resendCooldown == 0 else { return }
        errorMsg = ""; resendSuccess = false
        Task {
            do {
                try await authManager.sendMagicLink(email: email)
                resendSuccess = true
                startResendCooldown()
            } catch {
                errorMsg = error.localizedDescription
            }
        }
    }

    private func handleGoogleSignIn() {
        isGoogleLoading = true; errorMsg = ""
        Task {
            do {
                try await authManager.signInWithGoogle()
                // Auth succeeded — view will go away, cancel cooldown
                cooldownTask?.cancel()
                cooldownTask = nil
            } catch {
                // Suppress user-cancelled errors (CancellationError or
                // ASWebAuthenticationSession canceledLogin code 1)
                let nsError = error as NSError
                let isCancelled = (error is CancellationError) ||
                    (nsError.domain == "com.apple.AuthenticationServices.WebAuthenticationSession" && nsError.code == 1)
                if !isCancelled {
                    errorMsg = error.localizedDescription
                }
            }
            isGoogleLoading = false
        }
    }

    private func handleAppleSignIn(result: Result<ASAuthorization, Error>) {
        errorMsg = ""
        Task {
            do {
                let authorization = try result.get()
                guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                      let idTokenData = credential.identityToken,
                      let idToken = String(data: idTokenData, encoding: .utf8) else {
                    errorMsg = "Could not retrieve Apple credentials."
                    return
                }
                try await authManager.signInWithApple(
                    idToken: idToken,
                    nonce: appleCoordinator.currentNonce,
                    fullName: credential.fullName
                )
                // Auth succeeded — view will go away, cancel cooldown
                cooldownTask?.cancel()
                cooldownTask = nil
            } catch let error as ASAuthorizationError where error.code == .canceled {
                // User dismissed the Apple sign-in dialog — not an error
            } catch {
                // Suppress user-cancelled web auth errors
                let nsError = error as NSError
                let isCancelled = nsError.domain == "com.apple.AuthenticationServices.WebAuthenticationSession" && nsError.code == 1
                if !isCancelled {
                    errorMsg = error.localizedDescription
                }
            }
        }
    }

    private func startResendCooldown() {
        cooldownTask?.cancel()
        resendCooldown = 60
        cooldownTask = Task {
            while !Task.isCancelled && resendCooldown > 0 {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                guard !Task.isCancelled else { break }
                resendCooldown -= 1
            }
        }
    }

    private func normalizedEmail(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private func isValidEmail(_ value: String) -> Bool {
        let parts = value.split(separator: "@")
        guard parts.count == 2,
              let local = parts.first,
              let domain = parts.last,
              !local.isEmpty,
              domain.contains("."),
              !domain.hasPrefix("."),
              !domain.hasSuffix(".") else { return false }
        // Require TLD to be at least 2 characters (e.g. .co minimum)
        guard let tld = domain.split(separator: ".").last,
              tld.count >= 2 else { return false }
        return true
    }

    // MARK: - Mail App Detection

    private struct MailApp {
        let name: String
        let urlScheme: String
    }

    private func availableMailApps() -> [MailApp] {
        let allApps: [MailApp] = [
            MailApp(name: "Mail", urlScheme: "mailto:"),
            MailApp(name: "Gmail", urlScheme: "googlegmail://"),
            MailApp(name: "Outlook", urlScheme: "ms-outlook://"),
        ]
        return allApps.filter { app in
            guard let url = URL(string: app.urlScheme) else { return false }
            return UIApplication.shared.canOpenURL(url)
        }
    }
}
