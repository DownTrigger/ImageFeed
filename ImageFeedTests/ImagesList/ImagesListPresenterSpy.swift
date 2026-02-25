@testable import ImageFeed
import Foundation

@MainActor
final class ImagesListPresenterSpy: ImagesListPresenterProtocol {
    var view: ImagesListViewProtocol?

    var viewDidLoadCalled = false
    var willDisplayRowCalled = false
    var willDisplayRowIndex: Int?
    var willDisplayRowTotalCount: Int?
    var didTapLikeCalled = false
    var didTapLikePhotoId: String?

    func viewDidLoad() {
        viewDidLoadCalled = true
    }

    func willDisplayRow(at index: Int, totalCount: Int) {
        willDisplayRowCalled = true
        willDisplayRowIndex = index
        willDisplayRowTotalCount = totalCount
    }

    func didTapLike(photoId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        didTapLikeCalled = true
        didTapLikePhotoId = photoId
        completion(.success(()))
    }
}
