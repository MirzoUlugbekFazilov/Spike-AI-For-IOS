//
//  SpokenGoalParserTests.swift
//  SpikeAITests
//
//  A goal title says WHAT; the reminder says WHEN. These tests pin that split,
//  and guard the numbers that are NOT times against over-eager stripping.
//

import Foundation
import Testing
@testable import SpikeAI

struct SpokenGoalParserTests {

    // MARK: - The reported bug

    @Test func timeNeverSurvivesInTheTitle() {
        let goals = SpokenGoalParser.parse(
            "Tomorrow I want to have breakfast at 5:52 am and then hit the gym"
        )

        let breakfast = try? #require(goals.first)
        #expect(breakfast?.title == "Breakfast")
        #expect(breakfast?.time?.hour == 5)
        #expect(breakfast?.time?.minute == 52)
        #expect(breakfast?.dayOffset == 1)
        #expect(breakfast?.notify == true)
    }

    @Test func titlesAreCleanedAcrossTheSpokenFormsOfATime() {
        let cases: [(spoken: String, title: String)] = [
            ("Breakfast at 5:52 AM", "Breakfast"),
            ("Have breakfast at 5.52 am tomorrow", "Breakfast"),
            ("Go to gym at 6pm", "Go to gym"),
            ("Call mum at 7 o'clock", "Call mum"),
            ("Lunch at noon", "Lunch"),
            ("Meeting at half past eight", "Meeting"),
            ("Visit grandma at 6 tomorrow", "Visit grandma"),
            ("Study in the evening", "Study"),
            ("Hit the gym 6 pm", "Hit the gym"),
        ]

        for (spoken, expected) in cases {
            let title = SpokenGoalParser.cleanTitle(spoken)
            #expect(title == expected, "\"\(spoken)\" produced \"\(title)\"")
        }
    }

    @Test func dayWordsNeverSurviveInTheTitle() {
        let cases: [(spoken: String, title: String)] = [
            ("Call mum tomorrow", "Call mum"),
            ("Visit bank on Monday", "Visit bank"),
            ("Hit the gym tonight", "Hit the gym"),
            ("Buy groceries today", "Buy groceries"),
        ]

        for (spoken, expected) in cases {
            let title = SpokenGoalParser.cleanTitle(spoken)
            #expect(title == expected, "\"\(spoken)\" produced \"\(title)\"")
        }
    }

    @Test func aTimeInTheMiddleIsRemovedWithoutBreakingTheTitle() {
        // The seam left behind must close: no doubled spaces, no dangling "with".
        #expect(SpokenGoalParser.cleanTitle("Meeting at 5 pm with professor") == "Meeting with professor")
        #expect(SpokenGoalParser.cleanTitle("Breakfast at 5:52 am tomorrow") == "Breakfast")
    }

    // MARK: - Numbers that are not times

    @Test func countsAndMeasurementsAreLeftAlone() {
        let preserved = [
            "Run 5 km",
            "Buy 2 tickets",
            "Do 30 pushups",
            "Read 20 pages",
        ]

        for title in preserved {
            #expect(SpokenGoalParser.cleanTitle(title) == title,
                    "\"\(title)\" was altered to \"\(SpokenGoalParser.cleanTitle(title))\"")
        }
    }

    @Test func aPrepositionBeforeACountDoesNotMakeItATime() {
        // "at 3" here is followed by a noun, so it is not a clock reading.
        #expect(SpokenGoalParser.cleanTitle("Look at 3 options") == "Look at 3 options")
    }

    // MARK: - Guards

    @Test func aTitleMadeOnlyOfSchedulingWordsIsNotEmptied() {
        // Stripping everything would leave nothing to show or edit, so the
        // original is kept and the caller decides whether to reject it.
        #expect(!SpokenGoalParser.cleanTitle("At 5 PM").isEmpty)
        #expect(!SpokenGoalParser.cleanTitle("Tomorrow").isEmpty)
    }

    @Test func recoveringTimeAndDayFromFreeText() {
        #expect(SpokenGoalParser.time(in: "Breakfast at 5:52 AM")?.hour == 5)
        #expect(SpokenGoalParser.time(in: "Breakfast at 5:52 AM")?.minute == 52)
        #expect(SpokenGoalParser.time(in: "Gym at 6pm")?.hour == 18)
        #expect(SpokenGoalParser.time(in: "Buy groceries") == nil)

        #expect(SpokenGoalParser.relativeDayOffset(in: "Call mum tomorrow") == 1)
        #expect(SpokenGoalParser.relativeDayOffset(in: "Call mum day after tomorrow") == 2)
        #expect(SpokenGoalParser.relativeDayOffset(in: "Call mum") == 0)
    }

    // MARK: - Existing behaviour must not regress

    @Test func instructionsStillConfigureTheGoalBeforeThem() {
        let goals = SpokenGoalParser.parse(
            "I'm planning to visit the bank at 3 pm, make the priority low, turn on alarm"
        )

        #expect(goals.count == 1)
        #expect(goals.first?.title.localizedCaseInsensitiveContains("bank") == true)
        #expect(goals.first?.title.contains("3") == false)
        #expect(goals.first?.priority == .low)
        #expect(goals.first?.alarm == true)
        #expect(goals.first?.time?.hour == 15)
    }

    @Test func separateGoalsKeepTheirOwnTimes() {
        let goals = SpokenGoalParser.parse(
            "Today at 6 PM I'm planning to hit the gym. Also visit the bank at 9 am."
        )

        #expect(goals.count == 2)
        for goal in goals {
            #expect(!goal.title.contains(":"), "\"\(goal.title)\" still carries a clock time")
            #expect(goal.title.rangeOfCharacter(from: .decimalDigits) == nil,
                    "\"\(goal.title)\" still carries a number")
        }
    }
}
