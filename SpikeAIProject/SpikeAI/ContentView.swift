//
//  ContentView.swift
//  Spike AI
//

import SwiftUI
import UIKit
import UserNotifications
import AudioToolbox
import AVFoundation
#if canImport(ActivityKit)
import ActivityKit
#endif

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - Dark Midnight Palette
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

extension Color {
    // Top of gradient (slightly tinted in light, cosmic purple-navy in dark)
    static let spikeBgTop = Color(uiColor: UIColor { tc in
        tc.userInterfaceStyle == .dark
            ? UIColor(red: 0.10, green: 0.06, blue: 0.22, alpha: 1)
            : UIColor(red: 0.91, green: 0.91, blue: 0.93, alpha: 1)
    })
    // Bottom of gradient (very light in light mode, deep space in dark)
    static let spikeBgBottom = Color(uiColor: UIColor { tc in
        tc.userInterfaceStyle == .dark
            ? UIColor(red: 0.02, green: 0.01, blue: 0.06, alpha: 1)
            : UIColor(red: 0.97, green: 0.97, blue: 0.98, alpha: 1)
    })
    // Fallback solid for List backgrounds
    static let spikeBg = Color(uiColor: UIColor { tc in
        tc.userInterfaceStyle == .dark
            ? UIColor(red: 0.02, green: 0.01, blue: 0.06, alpha: 1)
            : .systemGroupedBackground
    })
    static let spikeCard = Color(uiColor: UIColor { tc in
        tc.userInterfaceStyle == .dark
            ? UIColor(red: 0.09, green: 0.07, blue: 0.14, alpha: 1)
            : .secondarySystemGroupedBackground
    })
    static let spikeCardBorder = Color(uiColor: UIColor { tc in
        tc.userInterfaceStyle == .dark
            ? UIColor(red: 0.15, green: 0.12, blue: 0.22, alpha: 1)
            : .separator
    })
}

struct SpikeGradientBackground: View {
    var body: some View {
        LinearGradient(
            colors: [.spikeBgTop, .spikeBgBottom],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - iPad Adaptive Layout
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/// Reliable iPad detection using UIDevice (works always, unlike horizontalSizeClass).
enum DeviceLayout {
    static let isPad: Bool = UIDevice.current.userInterfaceIdiom == .pad
}

/// Constrains content to a readable width on iPad while remaining full-width on iPhone.
/// Uses a single view tree (no if/else branching) to avoid SwiftUI identity issues.
/// Explicitly preserves maxHeight: .infinity so Spacer-based layouts expand correctly.
struct iPadReadableWidth: ViewModifier {
    var maxWidth: CGFloat

    func body(content: Content) -> some View {
        content
            .frame(maxWidth: DeviceLayout.isPad ? maxWidth : .infinity, maxHeight: .infinity, alignment: .center)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }
}

/// Same as iPadReadableWidth but does NOT force maxHeight: .infinity.
/// Use for content inside ScrollView where height should fit content, not expand.
struct iPadReadableScrollWidth: ViewModifier {
    var maxWidth: CGFloat

    func body(content: Content) -> some View {
        content
            .frame(maxWidth: DeviceLayout.isPad ? maxWidth : .infinity, alignment: .center)
            .frame(maxWidth: .infinity, alignment: .center)
    }
}

extension View {
    /// Constrains content to a max width on iPad (regular size class), centered.
    /// Forces maxHeight: .infinity so Spacer-based layouts fill available height.
    func iPadReadable(maxWidth: CGFloat = 680) -> some View {
        modifier(iPadReadableWidth(maxWidth: maxWidth))
    }

    /// Constrains content width on iPad but does NOT force height expansion.
    /// Use inside ScrollView where content height should fit naturally.
    func iPadReadableScroll(maxWidth: CGFloat = 680) -> some View {
        modifier(iPadReadableScrollWidth(maxWidth: maxWidth))
    }
}

#if canImport(ActivityKit)
struct LiveTaskItem: Codable, Hashable {
    let title: String
    let done: Bool
    let priority: String
}

struct DailyGoalsActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var completedGoals: Int
        var totalGoals: Int
        var streak: Int
        var motivation: String
        var tasks: [LiveTaskItem]

        init(completedGoals: Int, totalGoals: Int, streak: Int, motivation: String, tasks: [LiveTaskItem] = []) {
            self.completedGoals = completedGoals
            self.totalGoals = totalGoals
            self.streak = streak
            self.motivation = motivation
            self.tasks = tasks
        }
    }

    var title: String
}

@MainActor
enum DailyGoalsLiveActivityManager {
    private static var motivations: [String] {
        [
            AppLocalization.string("motivation_small_wins"),
            AppLocalization.string("motivation_next_step"),
            AppLocalization.string("motivation_protect_hour"),
            AppLocalization.string("motivation_consistency"),
            AppLocalization.string("stay_with_plan"),
        ]
    }

    static func sync(isEnabled: Bool, tasks: [TaskRecord], streak: Int, showCompleted: Bool = true) async {
        guard #available(iOS 16.2, *) else { return }
        if isEnabled {
            await startOrUpdate(tasks: tasks, streak: streak, showCompleted: showCompleted)
        } else {
            await endAll()
        }
    }

    static func endAll() async {
        guard #available(iOS 16.2, *) else { return }
        for activity in Activity<DailyGoalsActivityAttributes>.activities {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
    }

    private static func startOrUpdate(tasks: [TaskRecord], streak: Int, showCompleted: Bool = true) async {
        // Filter tasks based on showCompleted preference, then build items for the Live Activity
        let displayTasks = showCompleted ? tasks : tasks.filter { !$0.completed }
        let liveItems: [LiveTaskItem] = displayTasks.prefix(8).map { task in
            LiveTaskItem(
                title: String(task.title.prefix(32)),
                done: task.completed,
                priority: task.priority ?? "medium"
            )
        }

        let state = DailyGoalsActivityAttributes.ContentState(
            completedGoals: tasks.filter(\.completed).count,
            totalGoals: tasks.count,
            streak: streak,
            motivation: motivations.randomElement() ?? AppLocalization.string("stay_with_plan"),
            tasks: liveItems
        )
        let content = ActivityContent(state: state, staleDate: Calendar.current.date(byAdding: .hour, value: 3, to: Date()))

        if let activity = Activity<DailyGoalsActivityAttributes>.activities.first {
            await activity.update(content)
            return
        }

        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        do {
            _ = try Activity.request(
                attributes: DailyGoalsActivityAttributes(title: AppLocalization.string("daily_goals_title")),
                content: content,
                pushType: nil
            )
        } catch {
            // Live Activities can fail if the system setting is disabled; the app still works normally.
        }
    }
}
#endif

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - Task Reminder Store (notifications + alarms)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

struct AlarmEntry: Codable {
    let taskId: String
    let title: String
    let time: Date
    var dismissed: Bool
    /// Set once the system (AlarmKit) took ownership of this alarm. Optional so
    /// entries written before AlarmKit existed still decode.
    var alarmKit: Bool?

    var isSystemAlarm: Bool { alarmKit == true }
}

@MainActor @Observable
final class TaskReminderStore {
    static let shared = TaskReminderStore()
    private let notifKey = "spike_task_notifs"
    private let alarmKey = "spike_task_alarms"
    /// Bumped on every change so SwiftUI re-renders task rows.
    var revision: UInt = 0

    // ── Notification (standard) ──────────────────────────────────────
    func setNotification(for taskId: String, title: String, at date: Date) {
        guard date > Date().addingTimeInterval(10) else {
            print("[Spike AI] ⚠️ Notification skipped — date \(date) is not >10s in the future")
            return
        }
        var dict = notifDict()
        dict[taskId] = date.timeIntervalSince1970
        UserDefaults.standard.set(dict, forKey: notifKey)
        revision += 1

        let c = UNMutableNotificationContent()
        c.title = AppLocalization.string("task_notification")
        c.body = sanitizedTitle(title)
        c.sound = .default
        c.interruptionLevel = .timeSensitive
        let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let req = UNNotificationRequest(
            identifier: "notif-\(taskId)", content: c,
            trigger: UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        )
        Task {
            let center = UNUserNotificationCenter.current()

            // Check authorization before scheduling
            let settings = await center.notificationSettings()
            print("[Spike AI] 🔔 Notification auth status: \(settings.authorizationStatus.rawValue) (2=authorized)")

            do {
                try await center.add(req)
                print("[Spike AI] ✅ Notification scheduled for \(date) — id: notif-\(taskId)")
            } catch {
                print("[Spike AI] ❌ Notification scheduling FAILED: \(error.localizedDescription)")
            }

            // Verify it's in the pending list
            let pending = await center.pendingNotificationRequests()
            let found = pending.contains { $0.identifier == "notif-\(taskId)" }
            print("[Spike AI] 📋 Pending notifications: \(pending.count), this one found: \(found)")
        }
    }

    func getNotificationTime(for taskId: String) -> Date? {
        guard let ts = notifDict()[taskId] else { return nil }
        return Date(timeIntervalSince1970: ts)
    }

    // ── Alarm (persistent, rings until dismissed) ────────────────────

    /// Legacy path only (iOS < 26, or AlarmKit declined). Repeats scheduled
    /// after the alarm time so the phone keeps alerting while the app is
    /// backgrounded or locked. iOS caps an app at 64 pending notifications, so
    /// this stays deliberately modest — the first minute is a dense burst, then
    /// it thins out over the following few minutes.
    static let alarmBurstCount = 12
    static let alarmBurstInterval: TimeInterval = 5
    static let alarmTailCount = 10
    static let alarmTailInterval: TimeInterval = 30
    private static var alarmRepeatCount: Int { alarmBurstCount + alarmTailCount }

    private func alarmIdentifiers(for taskId: String) -> [String] {
        (0..<Self.alarmRepeatCount).map { "alarm-\(taskId)-\($0)" }
    }

    /// Offset of leg `index` from the alarm time.
    private static func alarmLegOffset(_ index: Int) -> TimeInterval {
        index < alarmBurstCount
            ? Double(index) * alarmBurstInterval
            : Double(alarmBurstCount) * alarmBurstInterval
                + Double(index - alarmBurstCount + 1) * alarmTailInterval
    }

    func setAlarm(for taskId: String, title: String, at date: Date) {
        guard date > Date().addingTimeInterval(10) else {
            print("[Spike AI] ⚠️ Alarm skipped — date \(date) is not >10s in the future")
            return
        }
        let name = sanitizedTitle(title)

        // Optimistically record it as a system alarm when AlarmKit is available
        // so the in-app overlay stays out of the way; corrected below if the
        // system refuses to take it.
        storeAlarmEntry(taskId: taskId, title: name, at: date, systemOwned: SpikeAlarmScheduler.isSupported)

        Task {
            let systemOwned = await SpikeAlarmScheduler.schedule(taskId: taskId, title: name, at: date)
            storeAlarmEntry(taskId: taskId, title: name, at: date, systemOwned: systemOwned)
            if !systemOwned {
                await scheduleFallbackAlarmNotifications(taskId: taskId, title: name, at: date)
            }
        }
    }

    private func storeAlarmEntry(taskId: String, title: String, at date: Date, systemOwned: Bool) {
        var list = loadAlarms()
        list.removeAll { $0.taskId == taskId }
        list.append(AlarmEntry(taskId: taskId, title: title, time: date,
                               dismissed: false, alarmKit: systemOwned))
        saveAlarms(list)
        revision += 1
    }

    /// A single notification only chimes once. Chaining a burst keeps the phone
    /// alerting until the user opens the app, where the full-screen overlay
    /// takes over and rings until they press Stop.
    private func scheduleFallbackAlarmNotifications(taskId: String, title: String, at date: Date) async {
        let center = UNUserNotificationCenter.current()
        var scheduled = 0

        for index in 0..<Self.alarmRepeatCount {
            let content = UNMutableNotificationContent()
            content.title = AppLocalization.string("reminder")
            content.body = title
            content.sound = UNNotificationSound(named: UNNotificationSoundName(spikeAlarmSoundFileName))
            content.interruptionLevel = .timeSensitive
            content.userInfo = ["taskId": taskId, "kind": "alarm"]

            let fireDate = date.addingTimeInterval(Self.alarmLegOffset(index))
            let comps = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute, .second], from: fireDate)

            let request = UNNotificationRequest(
                identifier: "alarm-\(taskId)-\(index)", content: content,
                trigger: UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
            )
            do {
                try await center.add(request)
                scheduled += 1
            } catch {
                print("[Spike AI] ❌ Alarm leg \(request.identifier) FAILED: \(error.localizedDescription)")
            }
        }
        print("[Spike AI] ✅ Fallback alarm scheduled for \(date) — \(scheduled)/\(Self.alarmRepeatCount) legs")
    }

    func getAlarmTime(for taskId: String) -> Date? {
        loadAlarms().first { $0.taskId == taskId }?.time
    }

    /// The alarm the in-app overlay should present. System-owned alarms are
    /// excluded — AlarmKit already puts its own full-screen alert in front of
    /// everything, so showing ours too would double the ringing.
    func activeAlarm() -> (taskId: String, title: String)? {
        let now = Date()
        return loadAlarms().first { $0.time <= now && !$0.dismissed && !$0.isSystemAlarm }
            .map { ($0.taskId, $0.title) }
    }

    /// Marks system alarms the user already stopped from the Lock Screen as
    /// dismissed, so the task rows stop advertising a pending alarm.
    func reconcileSystemAlarms() {
        guard let live = SpikeAlarmScheduler.liveAlarmIDs() else { return }
        var list = loadAlarms()
        var changed = false
        for index in list.indices where !list[index].dismissed && list[index].isSystemAlarm {
            let id = SpikeAlarmScheduler.alarmID(for: list[index].taskId)
            if !live.contains(id) {
                list[index].dismissed = true
                changed = true
            }
        }
        if changed {
            saveAlarms(list)
            revision += 1
        }
    }

