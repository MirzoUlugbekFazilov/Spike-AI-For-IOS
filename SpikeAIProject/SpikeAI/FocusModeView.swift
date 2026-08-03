//
//  FocusModeView.swift
//  Spike AI
//
//  Focus Mode UI — MVVM architecture using FocusModeViewModel.
//  Chill / Focus / Lock-in / Sweat mode selection,
//  Screen Time app selection, and onboarding.
//

import SwiftUI
import AVFoundation
import UIKit
import Combine
import Vision

#if os(iOS)
import FamilyControls
#endif

// MARK: ─── Main Focus Mode View ──────────────────────────────────────────────

struct FocusModeView: View {
    @Environment(\.scenePhase)              var scenePhase
    @Environment(FocusModeViewModel.self)   var vm
    @Environment(AuthorizationManager.self) var stAuth
    @Environment(AppBlockingManager.self)   var blocker
    @Environment(ActivityScheduler.self)    var scheduler
    @Environment(NotificationManager.self)  var notifications
    @Environment(AppLocalization.self)      private var loc
    @Environment(TaskStore.self)            private var taskStore

    @State private var showOnboarding    = false
    @State private var showAppPicker     = false
    @State private var showSweatUnlock   = false

    var body: some View {
        NavigationStack {
            ScrollView {
                    VStack(spacing: 20) {
                        if vm.isActive { activeBanner }
                        if let activationError = vm.activationError {
                            focusErrorBanner(activationError)
                        }
                        modeSelector
                        modeDescription
                        modeContent
                }
                .padding()
                .iPadReadableScroll(maxWidth: 720)
            }
            .background(Color.spikeBgTop)
            .navigationTitle(loc["focus_title"])
            .toolbarBackground(Color.spikeBgTop, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showOnboarding = true } label: {
                        Image(systemName: "info.circle")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(Color.primary)
                    }
                    .accessibilityLabel(Text(loc["focus_info_btn"] == "focus_info_btn" ? "About focus modes" : loc["focus_info_btn"]))
                }
            }
            .sheet(isPresented: $showOnboarding) {
                FocusOnboardingView(isPresented: $showOnboarding)
            }
            .fullScreenCover(isPresented: $showSweatUnlock) {
                SweatUnlockView(isPresented: $showSweatUnlock)
                    .environment(vm)
            }
            .alert(
                loc["giving_up_title"] == "giving_up_title"
                    ? "You're making progress \u{2014} don't stop now"
                    : loc["giving_up_title"],
                isPresented: Bindable(vm).showDeactivationAlert
            ) {
                Button(loc["giving_up_continue"] == "giving_up_continue"
                       ? "Stay Focused" : loc["giving_up_continue"],
                       role: .cancel) { }
                Button(loc["giving_up_stop"] == "giving_up_stop"
                       ? "Turn Off Anyway" : loc["giving_up_stop"],
                       role: .destructive) {
                    // Fall back to Chill — a mode must always be active
                    vm.performFallbackToChill()
                }
            } message: {
                Text(loc["giving_up_msg"] == "giving_up_msg"
                     ? "You still have uncompleted goals for today. Every finished task builds momentum. Stay committed \u{2014} your future self will thank you."
                     : loc["giving_up_msg"])
            }
            .alert(
                loc["switch_to_chill_title"] == "switch_to_chill_title"
                    ? "Switch to Chill Mode?" : loc["switch_to_chill_title"],
                isPresented: Bindable(vm).showChillSwitchAlert
            ) {
                Button(loc["stay_focused_btn"] == "stay_focused_btn"
                       ? "Stay Focused" : loc["stay_focused_btn"], role: .cancel) {
                    vm.cancelChillSwitch()
                }
                Button(loc["switch_anyway_btn"] == "switch_anyway_btn"
                       ? "Switch Anyway" : loc["switch_anyway_btn"], role: .destructive) {
                    vm.confirmChillSwitch()
                }
            } message: {
                Text(loc["switch_to_chill_msg"] == "switch_to_chill_msg"
                     ? "You still have uncompleted goals. Switching to Chill Mode removes app blocking, which increases the risk of not finishing your goals today."
                     : loc["switch_to_chill_msg"])
            }
            .alert(
                loc["no_active_goals_title"] == "no_active_goals_title"
                    ? "No active goals" : loc["no_active_goals_title"],
                isPresented: Bindable(vm).showNoGoalsAlert
            ) {
                Button(loc["no_active_goals_btn"] == "no_active_goals_btn"
                       ? "Got it" : loc["no_active_goals_btn"]) { }
            } message: {
                Text(loc["no_active_goals_msg"] == "no_active_goals_msg"
                     ? "Focus and Lock-in only run while you have an uncompleted goal to work toward. Add a goal \u{2014} or reactivate one \u{2014} then start your session."
                     : loc["no_active_goals_msg"])
            }
            .onAppear {
                if !vm.hasCompletedOnboarding { showOnboarding = true }
                Task { await notifications.checkStatus() }
                stAuth.refreshStatus()
                vm.ensureModeActive()
                vm.autoRequestIfNeeded()
            }
            .onChange(of: scenePhase) {
                if scenePhase == .active {
                    stAuth.refreshStatus()
                    vm.onForeground()
                    Task { await notifications.checkStatus() }
                }
            }
            .onChange(of: vm.selectedMode) {
                vm.autoRequestIfNeeded()
            }
        }
    }

    // MARK: Active Banner

    private var activeBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: vm.selectedMode.icon)
                .font(.title3).foregroundStyle(.white)
            VStack(alignment: .leading, spacing: 2) {
                Text(localizedModeName(vm.selectedMode) + " " + (loc["mode_active"] == "mode_active" ? "Mode Active" : loc["mode_active"]))
                    .font(.subheadline).fontWeight(.semibold).foregroundStyle(.white)
                if vm.selectedMode == .light {
                    Text(loc["reminders_scheduled"] == "reminders_scheduled" ? "Reminders scheduled" : loc["reminders_scheduled"])
                        .font(.caption).foregroundStyle(.white.opacity(0.8))
                } else if vm.selectedMode == .medium {
                    Text("\(blocker.focusAppCount) \(loc["apps_prompt_active"])")
                        .font(.caption).foregroundStyle(.white.opacity(0.8))
                } else if vm.selectedMode == .sweat {
                    Text(vm.sweatUnlockRemaining > 0
                         ? (loc["temp_access_active"] == "temp_access_active" ? "Temporary access active" : loc["temp_access_active"])
                         : (loc["apps_require_movement"] == "apps_require_movement"
                            ? "\(blocker.focusAppCount) app(s) require movement to unlock"
                            : "\(blocker.focusAppCount) \(loc["apps_require_movement"])"))
                        .font(.caption).foregroundStyle(.white.opacity(0.8))
                } else {
                    Text(loc["apps_blocked"] == "apps_blocked"
                         ? "\(blocker.focusAppCount) app(s) blocked"
                         : "\(blocker.focusAppCount) \(loc["apps_blocked"])")
                        .font(.caption).foregroundStyle(.white.opacity(0.8))
                }
            }
            Spacer()
            Image(systemName: "checkmark.seal.fill")
                .font(.title3).foregroundStyle(.white.opacity(0.7))
        }
        .padding()
        .background(vm.selectedMode.color.gradient)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func localizedModeName(_ mode: FocusMode) -> String {
        let key: String
        switch mode {
        case .light:  key = "mode_chill"
        case .medium: key = "mode_focus"
        case .hard:   key = "mode_lock_in"
        case .sweat:  key = "mode_sweat"
        }
        let value = loc[key]
        return value == key ? mode.title : value
    }

    private func focusErrorBanner(_ message: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.primary)
            Spacer()
        }
        .padding()
        .background(Color.orange.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: Mode Selector

    private var modeSelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(loc["select_mode"] == "select_mode" ? "Select Mode" : loc["select_mode"]).font(.headline)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 2), spacing: 10) {
                ForEach(FocusMode.allCases, id: \.self) { m in
                    ModeCard(
                        focusMode: m,
                        isSelected: vm.selectedMode == m,
                        isActive: vm.selectedMode == m
                    ) {
                        vm.setMode(m)
                    }
                }
            }
        }
    }

    // MARK: Mode Description

    private var modeDescription: some View {
        HStack(spacing: 12) {
            Image(systemName: vm.selectedMode.icon)
                .font(.title2).foregroundStyle(vm.selectedMode.color)
                .frame(width: 40)
            Text(localizedModeDescription(vm.selectedMode))
                .font(.subheadline).foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.spikeCard)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.spikeCardBorder, lineWidth: 0.5))
    }

    private func localizedModeDescription(_ mode: FocusMode) -> String {
        let key: String
        switch mode {
        case .light:  key = "chill_desc"
        case .medium: key = "focus_desc"
        case .hard:   key = "lock_in_desc"
        case .sweat:  key = "sweat_desc"
        }
        let value = loc[key]
        return value == key ? mode.description : value
    }

    // MARK: Mode Content Router

    @ViewBuilder
    private var modeContent: some View {
        switch vm.selectedMode {
        case .light:  lightModeSection
        case .medium: screenTimeModeSection(isHard: false)
        case .hard:   screenTimeModeSection(isHard: true)
        case .sweat:  sweatModeSection
        }
    }

}

