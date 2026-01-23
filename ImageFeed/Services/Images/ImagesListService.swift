import Foundation

final class ImagesListService {

    // MARK: - Singleton
    static let shared = ImagesListService()
    private init() {}

    private let tokenStorage = OAuth2TokenStorage.shared
    
    // MARK: - Public State
    private(set) var photos: [Photo] = []

    // MARK: - Notifications
    static let didChangeNotification = Notification.Name("ImagesListServiceDidChange")

    // MARK: - Private State
    private var lastLoadedPage: Int?
    private var isLoading = false
    private let urlSession = URLSession.shared

    // MARK: - Public API
    func fetchPhotosNextPage() {
        assert(Thread.isMainThread)

        guard !isLoading else { return }
        isLoading = true

        let nextPage = (lastLoadedPage ?? 0) + 1

        guard let request = makePhotosRequest(page: nextPage) else {
            print("[ImagesListService.fetchPhotosNextPage]: invalid request")
            isLoading = false
            return
        }

        let task = urlSession.objectTask(for: request) { [weak self] (result: Result<[PhotoResult], Error>) in
            guard let self else { return }
            defer { self.isLoading = false }

            switch result {
            case .success(let photoResults):
                let newPhotos = photoResults.map {
                    Photo(
                        id: $0.id,
                        size: CGSize(width: $0.width, height: $0.height),
                        createdAt: $0.createdAt,
                        description: $0.description,
                        regularImageURL: $0.urls.regular,
                        largeImageURL: $0.urls.full,
                        isLiked: $0.likedByUser
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

        task.resume()
    }
    
    
    func changeLike(photoId: String, isLike: Bool, completion: @escaping (Result<Void, Error>) -> Void) {
        
        guard let token = tokenStorage.token else {
                print("[ImagesListService.changeLike]: no auth token")
                completion(.failure(NSError(domain: "NoToken", code: 401)))
                return
            }
        
        guard let url = URL(string: "https://api.unsplash.com/photos/\(photoId)/like") else {
            print("[ImagesListService.changeLike]: invalid URL")
            completion(.failure(NSError(domain: "InvalidURL", code: 0, userInfo: nil)))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = isLike ? HTTPMethod.post.rawValue : HTTPMethod.delete.rawValue
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let task = urlSession.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("[ImagesListService.changeLike]: \(error)")
                    completion(.failure(error))
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    let error = NSError(domain: "NoHTTPResponse", code: 0, userInfo: nil)
                    print("[ImagesListService.changeLike]: no HTTP response")
                    completion(.failure(error))
                    return
                }
                
                if (200...299).contains(httpResponse.statusCode) {
                    completion(.success(()))
                } else {
                    let error = NSError(domain: "HTTPError", code: httpResponse.statusCode, userInfo: nil)
                    print("[ImagesListService.changeLike]: HTTP error code \(httpResponse.statusCode)")
                    completion(.failure(error))
                }
            }
        }
        
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
}
