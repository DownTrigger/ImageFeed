import Foundation
import Logging

final class OAuth2Service {
    
    // MARK: - Logger
    private let logger = Logger(label: "OAuth2Service")
    
    // MARK: - Singleton
    static let shared = OAuth2Service()
    private init() { }
    
    // MARK: - Dependencies
    private let tokenStorage = OAuth2TokenStorage.shared
    private let urlSession = URLSession.shared
    
    // MARK: - Private State
    private var task: URLSessionTask?
    private var lastCode: String?
    
    // MARK: - Public API
    func fetchOAuthToken(_ code: String, completion: @escaping (Result<String, Error>) -> Void) {
        assert(Thread.isMainThread)
        
        guard lastCode != code else {
            logger.error("[fetchOAuthToken]: DuplicateCode code=\(code)")
            return
        }
        
        task?.cancel()
        
        lastCode = code
        let requestCode = code
        
        guard let request = makeOAuthTokenRequest(code: code) else {
            logger.error("[fetchOAuthToken]: NetworkError.invalidRequest – failed to build request")
            DispatchQueue.main.async {
                completion(.failure(NetworkError.invalidRequest))
            }
            return
        }
        
        let task = urlSession.objectTask(for: request) { [weak self] (result: Result<OAuth2TokenResponseBody, Error>) in
            guard
                let self = self,
                self.lastCode == requestCode
            else {
                return
            }
                
            switch result {
            case .success(let decoded):
                let token = decoded.accessToken
                self.tokenStorage.token = token
                completion(.success(token))
                
            case .failure(let error):
                self.logger.error("[fetchOAuthToken]: NetworkError – \(error)")
                completion(.failure(error))
            }
    
            self.task = nil
            self.lastCode = nil
        }
        self.task = task
        task.resume()
    }
    
    // MARK: - Requests
    private func makeOAuthTokenRequest(code: String) -> URLRequest? {
        guard var components = URLComponents(string: "https://unsplash.com/oauth/token") else {
            logger.error("[makeOAuthTokenRequest]: Failed to create URLComponents")
            return nil
        }
        
        components.queryItems = [
            URLQueryItem(name: "client_id", value: APIConstants.accessKey),
            URLQueryItem(name: "client_secret", value: APIConstants.secretKey),
            URLQueryItem(name: "redirect_uri", value: APIConstants.redirectURI),
            URLQueryItem(name: "code", value: code),
            URLQueryItem(name: "grant_type", value: "authorization_code"),
        ]
        
        guard let url = components.url else {
            logger.error("[makeOAuthTokenRequest]: Failed to build URL")
            return nil
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = HTTPMethod.post.rawValue
        return request
    }
}
