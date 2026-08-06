//
//  QuoteOfTheDayTests.swift
//  SpikeAITests
//
//  The 5 AM notification is written days before the app decides what to show
//  that morning, so the two can only agree if both derive the quote from the
//  same pure function of (user, quote day). These tests pin that down.
//

import Foundation
import Testing
@testable import SpikeAI

struct QuoteOfTheDayTests {

    // MARK: - Notification ⇄ app agreement

    @Test func notificationAndAppResolveTheSameQuote() throws {
        let user = UUID(uuidString: "6C7C6D5E-0000-4000-8000-00000000ABCD")!

        // What the scheduler bakes into the banner for a given morning…
        let fireDate = try #require(makeDate("2026-08-07 05:00", in: .newYork))
        let scheduledKey = QuoteTrackingStore.dayKey(for: fireDate, calendar: .newYork)
        let scheduled = QuoteTrackingStore.quote(userId: user, dayKey: scheduledKey)

        // …must be what the app shows at every moment that quote day owns.
        for time in ["05:00", "05:01", "09:30", "23:59"] {
            let now = try #require(makeDate("2026-08-07 \(time)", in: .newYork))
            let displayedKey = QuoteTrackingStore.quoteDay(for: now, calendar: .newYork)
            let displayed = QuoteTrackingStore.quote(userId: user, dayKey: displayedKey)

            #expect(displayedKey == scheduledKey, "quote day drifted at \(time)")
            #expect(displayed.text == scheduled.text, "quote text drifted at \(time)")
        }
    }

    @Test func quoteHoldsUntilTheFiveAMBoundary() throws {
        // 04:59 still belongs to the previous day: the app must not swap the
        // quote before the notification that announces the new one arrives.
        let beforeBoundary = try #require(makeDate("2026-08-07 04:59", in: .newYork))
        #expect(QuoteTrackingStore.quoteDay(for: beforeBoundary, calendar: .newYork) == "2026-08-06")

        let atBoundary = try #require(makeDate("2026-08-07 05:00", in: .newYork))
        #expect(QuoteTrackingStore.quoteDay(for: atBoundary, calendar: .newYork) == "2026-08-07")
    }

    @Test func quoteDaySurvivesDaylightSavingTransitions() throws {
        // Clocks spring forward at 02:00 on 2026-03-08 (US). Subtracting five
        // fixed hours from 05:30 lands on the previous calendar day here, which
        // is exactly how the app and the notification used to disagree.
        let springForward = try #require(makeDate("2026-03-08 05:30", in: .newYork))
        #expect(QuoteTrackingStore.quoteDay(for: springForward, calendar: .newYork) == "2026-03-08")

        // Clocks fall back at 02:00 on 2026-11-01 (US).
        let fallBack = try #require(makeDate("2026-11-01 05:30", in: .newYork))
        #expect(QuoteTrackingStore.quoteDay(for: fallBack, calendar: .newYork) == "2026-11-01")
    }

    // MARK: - Selection behaviour

    @Test func sameDayAlwaysYieldsTheSameQuote() {
        let user = UUID(uuidString: "11111111-2222-3333-4444-555555555555")!
        let first = QuoteTrackingStore.quoteIndex(userId: user, dayKey: "2026-08-07")
        let second = QuoteTrackingStore.quoteIndex(userId: user, dayKey: "2026-08-07")

        #expect(first == second)
        #expect(QuotesData.all.indices.contains(first))
    }

    @Test func signedOutUsersStillGetAStablePerDayQuote() {
        let first = QuoteTrackingStore.quoteIndex(userId: nil, dayKey: "2026-08-07")
        let second = QuoteTrackingStore.quoteIndex(userId: nil, dayKey: "2026-08-07")

        #expect(first == second)
        #expect(QuotesData.all.indices.contains(first))
        #expect(QuoteTrackingStore.quoteIndex(userId: nil, dayKey: "2026-08-08") != first)
    }

    @Test func quotesDoNotRepeatUntilTheCatalogueIsExhausted() throws {
        let user = UUID(uuidString: "ABCDEF01-2345-6789-ABCD-EF0123456789")!
        let start = try #require(makeDate("2026-01-01 12:00", in: .utc))
        let total = QuotesData.all.count

        var seen: Set<Int> = []
        for dayOffset in 0..<total {
            let day = try #require(Calendar.utc.date(byAdding: .day, value: dayOffset, to: start))
            let key = QuoteTrackingStore.dayKey(for: day, calendar: .utc)
            seen.insert(QuoteTrackingStore.quoteIndex(userId: user, dayKey: key))
        }

        #expect(seen.count == total, "a full cycle should cover every quote exactly once")
    }

    @Test func differentUsersGetDifferentSequences() throws {
        let a = UUID(uuidString: "AAAAAAAA-0000-4000-8000-000000000001")!
        let b = UUID(uuidString: "BBBBBBBB-0000-4000-8000-000000000002")!
        let start = try #require(makeDate("2026-01-01 12:00", in: .utc))

        var shared = 0
        for dayOffset in 0..<30 {
            let day = try #require(Calendar.utc.date(byAdding: .day, value: dayOffset, to: start))
            let key = QuoteTrackingStore.dayKey(for: day, calendar: .utc)
            if QuoteTrackingStore.quoteIndex(userId: a, dayKey: key)
                == QuoteTrackingStore.quoteIndex(userId: b, dayKey: key) {
                shared += 1
            }
        }

        #expect(shared == 0, "two users should rarely, if ever, share a day's quote")
    }

    // MARK: - Helpers

    private func makeDate(_ string: String, in calendar: Calendar) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = calendar.timeZone
        return formatter.date(from: string)
    }
}

private extension Calendar {
    /// A time zone with daylight saving, so the boundary maths is exercised
    /// rather than assumed away.
    static let newYork = fixed(to: "America/New_York")
    static let utc = fixed(to: "UTC")

    static func fixed(to identifier: String) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: identifier) ?? .gmt
        calendar.locale = Locale(identifier: "en_US_POSIX")
        return calendar
    }
}
