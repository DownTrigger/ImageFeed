import Foundation
import CoreGraphics

struct Photo {
    let id: String
    let size: CGSize
    let createdAt: Date?
    let description: String?
    let thumbImageURL: String
    let largeImageURL: String
    let isLiked: Bool
}
