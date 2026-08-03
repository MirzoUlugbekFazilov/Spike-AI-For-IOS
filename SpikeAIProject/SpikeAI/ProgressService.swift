//
//  ProgressService.swift
//  Spike AI
//

import Foundation
import Observation

enum ConsistencyLevel: String, CaseIterable {
    case unstable = "Unstable"
    case stable = "Stable"
    case strong = "Strong"
    case elite = "Elite"
}

struct ProgressMilestone: Identifiable, Hashable {
    let id: String
    let title: String
    let subtitle: String
    let isUnlocked: Bool
}

struct FocusCalendarDay: Identifiable, Hashable {
    let id: String
    let date: Date
    let dayNumber: Int
    let isFocusDay: Bool
    let completedItems: [String]
    let missedItems: [String]
    let activeMode: String?
}

struct ProgressSnapshot {
    let currentStreak: Int
    let bestStreak: Int
    let totalFocusDays: Int
    let consistencyLevel: ConsistencyLevel
    let monthlyConsistencyPercent: Int
    let monthlyFocusDays: Int
    let monthlyMissedDays: Int
    let timeReclaimedThisWeek: TimeInterval
    let weeklyNarrative: String
    let screenTimeTrend: String
    let averageScreenTimeLastSevenDays: TimeInterval
    let screenTimeBenchmarkMessage: String
    let milestones: [ProgressMilestone]
    let calendarDays: [FocusCalendarDay]
}

struct DailyTaskHistory: Codable, Hashable {
    var completed: [String]
    var missed: [String]
}

enum DailyTaskHistoryStore {
    static let key = "linear_daily_task_history"

    static func recordToday(tasks: [TaskRecord]) {
        let completed = tasks.filter(\.completed).map(\.title)
        let missed = tasks.filter { !$0.completed }.map(\.title)
        record(day: todayString(), completed: completed, missed: missed)
    }

    static func record(day: String, completed: [String], missed: [String]) {
        var history = load()
        history[day] = DailyTaskHistory(completed: completed, missed: missed)
        save(history)
    }

    static func load() -> [String: DailyTaskHistory] {
        guard let data = UserDefaults.standard.data(forKey: key),
              var history = try? JSONDecoder().decode([String: DailyTaskHistory].self, from: data) else {
            return [:]
        }
        // Prune entries older than 90 days
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        let cutoff = Calendar.current.date(byAdding: .day, value: -90, to: Date()) ?? Date()
        let originalCount = history.count
        history = history.filter { key, _ in
            guard let date = formatter.date(from: key) else { return false }
            return date >= cutoff
        }
        if history.count != originalCount {
            save(history)
        }
        return history
    }

    private static func save(_ history: [String: DailyTaskHistory]) {
        if let data = try? JSONEncoder().encode(history) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}

struct ProgressService {
    private let calendar: Calendar
    private let now: Date

    init(calendar: Calendar = .current, now: Date = Date()) {
        self.calendar = calendar
        self.now = now
    }

    func snapshot(
        successDays: Set<String>,
        tasks: [TaskRecord],
        usageByDay: [String: TimeInterval],
        unlockedMilestoneIDs: Set<String>
    ) -> ProgressSnapshot {
        let currentStreak = monthlyStreak(in: successDays, endingAt: now)
        let bestStreak = bestStreak(in: successDays)
        let totalFocusDays = successDays.count
        let recentFocusDays = countSuccessDays(in: successDays, daysBack: 30)
        let level = consistencyLevel(recentFocusDays: recentFocusDays, currentStreak: currentStreak, bestStreak: bestStreak)
        let monthlyFocusDays = countSuccessDaysThisMonth(in: successDays)
        let monthlyElapsedDays = elapsedTrackedDaysThisMonth(successDays: successDays, tasks: tasks)
        let monthlyMissedDays = max(0, monthlyElapsedDays - monthlyFocusDays)
        let monthlyPercent = consistencyPercent(streakDays: monthlyFocusDays, missedDays: monthlyMissedDays)
        let reclaimed = timeReclaimedThisWeek(successDays: successDays, usageByDay: usageByDay)
        let trend = screenTimeTrend(usageByDay: usageByDay)
        let averageScreenTime = recentAverageUsage(usageByDay: usageByDay)
        let milestones = makeMilestones(
            currentStreak: currentStreak,
            bestStreak: bestStreak,
            totalFocusDays: totalFocusDays,
            timeReclaimedThisWeek: reclaimed,
            unlockedIDs: unlockedMilestoneIDs
        )
        let calendarDays = monthCalendarDays(successDays: successDays, tasks: tasks)

        return ProgressSnapshot(
            currentStreak: currentStreak,
            bestStreak: bestStreak,
            totalFocusDays: totalFocusDays,
            consistencyLevel: level,
            monthlyConsistencyPercent: monthlyPercent,
            monthlyFocusDays: monthlyFocusDays,
            monthlyMissedDays: monthlyMissedDays,
            timeReclaimedThisWeek: reclaimed,
            weeklyNarrative: weeklyNarrative(recentFocusDays: countSuccessDays(in: successDays, daysBack: 7), trend: trend),
            screenTimeTrend: trend,
            averageScreenTimeLastSevenDays: averageScreenTime,
            screenTimeBenchmarkMessage: screenTimeBenchmarkMessage(averageUsage: averageScreenTime),
            milestones: milestones,
            calendarDays: calendarDays
        )
    }

