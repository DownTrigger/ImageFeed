@testable import ImageFeed
import Foundation

@MainActor
final class ProfileViewControllerSpy: ProfileViewProtocol {
    var presenter: ProfilePresenterProtocol?

    var renderCalled = false
    var renderedState: ProfileState?

    var applyFavoritesUpdatesCalled = false
    var applyFavoritesUpdatesDeleted: [IndexPath]?
    var applyFavoritesUpdatesInserted: [IndexPath]?

    var reloadFavoritesCalled = false
    var resetToSplashCalled = false

    func render(state: ProfileState) {
        renderCalled = true
        renderedState = state
    }

    func applyFavoritesUpdates(deleted: [IndexPath], inserted: [IndexPath]) {
        applyFavoritesUpdatesCalled = true
        applyFavoritesUpdatesDeleted = deleted
        applyFavoritesUpdatesInserted = inserted
    }

    func reloadFavorites() {
        reloadFavoritesCalled = true
    }

    func resetToSplash() {
        resetToSplashCalled = true
    }
}
