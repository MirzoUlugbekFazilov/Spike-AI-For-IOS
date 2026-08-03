//
//  SpikeAIUITests.swift
//  SpikeAIUITests
//
//  Created by Мирзо-Улугбек Фазилов on 04/05/2026.
//

import XCTest

final class SpikeAIUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testLaunchShowsExpectedEntrySurface() throws {
        let app = XCUIApplication()
        app.launch()

        let expectedTexts = [
            "Spike AI",
            "Home",
            "Progress",
            "Focus",
            "Profile",
            "Continue",
            "Sign in"
        ]

        let reachedKnownSurface = expectedTexts.contains { label in
            app.staticTexts[label].waitForExistence(timeout: 1)
                || app.buttons[label].waitForExistence(timeout: 1)
                || app.tabBars.buttons[label].waitForExistence(timeout: 1)
        }

        XCTAssertTrue(reachedKnownSurface, "Launch did not reach an expected auth, onboarding, or main-app surface.")
    }

    @MainActor
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
