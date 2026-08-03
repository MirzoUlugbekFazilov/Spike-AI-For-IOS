//
//  ActivityScheduler.swift
//  Spike AI
//
//  Manages DeviceActivity scheduling for Lock-in and Sweat mode reapply behavior.
//

import Foundation

#if os(iOS)
import DeviceActivity
import FamilyControls
#endif

// MARK: - Activity Scheduler

@MainActor @Observable
final class ActivityScheduler {

    var isScheduleActive: Bool = false

    private let defaults: UserDefaults

    init() {
        defaults = UserDefaults(suiteName: FocusConstants.appGroupID) ?? .standard
        isScheduleActive = defaults.bool(forKey: FocusConstants.scheduleActiveKey)
    }

    // ═══════════════════════════════════════════════════════════════
    // MARK: ── Lock-in/Sweat Mode: Immediate Block Schedule ────────
    // ═══════════════════════════════════════════════════════════════

    /// Starts a full-day schedule for strict blocking modes.
    /// The DeviceActivityMonitor extension applies shields immediately
    /// when the interval starts (intervalDidStart) — NO threshold,
    /// NO bypass, NO "ignore limit" option.
    func startHardModeMonitoring() {
        #if os(iOS)
        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59),
            repeats: true
        )

        do {
            try DeviceActivityCenter().startMonitoring(
                .hardMode,
                during: schedule
            )
            isScheduleActive = true
            defaults.set(true, forKey: FocusConstants.scheduleActiveKey)
            #if DEBUG
            print("[Spike AI] Strict mode monitoring started (immediate block)")
            #endif
        } catch {
            #if DEBUG
            print("[Spike AI] Failed to start strict mode monitoring: \(error)")
            #endif
        }
        #endif
    }

    // ═══════════════════════════════════════════════════════════════
    // MARK: ── Focus (Medium) Mode: Re-block After Brief Usage ─────
    // ═══════════════════════════════════════════════════════════════

    /// Focus mode lets the user open a blocked app via the "Are you sure?"
    /// prompt, which removes that app's shield so it can launch. To make the
    /// prompt appear again on the next open, the DeviceActivityMonitor
    /// re-applies the shield once the user has spent a little time in the app.
    /// This schedules the usage-threshold event that drives that re-block.
    func startFocusModeMonitoring(selection: FamilyActivitySelection) {
        #if os(iOS)
        guard !selection.applicationTokens.isEmpty
            || !selection.categoryTokens.isEmpty
            || !selection.webDomainTokens.isEmpty
        else { return }

        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59),
            repeats: true
        )

        // Re-block after the user-selected amount of actual app usage so the
        // "Are you sure?" prompt is back in place for a future launch attempt.
        let event = DeviceActivityEvent(
            applications: selection.applicationTokens,
            categories: selection.categoryTokens,
            webDomains: selection.webDomainTokens,
            threshold: DateComponents(minute: focusRelockMinutes)
        )

        do {
            let center = DeviceActivityCenter()
            center.stopMonitoring([.mediumMode])
            try center.startMonitoring(
                .mediumMode,
                during: schedule,
                events: [.mediumUsage: event]
            )
            isScheduleActive = true
            defaults.set(true, forKey: FocusConstants.scheduleActiveKey)
            #if DEBUG
            print("[Spike AI] Focus mode monitoring started (re-block after usage)")
            #endif
        } catch {
            #if DEBUG
            print("[Spike AI] Failed to start Focus mode monitoring: \(error)")
            #endif
        }
        #endif
    }

    // ═══════════════════════════════════════════════════════════════
    // MARK: ── Stop All Monitoring ─────────────────────────────────
    // ═══════════════════════════════════════════════════════════════

    func stopAllMonitoring() {
        #if os(iOS)
        DeviceActivityCenter().stopMonitoring()
        isScheduleActive = false
        defaults.set(false, forKey: FocusConstants.scheduleActiveKey)
        #if DEBUG
        print("[Spike AI] All monitoring stopped")
        #endif
        #endif
    }
}

private extension ActivityScheduler {
    var focusRelockMinutes: Int {
        let saved = defaults.integer(forKey: FocusConstants.focusRelockMinutesKey)
        return FocusConstants.focusRelockMinuteOptions.contains(saved)
            ? saved
            : FocusConstants.defaultFocusRelockMinutes
    }
}

// MARK: - DeviceActivity Names & Events

#if os(iOS)
extension DeviceActivityName {
    /// Strict modes: immediate blocking on interval start
    static let hardMode = DeviceActivityName(rawValue: "SpikeAIHardMode")
    /// Focus mode: re-block after a short amount of usage so the
    /// "Are you sure?" prompt reappears on the next open.
    static let mediumMode = DeviceActivityName(rawValue: "SpikeAIMediumMode")
}

extension DeviceActivityEvent.Name {
    /// Fires once the user has spent the threshold time in a Focus-blocked app.
    static let mediumUsage = DeviceActivityEvent.Name(rawValue: "SpikeAIMediumUsage")
}
#endif
