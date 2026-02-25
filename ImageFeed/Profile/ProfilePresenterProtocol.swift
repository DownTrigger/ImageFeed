import Foundation

protocol ProfilePresenterProtocol: AnyObject {
    var likedPhotosCount: Int { get }

    func viewDidLoad()

    func likedPhoto(at index: Int) -> Photo
    func likedPhotoId(at index: Int) -> String

    func didTapUnlike(photoId: String, completion: @escaping (Result<Void, Error>) -> Void)
    func didConfirmLogout()
}

