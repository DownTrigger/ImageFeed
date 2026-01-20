import Foundation
import Logging

struct ProfileImage: Codable {
    let small: String
    let medium: String
    let large: String

    private enum CodingKeys: String, CodingKey {
        case small
        case medium
        case large
    }
}

struct UserResult: Codable {
    let profileImage: ProfileImage

    private enum CodingKeys: String, CodingKey {
        case profileImage = "profile_image"
    }
}

final class ProfileImageService {
    
    private let logger = Logger(label: "ProfileImageService")
    
    static let didChangeNotification = Notification.Name(rawValue: "ProfileImageProviderDidChange")
    static let shared = ProfileImageService()
    private init() {}
    private(set) var avatarURL: String?
    
    private var task: URLSessionTask?
    
    func fetchProfileImageURL(username: String, completion: @escaping (Result<String, Error>) -> Void) {
        task?.cancel()

        guard let token = OAuth2TokenStorage.shared.token else {
//            self.logger.error("[ProfileImageService.fetchProfileImageURL]: AuthError – token missing")
            print("[ProfileImageService.fetchProfileImageURL]: AuthError – token missing")
            completion(.failure(NSError(domain: "ProfileImageService", code: 401, userInfo: [NSLocalizedDescriptionKey: "Authorization token missing"])))
            return
        }

        guard let request = makeProfileImageRequest(username: username, token: token) else {
//            self.logger.error("[ProfileImageService.fetchProfileImageURL]: NetworkError – badURL, username=\(username)")
            print("[ProfileImageService.fetchProfileImageURL]: NetworkError – badURL, username=\(username)")
            completion(.failure(URLError(.badURL)))
            return
        }

        let task = URLSession.shared.objectTask(
            for: request
        ) { [weak self] (result: Result<UserResult, Error>) in
            guard let self else { return }

            switch result {
            case .success(let userResult):
                let url = userResult.profileImage.large
                
                DispatchQueue.main.async {
                    self.avatarURL = url
                    completion(.success(url))
                    NotificationCenter.default.post(
                        name: ProfileImageService.didChangeNotification,
                        object: self,
                        userInfo: ["URL": url]
                    )
                }
                
            case .failure(let error):
//                self.logger.error("[ProfileImageService.fetchProfileImageURL]: NetworkError – \(error), username=\(username)")
                print("[ProfileImageService.fetchProfileImageURL]: NetworkError – \(error), username=\(username)")
                completion(.failure(error))
            }

            self.task = nil
        }

        self.task = task
        task.resume()
    }
    
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
