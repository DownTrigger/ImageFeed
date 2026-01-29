import Foundation
import Logging

final class ImagesListPresenter: ImagesListPresenterProtocol {

    // MARK: - Logger
    private let logger = Logger(label: "ImagesListPresenter")

    // MARK: - Dependencies
    weak var view: ImagesListViewProtocol?
    private let imagesListService: ImagesListService

    // MARK: - State
    private var photos: [Photo] = []
    private var imagesObserver: NSObjectProtocol?

    init(
        view: ImagesListViewProtocol,
        imagesListService: ImagesListService
    ) {
        self.view = view
        self.imagesListService = imagesListService
    }

    deinit {
        if let imagesObserver {
            NotificationCenter.default.removeObserver(imagesObserver)
        }
    }

    // MARK: - Lifecycle
    func viewDidLoad() {
        setupObserver()
        photos = imagesListService.photos
        renderCurrentPhotos()
        imagesListService.fetchPhotosNextPage()
    }

    // MARK: - Public API
    func willDisplayRow(at index: Int, totalCount: Int) {
        guard index + 1 == totalCount else { return }
        imagesListService.fetchPhotosNextPage()
    }

    func didTapLike(photoId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let photo = photos.first(where: { $0.id == photoId }) else {
            let error = NSError(domain: "ImagesListPresenter", code: 0, userInfo: [NSLocalizedDescriptionKey: "Photo not found"])
            logger.error("[didTapLike]: photo not found id=\(photoId)")
            completion(.failure(error))
            return
        }

        let shouldLike = !photo.isLiked

        imagesListService.changeLike(
            photoId: photoId,
            shouldLike: shouldLike
        ) { [weak self] result in
            if case .failure(let error) = result {
                self?.logger.error("[didTapLike]: error changing like \(error.localizedDescription)")
            }
            completion(result)
        }
    }

    // MARK: - Observers
    private func setupObserver() {
        imagesObserver = NotificationCenter.default.addObserver(
            forName: ImagesListService.didChangeNotification,
            object: imagesListService,
            queue: .main
        ) { [weak self] _ in
            self?.didReceiveImagesUpdate()
        }
    }

    private func didReceiveImagesUpdate() {
        logger.info("[didReceiveImagesUpdate]: received images update")

        let newPhotos = imagesListService.photos
        let oldCount = photos.count
        let newCount = newPhotos.count

        photos = newPhotos
        renderCurrentPhotos()

        if newCount > oldCount {
            let indexPaths = (oldCount..<newCount).map {
                IndexPath(row: $0, section: 0)
            }
            view?.insertRows(at: indexPaths)
        } else {
            view?.reloadVisibleRows()
        }
    }

    // MARK: - Rendering
    private func renderCurrentPhotos() {
        let state = ImagesListState(photos: photos)
        view?.render(state: state)
    }
}