// MARK: ─── Chill Mode Section ────────────────────────────────────────────────

extension FocusModeView {

    private var lightModeSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            notificationPermissionCard
        }
    }

    private var notificationPermissionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(loc["notifications_label"], systemImage: "bell.fill").font(.headline)
            switch notifications.authorizationStatus {
            case .authorized:
                statusRow(icon: "checkmark.circle.fill", color: .green, text: loc["notifications_enabled"])
            case .denied:
                VStack(alignment: .leading, spacing: 8) {
                    statusRow(icon: "xmark.circle.fill", color: .red, text: loc["notifications_denied"])
                    Text(loc["enable_notif_settings"])
                        .font(.caption).foregroundStyle(.secondary)
                    openSettingsButton
                }
            default:
                VStack(alignment: .leading, spacing: 8) {
                    Text(loc["allow_notif_desc"])
                        .font(.subheadline).foregroundStyle(.secondary)
                    pillButton(loc["enable_notifications"], color: .blue) {
                        Task { await notifications.requestAuthorization() }
                    }
                }
            }
        }
        .padding().background(Color.spikeCard)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.spikeCardBorder, lineWidth: 0.5))
    }

}

// MARK: ─── Screen Time Mode Section (Focus / Lock-in) ───────────────────────

extension FocusModeView {

