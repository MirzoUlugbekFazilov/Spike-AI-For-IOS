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

    /// Reference to the shared quote tracking store (Supabase-backed).
    var quoteTrackingStore: QuoteTrackingStore?

    /// Schedules the next 3 days of quote notifications at 5 AM.
    /// Quotes are tracked via Supabase so they persist across reinstalls.
    func scheduleDailyQuotes(userId: UUID? = nil) {
        Task {
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            let pending = await center.pendingNotificationRequests()

            for dayOffset in 0..<3 {
                guard let targetDate = calendar.date(byAdding: .day, value: dayOffset + 1, to: today) else { continue }
                let dateKey = dateString(targetDate)
                let notifID = "spike-daily-quote-\(dateKey)"

                // Skip if already scheduled for this date
                if pending.contains(where: { $0.identifier == notifID }) { continue }

                let quote: DailyQuote
                let quoteIdx: Int
                if let uid = userId, let store = quoteTrackingStore {
                    quoteIdx = store.pickNotificationQuote(userId: uid)
                    quote = QuotesData.all[max(0, min(quoteIdx, QuotesData.all.count - 1))]
                } else {
                    quoteIdx = Int.random(in: 0..<QuotesData.all.count)
                    quote = QuotesData.all[quoteIdx]
                }

                // Use bundled or cached translation
                var displayText = quote.text
                let lang = UserDefaults.standard.string(forKey: "spike_app_language") ?? "en"
                if lang != "en" {
                    if let langArray = QuotesTranslations.all[lang],
                       quoteIdx < langArray.count,
                       !langArray[quoteIdx].isEmpty {
                        displayText = langArray[quoteIdx]
                    } else if let cached = UserDefaults.standard.string(forKey: "spike_quote_trans_\(lang)_\(quoteIdx)"),
                              !cached.isEmpty {
                        displayText = cached
                    }
                }

                let content = UNMutableNotificationContent()
                content.title = AppLocalization.string("quote_of_day")
                content.body = "\"\(displayText)\"\n— \(quote.author)"
                content.sound = .default

                var dc = calendar.dateComponents([.year, .month, .day], from: targetDate)
                dc.hour = 5
                dc.minute = 0

                let trigger = UNCalendarNotificationTrigger(dateMatching: dc, repeats: false)
                let req = UNNotificationRequest(identifier: notifID, content: content, trigger: trigger)
                try? await center.add(req)
            }
        }
    }

    private func dateString(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f.string(from: date)
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
