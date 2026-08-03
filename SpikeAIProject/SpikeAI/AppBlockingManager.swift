//
//  AppBlockingManager.swift
//  Spike AI
//
//  Coordinates Screen Time shields for Focus modes.
//

import Foundation
import SwiftUI

#if os(iOS)
import FamilyControls
import ManagedSettings
#endif

@MainActor @Observable
final class AppBlockingManager {

    // ── App Selection ────────────────────────────────────────────
    #if os(iOS)
    var focusSelection = FamilyActivitySelection()
    #endif

    // ── Private ──────────────────────────────────────────────────
    #if os(iOS)
    private let focusStore = ManagedSettingsStore()
    #endif

    private let defaults: UserDefaults

    // MARK: Init

    init() {
        if let d = UserDefaults(suiteName: FocusConstants.appGroupID) {
            defaults = d
        } else {
            defaults = .standard
            #if DEBUG
            print("[Blocker] App Group defaults unavailable — using .standard")
            #endif
        }
        loadFocusSelection()
    }

    // ═══════════════════════════════════════════════════════════════
    // MARK: ── Focus Shields ───────────────────────────────────────
    // ═══════════════════════════════════════════════════════════════

    /// Apply shields to selected apps.
    /// Focus mode uses this shield as a confirmation prompt; Lock-in and Sweat modes use it as a block.
    func applyFocusShield() {
        #if os(iOS)
        let apps = focusSelection.applicationTokens
        let cats = focusSelection.categoryTokens

        focusStore.shield.applications = apps.isEmpty ? nil : apps
        focusStore.shield.applicationCategories = cats.isEmpty
            ? nil
            : ShieldSettings.ActivityCategoryPolicy.specific(cats)
        focusStore.shield.webDomains = focusSelection.webDomainTokens.isEmpty
            ? nil
            : focusSelection.webDomainTokens
        focusStore.shield.webDomainCategories = cats.isEmpty
            ? nil
            : ShieldSettings.ActivityCategoryPolicy.specific(cats)

        #if DEBUG
        print("[Blocker] Shields applied — \(apps.count) apps, \(cats.count) categories")
        #endif
        #endif
    }

    func removeFocusShield() {
        #if os(iOS)
        focusStore.shield.applications = nil
        focusStore.shield.applicationCategories = nil
        focusStore.shield.webDomains = nil
        focusStore.shield.webDomainCategories = nil
        focusStore.clearAllSettings()
        #if DEBUG
        print("[Blocker] Shields removed")
        #endif
        #endif
    }

    // ── Selection Persistence ────────────────────────────────────

    func saveFocusSelection() {
        #if os(iOS)
        guard let data = try? JSONEncoder().encode(focusSelection) else { return }
        defaults.set(data, forKey: FocusConstants.selectionKey)
        #endif
    }

    private func loadFocusSelection() {
        #if os(iOS)
        guard let data = defaults.data(forKey: FocusConstants.selectionKey),
              let saved = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data)
        else { return }
        focusSelection = saved
        #endif
    }

    var focusAppCount: Int {
        #if os(iOS)
        focusSelection.applicationTokens.count
        + focusSelection.categoryTokens.count
        + focusSelection.webDomainTokens.count
        #else
        0
        #endif
    }

    var hasFocusSelection: Bool {
        #if os(iOS)
        !focusSelection.applicationTokens.isEmpty
        || !focusSelection.categoryTokens.isEmpty
        || !focusSelection.webDomainTokens.isEmpty
        #else
        false
        #endif
    }

}
