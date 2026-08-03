//
//  FocusModeViewModel.swift
//  Spike AI
//
//  MVVM ViewModel that coordinates AuthorizationManager, AppBlockingManager,
//  ActivityScheduler, and NotificationManager to implement the focus system.
//

import Foundation
import SwiftUI
import UserNotifications

// MARK: - Shared Constants (App ↔ Extensions)

enum FocusConstants {
    static let appGroupID              = "group.com.spikeai.spikeai"
    static let legacyAppGroupID        = "group.Mirzo-Ulugbek-Fazilov.Linear"
    static let modeKey                 = "linear_focus_mode"
    static let isActiveKey             = "linear_focus_active"
    static let selectionKey            = "linear_focus_selection"
    static let onboardingKey           = "linear_focus_onboarding_done"
    static let remindersKey            = "linear_focus_reminders"
    static let screenTimeOnboardingKey = "linear_screentime_onboarding_done"
    static let scheduleActiveKey       = "linear_schedule_active"
    static let shieldDismissedKey      = "linear_shield_dismissed_at"
    static let sweatUnlockUntilKey     = "linear_sweat_unlock_until"
    static let focusRelockMinutesKey   = "linear_focus_relock_minutes"
    // New users start with a 30-minute "Ask Again After" allowance; they can
    // change it anytime from the Focus screen.
    static let defaultFocusRelockMinutes = 30
    static let focusRelockMinuteOptions = [1, 5, 15, 30, 60]
    static let maxSweatUnlock: Double  = 15 * 60
}

enum AppGroupStorage {
    static func makeDefaults() -> UserDefaults {
        let defaults = UserDefaults(suiteName: FocusConstants.appGroupID) ?? .standard
        migrateIfNeeded(to: defaults)
        return defaults
    }

    static func migrateIfNeeded(to defaults: UserDefaults) {
        guard let legacy = UserDefaults(suiteName: FocusConstants.legacyAppGroupID) else {
            return
        }
        guard defaults.dictionaryRepresentation().isEmpty else {
            return
        }

        for (key, value) in legacy.dictionaryRepresentation() {
            defaults.set(value, forKey: key)
        }
    }
}

// MARK: - Focus Mode Enum

enum FocusMode: String, CaseIterable, Codable {
    case light, medium, hard, sweat

    var title: String {
        switch self {
        case .light:  AppLocalization.string("chill")
        case .medium: AppLocalization.string("focus")
        case .hard:   AppLocalization.string("lock_in")
        case .sweat:  AppLocalization.string("sweat")
        }
    }

    var subtitle: String {
        switch self {
        case .light:  AppLocalization.string("gentle_nudges")
        case .medium: AppLocalization.string("confirm_intent")
        case .hard:   AppLocalization.string("no_bypass")
        case .sweat:  AppLocalization.string("move_to_unlock")
        }
    }

    var description: String {
        switch self {
        case .light:
            AppLocalization.string("chill_desc")
        case .medium:
            AppLocalization.string("focus_desc")
        case .hard:
            AppLocalization.string("lock_in_desc")
        case .sweat:
            AppLocalization.string("sweat_desc")
        }
    }

    var icon: String {
        switch self {
        case .light:  "bell.badge"
        case .medium: "shield.lefthalf.filled"
        case .hard:   "lock.shield"
        case .sweat:  "figure.strengthtraining.traditional"
        }
    }

    var color: Color {
        switch self {
        case .light:  .blue
        case .medium: .orange
        case .hard:   .red
        case .sweat:  .teal
        }
    }
}

// MARK: - Focus Mode ViewModel

@MainActor @Observable
final class FocusModeViewModel {

    // ── Published State ──────────────────────────────────────────
    var selectedMode: FocusMode = .light
    var isActive: Bool = false
    var hasCompletedOnboarding: Bool = false
    var sweatUnlockUntil: Date?
    var activationError: String?
    var showDeactivationAlert: Bool = false
    var showChillSwitchAlert: Bool = false
    var showNoGoalsAlert: Bool = false
    var pendingChillSwitch: Bool = false
    var focusRelockMinutes: Int = FocusConstants.defaultFocusRelockMinutes