    func dismissAlarm(taskId: String) {
        var list = loadAlarms()
        if let i = list.firstIndex(where: { $0.taskId == taskId }) {
            list[i].dismissed = true
            saveAlarms(list)
        }
        revision += 1

        // Stop means stop: silence the system alarm, kill the remaining legs of
        // the fallback burst, and clear any that already landed in
        // Notification Center.
        SpikeAlarmScheduler.stop(taskId: taskId)
        closeOverlayIfShowing(taskId)
        let ids = alarmIdentifiers(for: taskId)
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ids)
        center.removeDeliveredNotifications(withIdentifiers: ids)
    }

    // ── Display helpers ──────────────────────────────────────────────
    func displayTime(for taskId: String) -> Date? {
        getNotificationTime(for: taskId) ?? getAlarmTime(for: taskId)
    }

    /// Still-pending alarm — drives the alarm badge on a task row.
    func hasAlarm(for taskId: String) -> Bool {
        loadAlarms().contains { $0.taskId == taskId && !$0.dismissed }
    }

    /// Task was set up as an alarm rather than a plain notification, whether or
    /// not it has already rung. The Edit sheet needs this so reopening a task
    /// whose alarm already fired doesn't silently downgrade it to a
    /// notification on save.
    func hasAlarmEntry(for taskId: String) -> Bool {
        loadAlarms().contains { $0.taskId == taskId }
    }

    // ── Cleanup ──────────────────────────────────────────────────────
    func removeAll(for taskId: String) {
        var d = notifDict(); d.removeValue(forKey: taskId)
        UserDefaults.standard.set(d, forKey: notifKey)
        var a = loadAlarms(); a.removeAll { $0.taskId == taskId }; saveAlarms(a)
        revision += 1

        SpikeAlarmScheduler.cancel(taskId: taskId)
        closeOverlayIfShowing(taskId)
        let ids = ["notif-\(taskId)", "missed-alarm-\(taskId)"] + alarmIdentifiers(for: taskId)
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ids)
        center.removeDeliveredNotifications(withIdentifiers: ids)
    }

    func clearAll() {
        for entry in loadAlarms() where entry.isSystemAlarm {
            SpikeAlarmScheduler.cancel(taskId: entry.taskId)
        }
        UserDefaults.standard.removeObject(forKey: notifKey)
        UserDefaults.standard.removeObject(forKey: alarmKey)
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let taskReminderIDs = requests.map(\.identifier).filter {
                $0.hasPrefix("notif-") || $0.hasPrefix("alarm-")
            }
            guard !taskReminderIDs.isEmpty else { return }
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: taskReminderIDs)
        }
    }

    // ── Private ──────────────────────────────────────────────────────

    /// Tears down the alarm window when the task it belongs to is stopped or
    /// deleted from somewhere other than the overlay's own Stop button.
    private func closeOverlayIfShowing(_ taskId: String) {
        if AlarmWindowPresenter.shared.presentedTaskId == taskId {
            AlarmWindowPresenter.shared.dismiss()
        }
    }

    private func notifDict() -> [String: Double] {
        UserDefaults.standard.dictionary(forKey: notifKey) as? [String: Double] ?? [:]
    }
    private func loadAlarms() -> [AlarmEntry] {
        guard let d = UserDefaults.standard.data(forKey: alarmKey),
              let a = try? JSONDecoder().decode([AlarmEntry].self, from: d) else { return [] }
        // Clean up dismissed entries older than 24 hours
        let cutoff = Date().addingTimeInterval(-86400)
        let cleaned = a.filter { !$0.dismissed || $0.time > cutoff }
        if cleaned.count < a.count { saveAlarms(cleaned) }
        return cleaned
    }
    private func saveAlarms(_ a: [AlarmEntry]) {
        if let d = try? JSONEncoder().encode(a) { UserDefaults.standard.set(d, forKey: alarmKey) }
    }

    private func sanitizedTitle(_ title: String) -> String {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? AppLocalization.string("task_reminder_default") : String(trimmed.prefix(120))
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - Root
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(AuthManager.self) private var auth
    @Environment(TaskStore.self) private var taskStore
    @Environment(DailyFocusStore.self) private var dailyFocus
    @Environment(FocusModeViewModel.self) private var focusVM
    @Environment(UsageStore.self) private var usage
    @Environment(AppLocalization.self) private var loc

    @AppStorage("spike_theme") private var themeRaw = "system"
    @AppStorage("spike_live_activity") private var liveActivityEnabled = false
    @AppStorage("spike_show_completed") private var showCompletedTasks = true
    @AppStorage("spike_quote_seen_date") private var quoteSeenDate = ""

    // Quote of the Day opened from its 5 AM notification. Presented at the root
    // so the tap lands on the quote whichever tab the user was last on.
    @State private var quoteNotificationDay: String?
    @State private var showQuoteFromNotification = false

    var body: some View {
        TabView {
            HomeTabView()
                .tabItem { Label(loc["tab_home"], systemImage: "house.fill") }
            ProgressTabView()
                .tabItem { Label(loc["tab_progress"], systemImage: "chart.line.uptrend.xyaxis") }
            FocusModeView()
                .tabItem { Label(loc["tab_mode"], systemImage: "shield.lefthalf.filled") }
            ProfileView()
                .tabItem { Label(loc["tab_profile"], systemImage: "person.crop.circle") }
        }
        .tint(Color.primary)
        .preferredColorScheme(themeScheme)
        .fullScreenCover(isPresented: $showQuoteFromNotification) {
            QuoteOfTheDaySheet(dayKey: quoteNotificationDay)
        }
        .onReceive(NotificationCenter.default.publisher(for: .spikeOpenQuoteOfTheDay)) { _ in
            openQuoteFromNotification()
        }
        .task {
            // Covers a cold launch, where the tap is handled before this view
            // exists and the posted notification has nowhere to land.
            openQuoteFromNotification()
            if let userId = auth.userId { await dailyFocus.fetch(userId: userId) }
            await markPerfectDayIfNeeded()
            checkAlarms()
            autoSetup()
            await syncLiveActivity()
        }
        .onChange(of: scenePhase) {
            if scenePhase == .active {
                openQuoteFromNotification()
                usage.appBecameActive()
                focusVM.onForeground()
                checkAlarms()
            } else {
                usage.appBecameInactive()
            }
        }
        .onChange(of: taskStore.completedCount) {
            DailyTaskHistoryStore.recordToday(tasks: taskStore.todayTasks)
            focusVM.autoSwitchToChillIfGoalsDone()
            Task { await markPerfectDayIfNeeded() }
            Task { await syncLiveActivity() }
        }
        .onChange(of: taskStore.tasks.count) {
            DailyTaskHistoryStore.recordToday(tasks: taskStore.todayTasks)
            focusVM.autoSwitchToChillIfGoalsDone()
            Task { await syncLiveActivity() }
        }
        .onChange(of: dailyFocus.currentStreak) {
            Task { await syncLiveActivity() }
        }
        .onChange(of: liveActivityEnabled) {
            Task { await syncLiveActivity() }
        }
    }

    private var themeScheme: ColorScheme? {
        switch themeRaw {
        case "light": .light
        case "dark": .dark
        default: nil
        }
    }

    /// Opens the Quote of the Day sheet for a tapped notification, if one is
    /// waiting. `consume()` returns the day key only once, so calling this from
    /// several lifecycle hooks is harmless.
    private func openQuoteFromNotification() {
        guard let dayKey = QuoteDeepLink.consume() else { return }
        quoteNotificationDay = dayKey
        // The user has now seen it — stop the home screen sparkle from nagging.
        quoteSeenDate = QuoteTrackingStore.quoteDay()
        showQuoteFromNotification = true
    }

    private func checkAlarms() {
        let store = TaskReminderStore.shared
        store.reconcileSystemAlarms()
        guard let a = store.activeAlarm() else { return }
        // Presented in its own window so it covers sheets, the tab bar and any
        // other in-app UI. AlarmKit alarms never reach here — the system already
        // shows those over the Lock Screen.
        AlarmWindowPresenter.shared.present(taskId: a.taskId, title: a.title, localization: loc) { taskId in
            TaskReminderStore.shared.dismissAlarm(taskId: taskId)
        }
    }

    private func markPerfectDayIfNeeded() async {
        // Streak earned only when ALL of today's tasks are completed
        let today = taskStore.todayTasks
        guard let userId = auth.userId,
              !today.isEmpty,
              today.allSatisfy(\.completed) else { return }
        DailyTaskHistoryStore.recordToday(tasks: today)
        await dailyFocus.markFocusSessionCompleted(userId: userId)
    }

    private func autoSetup() {
        focusVM.autoActivateChillIfNeeded()
    }

    private func syncLiveActivity() async {
        #if canImport(ActivityKit)
        await DailyGoalsLiveActivityManager.sync(
            isEnabled: liveActivityEnabled,
            tasks: taskStore.todayTasks,
            streak: dailyFocus.currentStreak,
            showCompleted: showCompletedTasks
        )
        #endif
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - Alarm Overlay
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/// Fallback alarm UI for systems without AlarmKit. It rings until the user
/// presses Stop — there is no countdown and no time limit.
struct AlarmOverlayView: View {
    @Environment(AppLocalization.self) private var loc
    let title: String
    let onDismiss: () -> Void
    @State private var pulse = false
    @State private var ringPulse = false
    @State private var soundTimer: Timer?
    @State private var vibrationTimer: Timer?
    @State private var audioPlayer: AVAudioPlayer?

    var body: some View {
        ZStack {
            Color.black.opacity(0.92).ignoresSafeArea()
            VStack(spacing: 36) {
                Spacer()

                ZStack {
                    Circle()
                        .stroke(Color.orange.opacity(0.85), lineWidth: 6)
                        .frame(width: 160, height: 160)
                        .scaleEffect(ringPulse ? 1.06 : 1.0)
                        .animation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true), value: ringPulse)
                    Image(systemName: "alarm.fill")
                        .font(.system(size: 56))
                        .foregroundStyle(.orange)
                        .scaleEffect(pulse ? 1.18 : 1.0)
                        .animation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true), value: pulse)
                }

                VStack(spacing: 8) {
                    Text(loc["reminder_title"]).font(.headline).foregroundStyle(.white.opacity(0.6))
                    Text(title)
                        .font(.title.weight(.bold)).foregroundStyle(.white)
                        .multilineTextAlignment(.center).padding(.horizontal, 24)
                }

                Spacer()

                Button {
                    stopAlarmSound()
                    onDismiss()
                } label: {
                    Label(loc["alarm_stop"], systemImage: "stop.fill")
                        .font(.title3.weight(.semibold)).foregroundStyle(.white)
                        .frame(maxWidth: .infinity).padding(.vertical, 18)
                        .background(Color.orange.gradient)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .padding(.horizontal, 32).padding(.bottom, 48)
            }
            .iPadReadable(maxWidth: 500)
        }
        .onAppear {
            pulse = true
            ringPulse = true
            // The screen must not dim away while the alarm is going off.
            UIApplication.shared.isIdleTimerDisabled = true
            startAlarmSound()
        }
        .onDisappear { stopAlarmSound() }
    }

    private func startAlarmSound() {
        // .playback so the tone still rings with the silent switch on — an alarm
        // the mute switch can kill is not an alarm.
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .default, options: [.duckOthers])
        try? session.setActive(true, options: [])

        if let url = Bundle.main.url(forResource: (spikeAlarmSoundFileName as NSString).deletingPathExtension,
                                     withExtension: (spikeAlarmSoundFileName as NSString).pathExtension),
           let player = try? AVAudioPlayer(contentsOf: url) {
            player.numberOfLoops = -1        // rings until the user presses Stop
            player.volume = 1.0
            player.prepareToPlay()
            player.play()
            audioPlayer = player
        } else {
            // Bundled tone missing — fall back to the system alert so the alarm
            // is never silent.
            AudioServicesPlayAlertSound(1005)
            soundTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
                AudioServicesPlayAlertSound(1005)
            }
        }

        // Vibration runs on its own cadence alongside the tone.
        AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
        vibrationTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { _ in
            AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
        }
    }

    private func stopAlarmSound() {
        soundTimer?.invalidate(); soundTimer = nil
        vibrationTimer?.invalidate(); vibrationTimer = nil
        audioPlayer?.stop(); audioPlayer = nil
        UIApplication.shared.isIdleTimerDisabled = false
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - Home Tab
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

struct HomeTabView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(AuthManager.self) private var auth
    @Environment(TaskStore.self) private var store
    @Environment(DailyFocusStore.self) private var dailyFocus
    @Environment(AppLocalization.self) private var loc
    @AppStorage("spike_show_completed") private var showCompletedTasks = true
    @State private var showAdd = false
    @State private var showVoice = false
    @State private var selectedDate = Date()
    @State private var showDatePicker = false
    @State private var showQuote = false
    @State private var quoteRingPulse = false
    @State private var quoteGlow = false
    @State private var quoteIconSpin = false
    @State private var editingTask: TaskRecord?
    @State private var editingTitle = ""
    @AppStorage("spike_quote_seen_date") private var quoteSeenDate = ""

    private let cal = Calendar.current
    private let dateFmt: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX"); return f
    }()

    private var selectedKey: String { dateFmt.string(from: selectedDate) }
    private var allSelectedTasks: [TaskRecord] { store.tasksFor(date: selectedKey) }
    private var selectedTasks: [TaskRecord] {
        let tasks = allSelectedTasks
        return showCompletedTasks ? tasks : tasks.filter { !$0.completed }
    }
    private var isToday: Bool { cal.isDateInToday(selectedDate) }
    private var isPastDate: Bool {
        cal.compare(selectedDate, to: cal.startOfDay(for: Date()), toGranularity: .day) == .orderedAscending
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                ScrollView {
                    VStack(spacing: 24) {
                        logoHeader
                        weekStrip
                        dateSection
                    }
                    .padding(.horizontal)
                    .padding(.top, 12)
                    .padding(.bottom, 90)
                    .iPadReadableScroll()
                }
                if !isPastDate { actionStack }
            }
            .background { SpikeGradientBackground() }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showAdd) {
                AddTaskSheet(isPresented: $showAdd, initialDate: selectedDate)
            }
            .sheet(isPresented: $showVoice) {
                // Jump Home to the day the goals landed on so they're visible.
                VoiceGoalSheet { day in
                    withAnimation(.easeInOut(duration: 0.25)) { selectedDate = day }
                }
            }
            .sheet(isPresented: $showDatePicker) { datePickerSheet }
            .sheet(item: $editingTask) { task in
                EditTaskSheet(task: task, title: task.title, store: store)
            }
            .task { if let uid = auth.userId { await store.fetch(userId: uid) } }
        }
    }

    // MARK: Logo

    private var hasSeenTodayQuote: Bool {
        quoteSeenDate == QuoteTrackingStore.quoteDay()
    }

    private func startQuoteAnimationIfNeeded() {
        guard !hasSeenTodayQuote else { return }
        // Outer ring pulse
        withAnimation(.easeOut(duration: 1.8).repeatForever(autoreverses: false)) {
            quoteRingPulse = true
        }
        // Glow + scale breathe
        withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
            quoteGlow = true
        }
        // Icon wiggle
        withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
            quoteIconSpin = true
        }
    }

    private var logoHeader: some View {
        HStack(alignment: .center) {
            HStack(spacing: 10) {
                Image("SpikeLogo")
                    .resizable().scaledToFit().frame(height: 44)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                Text("Spike AI")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
            }
            Spacer()
            Button {
                quoteSeenDate = QuoteTrackingStore.quoteDay()
                showQuote = true
                // Stop animations immediately
                withAnimation(.easeOut(duration: 0.3)) {
                    quoteRingPulse = false
                    quoteGlow = false
                    quoteIconSpin = false
                }
            } label: {
                ZStack {
                    // Outer pulsing ring (only when unseen)
                    if !hasSeenTodayQuote {
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [Color(red: 0.55, green: 0.40, blue: 1.0).opacity(0.6),
                                             Color(red: 0.40, green: 0.25, blue: 0.85).opacity(0.0)],
                                    startPoint: .topLeading, endPoint: .bottomTrailing
                                ),
                                lineWidth: 2.5
                            )
                            .frame(width: 56, height: 56)
                            .scaleEffect(quoteRingPulse ? 1.35 : 1.0)
                            .opacity(quoteRingPulse ? 0.0 : 0.8)

                        // Second ring (offset timing)
                        Circle()
                            .stroke(
                                Color(red: 0.50, green: 0.35, blue: 1.0).opacity(0.4),
                                lineWidth: 1.5
                            )
                            .frame(width: 56, height: 56)
                            .scaleEffect(quoteGlow ? 1.2 : 0.95)
                            .opacity(quoteGlow ? 0.0 : 0.6)
                    }

                    // Main circle
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color(red: 0.55, green: 0.40, blue: 1.0),
                                         Color(red: 0.40, green: 0.25, blue: 0.85)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)
                        .shadow(
                            color: hasSeenTodayQuote
                                ? .clear
                                : Color(red: 0.50, green: 0.35, blue: 1.0).opacity(quoteGlow ? 0.7 : 0.3),
                            radius: quoteGlow ? 14 : 6, y: 2
                        )

                    // Sparkle icon with subtle rotation
                    Image(systemName: "sparkles")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(.white)
                        .rotationEffect(.degrees(hasSeenTodayQuote ? 0 : (quoteIconSpin ? 8 : -8)))
                        .scaleEffect(hasSeenTodayQuote ? 1.0 : (quoteIconSpin ? 1.15 : 0.95))
                }
                .scaleEffect(hasSeenTodayQuote ? 1.0 : (quoteGlow ? 1.08 : 1.0))
            }
            .buttonStyle(.plain)
            .onAppear { startQuoteAnimationIfNeeded() }
            .onChange(of: hasSeenTodayQuote) { startQuoteAnimationIfNeeded() }
        }
        .padding(.top, 4)
        .fullScreenCover(isPresented: $showQuote) {
            QuoteOfTheDaySheet()
        }
    }

    // MARK: Week Strip

    private var weekStrip: some View {
        let isDark = colorScheme == .dark
        return HStack(spacing: 0) {
            ForEach(-3...3, id: \.self) { offset in
                let date = cal.date(byAdding: .day, value: offset, to: Date()) ?? Date()
                let isSelected = cal.isDate(date, inSameDayAs: selectedDate)
                let isPast = cal.compare(date, to: cal.startOfDay(for: Date()), toGranularity: .day) == .orderedAscending
                let taskCount = store.tasksFor(date: dateFmt.string(from: date)).count

                Button { withAnimation(.easeInOut(duration: 0.2)) { selectedDate = date } } label: {
                    VStack(spacing: 8) {
                        Text(date.formatted(.dateTime.weekday(.abbreviated).locale(Locale(identifier: loc.language))))
                            .font(.system(size: isSelected ? 14 : 12, weight: isSelected ? .bold : .medium, design: .rounded))
                            .foregroundStyle(isSelected ? (isDark ? .white : Color.black) : .secondary)
                        ZStack {
                            Text("\(cal.component(.day, from: date))")
                                .font(.system(size: 17, weight: isSelected ? .bold : .medium, design: .rounded))
                                .foregroundStyle(isSelected ? (isDark ? .white : Color.black) : (isPast ? .secondary : .primary))
                        }
                        .frame(width: 38, height: 38)
                        .background {
                            if isSelected {
                                Circle().stroke(isDark ? Color.white.opacity(0.25) : Color.gray.opacity(0.35), lineWidth: 1.5)
                            } else if isPast {
                                Circle().stroke(style: StrokeStyle(lineWidth: 1.2, dash: [3, 3]))
                                    .foregroundStyle(Color.secondary.opacity(0.45))
                            } else {
                                Circle().stroke(Color.secondary.opacity(0.35), lineWidth: 1.2)
                            }
                        }
                        Circle()
                            .fill(taskCount > 0 ? Color.primary.opacity(0.35) : .clear)
                            .frame(width: 5, height: 5)
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 4)
                    .background {
                        if isSelected {
                            RoundedRectangle(cornerRadius: 18)
                                .fill(isDark ? Color.white.opacity(0.1) : Color.white)
                                .shadow(color: isDark ? .clear : Color.black.opacity(0.08), radius: 8, y: 2)
                        }
                    }
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: Date Picker Sheet

    private var datePickerSheet: some View {
        NavigationStack {
            DatePicker(
                loc["select_date"],
                selection: $selectedDate,
                displayedComponents: .date
            )
            .datePickerStyle(.graphical)
            .tint(Color.primary)
            .padding()
            .navigationTitle(loc["jump_to_date"])
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(loc["done"]) { showDatePicker = false }
                        .fontWeight(.semibold)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button(loc["today"]) {
                        selectedDate = Date()
                        showDatePicker = false
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    // MARK: Date Section

    private var sectionTitle: String {
        if isToday { return loc["today"] }
        if cal.isDateInTomorrow(selectedDate) { return loc["tomorrow"] }
        if cal.isDateInYesterday(selectedDate) { return loc["yesterday"] }
        return selectedDate.formatted(.dateTime.weekday(.wide).month(.abbreviated).day().locale(Locale(identifier: loc.language)))
    }

    private var dateSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Button { showDatePicker = true } label: {
                    Text(sectionTitle)
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundStyle(colorScheme == .dark ? Color.white : Color.black)
                }
                Spacer()
                if !isToday {
                    Button { withAnimation { selectedDate = Date() } } label: {
                        Text(loc["back_to_today"])
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.top, 4)
            if selectedTasks.isEmpty { emptyState } else { taskList }
        }
    }

    private var taskList: some View {
        VStack(spacing: 0) {
            ForEach(selectedTasks) { task in
                taskRow(task)
                if task.id != selectedTasks.last?.id {
                    Divider().padding(.leading, 52).opacity(0.3)
                }
            }
        }
        .padding(.vertical, 6)
        .background(Color.spikeCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.spikeCardBorder, lineWidth: 0.5))
    }

    private func taskRow(_ task: TaskRecord) -> some View {
        let reminderRevision = TaskReminderStore.shared.revision
        let _ = reminderRevision // observe so SwiftUI re-renders on change
        let notifTime = TaskReminderStore.shared.displayTime(for: task.id)
        let isAlarm = TaskReminderStore.shared.hasAlarm(for: task.id)

        return HStack(spacing: 14) {
            Button { Task { await store.toggle(task) } } label: {
                RoundedRectangle(cornerRadius: 6)
                    .stroke(cbColor(task), lineWidth: 2)
                    .frame(width: 22, height: 22)
                    .overlay {
                        if task.completed {
                            Image(systemName: "checkmark")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(cbColor(task))
                        }
                    }
            }
            .buttonStyle(.plain)

            Text(task.title)
                .font(.system(size: 16, design: .rounded)).strikethrough(task.completed)
                .foregroundStyle(task.completed ? .secondary : .primary)
            Spacer()

            if let t = notifTime {
                VStack(alignment: .trailing, spacing: 3) {
                    Text(t.formatted(.dateTime.hour().minute()))
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(.orange)
                    Image(systemName: isAlarm ? "alarm.fill" : "bell.fill")
                        .font(.caption2).foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 14)
        .contentShape(Rectangle())
        .onTapGesture {
            editingTask = task
        }
        .contextMenu {
            Button {
                editingTask = task
            } label: { Label(loc["edit"], systemImage: "pencil") }
            Button(role: .destructive) {
                TaskReminderStore.shared.removeAll(for: task.id)
                Task { await store.delete(task) }
            } label: { Label(loc["delete"], systemImage: "trash") }
        }
    }

    private func cbColor(_ t: TaskRecord) -> Color {
        if t.completed { return .primary }
        return t.priorityEnum == .high ? .orange : .secondary
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            if isPastDate {
                Image(systemName: "tray")
                    .font(.system(size: 24, weight: .light))
                    .foregroundStyle(.secondary.opacity(0.5))
                Text(loc["no_tasks_this_day"] == "no_tasks_this_day" ? "No tasks on this day" : loc["no_tasks_this_day"])
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            } else {
                Text(loc["add_first_task"])
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity).padding(.vertical, 48)
        .background(Color.spikeCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.spikeCardBorder, lineWidth: 0.5))
        .contentShape(RoundedRectangle(cornerRadius: 16))
        .onTapGesture {
            guard !isPastDate, allSelectedTasks.count < 25 else { return }
            showAdd = true
        }
    }

    /// Voice capture sits directly above the "+" button.
    private var actionStack: some View {
        VStack(spacing: 14) {
            VoiceGoalButton(isDisabled: allSelectedTasks.count >= 25) { showVoice = true }
            fab
        }
        .padding(.trailing, 20).padding(.bottom, 16)
    }

    private var fab: some View {
        let atLimit = allSelectedTasks.count >= 25
        return Button { showAdd = true } label: {
            Image(systemName: "plus")
                .font(.title2.weight(.bold)).foregroundStyle(Color(uiColor: .systemBackground))
                .frame(width: 58, height: 58)
                .background(Circle().fill(Color.primary).shadow(color: .black.opacity(0.15), radius: 12, y: 4))
        }
        .disabled(atLimit)
        .opacity(atLimit ? 0.4 : 1)
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - Alarm Toggle Row
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/// "Ring like an alarm" switch, shared by the Add and Edit task sheets.
/// When on, the scheduled time rings continuously instead of chiming once.
struct AlarmToggleRow: View {
    @Binding var isOn: Bool
    let loc: AppLocalization

    var body: some View {
        Toggle(isOn: Binding(
            get: { isOn },
            set: { newValue in
                withAnimation(.easeInOut(duration: 0.2)) { isOn = newValue }
                // Ask for AlarmKit up front. Without it the alarm silently
                // degrades to a notification instead of taking over the
                // Lock Screen, so the user should see the prompt here — while
                // they are deciding — not after they save.
                guard newValue, SpikeAlarmScheduler.isSupported else { return }
                Task { await SpikeAlarmScheduler.requestAuthorization() }
            }
        )) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 7)
                        .fill(isOn ? Color.orange : Color(.systemGray5))
                        .frame(width: 32, height: 32)
                    Image(systemName: isOn ? "alarm.fill" : "alarm")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(isOn ? .white : .gray)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(loc["alarm_sound"])
                        .font(.subheadline.weight(.semibold))
                    Text(loc["reminder_desc"])
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                }
            }
        }
        .tint(.orange)
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - Edit Task Sheet
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

struct EditTaskSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppLocalization.self) private var loc
    let task: TaskRecord
    let store: TaskStore

    @State private var title: String
    @State private var priority: TaskPriority
    @State private var scheduledDate: Date
    @State private var hasNotification: Bool
    @State private var notifTime: Date
    @State private var isAlarm: Bool
    @State private var isSaving = false

    init(task: TaskRecord, title: String, store: TaskStore) {
        self.task = task
        self.store = store
        _title = State(initialValue: title)
        _priority = State(initialValue: TaskPriority(rawValue: task.priority ?? "medium") ?? .medium)

        // Parse scheduled date
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        let date = formatter.date(from: task.scheduledDate ?? "") ?? Date()
        _scheduledDate = State(initialValue: date)

        // Load existing notification
        let existingTime = TaskReminderStore.shared.displayTime(for: task.id)
        _hasNotification = State(initialValue: existingTime != nil)
        _notifTime = State(initialValue: existingTime ?? Date().addingTimeInterval(120))
        _isAlarm = State(initialValue: TaskReminderStore.shared.hasAlarmEntry(for: task.id))
    }

    private var scheduledKey: String {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f.string(from: scheduledDate)
    }

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                // ── Task Name ──────────────────────────────────
                Section {
                    TextField(loc["task_name_placeholder"], text: $title)
                        .font(.system(size: 17, design: .rounded))
                } header: {
                    Label(loc["task"], systemImage: "pencil.line")
                }

                // ── Schedule Date ──────────────────────────────
                Section {
                    DatePicker(
                        loc["date"],
                        selection: $scheduledDate,
                        in: Calendar.current.startOfDay(for: Date())...,
                        displayedComponents: .date
                    )
                } header: {
                    Label(loc["schedule"], systemImage: "calendar")
                }

                // ── Priority ───────────────────────────────────
                Section {
                    Picker(loc["priority"], selection: $priority) {
                        ForEach(TaskPriority.allCases) { Label($0.label, systemImage: $0.icon).tag($0) }
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Label(loc["priority"], systemImage: "flag.fill")
                }

                // ── Notification ───────────────────────────────
                Section {
                    Toggle(isOn: Binding(
                        get: { hasNotification },
                        set: { newValue in
                            withAnimation(.easeInOut(duration: 0.2)) { hasNotification = newValue }
                            if newValue {
                                let cal = Calendar.current
                                let soon = Date().addingTimeInterval(120)
                                var comps = cal.dateComponents([.year, .month, .day, .hour, .minute], from: soon)
                                comps.second = 0
                                notifTime = cal.date(from: comps) ?? soon
                            }
                        }
                    )) {
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 7)
                                    .fill(hasNotification ? Color.green : Color(.systemGray5))
                                    .frame(width: 32, height: 32)
                                Image(systemName: hasNotification ? "bell.badge.fill" : "bell.fill")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(hasNotification ? .white : .gray)
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text(loc["notification"])
                                    .font(.subheadline.weight(.semibold))
                                Text(loc["notification_desc"])
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }
                        }
                    }
                    .tint(.green)
                    if hasNotification {
                        let isToday = Calendar.current.isDateInToday(scheduledDate)
                        let minTime = isToday
                            ? Date().addingTimeInterval(60)
                            : Calendar.current.startOfDay(for: scheduledDate)
                        DatePicker(loc["time"], selection: $notifTime, in: minTime..., displayedComponents: .hourAndMinute)
                            .onChange(of: scheduledDate) {
                                // Moving the task to today can leave the saved
                                // time already in the past, which would make the
                                // reminder silently never fire.
                                let merged = mergeTime(notifTime, into: scheduledDate)
                                if Calendar.current.isDateInToday(scheduledDate),
                                   merged < Date().addingTimeInterval(60) {
                                    notifTime = Date().addingTimeInterval(120)
                                }
                            }
                        AlarmToggleRow(isOn: $isAlarm, loc: loc)
                    }
                }
            }
            .navigationTitle(loc["edit_task"])
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(loc["cancel"]) { dismiss() }
                        .disabled(isSaving)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(loc["save"]) { saveTask() }
                        .fontWeight(.semibold)
                        .disabled(!canSave || isSaving)
                }
            }
        }
    }

    private func saveTask() {
        // Save runs across awaits; without this a second tap would update the
        // task and re-schedule the reminder a second time.
        guard !isSaving else { return }
        isSaving = true

        Task {
            await store.updateTask(task, title: title, priority: priority, scheduledDate: scheduledKey)

            // Update notification
            TaskReminderStore.shared.removeAll(for: task.id)
            if hasNotification, await requestNotificationPermission() {
                let date = mergeTime(notifTime, into: scheduledDate)
                if isAlarm {
                    TaskReminderStore.shared.setAlarm(for: task.id, title: title, at: date)
                } else {
                    TaskReminderStore.shared.setNotification(for: task.id, title: title, at: date)
                }
            }
            isSaving = false
            dismiss()
        }
    }

    private func requestNotificationPermission() async -> Bool {
        let center = UNUserNotificationCenter.current()
        if await center.notificationSettings().authorizationStatus == .authorized { return true }
        return (try? await center.requestAuthorization(options: [.alert, .badge, .sound, .timeSensitive])) ?? false
    }

    private func mergeTime(_ time: Date, into base: Date) -> Date {
        var c = Calendar.current.dateComponents([.year, .month, .day], from: base)
        let t = Calendar.current.dateComponents([.hour, .minute], from: time)
        c.hour = t.hour; c.minute = t.minute
        return Calendar.current.date(from: c) ?? base
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - Add Task Sheet
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

struct AddTaskSheet: View {
    @Environment(TaskStore.self) private var store
    @Environment(AuthManager.self) private var auth
    @Environment(AppLocalization.self) private var loc
    @Binding var isPresented: Bool
    var initialDate: Date = Date()

    @State private var title = ""
    @State private var priority: TaskPriority = .medium
    @State private var scheduledDate = Date()
    @State private var hasNotification = false
    @State private var notifTime = Date().addingTimeInterval(120) // default: 2 min from now
    @State private var isAlarm = false
    @State private var isSaving = false
    @State private var didApplyInitialDate = false

    private var scheduledKey: String {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f.string(from: scheduledDate)
    }

    private var tasksOnDate: Int { store.tasksFor(date: scheduledKey).count }

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && tasksOnDate < 25
    }

    var body: some View {
        NavigationStack {
            Form {
                // ── Task ─────────────────────────────────────────
                Section {
                    TextField(loc["what_to_do"], text: $title)
                        .font(.body)
                } header: {
                    Label(loc["task"], systemImage: "pencil.line")
                }

                // ── Date (no upper limit) ────────────────────────
                Section {
                    DatePicker(
                        loc["date"],
                        selection: $scheduledDate,
                        in: Calendar.current.startOfDay(for: Date())...,
                        displayedComponents: .date
                    )
                } header: {
                    Label(loc["schedule"], systemImage: "calendar")
                } footer: {
                    Text(loc["pick_date_hint"])
                }

                // ── Priority ─────────────────────────────────────
                Section {
                    Picker(loc["priority"], selection: $priority) {
                        ForEach(TaskPriority.allCases) { Label($0.label, systemImage: $0.icon).tag($0) }
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Label(loc["priority"], systemImage: "flag.fill")
                }

                // ── Notification ─────────────────────────────────
                Section {
                    Toggle(isOn: Binding(
                        get: { hasNotification },
                        set: { newValue in
                            withAnimation(.easeInOut(duration: 0.2)) { hasNotification = newValue }
                            if newValue {
                                // Set default time to next round minute from now (+2 min buffer)
                                let cal = Calendar.current
                                let soon = Date().addingTimeInterval(120)
                                var comps = cal.dateComponents([.year, .month, .day, .hour, .minute], from: soon)
                                comps.second = 0
                                notifTime = cal.date(from: comps) ?? soon
                            }
                        }
                    )) {
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 7)
                                    .fill(hasNotification ? Color.green : Color(.systemGray5))
                                    .frame(width: 32, height: 32)
                                Image(systemName: hasNotification ? "bell.badge.fill" : "bell.fill")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(hasNotification ? .white : .gray)
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text(loc["notification"])
                                    .font(.subheadline.weight(.semibold))
                                Text(loc["notification_desc"])
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }
                        }
                    }
                    .tint(.green)
                    if hasNotification {
                        let isToday = Calendar.current.isDateInToday(scheduledDate)
                        let minTime = isToday
                            ? Date().addingTimeInterval(60)
                            : Calendar.current.startOfDay(for: scheduledDate)
                        DatePicker(loc["time"], selection: $notifTime, in: minTime..., displayedComponents: .hourAndMinute)
                            .onChange(of: scheduledDate) {
                                // When date changes, reset time if it's now in the past
                                let merged = mergeTime(notifTime, into: scheduledDate)
                                if merged < Date().addingTimeInterval(60) && Calendar.current.isDateInToday(scheduledDate) {
                                    notifTime = Date().addingTimeInterval(120)
                                }
                            }
                        AlarmToggleRow(isOn: $isAlarm, loc: loc)
                    }
                }

                // ── Limit Warning ────────────────────────────────
                if tasksOnDate >= 25 {
                    Section {
                        Label(loc["task_limit"], systemImage: "exclamationmark.triangle.fill")
                            .font(.subheadline)
                            .foregroundStyle(.orange)
                    }
                }
            }
            .navigationTitle(loc["new_task"])
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(loc["cancel"]) { isPresented = false }
                        .disabled(isSaving)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(loc["add"]) { addTask() }
                        .fontWeight(.semibold)
                        .disabled(!canSave || isSaving)
                }
            }
            .onAppear {
                // Only on first appearance — onAppear fires again when the app
                // returns to the foreground, which would otherwise throw away
                // the date the user just picked.
                guard !didApplyInitialDate else { return }
                didApplyInitialDate = true
                scheduledDate = initialDate
            }
        }
    }

    private func addTask() {
        // Each call mints a fresh task id, so a double tap while the insert is
        // in flight would create two identical goals.
        guard !isSaving else { return }
        guard let userId = auth.userId, tasksOnDate < 25 else { return }
        isSaving = true
        let taskId = UUID().uuidString
        Task {
            let notificationsAllowed = hasNotification
                ? await requestNotificationPermission()
                : true

            await store.add(id: taskId, title: title, priority: priority, scheduledDate: scheduledKey, userId: userId)
            if hasNotification && notificationsAllowed {
                let date = mergeTime(notifTime, into: scheduledDate)
                if isAlarm {
                    TaskReminderStore.shared.setAlarm(for: taskId, title: title, at: date)
                } else {
                    TaskReminderStore.shared.setNotification(for: taskId, title: title, at: date)
                }
            }
            isSaving = false
            isPresented = false
        }
    }

    private func requestNotificationPermission() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        if settings.authorizationStatus == .authorized {
            return true
        }
        // If provisional or not determined, request full authorization
        // so notifications actually appear with banner + sound.
        return (try? await center.requestAuthorization(options: [.alert, .badge, .sound, .timeSensitive])) ?? false
    }

    private func mergeTime(_ time: Date, into base: Date) -> Date {
        var c = Calendar.current.dateComponents([.year, .month, .day], from: base)
        let t = Calendar.current.dateComponents([.hour, .minute], from: time)
        c.hour = t.hour; c.minute = t.minute
        return Calendar.current.date(from: c) ?? base
    }
}

