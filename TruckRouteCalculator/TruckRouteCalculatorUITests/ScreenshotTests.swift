import XCTest

class ScreenshotTests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = true
        app = XCUIApplication()
        setupSnapshot(app)
        app.launch()
    }

    func testScreenshots() throws {
        // Dismiss onboarding if present
        let welcomeText = app.staticTexts["Set Up Your Truck"]
        if welcomeText.waitForExistence(timeout: 2) {
            // Complete quick onboarding
            let sleeperCab = app.buttons["Sleeper Cab"]
            if sleeperCab.waitForExistence(timeout: 2) {
                sleeperCab.tap()
            }
            app.swipeUp()

            let dryVan = app.buttons["Dry Van"]
            if dryVan.waitForExistence(timeout: 2) {
                dryVan.tap()
            }

            let saveButton = app.buttons["Save Profile"]
            if saveButton.waitForExistence(timeout: 2) {
                saveButton.tap()
            }
            sleep(1)
        }

        // Screenshot 1: Input form (empty state with trial counter visible)
        snapshot("01_input_form")

        // Fill in demo data for a realistic screenshot
        let textFields = app.textFields.allElementsBoundByIndex

        // Load rate
        if textFields.count > 0 {
            textFields[0].tap()
            textFields[0].typeText("2850")
        }

        // Current location
        if textFields.count > 1 {
            textFields[1].tap()
            textFields[1].typeText("Dallas, TX")
            sleep(1)
            // Dismiss suggestions
            app.tap()
        }

        snapshot("02_load_entry")

        // Scroll down and fill more fields
        app.swipeUp()

        // Find delivery address field and fill it
        let deliveryFields = app.textFields.matching(NSPredicate(format: "placeholderValue CONTAINS 'Delivery' OR placeholderValue CONTAINS 'address'"))
        if deliveryFields.count > 0 {
            deliveryFields.element(boundBy: 0).tap()
            deliveryFields.element(boundBy: 0).typeText("Houston, TX")
            sleep(1)
            app.tap()
        }

        snapshot("03_delivery_entered")

        // Scroll to calculate button
        app.swipeUp()
        app.swipeUp()

        snapshot("04_calculate_button")

        // Open settings
        let settingsButton = app.buttons["gear"]
        if settingsButton.waitForExistence(timeout: 2) {
            settingsButton.tap()
            sleep(1)
            snapshot("05_settings")

            // Close settings
            let doneButton = app.buttons["Done"]
            if doneButton.exists {
                doneButton.tap()
            }
        }
    }
}
