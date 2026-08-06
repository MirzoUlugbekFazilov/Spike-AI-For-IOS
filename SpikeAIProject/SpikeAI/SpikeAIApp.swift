//
//  SpikeAIApp.swift
//  Spike AI
//
//  Created by Мирзо-Улугбек Фазилов on 04/05/2026.
//

import SwiftUI
import UIKit
import UserNotifications

// Test comment for verifying the Git history workflow — safe to delete.

// MARK: - Notification Delegate

extension Notification.Name {
    /// Posted when a Quote of the Day notification is tapped. The object is the
    /// quote-day key ("yyyy-MM-dd") that notification was written for.
    static let spikeOpenQuoteOfTheDay = Notification.Name("spikeOpenQuoteOfTheDay")
}

/// Holds a tapped quote notification until the UI is ready for it.
///
/// On a cold launch the delegate fires before SwiftUI has installed its
/// observers, and `NotificationCenter` posts aren't buffered — so the day key is
/// parked here and consumed exactly once by whichever side gets there first.
enum QuoteDeepLink {
    private static let lock = NSLock()
    private static var pendingDayKey: String?

    static func set(_ dayKey: String) {
        lock.lock()
        defer { lock.unlock() }
        pendingDayKey = dayKey
    }

    static func consume() -> String? {
        lock.lock()
        defer { lock.unlock() }
        let dayKey = pendingDayKey
        pendingDayKey = nil
        return dayKey
    }
}

/// Ensures notifications are displayed even when the app is in the foreground.
class SpikeNotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let request = response.notification.request

        // Tapping the 5 AM quote opens it directly, carrying the notification's
        // own day so the sheet renders the quote that was actually delivered
        // rather than re-deriving "today" at tap time.
        if response.actionIdentifier == UNNotificationDefaultActionIdentifier,
           request.identifier.hasPrefix(NotificationManager.quoteIdentifierPrefix) {
            let dayKey = request.content.userInfo[NotificationManager.quoteDayInfoKey] as? String
                ?? String(request.identifier.dropFirst(NotificationManager.quoteIdentifierPrefix.count))

            QuoteDeepLink.set(dayKey)
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .spikeOpenQuoteOfTheDay, object: dayKey)
            }
        }

        completionHandler()
    }
}

@main
struct SpikeAIApp: App {
    @Environment(\.scenePhase) private var scenePhase

    // ── Core stores ──────────────────────────────────────────────
    @State private var auth           = AuthManager()
    @State private var taskStore      = TaskStore()
    @State private var dailyFocus     = DailyFocusStore()
    @State private var profileStore   = ProfileStore()
    @State private var goalStore      = GoalStore()
    @State private var usageStore     = UsageStore()
    @State private var progressSummaryStore = ProgressSummaryStore()
    @State private var progressMilestones = ProgressMilestoneStore()
    @State private var quoteTracking = QuoteTrackingStore()
    @State private var localization   = AppLocalization()

    // ── New MVVM managers ────────────────────────────────────────
    @State private var stAuth: AuthorizationManager
    @State private var blocker: AppBlockingManager
    @State private var scheduler: ActivityScheduler
    @State private var notifManager: NotificationManager

    // ── ViewModel (initialized in init) ──────────────────────────
    @State private var focusVM: FocusModeViewModel

    // ── Notification delegate (must be retained) ─────────────────
    private let notificationDelegate = SpikeNotificationDelegate()

    // ── Onboarding gates ───────────────────────────────────────────
    @State private var hasCompletedOnboarding: Bool
    @State private var hasCompletedScreenTimeOnboarding: Bool

