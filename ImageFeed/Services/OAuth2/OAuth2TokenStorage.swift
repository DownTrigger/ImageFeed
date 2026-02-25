import Foundation
import SwiftKeychainWrapper

final class OAuth2TokenStorage {

    // MARK: - Singleton
    static let shared = OAuth2TokenStorage()
    private let tokenKey = "OAuthToken"
    private init() {}

    // MARK: - Public API
    var token: String? {
        get {
            KeychainWrapper.standard.string(forKey: tokenKey)
        }
        set {
            if let token = newValue {
                KeychainWrapper.standard.set(token, forKey: tokenKey)
            } else {
                KeychainWrapper.standard.removeObject(forKey: tokenKey)
            }
        }
    }
}