    private func screenTimeModeSection(isHard: Bool) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            goalsRequiredCard(isHard: isHard)
            screenTimePermissionCard
            #if os(iOS)
            if stAuth.status == .approved {
                if !isHard {
                    focusRelockCard
                }
                appSelectionCard(isHard: isHard)
            }
            #endif
            if isHard { hardModeWarning }
        }
    }

    private func goalsRequiredCard(isHard: Bool) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "target")
                .font(.title3)
                .foregroundStyle(isHard ? .red : .orange)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 4) {
                Text(loc["goals_required_title"] == "goals_required_title"
                     ? "Goals Required"
                     : loc["goals_required_title"])
                    .font(.subheadline).fontWeight(.semibold)
                Text({
                    let key = isHard ? "goals_required_desc_lockin" : "goals_required_desc_focus"
                    let val = loc[key]
                    if val == key {
                        return "\(isHard ? "Lock-in" : "Focus") mode blocks selected apps only when you have uncompleted goals. Add goals in the Home tab to activate app blocking."
                    }
                    return val
                }())
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background((isHard ? Color.red : Color.orange).opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke((isHard ? Color.red : Color.orange).opacity(0.2), lineWidth: 0.5))
    }

    // MARK: Permission Card

    private var screenTimePermissionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(loc["screen_time_access"], systemImage: "hourglass").font(.headline)
            if stAuth.status == .approved {
                statusRow(icon: "checkmark.circle.fill", color: .green, text: loc["screen_time_authorized"])
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    Text(loc["tap_to_allow"])
                        .font(.subheadline).foregroundStyle(.secondary)
                    Button {
                        Task { await stAuth.requestAuthorization() }
                    } label: {
                        HStack {
                            Image(systemName: "lock.shield")
                            Text(loc["allow_screen_time"]).fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity).padding(.vertical, 12)
                        .background(Color.primary).foregroundStyle(Color(uiColor: .systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    if stAuth.status == .denied {
                        Button { stAuth.openSettings() } label: {
                            Text(loc["open_settings_manual"])
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
                if let error = stAuth.error {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.yellow).font(.caption)
                        Text(error).font(.caption).foregroundStyle(.secondary)
                    }
                    .padding(10).frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.yellow.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
        .padding().background(Color.spikeCard)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.spikeCardBorder, lineWidth: 0.5))
    }

    // MARK: App Selection Card

    #if os(iOS)
    private var focusRelockCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Ask Again After", systemImage: "timer")
                .font(.headline)

            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Shield reactivates after this Focus allowance.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("Current: \(focusRelockLabel(vm.focusRelockMinutes))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 12)

                Menu {
                    ForEach(FocusConstants.focusRelockMinuteOptions, id: \.self) { minutes in
                        Button {
                            vm.setFocusRelockMinutes(minutes)
                        } label: {
                            HStack {
                                Text(focusRelockLabel(minutes))
                                if vm.focusRelockMinutes == minutes {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 8) {
                        Text(focusRelockLabel(vm.focusRelockMinutes))
                            .fontWeight(.semibold)
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.caption2)
                    }
                    .font(.subheadline)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 9)
                    .background(Color.orange.opacity(0.12))
                    .foregroundStyle(.orange)
                    .clipShape(Capsule())
                }
            }
        }
        .padding().background(Color.spikeCard)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.spikeCardBorder, lineWidth: 0.5))
    }

    private func focusRelockLabel(_ minutes: Int) -> String {
        minutes == 1 ? "1 min" : "\(minutes) min"
    }

    private func appSelectionCard(isHard: Bool) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(loc["app_selection"], systemImage: "apps.iphone").font(.headline)
            if blocker.hasFocusSelection {
                HStack(spacing: 8) {
                    Image(systemName: "app.badge.checkmark.fill")
                        .foregroundStyle(vm.selectedMode == .sweat ? .teal : (isHard ? .red : .orange))
                    Text("\(blocker.focusAppCount) \(loc["selections"])").font(.subheadline)
                    Spacer()
                }
            } else {
                Text(vm.selectedMode == .sweat ? loc["choose_apps_movement"] : (isHard ? loc["choose_apps_block"] : loc["choose_apps_confirm"]))
                    .font(.subheadline).foregroundStyle(.secondary)
            }
            appPickerButton
        }
        .padding().background(Color.spikeCard)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.spikeCardBorder, lineWidth: 0.5))
    }

    @ViewBuilder
    private var appPickerButton: some View {
        @Bindable var b = blocker
        Button { showAppPicker = true } label: {
            HStack {
                Image(systemName: "square.grid.2x2")
                Text(blocker.hasFocusSelection ? loc["change_selection"] : loc["select_apps"])
                    .fontWeight(.medium)
            }
            .font(.subheadline)
            .padding(.horizontal, 16).padding(.vertical, 8)
            .background(Color.primary).foregroundStyle(Color(uiColor: .systemBackground)).clipShape(Capsule())
        }
        .familyActivityPicker(isPresented: $showAppPicker, selection: $b.focusSelection)
        .onChange(of: b.focusSelection) { blocker.saveFocusSelection() }
    }
    #endif

    // MARK: Lock-in Mode Warning

    private var hardModeWarning: some View {
        HStack(spacing: 10) {
            Image(systemName: "hand.raised.slash.fill")
                .foregroundStyle(.white).font(.title3)
            VStack(alignment: .leading, spacing: 4) {
                Text(loc["lock_in_mode"])
                    .font(.caption).fontWeight(.bold).foregroundStyle(.white)
                Text(loc["lock_in_warning"])
                    .font(.caption2).foregroundStyle(.white.opacity(0.85))
            }
        }
        .padding().background(Color.red.gradient)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: ─── Sweat Mode Section ───────────────────────────────────────────────

extension FocusModeView {

    private var sweatModeSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            screenTimePermissionCard
            #if os(iOS)
            if stAuth.status == .approved {
                appSelectionCard(isHard: true)
            }
            #endif
            sweatModeCard
        }
    }

    private var sweatModeCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(loc["movement_unlock"], systemImage: "figure.strengthtraining.traditional")
                .font(.headline)
            Text(loc["movement_desc"])
                .font(.subheadline)
                .foregroundStyle(.secondary)
            if vm.sweatUnlockRemaining > 0 {
                Label(String(format: loc["access_available"], formatRemaining(vm.sweatUnlockRemaining)), systemImage: "timer")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.teal)
            }
            Button {
                showSweatUnlock = true
            } label: {
                HStack {
                    Image(systemName: "camera.viewfinder")
                    Text(loc["open_camera"])
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.teal)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
        .padding()
        .background(Color.spikeCard)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.spikeCardBorder, lineWidth: 0.5))
    }

    private func formatRemaining(_ interval: TimeInterval) -> String {
        let seconds = max(0, Int(interval))
        return seconds < 60 ? "\(seconds)s" : "\(seconds / 60)m \(seconds % 60)s"
    }
}

// MARK: ─── Shared UI Helpers ─────────────────────────────────────────────────

extension FocusModeView {

    private func statusRow(icon: String, color: Color, text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon).foregroundStyle(color)
            Text(text).font(.subheadline)
            Spacer()
        }
    }

    private func pillButton(_ title: String, color: Color,
                            action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title).font(.subheadline).fontWeight(.medium)
                .padding(.horizontal, 16).padding(.vertical, 8)
                .background(color).foregroundStyle(.white).clipShape(Capsule())
        }
    }

    private var openSettingsButton: some View {
        Button {
            #if os(iOS)
            guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
            UIApplication.shared.open(url)
            #endif
        } label: {
            Text(loc["open_settings"]).font(.subheadline).fontWeight(.medium)
                .padding(.horizontal, 16).padding(.vertical, 8)
                .background(Color.primary).foregroundStyle(Color(uiColor: .systemBackground)).clipShape(Capsule())
        }
    }
}

// MARK: ─── Mode Card ─────────────────────────────────────────────────────────

struct ModeCard: View {
    @Environment(AppLocalization.self) private var loc
    let focusMode: FocusMode
    let isSelected: Bool
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: focusMode.icon)
                    .font(.title2)
                    .foregroundStyle(isActive ? .white : focusMode.color)
                Text(localizedTitle)
                    .font(.subheadline).fontWeight(.semibold)
                    .foregroundStyle(isActive ? .white : .primary)
                Text(localizedSubtitle)
                    .font(.caption2).foregroundStyle(isActive ? .white.opacity(0.8) : .secondary)
            }
            .frame(maxWidth: .infinity).padding(.vertical, 16)
            .background(isActive ? AnyShapeStyle(focusMode.color.gradient) : AnyShapeStyle(Color.spikeCard))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay {
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isActive ? Color.clear : Color.spikeCardBorder, lineWidth: 0.5)
            }
            .shadow(color: isActive ? focusMode.color.opacity(0.3) : .clear, radius: 8, y: 3)
            .scaleEffect(isActive ? 1.0 : 0.97)
            .animation(.easeInOut(duration: 0.2), value: isActive)
        }
        .buttonStyle(.plain)
    }

    private var localizedTitle: String {
        switch focusMode {
        case .light: loc["chill"]
        case .medium: loc["focus"]
        case .hard: loc["lock_in"]
        case .sweat: loc["sweat"]
        }
    }

    private var localizedSubtitle: String {
        switch focusMode {
        case .light: loc["gentle_nudges"]
        case .medium: loc["confirm_intent"]
        case .hard: loc["no_bypass"]
        case .sweat: loc["move_to_unlock"]
        }
    }
}

// MARK: ─── Sweat Mode Unlock (Full-Screen Camera + Body Tracking) ───────────

