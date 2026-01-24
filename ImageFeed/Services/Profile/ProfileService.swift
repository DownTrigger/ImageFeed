import Foundation
import Logging

final class ProfileService {
    
    // MARK: - Logger
    private let logger = Logger(label: "ProfileService")
    
    // MARK: - Singleton
    static let shared = ProfileService()
    private init() {}
    
    // MARK: - Dependencies
    private let urlSession = URLSession.shared
    
    // MARK: - Public State
    private(set) var profile: Profile?
    
    // MARK: - Notifications
    static let profileDidChange = Notification.Name("profileDidChange")
    
    // MARK: - Private State
    private var task: URLSessionTask?
    
    // MARK: - Public API
    func fetchProfile(_ token: String, completion: @escaping (Result<Profile, Error>) -> Void) {

        task?.cancel()
        
        guard let request = makeProfileRequest(token: token) else {
            logger.error("[fetchProfile]: NetworkError badURL (failed to build request)")
            DispatchQueue.main.async {
                completion(.failure(URLError(.badURL)))
            }
            return
        }
        
        let task = urlSession.objectTask(
            for: request
        ) { [weak self] (result: Result<ProfileResult, Error>) in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                defer { self.task = nil }

                switch result {
                case .success(let profileResult):
                    let profile = Profile(
                        username: profileResult.username,
                        loginName: "@\(profileResult.username)",
                        name: "\(profileResult.firstName) \(profileResult.lastName)",
                        bio: profileResult.bio
                    )
                    
                    self.profile = profile
                    NotificationCenter.default.post(
                        name: ProfileService.profileDidChange,
                        object: self
                    )
                    completion(.success(profile))
                    
                case .failure(let error):
                    self.logger.error("[fetchProfile]: NetworkError \(error.localizedDescription)")
                    completion(.failure(error))
                }
            }
        }
        
        self.task = task
        task.resume()
    }
    
    // MARK: - Requests
    private func makeProfileRequest(token: String) -> URLRequest? {
        guard let url = URL(string: "https://api.unsplash.com/me") else {
            logger.error("[makeProfileRequest]: NetworkError invalidURL")
            return nil
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        return request
    }
}
