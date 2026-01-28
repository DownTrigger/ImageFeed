import Foundation

struct ImagesListState {
    let photos: [Photo]
}

extension ImagesListState {
    static let empty = ImagesListState(photos: [])
}

