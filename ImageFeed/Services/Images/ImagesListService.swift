import Foundation

final class ImagesListService {

    // MARK: - Singleton
    static let shared = ImagesListService()
    private init() {}

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
                        createdAt: nil,
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
