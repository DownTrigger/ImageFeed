@testable import ImageFeed
import XCTest

final class ProfileTests: XCTestCase {

    // MARK: - ViewController → Presenter

    @MainActor
    func testViewControllerCallsPresenterViewDidLoad() {
        // given
        let presenter = ProfilePresenterSpy()
        let viewController = ProfileViewController()
        viewController.presenter = presenter
        presenter.view = viewController

        // when
        _ = viewController.view

        // then
        XCTAssertTrue(presenter.viewDidLoadCalled)
    }

    // MARK: - Presenter → View

    @MainActor
    func testPresenterCallsViewRenderOnViewDidLoad() {
        // given
        let viewController = ProfileViewControllerSpy()
        let presenter = ProfilePresenter(
            view: viewController,
            profileService: ProfileService.shared,
            profileImageService: ProfileImageService.shared,
            imagesListService: ImagesListService.shared,
            tokenStorage: OAuth2TokenStorage.shared,
            dataCleaner: WebViewDataCleaner.shared
        )
        viewController.presenter = presenter
        presenter.view = viewController

        // when
        presenter.viewDidLoad()

        // then
        XCTAssertTrue(viewController.renderCalled)
        XCTAssertNotNil(viewController.renderedState)
    }

    // MARK: - ProfileState

    func testProfileStateEmpty() {
        // when
        let state = ProfileState.empty

        // then
        XCTAssertEqual(state.nameText, "")
        XCTAssertEqual(state.loginText, "")
        XCTAssertEqual(state.bioText, "")
        XCTAssertNil(state.avatarURL)
        XCTAssertEqual(state.favoritesCount, 0)
    }
}