    func newlyUnlockedMilestoneIDs(from milestones: [ProgressMilestone], existingIDs: Set<String>) -> Set<String> {
        Set(milestones.filter { $0.isUnlocked && !existingIDs.contains($0.id) }.map(\.id))
    }

    private func consistencyLevel(recentFocusDays: Int, currentStreak: Int, bestStreak: Int) -> ConsistencyLevel {
        if recentFocusDays >= 26 || currentStreak >= 21 { return .elite }
        if recentFocusDays >= 20 || currentStreak >= 10 || bestStreak >= 14 { return .strong }
        if recentFocusDays >= 12 || currentStreak >= 3 { return .stable }
        return .unstable
    }

    private func timeReclaimedThisWeek(successDays: Set<String>, usageByDay: [String: TimeInterval]) -> TimeInterval {
        let focusDays = countSuccessDays(in: successDays, daysBack: 7)
        let baseline: TimeInterval = TimeInterval(focusDays * 35 * 60)
        let improvement = max(0, previousAverageUsage(usageByDay: usageByDay) - recentAverageUsage(usageByDay: usageByDay)) * 7
        // Focus-day baseline is used until Apple Screen Time reports are available for this metric.
        return baseline + improvement
    }

    private func weeklyNarrative(recentFocusDays: Int, trend: String) -> String {
        if trend.contains("improved") {
            return AppLocalization.string("narrative_improved")
        }
        if recentFocusDays >= 5 {
            return AppLocalization.string("narrative_consistent")
        }
        if recentFocusDays >= 3 {
            return AppLocalization.string("narrative_more_days")
        }
        return AppLocalization.string("narrative_building")
    }

    private func screenTimeTrend(usageByDay: [String: TimeInterval]) -> String {
        let previous = previousAverageUsage(usageByDay: usageByDay)
        guard previous > 0 else { return AppLocalization.string("screen_time_trend_pending") }

        let recent = recentAverageUsage(usageByDay: usageByDay)
        let change = (previous - recent) / previous
        if change >= 0.02 {
            return String(format: AppLocalization.string("screen_time_improved"), Int((change * 100).rounded()))
        }
        if change <= -0.05 {
            return AppLocalization.string("screen_time_higher")
        }
        return AppLocalization.string("screen_time_steady")
    }

