import Foundation

final class AuthHelper: AuthHelperProtocol {
    private let configuration: AuthConfiguration
    
    init(configuration: AuthConfiguration = .standard) {
        self.configuration = configuration
    }
    
    func authRequest() -> URLRequest? {
        guard let url = authURL() else {
            return nil
        }
        return URLRequest(url: url)
    }
    
    func authURL() -> URL? {
        guard var components = URLComponents(string: configuration.authURLString) else {
            return nil
        }
        
        components.queryItems = [
            URLQueryItem(name: "client_id", value: configuration.accessKey),
            URLQueryItem(name: "redirect_uri", value: configuration.redirectURI),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "scope", value: configuration.accessScope)
        ]
        
        return components.url
    }
    
    func code(from url: URL) -> String? {
        guard
            let components = URLComponents(string: url.absoluteString),
            components.path == "/oauth/authorize/native",
            let items = components.queryItems,
            let codeItem = items.first(where: { $0.name == "code" })
        else {
            return nil
        }
        
        return codeItem.value
    }
}
