// MARK: - ProfileImage
struct ProfileImage: Codable {
    let small: String
    let medium: String
    let large: String
}

// MARK: - UserResult
struct UserResult: Codable {
    let profileImage: ProfileImage
    
    private enum CodingKeys: String, CodingKey {
        case profileImage = "profile_image"
    }
}