    private func makeMilestones(
        currentStreak: Int,
        bestStreak: Int,
        totalFocusDays: Int,
        timeReclaimedThisWeek: TimeInterval,
        unlockedIDs: Set<String>
    ) -> [ProgressMilestone] {
        let earned3Day = bestStreak >= 3 || currentStreak >= 3 || unlockedIDs.contains("streak_3")
        let earned7Day = bestStreak >= 7 || currentStreak >= 7 || unlockedIDs.contains("streak_7")
        let earned10Hours = timeReclaimedThisWeek >= 10 * 60 * 60 || unlockedIDs.contains("reclaimed_10h")
        let earned30Days = totalFocusDays >= 30 || unlockedIDs.contains("focus_30")

        return [
            ProgressMilestone(id: "streak_3", title: AppLocalization.string("milestone_3day_streak"), subtitle: AppLocalization.string("milestone_3day_desc"), isUnlocked: earned3Day),
            ProgressMilestone(id: "streak_7", title: AppLocalization.string("milestone_7day_streak"), subtitle: AppLocalization.string("milestone_7day_desc"), isUnlocked: earned7Day),
            ProgressMilestone(id: "reclaimed_10h", title: AppLocalization.string("milestone_10h_protected"), subtitle: AppLocalization.string("milestone_10h_desc"), isUnlocked: earned10Hours),
            ProgressMilestone(id: "focus_30", title: AppLocalization.string("milestone_30_focus"), subtitle: AppLocalization.string("milestone_30_desc"), isUnlocked: earned30Days)
        ]
    }

