import Foundation

final class OAuth2TokenStorage {
    
    static let shared = OAuth2TokenStorage()
    
    private let storage = UserDefaults.standard
    private let tokenKey = "OAuthToken"
    
    private init() {}
    
    var token: String? {
        get {
            let value = storage.string(forKey: tokenKey)
            return value
        }
        set {
            storage.set(newValue, forKey: tokenKey)
        }
    }
}
