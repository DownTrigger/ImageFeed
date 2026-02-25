import Foundation

struct ProfileState {
    let nameText: String
    let loginText: String
    let bioText: String
    let avatarURL: URL?
    let favoritesCount: Int
}

extension ProfileState {
    static let empty = ProfileState(
        nameText: "",
        loginText: "",
        bioText: "",
        avatarURL: nil,
        favoritesCount: 0
    )
}