struct SweatUnlockView: View {
    @Environment(FocusModeViewModel.self) private var vm
    @Environment(AppLocalization.self) private var loc
    @Binding var isPresented: Bool
    @StateObject private var camera = SweatCameraModel()
    @State private var elapsedSeconds = 0
    @State private var timerTask: Task<Void, Never>?

    var body: some View {
        ZStack {
            Color(red: 0.04, green: 0.04, blue: 0.10).ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                    .padding(.horizontal)
                    .padding(.top, 8)

                cameraSurface
                    .padding(.horizontal, 12)
                    .padding(.top, 12)

                Spacer(minLength: 14)

                if vm.sweatUnlockRemaining > 0 {
                    HStack(spacing: 6) {
                        Image(systemName: "lock.open.fill")
                        Text(String(format: loc["unlocked_for"], fmtRemaining(vm.sweatUnlockRemaining)))
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.teal)
                    .padding(.bottom, 10)
                }

                claimButton
                    .padding(.horizontal)
                    .padding(.bottom, 20)
            }
            .iPadReadable(maxWidth: 640)
        }
        .statusBarHidden()
        .task {
            await camera.prepare()
            startTimer()
        }
        .onDisappear {
            camera.stop()
            timerTask?.cancel()
        }
    }

    // MARK: Top Bar

    private var topBar: some View {
        HStack {
            Button { isPresented = false } label: {
                Image(systemName: "xmark")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(10)
                    .background(.white.opacity(0.15), in: Circle())
            }

            Spacer()

            HStack(spacing: 6) {
                Image(systemName: "figure.strengthtraining.traditional")
                Text(loc["sweat_mode"])
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.white)

            Spacer()

            Text(fmtTime(elapsedSeconds))
                .font(.subheadline.weight(.medium).monospacedDigit())
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(.white.opacity(0.15), in: Capsule())
        }
    }

    // MARK: Camera Surface

    @ViewBuilder
    private var cameraSurface: some View {
        ZStack {
            if camera.isReady {
                SweatCameraPreview(session: camera.session)
                    .clipShape(RoundedRectangle(cornerRadius: 18))

                SkeletonOverlay(points: camera.bodyPoints)
                    .clipShape(RoundedRectangle(cornerRadius: 18))

                // Rep counter bubble — scaled up on iPad's larger camera surface.
                VStack {
                    Spacer()
                    Text("\(camera.repCount)")
                        .font(.system(size: DeviceLayout.isPad ? 62 : 48, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(width: DeviceLayout.isPad ? 108 : 82,
                               height: DeviceLayout.isPad ? 108 : 82)
                        .background(
                            Circle()
                                .fill(
                                    LinearGradient(colors: [.cyan, .teal],
                                                   startPoint: .topLeading,
                                                   endPoint: .bottomTrailing)
                                )
                                .shadow(color: .cyan.opacity(0.45), radius: 14, y: 4)
                        )
                        .padding(.bottom, DeviceLayout.isPad ? 36 : 24)
                }

                // Body-not-detected hint
                if !camera.hasBody {
                    VStack {
                        Spacer()
                        HStack(spacing: 6) {
                            Image(systemName: "person.fill.questionmark")
                            Text(loc["keep_in_view"])
                        }
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(.black.opacity(0.6), in: Capsule())
                        .padding(.bottom, DeviceLayout.isPad ? 150 : 120)
                    }
                }
            } else {
                cameraPlaceholder
            }
        }
        .frame(maxHeight: .infinity)
    }

    private var cameraPlaceholder: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white.opacity(0.06))
            VStack(spacing: 14) {
                if camera.needsPermissionButton {
                    Image(systemName: "camera.fill")
                        .font(.largeTitle)
                        .foregroundStyle(.teal)
                    Text(camera.statusText)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                    Button(loc["allow_camera"]) {
                        Task { await camera.requestPermissionAndStart() }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.teal)
                } else {
                    ProgressView().tint(.white)
                    Text(camera.statusText)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
            }
            .padding()
        }
    }

    // MARK: Claim Button

    private var claimButton: some View {
        Button {
            let claimedReps = min(camera.repCount, 5)
            for _ in 0..<claimedReps { vm.addSweatUnlockMinute() }
            camera.resetReps()
        } label: {
            let claimedReps = min(camera.repCount, 5)
            Text(claimedReps > 0
                 ? String(format: loc["add_minutes"], claimedReps)
                 : loc["do_exercises"])
                .font(.title3.weight(.semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(
                            LinearGradient(colors: [.cyan, .teal],
                                           startPoint: .leading, endPoint: .trailing),
                            lineWidth: 2
                        )
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(.white.opacity(camera.repCount > 0 ? 0.08 : 0.03))
                        )
                )
        }
        .disabled(camera.repCount == 0)
        .opacity(camera.repCount > 0 ? 1 : 0.4)
    }

    // MARK: Helpers

    private func startTimer() {
        timerTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                guard !Task.isCancelled else { break }
                elapsedSeconds += 1
            }
        }
    }

    private func fmtTime(_ s: Int) -> String {
        String(format: "%d:%02d", s / 60, s % 60)
    }

    private func fmtRemaining(_ interval: TimeInterval) -> String {
        let s = max(0, Int(interval))
        return s < 60 ? "\(s)s" : "\(s / 60)m \(s % 60)s"
    }
}

// MARK: ─── Skeleton Overlay ─────────────────────────────────────────────────

struct SkeletonOverlay: View {
    let points: [VNHumanBodyPoseObservation.JointName: CGPoint]

    private let connections: [(VNHumanBodyPoseObservation.JointName, VNHumanBodyPoseObservation.JointName)] = [
        (.nose, .neck),
        (.neck, .leftShoulder), (.neck, .rightShoulder),
        (.leftShoulder, .rightShoulder),
        (.leftShoulder, .leftElbow), (.leftElbow, .leftWrist),
        (.rightShoulder, .rightElbow), (.rightElbow, .rightWrist),
        (.leftShoulder, .leftHip), (.rightShoulder, .rightHip),
        (.neck, .root),
        (.root, .leftHip), (.root, .rightHip),
        (.leftHip, .rightHip),
        (.leftHip, .leftKnee), (.leftKnee, .leftAnkle),
        (.rightHip, .rightKnee), (.rightKnee, .rightAnkle),
    ]

    var body: some View {
        Canvas { context, size in
            // Glow layer
            for (from, to) in connections {
                guard let p1 = points[from], let p2 = points[to] else { continue }
                var path = Path()
                path.move(to: viewPt(p1, in: size))
                path.addLine(to: viewPt(p2, in: size))
                context.stroke(path, with: .color(.cyan.opacity(0.25)),
                               style: StrokeStyle(lineWidth: 10, lineCap: .round))
            }
            // Main lines
            for (from, to) in connections {
                guard let p1 = points[from], let p2 = points[to] else { continue }
                var path = Path()
                path.move(to: viewPt(p1, in: size))
                path.addLine(to: viewPt(p2, in: size))
                context.stroke(path, with: .color(.cyan.opacity(0.85)),
                               style: StrokeStyle(lineWidth: 3, lineCap: .round))
            }
            // Joint dots
            for (_, pt) in points {
                let p = viewPt(pt, in: size)
                let r: CGFloat = 5
                context.fill(
                    Path(ellipseIn: CGRect(x: p.x - r, y: p.y - r, width: r * 2, height: r * 2)),
                    with: .color(.cyan)
                )
            }
        }
    }