// MARK: - Task Row (standalone)

struct TaskRowView: View {
    @Environment(TaskStore.self) private var store
    let task: TaskRecord
    var body: some View {
        HStack(spacing: 14) {
            Button { Task { await store.toggle(task) } } label: {
                RoundedRectangle(cornerRadius: 6).stroke(cbColor, lineWidth: 2)
                    .frame(width: 22, height: 22)
                    .overlay {
                        if task.completed {
                            Image(systemName: "checkmark").font(.caption2.weight(.bold)).foregroundStyle(cbColor)
                        }
                    }
            }.buttonStyle(.plain)
            Text(task.title).font(.body).strikethrough(task.completed)
                .foregroundStyle(task.completed ? .secondary : .primary)
            Spacer()
            if let p = task.priorityEnum {
                Label(p.label, systemImage: p.icon).font(.caption).foregroundStyle(p.color).labelStyle(.iconOnly)
            }
        }
    }
    private var cbColor: Color {
        if task.completed { return .primary }
        return task.priorityEnum == .high ? .orange : .secondary
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - Progress
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

struct ProgressTabView: View {
    @Environment(AuthManager.self) private var auth
    @Environment(TaskStore.self) private var taskStore
    @Environment(DailyFocusStore.self) private var dailyFocus
    @Environment(GoalStore.self) private var goalStore
    @Environment(UsageStore.self) private var usage
    @Environment(ProgressSummaryStore.self) private var progressSummary
    @Environment(ProgressMilestoneStore.self) private var milestones
    @Environment(AppLocalization.self) private var loc
    @State private var selectedCalendarDay: FocusCalendarDay?
    @State private var celebrationMilestone: ProgressMilestone?

    private let progressService = ProgressService()

    private var snapshot: ProgressSnapshot {
        progressService.snapshot(successDays: dailyFocus.successDays, tasks: taskStore.tasks, usageByDay: usage.secondsByDay, unlockedMilestoneIDs: milestones.unlockedIDs)
    }

    var body: some View {
        let snapshot = self.snapshot
        let isWide = DeviceLayout.isPad
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if isWide {
                        // iPad: 2-column layout for hero + today cards
                        HStack(alignment: .top, spacing: 16) {
                            ProgressHeroCard(snapshot: snapshot, completedTasks: taskStore.completedCount, totalTasks: taskStore.tasks.count)
                            TodayProgressCard(snapshot: snapshot, completionRate: taskStore.completionRate)
                        }
                    } else {
                        ProgressHeroCard(snapshot: snapshot, completedTasks: taskStore.completedCount, totalTasks: taskStore.tasks.count)
                        TodayProgressCard(snapshot: snapshot, completionRate: taskStore.completionRate)
                    }
                    HStack(spacing: 12) {
                        ProgressMetricCard(title: loc["streaks"], value: "\(snapshot.currentStreak)", icon: "flame.fill", tint: .orange)
                        ProgressMetricCard(title: loc["consistency"], value: "\(snapshot.monthlyConsistencyPercent)%", icon: "calendar.badge.checkmark", tint: .green)
                    }
                    DailyBreakdownCard(completed: taskStore.completedCount, total: taskStore.tasks.count)
                    if isWide {
                        // iPad: Side-by-side AI summary + screen time
                        HStack(alignment: .top, spacing: 16) {
                            AIProgressSummaryCard(
                                summary: progressSummary.summary,
                                isLoading: progressSummary.isLoading,
                                error: progressSummary.error,
                                isEligible: eligibleSummaryPeriod != nil,
                                nextSummaryDate: nextSummaryDateLabel,
                                nextUpdateDate: nextUpdateDateLabel
                            )
                            ScreenTimeTrendCard(
                                trend: snapshot.screenTimeTrend,
                                benchmark: snapshot.screenTimeBenchmarkMessage,
                                average: snapshot.averageScreenTimeLastSevenDays,
                                usage: usage.lastSevenUsage()
                            )
                        }
                    } else {
                        AIProgressSummaryCard(
                            summary: progressSummary.summary,
                            isLoading: progressSummary.isLoading,
                            error: progressSummary.error,
                            isEligible: eligibleSummaryPeriod != nil,
                            nextSummaryDate: nextSummaryDateLabel,
                            nextUpdateDate: nextUpdateDateLabel
                        )
                        ScreenTimeTrendCard(
                            trend: snapshot.screenTimeTrend,
                            benchmark: snapshot.screenTimeBenchmarkMessage,
                            average: snapshot.averageScreenTimeLastSevenDays,
                            usage: usage.lastSevenUsage()
                        )
                    }
                    ProgressMetricCard(title: loc["best_streak"], value: "\(snapshot.bestStreak) \(loc["days"])", icon: "seal.fill", tint: .orange)
                    MilestonesCard(milestones: snapshot.milestones)
                    FocusCalendarCard(days: snapshot.calendarDays, selectedDay: $selectedCalendarDay)
                }
                .padding()
                .iPadReadableScroll(maxWidth: 900)
            }
            .background { SpikeGradientBackground() }
            .navigationTitle(loc["tab_progress"])
            .task {
                if let uid = auth.userId {
                    await taskStore.fetch(userId: uid)
                }
                persistMilestones()
                await loadProgressSummary()
            }
            .onChange(of: dailyFocus.successDays) { persistMilestones() }
            .onChange(of: usage.secondsByDay) { persistMilestones() }
            .sheet(item: $selectedCalendarDay) { FocusDayDetailView(day: $0).presentationDetents([.medium, .large]) }
            .fullScreenCover(item: $celebrationMilestone) { milestone in
                MilestoneCelebrationView(milestone: milestone) {
                    celebrationMilestone = nil
                }
            }
        }
    }
    private func persistMilestones() {
        let latest = progressService.snapshot(successDays: dailyFocus.successDays, tasks: taskStore.tasks, usageByDay: usage.secondsByDay, unlockedMilestoneIDs: milestones.unlockedIDs)
        let newIDs = progressService.newlyUnlockedMilestoneIDs(from: latest.milestones, existingIDs: milestones.unlockedIDs)
        guard !newIDs.isEmpty else { return }
        milestones.storeUnlocked(newIDs)
        if celebrationMilestone == nil {
            celebrationMilestone = latest.milestones.first { newIDs.contains($0.id) }
        }
    }

    private func loadProgressSummary() async {
        guard let userId = auth.userId else { return }

        if let period = eligibleSummaryPeriod {
            // Try to load the summary for the current eligible period
            await progressSummary.fetchCached(userId: userId, periodStart: period.start, periodEnd: period.end)
            if progressSummary.summary == nil {
                // No summary for this period yet — generate it
                await generateProgressSummary(forceRefresh: false)
            }
        }

        // If still no summary (new user before first delivery, or generation
        // failed, or new week just started), fall back to the latest available
        // summary so the user always sees their most recent one.
        if progressSummary.summary == nil {
            await progressSummary.fetchLatest(userId: userId)
        }
    }

    private func generateProgressSummary(forceRefresh: Bool) async {
        guard let period = eligibleSummaryPeriod else { return }
        let request = makeProgressSummaryRequest(period: period, forceRefresh: forceRefresh)
        await progressSummary.generate(request: request)
    }

    private func makeProgressSummaryRequest(period: (start: String, end: String), forceRefresh: Bool) -> ProgressSummaryRequest {
        let taskHistory = lastSevenTaskTitles()
        return ProgressSummaryRequest(
            periodStart: period.start,
            periodEnd: period.end,
            currentStreak: snapshot.currentStreak,
            bestStreak: snapshot.bestStreak,
            monthlyConsistencyPercent: snapshot.monthlyConsistencyPercent,
            monthlyFocusDays: snapshot.monthlyFocusDays,
            monthlyMissedDays: snapshot.monthlyMissedDays,
            completedTasks: Array(taskHistory.completed.prefix(12)),
            missedTasks: Array(taskHistory.missed.prefix(12)),
            screenTimeTrend: snapshot.screenTimeTrend,
            averageScreenTimeMinutes: Int((snapshot.averageScreenTimeLastSevenDays / 60).rounded()),
            goals: Array(goalStore.goals.filter { $0.status == GoalStatus.active.rawValue }.map(\.title).prefix(5)),
            forceRefresh: forceRefresh,
            language: loc.language
        )
    }

    /// Returns the Mon–Sun period of the latest completed week eligible for summary,
    /// or nil if the user hasn't been around long enough yet.
    private var eligibleSummaryPeriod: (start: String, end: String)? {
        let calendar = Calendar.current
        let now = Date()
        let weekday = calendar.component(.weekday, from: now) // 1=Sun, 2=Mon, …, 7=Sat
        let hour = calendar.component(.hour, from: now)

        // Find the most recent Sunday at 21:00 that has already passed.
        let deliverySunday: Date
        if weekday == 1 && hour >= 21 {
            deliverySunday = calendar.startOfDay(for: now)
        } else {
            let daysSinceSunday = (weekday == 1) ? 7 : (weekday - 1)
            guard let previousSunday = calendar.date(
                byAdding: .day,
                value: -daysSinceSunday,
                to: calendar.startOfDay(for: now)
            ) else { return nil }
            deliverySunday = previousSunday
        }

        // The week runs Monday … Sunday.
        guard let periodMonday = calendar.date(byAdding: .day, value: -6, to: deliverySunday) else {
            return nil
        }

        // Signup-gate: Sunday sign-ups wait until the following week.
        guard let signupDate = auth.userCreatedAt else { return nil }
        let signupDay = calendar.startOfDay(for: signupDate)
        let signupWeekday = calendar.component(.weekday, from: signupDate)

        if signupWeekday == 1 {
            // Signed up on a Sunday → eligible only for weeks starting after that day.
            guard signupDay < periodMonday else { return nil }
        } else {
            // Signed up Mon–Sat → eligible if sign-up is on or before this period's Sunday.
            guard signupDay <= deliverySunday else { return nil }
        }

        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        fmt.locale = Locale(identifier: "en_US_POSIX")
        return (fmt.string(from: periodMonday), fmt.string(from: deliverySunday))
    }

    /// Formatted label for the next Sunday 9 PM delivery, or nil if already eligible.
    private var nextSummaryDateLabel: String? {
        guard eligibleSummaryPeriod == nil,
              let signupDate = auth.userCreatedAt else { return nil }

        let calendar = Calendar.current
        let now = Date()
        let weekday = calendar.component(.weekday, from: now)
        let hour = calendar.component(.hour, from: now)

        // Next Sunday 9 PM that hasn't passed yet.
        let nextSunday: Date
        if weekday == 1 && hour < 21 {
            nextSunday = calendar.startOfDay(for: now)          // tonight at 9 PM
        } else {
            let daysToAdd = (weekday == 1) ? 7 : (8 - weekday)
            guard let upcomingSunday = calendar.date(
                byAdding: .day,
                value: daysToAdd,
                to: calendar.startOfDay(for: now)
            ) else { return nil }
            nextSunday = upcomingSunday
        }

        // Would the user be eligible at that Sunday's delivery?
        guard let periodMonday = calendar.date(byAdding: .day, value: -6, to: nextSunday) else {
            return nil
        }
        let signupDay = calendar.startOfDay(for: signupDate)
        let signupWeekday = calendar.component(.weekday, from: signupDate)

        let eligibleThen: Bool
        if signupWeekday == 1 {
            eligibleThen = signupDay < periodMonday
        } else {
            eligibleThen = signupDay <= nextSunday
        }

        let target: Date
        if eligibleThen {
            target = nextSunday
        } else {
            guard let followingSunday = calendar.date(byAdding: .day, value: 7, to: nextSunday) else {
                return nil
            }
            target = followingSunday
        }

        let fmt = DateFormatter()
        fmt.dateFormat = "EEEE, MMM d, h a"
        fmt.locale = Locale(identifier: loc.language)
        guard let targetWithTime = calendar.date(bySettingHour: 21, minute: 0, second: 0, of: target) else {
            return fmt.string(from: target)
        }
        return fmt.string(from: targetWithTime)
    }

    /// Label for when the NEXT update will arrive (shown alongside an existing summary).
    private var nextUpdateDateLabel: String? {
        guard eligibleSummaryPeriod != nil else { return nil }
        let calendar = Calendar.current
        let now = Date()
        let weekday = calendar.component(.weekday, from: now)
        let hour = calendar.component(.hour, from: now)

        let nextSunday: Date
        if weekday == 1 && hour < 21 {
            nextSunday = calendar.startOfDay(for: now)
        } else {
            let daysToAdd = (weekday == 1) ? 7 : (8 - weekday)
            nextSunday = calendar.date(byAdding: .day, value: daysToAdd,
                                       to: calendar.startOfDay(for: now)) ?? calendar.startOfDay(for: now)
        }

        let fmt = DateFormatter()
        fmt.dateFormat = "EEEE, MMM d, h a"
        fmt.locale = Locale(identifier: loc.language)
        guard let sundayAtNine = calendar.date(bySettingHour: 21, minute: 0, second: 0, of: nextSunday) else {
            return fmt.string(from: nextSunday)
        }
        return fmt.string(from: sundayAtNine)
    }

    private func lastSevenTaskTitles() -> (completed: [String], missed: [String]) {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        let history = DailyTaskHistoryStore.load()
        var completed: [String] = []
        var missed: [String] = []

        for offset in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: -offset, to: Date()) else { continue }
            let key = formatter.string(from: date)
            if calendar.isDateInToday(date) {
                let todayTasks = taskStore.tasksFor(date: key)
                completed.append(contentsOf: todayTasks.filter(\.completed).map(\.title))
                missed.append(contentsOf: todayTasks.filter { !$0.completed }.map(\.title))
            } else if let saved = history[key] {
                completed.append(contentsOf: saved.completed)
                missed.append(contentsOf: saved.missed)
            }
        }

        return (deduplicated(completed), deduplicated(missed))
    }

    private func deduplicated(_ values: [String]) -> [String] {
        var seen = Set<String>()
        return values.filter { seen.insert($0).inserted }
    }
}

