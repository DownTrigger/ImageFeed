import Foundation

enum Constants {
    static let accessKey = "5zkiCmpxIDr9CzHKmyyTPy6v9vfk65Up_BlP4ljVSwE"
    static let secretKey = "6dUsGiJzOt7h268hF-F1yZMrwQXQoeriacPbd2x7LPw"
    static let redirectURI = "urn:ietf:wg:oauth:2.0:oob"
    static let accessScope = "public+read_user+write_likes"
    
    static let defaultBaseURL: URL = {
        guard let url = URL(string: "https://api.unsplash.com") else {
            print("[APIConstants.defaultBaseURL]: Error – invalid base URL string")
            fatalError("Invalid base URL")
        }
        return url
    }()
}
