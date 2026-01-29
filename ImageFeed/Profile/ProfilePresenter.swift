import Foundation
import Logging

final class ProfilePresenter: ProfilePresenterProtocol {

    // MARK: - Logger
    private let logger = Logger(label: "ProfilePresenter")

    // MARK: - Dependencies
    weak var view: ProfileViewProtocol?
    private let profileService: ProfileService
    private let profileImageService: ProfileImageService
    private let imagesListService: ImagesListService
    private let tokenStorage: OAuth2TokenStorage
    private let dataCleaner: WebViewDataCleaner

    // MARK: - Observers
    private var profileObserver: NSObjectProtocol?
    private var avatarObserver: NSObjectProtocol?
    private var imagesObserver: NSObjectProtocol?

    // MARK: - State
    private var previousLikedPhotos: [Photo] = []

    var likedPhotosCount: Int {
        imagesListService.likedPhotos.count
    }

    init(
        view: ProfileViewProtocol,
        profileService: ProfileService,
        profileImageService: ProfileImageService,
        imagesListService: ImagesListService,
        tokenStorage: OAuth2TokenStorage,
        dataCleaner: WebViewDataCleaner
    ) {
        self.view = view
        self.profileService = profileService
        self.profileImageService = profileImageService
        self.imagesListService = imagesListService
        self.tokenStorage = tokenStorage
        self.dataCleaner = dataCleaner
    }

    deinit {
        if let profileObserver { NotificationCenter.default.removeObserver(profileObserver) }
        if let avatarObserver { NotificationCenter.default.removeObserver(avatarObserver) }
        if let imagesObserver { NotificationCenter.default.removeObserver(imagesObserver) }
    }

    func viewDidLoad() {
        setupObservers()
        previousLikedPhotos = imagesListService.likedPhotos
        renderFullState()
    }

    func likedPhoto(at index: Int) -> Photo {
        imagesListService.likedPhotos[index]
    }

    func likedPhotoId(at index: Int) -> String {
        imagesListService.likedPhotos[index].id
    }

    func didTapUnlike(photoId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        imagesListService.changeLike(photoId: photoId, shouldLike: false) { [weak self] result in
            if case .failure(let error) = result {
                self?.logger.error("[didTapUnlike]: error=\(error) photoId=\(photoId)")
            }
            completion(result)
        }
    }

    func didConfirmLogout() {
        dataCleaner.clear { [weak self] in
            guard let self else { return }
            self.tokenStorage.token = nil
            self.imagesListService.cleanImagesList()
            self.view?.resetToSplash()
        }
    }

    // MARK: - Observers
    private func setupObservers() {
        profileObserver = NotificationCenter.default.addObserver(
            forName: ProfileService.profileDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.renderFullState()
        }

        avatarObserver = NotificationCenter.default.addObserver(
            forName: ProfileImageService.didChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.renderFullState()
        }

        imagesObserver = NotificationCenter.default.addObserver(
            forName: ImagesListService.didChangeNotification,
            object: imagesListService,
            queue: .main
        ) { [weak self] _ in
            self?.didReceiveImagesUpdate()
        }
    }

    private func didReceiveImagesUpdate() {
        let newLikedPhotos = imagesListService.likedPhotos
        let oldLikedPhotos = previousLikedPhotos
        previousLikedPhotos = newLikedPhotos

        let oldIDs = oldLikedPhotos.map { $0.id }
        let newIDs = newLikedPhotos.map { $0.id }

        let deleted = oldIDs.enumerated()
            .filter { !newIDs.contains($0.element) }
            .map { IndexPath(row: $0.offset, section: 0) }

        let inserted = newIDs.enumerated()
            .filter { !oldIDs.contains($0.element) }
            .map { IndexPath(row: $0.offset, section: 0) }

        renderFullState()

        if deleted.isEmpty && inserted.isEmpty {
            view?.reloadFavorites()
        } else {
            view?.applyFavoritesUpdates(deleted: deleted, inserted: inserted)
        }
    }

    // MARK: - Rendering
    private func renderFullState() {
        let profile = profileService.profile

        let nameText: String
        let loginText: String
        let bioText: String

        if let profile {
            nameText = profile.name.isEmpty ? "Имя не указано" : profile.name
            loginText = profile.loginName.isEmpty ? "@неизвестный_пользователь" : profile.loginName
            bioText = (profile.bio?.isEmpty ?? true) ? "Профиль не заполнен" : (profile.bio ?? "")
        } else {
            nameText = ""
            loginText = ""
            bioText = ""
        }

        let avatarURL: URL? = {
            guard let urlString = profileImageService.avatarURL else { return nil }
            return URL(string: urlString)
        }()

        let state = ProfileState(
            nameText: nameText,
            loginText: loginText,
            bioText: bioText,
            avatarURL: avatarURL,
            favoritesCount: imagesListService.likedPhotos.count
        )

        view?.render(state: state)
    }
}

