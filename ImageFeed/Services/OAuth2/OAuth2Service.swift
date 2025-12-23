import Foundation

final class OAuth2Service {
    
    // MARK: Singleton
    static let shared = OAuth2Service()
    private init() { }
    
    // MARK: - Dependencies
    private let tokenStorage = OAuth2TokenStorage.shared
    
    // MARK: Public API
    func fetchAuthToken(_ code: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard let request = makeOAuthTokenRequest(code: code) else {
            DispatchQueue.main.async {
                completion(.failure(NetworkError.invalidRequest))
            }
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            
            if let error = error {
                print("Network error:", error)
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }
            
            guard
                let response = response as? HTTPURLResponse,
                let data = data
            else {
                DispatchQueue.main.async {
                    completion(.failure(NetworkError.urlSessionError))
                }
                return
            }
            
            guard (200...299).contains(response.statusCode) else {
                print("HTTP error, statusCode =", response.statusCode)
                DispatchQueue.main.async {
                    completion(.failure(NetworkError.httpStatusCode(response.statusCode)))
                }
                return
            }
            
            do {
                let decoded = try JSONDecoder().decode(OAuth2TokenResponseBody.self, from: data)
                let token = decoded.accessToken
                self.tokenStorage.token = token
                DispatchQueue.main.async {
                    completion(.success(token))
                }
            } catch {
                print("Decoding error:", error)
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
        
        task.resume()
    }
    
    // MARK: Private helpers
    private func makeOAuthTokenRequest(code: String) -> URLRequest? {
        guard var components = URLComponents(string: "https://unsplash.com/oauth/token") else {
            print("Failed to create URLComponents")
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
            print("Failed to get URL from URLComponents")
            return nil
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        return request
    }
}