    /// Convert Vision normalised coords (origin bottom-left) → view coords.
    private func viewPt(_ p: CGPoint, in size: CGSize) -> CGPoint {
        CGPoint(x: p.x * size.width, y: (1 - p.y) * size.height)
    }
}

// MARK: ─── Sweat Mode: Tunable Configuration ───────────────────────────────

private struct AthleteConfig {
    // ── Joint confidence (Vision scale) ──────────────────────────
    // The Android app (ML Kit) gates joints at 0.6/0.65 in-frame likelihood.
    // Apple's Vision body-pose confidences are scaled differently, so this
    // single gate is tuned for Vision — the *detection algorithm* below is a
    // verbatim port of the Android Athlete-mode logic.
    let jointConfidence: VNConfidence = 0.22       // lowered so partial-body / angled poses still track
    let minTrackedJoints = 4

    // ── Push-up (angle-driven; robust to partial body / any angle) ─
    // Counts a rep on a full extend → bend → extend elbow cycle. Works from a
    // SINGLE visible arm and does NOT require hips or legs to be in frame.
    let pushUpElbowAngle: CGFloat = 145            // arms considered "extended" (top)
    let pushDownElbowAngle: CGFloat = 120          // arms considered "bent" (bottom)
    let pushEndpointHoldMs: Double = 110           // brief hold to confirm an endpoint
    let pushMinRepMs: Double = 430                 // fastest valid rep
    let pushCooldownMs: Double = 250               // gap after a counted rep
    let pushMinElbowRange: CGFloat = 25            // min elbow-angle swing for a real rep
    let pushSmoothingAlpha: CGFloat = 0.55         // elbow-angle EMA (higher = more responsive)
    let pushMaxMissingFrames = 6                   // tolerated dropouts before reset

    // ── Squat / stand-up (ported from Android MovementRepDetector) ─
    let squatSmoothingAlpha: CGFloat = 0.5         // per-joint EMA (Android AngleSmoother)
    let squatMaxSideDisagreement: CGFloat = 35     // max left/right angle gap
    let squatDownKneeAngle: CGFloat = 115
    let squatDownHipAngle: CGFloat = 140
    let squatUpKneeAngle: CGFloat = 165
    let squatUpHipAngle: CGFloat = 155
    let squatConfirmationFrames = 2                // frames to confirm an endpoint
    let squatMaxMissingFrames = 4                  // tolerated dropouts before reset
    let squatMinMovementMs: Double = 250
    let squatMaxMovementMs: Double = 8000

    // ── Body overlay smoothing (display only) ────────────────────
    let overlayPointSmoothing: CGFloat = 0.5
    let overlayRetainedFrames = 8
}

// MARK: ─── Athlete Mode: Geometry Helpers (ported from Android) ───────────────

private enum AthleteGeometry {
    /// Angle (degrees) at vertex `b`, identical to Android's `angle(a,b,c)`.
    /// Coordinate-system independent (works for both Vision and ML Kit axes).
    static func angle(_ a: CGPoint, _ b: CGPoint, _ c: CGPoint) -> CGFloat {
        let radians = atan2(c.y - b.y, c.x - b.x) - atan2(a.y - b.y, a.x - b.x)
        var degrees = abs(radians * 180 / .pi)
        if degrees > 180 { degrees = 360 - degrees }
        return degrees
    }

    static func distance(_ a: CGPoint, _ b: CGPoint) -> CGFloat { hypot(a.x - b.x, a.y - b.y) }

    static func midpoint(_ a: CGPoint, _ b: CGPoint) -> CGPoint {
        CGPoint(x: (a.x + b.x) / 2, y: (a.y + b.y) / 2)
    }

    /// Average left/right angles when they agree, else trust the single
    /// available side; reject if both present but disagree (Android combinedAngle).
    static func combined(_ left: CGFloat?, _ right: CGFloat?, maxDisagreement: CGFloat) -> CGFloat? {
        if let l = left, let r = right {
            return abs(l - r) <= maxDisagreement ? (l + r) / 2 : nil
        }
        return left ?? right
    }
}

// MARK: ─── Athlete Mode: Push-Up Detector (ported from Android) ───────────────

private final class AthletePushUpDetector {
    enum State { case ready, up, down }

    private let cfg: AthleteConfig
    private(set) var state: State = .ready

    // Smoothed elbow angle (EMA). The model feeds the elbow angle computed from
    // whichever arm(s) are visible — so this works from a single arm and never
    // needs hips, legs, or a full body in frame.
    private var elbowEMA: CGFloat?
    private(set) var smoothedElbow: CGFloat = 170

    private var repStartMs: Double = 0
    private var cooldownUntilMs: Double = 0
    private var upHoldStartMs: Double?
    private var downHoldStartMs: Double?
    private var missingFrames = 0
    private var minElbow = CGFloat.infinity
    private var maxElbow = -CGFloat.infinity

    init(_ cfg: AthleteConfig) { self.cfg = cfg }

    /// Mid-rep means the user has actually descended — used to suppress the
    /// squat detector so the two can never double-count.
    var inDownPhase: Bool { state == .down }

    func reset() {
        state = .ready
        elbowEMA = nil; smoothedElbow = 170
        repStartMs = 0; cooldownUntilMs = 0
        upHoldStartMs = nil; downHoldStartMs = nil
        missingFrames = 0
        minElbow = .infinity; maxElbow = -.infinity
    }

    /// Feed the current elbow angle (degrees), or nil when no arm is visible.
    /// Returns true when a valid rep is counted.
    func update(elbowAngle raw: CGFloat?, nowMs: Double) -> Bool {
        guard let raw else {
            upHoldStartMs = nil; downHoldStartMs = nil
            missingFrames += 1
            if missingFrames > cfg.pushMaxMissingFrames { softReset() }
            return false
        }
        missingFrames = 0
        let e = elbowEMA.map { $0 + cfg.pushSmoothingAlpha * (raw - $0) } ?? raw
        elbowEMA = e
        smoothedElbow = e
        return advance(e, nowMs)
    }

    private func softReset() {
        state = .ready
        upHoldStartMs = nil; downHoldStartMs = nil
        minElbow = .infinity; maxElbow = -.infinity
    }