struct ProgressCard<Content: View>: View {
    let title: String; let icon: String; @ViewBuilder var content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: 14) { Label(title, systemImage: icon).font(.headline); content }
            .frame(maxWidth: .infinity, alignment: .leading).padding()
            .background(Color.spikeCard)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.spikeCardBorder, lineWidth: 0.5))
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - Quote of the Day
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

enum QuoteOfTheDayManager {
    /// The quote for a given quote day. Delegates to the same pure function the
    /// 5 AM notification uses, so the banner and the sheet can never disagree —
    /// signed in or out, online or off.
    static func quote(userId: UUID?, dayKey: String = QuoteTrackingStore.quoteDay()) -> DailyQuote {
        QuoteTrackingStore.quote(userId: userId, dayKey: dayKey)
    }

    /// Index of the quote for a given quote day, for translation lookups.
    static func quoteIndex(userId: UUID?, dayKey: String = QuoteTrackingStore.quoteDay()) -> Int {
        QuoteTrackingStore.quoteIndex(userId: userId, dayKey: dayKey)
    }

    /// Today's quote. Signed-in users additionally get the pick recorded in the
    /// tracking store for cross-device history; the value returned is the same
    /// either way.
    static func todayQuote(userId: UUID?, store: QuoteTrackingStore?) -> DailyQuote {
        guard let uid = userId, let store else { return quote(userId: userId) }

        let index = store.pickQuote(userId: uid)
        return QuotesData.all[max(0, min(index, QuotesData.all.count - 1))]
    }

