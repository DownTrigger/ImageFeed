import Foundation

protocol ImagesListPresenterProtocol: AnyObject {
    func viewDidLoad()
    func willDisplayRow(at index: Int, totalCount: Int)
    func didTapLike(photoId: String, completion: @escaping (Result<Void, Error>) -> Void)
}

