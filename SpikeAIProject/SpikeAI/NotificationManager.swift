//
//  NotificationManager.swift
//  Spike AI
//
//  Manages local notifications for Chill Mode.
//  Handles permission requests, reminder CRUD, and scheduling.
//

import Foundation
import UserNotifications
import SwiftUI

// MARK: - Reminder Model

struct FocusReminder: Codable, Identifiable, Equatable {
    let id: UUID
    var message: String
    var hour: Int        // 0-23
    var minute: Int      // 0-59
    var isEnabled: Bool
    var days: Set<Int>   // Calendar weekday: 1 = Sunday … 7 = Saturday

    var timeString: String {
        let h = hour % 12 == 0 ? 12 : hour % 12
        let period = hour < 12 ? "AM" : "PM"
        return String(format: "%d:%02d %@", h, minute, period)
    }

    var daysString: String {
        let lang = UserDefaults.standard.string(forKey: "spike_app_language") ?? "en"
        let f = DateFormatter()
        f.locale = Locale(identifier: lang)
        let names = f.shortWeekdaySymbols ?? ["", "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        if days.count == 7 { return AppLocalization.string("every_day") }
        if days == Set(2...6) { return AppLocalization.string("weekdays") }
        if days == Set([1, 7]) { return AppLocalization.string("weekends") }
        return days.sorted().map { $0 < names.count ? names[$0 - 1] : "" }.joined(separator: ", ")
    }

    static func makeDefault() -> FocusReminder {
        FocusReminder(
            id: UUID(),
            message: AppLocalization.string("time_to_focus"),
            hour: 9, minute: 0,
            isEnabled: true,
            days: Set(1...7)
        )
    }
}

// MARK: - Notification Manager

@MainActor @Observable
final class NotificationManager {
    var reminders: [FocusReminder] = []
    var authorizationStatus: UNAuthorizationStatus = .notDetermined
    var error: String?

    private let center = UNUserNotificationCenter.current()
    private let reminderPrefix = "spike-focus-reminder-"
    private let maxReminderCount = 21

    init() { loadReminders() }

    // MARK: Authorization

    func checkStatus() async {
        let settings = await center.notificationSettings()
        authorizationStatus = settings.authorizationStatus
    }