    /// Returns the next quote delivery time (5 AM tomorrow or today if before 5 AM).
    static func nextQuoteDate() -> Date {
        let cal = Calendar.current
        let now = Date()
        let hour = QuoteTrackingStore.quoteHour

        if let today5am = cal.date(bySettingHour: hour, minute: 0, second: 0, of: now), now < today5am {
            return today5am
        }
        let tomorrow = cal.date(byAdding: .day, value: 1, to: now) ?? now
        return cal.date(bySettingHour: hour, minute: 0, second: 0, of: tomorrow) ?? tomorrow
    }

    /// Returns a human-readable countdown to the next quote.
    static func nextQuoteCountdown() -> String {
        let next = nextQuoteDate()
        let diff = Calendar.current.dateComponents([.hour, .minute], from: Date(), to: next)
        let h = diff.hour ?? 0
        let m = diff.minute ?? 0
        if h > 0 {
            return String(format: AppLocalization.string("time_h_m"), h, m)
        }
        return String(format: AppLocalization.string("time_m"), m)
    }
}

struct QuoteOfTheDaySheet: View {
    /// Quote day to display. Set when the sheet is opened from a notification so
    /// it shows precisely the quote that notification delivered — even if the
    /// user taps the banner the next morning, after the boundary has rolled
    /// over. `nil` means today.
    var dayKey: String? = nil

    @Environment(\.dismiss) private var dismiss
    @Environment(AuthManager.self) private var auth
    @Environment(AppLocalization.self) private var loc
    @Environment(QuoteTrackingStore.self) private var quoteTracking

    private var resolvedDay: String { dayKey ?? QuoteTrackingStore.quoteDay() }
    private var isToday: Bool { resolvedDay == QuoteTrackingStore.quoteDay() }
    private var quoteIndex: Int { QuoteOfTheDayManager.quoteIndex(userId: auth.userId, dayKey: resolvedDay) }
    private var quote: DailyQuote { QuoteOfTheDayManager.quote(userId: auth.userId, dayKey: resolvedDay) }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.07, green: 0.05, blue: 0.16), Color(red: 0.02, green: 0.01, blue: 0.06)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(.white.opacity(0.35))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)

                Spacer()

                VStack(spacing: 32) {
                    Text(loc["quote_of_day"] == "quote_of_day" ? "Quote of the Day" : loc["quote_of_day"])
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .textCase(.uppercase)
                        .tracking(1.5)
                        .foregroundStyle(.white.opacity(0.35))

                    Image(systemName: "quote.opening")
                        .font(.system(size: 44, weight: .ultraLight))
                        .foregroundStyle(.white.opacity(0.25))

                    Text(quoteTracking.displayText(for: quote))
                        .font(.system(size: 30, weight: .light, design: .serif))
                        .foregroundStyle(.white.opacity(quoteTracking.isTranslating ? 0.4 : 0.92))
                        .multilineTextAlignment(.center)
                        .lineSpacing(10)
                        .padding(.horizontal, 24)
                        .animation(.easeInOut(duration: 0.3), value: quoteTracking.translatedText)

                    Text("— \(quoteTracking.displayAuthor(for: quote))")
                        .font(.system(size: 17, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.45))
                }
                .iPadReadableScroll(maxWidth: 600)

                Spacer()

                // Next quote countdown
                VStack(spacing: 6) {
                    HStack(spacing: 6) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(.white.opacity(0.3))
                        Text(String(format: loc["next_quote_in"], QuoteOfTheDayManager.nextQuoteCountdown()))
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.3))
                    }

                    Text(loc["new_quotes_daily"] == "new_quotes_daily" ? "New quotes arrive daily at 5:00 AM" : loc["new_quotes_daily"])
                        .font(.system(size: 11, weight: .regular, design: .rounded))
                        .foregroundStyle(.white.opacity(0.2))
                }
                .padding(.bottom, 24)

                HStack(spacing: 12) {
                    Image("SpikeLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 38)
                    Text("Spike AI")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.4))
                }
                .padding(.bottom, 44)
            }
        }
        .task {
            // Record the pick for cross-device history, but only for today —
            // reopening an older notification must not rewrite the day's entry.
            if let uid = auth.userId, isToday {
                _ = quoteTracking.pickQuote(userId: uid)
            }
            await quoteTracking.loadTranslationAsync(quoteIndex: quoteIndex, language: loc.language)
        }
    }
}

struct ProgressHeroCard: View {
    @Environment(AppLocalization.self) private var loc
    let snapshot: ProgressSnapshot
    let completedTasks: Int
    let totalTasks: Int
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(loc["daily_progress"])
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(goalSummary)
                        .font(.title2.weight(.bold))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .layoutPriority(1)
                Spacer()
                Image(systemName: "target")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.primary)
                    .frame(width: 44, height: 44)
                    .background(Color.primary.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
            }
            ProgressBar(value: progress)
            HStack {
                metric("\(snapshot.currentStreak)", loc["streaks"])
                Divider().frame(height: 34)
                metric("\(snapshot.totalFocusDays)", loc["focus_days"])
                Divider().frame(height: 34)
                metric("\(snapshot.monthlyConsistencyPercent)%", loc["consistency"])
            }
        }
        .padding()
        .background(Color.spikeCard)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.spikeCardBorder, lineWidth: 0.5))
    }

    private var progress: Double {
        guard totalTasks > 0 else { return 0 }
        return Double(completedTasks) / Double(totalTasks)
    }

    private var goalSummary: String {
        guard totalTasks > 0 else { return loc["set_first_goal"] }
        if completedTasks == totalTasks { return loc["all_goals_completed"] }
        return "\(completedTasks) \(loc["goals_completed"]) \(totalTasks) \(loc["daily_goals_completed"])"
    }

    private func metric(_ value: String, _ label: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value).font(.headline.weight(.bold))
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
struct TodayProgressCard: View {
    @Environment(AppLocalization.self) private var loc
    let snapshot: ProgressSnapshot; let completionRate: Double
    var body: some View {
        HStack(spacing: 18) {
            ZStack {
                Circle().stroke(Color.primary.opacity(0.08), lineWidth: 7)
                Circle().trim(from: 0, to: completionRate)
                    .stroke(Color.primary.opacity(0.85), style: StrokeStyle(lineWidth: 7, lineCap: .round))
                    .rotationEffect(.degrees(-90)).animation(.easeInOut(duration: 0.5), value: completionRate)
                VStack(spacing: 0) {
                    Text("\(Int(completionRate * 100))").font(.system(size: 22, weight: .bold, design: .rounded))
                    Text("%").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                }
            }.frame(width: 72, height: 72)
            VStack(alignment: .leading, spacing: 6) {
                Text(loc["todays_completion"]).font(.title3.weight(.semibold))
                Text(String(format: loc["monthly_streak_summary"], snapshot.currentStreak, snapshot.monthlyFocusDays, snapshot.monthlyMissedDays))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
            }
            .layoutPriority(1)
            Spacer(minLength: 0)
        }
        .padding()
        .background(Color.spikeCard)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.spikeCardBorder, lineWidth: 0.5))
    }
}
struct ProgressMetricCard: View {
    let title: String; let value: String; let icon: String
    var tint: Color = .primary
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon).font(.headline).foregroundStyle(tint.opacity(0.85))
            Text(value).font(.title3.weight(.bold)).lineLimit(1).minimumScaleFactor(0.8)
            Text(title).font(.caption).foregroundStyle(.secondary)
        }.frame(maxWidth: .infinity, alignment: .leading).padding()
            .background(Color.spikeCard)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.spikeCardBorder, lineWidth: 0.5))
    }
}
struct DailyBreakdownCard: View {
    @Environment(AppLocalization.self) private var loc
    let completed: Int
    let total: Int
    var body: some View {
        ProgressCard(title: loc["daily_goals"], icon: "checklist") {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    Text(statusText)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                        .layoutPriority(1)
                    Spacer(minLength: 8)
                    Text(countText)
                        .font(.subheadline.monospacedDigit().weight(.medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                ProgressBar(value: progress)
                Text(helperText).font(.caption).foregroundStyle(.secondary)
            }
        }
    }

    private var progress: Double {
        guard total > 0 else { return 0 }
        return Double(completed) / Double(total)
    }

    private var statusText: String {
        if total == 0 { return loc["no_goals_planned"] }
        if completed == total { return loc["daily_plan_complete"] }
        return "\(max(total - completed, 0)) \(loc["remaining"])"
    }

    private var helperText: String {
        total == 0 ? loc["add_task_to_start"] : loc["complete_to_focus"]
    }

    private var countText: String {
        "\(completed) / \(total)"
    }
}
struct AIProgressSummaryCard: View {
    @Environment(AppLocalization.self) private var loc
    let summary: ProgressSummaryRecord?
    let isLoading: Bool
    let error: String?
    var isEligible: Bool = false
    var nextSummaryDate: String? = nil
    var nextUpdateDate: String? = nil

