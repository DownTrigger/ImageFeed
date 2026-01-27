import Foundation
import Logging

final class ImagesListService {

    // MARK: Logger
    private let logger = Logger(label: "ImagesListService")

    // MARK: Singleton
    static let shared = ImagesListService()
    private init() {}

    // MARK: Dependencies
    private let urlSession = URLSession.shared
    private let tokenStorage = OAuth2TokenStorage.shared

    // MARK: Public State
    private(set) var photos: [Photo] = []
    private(set) var likedPhotos: [Photo] = []

    // MARK: Notifications
    static let didChangeNotification = Notification.Name("ImagesListServiceDidChange")

    // MARK: Private State
    private var lastLoadedPage: Int?
    private var isLoading = false
    private var likedPhotoIDs: Set<String> {
        Set(likedPhotos.map { $0.id })
    }
    private var photoTask: URLSessionTask?
    private var likeTask: URLSessionTask?

    // MARK: Public API
    func fetchPhotosNextPage() {
        assert(Thread.isMainThread)

        guard !isLoading else { return }
        isLoading = true

        photoTask?.cancel()
        photoTask = nil

        let nextPage = (lastLoadedPage ?? 0) + 1

        guard let request = makePhotosRequest(page: nextPage) else {
            logger.error("fetchPhotosNextPage: invalidRequest page=\(nextPage)")
            isLoading = false
            return
        }

        let task = urlSession.objectTask(for: request) { [weak self] (result: Result<[PhotoResult], Error>) in
            guard let self else { return }

            self.isLoading = false

            switch result {
            case .success(let photoResults):
                let newPhotos = photoResults.map { result in
                    Photo(
                        id: result.id,
                        size: CGSize(width: result.width, height: result.height),
                        createdAt: result.createdAt,
                        description: result.description,
                        regularImageURL: result.urls.regular,
                        largeImageURL: result.urls.full,
                        isLiked: self.likedPhotoIDs.contains(result.id) || result.likedByUser
                    )
                }

                self.photos.append(contentsOf: newPhotos)
                self.lastLoadedPage = nextPage

                NotificationCenter.default.post(
                    name: Self.didChangeNotification,
                    object: self
                )

            case .failure(let error):
                if let decodingError = error as? DecodingError {
                    self.logger.error("fetchPhotosNextPage: decodingError page=\(nextPage) error=\(decodingError)")
                }
                self.logger.error("fetchPhotosNextPage: networkError page=\(nextPage) error=\(error)")
            }
        }

        photoTask = task
        task.resume()
    }