    // ── State machine: extend → bend → extend ──
    private func advance(_ e: CGFloat, _ nowMs: Double) -> Bool {
        if nowMs < cooldownUntilMs { return false }

        minElbow = min(minElbow, e)
        maxElbow = max(maxElbow, e)

        let isUp = e > cfg.pushUpElbowAngle      // arms extended
        let isDown = e < cfg.pushDownElbowAngle  // arms bent

        switch state {
        case .ready:
            if heldUp(isUp, nowMs) {
                state = .up
                repStartMs = nowMs
                minElbow = e; maxElbow = e
            }
            downHoldStartMs = nil

        case .up:
            maxElbow = max(maxElbow, e)
            if heldDown(isDown, nowMs) {
                state = .down
            }
            if !isDown { downHoldStartMs = nil }

        case .down:
            minElbow = min(minElbow, e)
            if heldUp(isUp, nowMs) {
                let valid = (nowMs - repStartMs) >= cfg.pushMinRepMs
                    && (maxElbow - minElbow) >= cfg.pushMinElbowRange
                // Cycle complete — return to top whether or not it qualified.
                cooldownUntilMs = nowMs + cfg.pushCooldownMs
                state = .ready
                repStartMs = nowMs
                minElbow = e; maxElbow = e
                upHoldStartMs = nil; downHoldStartMs = nil
                if valid { return true }
            }
            if !isUp { upHoldStartMs = nil }
        }
        return false
    }

    private func heldUp(_ condition: Bool, _ nowMs: Double) -> Bool {
        if !condition { upHoldStartMs = nil; return false }
        if upHoldStartMs == nil { upHoldStartMs = nowMs }
        return nowMs - (upHoldStartMs ?? nowMs) >= cfg.pushEndpointHoldMs
    }

    private func heldDown(_ condition: Bool, _ nowMs: Double) -> Bool {
        if !condition { downHoldStartMs = nil; return false }
        if downHoldStartMs == nil { downHoldStartMs = nowMs }
        return nowMs - (downHoldStartMs ?? nowMs) >= cfg.pushEndpointHoldMs
    }
}

// MARK: ─── Athlete Mode: Squat / Stand-Up Detector (ported from Android) ──────

private final class AthleteSquatDetector {
    private let cfg: AthleteConfig

    // Per-joint angle EMAs (Android AngleSmoother, alpha = 0.5).
    private var kneeValue: CGFloat?
    private var hipValue: CGFloat?

    // MovementRepDetector state.
    private var downFrames = 0
    private var upFrames = 0
    private var missingFrames = 0
    private var downSinceMs: Double = 0
    private var isDownConfirmed = false

    private(set) var smoothedKnee: CGFloat = 170
    private(set) var smoothedHip: CGFloat = 170

    /// True once a squat bottom is confirmed — used to suppress the push-up
    /// detector so the two can never double-count.
    var isActive: Bool { isDownConfirmed }

    init(_ cfg: AthleteConfig) { self.cfg = cfg }

    func reset() {
        kneeValue = nil; hipValue = nil
        resetCycle()
        smoothedKnee = 170; smoothedHip = 170
    }

    /// Feed raw knee/hip angles (nil when not measurable). Returns true on a rep.
    func update(rawKnee: CGFloat?, rawHip: CGFloat?, nowMs: Double) -> Bool {
        let knee = ema(&kneeValue, rawKnee)
        let hip = ema(&hipValue, rawHip)
        guard let knee, let hip else {
            missingFrame()
            return false
        }
        smoothedKnee = knee; smoothedHip = hip
        return advance(knee: knee, hip: hip, nowMs: nowMs)
    }

    func missingFrame() {
        missingFrames += 1
        if missingFrames > cfg.squatMaxMissingFrames { resetCycle() }
    }

    private func ema(_ store: inout CGFloat?, _ reading: CGFloat?) -> CGFloat? {
        guard let reading else { return nil }   // joint lost: report nil, keep running average
        if let prev = store {
            store = prev + cfg.squatSmoothingAlpha * (reading - prev)
        } else {
            store = reading
        }
        return store
    }

    private func advance(knee: CGFloat, hip: CGFloat, nowMs: Double) -> Bool {
        missingFrames = 0
        let isDown = knee <= cfg.squatDownKneeAngle && hip <= cfg.squatDownHipAngle
        let isUp = knee >= cfg.squatUpKneeAngle && hip >= cfg.squatUpHipAngle

        if !isDownConfirmed {
            downFrames = isDown ? downFrames + 1 : 0
            if downFrames >= cfg.squatConfirmationFrames {
                isDownConfirmed = true
                downSinceMs = nowMs
                upFrames = 0
            }
            return false
        }

        if nowMs - downSinceMs > cfg.squatMaxMovementMs {
            resetCycle()
            return false
        }

        upFrames = isUp ? upFrames + 1 : 0
        if upFrames < cfg.squatConfirmationFrames { return false }

        let duration = nowMs - downSinceMs
        resetCycle()
        return duration >= cfg.squatMinMovementMs
    }

    private func resetCycle() {
        downFrames = 0; upFrames = 0; missingFrames = 0
        downSinceMs = 0; isDownConfirmed = false
    }
}

// MARK: ─── Sweat Mode: Debug Info ───────────────────────────────────────────

struct SweatDebugInfo {
    var pushState: String = "idle"
    var squatState: String = "standing"
    var elbowAngle: CGFloat = 0
    var kneeAngle: CGFloat = 0
    var qualityScore: Int = 0
    var avgConfidence: CGFloat = 0
    var trackedJoints: Int = 0
    var lastRejection: String?
    var repDuration: TimeInterval = 0
    var elbowVelocity: CGFloat = 0
    var kneeVelocity: CGFloat = 0
}

// MARK: ─── Camera Model (AVFoundation + Vision Body Pose) ───────────────────

