import Foundation
import Logging

final class ProfileService {
    
    // MARK: - Singleton
    static let shared = ProfileService()
    private init() {}
    
    // MARK: - Notifications
    static let profileDidChange = Notification.Name("profileDidChange")
    
    // MARK: - Dependencies
    private let urlSession = URLSession.shared
    
    // MARK: - State
    private var task: URLSessionTask?
    private(set) var profile: Profile?
    
    // MARK: - Logger
    private let logger = Logger(label: "ProfileService")
    
    // MARK: - Public API
    func fetchProfile(_ token: String, completion: @escaping (Result<Profile, Error>) -> Void) {
        // Cancel previous in-flight request
        task?.cancel()
        
        // Build profile request
        guard let request = makeProfileRequest(token: token) else {
//            self.logger.error("[ProfileService.fetchProfile]: NetworkError – badURL (failed to build request)")
            print("[ProfileService.fetchProfile]: NetworkError – badURL (failed to build request)")
            completion(.failure(URLError(.badURL)))
            return
        }

        let task = urlSession.objectTask(
            for: request
        ) { [weak self] (result: Result<ProfileResult, Error>) in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                defer { self.task = nil }
                // Handle network result
                switch result {
                case .success(let profileResult):
                    let profile = Profile(
                        username: profileResult.username,
                        name: "\(profileResult.firstName) \(profileResult.lastName)",
                        loginName: "@\(profileResult.username)",
                        bio: profileResult.bio
                    )
                    
                    self.profile = profile
                    NotificationCenter.default.post(
                        name: ProfileService.profileDidChange,
                        object: self
                    )
                    completion(.success(profile))
                    
                case .failure(let error):
                    //                self.logger.error("[ProfileService.fetchProfile]: NetworkError – \(error)")
                    print("[ProfileService.fetchProfile]: NetworkError – \(error)")
                    completion(.failure(error))
                }
            }
        }

        self.task = task
        task.resume()
    }
    
    // MARK: - Private Helpers
    private func makeProfileRequest(token: String) -> URLRequest? {
        guard let url = URL(string: "https://api.unsplash.com/me") else {
//            self.logger.error("[ProfileService.makeProfileRequest]: NetworkError – invalidURL")
            print("[ProfileService.makeProfileRequest]: NetworkError – invalidURL")
            return nil
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        return request
    }
}

