import Foundation
import Logging

final class OAuth2Service {
    
    private let urlSession = URLSession.shared
    private var task: URLSessionTask?
    private var lastCode: String?
    
    // MARK: Singleton
    static let shared = OAuth2Service()
    private init() { }
    
    // MARK: - Dependencies
    private let tokenStorage = OAuth2TokenStorage.shared
    
    // MARK: - Logger
    private let logger = Logger(label: "OAuth2Service")
    
    // MARK: Public API
    func fetchOAuthToken(_ code: String, completion: @escaping (Result<String, Error>) -> Void) {
        assert(Thread.isMainThread)
        
//         // Потестить алерт
//        DispatchQueue.main.async {
//                completion(.failure(NetworkError.invalidRequest))
//            }
//            return

        guard lastCode != code else {
            return
        }
        
        task?.cancel()
        
        lastCode = code
        let requestCode = code
        
        guard let request = makeOAuthTokenRequest(code: code) else {
//            self.logger.error("[OAuth2Service.fetchOAuthToken]: NetworkError.invalidRequest – failed to build request")
            print("[OAuth2Service.fetchOAuthToken]: NetworkError.invalidRequest – failed to build request")
            completion(.failure(NetworkError.invalidRequest))
            return
        }
        
        let task = urlSession.objectTask(for: request) { [weak self] (result: Result<OAuth2TokenResponseBody, Error>) in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                guard self.lastCode == requestCode else {
                    return
                }
                
                switch result {
                case .success(let decoded):
                    let token = decoded.accessToken
                    self.tokenStorage.token = token
                    completion(.success(token))
                    
                case .failure(let error):
                    //                self.logger.error("[OAuth2Service.fetchOAuthToken]: NetworkError – \(error)")
                    print("[OAuth2Service.fetchOAuthToken]: NetworkError – \(error)")
                    completion(.failure(error))
                }
                
                self.task = nil
                self.lastCode = nil
            }
        }
        self.task = task
        task.resume()
    }
    
    // MARK: Private helpers
    private func makeOAuthTokenRequest(code: String) -> URLRequest? {
        guard var components = URLComponents(string: "https://unsplash.com/oauth/token") else {
//            self.logger.error("[OAuth2Service.makeOAuthTokenRequest]: Failed to create URLComponents")
            print("[OAuth2Service.makeOAuthTokenRequest]: Failed to create URLComponents")
            return nil
        }
        
        components.queryItems = [
            URLQueryItem(name: "client_id", value: Constants.accessKey),
            URLQueryItem(name: "client_secret", value: Constants.secretKey),
            URLQueryItem(name: "redirect_uri", value: Constants.redirectURI),
            URLQueryItem(name: "code", value: code),
            URLQueryItem(name: "grant_type", value: "authorization_code"),
        ]
        
        guard let url = components.url else {
//            self.logger.error("[OAuth2Service.makeOAuthTokenRequest]: Failed to build URL")
            print("[OAuth2Service.makeOAuthTokenRequest]: Failed to build URL")
            return nil
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = HTTPMethod.post.rawValue
        return request
    }
}
