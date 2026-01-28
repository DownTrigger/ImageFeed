import Foundation

protocol ProfileViewProtocol: AnyObject {
    func render(state: ProfileState)

    func applyFavoritesUpdates(deleted: [IndexPath], inserted: [IndexPath])
    func reloadFavorites()

    func resetToSplash()
}

