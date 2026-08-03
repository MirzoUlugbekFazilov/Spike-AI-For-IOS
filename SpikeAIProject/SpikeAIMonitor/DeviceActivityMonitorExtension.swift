//
//  DeviceActivityMonitorExtension.swift
//  SpikeAIMonitor
//
//  Runs as a SEPARATE PROCESS. Powers the blocking and notification system.
//
//  HARD MODE: Immediate block on interval start.
//

import DeviceActivity
import ManagedSettings
import FamilyControls
import Foundation

@objc(SpikeAIMonitorExtension)
class SpikeAIMonitorExtension: DeviceActivityMonitor {

    private let store = ManagedSettingsStore()
    private let defaultFocusRelockMinutes = 1
    private let focusRelockMinuteOptions = [1, 5, 15, 30, 60]

    private var defaults: UserDefaults? {
        let defaults = UserDefaults(suiteName: "group.com.spikeai.spikeai")
        if let defaults,
           defaults.dictionaryRepresentation().isEmpty,
           let legacy = UserDefaults(suiteName: "group.Mirzo-Ulugbek-Fazilov.Linear")
        {
            for (key, value) in legacy.dictionaryRepresentation() {
                defaults.set(value, forKey: key)
            }
        }
        return defaults
    }

    /// True while the user has earned (and not yet used up) movement time in
    /// Athlete mode. During this window the app is intentionally unshielded.
    private var sweatUnlockIsActive: Bool {
        let unlockUntil = defaults?.double(forKey: "linear_sweat_unlock_until") ?? 0
        return unlockUntil > Date().timeIntervalSince1970
    }

    // ═══════════════════════════════════════════════════════════════
    // MARK: ── Interval Started ────────────────────────────────────
    // ═══════════════════════════════════════════════════════════════

    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)

        let mode = defaults?.string(forKey: "linear_focus_mode") ?? "medium"
        let isActive = defaults?.bool(forKey: "linear_focus_active") ?? false

        guard isActive else {
            clearShields()
            return
        }

        // Athlete (sweat) mode is movement-based: it always blocks regardless of
        // goals, and only lifts while the user has earned movement time. Handle
        // it before the goal check so finishing goals never unblocks it.
        if mode == "sweat" {
            if sweatUnlockIsActive {
                clearShields()
            } else {
                applyShields()
            }
            return
        }

        // Goal-based modes: if user has no uncompleted tasks, don't block apps.
        let totalTasks = defaults?.integer(forKey: "linear_goals_total") ?? 0
        let completedTasks = defaults?.integer(forKey: "linear_goals_completed") ?? 0
        if totalTasks == 0 || completedTasks >= totalTasks {
            clearShields()
            return
        }

        // Hard blocks immediately; Focus (medium) re-asserts the confirmation
        // shield at the start of each day so it stays in place.
        if mode == "hard" || mode == "medium" {
            applyShields()
        }
    }

    // ═══════════════════════════════════════════════════════════════
    // MARK: ── Threshold Reached (Medium Mode) ───────────────────
    // ═══════════════════════════════════════════════════════════════

    override func eventDidReachThreshold(
        _ event: DeviceActivityEvent.Name,
        activity: DeviceActivityName
    ) {
        super.eventDidReachThreshold(event, activity: activity)

        let totalTasks = defaults?.integer(forKey: "linear_goals_total") ?? 0
        let completedTasks = defaults?.integer(forKey: "linear_goals_completed") ?? 0
        let hasUncompleted = totalTasks > 0 && completedTasks < totalTasks
        if defaults?.string(forKey: "linear_focus_mode") == "medium" && hasUncompleted {
            // The user let an app through earlier and has now spent a little
            // time in it — re-apply the shield so the "Are you sure?" prompt
            // appears again next time, then re-arm so this can happen again.
            applyShields()
            rearmFocusMonitoring()
        }
    }

    // ═══════════════════════════════════════════════════════════════
    // MARK: ── Interval Ended ────────────────────────────────────
    // ═══════════════════════════════════════════════════════════════

    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)

        // Focus mode re-arms its monitoring throughout the day (see
        // rearmFocusMonitoring), which ends and restarts its interval. Don't
        // drop the shield on those boundaries — only strict schedules clear.
        if activity == DeviceActivityName(rawValue: "SpikeAIMediumMode") {
            return
        }

        clearShields()
    }

    // ═══════════════════════════════════════════════════════════════
    // MARK: ── Shield Application ────────────────────────────────
    // ═══════════════════════════════════════════════════════════════

    private func applyShields() {
        guard defaults?.bool(forKey: "linear_focus_active") == true else {
            clearShields()
            return
        }

        guard let data = defaults?.data(forKey: "linear_focus_selection"),
              let selection = try? JSONDecoder().decode(
                  FamilyActivitySelection.self, from: data
              )
        else {
            clearShields()
            return
        }

        let apps = selection.applicationTokens
        let cats = selection.categoryTokens
        let domains = selection.webDomainTokens

        guard !apps.isEmpty || !cats.isEmpty || !domains.isEmpty else {
            clearShields()
            return
        }

        store.shield.applications = apps.isEmpty ? nil : apps
        store.shield.applicationCategories = cats.isEmpty
            ? nil
            : ShieldSettings.ActivityCategoryPolicy.specific(cats)
        store.shield.webDomains = domains.isEmpty
            ? nil
            : domains
        store.shield.webDomainCategories = cats.isEmpty
            ? nil
            : ShieldSettings.ActivityCategoryPolicy.specific(cats)
    }

    private func clearShields() {
        store.shield.applications = nil
        store.shield.applicationCategories = nil
        store.shield.webDomains = nil
        store.shield.webDomainCategories = nil
        store.clearAllSettings()
    }

    // ═══════════════════════════════════════════════════════════════
    // MARK: ── Re-arm Focus Usage Event ──────────────────────────
    // ═══════════════════════════════════════════════════════════════

    /// A usage-threshold event only fires once per monitoring interval. After it
    /// fires we restart monitoring so the next time the user lets an app through,
    /// the shield is re-applied again. Names match ActivityScheduler.
    private func rearmFocusMonitoring() {
        guard defaults?.bool(forKey: "linear_focus_active") == true,
              defaults?.string(forKey: "linear_focus_mode") == "medium",
              let data = defaults?.data(forKey: "linear_focus_selection"),
              let selection = try? JSONDecoder().decode(
                  FamilyActivitySelection.self, from: data
              )
        else { return }

        guard !selection.applicationTokens.isEmpty
            || !selection.categoryTokens.isEmpty
            || !selection.webDomainTokens.isEmpty
        else { return }

        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59),
            repeats: true
        )

        let event = DeviceActivityEvent(
            applications: selection.applicationTokens,
            categories: selection.categoryTokens,
            webDomains: selection.webDomainTokens,
            threshold: DateComponents(minute: focusRelockMinutes)
        )

        let center = DeviceActivityCenter()
        center.stopMonitoring([DeviceActivityName(rawValue: "SpikeAIMediumMode")])
        try? center.startMonitoring(
            DeviceActivityName(rawValue: "SpikeAIMediumMode"),
            during: schedule,
            events: [DeviceActivityEvent.Name(rawValue: "SpikeAIMediumUsage"): event]
        )
    }

    private var focusRelockMinutes: Int {
        let saved = defaults?.integer(forKey: "linear_focus_relock_minutes") ?? 0
        return focusRelockMinuteOptions.contains(saved)
            ? saved
            : defaultFocusRelockMinutes
    }

}
