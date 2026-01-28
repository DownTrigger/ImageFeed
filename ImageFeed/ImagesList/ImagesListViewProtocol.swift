import Foundation

protocol ImagesListViewProtocol: AnyObject {
    func render(state: ImagesListState)
    func insertRows(at indexPaths: [IndexPath])
    func reloadVisibleRows()
}

