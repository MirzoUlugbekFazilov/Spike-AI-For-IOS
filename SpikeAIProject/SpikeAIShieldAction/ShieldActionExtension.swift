//
//  ShieldActionExtension.swift
//  SpikeAIShieldAction
//
//  Handles button taps on the system shield.
//
//  ┌──────────────────────────────────────────────────────────────────┐
//  │  FOCUS:  "Yes, open app" opens once; "No" closes app.           │
//  │  LOCK-IN: "Close" closes app. No shield bypass.                 │
//  │  ATHLETE: "Open Camera Check" / "Close" both close the blocked  │
//  │           app (iOS shields cannot launch another app), sending  │
//  │           the user home so they can open Spike AI to earn time. │
//  └──────────────────────────────────────────────────────────────────┘
//

import ManagedSettings
import ManagedSettingsUI
import FamilyControls
import Foundation

@objc(SpikeAIShieldAction)
class SpikeAIShieldAction: ShieldActionDelegate {

    private let store = ManagedSettingsStore()
    private let defaultFocusRelockMinutes = 30
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

    override func handle(
        action: ShieldAction,
        for application: ApplicationToken,
        completionHandler: @escaping (ShieldActionResponse) -> Void
    ) {
        handleAction(action, completionHandler: completionHandler) { [weak self] in
            guard let self, var apps = self.store.shield.applications else { return }
            apps.remove(application)
            self.store.shield.applications = apps.isEmpty ? nil : apps
        }
    }

    override func handle(
        action: ShieldAction,
        for webDomain: WebDomainToken,
        completionHandler: @escaping (ShieldActionResponse) -> Void
    ) {
        handleAction(action, completionHandler: completionHandler) { [weak self] in
            guard let self, var domains = self.store.shield.webDomains else { return }
            domains.remove(webDomain)
            self.store.shield.webDomains = domains.isEmpty ? nil : domains
        }
    }

    override func handle(
        action: ShieldAction,
        for category: ActivityCategoryToken,
        completionHandler: @escaping (ShieldActionResponse) -> Void
    ) {
        handleAction(action, completionHandler: completionHandler) { [weak self] in
            self?.store.shield.applicationCategories = nil
            self?.store.shield.webDomainCategories = nil
        }
    }

    private var allGoalsCompleted: Bool {
        let completed = defaults?.integer(forKey: "linear_goals_completed") ?? 0
        let total = defaults?.integer(forKey: "linear_goals_total") ?? 0
        return total == 0 || completed >= total
    }

    private var sweatUnlockIsActive: Bool {
        let unlockUntil = defaults?.double(forKey: "linear_sweat_unlock_until") ?? 0
        return unlockUntil > Date().timeIntervalSince1970
    }

    private func handleAction(
        _ action: ShieldAction,
        completionHandler: @escaping (ShieldActionResponse) -> Void,
        unlockTappedTarget: @escaping () -> Void
    ) {
        let mode = defaults?.string(forKey: "linear_focus_mode") ?? "hard"
        let isActive = defaults?.bool(forKey: "linear_focus_active") ?? false

        guard isActive else {
            clearShields()
            completionHandler(.none)
            return
        }

        // Athlete (sweat) mode is movement-based: access is earned ONLY through
        // exercise, never by goal completion. Honor an active movement unlock,
        // otherwise keep the app closed regardless of which button was tapped.
        if mode == "sweat" {
            if sweatUnlockIsActive {
                clearShields()
                completionHandler(.none)
            } else {
                completionHandler(.close)
            }
            return
        }

        // Goal-based modes (Focus / Lock-in): no uncompleted goals → allow access.
        if allGoalsCompleted {
            clearShields()
            completionHandler(.none)
            return
        }

        switch action {
        case .primaryButtonPressed:
            if mode == "medium" {
                // Focus primary button is "Yes, open app".
                //
                // Remove only the tapped target so iOS can launch it. The
                // DeviceActivity monitor tracks actual usage, while this timer
                // is a deterministic fallback so the shield returns inside the
                // app after the user-selected Focus allowance.
                unlockTappedTarget()
                scheduleFocusRelock()
                completionHandler(.none)
            } else if mode == "light" {
                // Chill mode should not apply shields. Clear stale shield state.
                clearShields()
                completionHandler(.none)
            } else {
                // Lock-in mode: no shield bypass. (Athlete is handled earlier.)
                completionHandler(.close)
            }

        case .secondaryButtonPressed:
            // Focus secondary button is "No, back to goals" — close the app.
            completionHandler(.close)

        @unknown default:
            completionHandler(.close)
        }
    }

    private func clearShields() {
        store.shield.applications = nil
        store.shield.applicationCategories = nil
        store.shield.webDomains = nil
        store.shield.webDomainCategories = nil
        store.clearAllSettings()
    }

    private func scheduleFocusRelock() {
        let delay = TimeInterval(focusRelockMinutes * 60)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self else { return }
            guard self.defaults?.bool(forKey: "linear_focus_active") == true,
                  self.defaults?.string(forKey: "linear_focus_mode") == "medium",
                  !self.allGoalsCompleted
            else { return }

            self.applySavedShields()
        }
    }

    private func applySavedShields() {
        guard let data = defaults?.data(forKey: "linear_focus_selection"),
              let selection = try? JSONDecoder().decode(
                  FamilyActivitySelection.self,
                  from: data
              )
        else { return }

        let apps = selection.applicationTokens
        let cats = selection.categoryTokens
        let domains = selection.webDomainTokens

        guard !apps.isEmpty || !cats.isEmpty || !domains.isEmpty else { return }

        store.shield.applications = apps.isEmpty ? nil : apps
        store.shield.applicationCategories = cats.isEmpty
            ? nil
            : ShieldSettings.ActivityCategoryPolicy.specific(cats)
        store.shield.webDomains = domains.isEmpty ? nil : domains
        store.shield.webDomainCategories = cats.isEmpty
            ? nil
            : ShieldSettings.ActivityCategoryPolicy.specific(cats)
    }

    private var focusRelockMinutes: Int {
        let saved = defaults?.integer(forKey: "linear_focus_relock_minutes") ?? 0
        return focusRelockMinuteOptions.contains(saved)
            ? saved
            : defaultFocusRelockMinutes
    }

}
