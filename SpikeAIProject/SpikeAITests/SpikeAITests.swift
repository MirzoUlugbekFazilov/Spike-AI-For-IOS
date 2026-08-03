//
//  SpikeAITests.swift
//  SpikeAITests
//
//  Created by Мирзо-Улугбек Фазилов on 04/05/2026.
//

import Foundation
import Testing
@testable import SpikeAI

struct SpikeAITests {

    @Test func progressSnapshotCalculatesCoreProgress() async throws {
        let now = try #require(makeDate("2026-05-24"))
        let service = ProgressService(calendar: gregorianCalendar, now: now)
        let successDays: Set<String> = [
            "2026-05-19", "2026-05-20", "2026-05-21",
            "2026-05-22", "2026-05-23", "2026-05-24"
        ]

        let snapshot = service.snapshot(
            successDays: successDays,
            tasks: [],
            usageByDay: [:],
            unlockedMilestoneIDs: []
        )

        #expect(snapshot.currentStreak == 6)
        #expect(snapshot.bestStreak == 6)
        #expect(snapshot.monthlyFocusDays == 6)
        #expect(snapshot.monthlyConsistencyPercent == 25)
        #expect(snapshot.consistencyLevel == .stable)
        #expect(snapshot.milestones.first { $0.id == "streak_3" }?.isUnlocked == true)
        #expect(snapshot.milestones.first { $0.id == "streak_7" }?.isUnlocked == false)
    }

    @Test func progressSnapshotReportsScreenTimeImprovement() async throws {
        let now = try #require(makeDate("2026-05-24"))
        let service = ProgressService(calendar: gregorianCalendar, now: now)
        var usage: [String: TimeInterval] = [:]

        for offset in 0..<7 {
            usage[dayString(offset: offset, from: now)] = 60 * 60
        }
        for offset in 7..<14 {
            usage[dayString(offset: offset, from: now)] = 2 * 60 * 60
        }

        let snapshot = service.snapshot(
            successDays: [],
            tasks: [],
            usageByDay: usage,
            unlockedMilestoneIDs: []
        )

        #expect(snapshot.screenTimeTrend == "Screen time improved by 50%")
        #expect(snapshot.weeklyNarrative == "Your screen time improved compared to last week.")
    }

    private var gregorianCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    private func makeDate(_ string: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter.date(from: string)
    }

    private func dayString(offset: Int, from date: Date) -> String {
        let target = gregorianCalendar.date(byAdding: .day, value: -offset, to: date) ?? date
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter.string(from: target)
    }

}