    var body: some View {
        ProgressCard(title: loc["ai_weekly_summary"], icon: "sparkles") {
            VStack(alignment: .leading, spacing: 14) {
                if let summary {
                    // ── Title ──────────────────────────────────
                    Text(summary.title)
                        .font(.headline.weight(.bold))
                        .fixedSize(horizontal: false, vertical: true)

                    // ── Summary paragraph ─────────────────────
                    Text(summary.summary)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    // ── Wins ───────────────────────────────────
                    if !summary.wins.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(loc["wins"]).font(.caption.weight(.bold)).foregroundStyle(.green)
                            ForEach(summary.wins.prefix(3), id: \.self) { win in
                                Label(win, systemImage: "checkmark.circle.fill")
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(.green)
                            }
                        }
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.green.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }

                    // ── Next action ───────────────────────────
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "arrow.forward.circle.fill")
                            .foregroundStyle(.primary.opacity(0.8))
                            .font(.subheadline)
                        Text(summary.nextAction)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary.opacity(0.8))
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    // ── Period label ──────────────────────────
                    HStack(spacing: 6) {
                        Image(systemName: "calendar")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text("\(summary.periodStart) — \(summary.periodEnd)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    // ── Next update info ─────────────────────
                    if let nextUpdate = nextUpdateDate {
                        Label(String(format: loc["next_update"], nextUpdate), systemImage: "clock.arrow.circlepath")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                } else if isLoading {
                    HStack(spacing: 10) {
                        ProgressView()
                        Text(loc["creating_summary"])
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                } else if let nextDate = nextSummaryDate {
                    VStack(alignment: .leading, spacing: 10) {
                        Label(loc["first_summary_coming"], systemImage: "sparkles")
                            .font(.subheadline.weight(.semibold))
                        Text(String(format: loc["first_summary_desc"], nextDate))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                } else {
                    Text(loc["weekly_recap"])
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if let error, !error.isEmpty {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .fixedSize(horizontal: false, vertical: true)
                }

            }
        }
    }
}

struct ScreenTimeTrendCard: View {
    @Environment(AppLocalization.self) private var loc
    let trend: String
    let benchmark: String
    let average: TimeInterval
    let usage: [(String, TimeInterval)]
    var body: some View {
        ProgressCard(title: loc["screen_time_7day"], icon: "iphone") {
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(formatDuration(average))
                        .font(.title3.weight(.bold))
                    Text(benchmark)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(trend)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                HStack(alignment: .bottom, spacing: 8) {
                    ForEach(usage, id: \.0) { day, value in
                        VStack(spacing: 6) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.primary.opacity(0.3))
                                .frame(height: barHeight(value))
                                .frame(maxWidth: .infinity)
                            Text(day).font(.caption2).foregroundStyle(.secondary)
                        }
                    }
                }
                .frame(height: 86)
            }
        }
    }

    private func barHeight(_ value: TimeInterval) -> CGFloat {
        let maxValue = max(usage.map(\.1).max() ?? 1, 1)
        return max(8, CGFloat(value / maxValue) * 54)
    }

    private func formatDuration(_ interval: TimeInterval) -> String {
        let minutes = max(0, Int((interval / 60).rounded()))
        let duration = minutes < 60 ? "\(minutes)m" : "\(minutes / 60)h \(minutes % 60)m"
        return String(format: loc["duration_average"], duration)
    }
}
struct ProgressBar: View {
    let value: Double
    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.primary.opacity(0.08))
                Capsule()
                    .fill(LinearGradient(colors: [Color.primary.opacity(0.85), Color.primary.opacity(0.45)], startPoint: .leading, endPoint: .trailing))
                    .frame(width: max(0, min(1, value)) * proxy.size.width)
            }
        }
        .frame(height: 6)
    }
}
struct MilestonesCard: View {
    @Environment(AppLocalization.self) private var loc
    let milestones: [ProgressMilestone]
    var body: some View {
        ProgressCard(title: loc["milestones"], icon: "medal") {
            VStack(spacing: 12) {
                ForEach(milestones) { m in
                    HStack(spacing: 12) {
                        Image(systemName: m.isUnlocked ? "checkmark.seal.fill" : "circle").font(.title3)
                            .foregroundStyle(m.isUnlocked ? Color.primary : Color.secondary.opacity(0.45)).frame(width: 24)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(m.title).font(.subheadline.weight(.semibold))
                            Text(m.subtitle).font(.caption).foregroundStyle(.secondary)
                        }; Spacer()
                    }
                }
            }
        }
    }
}

struct MilestoneCelebrationView: View {
    @Environment(AppLocalization.self) private var loc
    let milestone: ProgressMilestone
    let onDismiss: () -> Void
    @State private var pulse = false
    @State private var rise = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(white: 0.08), Color.black],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ForEach(0..<18, id: \.self) { index in
                Circle()
                    .fill([Color.yellow, .mint, .cyan, .orange, .white][index % 5].opacity(0.85))
                    .frame(width: CGFloat(8 + (index % 4) * 4), height: CGFloat(8 + (index % 4) * 4))
                    .offset(x: CGFloat((index % 6) * 56 - 140), y: rise ? CGFloat(-260 - (index % 5) * 38) : CGFloat(260 + (index % 4) * 24))
                    .opacity(rise ? 0 : 1)
                    .animation(.easeOut(duration: 1.8).delay(Double(index) * 0.035), value: rise)
            }

            VStack(spacing: 24) {
                Spacer()

                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.14))
                        .frame(width: 164, height: 164)
                        .scaleEffect(pulse ? 1.08 : 0.94)
                    Circle()
                        .fill(Color.white.opacity(0.18))
                        .frame(width: 126, height: 126)
                    Image(systemName: "medal.fill")
                        .font(.system(size: 64, weight: .bold))
                        .foregroundStyle(.yellow)
                        .shadow(color: .orange.opacity(0.6), radius: 18, y: 8)
                        .scaleEffect(pulse ? 1.0 : 0.88)
                }
                .animation(.spring(response: 0.7, dampingFraction: 0.58).repeatForever(autoreverses: true), value: pulse)

                VStack(spacing: 10) {
                    Text(loc["milestone_unlocked"])
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.74))
                    Text(milestone.title)
                        .font(.system(size: 34, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(0.72)
                    Text(milestone.subtitle)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.82))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }

                Spacer()

                Button(action: onDismiss) {
                    Text(loc["continue_btn"])
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 17)
                        .background(Color.white, in: RoundedRectangle(cornerRadius: 16))
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 34)
            }
            .iPadReadable(maxWidth: 540)
        }
        .onAppear {
            pulse = true
            rise = true
        }
    }
}

struct FocusCalendarCard: View {
    @Environment(AppLocalization.self) private var loc
    let days: [FocusCalendarDay]; @Binding var selectedDay: FocusCalendarDay?
    @State private var showFullCalendar = false

    private let cols = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)
    private var weekdaySymbols: [String] {
        let lang = UserDefaults.standard.string(forKey: "spike_app_language") ?? "en"
        let f = DateFormatter()
        f.locale = Locale(identifier: lang)
        return f.veryShortWeekdaySymbols
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label(loc["history_calendar"], systemImage: "calendar")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                Spacer()
                Button { showFullCalendar = true } label: {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }
            LazyVGrid(columns: cols, spacing: 4) {
                ForEach(weekdaySymbols, id: \.self) { sym in
                    Text(sym)
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            LazyVGrid(columns: cols, spacing: 6) {
                // Leading empty cells for first day offset
                if let firstDate = days.first?.date {
                    let weekday = Calendar.current.component(.weekday, from: firstDate)
                    let offset = weekday - Calendar.current.firstWeekday
                    let emptyCount = offset >= 0 ? offset : offset + 7
                    ForEach(0..<emptyCount, id: \.self) { _ in Color.clear.aspectRatio(1, contentMode: .fit) }
                }
                ForEach(days) { d in
                    Button { selectedDay = d } label: {
                        VStack(spacing: 2) {
                            Text("\(d.dayNumber)")
                                .font(.system(size: 13, weight: d.isFocusDay ? .bold : .medium, design: .rounded))
                                .foregroundStyle(d.isFocusDay ? .white : .secondary)
                                .frame(maxWidth: .infinity)
                                .aspectRatio(1, contentMode: .fit)
                                .background {
                                    if d.isFocusDay {
                                        Circle().fill(Color.primary.opacity(0.85))
                                    } else {
                                        Circle().fill(Color.primary.opacity(0.03))
                                    }
                                }
                                .clipShape(Circle())
                            if let mode = d.activeMode {
                                Text(modeShortLabel(mode))
                                    .font(.system(size: 8, weight: .medium, design: .rounded))
                                    .foregroundStyle(modeColor(mode))
                                    .lineLimit(1)
                            } else {
                                Color.clear.frame(height: 10)
                            }
                        }
                    }.buttonStyle(.plain)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading).padding()
        .background(Color.spikeCard)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.spikeCardBorder, lineWidth: 0.5))
        .fullScreenCover(isPresented: $showFullCalendar) {
            FullHistoryCalendarView(days: days)
        }
    }

    private func modeShortLabel(_ mode: String) -> String {
        let localized: String
        switch mode {
        case "Chill":  localized = loc["chill"]
        case "Focus":  localized = loc["focus"]
        case "Lock-in": localized = loc["lock_in"]
        case "Sweat":  localized = loc["sweat"]
        default: return ""
        }
        return String(localized.prefix(1)).uppercased()
    }

    private func modeColor(_ mode: String) -> Color {
        switch mode {
        case "Chill": return .blue
        case "Focus": return .purple
        case "Lock-in": return .orange
        case "Sweat": return .green
        default: return .secondary
        }
    }
}

// MARK: - Full History Calendar

