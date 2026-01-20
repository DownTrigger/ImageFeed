import Foundation
import Logging

struct Profile {
    let username: String
    let name: String
    let loginName: String
    let bio: String?
}

struct ProfileResult: Codable {
    let username: String
    let firstName: String
    let lastName: String
    let bio: String?
    
    enum CodingKeys: String, CodingKey {
        case username
        case firstName = "first_name"
        case lastName = "last_name"
        case bio
    }
}

final class ProfileService {
    
    private let logger = Logger(label: "ProfileService")
    
    static let profileDidChange = Notification.Name("profileDidChange")
    static let shared = ProfileService()
    private init() {}
    private(set) var profile: Profile?
    
    private let urlSession = URLSession.shared
    private var task: URLSessionTask?
    
    func fetchProfile(_ token: String, completion: @escaping (Result<Profile, Error>) -> Void) {
        task?.cancel()
        
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
            
            self.task = nil
        }

        self.task = task
        task.resume()
    }
    
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