    // ── Managers (injected) ──────────────────────────────────────
    let auth: AuthorizationManager
    let blocker: AppBlockingManager
    let scheduler: ActivityScheduler
    let notifications: NotificationManager

    // ── Private ──────────────────────────────────────────────────
    private let defaults: UserDefaults
    private var mediumReapplyTask: Task<Void, Never>?

    // MARK: Init

    init(
        auth: AuthorizationManager,
        blocker: AppBlockingManager,
        scheduler: ActivityScheduler,
        notifications: NotificationManager
    ) {
        self.auth = auth
        self.blocker = blocker
        self.scheduler = scheduler
        self.notifications = notifications

        defaults = AppGroupStorage.makeDefaults()

        // Restore persisted state
        if let raw = defaults.string(forKey: FocusConstants.modeKey),
           let mode = FocusMode(rawValue: raw) {
            selectedMode = mode
        }
        isActive = defaults.bool(forKey: FocusConstants.isActiveKey)
        hasCompletedOnboarding = defaults.bool(forKey: FocusConstants.onboardingKey)
        focusRelockMinutes = Self.normalizedFocusRelockMinutes(
            defaults.integer(forKey: FocusConstants.focusRelockMinutesKey)
        )
        defaults.set(focusRelockMinutes, forKey: FocusConstants.focusRelockMinutesKey)
        let unlockUntil = defaults.double(forKey: FocusConstants.sweatUnlockUntilKey)
        if unlockUntil > 0 { sweatUnlockUntil = Date(timeIntervalSince1970: unlockUntil) }
    }

    // ═══════════════════════════════════════════════════════════════
    // MARK: ── Mode Selection ──────────────────────────────────────
    // ═══════════════════════════════════════════════════════════════

    func setMode(_ mode: FocusMode) {
        // Already on this mode — do nothing
        guard mode != selectedMode else { return }

        // Focus and Lock-in only make sense when there's something to work toward.
        // Block turning them on when the user has no uncompleted goals for today.
        if (mode == .medium || mode == .hard) && !hasUncompletedGoals {
            showNoGoalsAlert = true
            return
        }

        // Warn when switching from a blocking mode to Chill with uncompleted goals
        let isBlockingMode = selectedMode == .medium || selectedMode == .hard
        if isBlockingMode && mode == .light && isActive && hasUncompletedGoals {
            pendingChillSwitch = true
            showChillSwitchAlert = true
            return
        }
        performModeSwitch(mode)
    }

    /// Called after user confirms the chill switch alert.
    func confirmChillSwitch() {
        pendingChillSwitch = false
        performModeSwitch(.light)
    }

    func cancelChillSwitch() {
        pendingChillSwitch = false
    }

    /// True when the user has at least one task scheduled for today that is
    /// not yet completed. Focus and Lock-in modes require this.
    var hasUncompletedGoals: Bool {
        let total = defaults.integer(forKey: "linear_goals_total")
        let completed = defaults.integer(forKey: "linear_goals_completed")
        return total > 0 && completed < total
    }

    func setFocusRelockMinutes(_ minutes: Int) {
        let normalized = Self.normalizedFocusRelockMinutes(minutes)
        focusRelockMinutes = normalized
        defaults.set(normalized, forKey: FocusConstants.focusRelockMinutesKey)

        if isActive && selectedMode == .medium {
            scheduler.startFocusModeMonitoring(selection: blocker.focusSelection)
        }
    }

    private static func normalizedFocusRelockMinutes(_ minutes: Int) -> Int {
        FocusConstants.focusRelockMinuteOptions.contains(minutes)
            ? minutes
            : FocusConstants.defaultFocusRelockMinutes
    }

    private func performModeSwitch(_ mode: FocusMode) {
        if isActive { deactivate() }
        mediumReapplyTask?.cancel()
        selectedMode = mode
        defaults.set(mode.rawValue, forKey: FocusConstants.modeKey)
        activate()
    }

    /// Ensures a mode is always active. Called on app launch / view appear.
    func ensureModeActive() {
        if !isActive { activate() }
    }

    /// Deactivates the current mode and switches to Chill as fallback.
    func performFallbackToChill() {
        deactivate()
        selectedMode = .light
        defaults.set(FocusMode.light.rawValue, forKey: FocusConstants.modeKey)
        activate()
    }

