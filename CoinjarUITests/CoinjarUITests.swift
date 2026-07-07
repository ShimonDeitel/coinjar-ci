import XCTest

final class CoinjarUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    func testAddFirstKid() {
        let addFirstKidButton = app.buttons["addFirstKidButton"]
        XCTAssertTrue(addFirstKidButton.waitForExistence(timeout: 15))
        addFirstKidButton.tap()
        let nameField = app.textFields["kidNameField"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 5))
        nameField.tap()
        nameField.typeText("Sam")
        app.buttons["saveKidButton"].tap()
        XCTAssertTrue(app.navigationBars["Coinjar"].waitForExistence(timeout: 5))
    }

    func testAddEntryViaMenu() {
        addSeedKid()
        let addMenu = app.buttons["addMenuButton"]
        XCTAssertTrue(addMenu.waitForExistence(timeout: 5))
        addMenu.tap()
        app.buttons["Add Entry"].tap()
        let saveButton = app.buttons["saveEntryButton"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 5))
        saveButton.tap()
        XCTAssertTrue(app.navigationBars["Coinjar"].waitForExistence(timeout: 5))
    }

    func testEditEntryViaMenu() {
        addSeedKid()
        addSeedEntry()
        let menu = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'entryMenu_'")).firstMatch
        XCTAssertTrue(menu.waitForExistence(timeout: 5))
        menu.tap()
        app.buttons["Edit"].tap()
        let saveButton = app.buttons["saveEntryButton"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 5))
        saveButton.tap()
    }

    func testDeleteEntryViaMenu() {
        addSeedKid()
        addSeedEntry()
        let menu = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'entryMenu_'")).firstMatch
        XCTAssertTrue(menu.waitForExistence(timeout: 5))
        menu.tap()
        app.buttons["Delete"].tap()
        let deleteButtons = app.buttons.matching(identifier: "Delete")
        let confirmDelete = deleteButtons.element(boundBy: max(0, deleteButtons.count - 1))
        if confirmDelete.waitForExistence(timeout: 3) {
            confirmDelete.tap()
        }
    }

    func testSettingsTabOpensAndTogglesConfirm() {
        app.tabBars.buttons["Settings"].tap()
        let toggle = app.switches["confirmWithdrawalsToggle"]
        XCTAssertTrue(toggle.waitForExistence(timeout: 5))
        toggle.tap()
    }

    func testSecondKidTriggersPaywall() {
        addSeedKid()
        let addMenu = app.buttons["addMenuButton"]
        XCTAssertTrue(addMenu.waitForExistence(timeout: 5))
        addMenu.tap()
        app.buttons["Add Kid"].tap()
        let closeButton = app.buttons["Close"]
        XCTAssertTrue(closeButton.waitForExistence(timeout: 5))
    }

    func testJarViewAppearsAfterSeedKid() {
        addSeedKid()
        XCTAssertTrue(app.otherElements["fillableJarView"].waitForExistence(timeout: 5))
    }

    private func addSeedKid() {
        let addFirstKidButton = app.buttons["addFirstKidButton"]
        if addFirstKidButton.waitForExistence(timeout: 5) {
            addFirstKidButton.tap()
            let nameField = app.textFields["kidNameField"]
            nameField.tap()
            nameField.typeText("Sam")
            app.buttons["saveKidButton"].tap()
        }
    }

    private func addSeedEntry() {
        let addMenu = app.buttons["addMenuButton"]
        if addMenu.waitForExistence(timeout: 5) {
            addMenu.tap()
            app.buttons["Add Entry"].tap()
            app.buttons["saveEntryButton"].tap()
        }
    }
}
