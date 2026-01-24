import Foundation
import CoreGraphics

struct Photo {
    let id: String
    let size: CGSize
    let createdAt: Date?
    let description: String?
    let regularImageURL: String
    let largeImageURL: String
    var isLiked: Bool
}