    func fetchLikedPhotos(
        username: String,
        completion: @escaping (Result<[Photo], Error>) -> Void
    ) {
        guard let token = tokenStorage.token else {
            let error = NSError(domain: "AuthError", code: 401)
            logger.error("fetchLikedPhotos: authError username=\(username)")
            completion(.failure(error))
            return
        }

        guard let url = URL(string: "https://api.unsplash.com/users/\(username)/likes") else {
            let error = NSError(domain: "InvalidURL", code: 0)
            completion(.failure(error))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = HTTPMethod.get.rawValue
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let task = urlSession.objectTask(for: request) { [weak self] (result: Result<[PhotoResult], Error>) in
            guard let self else { return }

                switch result {
                case .success(let photoResults):
                    let photos = photoResults.compactMap { result -> Photo? in
                        Photo(
                            id: result.id,
                            size: CGSize(width: result.width, height: result.height),
                            createdAt: result.createdAt,
                            description: result.description,
                            regularImageURL: result.urls.regular,
                            largeImageURL: result.urls.full,
                            isLiked: true
                        )
                    }

                    self.likedPhotos = photos
                    
                    self.photos = self.photos.map { photo in
                        photo.withLiked(self.likedPhotoIDs.contains(photo.id))
                    }

                    NotificationCenter.default.post(
                        name: Self.didChangeNotification,
                        object: self
                    )
                    
                    completion(.success(photos))

                case .failure(let error):
                    if let decodingError = error as? DecodingError {
                        self.logger.error("fetchLikedPhotos: decodingError username=\(username) error=\(decodingError)")
                    }
                    self.logger.error("fetchLikedPhotos: networkError username=\(username) error=\(error)")
                    completion(.failure(error))
                }
        }

        task.resume()
    }
    
    func changeLike(
        photoId: String,
        shouldLike: Bool,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        assert(Thread.isMainThread)

        likeTask?.cancel()
        likeTask = nil

        guard let token = tokenStorage.token else {
            let error = NSError(domain: "AuthError", code: 401)
            logger.error("changeLike: authError photoId=\(photoId)")
            completion(.failure(error))
            return
        }

        guard let request = makeLikeRequest(photoId: photoId, shouldLike: shouldLike, token: token) else {
            let error = NSError(domain: "InvalidRequest", code: 0)
            logger.error("changeLike: invalidRequest photoId=\(photoId)")
            completion(.failure(error))
            return
        }

        let task = urlSession.objectTask(for: request) { [weak self] (result: Result<EmptyResponse, Error>) in
            guard let self else { return }

            switch result {
            case .success:
                if let index = self.photos.firstIndex(where: { $0.id == photoId }) {
                    let photo = self.photos[index]

                    let newPhoto = Photo(
                        id: photo.id,
                        size: photo.size,
                        createdAt: photo.createdAt,
                        description: photo.description,
                        regularImageURL: photo.regularImageURL,
                        largeImageURL: photo.largeImageURL,
                        isLiked: shouldLike
                    )

                    self.photos[index] = newPhoto

                    if shouldLike {
                        if let existing = self.likedPhotos.firstIndex(where: { $0.id == photoId }) {
                            self.likedPhotos[existing] = self.likedPhotos[existing].withLiked(true)
                        } else if let photoInFeed = self.photos.first(where: { $0.id == photoId }) {
                            let liked = photoInFeed.withLiked(true)
                            self.likedPhotos.insert(liked, at: 0)
                        }
                    } else {
                        self.likedPhotos.removeAll { $0.id == photoId }
                    }
                }

                NotificationCenter.default.post(
                    name: Self.didChangeNotification,
                    object: self
                )

                completion(.success(()))

            case .failure(let error):
                if let decodingError = error as? DecodingError {
                    self.logger.error("changeLike: decodingError photoId=\(photoId) error=\(decodingError)")
                }
                self.logger.error("changeLike: networkError photoId=\(photoId) error=\(error)")
                completion(.failure(error))
            }

            self.likeTask = nil
        }

        likeTask = task
        task.resume()
    }

    // MARK: Requests
    private func makePhotosRequest(page: Int) -> URLRequest? {
        guard var components = URLComponents(string: "https://api.unsplash.com/photos") else {
            return nil
        }

        components.queryItems = [
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "per_page", value: "10")
        ]

        guard let url = components.url else { return nil }

        var request = URLRequest(url: url)
        request.httpMethod = HTTPMethod.get.rawValue
        request.setValue("Client-ID \(APIConstants.accessKey)", forHTTPHeaderField: "Authorization")
        return request
    }

    private func makeLikeRequest(
        photoId: String,
        shouldLike: Bool,
        token: String
    ) -> URLRequest? {
        guard let url = URL(string: "https://api.unsplash.com/photos/\(photoId)/like") else {
            return nil
        }

        var request = URLRequest(url: url)
        request.httpMethod = shouldLike ? HTTPMethod.post.rawValue : HTTPMethod.delete.rawValue
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        return request
    }
}

// MARK: - Extensions
// MARK: Cleanup
extension ImagesListService {
    func cleanImagesList() {
        photos.removeAll()
        lastLoadedPage = nil
        isLoading = false

        photoTask?.cancel()
        photoTask = nil

        likeTask?.cancel()
        likeTask = nil
    }
}

// MARK: - Helpers
private struct EmptyResponse: Decodable {}