    // ═══════════════════════════════════════════════════════════════
    // MARK: ── Activate / Deactivate ───────────────────────────────
    // ═══════════════════════════════════════════════════════════════

    func activate() {
        activationError = nil
        guard canActivate else {
            activationError = activationFailureMessage
            return
        }

        isActive = true
        defaults.set(true, forKey: FocusConstants.isActiveKey)
        recordModeForToday()

        // Check if user has any daily tasks — Focus and Lock-in only block when tasks exist
        let totalTasks = defaults.integer(forKey: "linear_goals_total")
        let hasTasks = totalTasks > 0

        switch selectedMode {
        case .light:
            notifications.rescheduleAll()
            scheduleChillMorningNotification()

        case .medium:
            blocker.saveFocusSelection()
            if hasTasks {
                blocker.applyFocusShield()
                // Background re-block so the "Are you sure?" prompt reappears on
                // the next open after the user lets an app through.
                scheduler.startFocusModeMonitoring(selection: blocker.focusSelection)
            }

        case .hard:
            blocker.saveFocusSelection()
            if hasTasks { blocker.applyFocusShield() }
            scheduler.startHardModeMonitoring()

        case .sweat:
            blocker.saveFocusSelection()
            scheduler.startHardModeMonitoring()
            refreshSweatShield()
        }
    }

    func deactivate() {
        isActive = false
        mediumReapplyTask?.cancel()
        defaults.set(false, forKey: FocusConstants.isActiveKey)
        defaults.removeObject(forKey: FocusConstants.shieldDismissedKey)

        switch selectedMode {
        case .light:
            notifications.cancelAll()

        case .medium:
            blocker.removeFocusShield()
            scheduler.stopAllMonitoring()

        case .hard, .sweat:
            blocker.removeFocusShield()
            scheduler.stopAllMonitoring()
            clearSweatUnlock()
        }
    }

    /// Check for uncompleted goals and show a motivational alert, or switch to Chill.
    func requestDeactivation() {
        // If already on Chill, nothing to deactivate to
        guard selectedMode != .light else { return }

        if hasUncompletedGoals {
            showDeactivationAlert = true
        } else {
            performFallbackToChill()
        }
    }

    /// Called when today's goals change. Once every goal is finished (or none
    /// remain uncompleted), a blocking mode has served its purpose, so we
    /// gracefully fall back to Chill and lift app restrictions automatically.
    func autoSwitchToChillIfGoalsDone() {
        guard isActive,
              selectedMode == .medium || selectedMode == .hard,
              !hasUncompletedGoals else { return }
        performFallbackToChill()
    }

    // ═══════════════════════════════════════════════════════════════
    // MARK: ── Permission Checks ───────────────────────────────────
    // ═══════════════════════════════════════════════════════════════

    var canActivate: Bool {
        switch selectedMode {
        case .light:
            return notifications.authorizationStatus == .authorized
        case .medium, .hard, .sweat:
            return auth.status == .approved && blocker.hasFocusSelection
        }
    }

    private var activationFailureMessage: String {
        switch selectedMode {
        case .light:
            return AppLocalization.string("enable_notif_chill")
        case .medium, .hard, .sweat:
            if auth.status != .approved {
                return AppLocalization.string("enable_screen_time_mode")
            }
            if !blocker.hasFocusSelection {
                return AppLocalization.string("select_app_before_mode")
            }
            return AppLocalization.string("mode_not_ready")
        }
    }

    func autoRequestIfNeeded() {
        switch selectedMode {
        case .medium, .hard, .sweat:
            if auth.status != .approved {
                Task { await auth.requestAuthorization() }
            }
        case .light:
            if notifications.authorizationStatus != .authorized {
                Task { await notifications.requestAuthorization() }
            }
        }
    }

    // ═══════════════════════════════════════════════════════════════
    // MARK: ── Foreground Refresh ──────────────────────────────────
    // ═══════════════════════════════════════════════════════════════