final class SweatCameraModel: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    // ── Public interface (unchanged from original) ──────────────────
    @Published var isReady = false
    @Published var statusText = AppLocalization.string("camera_required")
    @Published var needsPermissionButton = false
    @Published var repCount = 0
    @Published var bodyPoints: [VNHumanBodyPoseObservation.JointName: CGPoint] = [:]
    @Published var hasBody = false

    /// Optional debug overlay data. Toggle with `showDebug`.
    @Published var debugInfo: SweatDebugInfo?
    var showDebug = false

    let session = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let processingQueue = DispatchQueue(label: "com.spikeai.pose", qos: .userInitiated)

    // ── Detectors (ported from Android Athlete mode) ─────────────
    private let config = AthleteConfig()
    private lazy var pushDetector = AthletePushUpDetector(config)
    private lazy var squatDetector = AthleteSquatDetector(config)

    // ── Body overlay smoothing (display only) ─────────────────────
    private var stablePoints: [VNHumanBodyPoseObservation.JointName: CGPoint] = [:]
    private var missingJointFrames: [VNHumanBodyPoseObservation.JointName: Int] = [:]

    // ── Debug ─────────────────────────────────────────────────────
    private var lastRejectionReason: String?

    // ── Reusable Vision request ───────────────────────────────────
    private let poseRequest = VNDetectHumanBodyPoseRequest()

    // MARK: Lifecycle

    @MainActor
    func prepare() async {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            configureAndStart()
        case .notDetermined:
            needsPermissionButton = true
        case .denied, .restricted:
            statusText = AppLocalization.string("camera_disabled")
            needsPermissionButton = false
        @unknown default:
            statusText = AppLocalization.string("camera_unavailable")
            needsPermissionButton = false
        }
    }

    @MainActor
    func requestPermissionAndStart() async {
        let allowed = await AVCaptureDevice.requestAccess(for: .video)
        if allowed {
            configureAndStart()
        } else {
            statusText = AppLocalization.string("camera_disabled")
            needsPermissionButton = false
        }
    }

    func stop() {
        if session.isRunning { session.stopRunning() }
    }

    func resetReps() {
        processingQueue.async { [self] in
            pushDetector.reset()
            squatDetector.reset()
            stablePoints = [:]; missingJointFrames = [:]
            lastRejectionReason = nil
            DispatchQueue.main.async {
                self.repCount = 0
                self.debugInfo = nil
            }
        }
    }

    // MARK: Session Configuration

    @MainActor
    private func configureAndStart() {
        needsPermissionButton = false
        statusText = AppLocalization.string("starting_camera")

        session.beginConfiguration()
        session.sessionPreset = .high
        session.inputs.forEach { session.removeInput($0) }
        session.outputs.forEach { session.removeOutput($0) }

        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else {
            statusText = AppLocalization.string("front_camera_unavailable")
            isReady = false
            session.commitConfiguration()
            return
        }

        session.addInput(input)

        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.setSampleBufferDelegate(self, queue: processingQueue)
        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
            if let connection = videoOutput.connection(with: .video) {
                if connection.isVideoRotationAngleSupported(90) {
                    connection.videoRotationAngle = 90
                }
                if connection.isVideoMirroringSupported {
                    connection.isVideoMirrored = true
                }
            }
        }

        session.commitConfiguration()
        processingQueue.async { [weak self] in
            guard let self else { return }
            self.session.startRunning()
            DispatchQueue.main.async {
                self.statusText = AppLocalization.string("camera_active")
                self.isReady = true
            }
        }
    }

    // MARK: Frame Processing

    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])
        do {
            try handler.perform([poseRequest])
            guard let observation = bestObservation(from: poseRequest.results) else {
                ageTrackedPoints()
                return
            }
            processObservation(observation)
        } catch {
            // Skip frame
        }
    }

    // MARK: ── Core Analysis Pipeline (Athlete mode, ported from Android) ──

    private func processObservation(_ observation: VNHumanBodyPoseObservation) {
        let nowMs = Date().timeIntervalSince1970 * 1000

        // ── 1. Confidence-filtered raw landmarks ─────────────────
        let allJoints: [VNHumanBodyPoseObservation.JointName] = [
            .nose, .neck,
            .leftShoulder, .rightShoulder,
            .leftElbow, .rightElbow,
            .leftWrist, .rightWrist,
            .root,
            .leftHip, .rightHip,
            .leftKnee, .rightKnee,
            .leftAnkle, .rightAnkle
        ]
        var raw: [VNHumanBodyPoseObservation.JointName: CGPoint] = [:]
        for name in allJoints {
            guard let p = try? observation.recognizedPoint(name),
                  p.confidence >= config.jointConfidence else { continue }
            raw[name] = p.location
        }

        // ── 2. Compute exercise signals from whatever joints are visible ──
        // Push-ups need only ONE arm chain (shoulder-elbow-wrist); squats need a
        // leg chain (hip-knee-ankle) plus a shoulder for the hip angle. Each
        // exercise runs whenever its joints are present — no full body required.
        let elbow = elbowAngle(from: raw)
        let knee = kneeAngle(from: raw)
        let hip = hipAngle(from: raw)
        let hasArmChain = elbow != nil
        let hasLegChain = knee != nil && hip != nil

        // Mutual exclusion: a committed push-up (descended) blocks the squat
        // detector and vice-versa, so the same motion can never count twice.
        let pushBusy = pushDetector.inDownPhase
        let squatBusy = squatDetector.isActive

        // ── 3. Drive both detectors ──────────────────────────────
        var countedRep = false
        if hasArmChain && !squatBusy {
            if pushDetector.update(elbowAngle: elbow, nowMs: nowMs) { countedRep = true }
        } else {
            _ = pushDetector.update(elbowAngle: nil, nowMs: nowMs)
        }
        if hasLegChain && !pushBusy {
            if squatDetector.update(rawKnee: knee, rawHip: hip, nowMs: nowMs) { countedRep = true }
        } else {
            squatDetector.missingFrame()
        }

        if countedRep {
            DispatchQueue.main.async { self.repCount += 1 }
        }

        // ── 4. Stabilize points for the on-screen skeleton overlay ─
        let points = stabilizedPoints(from: raw, expectedJoints: allJoints)
        let detected = isTrackableBody(points)

        let debug = showDebug ? SweatDebugInfo(
            pushState: "\(pushDetector.state)",
            squatState: squatDetector.isActive ? "squat" : "standing",
            elbowAngle: pushDetector.smoothedElbow,
            kneeAngle: squatDetector.smoothedKnee,
            qualityScore: 0,
            avgConfidence: 0,
            trackedJoints: points.count,
            lastRejection: lastRejectionReason,
            repDuration: 0,
            elbowVelocity: 0,
            kneeVelocity: 0
        ) : nil

        DispatchQueue.main.async {
            self.bodyPoints = points
            self.hasBody = detected
            if self.showDebug { self.debugInfo = debug }
        }
    }

    // MARK: ── Exercise angle inputs (computed from visible joints) ──

    /// Elbow angle from whichever arm(s) are visible — averaged when both are
    /// present, otherwise the single available side. Returns nil if no arm chain.
    private func elbowAngle(from p: [VNHumanBodyPoseObservation.JointName: CGPoint]) -> CGFloat? {
        let left = jointAngle(p[.leftShoulder], p[.leftElbow], p[.leftWrist])
        let right = jointAngle(p[.rightShoulder], p[.rightElbow], p[.rightWrist])
        if let l = left, let r = right { return (l + r) / 2 }
        return left ?? right
    }

    private func kneeAngle(from p: [VNHumanBodyPoseObservation.JointName: CGPoint]) -> CGFloat? {
        let left = jointAngle(p[.leftHip], p[.leftKnee], p[.leftAnkle])
        let right = jointAngle(p[.rightHip], p[.rightKnee], p[.rightAnkle])
        return AthleteGeometry.combined(left, right, maxDisagreement: config.squatMaxSideDisagreement)
    }

    private func hipAngle(from p: [VNHumanBodyPoseObservation.JointName: CGPoint]) -> CGFloat? {
        let left = jointAngle(p[.leftShoulder], p[.leftHip], p[.leftKnee])
        let right = jointAngle(p[.rightShoulder], p[.rightHip], p[.rightKnee])
        return AthleteGeometry.combined(left, right, maxDisagreement: config.squatMaxSideDisagreement)
    }

    private func jointAngle(_ a: CGPoint?, _ b: CGPoint?, _ c: CGPoint?) -> CGFloat? {
        guard let a, let b, let c else { return nil }
        return AthleteGeometry.angle(a, b, c)
    }

    // MARK: ── Point Stabilization (overlay only) ──────────────────

    private func stabilizedPoints(
        from current: [VNHumanBodyPoseObservation.JointName: CGPoint],
        expectedJoints: [VNHumanBodyPoseObservation.JointName]
    ) -> [VNHumanBodyPoseObservation.JointName: CGPoint] {
        for joint in expectedJoints {
            if let point = current[joint] {
                if let prev = stablePoints[joint] {
                    let dist = hypot(point.x - prev.x, point.y - prev.y)
                    let weight = dist > 0.15 ? config.overlayPointSmoothing * 0.3 : config.overlayPointSmoothing
                    stablePoints[joint] = CGPoint(
                        x: weight * point.x + (1 - weight) * prev.x,
                        y: weight * point.y + (1 - weight) * prev.y
                    )
                } else {
                    stablePoints[joint] = point
                }
                missingJointFrames[joint] = 0
            } else if let missed = missingJointFrames[joint], missed < config.overlayRetainedFrames {
                missingJointFrames[joint] = missed + 1
            } else {
                stablePoints.removeValue(forKey: joint)
                missingJointFrames[joint] = config.overlayRetainedFrames
            }
        }
        return stablePoints
    }

    // MARK: ── Body Detection ──────────────────────────────────────

    private func isTrackableBody(_ points: [VNHumanBodyPoseObservation.JointName: CGPoint]) -> Bool {
        guard points.count >= config.minTrackedJoints else { return false }
        let hasTorso = points[.neck] != nil || points[.root] != nil || points[.leftHip] != nil || points[.rightHip] != nil
        let hasArm = (points[.leftElbow] != nil && points[.leftWrist] != nil)
                  || (points[.rightElbow] != nil && points[.rightWrist] != nil)
        let hasLeg = (points[.leftKnee] != nil) || (points[.rightKnee] != nil)
                  || (points[.leftHip] != nil) || (points[.rightHip] != nil)
        return hasTorso && (hasArm || hasLeg)
    }

    // MARK: ── Observation Selection ───────────────────────────────

    private func bestObservation(from results: [VNHumanBodyPoseObservation]?) -> VNHumanBodyPoseObservation? {
        results?.max { scoreObservation($0) < scoreObservation($1) }
    }

    private func scoreObservation(_ obs: VNHumanBodyPoseObservation) -> CGFloat {
        let keys: [VNHumanBodyPoseObservation.JointName] = [
            .neck, .root,
            .leftShoulder, .rightShoulder,
            .leftElbow, .rightElbow,
            .leftWrist, .rightWrist,
            .leftHip, .rightHip,
            .leftKnee, .rightKnee,
            .leftAnkle, .rightAnkle
        ]
        return keys.reduce(CGFloat.zero) { total, name in
            total + CGFloat((try? obs.recognizedPoint(name))?.confidence ?? 0)
        }
    }

    // MARK: ── Stale Point Aging ───────────────────────────────────

    private func ageTrackedPoints() {
        let retained = stabilizedPoints(from: [:], expectedJoints: Array(stablePoints.keys))
        let detected = isTrackableBody(retained)
        DispatchQueue.main.async {
            self.bodyPoints = retained
            self.hasBody = detected
        }
    }
}

