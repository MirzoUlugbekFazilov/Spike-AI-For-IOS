//
//  AuthorizationManager.swift
//  Spike AI
//
//  Handles FamilyControls authorization (Screen Time permission).
//  Separated from blocking logic for clean MVVM architecture.
//
//  Key Apple API limitation:
//  - AuthorizationCenter.shared.requestAuthorization() can only be called
//    from the MAIN APP target, not from extensions.
//  - Authorization status can change at any time via Settings; always
//    re-read with refreshStatus() when the app returns to foreground.
//  - On Simulator, authorization always returns .denied.
//

import Foundation
import SwiftUI

#if os(iOS)
import FamilyControls
#endif

// MARK: - Authorization Status

enum STAuthStatus: String, Sendable {
    case notDetermined, approved, denied
}

// MARK: - Authorization Manager

@MainActor @Observable
final class AuthorizationManager {

    var status: STAuthStatus = .notDetermined
    var error: String?
    var isRequesting = false

    // MARK: Request

    /// Triggers Apple's in-app Screen Time permission dialog.
    /// Must be called from the main app target — extensions cannot request auth.
    func requestAuthorization() async {
        #if os(iOS)
        guard !isRequesting else { return }
        isRequesting = true
        defer { isRequesting = false }
        error = nil
        do {
            #if DEBUG
            print("[Spike AI][Auth] Requesting Screen Time authorization…")
            #endif
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
            refreshStatus()
            #if DEBUG
            print("[Spike AI][Auth] ✓ Authorization approved")
            #endif
        } catch {
            refreshStatus()
            self.error = error.localizedDescription
            #if DEBUG
            print("[Spike AI][Auth] ✗ Authorization failed: \(error)")
            #endif
        }
        #endif
    }

    // MARK: Refresh

    /// Re-reads the live status from AuthorizationCenter.
    /// Call on every scenePhase → .active so we catch Settings changes.
    func refreshStatus() {
        #if os(iOS)
        switch AuthorizationCenter.shared.authorizationStatus {
        case .approved:      status = .approved
        case .denied:        status = .denied
        case .notDetermined: status = .notDetermined
        @unknown default:    status = .notDetermined
        }
        #endif
    }

    // MARK: Open Settings

    func openSettings() {
        #if os(iOS)
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
        #endif
    }
}