struct FullHistoryCalendarView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppLocalization.self) private var loc
    let days: [FocusCalendarDay]

    @State private var isYearlyMode = false
    @State private var displayedMonth: Date = Date()
    @State private var selectedDay: FocusCalendarDay?

    private let cal = Calendar.current
    private let cols7 = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
    private var weekdaySymbols: [String] {
        let lang = UserDefaults.standard.string(forKey: "spike_app_language") ?? "en"
        let f = DateFormatter()
        f.locale = Locale(identifier: lang)
        return f.veryShortWeekdaySymbols
    }
    private let dateFmt: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX"); return f
    }()

    private var daysByKey: [String: FocusCalendarDay] {
        Dictionary(uniqueKeysWithValues: days.map { ($0.id, $0) })
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Toggle: Monthly / Yearly
                HStack(spacing: 0) {
                    scopeTab(loc["monthly_scope_btn"], active: !isYearlyMode) {
                        withAnimation(.easeInOut(duration: 0.2)) { isYearlyMode = false }
                    }
                    scopeTab(loc["yearly_scope_btn"], active: isYearlyMode) {
                        withAnimation(.easeInOut(duration: 0.2)) { isYearlyMode = true }
                    }
                }
                .padding(3)
                .background(Color.white.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding(.horizontal)
                .padding(.top, 12)
                .padding(.bottom, 4)

                if isYearlyMode {
                    yearlyView
                } else {
                    ScrollView {
                        monthlyView
                    }
                }
            }
            .background { SpikeGradientBackground() }
            .navigationTitle(loc["history_calendar"])
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(.secondary)
                            .font(.title3)
                    }
                }
            }
            .sheet(item: $selectedDay) { day in
                FocusDayDetailView(day: day).presentationDetents([.medium, .large])
            }
        }
    }

    // MARK: - Scope Tab

    private func scopeTab(_ title: String, active: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(active ? .white : .secondary)
                .frame(maxWidth: .infinity, minHeight: 34)
                .contentShape(RoundedRectangle(cornerRadius: 8))
        }
        .background(active ? Color.white.opacity(0.12) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .buttonStyle(.plain)
    }

    // MARK: - Monthly View (swipeable)

    private var displayedMonthLabel: String {
        let lang = UserDefaults.standard.string(forKey: "spike_app_language") ?? "en"
        let f = DateFormatter(); f.dateFormat = "MMMM yyyy"; f.locale = Locale(identifier: lang)
        return f.string(from: displayedMonth)
    }

    private var monthlyView: some View {
        VStack(spacing: 14) {
            // Navigation header
            HStack {
                Button { shiftMonth(-1) } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                        .frame(width: 40, height: 40)
                        .contentShape(Rectangle())
                }
                Spacer()
                Text(displayedMonthLabel)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .contentTransition(.numericText())
                Spacer()
                Button { shiftMonth(1) } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .frame(width: 40, height: 40)
                        .contentShape(Rectangle())
                }
            }
            .padding(.horizontal)
            .padding(.top, 12)

            // Weekday headers
            weekdayHeader

            // Days
            let year = cal.component(.year, from: displayedMonth)
            let month = cal.component(.month, from: displayedMonth)
            let data = daysForMonth(month, year: year)

            LazyVGrid(columns: cols7, spacing: 6) {
                ForEach(0..<data.emptyLeading, id: \.self) { _ in
                    Color.clear.aspectRatio(1, contentMode: .fit)
                }
                ForEach(data.dates, id: \.self) { key in
                    dayCell(key: key, size: 36)
                }
            }
            .padding(.horizontal)
            .gesture(swipeGesture)

            legendRow.padding(.bottom, 16)
        }
    }

    private func shiftMonth(_ delta: Int) {
        withAnimation(.easeInOut(duration: 0.2)) {
            displayedMonth = cal.date(byAdding: .month, value: delta, to: displayedMonth) ?? displayedMonth
        }
    }

    // MARK: - Yearly View (2026 → 2100, with day numbers)

    private var yearlyView: some View {
        let colCount = DeviceLayout.isPad ? 4 : 3
        let monthCols = Array(repeating: GridItem(.flexible(), spacing: 16), count: colCount)
        let currentYear = cal.component(.year, from: Date())
        let currentMonth = cal.component(.month, from: Date())
        let todayKey = dateFmt.string(from: Date())

        return ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(2026...2100, id: \.self) { year in
                        VStack(spacing: 0) {
                            yearSectionHeader(year: year, isCurrent: year == currentYear)

                            LazyVGrid(columns: monthCols, spacing: 24) {
                                ForEach(1...12, id: \.self) { month in
                                    let isNow = year == currentYear && month == currentMonth
                                    yearlyMonthBlock(year: year, month: month, isCurrentMonth: isNow, todayKey: todayKey)
                                }
                            }
                            .padding(.horizontal, 14)
                            .padding(.bottom, 16)
                        }
                        .id(year)
                    }
                }
                .onAppear {
                    proxy.scrollTo(currentYear, anchor: .top)
                }
            }
        }
    }

    private func yearSectionHeader(year: Int, isCurrent: Bool) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(String(year))
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.top, 20)
                .padding(.bottom, 10)

            Rectangle().fill(.white.opacity(0.12)).frame(height: 0.5)
                .padding(.horizontal, 14)
                .padding(.bottom, 14)
        }
    }

    @ViewBuilder
    private func yearlyMonthBlock(year: Int, month: Int, isCurrentMonth: Bool, todayKey: String) -> some View {
        let miniCols = Array(repeating: GridItem(.flexible(), spacing: 1), count: 7)
        let data = daysForMonth(month, year: year)

        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                isYearlyMode = false
                displayedMonth = cal.date(from: DateComponents(year: year, month: month, day: 1)) ?? Date()
            }
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                Text({
                    let lang = UserDefaults.standard.string(forKey: "spike_app_language") ?? "en"
                    let f = DateFormatter(); f.locale = Locale(identifier: lang)
                    return f.shortMonthSymbols[month - 1]
                }())
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(isCurrentMonth ? .white : .white.opacity(0.65))

                LazyVGrid(columns: miniCols, spacing: 3) {
                    ForEach(0..<data.emptyLeading, id: \.self) { _ in
                        Color.clear.frame(height: 14)
                    }
                    ForEach(data.dates, id: \.self) { key in
                        let dayNum = Int(key.suffix(2)) ?? 0
                        let day = daysByKey[key]
                        let isToday = key == todayKey
                        Text("\(dayNum)")
                            .font(.system(size: 10, weight: day?.isFocusDay == true ? .bold : .regular, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(
                                day?.isFocusDay == true
                                    ? .white
                                    : isToday ? .white.opacity(0.9) : .white.opacity(0.3)
                            )
                            .frame(maxWidth: .infinity)
                            .frame(height: 14)
                            .background {
                                if isToday {
                                    Circle().fill(Color.accentColor.opacity(0.5))
                                } else if day?.isFocusDay == true {
                                    Circle().fill(Color.white.opacity(0.15))
                                }
                            }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Shared Helpers

    private var weekdayHeader: some View {
        LazyVGrid(columns: cols7, spacing: 4) {
            ForEach(weekdaySymbols, id: \.self) { sym in
                Text(sym).font(.system(size: 11, weight: .semibold, design: .rounded)).foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal)
    }

    @ViewBuilder
    private func dayCell(key: String, size: CGFloat) -> some View {
        let dayNum = Int(key.suffix(2)) ?? 0
        let day = daysByKey[key]
        Button {
            if let d = day { selectedDay = d }
        } label: {
            VStack(spacing: 2) {
                Text("\(dayNum)")
                    .font(.system(size: 13, weight: day?.isFocusDay == true ? .bold : .medium, design: .rounded))
                    .foregroundStyle(day?.isFocusDay == true ? .white : .secondary)
                    .frame(width: size, height: size)
                    .background {
                        if day?.isFocusDay == true {
                            Circle().fill(Color.primary.opacity(0.85))
                        } else {
                            Circle().fill(Color.primary.opacity(0.04))
                        }
                    }
                    .clipShape(Circle())
                if let mode = day?.activeMode {
                    Text(mode)
                        .font(.system(size: 9, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                } else {
                    Color.clear.frame(height: 12)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var legendRow: some View {
        HStack(spacing: 16) {
            HStack(spacing: 6) {
                Circle().fill(Color.primary.opacity(0.85)).frame(width: 10, height: 10)
                Text(loc["focus_day_label"] == "focus_day_label" ? "Focus Day" : loc["focus_day_label"]).font(.system(size: 11, design: .rounded)).foregroundStyle(.secondary)
            }
            HStack(spacing: 6) {
                Circle().fill(Color.primary.opacity(0.06)).frame(width: 10, height: 10)
                Text(loc["missed_label"] == "missed_label" ? "Missed" : loc["missed_label"]).font(.system(size: 11, design: .rounded)).foregroundStyle(.secondary)
            }
        }
        .padding(.top, 8)
    }

    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 50, coordinateSpace: .local)
            .onEnded { value in
                if value.translation.width < -50 { shiftMonth(1) }
                else if value.translation.width > 50 { shiftMonth(-1) }
            }
    }

    private func daysForMonth(_ month: Int, year: Int) -> (emptyLeading: Int, dates: [String]) {
        var comps = DateComponents(year: year, month: month, day: 1)
        guard let start = cal.date(from: comps) else { return (0, []) }
        let weekday = cal.component(.weekday, from: start)
        let offset = weekday - cal.firstWeekday
        let emptyLeading = offset >= 0 ? offset : offset + 7
        let range = cal.range(of: .day, in: .month, for: start) ?? 1..<2
        let dates = range.compactMap { d -> String? in
            comps.day = d
            guard let date = cal.date(from: comps) else { return nil }
            return dateFmt.string(from: date)
        }
        return (emptyLeading, dates)
    }
}
struct FocusDayDetailView: View {
    @Environment(AppLocalization.self) private var loc
    let day: FocusCalendarDay
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // ── Status Banner ──────────────────────────
                    HStack(spacing: 12) {
                        Image(systemName: day.isFocusDay ? "checkmark.circle.fill" : "xmark.circle")
                            .font(.system(size: 24))
                            .foregroundStyle(day.isFocusDay ? .green : .secondary)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(day.isFocusDay ? loc["streak_day"] : loc["missed_day"])
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                            if let mode = day.activeMode {
                                Label(localizedModeName(mode), systemImage: modeIcon(mode))
                                    .font(.system(size: 13, weight: .medium, design: .rounded))
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                    }
                    .padding(16)
                    .background(Color.spikeCard)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.spikeCardBorder, lineWidth: 0.5))

                    // ── Completed Tasks ─────────────────────────
                    if !day.completedItems.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text(loc["completed"])
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundStyle(.secondary)
                                .padding(.leading, 4)
                            VStack(spacing: 0) {
                                ForEach(Array(day.completedItems.enumerated()), id: \.offset) { idx, item in
                                    HStack(spacing: 12) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(.green).font(.subheadline)
                                        Text(item)
                                            .font(.system(size: 15, design: .rounded))
                                        Spacer()
                                    }
                                    .padding(.horizontal, 16).padding(.vertical, 12)
                                    if idx < day.completedItems.count - 1 {
                                        Divider().padding(.leading, 44).opacity(0.3)
                                    }
                                }
                            }
                            .background(Color.spikeCard)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.spikeCardBorder, lineWidth: 0.5))
                        }
                    }

                    // ── Missed Tasks ────────────────────────────
                    if !day.missedItems.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text(loc["not_completed"])
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundStyle(.secondary)
                                .padding(.leading, 4)
                            VStack(spacing: 0) {
                                ForEach(Array(day.missedItems.enumerated()), id: \.offset) { idx, item in
                                    HStack(spacing: 12) {
                                        Image(systemName: "circle")
                                            .foregroundStyle(.secondary).font(.subheadline)
                                        Text(item)
                                            .font(.system(size: 15, design: .rounded))
                                            .foregroundStyle(.secondary)
                                        Spacer()
                                    }
                                    .padding(.horizontal, 16).padding(.vertical, 12)
                                    if idx < day.missedItems.count - 1 {
                                        Divider().padding(.leading, 44).opacity(0.3)
                                    }
                                }
                            }
                            .background(Color.spikeCard)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.spikeCardBorder, lineWidth: 0.5))
                        }
                    }

                    // ── Empty state ─────────────────────────────
                    if day.completedItems.isEmpty && day.missedItems.isEmpty {
                        VStack(spacing: 10) {
                            Image(systemName: "tray")
                                .font(.system(size: 28, weight: .light))
                                .foregroundStyle(Color.secondary.opacity(0.4))
                            Text(loc["no_completed_tasks"])
                                .font(.system(size: 14, design: .rounded))
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity).padding(.vertical, 32)
                        .background(Color.spikeCard)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.spikeCardBorder, lineWidth: 0.5))
                    }
                }
                .padding()
                .iPadReadableScroll()
            }
            .background { SpikeGradientBackground() }
            .navigationTitle(DateFormatter.localizedString(from: day.date, dateStyle: .medium, timeStyle: .none))
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func localizedModeName(_ mode: String) -> String {
        switch mode {
        case "Chill":   return loc["chill"]
        case "Focus":   return loc["focus"]
        case "Lock-in": return loc["lock_in"]
        case "Sweat":   return loc["sweat"]
        default:        return mode
        }
    }

    private func modeIcon(_ mode: String) -> String {
        switch mode {
        case "Chill": "bell.badge"
        case "Focus": "shield.lefthalf.filled"
        case "Lock-in": "lock.shield"
        case "Sweat": "figure.strengthtraining.traditional"
        default: "circle"
        }
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - Profile
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

struct ProfileView: View {
    @Environment(AuthManager.self) private var auth
    @Environment(ProfileStore.self) private var profiles
    @Environment(AppLocalization.self) private var loc
    @AppStorage("spike_theme") private var themeRaw = "system"
    @AppStorage("spike_live_activity") private var liveActivityEnabled = false
    @AppStorage("spike_show_completed") private var showCompletedTasks = true
    @State private var draft: UserProfile?
    @State private var showDeleteConfirm = false
    @State private var showDeleteFinalConfirm = false
    @State private var isDeletingAccount = false
    @State private var accountActionError: String?
    @State private var profileNavPath = NavigationPath()

    var body: some View {
        @Bindable var loc = loc
        NavigationStack(path: $profileNavPath) {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Button {
                        // Ensure draft is populated before opening the edit form
                        if draft == nil, let uid = auth.userId {
                            draft = profiles.profile ?? fallbackProfile(userId: uid)
                        }
                        profileNavPath.append("personalDetails")
                    } label: {
                        profileHeaderCard
                    }
                    .buttonStyle(.plain)

                    profileSection(title: loc["account"]) {
                        NavigationLink { preferencesForm } label: {
                            ProfileMenuRow(icon: "gearshape", title: loc["preferences"])
                        }
                        sectionDivider
                        NavigationLink { LanguageSettingsView() } label: {
                            ProfileMenuRow(icon: "globe", title: loc["language"], trailing: currentLanguageLabel)
                        }
                    }

                    profileSection(title: loc["support_legal"]) {
                        Link(destination: URL(string: "https://spikeai.tech/privacy.html")!) {
                            ProfileMenuRow(icon: "checkmark.shield", title: loc["privacy_policy"])
                        }
                        sectionDivider
                        Link(destination: URL(string: "https://spikeai.tech/terms.html")!) {
                            ProfileMenuRow(icon: "doc.text", title: loc["terms_of_service"])
                        }
                    }

                    profileSection(title: loc["follow_us"]) {
                        Link(destination: URL(string: "https://instagram.com/spikeai.tech")!) {
                            ProfileMenuRow(icon: "camera", title: "Instagram")
                        }
                        sectionDivider
                        Link(destination: URL(string: "https://tiktok.com/@spikeai.tech")!) {
                            ProfileMenuRow(icon: "music.note", title: "TikTok")
                        }
                    }

                    profileSection(title: loc["account_actions"]) {
                        Button { Task { try? await auth.signOut() } } label: {
                            ProfileMenuRow(icon: "rectangle.portrait.and.arrow.right", title: loc["sign_out"], tint: .red)
                        }
                        .disabled(isDeletingAccount)
                        sectionDivider
                        Button(role: .destructive) { showDeleteConfirm = true } label: {
                            ProfileMenuRow(icon: "person.crop.circle.badge.minus", title: loc["delete_account"], tint: .red)
                        }
                        .disabled(isDeletingAccount)
                    }

                    if isDeletingAccount {
                        HStack(spacing: 10) {
                            ProgressView()
                            Text(loc["deleting_account"]).foregroundStyle(.secondary)
                        }
                    }
                    if let accountActionError {
                        Text(accountActionError).font(.footnote).foregroundStyle(.red)
                    }

                    Spacer(minLength: 40)
                }
                .padding(.horizontal)
                .padding(.top, 8)
                .iPadReadableScroll()
            }
            .background(Color.spikeBg.ignoresSafeArea())
            .navigationTitle(loc["tab_profile"])
            .navigationDestination(for: String.self) { dest in
                if dest == "personalDetails" {
                    personalDetailsForm
                }
            }
            .alert(loc["delete_account_title"], isPresented: $showDeleteConfirm) {
                Button(loc["cancel"], role: .cancel) {}
                Button(loc["delete_account_continue"], role: .destructive) {
                    showDeleteFinalConfirm = true
                }
            } message: {
                Text(loc["delete_account_msg"])
            }
            .alert(loc["delete_account_final_title"], isPresented: $showDeleteFinalConfirm) {
                Button(loc["cancel"], role: .cancel) {}
                Button(loc["delete"], role: .destructive) {
                    Task { await deleteAccount() }
                }
            } message: {
                Text(loc["delete_account_final_msg"])
            }
            .onAppear {
                // Populate draft from cache so edit form has data ready
                if draft == nil, let profile = profiles.profile {
                    draft = profile
                }
            }
            .task {
                // Background: refresh from network when available
                guard let uid = auth.userId else { return }
                await auth.upsertCurrentProfile()
                await profiles.fetch(userId: uid)
                let profile = profiles.profile ?? fallbackProfile(userId: uid)
                draft = profile
            }
        }
    }

    private var preferencesForm: some View {
        ScrollView {
            VStack(spacing: 22) {
                preferencesAppearanceCard
                preferencesTogglesCard
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 40)
            .iPadReadableScroll()
        }
        .background(Color.spikeBg.ignoresSafeArea())
        .navigationBarBackButtonHidden(false)
        .toolbarBackground(.hidden, for: .navigationBar)
        .navigationTitle(loc["preferences"])
        .navigationBarTitleDisplayMode(.inline)
    }

    private var preferencesAppearanceCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 3) {
                Text(loc["appearance"])
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                Text(loc["appearance_desc"])
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 10) {
                appearanceOption(id: "system", icon: "circle.lefthalf.filled", title: loc["system"])
                appearanceOption(id: "light", icon: "sun.max", title: loc["light"])
                appearanceOption(id: "dark", icon: "moon", title: loc["dark"])
            }
        }
        .padding(18)
        .background(Color.spikeCard)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private var preferencesTogglesCard: some View {
        VStack(spacing: 0) {
            PreferenceToggleRow(
                title: loc["live_activity"],
                subtitle: loc["live_activity_profile_desc"],
                isOn: $liveActivityEnabled
            )
            profilePreferenceDivider
            PreferenceToggleRow(
                title: loc["pref_show_completed"],
                subtitle: loc["pref_show_completed_desc"],
                isOn: $showCompletedTasks
            )
        }
        .padding(.vertical, 6)
        .background(Color.spikeCard)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private var profilePreferenceDivider: some View {
        Divider().padding(.horizontal, 18)
    }

    private func appearanceOption(id: String, icon: String, title: String) -> some View {
        Button {
            themeRaw = id
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                ZStack(alignment: .topTrailing) {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(id == "dark" ? Color(red: 0.14, green: 0.13, blue: 0.17) : Color.white)
                        .overlay(
                            VStack(alignment: .leading, spacing: 5) {
                                Capsule().fill(id == "dark" ? Color.white.opacity(0.12) : Color.black.opacity(0.08)).frame(width: 40, height: 7)
                                Capsule().fill(id == "dark" ? Color.white.opacity(0.08) : Color.black.opacity(0.06)).frame(width: 26, height: 5)
                                Spacer()
                                HStack(spacing: 4) {
                                    previewTile(color: .red)
                                    previewTile(color: .orange)
                                    previewTile(color: .blue)
                                }
                            }
                            .padding(7)
                        )
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(id == "dark" ? .white : .black)
                        .padding(6)
                }
                .frame(height: 76)

                Label(title, systemImage: icon)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .padding(8)
            .frame(maxWidth: .infinity)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(themeRaw == id ? Color.primary : Color.clear, lineWidth: 2.5)
            )
        }
        .buttonStyle(.plain)
    }

    private func previewTile(color: Color) -> some View {
        RoundedRectangle(cornerRadius: 5)
            .stroke(color.opacity(0.8), lineWidth: 1.2)
            .background(RoundedRectangle(cornerRadius: 5).fill(color.opacity(0.12)))
            .frame(maxWidth: .infinity, maxHeight: 26)
    }

    private var profileHeaderCard: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(avatarGradient(for: effectiveProfile?.avatarColor))
                Text(initials)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
            }
            .frame(width: 52, height: 52)

            VStack(alignment: .leading, spacing: 3) {
                Text(hasName ? displayName : loc["set_name"])
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                Text(profileSubtitle)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.spikeCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // ── Section Builder ──────────────────────────────────────────
    private func profileSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if !title.isEmpty {
                Text(title)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .padding(.leading, 4)
            }
            VStack(spacing: 0) {
                content()
            }
            .padding(.vertical, 2)
            .background(Color.spikeCard)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .buttonStyle(.plain)
        }
    }

    private var sectionDivider: some View {
        Divider().padding(.leading, 48).padding(.trailing, 16).opacity(0.22)
    }

    private func deleteAccount() async {
        isDeletingAccount = true
        accountActionError = nil
        do {
            try await auth.deleteAccount()
        } catch {
            // Even if deletion partially fails, sign out to redirect to login
            try? await auth.signOut()
        }
        isDeletingAccount = false
    }

    private let avatarColorOptions = ["green", "blue", "purple", "red", "orange", "pink", "indigo", "teal"]

    private var personalDetailsForm: some View {
        Form {
            if draft != nil {
                Section {
                    HStack {
                        Spacer()
                        ZStack {
                            Circle().fill(avatarGradient(for: draft?.avatarColor))
                            Text(initials)
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                        }
                        .frame(width: 80, height: 80)
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                    .padding(.vertical, 8)
                }

                Section(header: Text(loc["avatar_color"])) {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 14) {
                        ForEach(avatarColorOptions, id: \.self) { color in
                            Circle()
                                .fill(avatarGradient(for: color))
                                .frame(width: 44, height: 44)
                                .overlay(
                                    Circle()
                                        .stroke(Color.primary, lineWidth: draft?.avatarColor == color ? 3 : 0)
                                        .padding(2)
                                )
                                .overlay(
                                    draft?.avatarColor == color ?
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundStyle(.white) : nil
                                )
                                .onTapGesture { draft?.avatarColor = color }
                        }
                    }
                    .padding(.vertical, 8)
                }

                Section {
                    TextField(loc["first_name"], text: strBinding(\.firstName))
                        .textContentType(.givenName)
                    TextField(loc["last_name"], text: strBinding(\.lastName))
                        .textContentType(.familyName)
                    HStack {
                        Text(loc["email"])
                        Spacer()
                        Text(auth.userEmail)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.trailing)
                    }
                } footer: {
                    Text(loc["email_not_editable"])
                }

                Section {
                    Button { save() } label: {
                        if isSavingProfile {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Text(loc["save_changes"])
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .disabled(isSavingProfile)
                }

                if let error = profiles.error {
                    Section {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
            }
        }
        .navigationTitle(loc["personal_details"])
        .navigationBarTitleDisplayMode(.inline)
    }

    // Helpers

    /// The profile to display: uses the editable draft if available, otherwise falls back
    /// to the store's cached/fetched profile. Because `profiles` is @Observable, SwiftUI
    /// re-renders automatically when the store's profile updates (e.g. after loadAll).
    private var effectiveProfile: UserProfile? {
        draft ?? profiles.profile
    }

    private var displayName: String {
        let first = effectiveProfile?.firstName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let last = effectiveProfile?.lastName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let full = [first, last].filter { !$0.isEmpty }.joined(separator: " ")
        if !full.isEmpty { return full }
        return loc["set_name"]
    }
    private var hasName: Bool {
        let first = effectiveProfile?.firstName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let last = effectiveProfile?.lastName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return !first.isEmpty || !last.isEmpty
    }
    private var profileSubtitle: String {
        hasName ? auth.userEmail : loc["and_username"]
    }
    private var initials: String {
        let p = displayName.split(separator: " ")
        return p.count >= 2 ? "\(p[0].prefix(1))\(p[1].prefix(1))".uppercased() : String(displayName.prefix(1)).uppercased()
    }
    private func avatarGradient(for colorName: String?) -> LinearGradient {
        let name = colorName ?? "green"
        let colors: [Color] = {
            switch name {
            case "blue":   return [Color(red: 0.25, green: 0.45, blue: 0.85), Color(red: 0.12, green: 0.25, blue: 0.55)]
            case "purple": return [Color(red: 0.55, green: 0.25, blue: 0.75), Color(red: 0.30, green: 0.12, blue: 0.45)]
            case "red":    return [Color(red: 0.82, green: 0.22, blue: 0.22), Color(red: 0.50, green: 0.10, blue: 0.10)]
            case "orange": return [Color(red: 0.90, green: 0.52, blue: 0.20), Color(red: 0.70, green: 0.32, blue: 0.10)]
            case "pink":   return [Color(red: 0.88, green: 0.30, blue: 0.50), Color(red: 0.60, green: 0.15, blue: 0.30)]
            case "indigo": return [Color(red: 0.30, green: 0.22, blue: 0.65), Color(red: 0.15, green: 0.10, blue: 0.40)]
            case "teal":   return [Color(red: 0.20, green: 0.62, blue: 0.62), Color(red: 0.10, green: 0.38, blue: 0.38)]
            default:       return [Color(red: 0.22, green: 0.62, blue: 0.42), Color(red: 0.10, green: 0.38, blue: 0.22)]
            }
        }()
        return LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }
    private var currentLanguageLabel: String {
        guard let selected = supportedLanguages.first(where: { $0.id == loc.language }) else {
            return ""
        }
        return "\(selected.flag) \(selected.name)"
    }
    @State private var isSavingProfile = false

    private func save() {
        guard var draft else { return }
        guard !isSavingProfile else { return }
        draft.firstName = draft.firstName?.trimmingCharacters(in: .whitespacesAndNewlines)
        draft.lastName = draft.lastName?.trimmingCharacters(in: .whitespacesAndNewlines)
        isSavingProfile = true
        Task {
            let success = await profiles.save(profile: draft, fallbackEmail: auth.userEmail)
            isSavingProfile = false
            if success {
                self.draft = profiles.profile ?? draft
                profileNavPath = NavigationPath()
            }
        }
    }
    private func strBinding(_ kp: WritableKeyPath<UserProfile, String?>) -> Binding<String> {
        Binding(get: { draft?[keyPath: kp] ?? "" }, set: { draft?[keyPath: kp] = $0 })
    }

    private func fallbackProfile(userId: UUID) -> UserProfile {
        UserProfile(
            id: userId,
            firstName: nil,
            lastName: nil,
            avatarColor: "green"
        )
    }
}

struct ProfileMenuRow: View {
    let icon: String
    let title: String
    var subtitle: String? = nil
    var trailing: String? = nil
    var tint: Color = .primary
    var showsChevron = true

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(tint == .red ? .red : tint.opacity(0.85))
                .frame(width: 26, height: 26)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(tint == .red ? .red : .primary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
                if let subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.system(size: 13, weight: .regular, design: .rounded))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
            Spacer(minLength: 8)
            if let trailing, !trailing.isEmpty {
                Text(trailing)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }
}

struct PreferenceToggleRow: View {
    let title: String
    let subtitle: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
                Text(subtitle)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 12)
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(.green)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
    }
}

