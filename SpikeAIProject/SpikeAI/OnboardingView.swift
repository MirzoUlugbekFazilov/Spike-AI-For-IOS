//
//  OnboardingView.swift
//  Spike AI
//
//  Pre-auth onboarding flow for Spike AI.
//

import SwiftUI

#if os(iOS)
import FamilyControls
#endif

// MARK: - Main View

struct OnboardingView: View {
    @Environment(AuthorizationManager.self) private var stAuth
    @Environment(AppBlockingManager.self) private var blocker
    @State private var vm = OnboardingViewModel()

    var onComplete: () -> Void

    var body: some View {
        ZStack {
            OBColor.background.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Text("\(vm.currentPage + 1)/\(vm.totalPages)")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(OBColor.muted)
                    Spacer()
                    OBProgressDots(current: vm.currentPage, total: vm.totalPages)
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)

                Group {
                    switch vm.currentPage {
                    case 0: LanguagePage(vm: vm, onContinue: advance)
                    case 1: WelcomePage(onContinue: advance)
                    case 2: DidYouKnowPage(onContinue: advance)
                    case 3: SolutionPage(onContinue: advance)
                    case 4: ScreenTimePage(onContinue: advance)
                    case 5: AppSelectionPage(onContinue: advance)
                    case 6: ReadyPage {
                        vm.saveSelections()
                        onComplete()
                    }
                    default: EmptyView()
                    }
                }
                .id(vm.currentPage)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
            }
        }
    }

    private func advance() {
        withAnimation(.spring(response: 0.42, dampingFraction: 0.9)) {
            vm.advance()
        }
    }
}

// MARK: - Screen 0: Language

private struct LanguagePage: View {
    @Environment(AppLocalization.self) private var loc
    @Bindable var vm: OnboardingViewModel
    var onContinue: () -> Void

    private var isWide: Bool { DeviceLayout.isPad }