    private func monthCalendarDays(successDays: Set<String>, tasks: [TaskRecord]) -> [FocusCalendarDay] {
        guard let interval = calendar.dateInterval(of: .month, for: now),
              let days = calendar.dateComponents([.day], from: interval.start, to: interval.end).day else {
            return []
        }

        let history = DailyTaskHistoryStore.load()
        let modeHistory = UserDefaults(suiteName: FocusConstants.appGroupID)?
            .dictionary(forKey: "spike_mode_history") as? [String: String] ?? [:]

        return (0..<days).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: offset, to: interval.start) else { return nil }
            let key = dayString(from: date)
            let isFocusDay = successDays.contains(key)
            let saved = history[key]
            let isToday = calendar.isDate(date, inSameDayAs: now)
            let completed = saved?.completed ?? (isToday ? tasks.filter(\.completed).map(\.title) : [])
            let missed = saved?.missed ?? (isToday ? tasks.filter { !$0.completed }.map(\.title) : [])
            return FocusCalendarDay(
                id: key,
                date: date,
                dayNumber: calendar.component(.day, from: date),
                isFocusDay: isFocusDay,
                completedItems: completed,
                missedItems: missed,
                activeMode: modeHistory[key]
            )
        }
    }

    private func countSuccessDaysThisMonth(in successDays: Set<String>) -> Int {
        guard let interval = calendar.dateInterval(of: .month, for: now) else { return 0 }
        return successDays.compactMap { date(from: $0) }.filter { interval.contains($0) && $0 <= now }.count
    }

    private func elapsedTrackedDaysThisMonth(successDays: Set<String>, tasks: [TaskRecord]) -> Int {
        guard let month = calendar.dateInterval(of: .month, for: now) else {
            return calendar.component(.day, from: now)
        }

        let start = max(month.start, firstUseDate(successDays: successDays, tasks: tasks) ?? month.start)
        let startOfStart = calendar.startOfDay(for: start)
        let startOfToday = calendar.startOfDay(for: now)
        guard startOfStart <= startOfToday else { return 0 }
        return (calendar.dateComponents([.day], from: startOfStart, to: startOfToday).day ?? 0) + 1
    }

    private func firstUseDate(successDays: Set<String>, tasks: [TaskRecord]) -> Date? {
        let successDates = successDays.compactMap { date(from: $0) }
        let taskDates = tasks.compactMap { dateTime(from: $0.createdAt) }
        let stored = UserDefaults.standard.object(forKey: "linear_first_use_date") as? Date
        let earliest = (successDates + taskDates + [stored].compactMap { $0 }).min()
        if let earliest {
            UserDefaults.standard.set(earliest, forKey: "linear_first_use_date")
            return earliest
        }
        UserDefaults.standard.set(now, forKey: "linear_first_use_date")
        return now
    }

    private func consistencyPercent(streakDays: Int, missedDays: Int) -> Int {
        let total = streakDays + missedDays
        guard total > 0 else { return 0 }
        return Int((Double(streakDays) / Double(total) * 100).rounded())
    }

    private func countSuccessDays(in successDays: Set<String>, daysBack: Int) -> Int {
        (0..<daysBack).reduce(0) { count, offset in
            guard let date = calendar.date(byAdding: .day, value: -offset, to: now) else { return count }
            return count + (successDays.contains(dayString(from: date)) ? 1 : 0)
        }
    }

    private func streak(in successDays: Set<String>, endingAt date: Date) -> Int {
        var count = 0
        var cursor = date
        while successDays.contains(dayString(from: cursor)) {
            count += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = previous
        }
        return count
    }

    private func monthlyStreak(in successDays: Set<String>, endingAt date: Date) -> Int {
        guard let month = calendar.dateInterval(of: .month, for: date) else {
            return streak(in: successDays, endingAt: date)
        }
        var count = 0
        var cursor = date
        while cursor >= month.start && successDays.contains(dayString(from: cursor)) {
            count += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = previous
        }
        return count
    }

    private func bestStreak(in successDays: Set<String>) -> Int {
        let sorted = successDays.compactMap { date(from: $0) }.sorted()
        guard !sorted.isEmpty else { return 0 }

        var best = 1
        var current = 1
        for index in 1..<sorted.count {
            let previous = sorted[index - 1]
            let currentDate = sorted[index]
            let diff = calendar.dateComponents([.day], from: previous, to: currentDate).day ?? 0
            if diff == 1 {
                current += 1
                best = max(best, current)
            } else if diff > 1 {
                current = 1
            }
        }
        return best
    }

    private func recentAverageUsage(usageByDay: [String: TimeInterval]) -> TimeInterval {
        averageUsage(usageByDay: usageByDay, startOffset: 0, count: 7)
    }

    private func previousAverageUsage(usageByDay: [String: TimeInterval]) -> TimeInterval {
        averageUsage(usageByDay: usageByDay, startOffset: 7, count: 7)
    }

    private func averageUsage(usageByDay: [String: TimeInterval], startOffset: Int, count: Int) -> TimeInterval {
        let values = (startOffset..<(startOffset + count)).compactMap { offset -> TimeInterval? in
            guard let date = calendar.date(byAdding: .day, value: -offset, to: now) else { return nil }
            return usageByDay[dayString(from: date), default: 0]
        }
        guard !values.isEmpty else { return 0 }
        return values.reduce(0, +) / Double(values.count)
    }

    private func screenTimeBenchmarkMessage(averageUsage: TimeInterval) -> String {
        let worldAverage: TimeInterval = 7 * 60 * 60
        guard averageUsage > 0 else {
            return AppLocalization.string("benchmark_pending")
        }
        let formatted = formatDuration(averageUsage)
        if averageUsage < worldAverage {
            return String(format: AppLocalization.string("benchmark_below"), formatted)
        }
        if averageUsage > worldAverage {
            return String(format: AppLocalization.string("benchmark_above"), formatted)
        }
        return String(format: AppLocalization.string("benchmark_matching"), formatted)
    }

    private func formatDuration(_ interval: TimeInterval) -> String {
        let minutes = max(0, Int((interval / 60).rounded()))
        if minutes < 60 {
            return String(format: AppLocalization.string("time_m"), minutes)
        }
        return String(format: AppLocalization.string("time_h_m"), minutes / 60, minutes % 60)
    }

    private func date(from string: String) -> Date? {
        resolvedDayFormatter.date(from: string)
    }

    private func dateTime(from string: String?) -> Date? {
        guard let string else { return nil }
        return ISO8601DateFormatter().date(from: string)
    }

    private func dayString(from date: Date) -> String {
        resolvedDayFormatter.string(from: date)
    }

    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

    private var resolvedDayFormatter: DateFormatter {
        let f = Self.dayFormatter
        f.timeZone = calendar.timeZone
        return f
    }
}

@MainActor @Observable
final class ProgressMilestoneStore {
    private let key = "linear_progress_unlocked_milestones"
    var unlockedIDs: Set<String> = []

    init() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let saved = try? JSONDecoder().decode(Set<String>.self, from: data) else { return }
        unlockedIDs = saved
    }

    func storeUnlocked(_ ids: Set<String>) {
        guard !ids.isEmpty else { return }
        unlockedIDs.formUnion(ids)
        persist()
    }

    func resetForSignedOutUser(clearPersisted: Bool = true) {
        unlockedIDs = []
        if clearPersisted {
            UserDefaults.standard.removeObject(forKey: key)
        }
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(unlockedIDs) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}
