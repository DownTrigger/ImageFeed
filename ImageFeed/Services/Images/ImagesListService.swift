import Foundation

final class ImagesListService {

    // MARK: - Singleton
    static let shared = ImagesListService()
    private init() {}

    // MARK: - Dependencies
    private let urlSession = URLSession.shared
    private let tokenStorage = OAuth2TokenStorage.shared

    // MARK: - Public State
    private(set) var photos: [Photo] = []
    private(set) var likedPhotos: [Photo] = []

    // MARK: - Notifications
    static let didChangeNotification = Notification.Name("ImagesListServiceDidChange")

    // MARK: - Private State
    private var lastLoadedPage: Int?
    private var isLoading = false
    private var likedPhotoIDs: Set<String> {
        Set(likedPhotos.map { $0.id })
    }
    private var photoTask: URLSessionTask?
    private var likeTask: URLSessionTask?

    // MARK: - Public API

    /// Загружает следующую страницу фотографий
    func fetchPhotosNextPage() {
        assert(Thread.isMainThread)

        guard !isLoading else { return }
        isLoading = true

        // Отменяем предыдущий запрос, если он ещё идёт
        photoTask?.cancel()
        photoTask = nil

        let nextPage = (lastLoadedPage ?? 0) + 1

        guard let request = makePhotosRequest(page: nextPage) else {
            print("[ImagesListService.fetchPhotosNextPage]: invalid request")
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
                print("[ImagesListService.fetchPhotosNextPage]: \(error)")
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
            print("[ImagesListService.fetchLikedPhotos]: no auth token")
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

            DispatchQueue.main.async {
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
                        var updated = photo
                        updated.isLiked = self.likedPhotoIDs.contains(photo.id)
                        return updated
                    }

                    NotificationCenter.default.post(
                        name: Self.didChangeNotification,
                        object: self
                    )
                    
                    completion(.success(photos))

                case .failure(let error):
                    print("[ImagesListService.fetchLikedPhotos]: \(error)")
                    completion(.failure(error))
                }
            }
        }

        task.resume()
    }

    /// Ставит или убирает лайк у фотографии
    func changeLike(
        photoId: String,
        shouldLike: Bool,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        assert(Thread.isMainThread)

        // Отменяем предыдущий лайк-запрос
        likeTask?.cancel()
        likeTask = nil

        guard let token = tokenStorage.token else {
            let error = NSError(domain: "AuthError", code: 401)
            print("[ImagesListService.changeLike]: no auth token")
            completion(.failure(error))
            return
        }

        guard let request = makeLikeRequest(photoId: photoId, shouldLike: shouldLike, token: token) else {
            let error = NSError(domain: "InvalidRequest", code: 0)
            print("[ImagesListService.changeLike]: invalid request")
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
                            self.likedPhotos[existing].isLiked = true
                        } else if let photoInFeed = self.photos.first(where: { $0.id == photoId }) {
                            var liked = photoInFeed
                            liked.isLiked = true
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
                print("[ImagesListService.changeLike]: \(error)")
                completion(.failure(error))
            }

            self.likeTask = nil
        }

        likeTask = task
        task.resume()
    }

    // MARK: - Requests

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
        request.setValue("Client-ID \(Constants.accessKey)", forHTTPHeaderField: "Authorization")
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

// MARK: - Cleanup

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
