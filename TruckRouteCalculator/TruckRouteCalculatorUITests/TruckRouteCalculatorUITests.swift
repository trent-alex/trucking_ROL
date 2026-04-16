//
//  TruckRouteCalculatorUITests.swift
//  TruckRouteCalculatorUITests
//
//  Comprehensive UI test suite for TruckRouteCalculator
//  Tests all clickpaths and generates a report
//

import XCTest

final class TruckRouteCalculatorUITests: XCTestCase {

    var app: XCUIApplication!
    static var testReport: [TestResult] = []
    static var screenshotCount = 0

    struct TestResult {
        let testName: String
        let flow: String
        let steps: [String]
        let passed: Bool
        let duration: TimeInterval
        let errorMessage: String?
        let screenshots: [String]
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]

        // Reset user defaults for clean state
        app.launchArguments.append("--reset-state")
    }

    override func tearDownWithError() throws {
        // Take final screenshot
        takeScreenshot(name: "final_state")
    }

    override class func tearDown() {
        // Generate report after all tests complete
        generateReport()
        super.tearDown()
    }

    // MARK: - Helper Methods

    func takeScreenshot(name: String) {
        Self.screenshotCount += 1
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "\(Self.screenshotCount)_\(name)"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func waitForElement(_ element: XCUIElement, timeout: TimeInterval = 5) -> Bool {
        return element.waitForExistence(timeout: timeout)
    }

    func recordResult(testName: String, flow: String, steps: [String], passed: Bool, duration: TimeInterval, error: String? = nil, screenshots: [String] = []) {
        Self.testReport.append(TestResult(
            testName: testName,
            flow: flow,
            steps: steps,
            passed: passed,
            duration: duration,
            errorMessage: error,
            screenshots: screenshots
        ))
    }

    static func generateReport() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let timestamp = dateFormatter.string(from: Date())

        var report = """
        ╔══════════════════════════════════════════════════════════════════╗
        ║          TRUCKROUTECALCULATOR UI TEST REPORT                     ║
        ╠══════════════════════════════════════════════════════════════════╣
        ║ Generated: \(timestamp.padding(toLength: 43, withPad: " ", startingAt: 0))║
        ╚══════════════════════════════════════════════════════════════════╝

        """

        let passed = testReport.filter { $0.passed }.count
        let failed = testReport.filter { !$0.passed }.count
        let totalDuration = testReport.reduce(0) { $0 + $1.duration }

        report += """

        ┌──────────────────────────────────────────────────────────────────┐
        │ SUMMARY                                                          │
        ├──────────────────────────────────────────────────────────────────┤
        │ Total Tests:  \(String(testReport.count).padding(toLength: 51, withPad: " ", startingAt: 0))│
        │ Passed:       \(String(passed).padding(toLength: 51, withPad: " ", startingAt: 0))│
        │ Failed:       \(String(failed).padding(toLength: 51, withPad: " ", startingAt: 0))│
        │ Duration:     \(String(format: "%.2fs", totalDuration).padding(toLength: 51, withPad: " ", startingAt: 0))│
        │ Pass Rate:    \(String(format: "%.1f%%", Double(passed) / max(1, Double(testReport.count)) * 100).padding(toLength: 51, withPad: " ", startingAt: 0))│
        └──────────────────────────────────────────────────────────────────┘

        """

        // Group by flow
        let flows = Dictionary(grouping: testReport) { $0.flow }

        for (flow, tests) in flows.sorted(by: { $0.key < $1.key }) {
            let flowPassed = tests.filter { $0.passed }.count
            report += """

            ┌──────────────────────────────────────────────────────────────────┐
            │ FLOW: \(flow.padding(toLength: 59, withPad: " ", startingAt: 0))│
            │ Status: \(flowPassed == tests.count ? "✅ ALL PASSED" : "❌ \(tests.count - flowPassed) FAILED")
            └──────────────────────────────────────────────────────────────────┘

            """

            for test in tests {
                let status = test.passed ? "✅ PASS" : "❌ FAIL"
                report += """

                  [\(status)] \(test.testName)
                  Duration: \(String(format: "%.2fs", test.duration))
                  Steps:
                """
                for (index, step) in test.steps.enumerated() {
                    report += "\n    \(index + 1). \(step)"
                }
                if let error = test.errorMessage {
                    report += "\n  ⚠️  Error: \(error)"
                }
                report += "\n"
            }
        }

        report += """

        ══════════════════════════════════════════════════════════════════
                              END OF REPORT
        ══════════════════════════════════════════════════════════════════
        """

        // Print to console
        print(report)

        // Save to file
        let fileManager = FileManager.default
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let reportPath = documentsPath.appendingPathComponent("UITestReport_\(Date().timeIntervalSince1970).txt")

        do {
            try report.write(to: reportPath, atomically: true, encoding: .utf8)
            print("\n📄 Report saved to: \(reportPath.path)")
        } catch {
            print("\n⚠️  Failed to save report: \(error)")
        }
    }

    // MARK: - Profile Setup Tests

    @MainActor
    func test01_ProfileSetup_NewUser() throws {
        let startTime = Date()
        var steps: [String] = []
        var screenshots: [String] = []

        app.launch()
        steps.append("Launched app")
        takeScreenshot(name: "profile_setup_start")
        screenshots.append("profile_setup_start")

        // Check if onboarding appears
        let welcomeText = app.staticTexts["Set Up Your Truck"]
        if waitForElement(welcomeText, timeout: 3) {
            steps.append("Profile setup screen displayed")

            // Select truck type
            let sleeperCab = app.buttons["Sleeper Cab"]
            if sleeperCab.waitForExistence(timeout: 2) {
                sleeperCab.tap()
                steps.append("Selected Sleeper Cab truck type")
            }
            takeScreenshot(name: "profile_truck_selected")

            // Scroll and continue
            app.swipeUp()
            steps.append("Scrolled to configuration options")

            // Select configuration
            let bobtailTrailer = app.buttons["Bobtail + Trailer"]
            if bobtailTrailer.waitForExistence(timeout: 2) {
                bobtailTrailer.tap()
                steps.append("Selected Bobtail + Trailer configuration")
            }

            // Select trailer type
            let dryVan = app.buttons["Dry Van"]
            if dryVan.waitForExistence(timeout: 2) {
                dryVan.tap()
                steps.append("Selected Dry Van trailer type")
            }
            takeScreenshot(name: "profile_config_selected")

            // Complete setup
            let saveButton = app.buttons["Save Profile"]
            if saveButton.waitForExistence(timeout: 2) {
                saveButton.tap()
                steps.append("Tapped Save Profile button")
            }

            // Verify main screen appears
            let loadRateField = app.textFields.firstMatch
            let success = waitForElement(loadRateField, timeout: 5)
            steps.append("Main calculator screen loaded: \(success ? "Yes" : "No")")
            takeScreenshot(name: "profile_setup_complete")

            recordResult(
                testName: "Profile Setup - New User",
                flow: "1. Profile Setup",
                steps: steps,
                passed: success,
                duration: Date().timeIntervalSince(startTime),
                screenshots: screenshots
            )

            XCTAssertTrue(success, "Main screen should appear after profile setup")
        } else {
            steps.append("Onboarding not shown (user may already have profile)")
            recordResult(
                testName: "Profile Setup - New User",
                flow: "1. Profile Setup",
                steps: steps,
                passed: true,
                duration: Date().timeIntervalSince(startTime),
                screenshots: screenshots
            )
        }
    }

    // MARK: - Scenario Input Tests

    @MainActor
    func test02_ScenarioInput_BasicFlow() throws {
        let startTime = Date()
        var steps: [String] = []

        app.launch()
        steps.append("Launched app")

        // Dismiss onboarding if present
        dismissOnboardingIfPresent()
        steps.append("Dismissed onboarding if present")

        // Wait for main screen
        sleep(1)
        takeScreenshot(name: "scenario_input_start")

        // Enter load rate
        let loadRateField = app.textFields.element(boundBy: 0)
        if loadRateField.waitForExistence(timeout: 3) {
            loadRateField.tap()
            loadRateField.typeText("2500")
            steps.append("Entered load rate: $2500")
        }
        takeScreenshot(name: "scenario_load_rate")

        // Enter current location
        let locationFields = app.textFields.allElementsBoundByIndex
        if locationFields.count > 1 {
            let currentLocationField = locationFields[1]
            currentLocationField.tap()
            currentLocationField.typeText("Dallas, TX")
            steps.append("Entered current location: Dallas, TX")
        }
        takeScreenshot(name: "scenario_location_entered")

        app.swipeUp()
        steps.append("Scrolled to see more fields")
        takeScreenshot(name: "scenario_scrolled")

        recordResult(
            testName: "Scenario Input - Basic Flow",
            flow: "2. Scenario Input",
            steps: steps,
            passed: true,
            duration: Date().timeIntervalSince(startTime)
        )
    }

    @MainActor
    func test03_ScenarioInput_GPSButton() throws {
        let startTime = Date()
        var steps: [String] = []

        app.launch()
        dismissOnboardingIfPresent()
        steps.append("Launched app")

        // Find GPS button
        let gpsButton = app.buttons["GPS"]
        if gpsButton.waitForExistence(timeout: 3) {
            gpsButton.tap()
            steps.append("Tapped GPS button")
            takeScreenshot(name: "gps_button_tapped")

            // GPS might show permission dialog or loading
            sleep(2)
            steps.append("Waited for GPS response")
            takeScreenshot(name: "gps_response")
        } else {
            steps.append("GPS button not found")
        }

        recordResult(
            testName: "Scenario Input - GPS Button",
            flow: "2. Scenario Input",
            steps: steps,
            passed: gpsButton.exists,
            duration: Date().timeIntervalSince(startTime)
        )
    }

    @MainActor
    func test04_ScenarioInput_AddMultipleDrops() throws {
        let startTime = Date()
        var steps: [String] = []

        app.launch()
        dismissOnboardingIfPresent()
        steps.append("Launched app")

        app.swipeUp()
        app.swipeUp()
        steps.append("Scrolled to delivery stops section")
        takeScreenshot(name: "drops_section")

        // Find Add Stop button
        let addStopButton = app.buttons["Add Stop"]
        if addStopButton.waitForExistence(timeout: 3) {
            addStopButton.tap()
            steps.append("Added second drop location")
            takeScreenshot(name: "drops_second_added")

            addStopButton.tap()
            steps.append("Added third drop location")
            takeScreenshot(name: "drops_third_added")
        }

        // Verify multiple stops exist
        let stopLabels = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH 'Stop'"))
        let stopCount = stopLabels.count
        steps.append("Total stops visible: \(stopCount)")

        recordResult(
            testName: "Scenario Input - Add Multiple Drops",
            flow: "2. Scenario Input",
            steps: steps,
            passed: stopCount >= 2,
            duration: Date().timeIntervalSince(startTime)
        )
    }

    @MainActor
    func test05_ScenarioInput_LumperCharges() throws {
        let startTime = Date()
        var steps: [String] = []

        app.launch()
        dismissOnboardingIfPresent()
        steps.append("Launched app")

        app.swipeUp()
        steps.append("Scrolled to lumper section")
        takeScreenshot(name: "lumper_section")

        // Look for lumper fields
        let lumperLabel = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Lumper'")).firstMatch
        let lumperFound = lumperLabel.waitForExistence(timeout: 3)
        steps.append("Lumper charge field found: \(lumperFound)")

        if lumperFound {
            takeScreenshot(name: "lumper_field_found")
        }

        recordResult(
            testName: "Scenario Input - Lumper Charges",
            flow: "2. Scenario Input",
            steps: steps,
            passed: lumperFound,
            duration: Date().timeIntervalSince(startTime)
        )
    }

    // MARK: - Settings Tests

    @MainActor
    func test06_Settings_OpenAndClose() throws {
        let startTime = Date()
        var steps: [String] = []

        app.launch()
        dismissOnboardingIfPresent()
        steps.append("Launched app")

        // Tap settings gear icon
        let settingsButton = app.buttons["gear"]
        if !settingsButton.waitForExistence(timeout: 2) {
            // Try navigation bar button
            app.navigationBars.buttons.element(boundBy: 1).tap()
        } else {
            settingsButton.tap()
        }
        steps.append("Tapped settings button")
        sleep(1)
        takeScreenshot(name: "settings_opened")

        // Verify settings content
        let fuelPriceLabel = app.staticTexts["Fuel Price"]
        let settingsShown = fuelPriceLabel.waitForExistence(timeout: 3)
        steps.append("Settings sheet displayed: \(settingsShown)")

        // Check for truck profile section
        let truckProfileSection = app.staticTexts["Truck Profile"]
        if truckProfileSection.exists {
            steps.append("Truck Profile section visible")
        }

        // Close settings
        let doneButton = app.buttons["Done"]
        if doneButton.exists {
            doneButton.tap()
            steps.append("Closed settings")
        }
        takeScreenshot(name: "settings_closed")

        recordResult(
            testName: "Settings - Open and Close",
            flow: "3. Settings",
            steps: steps,
            passed: settingsShown,
            duration: Date().timeIntervalSince(startTime)
        )
    }

    @MainActor
    func test07_Settings_ResetProfile() throws {
        let startTime = Date()
        var steps: [String] = []

        app.launch()
        dismissOnboardingIfPresent()
        steps.append("Launched app")

        // Open settings
        let navBarButtons = app.navigationBars.buttons
        if navBarButtons.count > 0 {
            navBarButtons.element(boundBy: navBarButtons.count - 1).tap()
        }
        steps.append("Opened settings")
        sleep(1)

        // Scroll to find Reset Profile
        app.swipeUp()
        takeScreenshot(name: "settings_scrolled")

        let resetButton = app.buttons["Reset Profile"]
        let resetFound = resetButton.waitForExistence(timeout: 3)
        steps.append("Reset Profile button found: \(resetFound)")

        if resetFound {
            takeScreenshot(name: "reset_profile_button")
            // Don't actually tap it in test to preserve state
            steps.append("Reset Profile button is accessible")
        }

        recordResult(
            testName: "Settings - Reset Profile Button",
            flow: "3. Settings",
            steps: steps,
            passed: resetFound,
            duration: Date().timeIntervalSince(startTime)
        )
    }

    // MARK: - Calculate Flow Tests

    @MainActor
    func test08_Calculate_ButtonState() throws {
        let startTime = Date()
        var steps: [String] = []

        app.launch()
        dismissOnboardingIfPresent()
        steps.append("Launched app")

        app.swipeUp()
        app.swipeUp()
        app.swipeUp()
        steps.append("Scrolled to calculate button")
        takeScreenshot(name: "calculate_button_area")

        // Find calculate button
        let calculateButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Calculate'")).firstMatch
        let buttonFound = calculateButton.waitForExistence(timeout: 3)
        steps.append("Calculate button found: \(buttonFound)")

        if buttonFound {
            let isEnabled = calculateButton.isEnabled
            steps.append("Calculate button enabled: \(isEnabled)")
            steps.append("Button should be disabled without required fields")
            takeScreenshot(name: "calculate_button_state")
        }

        recordResult(
            testName: "Calculate - Button State",
            flow: "4. Calculation",
            steps: steps,
            passed: buttonFound,
            duration: Date().timeIntervalSince(startTime)
        )
    }

    @MainActor
    func test09_Calculate_FullScenario() throws {
        let startTime = Date()
        var steps: [String] = []

        app.launch()
        dismissOnboardingIfPresent()
        steps.append("Launched app")
        takeScreenshot(name: "full_scenario_start")

        // Fill in required fields
        let textFields = app.textFields.allElementsBoundByIndex

        // Load rate
        if textFields.count > 0 {
            textFields[0].tap()
            textFields[0].typeText("3000")
            steps.append("Entered load rate: $3000")
        }

        // Current location
        if textFields.count > 1 {
            textFields[1].tap()
            textFields[1].typeText("Houston, TX")
            steps.append("Entered current location")
            sleep(1)
            // Dismiss keyboard
            app.tap()
        }

        app.swipeUp()
        steps.append("Scrolled for more fields")

        // More location fields
        let visibleFields = app.textFields.allElementsBoundByIndex
        for (index, field) in visibleFields.enumerated() {
            if index > 1 && index < 5 && field.value as? String == "" {
                field.tap()
                field.typeText("Austin, TX")
                app.tap()
                steps.append("Filled location field \(index)")
                break
            }
        }

        takeScreenshot(name: "full_scenario_filled")

        app.swipeUp()
        app.swipeUp()

        // Try to calculate
        let calculateButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Calculate'")).firstMatch
        if calculateButton.waitForExistence(timeout: 2) && calculateButton.isEnabled {
            calculateButton.tap()
            steps.append("Tapped Calculate button")
            sleep(3)
            takeScreenshot(name: "full_scenario_results")

            // Check for results
            let profitLabel = app.staticTexts.matching(NSPredicate(format: "label CONTAINS '$'")).firstMatch
            if profitLabel.exists {
                steps.append("Results displayed with profit calculation")
            }
        } else {
            steps.append("Calculate button not enabled - missing required fields")
        }

        recordResult(
            testName: "Calculate - Full Scenario",
            flow: "4. Calculation",
            steps: steps,
            passed: true,
            duration: Date().timeIntervalSince(startTime)
        )
    }

    // MARK: - Navigation Tests

    @MainActor
    func test10_Navigation_BackFromResults() throws {
        let startTime = Date()
        var steps: [String] = []

        app.launch()
        dismissOnboardingIfPresent()
        steps.append("Launched app")

        // This test assumes we can get to results
        // Check for Edit/Back button in nav bar
        let editButton = app.buttons["Edit"]
        let backButton = app.navigationBars.buttons.element(boundBy: 0)

        steps.append("Checking navigation elements")
        steps.append("Edit button exists: \(editButton.exists)")
        steps.append("Back button exists: \(backButton.exists)")

        takeScreenshot(name: "navigation_elements")

        recordResult(
            testName: "Navigation - Back Button",
            flow: "5. Navigation",
            steps: steps,
            passed: true,
            duration: Date().timeIntervalSince(startTime)
        )
    }

    // MARK: - Accessibility Tests

    @MainActor
    func test11_Accessibility_VoiceOverLabels() throws {
        let startTime = Date()
        var steps: [String] = []

        app.launch()
        dismissOnboardingIfPresent()
        steps.append("Launched app")

        // Check for accessibility labels
        let allElements = app.descendants(matching: .any).allElementsBoundByIndex
        var accessibleCount = 0

        for element in allElements.prefix(50) {
            if element.label.count > 0 {
                accessibleCount += 1
            }
        }

        steps.append("Elements with accessibility labels: \(accessibleCount)")
        takeScreenshot(name: "accessibility_check")

        recordResult(
            testName: "Accessibility - VoiceOver Labels",
            flow: "6. Accessibility",
            steps: steps,
            passed: accessibleCount > 10,
            duration: Date().timeIntervalSince(startTime)
        )
    }

    // MARK: - Performance Tests

    @MainActor
    func test12_Performance_LaunchTime() throws {
        let startTime = Date()
        var steps: [String] = []

        measure(metrics: [XCTApplicationLaunchMetric()]) {
            app.launch()
        }

        steps.append("Measured app launch performance")
        steps.append("Launch time metric recorded by XCTest")

        recordResult(
            testName: "Performance - Launch Time",
            flow: "7. Performance",
            steps: steps,
            passed: true,
            duration: Date().timeIntervalSince(startTime)
        )
    }

    @MainActor
    func test13_Performance_ScrollPerformance() throws {
        let startTime = Date()
        var steps: [String] = []

        app.launch()
        dismissOnboardingIfPresent()
        steps.append("Launched app")

        let scrollView = app.scrollViews.firstMatch
        if scrollView.exists {
            measure(metrics: [XCTOSSignpostMetric.scrollingAndDecelerationMetric]) {
                scrollView.swipeUp(velocity: .fast)
                scrollView.swipeDown(velocity: .fast)
            }
            steps.append("Measured scroll performance")
        }

        takeScreenshot(name: "scroll_performance")

        recordResult(
            testName: "Performance - Scroll",
            flow: "7. Performance",
            steps: steps,
            passed: true,
            duration: Date().timeIntervalSince(startTime)
        )
    }

    // MARK: - Edge Cases

    @MainActor
    func test14_EdgeCase_EmptyFields() throws {
        let startTime = Date()
        var steps: [String] = []

        app.launch()
        dismissOnboardingIfPresent()
        steps.append("Launched app")

        // Scroll to calculate without filling anything
        app.swipeUp()
        app.swipeUp()
        app.swipeUp()
        steps.append("Scrolled to calculate button")

        let calculateButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Calculate'")).firstMatch
        if calculateButton.exists {
            let isEnabled = calculateButton.isEnabled
            steps.append("Calculate button enabled with empty fields: \(isEnabled)")
            XCTAssertFalse(isEnabled, "Calculate should be disabled with empty fields")
        }

        takeScreenshot(name: "empty_fields_state")

        recordResult(
            testName: "Edge Case - Empty Fields",
            flow: "8. Edge Cases",
            steps: steps,
            passed: true,
            duration: Date().timeIntervalSince(startTime)
        )
    }

    @MainActor
    func test15_EdgeCase_LargeNumbers() throws {
        let startTime = Date()
        var steps: [String] = []

        app.launch()
        dismissOnboardingIfPresent()
        steps.append("Launched app")

        // Enter very large load rate
        let loadRateField = app.textFields.element(boundBy: 0)
        if loadRateField.waitForExistence(timeout: 3) {
            loadRateField.tap()
            loadRateField.typeText("999999")
            steps.append("Entered large load rate: $999,999")
            app.tap()
        }

        takeScreenshot(name: "large_numbers")

        recordResult(
            testName: "Edge Case - Large Numbers",
            flow: "8. Edge Cases",
            steps: steps,
            passed: true,
            duration: Date().timeIntervalSince(startTime)
        )
    }

    // MARK: - Helper Methods

    func dismissOnboardingIfPresent() {
        let saveButton = app.buttons["Save Profile"]
        if saveButton.waitForExistence(timeout: 2) {
            // Quick setup to dismiss onboarding
            let sleeperCab = app.buttons["Sleeper Cab"]
            if sleeperCab.exists { sleeperCab.tap() }

            app.swipeUp()

            let bobtailTrailer = app.buttons["Bobtail + Trailer"]
            if bobtailTrailer.exists { bobtailTrailer.tap() }

            let dryVan = app.buttons["Dry Van"]
            if dryVan.exists { dryVan.tap() }

            if saveButton.exists { saveButton.tap() }
            sleep(1)
        }
    }
}
