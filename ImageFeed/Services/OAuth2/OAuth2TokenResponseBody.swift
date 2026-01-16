struct OAuth2TokenResponseBody: Decodable {
    
    let accessToken: String
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
    }
}
