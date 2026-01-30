import XCTest

final class ImageFeedUITests: XCTestCase {

    private let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launchArguments = ["UITEST"]
        app.launch()
    }
    
    let login = "логин"
    let password = "пароль"

    func testAuth() throws {
        app.buttons["Authenticate"].tap()

        let webView = app.webViews["UnsplashWebView"]
        XCTAssertTrue(webView.waitForExistence(timeout: 5))

        let loginTextField = webView.descendants(matching: .textField).element
        XCTAssertTrue(loginTextField.waitForExistence(timeout: 5))

        loginTextField.tap()
        loginTextField.typeText(login)

        let passwordTextField = webView.descendants(matching: .secureTextField).element
        XCTAssertTrue(passwordTextField.waitForExistence(timeout: 5))

        passwordTextField.tap()
        Thread.sleep(forTimeInterval: 2)
        passwordTextField.typeText(password)

        Thread.sleep(forTimeInterval: 2)
        webView.buttons["Login"].tap()

        let tablesQuery = app.tables
        let cell = tablesQuery.children(matching: .cell).element(boundBy: 0)
        XCTAssertTrue(cell.waitForExistence(timeout: 5))
    }

    func testFeed() throws {
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 15))
        tabBar.buttons.element(boundBy: 0).tap()

        let table = app.tables["ImagesListTable"]
        XCTAssertTrue(table.waitForExistence(timeout: 15))

        let firstCell = table.cells["photoCell"].firstMatch
        XCTAssertTrue(firstCell.waitForExistence(timeout: 15))

        table.swipeUp()
        
        let likeButton = firstCell.buttons["likeButton"]
        XCTAssertTrue(likeButton.waitForExistence(timeout: 5))
        likeButton.tap()
        Thread.sleep(forTimeInterval: 2)

        likeButton.tap()
        Thread.sleep(forTimeInterval: 2)

        firstCell.tap()

        let backButton = app.buttons["backButton"]
        XCTAssertTrue(backButton.waitForExistence(timeout: 5))

        let image = app.scrollViews.images.element(boundBy: 0)
        XCTAssertTrue(image.waitForExistence(timeout: 5))
        image.pinch(withScale: 3, velocity: 1)
        image.pinch(withScale: 0.5, velocity: -1)
        
        backButton.tap()
    }

    func testProfile() throws {
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 10))

        XCTAssertTrue(app.tables["ImagesListTable"].waitForExistence(timeout: 10))

        let profileTab = tabBar.buttons.element(boundBy: 1)
        profileTab.tap()

        let logoutButton = app.buttons["logoutButton"]
        XCTAssertTrue(logoutButton.waitForExistence(timeout: 5))

        let usernamePredicate = NSPredicate(format: "label CONTAINS[c] '@'")
        XCTAssertTrue(app.staticTexts.matching(usernamePredicate).firstMatch.waitForExistence(timeout: 3))
        let namePredicate = NSPredicate(format: "label != '' AND NOT label CONTAINS[c] '@'")
        XCTAssertTrue(app.staticTexts.matching(namePredicate).firstMatch.exists)

        logoutButton.tap()

        let logoutAlert = app.alerts["Выход из аккаунта"]
        XCTAssertTrue(logoutAlert.waitForExistence(timeout: 3))
        logoutAlert.buttons["Выйти"].tap()

        let authButton = app.buttons["Authenticate"]
        XCTAssertTrue(authButton.waitForExistence(timeout: 5))
    }
}
