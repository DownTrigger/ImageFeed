@testable import ImageFeed
import Foundation
internal import CoreGraphics

@MainActor
final class ProfilePresenterSpy: ProfilePresenterProtocol {
    var view: ProfileViewProtocol?

    var likedPhotosCount: Int { 0 }

    var viewDidLoadCalled = false

    func viewDidLoad() {
        viewDidLoadCalled = true
    }

    func likedPhoto(at index: Int) -> Photo {
        Photo(
            id: "",
            size: .zero,
            createdAt: nil,
            description: nil,
            regularImageURL: "",
            largeImageURL: "",
            isLiked: false
        )
    }

    func likedPhotoId(at index: Int) -> String {
        ""
    }

    func didTapUnlike(photoId: String, completion: @escaping (Result<Void, Error>) -> Void) {}

    func didConfirmLogout() {}
}