    init() {
        // Register notification delegate so notifications show even when app is in foreground
        UNUserNotificationCenter.current().delegate = notificationDelegate

        Self.configureTabBarAppearance()

        // Create managers once, then inject into ViewModel
        let a = AuthorizationManager()
        let b = AppBlockingManager()
        let s = ActivityScheduler()
        let n = NotificationManager()

        _stAuth       = State(initialValue: a)
        _blocker      = State(initialValue: b)
        _scheduler    = State(initialValue: s)
        _notifManager = State(initialValue: n)
        _focusVM      = State(initialValue: FocusModeViewModel(
            auth: a, blocker: b, scheduler: s, notifications: n
        ))

        _hasCompletedOnboarding = State(initialValue:
            UserDefaults.standard.bool(forKey: OnboardingViewModel.completedKey)
        )
        let defaults = UserDefaults(suiteName: FocusConstants.appGroupID) ?? .standard
        _hasCompletedScreenTimeOnboarding = State(initialValue:
            defaults.bool(forKey: FocusConstants.screenTimeOnboardingKey)
        )
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if !hasCompletedOnboarding {
                    // ── First-launch onboarding (before auth) ──
                    OnboardingView {
                        completeOnboarding()
                    }
                    .environment(stAuth)
                    .environment(blocker)
                    .environment(localization)
                } else if !auth.hasResolvedSession {
                    SessionRestoreView()
                        .environment(localization)
                        .task { await auth.checkSession() }
                } else if auth.isLoggedIn {
                    if auth.needsNameSetup {
                        NameSetupView()
                            .environment(auth)
                            .environment(profileStore)
                            .environment(localization)
                    } else if hasCompletedScreenTimeOnboarding {
                        ContentView()
                            .environment(auth)
                            .environment(taskStore)
                            .environment(dailyFocus)
                            .environment(profileStore)
                            .environment(goalStore)
                            .environment(usageStore)
                            .environment(progressSummaryStore)
                            .environment(progressMilestones)
                            .environment(quoteTracking)
                            .environment(stAuth)
                            .environment(blocker)
                            .environment(scheduler)
                            .environment(notifManager)
                            .environment(focusVM)
                            .environment(localization)
                            .task { await loadAll() }
                    } else {
                        ScreenTimeOnboardingView {
                            completeScreenTimeOnboarding()
                        }
                        .environment(stAuth)
                        .environment(focusVM)
                        .environment(localization)
                    }
                } else {
                    AuthView(authManager: auth)
                        .environment(localization)
                }
            }
            .animation(.easeInOut(duration: 0.25), value: hasCompletedOnboarding)
            .animation(.easeInOut(duration: 0.25), value: auth.isLoggedIn)
            .animation(.easeInOut(duration: 0.25), value: auth.needsNameSetup)
            .animation(.easeInOut(duration: 0.25), value: hasCompletedScreenTimeOnboarding)
            .onOpenURL { url in
                Task { await auth.handleMagicLink(url: url) }
            }
            .onChange(of: auth.isLoggedIn) {
                if !auth.isLoggedIn {
                    resetSignedOutSessionState()
                }
            }
            .onChange(of: localization.language) {
                // Quote bodies are baked in days ahead, so rewrite them in the
                // new language — otherwise the banner and the sheet would show
                // the same quote in two different languages.
                guard let uid = auth.userId else { return }
                notifManager.scheduleDailyQuotes(userId: uid)
            }
            .onChange(of: scenePhase) {
                if scenePhase == .active {
                    Task { await auth.syncPendingProfileNameIfNeeded() }
                    // Flush any operations queued while offline
                    Task { await OfflineSyncManager.shared.syncPendingOperations() }
                }
            }
        }
    }

    private func completeOnboarding() {
        hasCompletedOnboarding = true
        // If user granted Screen Time during onboarding, skip the post-auth prompt
        stAuth.refreshStatus()
        if stAuth.status == .approved {
            completeScreenTimeOnboarding()
        }
    }

    private func completeScreenTimeOnboarding() {
        let defaults = UserDefaults(suiteName: FocusConstants.appGroupID) ?? .standard
        defaults.set(true, forKey: FocusConstants.screenTimeOnboardingKey)
        hasCompletedScreenTimeOnboarding = true
    }

    func loadAll() async {
        // Verify session silently in background for returning users
        await auth.checkSession()
        guard let uid = auth.userId else { return }
        async let tasks: () = taskStore.fetch(userId: uid)
        async let focus: () = dailyFocus.fetch(userId: uid)
        async let profile: () = profileStore.fetch(userId: uid)
        async let goals: () = goalStore.fetch(userId: uid)
        async let quotes: () = quoteTracking.fetch(userId: uid)
        _ = await (tasks, focus, profile, goals, quotes)

        // Schedule or cancel the midday "no goals" reminder
        let hasActiveGoals = goalStore.goals.contains { $0.status == GoalStatus.active.rawValue }
        if hasActiveGoals {
            notifManager.cancelNoGoalsReminder()
        } else {
            notifManager.scheduleNoGoalsReminder()
        }

        // Queue the 5 AM quote notifications for this user. The bodies are
        // derived from the same function the app displays from, so they stay in
        // step no matter how far ahead they were written.
        notifManager.scheduleDailyQuotes(userId: uid)

        // Flush any operations queued while offline
        await OfflineSyncManager.shared.syncPendingOperations()
    }

    private static func configureTabBarAppearance() {
        // Selected-tab pill background. Light mode uses a clearly visible
        // mid-gray (approx. systemGray4) so the active tab reads at a glance;
        // dark mode keeps a subtle elevated-surface tone that fits the palette.
        let selectionTint = UIColor { tc in
            tc.userInterfaceStyle == .dark
                ? UIColor(red: 0.22, green: 0.20, blue: 0.30, alpha: 1.0)
                : UIColor(red: 0.84, green: 0.84, blue: 0.86, alpha: 1.0)
        }

        // Selected icon + label color. In light mode we want pure black on
        // the gray pill (matches the reference); in dark mode, pure white.
        let selectedItemColor = UIColor { tc in
            tc.userInterfaceStyle == .dark ? .white : .black
        }

        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.selectionIndicatorTintColor = selectionTint

        // Apply the selected-item color across all tab bar layouts
        // (phone stacked, iPad inline, compact inline) so the pill icon/text
        // is consistently high-contrast on every device.
        for itemAppearance in [
            appearance.stackedLayoutAppearance,
            appearance.inlineLayoutAppearance,
            appearance.compactInlineLayoutAppearance
        ] {
            itemAppearance.selected.iconColor = selectedItemColor
            itemAppearance.selected.titleTextAttributes = [
                .foregroundColor: selectedItemColor
            ]
        }

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    private func resetSignedOutSessionState() {
        focusVM.deactivate()
        taskStore.resetForSignedOutUser()
        dailyFocus.resetForSignedOutUser()
        profileStore.resetForSignedOutUser()
        goalStore.resetForSignedOutUser()
        usageStore.resetForSignedOutUser()
        progressSummaryStore.resetForSignedOutUser()
        progressMilestones.resetForSignedOutUser()
        quoteTracking.resetForSignedOutUser()
        // The queued quotes belong to the user who just signed out; leaving them
        // would deliver their sequence to whoever signs in next.
        notifManager.cancelDailyQuotes()
        TaskReminderStore.shared.clearAll()
    }
}

private struct SessionRestoreView: View {
    @Environment(AppLocalization.self) private var loc

    var body: some View {
        ZStack {
            SpikeGradientBackground()
            VStack(spacing: 14) {
                Image("SpikeLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 72, height: 72)
                ProgressView()
                    .tint(.white)
                Text(loc["restoring_session"])
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.8))
            }
        }
    }
}