    /// Returns true if permission was granted.
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            await checkStatus()
            return granted
        } catch {
            await checkStatus()
            return false
        }
    }

    // MARK: Reminder CRUD

    func addReminder(_ reminder: FocusReminder) {
        guard reminders.count < maxReminderCount else {
            error = String(format: AppLocalization.string("max_reminders"), maxReminderCount)
            return
        }
        let reminder = sanitized(reminder)
        reminders.append(reminder)
        persist()
        if reminder.isEnabled { schedule(reminder) }
    }

    func updateReminder(_ reminder: FocusReminder) {
        guard let i = reminders.firstIndex(where: { $0.id == reminder.id }) else { return }
        cancel(reminders[i])
        reminders[i] = sanitized(reminder)
        persist()
        if reminders[i].isEnabled { schedule(reminders[i]) }
    }

    func removeReminder(_ reminder: FocusReminder) {
        cancel(reminder)
        reminders.removeAll { $0.id == reminder.id }
        persist()
    }

    func toggleReminder(_ reminder: FocusReminder) {
        guard let i = reminders.firstIndex(where: { $0.id == reminder.id }) else { return }
        reminders[i].isEnabled.toggle()
        if reminders[i].isEnabled {
            schedule(reminders[i])
        } else {
            cancel(reminders[i])
        }
        persist()
    }

    /// Re-schedule every enabled reminder (call after mode activation).
    func rescheduleAll() {
        cancelManagedNotifications()
        for r in reminders where r.isEnabled { schedule(r) }
    }

    /// Cancel all pending notifications (call after mode deactivation).
    func cancelAll() {
        cancelManagedNotifications()
    }

    // MARK: Daily Quote of the Day (5 AM)

    /// Identifier prefix for the daily quote notifications. The quote-day key
    /// is appended, which is what makes rescheduling idempotent.
    static let quoteIdentifierPrefix = "spike-daily-quote-"

    /// `userInfo` keys carried by a quote notification so a tap can open the
    /// sheet on exactly the quote that was delivered.
    static let quoteDayInfoKey = "spike_quote_day"
    static let quoteIndexInfoKey = "spike_quote_index"

    /// Days of quote notifications kept queued. Enough that someone who doesn't
    /// open the app for a week keeps receiving them, while staying well inside
    /// the 64-pending-notification budget shared with reminders and goals.
    private static let quoteScheduleHorizon = 7

    /// Queues the upcoming 5 AM quote notifications.
    ///
    /// The body is rendered from `QuoteTrackingStore.quoteIndex` — the very same
    /// pure function of (user, quote day) the app uses to pick the quote it
    /// displays. Both sides therefore resolve to the same quote with no shared
    /// state to drift, no network round trip, and no dependence on *when* the
    /// notification happened to be scheduled.
    ///
    /// Safe to call as often as you like: each day is written under a stable
    /// identifier, so re-adding replaces the pending request rather than
    /// duplicating it. That is also the upgrade path — it overwrites bodies left
    /// behind by the old random picker, and refreshes them after a language
    /// change or a switch of signed-in user.
    func scheduleDailyQuotes(userId: UUID? = nil) {
        Task {
            let calendar = Calendar.current
            let now = Date()
            let language = UserDefaults.standard.string(forKey: "spike_app_language") ?? "en"
            var scheduled: Set<String> = []

            // Starts at today: opened in the small hours, this morning's 5 AM is
            // still ahead. Days already past their boundary are skipped.
            for dayOffset in 0..<Self.quoteScheduleHorizon {
                guard let day = calendar.date(byAdding: .day, value: dayOffset, to: now),
                      let fireDate = calendar.date(
                          bySettingHour: QuoteTrackingStore.quoteHour, minute: 0, second: 0, of: day
                      ),
                      fireDate > now
                else { continue }

                let dayKey = QuoteTrackingStore.dayKey(for: fireDate, calendar: calendar)
                let identifier = Self.quoteIdentifierPrefix + dayKey
                scheduled.insert(identifier)

                let quoteIndex = QuoteTrackingStore.quoteIndex(userId: userId, dayKey: dayKey)
                let quote = QuoteTrackingStore.quote(userId: userId, dayKey: dayKey)

                let content = UNMutableNotificationContent()
                content.title = AppLocalization.string("quote_of_day")
                content.body = "\"\(Self.quoteBody(index: quoteIndex, quote: quote, language: language))\"\n— \(quote.author)"
                content.sound = .default
                content.userInfo = [
                    Self.quoteDayInfoKey: dayKey,
                    Self.quoteIndexInfoKey: quoteIndex,
                ]

                var dc = calendar.dateComponents([.year, .month, .day], from: fireDate)
                dc.hour = QuoteTrackingStore.quoteHour
                dc.minute = 0

                let trigger = UNCalendarNotificationTrigger(dateMatching: dc, repeats: false)
                let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
                try? await center.add(request)
            }

            // Discard quote notifications outside the window. Without this, a
            // request queued by an older build for a date we no longer write
            // would still fire with a quote the app will never show.
            let stale = await center.pendingNotificationRequests()
                .map(\.identifier)
                .filter { $0.hasPrefix(Self.quoteIdentifierPrefix) && !scheduled.contains($0) }
            if !stale.isEmpty {
                center.removePendingNotificationRequests(withIdentifiers: stale)
            }
        }
    }

    /// Drops every pending quote notification — used on sign-out, where the
    /// per-user quote sequence no longer applies to whoever holds the device.
    func cancelDailyQuotes() {
        center.getPendingNotificationRequests { requests in
            let ids = requests
                .map(\.identifier)
                .filter { $0.hasPrefix(NotificationManager.quoteIdentifierPrefix) }
            guard !ids.isEmpty else { return }
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
        }
    }

    /// The quote text in the user's language: bundled translation first, then
    /// anything the app cached from the translate-quote function, then the
    /// English original. Mirrors `QuoteTrackingStore.loadTranslation` so the
    /// banner and the sheet resolve to the same string.
    private static func quoteBody(index: Int, quote: DailyQuote, language: String) -> String {
        guard language != "en" else { return quote.text }

        if let bundled = QuotesTranslations.all[language],
           index < bundled.count,
           !bundled[index].isEmpty {
            return bundled[index]
        }

        if let cached = UserDefaults.standard.string(forKey: "spike_quote_trans_\(language)_\(index)"),
           !cached.isEmpty {
            return cached
        }

        return quote.text
    }

    // MARK: No-Goals Midday Reminder

    func scheduleNoGoalsReminder() {
        // Cancel any existing no-goals notification
        center.removePendingNotificationRequests(withIdentifiers: ["spike_no_goals_midday"])

        let calendar = Calendar.current
        let now = Date()
        let hour = calendar.component(.hour, from: now)

        // Build the target date: today at 1 PM if before 1 PM, otherwise tomorrow at 1 PM
        var dc = calendar.dateComponents([.year, .month, .day], from: now)
        dc.hour = 13
        dc.minute = 0

        if hour >= 13 {
            // Already past 1 PM — schedule for tomorrow
            guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: now) else { return }
            dc = calendar.dateComponents([.year, .month, .day], from: tomorrow)
            dc.hour = 13
            dc.minute = 0
        }

        let content = UNMutableNotificationContent()
        content.title = "Spike AI"
        content.body = AppLocalization.string("no_goals_reminder_body")
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(dateMatching: dc, repeats: false)
        let req = UNNotificationRequest(identifier: "spike_no_goals_midday", content: content, trigger: trigger)
        center.add(req)
    }

    func cancelNoGoalsReminder() {
        center.removePendingNotificationRequests(withIdentifiers: ["spike_no_goals_midday"])
    }

    // MARK: Goal Reminders

    func scheduleGoalReminder(goalId: String, title: String, targetDate: Date) {
        let content = UNMutableNotificationContent()
        content.title = AppLocalization.string("goal_reminder")
        content.body = "\(AppLocalization.string("dont_forget")): \(title)"
        content.sound = .default

        // Notify at 9 AM on the target date
        var dc = Calendar.current.dateComponents([.year, .month, .day], from: targetDate)
        dc.hour = 9
        dc.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dc, repeats: false)
        let req = UNNotificationRequest(identifier: "spike-goal-\(goalId)", content: content, trigger: trigger)
        center.add(req)
    }

    func cancelGoalReminder(goalId: String) {
        center.removePendingNotificationRequests(withIdentifiers: ["spike-goal-\(goalId)"])
    }

    // MARK: Private — Scheduling

    private func schedule(_ reminder: FocusReminder) {
        let content = UNMutableNotificationContent()
        content.title = AppLocalization.string("spike_ai_focus")
        content.body  = reminder.message
        content.sound = .default

        for day in reminder.days {
            var dc = DateComponents()
            dc.hour    = reminder.hour
            dc.minute  = reminder.minute
            dc.weekday = day

            let trigger = UNCalendarNotificationTrigger(dateMatching: dc, repeats: true)
            let req = UNNotificationRequest(
                identifier: reminderIdentifier(reminder, day: day),
                content: content,
                trigger: trigger
            )
            center.add(req)
        }
    }

    private func cancel(_ reminder: FocusReminder) {
        let ids = (1...7).map { reminderIdentifier(reminder, day: $0) }
        center.removePendingNotificationRequests(withIdentifiers: ids)
    }

    private func cancelManagedNotifications() {
        center.getPendingNotificationRequests { [reminderPrefix] requests in
            let ids = requests
                .map(\.identifier)
                .filter { $0.hasPrefix(reminderPrefix) || $0 == "spike_chill_morning" }
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
        }
    }

    private func reminderIdentifier(_ reminder: FocusReminder, day: Int) -> String {
        "\(reminderPrefix)\(reminder.id.uuidString)-\(day)"
    }

    private func sanitized(_ reminder: FocusReminder) -> FocusReminder {
        let message = reminder.message
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .prefix(140)
        let days = reminder.days.filter { (1...7).contains($0) }

        return FocusReminder(
            id: reminder.id,
            message: message.isEmpty ? AppLocalization.string("time_to_focus") : String(message),
            hour: min(max(reminder.hour, 0), 23),
            minute: min(max(reminder.minute, 0), 59),
            isEnabled: reminder.isEnabled,
            days: days.isEmpty ? Set(1...7) : Set(days)
        )
    }

    // MARK: Private — Persistence

    private func persist() {
        let store = UserDefaults(suiteName: FocusConstants.appGroupID) ?? .standard
        if let data = try? JSONEncoder().encode(reminders) {
            store.set(data, forKey: FocusConstants.remindersKey)
        }
    }

    private func loadReminders() {
        let store = UserDefaults(suiteName: FocusConstants.appGroupID) ?? .standard
        guard let data = store.data(forKey: FocusConstants.remindersKey),
              let saved = try? JSONDecoder().decode([FocusReminder].self, from: data) else { return }
        reminders = saved
    }
}
