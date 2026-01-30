@testable import ImageFeed
import Foundation

@MainActor
final class ImagesListViewControllerSpy: ImagesListViewProtocol {
    var presenter: ImagesListPresenterProtocol?

    var renderCalled = false
    var renderedState: ImagesListState?

    var insertRowsCalled = false
    var insertRowsIndexPaths: [IndexPath]?

    var reloadVisibleRowsCalled = false

    func render(state: ImagesListState) {
        renderCalled = true
        renderedState = state
    }

    func insertRows(at indexPaths: [IndexPath]) {
        insertRowsCalled = true
        insertRowsIndexPaths = indexPaths
    }

    func reloadVisibleRows() {
        reloadVisibleRowsCalled = true
    }
}
