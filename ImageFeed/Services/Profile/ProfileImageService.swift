import Foundation
import Logging

final class ProfileImageService {
    
    // MARK: - Singleton
    static let shared = ProfileImageService()
    private init() {}
    
    // MARK: - Notifications
    static let didChangeNotification = Notification.Name(rawValue: "ProfileImageProviderDidChange")
    
    // MARK: - Dependencies
    private let urlSession = URLSession.shared
    private let tokenStorage = OAuth2TokenStorage.shared
    
    // MARK: - State
    private var task: URLSessionTask?
    private(set) var avatarURL: String?
    
    // MARK: - Logger
    private let logger = Logger(label: "ProfileImageService")
    
    // MARK: - Public API
    func fetchProfileImageURL(username: String, completion: @escaping (Result<String, Error>) -> Void) {
        // Cancel previous in-flight request
        task?.cancel()

        // Ensure auth token exists
        guard let token = tokenStorage.token else {
//            self.logger.error("[ProfileImageService.fetchProfileImageURL]: AuthError – token missing")
            print("[ProfileImageService.fetchProfileImageURL]: AuthError – token missing")
            completion(.failure(NSError(domain: "ProfileImageService", code: 401, userInfo: [NSLocalizedDescriptionKey: "Authorization token missing"])))
            return
        }

        // Build profile image request
        guard let request = makeProfileImageRequest(username: username, token: token) else {
//            self.logger.error("[ProfileImageService.fetchProfileImageURL]: NetworkError – badURL, username=\(username)")
            print("[ProfileImageService.fetchProfileImageURL]: NetworkError – badURL, username=\(username)")
            completion(.failure(URLError(.badURL)))
            return
        }

        let task = urlSession.objectTask(
            for: request
        ) { [weak self] (result: Result<UserResult, Error>) in
            guard let self else { return }

            DispatchQueue.main.async {
                defer { self.task = nil }
                
                // Handle network result
                switch result {
                case .success(let userResult):
                    let url = userResult.profileImage.large
                    self.avatarURL = url
                    completion(.success(url))
                    
                    NotificationCenter.default.post(
                        name: ProfileImageService.didChangeNotification,
                        object: self,
                        userInfo: ["URL": url]
                    )
                    
                case .failure(let error):
                    //                self.logger.error("[ProfileImageService.fetchProfileImageURL]: NetworkError – \(error), username=\(username)")
                    print("[ProfileImageService.fetchProfileImageURL]: NetworkError – \(error), username=\(username)")
                    completion(.failure(error))
                }
            }
        }
        self.task = task
        task.resume()
    }
    
    // MARK: - Private Helpers
    private func makeProfileImageRequest(username: String, token: String) -> URLRequest? {
        guard let url = URL(string: "https://api.unsplash.com/users/\(username)") else {
//            self.logger.error("[ProfileImageService.makeProfileImageRequest]: NetworkError – invalidURL, username=\(username)")
            print("[ProfileImageService.makeProfileImageRequest]: NetworkError – invalidURL, username=\(username)")
            return nil
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        return request
    }
    
}
