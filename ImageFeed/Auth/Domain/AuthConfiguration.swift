import Foundation

enum APIConstants {
    static let accessKey = "5zkiCmpxIDr9CzHKmyyTPy6v9vfk65Up_BlP4ljVSwE"
    static let secretKey = "6dUsGiJzOt7h268hF-F1yZMrwQXQoeriacPbd2x7LPw"
    static let redirectURI = "urn:ietf:wg:oauth:2.0:oob"
    static let accessScope = "public+read_user+write_likes"
    
    static let defaultBaseURLString = "https://api.unsplash.com"
    static let unsplashAuthorizeURLString = "https://unsplash.com/oauth/authorize"
}

struct AuthConfiguration {
    let accessKey: String
    let secretKey: String
    let redirectURI: String
    let accessScope: String
    let authURLString: String
    let defaultBaseURLString: String
    
    static var standard: AuthConfiguration {
        AuthConfiguration(
            accessKey: APIConstants.accessKey,
            secretKey: APIConstants.secretKey,
            redirectURI: APIConstants.redirectURI,
            accessScope: APIConstants.accessScope,
            authURLString: APIConstants.unsplashAuthorizeURLString,
            defaultBaseURLString: APIConstants.defaultBaseURLString
        )
    }
}