    func onForeground() {
        auth.refreshStatus()

        if isActive,
           selectedMode != .light,
           (auth.status != .approved || !blocker.hasFocusSelection) {
            deactivate()
            activationError = auth.status == .approved
                ? AppLocalization.string("protection_stopped_no_apps")
                : AppLocalization.string("protection_stopped_screen_time")
            return
        }

        if isActive && selectedMode == .medium {
            // Re-apply the shield now (instant re-block whenever the user passes
            // back through Spike AI) and make sure the background usage monitor
            // is running so apps the user let through get re-blocked on their own.
            blocker.applyFocusShield()
            scheduler.startFocusModeMonitoring(selection: blocker.focusSelection)
        }

        if isActive && selectedMode == .sweat {
            refreshSweatShield()
        }
    }

    var sweatUnlockRemaining: TimeInterval {
        guard let sweatUnlockUntil else { return 0 }
        return max(0, sweatUnlockUntil.timeIntervalSinceNow)
    }

    func addSweatUnlockMinute() {
        let base = max(Date(), sweatUnlockUntil ?? Date())
        let maximumUnlock = Date().addingTimeInterval(FocusConstants.maxSweatUnlock)
        let nextUnlock = min(base.addingTimeInterval(60), maximumUnlock)
        sweatUnlockUntil = nextUnlock
        defaults.set(nextUnlock.timeIntervalSince1970, forKey: FocusConstants.sweatUnlockUntilKey)
        blocker.removeFocusShield()
        scheduleSweatRelock(after: nextUnlock.timeIntervalSinceNow)
    }

    private func clearSweatUnlock() {
        sweatUnlockUntil = nil
        defaults.removeObject(forKey: FocusConstants.sweatUnlockUntilKey)
    }

    private func refreshSweatShield() {
        if sweatUnlockRemaining > 0 {
            blocker.removeFocusShield()
            scheduleSweatRelock(after: sweatUnlockRemaining)
        } else {
            clearSweatUnlock()
            blocker.applyFocusShield()
        }
    }

    private func scheduleSweatRelock(after delay: TimeInterval) {
        mediumReapplyTask?.cancel()
        mediumReapplyTask = Task { [weak self] in
            let nanoseconds = UInt64(max(delay, 0) * 1_000_000_000)
            try? await Task.sleep(nanoseconds: nanoseconds)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                guard let self, self.isActive, self.selectedMode == .sweat else { return }
                self.clearSweatUnlock()
                self.blocker.applyFocusShield()
            }
        }
    }

    // ═══════════════════════════════════════════════════════════════
    // MARK: ── Onboarding ──────────────────────────────────────────
    // ═══════════════════════════════════════════════════════════════

    func completeOnboarding() {
        hasCompletedOnboarding = true
        defaults.set(true, forKey: FocusConstants.onboardingKey)
    }

    // ═══════════════════════════════════════════════════════════════
    // MARK: ── Mode History (for calendar) ─────────────────────────
    // ═══════════════════════════════════════════════════════════════

    private func recordModeForToday() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        let today = formatter.string(from: Date())
        var history = defaults.dictionary(forKey: "spike_mode_history") as? [String: String] ?? [:]
        history[today] = selectedMode.title

        // Prune entries older than 365 days
        let cutoff = Calendar.current.date(byAdding: .day, value: -365, to: Date()) ?? Date()
        history = history.filter { key, _ in
            guard let date = formatter.date(from: key) else { return false }
            return date >= cutoff
        }

        defaults.set(history, forKey: "spike_mode_history")
    }

    // ═══════════════════════════════════════════════════════════════
    // MARK: ── Chill Morning Notification ──────────────────────────
    // ═══════════════════════════════════════════════════════════════

    private func scheduleChillMorningNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Spike AI"
        content.body = AppLocalization.string("chill_morning_body")
        content.sound = .default

        // Fire daily at 7:30 AM
        var comps = DateComponents()
        comps.hour = 7
        comps.minute = 30
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
        let request = UNNotificationRequest(
            identifier: "spike_chill_morning",
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request)
    }

    /// Auto-activate Chill mode on first launch if no mode has been activated yet.
    func autoActivateChillIfNeeded() {
        guard !isActive, !defaults.bool(forKey: "spike_chill_auto_activated") else { return }
        defaults.set(true, forKey: "spike_chill_auto_activated")
        selectedMode = .light
        defaults.set(FocusMode.light.rawValue, forKey: FocusConstants.modeKey)
        activate()
    }
}