struct ProfileRow: View {
    let icon: String
    let title: String
    var subtitle: String? = nil
    var trailing: String? = nil
    var tint: Color = .primary

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(tint.opacity(0.85))
                .frame(width: 22)
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(tint == .red ? .red : .primary)
                if let subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.system(size: 12, design: .rounded))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
            Spacer()
            if let trailing {
                Text(trailing)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
    }
}

struct LanguageSettingsView: View {
    @Environment(AppLocalization.self) private var loc

    var body: some View {
        @Bindable var loc = loc
        List {
            Section {
                ForEach(supportedLanguages) { language in
                    Button {
                        loc.language = language.id
                    } label: {
                        HStack(spacing: 14) {
                            Text(language.flag)
                                .font(.title2)
                                .frame(width: 34)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(language.name)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.primary)
                                Text(language.id.uppercased())
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if loc.language == language.id {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.primary)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            } footer: {
                Text(loc["language_desc"])
            }
        }
        .navigationTitle(loc["language"])
        .navigationBarTitleDisplayMode(.inline)
    }

}

struct LegalDetailView: View {
    let title: String
    let bodyText: String

    var body: some View {
        ScrollView {
            Text(bodyText)
                .font(.body)
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .background { SpikeGradientBackground() }
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - Name Setup (post-registration)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

struct NameSetupView: View {
    @Environment(AuthManager.self) private var auth
    @Environment(ProfileStore.self) private var profiles
    @Environment(AppLocalization.self) private var loc

    @State private var firstName = ""
    @State private var lastName = ""
    @State private var isSaving = false
    @FocusState private var focusedField: Field?

    enum Field { case first, last }

    // Names are optional — user can always continue
    private var canContinue: Bool { true }

    var body: some View {
        ZStack {
            SpikeGradientBackground()

            VStack(spacing: 0) {
                Spacer()

                // Icon
                Image("SpikeLogo")
                    .resizable().scaledToFit().frame(height: 56)
                    .padding(.bottom, 24)

                // Title
                Text(loc["whats_your_name"])
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)

                Text(loc["name_helps"])
                    .font(.system(size: 15, design: .rounded))
                    .foregroundStyle(.secondary)
                    .padding(.top, 6)

                Spacer().frame(height: 40)

                // Name Fields
                VStack(spacing: 14) {
                    TextField(loc["first_name"], text: $firstName)
                        .font(.system(size: 17, design: .rounded))
                        .padding(16)
                        .background(Color.spikeCard)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.spikeCardBorder, lineWidth: 0.5))
                        .textContentType(.givenName)
                        .focused($focusedField, equals: .first)
                        .submitLabel(.next)
                        .onSubmit { focusedField = .last }

                    TextField(loc["last_name"], text: $lastName)
                        .font(.system(size: 17, design: .rounded))
                        .padding(16)
                        .background(Color.spikeCard)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.spikeCardBorder, lineWidth: 0.5))
                        .textContentType(.familyName)
                        .focused($focusedField, equals: .last)
                        .submitLabel(.done)
                        .onSubmit { if canContinue { saveName() } }
                }
                .padding(.horizontal, 24)

                Spacer()

                // Continue Button
                Button {
                    focusedField = nil
                    saveName()
                } label: {
                    HStack(spacing: 8) {
                        if isSaving { ProgressView().tint(.black) }
                        Text(loc["continue_btn_name"])
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                    }
                    .frame(maxWidth: .infinity).padding(.vertical, 16)
                    .foregroundStyle(.black)
                    .background(canContinue ? Color.white : Color.white.opacity(0.3))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(!canContinue || isSaving)
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
            }
            .iPadReadable(maxWidth: 480)
        }
        .onAppear { focusedField = .first }
    }

    private func saveName() {
        guard canContinue else { return }
        isSaving = true
        let trimFirst = firstName.trimmingCharacters(in: .whitespaces)
        let trimLast = lastName.trimmingCharacters(in: .whitespaces)
        Task {
            // Cache profile locally so name is available offline immediately
            if let uid = auth.userId {
                let localProfile = UserProfile(
                    id: uid,
                    firstName: trimFirst.isEmpty ? nil : trimFirst,
                    lastName: trimLast.isEmpty ? nil : trimLast,
                    avatarColor: profiles.profile?.avatarColor ?? "green"
                )
                profiles.updateLocalProfile(localProfile)
            }
            await auth.submitNameSetup(firstName: trimFirst, lastName: trimLast)
            isSaving = false
        }
    }
}