    var body: some View {
        OBScreen(onContinue: onContinue) {
            Spacer(minLength: isWide ? 20 : 10)

            VStack(spacing: 6) {
                Image(systemName: "globe")
                    .font(.system(size: isWide ? 40 : 32, weight: .medium))
                    .foregroundStyle(OBColor.accent)
                    .padding(.bottom, 4)
                Text(vm.localizedChooseLanguage)
                    .font(.system(size: isWide ? 28 : 22, weight: .bold, design: .rounded))
                    .foregroundStyle(OBColor.ink)
            }
            .padding(.horizontal, 24)

            ScrollView {
                if isWide {
                    // iPad: 2-column grid for language selection
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 8) {
                        ForEach(supportedLanguages) { lang in
                            languageButton(lang)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                } else {
                    LazyVStack(spacing: 6) {
                        ForEach(supportedLanguages) { lang in
                            languageButton(lang)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                }
            }

            Spacer(minLength: 4)
        }
        .onAppear {
            if loc.language != vm.selectedLanguage {
                loc.language = vm.selectedLanguage
            }
        }
    }

    private func languageButton(_ lang: AppLanguage) -> some View {
        let selected = vm.selectedLanguage == lang.id
        return Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                vm.selectedLanguage = lang.id
                loc.language = lang.id
            }
        } label: {
            HStack(spacing: 14) {
                Text(lang.flag)
                    .font(.system(size: 24))
                    .frame(width: 36)
                Text(lang.name)
                    .font(.system(size: 16, weight: selected ? .bold : .medium, design: .rounded))
                    .foregroundStyle(OBColor.ink)
                Spacer()
                if selected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(OBColor.accent)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(selected ? OBColor.accent.opacity(0.08) : .white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(selected ? OBColor.accent.opacity(0.3) : .clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Screen 1: Welcome

private struct WelcomePage: View {
    @Environment(AppLocalization.self) private var loc
    @State private var heroScale: CGFloat = 0.85
    @State private var heroOpacity: Double = 0
    @State private var textOpacity: Double = 0
    var onContinue: () -> Void

    private var isWide: Bool { DeviceLayout.isPad }

    var body: some View {
        OBScreen(actionTitle: loc["start_setup"], onContinue: onContinue) {
            if isWide {
                // iPad: side-by-side hero card + text
                Spacer(minLength: 40)

                HStack(spacing: 48) {
                    heroCardView
                        .scaleEffect(heroScale)
                        .opacity(heroOpacity)

                    VStack(spacing: 16) {
                        Text(loc["spike_ai"])
                            .font(.system(size: 48, weight: .black, design: .rounded))
                            .foregroundStyle(OBColor.ink)

                        Text(loc["make_phone_work"])
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(OBColor.ink)
                            .multilineTextAlignment(.center)

                        Text(loc["onboarding_welcome_desc"])
                            .font(.system(size: 17, weight: .medium, design: .rounded))
                            .foregroundStyle(OBColor.secondary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(5)
                    }
                    .frame(maxWidth: .infinity)
                    .opacity(textOpacity)
                }
                .padding(.horizontal, 32)
                .onAppear { runAnimations() }

                Spacer(minLength: 20)
            } else {
                // iPhone: vertical stack
                Spacer(minLength: 14)

                heroCardView
                    .scaleEffect(heroScale)
                    .opacity(heroOpacity)
                    .onAppear { runAnimations() }

                VStack(spacing: 10) {
                    Text(loc["spike_ai"])
                        .font(.system(size: 36, weight: .black, design: .rounded))
                        .foregroundStyle(OBColor.ink)

                    Text(loc["make_phone_work"])
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(OBColor.ink)
                        .multilineTextAlignment(.center)

                    Text(loc["onboarding_welcome_desc"])
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(OBColor.secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                }
                .padding(.horizontal, 28)
                .opacity(textOpacity)

                Spacer(minLength: 10)
            }
        }
    }

    private func runAnimations() {
        withAnimation(.spring(response: 0.7, dampingFraction: 0.7).delay(0.1)) {
            heroScale = 1.0
            heroOpacity = 1
        }
        withAnimation(.easeOut(duration: 0.5).delay(0.4)) {
            textOpacity = 1
        }
    }

    private var heroCardView: some View {
        ZStack {
            Circle()
                .fill(OBColor.accent.opacity(0.06))
                .frame(width: isWide ? 280 : 200, height: isWide ? 280 : 200)
                .blur(radius: 8)

            RoundedRectangle(cornerRadius: 32)
                .fill(.white)
                .frame(width: isWide ? 220 : 156, height: isWide ? 300 : 250)
                .overlay {
                    VStack(spacing: 12) {
                        HStack {
                            Text(loc["today"])
                                .font(.system(size: isWide ? 13 : 11, weight: .bold, design: .rounded))
                                .foregroundStyle(OBColor.muted)
                            Spacer()
                            Image("SpikeLogo")
                                .resizable().scaledToFit()
                                .frame(width: isWide ? 48 : 42, height: isWide ? 48 : 42)
                        }

                        Text(loc["protect_focus"])
                            .font(.system(size: isWide ? 20 : 18, weight: .bold, design: .rounded))
                            .foregroundStyle(OBColor.ink)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        VStack(spacing: 8) {
                            OBHeroRow(text: loc["block_feeds"], color: OBColor.red)
                            OBHeroRow(text: loc["finish_tasks"], color: OBColor.accent)
                            OBHeroRow(text: loc["energy_plus_three"], color: .orange)
                        }
                    }
                    .padding(isWide ? 18 : 14)
                }
                .shadow(color: .black.opacity(0.10), radius: 24, x: 0, y: 12)
        }
        .frame(height: isWide ? 320 : 270)
    }
}

// MARK: - Screen 2: Did You Know (Animated Counter)

private struct DidYouKnowPage: View {
    @Environment(AppLocalization.self) private var loc
    var onContinue: () -> Void

    private var isWide: Bool { DeviceLayout.isPad }

    @State private var showMonths = false
    @State private var showDays = false
    @State private var showYears = false
    @State private var showSubtitle = false

    var body: some View {
        OBScreen(onContinue: onContinue) {
            Spacer()

            VStack(spacing: isWide ? 8 : 4) {
                Text(loc["did_you_know"])
                    .font(.system(size: isWide ? 36 : 28, weight: .black, design: .rounded))
                    .foregroundStyle(OBColor.ink)
                Text(loc["did_you_know_subtitle"])
                    .font(.system(size: isWide ? 18 : 15, weight: .medium, design: .rounded))
                    .foregroundStyle(OBColor.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, isWide ? 16 : 10)

            VStack(spacing: 0) {
                if showMonths {
                    CountStatRow(target: 9, label: loc["days_per_month"], duration: 0.7)
                        .transition(.opacity.combined(with: .scale(scale: 0.8)))
                }

                if showDays {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(OBColor.muted)
                        .padding(.vertical, 5)
                        .transition(.opacity)

                    CountStatRow(target: 108, label: loc["days_per_year"], duration: 1.2)
                        .transition(.opacity.combined(with: .scale(scale: 0.8)))
                }

                if showYears {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(OBColor.muted)
                        .padding(.vertical, 5)
                        .transition(.opacity)

                    CountStatRow(target: 30, label: loc["years_of_life"], duration: 1.0, highlight: true)
                        .transition(.opacity.combined(with: .scale(scale: 0.8)))
                }
            }
            .padding(.horizontal, 30)

            if showSubtitle {
                Text(loc["screen_time_reality"])
                    .font(.system(size: isWide ? 17 : 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(OBColor.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 34)
                    .padding(.top, 16)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }

            Spacer()
        }
        .task {
            try? await Task.sleep(nanoseconds: 400_000_000)
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) { showMonths = true }

            try? await Task.sleep(nanoseconds: 1_200_000_000)
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) { showDays = true }

            try? await Task.sleep(nanoseconds: 1_200_000_000)
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) { showYears = true }

            try? await Task.sleep(nanoseconds: 1_000_000_000)
            withAnimation(.easeOut(duration: 0.5)) { showSubtitle = true }
        }
    }
}

private struct CountStatRow: View {
    let target: Int
    let label: String
    let duration: Double
    var highlight: Bool = false

    var body: some View {
        HStack(spacing: 16) {
            CountUpNumber(target: target, duration: duration)
                .font(.system(size: DeviceLayout.isPad ? 64 : 52, weight: .black, design: .rounded))
                .foregroundStyle(highlight ? OBColor.red : OBColor.accent)
                .monospacedDigit()
                .frame(width: DeviceLayout.isPad ? 140 : 110, alignment: .trailing)

            Text(label)
                .font(.system(size: DeviceLayout.isPad ? 20 : 17, weight: .bold, design: .rounded))
                .foregroundStyle(OBColor.ink)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(obCard(cornerRadius: 20))
    }
}

private struct CountUpNumber: View {
    let target: Int
    let duration: Double
    @State private var current = 0
    @State private var animationTask: Task<Void, Never>?

    var body: some View {
        Text("\(current)")
            .onAppear {
                animationTask = Task {
                    let steps = 30
                    let intervalNanos = UInt64((duration / Double(steps)) * 1_000_000_000)
                    for step in 1...steps {
                        try? await Task.sleep(nanoseconds: intervalNanos)
                        guard !Task.isCancelled else { return }
                        let progress = Double(step) / Double(steps)
                        let eased = 1 - pow(1 - progress, 3)
                        current = Int(Double(target) * eased)
                    }
                }
            }
            .onDisappear {
                animationTask?.cancel()
                animationTask = nil
            }
    }
}

// MARK: - Screen 3: Solution

private struct SolutionPage: View {
    @Environment(AppLocalization.self) private var loc
    @State private var logoScale: CGFloat = 0.6
    @State private var textOpacity: Double = 0
    var onContinue: () -> Void

    private var isWide: Bool { DeviceLayout.isPad }

    var body: some View {
        OBScreen(onContinue: onContinue) {
            Spacer()

            Image("SpikeLogo")
                .resizable().scaledToFit()
                .frame(width: isWide ? 120 : 90, height: isWide ? 120 : 90)
                .scaleEffect(logoScale)
                .onAppear {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.65).delay(0.15)) {
                        logoScale = 1.0
                    }
                    withAnimation(.easeOut(duration: 0.6).delay(0.4)) {
                        textOpacity = 1
                    }
                }

            VStack(spacing: isWide ? 16 : 12) {
                Text(loc["dont_worry_title"])
                    .font(.system(size: isWide ? 40 : 32, weight: .black, design: .rounded))
                    .foregroundStyle(OBColor.ink)

                Text(loc["spike_has_your_back"])
                    .font(.system(size: isWide ? 28 : 22, weight: .bold, design: .rounded))
                    .foregroundStyle(OBColor.accent)

                Text(loc["solution_desc"])
                    .font(.system(size: isWide ? 17 : 15, weight: .medium, design: .rounded))
                    .foregroundStyle(OBColor.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(isWide ? 5 : 4)
                    .padding(.top, 4)
            }
            .padding(.horizontal, 30)
            .opacity(textOpacity)

            Spacer()
        }
    }
}

// MARK: - Screen 4: Screen Time Permission

private struct ScreenTimePage: View {
    @Environment(AuthorizationManager.self) private var stAuth
    @Environment(AppLocalization.self) private var loc
    @State private var isRequesting = false
    @State private var didAutoRequest = false
    var onContinue: () -> Void

    private var isWide: Bool { DeviceLayout.isPad }

    var body: some View {
        OBScreen(
            actionTitle: loc["continue_btn"],
            enabled: stAuth.status == .approved,
            onContinue: onContinue
        ) {
            Spacer()

            VStack(spacing: isWide ? 28 : 20) {
                ZStack {
                    Circle()
                        .fill(OBColor.accent.opacity(0.10))
                        .frame(width: isWide ? 130 : 100, height: isWide ? 130 : 100)
                    Image(systemName: "hourglass")
                        .font(.system(size: isWide ? 56 : 44, weight: .medium))
                        .foregroundStyle(OBColor.accent)
                }

                VStack(spacing: 8) {
                    Text(loc["screen_time_access_title"])
                        .font(.system(size: isWide ? 34 : 28, weight: .black, design: .rounded))
                        .foregroundStyle(OBColor.ink)
                        .multilineTextAlignment(.center)

                    Text(loc["screen_time_permission_desc"])
                        .font(.system(size: isWide ? 17 : 15, weight: .medium, design: .rounded))
                        .foregroundStyle(OBColor.secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                }
                .padding(.horizontal, 28)

                if stAuth.status == .approved {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text(loc["access_granted"] == "access_granted" ? "Access granted" : loc["access_granted"])
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(.green)
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 24)
                    .background(Capsule().fill(.green.opacity(0.10)))
                } else {
                    Button {
                        if stAuth.status == .denied {
                            stAuth.openSettings()
                        } else {
                            isRequesting = true
                            Task {
                                await stAuth.requestAuthorization()
                                stAuth.refreshStatus()
                                isRequesting = false
                            }
                        }
                    } label: {
                        HStack(spacing: 8) {
                            if isRequesting {
                                ProgressView().tint(.white)
                            } else {
                                Image(systemName: stAuth.status == .denied ? "gearshape.fill" : "lock.shield.fill")
                            }
                            Text(stAuth.status == .denied ? loc["open_settings"] : loc["grant_access"])
                        }
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity).frame(height: 54)
                        .background(RoundedRectangle(cornerRadius: 16).fill(OBColor.accent))
                    }
                    .buttonStyle(.plain)
                    .disabled(isRequesting)
                    .padding(.horizontal, 24)

                    Text(loc["apple_screen_time_required"])
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(OBColor.muted)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 30)
                }
            }

            Spacer()
        }
        .onAppear {
            stAuth.refreshStatus()
            // Auto-request permission immediately on appear
            if stAuth.status == .notDetermined && !didAutoRequest {
                didAutoRequest = true
                isRequesting = true
                Task {
                    await stAuth.requestAuthorization()
                    stAuth.refreshStatus()
                    isRequesting = false
                }
            }
        }
    }
}

// MARK: - Screen 5: App Selection

private struct AppSelectionPage: View {
    @Environment(AuthorizationManager.self) private var stAuth
    @Environment(AppBlockingManager.self) private var blocker
    @Environment(\.scenePhase) private var scenePhase
    @Environment(AppLocalization.self) private var loc
    @State private var showPicker = false
    @State private var isRequesting = false
    var onContinue: () -> Void

    private var isWide: Bool { DeviceLayout.isPad }
    private var canPickApps: Bool { stAuth.status == .approved }

    var body: some View {
        OBScreen(
            actionTitle: loc["save_apps"],
            enabled: blocker.hasFocusSelection,
            onContinue: {
                blocker.saveFocusSelection()
                onContinue()
            }
        ) {
            Spacer(minLength: 24)

            VStack(spacing: 10) {
                Text(loc["which_apps"])
                    .font(.system(size: isWide ? 34 : 26, weight: .black, design: .rounded))
                    .foregroundStyle(OBColor.ink)
                    .multilineTextAlignment(.center)

                Text(loc["choose_apps_protect"])
                    .font(.system(size: isWide ? 17 : 14, weight: .medium, design: .rounded))
                    .foregroundStyle(OBColor.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
            }
            .padding(.horizontal, 24)

            VStack(spacing: 14) {
                OBSelectionCard(count: blocker.focusAppCount, hasSelection: blocker.hasFocusSelection)

                if canPickApps {
                    appPickerButton
                } else {
                    permissionButton
                    Text(loc["apple_screen_time_required"])
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(OBColor.muted)
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)
                }
            }
            .padding(.horizontal, 22)
            .padding(.top, 14)

            Spacer()
        }
        .onAppear { stAuth.refreshStatus() }
        .onChange(of: scenePhase) {
            if scenePhase == .active { stAuth.refreshStatus() }
        }
    }

    #if os(iOS)
    private var appPickerButton: some View {
        @Bindable var b = blocker
        return Button { showPicker = true } label: {
            Label(blocker.hasFocusSelection ? loc["change_selected_apps"] : loc["select_apps"], systemImage: "apps.iphone")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity).frame(height: 52)
                .background(RoundedRectangle(cornerRadius: 16).fill(OBColor.accent))
        }
        .buttonStyle(.plain)
        .familyActivityPicker(isPresented: $showPicker, selection: $b.focusSelection)
        .onChange(of: b.focusSelection) { blocker.saveFocusSelection() }
    }
    #else
    private var appPickerButton: some View { EmptyView() }
    #endif

    private var permissionButton: some View {
        Button {
            if stAuth.status == .denied {
                stAuth.openSettings()
            } else {
                isRequesting = true
                Task {
                    await stAuth.requestAuthorization()
                    stAuth.refreshStatus()
                    isRequesting = false
                    if stAuth.status == .approved { showPicker = true }
                }
            }
        } label: {
            HStack(spacing: 8) {
                if isRequesting {
                    ProgressView().tint(.white)
                } else {
                    Image(systemName: stAuth.status == .denied ? "gearshape.fill" : "lock.shield.fill")
                }
                Text(stAuth.status == .denied ? loc["open_settings"] : loc["allow_screen_time"])
            }
            .font(.system(size: 15, weight: .bold, design: .rounded))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity).frame(height: 52)
            .background(RoundedRectangle(cornerRadius: 16).fill(OBColor.accent))
        }
        .buttonStyle(.plain)
        .disabled(isRequesting)
    }
}

// MARK: - Screen 6: Ready

private struct ReadyPage: View {
    @Environment(AppLocalization.self) private var loc
    @State private var cardsVisible = false
    var onComplete: () -> Void

    private var isWide: Bool { DeviceLayout.isPad }

    var body: some View {
        OBScreen(actionTitle: loc["get_started"], onContinue: onComplete) {
            Spacer()

            Image("SpikeLogo")
                .resizable().scaledToFit()
                .frame(width: isWide ? 130 : 100, height: isWide ? 130 : 100)

            VStack(spacing: isWide ? 14 : 10) {
                Text(loc["ready_change_life"])
                    .font(.system(size: isWide ? 34 : 26, weight: .black, design: .rounded))
                    .foregroundStyle(OBColor.ink)
                    .multilineTextAlignment(.center)

                Text(loc["ready_change_desc"])
                    .font(.system(size: isWide ? 17 : 14, weight: .medium, design: .rounded))
                    .foregroundStyle(OBColor.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
            }
            .padding(.horizontal, 26)

            VStack(spacing: 10) {
                OBBenefitRow(icon: "iphone.slash", text: loc["benefit_no_distraction"], delay: 0)
                OBBenefitRow(icon: "square.grid.2x2.fill", text: loc["benefit_discover_modes"], delay: 0.15)
                OBBenefitRow(icon: "chart.line.uptrend.xyaxis", text: loc["benefit_track_progress"], delay: 0.30)
            }
            .padding(.horizontal, 24)
            .padding(.top, 14)

            Spacer()
        }
    }
}

// MARK: - Shared Components

private struct OBScreen<Content: View>: View {
    @Environment(AppLocalization.self) private var loc
    var actionTitle = "Continue"
    var enabled: Bool = true
    var onContinue: () -> Void
    @ViewBuilder var content: Content

    var body: some View {
        VStack(spacing: 0) {
            content

            OBContinueButton(
                title: actionTitle == "Continue" ? loc["continue_btn"] : actionTitle,
                enabled: enabled,
                action: onContinue
            )
            .padding(.bottom, DeviceLayout.isPad ? 36 : 26)
        }
        .iPadReadable(maxWidth: DeviceLayout.isPad ? 780 : 540)
    }
}

private struct OBContinueButton: View {
    let title: String
    var enabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .frame(maxWidth: DeviceLayout.isPad ? 420 : .infinity)
                .frame(height: 54)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(OBColor.accentGradient)
                        .opacity(enabled ? 1.0 : 0.35)
                )
                .shadow(color: enabled ? OBColor.accent.opacity(0.22) : .clear, radius: 14, x: 0, y: 8)
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .padding(.horizontal, 22)
        .animation(.easeInOut(duration: 0.2), value: enabled)
    }
}

private struct OBProgressDots: View {
    let current: Int
    let total: Int

    var body: some View {
        HStack(spacing: 5) {
            ForEach(0..<total, id: \.self) { index in
                Capsule()
                    .fill(index == current ? OBColor.accent : OBColor.softBlue)
                    .frame(width: index == current ? 20 : 6, height: 6)
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.85), value: current)
    }
}

private struct OBHeroRow: View {
    let text: String; let color: Color

    var body: some View {
        HStack {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(text)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(OBColor.ink)
            Spacer()
        }
        .padding(.horizontal, 10).padding(.vertical, 8)
        .background(RoundedRectangle(cornerRadius: 12).fill(OBColor.softBlue))
    }
}

private struct OBSelectionCard: View {
    @Environment(AppLocalization.self) private var loc
    let count: Int; let hasSelection: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: hasSelection ? "checkmark.shield.fill" : "shield")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(hasSelection ? OBColor.accent : OBColor.muted)
                .frame(width: 46, height: 46)
                .background(Circle().fill((hasSelection ? OBColor.accent : OBColor.softBlue).opacity(0.14)))

            VStack(alignment: .leading, spacing: 2) {
                Text(hasSelection ? String(format: loc["selected_count"], count) : loc["no_apps_selected"])
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(OBColor.ink)
                Text(hasSelection ? loc["saved_for_modes"] : loc["select_apps_to_control"])
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(OBColor.secondary)
            }
            Spacer()
        }
        .padding(14)
        .background(obCard(cornerRadius: 18))
    }
}

private struct OBBenefitRow: View {
    let icon: String; let text: String
    var delay: Double = 0
    @State private var isVisible = false

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: DeviceLayout.isPad ? 20 : 16, weight: .bold))
                .foregroundStyle(OBColor.accent)
                .frame(width: DeviceLayout.isPad ? 46 : 38, height: DeviceLayout.isPad ? 46 : 38)
                .background(Circle().fill(OBColor.accent.opacity(0.10)))

            Text(text)
                .font(.system(size: DeviceLayout.isPad ? 17 : 14, weight: .semibold, design: .rounded))
                .foregroundStyle(OBColor.ink)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
        }
        .padding(.horizontal, 14).padding(.vertical, 13)
        .background(obCard(cornerRadius: 16))
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 12)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(delay)) {
                isVisible = true
            }
        }
    }
}

// MARK: - Card Background

private func obCard(cornerRadius: CGFloat) -> some View {
    RoundedRectangle(cornerRadius: cornerRadius)
        .fill(.white)
        .shadow(color: .black.opacity(0.06), radius: 14, x: 0, y: 8)
}

// MARK: - Colors

private enum OBColor {
    static let background = Color(red: 0.975, green: 0.978, blue: 0.99)
    static let ink        = Color(red: 0.07, green: 0.08, blue: 0.14)
    static let secondary  = Color(red: 0.39, green: 0.42, blue: 0.52)
    static let muted      = Color(red: 0.58, green: 0.62, blue: 0.72)
    static let softBlue   = Color(red: 0.90, green: 0.92, blue: 1.00)
    static let accent     = Color(red: 0.38, green: 0.30, blue: 0.86)
    static let red        = Color(red: 0.92, green: 0.24, blue: 0.28)

    static let accentGradient = LinearGradient(
        colors: [Color(red: 0.38, green: 0.30, blue: 0.86), Color(red: 0.56, green: 0.36, blue: 0.92)],
        startPoint: .leading, endPoint: .trailing
    )
}