// MARK: ─── Camera Preview ───────────────────────────────────────────────────

struct SweatCameraPreview: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.videoPreviewLayer.session = session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {
        uiView.videoPreviewLayer.session = session
    }

    final class PreviewView: UIView {
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
        var videoPreviewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
    }
}

// MARK: ─── Onboarding ────────────────────────────────────────────────────────

struct FocusOnboardingView: View {
    @Environment(FocusModeViewModel.self) var vm
    @Environment(AppLocalization.self) private var loc
    @Binding var isPresented: Bool

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    VStack(spacing: 12) {
                        Image(systemName: "shield.checkerboard")
                            .font(.system(size: 56)).foregroundStyle(.white.opacity(0.8))
                        Text(loc["focus_mode_title"]).font(.largeTitle).fontWeight(.bold)
                        Text(loc["focus_mode_desc"])
                            .font(.subheadline).foregroundStyle(.secondary)
                            .multilineTextAlignment(.center).padding(.horizontal)
                    }.padding(.top, 20)

                    VStack(spacing: 12) {
                        ForEach(FocusMode.allCases, id: \.self) { m in
                            OnboardingModeRow(focusMode: m)
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Label(loc["about_permissions"], systemImage: "lock.shield")
                            .font(.subheadline).fontWeight(.semibold)
                        Text(loc["permissions_desc"])
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    .padding().background(Color.spikeCard)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    Button {
                        vm.completeOnboarding(); isPresented = false
                    } label: {
                        Text(loc["get_started"]).fontWeight(.semibold)
                            .frame(maxWidth: .infinity).padding()
                            .background(Color.white).foregroundStyle(.black)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }.padding(.top, 4)
                }
                .padding()
                .iPadReadableScroll(maxWidth: 600)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        vm.completeOnboarding(); isPresented = false
                    } label: {
                        Text(loc["skip"])
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(Color.primary)
                    }
                }
            }
        }
    }
}

struct OnboardingModeRow: View {
    @Environment(AppLocalization.self) private var loc
    let focusMode: FocusMode
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: focusMode.icon)
                .font(.title2).foregroundStyle(focusMode.color)
                .frame(width: 44, height: 44)
                .background(focusMode.color.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            VStack(alignment: .leading, spacing: 3) {
                Text(localizedTitle).font(.subheadline).fontWeight(.semibold)
                Text(localizedDescription).font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding().frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.spikeCard)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var localizedTitle: String {
        switch focusMode {
        case .light: loc["chill"]
        case .medium: loc["focus"]
        case .hard: loc["lock_in"]
        case .sweat: loc["sweat"]
        }
    }

    private var localizedDescription: String {
        switch focusMode {
        case .light: loc["chill_desc"]
        case .medium: loc["focus_desc"]
        case .hard: loc["lock_in_desc"]
        case .sweat: loc["sweat_desc"]
        }
    }
}
