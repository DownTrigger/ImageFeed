import Foundation
import Logging

final class ProfileImageService {
    
    // MARK: - Logger
    private let logger = Logger(label: "ProfileImageService")
    
    // MARK: - Singleton
    static let shared = ProfileImageService()
    private init() {}
    
    // MARK: - Dependencies
    private let urlSession = URLSession.shared
    private let tokenStorage = OAuth2TokenStorage.shared
    
    // MARK: - Public State
    private(set) var avatarURL: String?
    
    // MARK: - Notifications
    static let didChangeNotification = Notification.Name("ProfileImageProviderDidChange")
    
    // MARK: - Private State
    private var task: URLSessionTask?
    
    // MARK: - Public API
    func fetchProfileImageURL(username: String, completion: @escaping (Result<String, Error>) -> Void) {

        task?.cancel()
        
        guard let token = tokenStorage.token else {
            logger.error("[fetchProfileImageURL]: AuthError Authorization token missing")
            DispatchQueue.main.async {
                completion(.failure(NSError(domain: "ProfileImageService", code: 401, userInfo: [NSLocalizedDescriptionKey: "Authorization token missing"])))
            }
            return
        }
        
        guard let request = makeProfileImageRequest(username: username, token: token) else {
            logger.error("[fetchProfileImageURL]: NetworkError badURL, username=\(username)")
            DispatchQueue.main.async {
                completion(.failure(URLError(.badURL)))
            }
            return
        }
        
        let task = urlSession.objectTask(
            for: request
        ) { [weak self] (result: Result<UserResult, Error>) in
            guard let self else { return }
            
            DispatchQueue.main.async {
                defer { self.task = nil }
                
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
                    self.logger.error("[fetchProfileImageURL]: NetworkError \(error), username=\(username)")
                    completion(.failure(error))
                }
            }
        }
        self.task = task
        task.resume()
    }
    
    // MARK: - Requests
    private func makeProfileImageRequest(username: String, token: String) -> URLRequest? {
        guard let url = URL(string: "https://api.unsplash.com/users/\(username)") else {
            logger.error("[makeProfileImageRequest]: NetworkError invalidURL, username=\(username)")
            return nil
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = HTTPMethod.get.rawValue
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        return request
    }
}
