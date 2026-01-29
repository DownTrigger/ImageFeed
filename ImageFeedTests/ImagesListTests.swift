@testable import ImageFeed
import XCTest

final class ImagesListTests: XCTestCase {

    // MARK: - ViewController → Presenter

    @MainActor
    func testViewControllerCallsPresenterViewDidLoad() {
        // given
        let presenter = ImagesListPresenterSpy()
        let viewController = ImagesListViewController()
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
        let viewController = ImagesListViewControllerSpy()
        let presenter = ImagesListPresenter(
            view: viewController,
            imagesListService: ImagesListService.shared
        )
        viewController.presenter = presenter
        presenter.view = viewController

        // when
        presenter.viewDidLoad()

        // then
        XCTAssertTrue(viewController.renderCalled)
        XCTAssertNotNil(viewController.renderedState)
    }

    @MainActor
    func testPresenterCallsWillDisplayRow() {
        // given
        let viewController = ImagesListViewControllerSpy()
        let presenter = ImagesListPresenterSpy()
        viewController.presenter = presenter
        presenter.view = viewController

        // when
        presenter.willDisplayRow(at: 5, totalCount: 10)

        // then
        XCTAssertTrue(presenter.willDisplayRowCalled)
        XCTAssertEqual(presenter.willDisplayRowIndex, 5)
        XCTAssertEqual(presenter.willDisplayRowTotalCount, 10)
    }

    @MainActor
    func testPresenterCallsDidTapLike() {
        // given
        let viewController = ImagesListViewControllerSpy()
        let presenter = ImagesListPresenterSpy()
        viewController.presenter = presenter
        presenter.view = viewController
        let photoId = "test-photo-id"

        // when
        let expectation = expectation(description: "didTapLike completion")
        presenter.didTapLike(photoId: photoId) { _ in
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1)

        // then
        XCTAssertTrue(presenter.didTapLikeCalled)
        XCTAssertEqual(presenter.didTapLikePhotoId, photoId)
    }

    // MARK: - ImagesListState

    func testImagesListStateEmpty() {
        // when
        let state = ImagesListState.empty

        // then
        XCTAssertTrue(state.photos.isEmpty)
    }
}
